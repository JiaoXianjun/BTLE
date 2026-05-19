"""Load pcap files written by btle_rx (DLT_BLUETOOTH_LE_LL_WITH_PHDR / DLT 251).

Strategy: hand-roll a tiny parser tuned to btle_rx's exact write format. This
file is intentionally NOT using scapy at runtime — scapy adds ~10MB of imports
and ~400ms cold start, neither of which we want for an MCP-attached CLI. The
on-disk format is small and stable enough to read directly.

Per-packet on-disk format (matches `write_packet_to_file` in btle_rx.c):
    16 bytes pcap record header (sec, usec, caplen, len) — big-endian
    10 bytes BLE phdr: ch:1 sig_power:1 noise:1 aa_off:1 ref_aa:4 flags:2
     4 bytes access address (LE, raw)
     N bytes packet (header(2) + payload + CRC(3))

Global header is 24 bytes, magic 0xA1B2C3D4 (big-endian for btle_rx).
"""

from __future__ import annotations

import struct
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


DLT_BLUETOOTH_LE_LL_WITH_PHDR = 256  # tcpdump.org LINKTYPE_BLUETOOTH_LE_LL_WITH_PHDR


@dataclass
class PcapPkt:
    ts: float  # unix seconds (float)
    channel: int
    rssi_dbm: Optional[int]  # None if sig_power is -127
    access_addr: int
    packet_bytes: bytes  # PDU header(2) + payload + CRC(3)

    @property
    def pdu_header(self) -> tuple[int, int, int, int, int]:
        """Returns (pdu_type, tx_add, rx_add, payload_len, is_adv_channel).
        is_adv_channel only correct for ch 37/38/39 (ADV channels).
        """
        if len(self.packet_bytes) < 2:
            return (0, 0, 0, 0, 0)
        h0 = self.packet_bytes[0]
        h1 = self.packet_bytes[1]
        is_adv = self.channel in (37, 38, 39)
        if is_adv:
            pdu_type = h0 & 0x0F
            tx_add = (h0 >> 6) & 0x1
            rx_add = (h0 >> 7) & 0x1
            payload_len = h1 & 0x3F
        else:
            pdu_type = h0 & 0x03
            tx_add = 0
            rx_add = 0
            payload_len = h1 & 0x1F
        return (pdu_type, tx_add, rx_add, payload_len, int(is_adv))

    @property
    def adv_a(self) -> Optional[str]:
        """Extract AdvA from PDUs that have it. None otherwise."""
        pdu_type, _, _, payload_len, is_adv = self.pdu_header
        if not is_adv or payload_len < 6 or len(self.packet_bytes) < 8:
            return None
        payload = self.packet_bytes[2 : 2 + payload_len]
        # PDU types with AdvA as first 6 bytes
        if pdu_type in (0, 2, 4, 6):
            mac = payload[:6][::-1]
            return ":".join(f"{b:02x}" for b in mac)
        # PDU 1/3 — A0 (advertiser) is first 6 bytes
        if pdu_type in (1, 3):
            mac = payload[:6][::-1]
            return ":".join(f"{b:02x}" for b in mac)
        # PDU 5 (CONNECT_REQ): AdvA at bytes 6..11
        if pdu_type == 5 and len(payload) >= 12:
            mac = payload[6:12][::-1]
            return ":".join(f"{b:02x}" for b in mac)
        return None


@dataclass
class CaptureFile:
    path: Path
    packets: list[PcapPkt] = field(default_factory=list)
    linktype: int = DLT_BLUETOOTH_LE_LL_WITH_PHDR

    @property
    def duration_s(self) -> float:
        if len(self.packets) < 2:
            return 0.0
        return self.packets[-1].ts - self.packets[0].ts


def load(path: Path) -> CaptureFile:
    """Parse a btle_rx pcap. Raises ValueError on bad magic or truncated file."""
    p = Path(path)
    data = p.read_bytes()
    if len(data) < 24:
        raise ValueError(f"{p}: file too short ({len(data)} bytes)")

    magic = struct.unpack(">I", data[:4])[0]
    # btle_rx writes BE magic A1B2C3D4 and BE timestamps; that's an unusual choice
    # but matches the source (see btle_rx.c:108).
    if magic == 0xA1B2C3D4:
        endian = ">"
    elif magic == 0xD4C3B2A1:
        # LE pcap files written by tshark etc.
        endian = "<"
    else:
        raise ValueError(f"{p}: bad pcap magic {magic:#x}")

    linktype = struct.unpack(f"{endian}I", data[20:24])[0]
    if linktype != DLT_BLUETOOTH_LE_LL_WITH_PHDR:
        raise ValueError(f"{p}: unexpected linktype {linktype} (want {DLT_BLUETOOTH_LE_LL_WITH_PHDR})")

    cap = CaptureFile(path=p, linktype=linktype)
    pos = 24
    n = len(data)
    rec_hdr = struct.Struct(f"{endian}IIII")
    while pos + 16 <= n:
        sec, usec, caplen, _length = rec_hdr.unpack_from(data, pos)
        pos += 16
        if pos + caplen > n:
            break
        body = data[pos : pos + caplen]
        pos += caplen
        if caplen < 14:  # 10 phdr + 4 access addr at minimum
            continue
        ch = body[0]
        sig_power = struct.unpack("b", body[1:2])[0]  # signed
        # body[2] = noise_power, body[3] = aa_off, body[4:8] = ref_aa, body[8:10] = flags
        access_addr_bytes = body[10:14]
        access_addr = struct.unpack("<I", access_addr_bytes)[0]
        packet_bytes = bytes(body[14:])
        rssi = None if sig_power == -127 else int(sig_power)
        cap.packets.append(
            PcapPkt(
                ts=sec + usec / 1_000_000.0,
                channel=ch,
                rssi_dbm=rssi,
                access_addr=access_addr,
                packet_bytes=packet_bytes,
            )
        )
    return cap
