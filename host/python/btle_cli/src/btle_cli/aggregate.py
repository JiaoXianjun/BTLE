"""Aggregate streaming events into device records & hop state.

`ScanAggregator` consumes Events from `rx_proc.RxProcess.stream()` (or any other
source) and maintains a per-AdvA `DeviceRecord` + a singleton `HopState`.

AD-structure parsing is intentionally minimal — we extract the bits a user
typically wants in a scan (Complete/Shortened Local Name, TX Power, Service
UUIDs, Manufacturer ID) and leave the rest as raw hex.
"""

from __future__ import annotations

import collections
import time
from dataclasses import dataclass, field
from typing import Iterable, Optional

from btle_cli.events import Event, HopEvent, PktEvent, StatusEvent
from btle_cli.oui import lookup as oui_lookup


# ---------------- AD structure parsing ----------------

# Subset of Bluetooth Assigned Numbers — AD Types we care about for UX.
AD_FLAGS = 0x01
AD_INCOMPLETE_16 = 0x02
AD_COMPLETE_16 = 0x03
AD_INCOMPLETE_32 = 0x04
AD_COMPLETE_32 = 0x05
AD_INCOMPLETE_128 = 0x06
AD_COMPLETE_128 = 0x07
AD_SHORTENED_NAME = 0x08
AD_COMPLETE_NAME = 0x09
AD_TX_POWER = 0x0A
AD_SERVICE_DATA_16 = 0x16
AD_MANUFACTURER_DATA = 0xFF


@dataclass
class ParsedAd:
    flags: Optional[int] = None
    local_name: Optional[str] = None
    tx_power: Optional[int] = None
    service_uuids_16: list[str] = field(default_factory=list)
    service_uuids_128: list[str] = field(default_factory=list)
    manufacturer_id: Optional[int] = None  # first 2 bytes of mfg data, little-endian
    manufacturer_data_hex: Optional[str] = None


def _parse_le_u16(b: bytes) -> int:
    return b[0] | (b[1] << 8)


def parse_ad_structures(payload_after_adva_hex: str) -> ParsedAd:
    """Parse the AD-structure stream that follows the 6-byte AdvA in an ADV_IND
    / ADV_NONCONN_IND / SCAN_RSP / ADV_SCAN_IND payload.

    The payload_hex passed here is the FULL payload of the PDU (incl. AdvA);
    we skip the first 6 bytes ourselves. Robust against truncation.
    """
    out = ParsedAd()
    try:
        data = bytes.fromhex(payload_after_adva_hex)
    except ValueError:
        return out
    if len(data) < 6:
        return out
    data = data[6:]  # skip AdvA

    i = 0
    n = len(data)
    while i < n:
        length = data[i]
        if length == 0 or i + 1 + length > n:
            break
        ad_type = data[i + 1]
        body = data[i + 2 : i + 1 + length]
        try:
            if ad_type == AD_FLAGS and len(body) >= 1:
                out.flags = body[0]
            elif ad_type in (AD_SHORTENED_NAME, AD_COMPLETE_NAME):
                out.local_name = body.decode("utf-8", errors="replace")
            elif ad_type == AD_TX_POWER and len(body) >= 1:
                # signed 8-bit
                v = body[0]
                out.tx_power = v - 256 if v >= 128 else v
            elif ad_type in (AD_COMPLETE_16, AD_INCOMPLETE_16):
                for j in range(0, len(body) - 1, 2):
                    out.service_uuids_16.append(f"{_parse_le_u16(body[j:j+2]):04x}")
            elif ad_type in (AD_COMPLETE_128, AD_INCOMPLETE_128):
                for j in range(0, len(body) - 15, 16):
                    raw = body[j : j + 16][::-1].hex()  # little-endian → big-endian display
                    out.service_uuids_128.append(
                        f"{raw[0:8]}-{raw[8:12]}-{raw[12:16]}-{raw[16:20]}-{raw[20:32]}"
                    )
            elif ad_type == AD_MANUFACTURER_DATA and len(body) >= 2:
                out.manufacturer_id = _parse_le_u16(body[:2])
                out.manufacturer_data_hex = body.hex()
        except Exception:  # never crash the aggregator on a malformed AD
            pass
        i += 1 + length
    return out


# ---------------- Device records ----------------


@dataclass
class DeviceRecord:
    adv_a: str
    pkt_count: int = 0
    crc_ok_count: int = 0
    first_seen: float = 0.0
    last_seen: float = 0.0
    last_rssi: Optional[int] = None
    last_channel: int = 0
    pdu_types_seen: set[int] = field(default_factory=set)
    last_payload_hex: str = ""
    parsed_ad: ParsedAd = field(default_factory=ParsedAd)
    advert_intervals_ms: collections.deque[float] = field(default_factory=lambda: collections.deque(maxlen=64))
    history: collections.deque[PktEvent] = field(default_factory=lambda: collections.deque(maxlen=20))

    @property
    def name(self) -> str:
        return self.parsed_ad.local_name or ""

    @property
    def vendor(self) -> str:
        if self.parsed_ad.manufacturer_id is not None:
            # Manufacturer ID is more accurate than OUI for BLE; map Apple etc.
            mid = self.parsed_ad.manufacturer_id
            from btle_cli.vendors import manufacturer_name

            v = manufacturer_name(mid)
            if v:
                return v
        return oui_lookup(self.adv_a) or ""

    def crc_ok_ratio(self) -> float:
        return self.crc_ok_count / self.pkt_count if self.pkt_count else 0.0


# ---------------- Hop state ----------------


@dataclass
class HopState:
    following_aa: Optional[str] = None
    current_ch: int = 0
    fsm_state: int = 0
    interval_us: int = 0
    hop_increment: int = 0
    crc_init: str = ""
    chm: str = ""
    last_change_ts: float = 0.0
    history: collections.deque[HopEvent] = field(default_factory=lambda: collections.deque(maxlen=100))


# ---------------- Aggregator ----------------


class ScanAggregator:
    """Streaming aggregator. Thread-safety: single-consumer; do not share."""

    def __init__(self) -> None:
        self.devices: dict[str, DeviceRecord] = {}
        self.hop = HopState()
        self.total_pkts: int = 0
        self.crc_ok_pkts: int = 0
        self.last_status: Optional[StatusEvent] = None
        self.started_at: float = time.time()

    def update(self, evt: Event) -> None:
        if isinstance(evt, PktEvent):
            self._on_pkt(evt)
        elif isinstance(evt, HopEvent):
            self._on_hop(evt)
        elif isinstance(evt, StatusEvent):
            self.last_status = evt

    def feed(self, events: Iterable[Event]) -> None:
        for e in events:
            self.update(e)

    def snapshot(self, sort: str = "last_seen") -> list[DeviceRecord]:
        records = list(self.devices.values())
        if sort == "last_seen":
            records.sort(key=lambda r: r.last_seen, reverse=True)
        elif sort == "pkts":
            records.sort(key=lambda r: r.pkt_count, reverse=True)
        elif sort == "name":
            records.sort(key=lambda r: r.name or "~")
        elif sort == "rssi":
            records.sort(key=lambda r: r.last_rssi or -200, reverse=True)
        return records

    # -------- internals --------

    def _on_pkt(self, evt: PktEvent) -> None:
        self.total_pkts += 1
        if evt.crc_ok:
            self.crc_ok_pkts += 1
        if evt.kind != "adv" or not evt.adv_a:
            return

        rec = self.devices.get(evt.adv_a)
        if rec is None:
            rec = DeviceRecord(adv_a=evt.adv_a, first_seen=evt.ts)
            self.devices[evt.adv_a] = rec

        if rec.last_seen:
            delta_ms = (evt.ts - rec.last_seen) * 1000.0
            if 0 < delta_ms < 60_000:
                rec.advert_intervals_ms.append(delta_ms)

        rec.pkt_count += 1
        if evt.crc_ok:
            rec.crc_ok_count += 1
        rec.last_seen = evt.ts
        rec.last_channel = evt.ch
        if evt.rssi_est is not None:
            rec.last_rssi = evt.rssi_est
        if evt.pdu_type is not None:
            rec.pdu_types_seen.add(evt.pdu_type)
        rec.last_payload_hex = evt.payload_hex
        rec.history.append(evt)

        # Parse AD structures only for PDU types that carry them
        # (ADV_IND / ADV_NONCONN_IND / SCAN_RSP / ADV_SCAN_IND = 0/2/4/6).
        if evt.pdu_type in (0, 2, 4, 6):
            parsed = parse_ad_structures(evt.payload_hex)
            # Merge: keep existing name unless new one is non-empty (SCAN_RSP often has name)
            if parsed.local_name:
                rec.parsed_ad.local_name = parsed.local_name
            if parsed.tx_power is not None:
                rec.parsed_ad.tx_power = parsed.tx_power
            if parsed.flags is not None:
                rec.parsed_ad.flags = parsed.flags
            if parsed.service_uuids_16:
                rec.parsed_ad.service_uuids_16 = sorted(
                    set(rec.parsed_ad.service_uuids_16) | set(parsed.service_uuids_16)
                )
            if parsed.service_uuids_128:
                rec.parsed_ad.service_uuids_128 = sorted(
                    set(rec.parsed_ad.service_uuids_128) | set(parsed.service_uuids_128)
                )
            if parsed.manufacturer_id is not None:
                rec.parsed_ad.manufacturer_id = parsed.manufacturer_id
                rec.parsed_ad.manufacturer_data_hex = parsed.manufacturer_data_hex

    def _on_hop(self, evt: HopEvent) -> None:
        self.hop.history.append(evt)
        self.hop.last_change_ts = evt.ts
        self.hop.current_ch = evt.ch
        self.hop.fsm_state = evt.state_to
        if evt.event == "track_start":
            self.hop.following_aa = evt.aa
            self.hop.interval_us = evt.interval_us
            self.hop.hop_increment = evt.hop
            self.hop.crc_init = evt.crc_init
            if evt.chm:
                self.hop.chm = evt.chm
        elif evt.event == "track_drop":
            self.hop.following_aa = None
