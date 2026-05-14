"""High-level reverse-engineering operations on BLE captures.

Designed for LLM/MCP consumption: every public function returns a small,
flat pydantic model. No raw packet lists, no full payload_hex per packet —
just the fingerprints, counters, deltas and verdicts an analyst usually wants.

Token budgets per call (approximate, with default args):
  profile()          ~ 300 tokens
  quickscan()        ~ 600 tokens (top 15 devices)
  diff()             ~ 400 tokens
  payload_entropy()  ~ 300 tokens

To get more detail, pass `details=True` — that's the only way the verbose
path is enabled. Default is always compact.
"""

from __future__ import annotations

import asyncio
import collections
import statistics
from pathlib import Path
from typing import Iterable, Literal, Optional

from pydantic import BaseModel, ConfigDict, Field

from btle_cli.aggregate import DeviceRecord, ParsedAd, ScanAggregator, parse_ad_structures
from btle_cli.events import PktEvent
from btle_cli.pcap_loader import CaptureFile, PcapPkt, load as load_pcap
from btle_cli.rx_proc import RxOptions, RxProcess


# ---------------- protocol fingerprint table ----------------
#
# Each entry is a (predicate, label) pair. predicate receives a ParsedAd plus
# the full payload_hex; returns True if this fingerprint matches. Order
# matters — most specific first.

_SERVICE_TAGS = {
    "00001523-1212-efde-1523-785feabcd123": "nordic_lbs",
    "6e400001-b5a3-f393-e0a9-e50e24dcca9e": "nordic_uart",
    "8d53dc1d-1db7-4cd3-868b-8a527460aa84": "mcumgr_smp",
    "0000feaa-0000-1000-8000-00805f9b34fb": "eddystone",
    "0000fd5a-0000-1000-8000-00805f9b34fb": "apple_findmy",
    "0000fe9f-0000-1000-8000-00805f9b34fb": "google_fast_pair",
    "0000fef3-0000-1000-8000-00805f9b34fb": "tile",
}


def fingerprint(parsed: ParsedAd, payload_after_adva_hex: str) -> Optional[str]:
    """Return a short protocol tag, or None."""
    # iBeacon: Apple mfg-id (0x004C) + iBeacon subtype byte (0x02) + length (0x15)
    if (parsed.manufacturer_id == 0x004C and parsed.manufacturer_data_hex
            and parsed.manufacturer_data_hex.startswith("4c000215")):
        return "ibeacon"
    if parsed.manufacturer_id == 0x004C:
        return "apple_continuity"
    if parsed.manufacturer_id == 0x0006:
        return "microsoft_swift_pair"
    if parsed.manufacturer_id == 0x0059:
        return "nordic_proprietary"
    if parsed.manufacturer_id == 0x1337:
        return "dev_or_hobby_0x1337"

    for u128 in parsed.service_uuids_128:
        tag = _SERVICE_TAGS.get(u128.lower())
        if tag:
            return tag
    for u16 in parsed.service_uuids_16:
        full = f"0000{u16.lower()}-0000-1000-8000-00805f9b34fb"
        tag = _SERVICE_TAGS.get(full)
        if tag:
            return tag
    return None


# ---------------- compact return models ----------------


class TargetProfile(BaseModel):
    """One device — everything an analyst usually wants in one shot."""
    model_config = ConfigDict(extra="forbid")

    adv_a: str
    name: Optional[str] = None
    vendor_hint: Optional[str] = None
    mfg_id: Optional[int] = None
    protocol_fingerprint: Optional[str] = None
    primary_service_uuids: list[str] = Field(default_factory=list)
    pdu_types_seen: list[str] = Field(default_factory=list)
    is_connectable: bool = False
    is_scan_responsive: bool = False
    flags: Optional[int] = None
    tx_power_dbm: Optional[int] = None
    avg_interval_ms: Optional[float] = None
    rssi_dbm: Optional[int] = None
    rssi_range_dbm: Optional[tuple[int, int]] = None
    n_packets: int = 0
    crc_ok_ratio: float = 0.0
    duration_s: float = 0.0
    mfg_data_sample: Optional[str] = None     # truncated hex, ≤32 chars
    mfg_data_changes: bool = False
    notes: list[str] = Field(default_factory=list)


class DeviceBrief(BaseModel):
    """Compact device row for ScanSummary."""
    model_config = ConfigDict(extra="forbid")
    adv_a: str
    name: Optional[str] = None
    vendor_hint: Optional[str] = None
    fingerprint: Optional[str] = None
    rssi_dbm: Optional[int] = None
    n_pkts: int = 0


class ScanSummary(BaseModel):
    model_config = ConfigDict(extra="forbid")
    duration_s: float
    n_devices: int
    n_packets: int
    crc_ok_ratio: float
    channels_scanned: list[int]
    devices_top: list[DeviceBrief]
    fingerprints_seen: dict[str, int]


class DiffReport(BaseModel):
    """Diff two captures — what changed across runs."""
    model_config = ConfigDict(extra="forbid")
    only_in_a: list[str]
    only_in_b: list[str]
    common: int
    rssi_shifts: dict[str, int]   # adv_a → delta_dbm (only |Δ|>=5)
    payload_changed: dict[str, str]  # adv_a → "byte 6..9, 14"
    notes: list[str] = Field(default_factory=list)


class PayloadEntropyReport(BaseModel):
    """Which bytes of a device's manuf data vary, and how."""
    model_config = ConfigDict(extra="forbid")
    adv_a: str
    n_samples: int
    payload_length: int
    static_prefix_bytes: int      # how many leading bytes never change
    static_suffix_bytes: int
    changing_positions: list[int]
    likely_counter_positions: list[int]      # strictly monotonic
    likely_random_positions: list[int]       # high entropy, not monotonic
    sample_hex_first: Optional[str] = None
    sample_hex_last: Optional[str] = None


# ---------------- helpers ----------------


def _short_hex(b: bytes | str, max_bytes: int = 16) -> str:
    if isinstance(b, bytes):
        b = b.hex()
    if len(b) <= max_bytes * 2:
        return b
    return b[: max_bytes * 2] + "…"


def _device_to_brief(rec: DeviceRecord) -> DeviceBrief:
    return DeviceBrief(
        adv_a=rec.adv_a,
        name=rec.name or None,
        vendor_hint=rec.vendor or None,
        fingerprint=fingerprint(rec.parsed_ad, ""),
        rssi_dbm=rec.last_rssi,
        n_pkts=rec.pkt_count,
    )


def _device_to_profile(rec: DeviceRecord, duration_s: float) -> TargetProfile:
    rssis = [e.rssi_est for e in rec.history if e.rssi_est is not None]
    rssi_range = (min(rssis), max(rssis)) if rssis else None
    intervals = list(rec.advert_intervals_ms)
    avg_int = sum(intervals) / len(intervals) if intervals else None

    pdu_names = {
        0: "ADV_IND", 1: "ADV_DIRECT_IND", 2: "ADV_NONCONN_IND",
        3: "SCAN_REQ", 4: "SCAN_RSP", 5: "CONNECT_REQ", 6: "ADV_SCAN_IND",
    }
    pdu_types_seen = sorted({pdu_names.get(t, f"R{t}") for t in rec.pdu_types_seen})
    is_connectable = any(t in rec.pdu_types_seen for t in (0, 1))
    is_scan_responsive = 4 in rec.pdu_types_seen

    # mfg data: are bytes changing across packets?
    mfg_blobs: list[str] = []
    for e in rec.history:
        if e.pdu_type in (0, 2, 4, 6):
            parsed = parse_ad_structures(e.payload_hex)
            if parsed.manufacturer_data_hex:
                mfg_blobs.append(parsed.manufacturer_data_hex)
    mfg_changes = len(set(mfg_blobs)) > 1

    fp = fingerprint(rec.parsed_ad, rec.last_payload_hex)

    notes: list[str] = []
    if is_connectable and is_scan_responsive:
        notes.append("connectable + responds to SCAN_REQ")
    if not is_connectable and 2 in rec.pdu_types_seen:
        notes.append("broadcast-only (ADV_NONCONN_IND)")
    if mfg_changes:
        notes.append("manuf-data varies across packets — likely counter/sensor")
    if rec.parsed_ad.service_uuids_128 and any(
        u.lower() == "8d53dc1d-1db7-4cd3-868b-8a527460aa84"
        for u in rec.parsed_ad.service_uuids_128
    ):
        notes.append("MCUmgr SMP service present — OTA-capable")

    return TargetProfile(
        adv_a=rec.adv_a,
        name=rec.name or None,
        vendor_hint=rec.vendor or None,
        mfg_id=rec.parsed_ad.manufacturer_id,
        protocol_fingerprint=fp,
        primary_service_uuids=(rec.parsed_ad.service_uuids_128[:3]
                               + rec.parsed_ad.service_uuids_16[:3]),
        pdu_types_seen=pdu_types_seen,
        is_connectable=is_connectable,
        is_scan_responsive=is_scan_responsive,
        flags=rec.parsed_ad.flags,
        tx_power_dbm=rec.parsed_ad.tx_power,
        avg_interval_ms=round(avg_int, 1) if avg_int else None,
        rssi_dbm=rec.last_rssi,
        rssi_range_dbm=rssi_range,
        n_packets=rec.pkt_count,
        crc_ok_ratio=round(rec.crc_ok_ratio(), 3),
        duration_s=round(duration_s, 1),
        mfg_data_sample=(_short_hex(mfg_blobs[0]) if mfg_blobs else None),
        mfg_data_changes=mfg_changes,
        notes=notes,
    )


def _aggregator_from_pcap(cap: CaptureFile) -> ScanAggregator:
    """Build an Aggregator by replaying a pcap's packets as synthetic PktEvents."""
    agg = ScanAggregator()
    for p in cap.packets:
        pdu_type, tx, rx, plen, is_adv = p.pdu_header
        if not is_adv:
            continue
        evt = PktEvent(
            v=1, t="pkt", ts=p.ts, pkt=0, ch=p.channel,
            aa=f"{p.access_addr:08x}", crc_ok=True, kind="adv",
            pdu_type=pdu_type, tx_add=tx, rx_add=rx, plen=plen,
            adv_a=p.adv_a,
            payload_hex=p.packet_bytes[2:2 + plen].hex(),
            rssi_est=p.rssi_dbm,
        )
        agg.update(evt)
    return agg


# ---------------- ops: live ----------------


async def _live_collect(
    channels: list[int],
    duration_s: float,
    dwell_s: float,
    gain: int,
    lna: int,
    filter_adva: Optional[str] = None,
) -> tuple[ScanAggregator, list[int]]:
    """Run rotating capture for duration_s seconds, return aggregator."""
    import time

    agg = ScanAggregator()
    started = time.time()
    deadline = started + duration_s
    chan_idx = 0
    visited: list[int] = []
    while time.time() < deadline:
        ch = channels[chan_idx % len(channels)]
        visited.append(ch)
        chan_idx += 1
        opts = RxOptions(channel=ch, gain=gain, lna=lna, rssi_est=True,
                         filter_adva=filter_adva)
        proc = RxProcess(opts)
        await proc.start()

        async def reader():
            async for evt in proc.stream():
                agg.update(evt)

        task = asyncio.create_task(reader())
        try:
            await asyncio.sleep(min(dwell_s, max(0.0, deadline - time.time())))
        finally:
            await proc.stop()
            try:
                await asyncio.wait_for(task, timeout=1.0)
            except asyncio.TimeoutError:
                task.cancel()
    return agg, sorted(set(visited))


def quickscan(
    duration_s: float = 10.0,
    channels: Optional[list[int]] = None,
    dwell_s: float = 2.0,
    gain: int = 24,
    lna: int = 32,
    top_n: int = 15,
) -> ScanSummary:
    """Short scan returning only top-N devices + protocol-fingerprint histogram.

    Token-friendly: no payload hex, no histories — just enough for an LLM to
    decide which device to investigate next.
    """
    if channels is None:
        channels = [37, 38, 39]
    agg, visited = asyncio.run(_live_collect(channels, duration_s, dwell_s, gain, lna))
    snap = agg.snapshot(sort="pkts")[:top_n]
    fp_hist: collections.Counter[str] = collections.Counter()
    for rec in snap:
        fp = fingerprint(rec.parsed_ad, rec.last_payload_hex)
        if fp:
            fp_hist[fp] += 1
    return ScanSummary(
        duration_s=round(duration_s, 1),
        n_devices=len(agg.devices),
        n_packets=agg.total_pkts,
        crc_ok_ratio=round((agg.crc_ok_pkts / agg.total_pkts) if agg.total_pkts else 0.0, 3),
        channels_scanned=visited,
        devices_top=[_device_to_brief(r) for r in snap],
        fingerprints_seen=dict(fp_hist),
    )


def profile(
    adv_a: str,
    duration_s: float = 20.0,
    channel: int = 37,
    gain: int = 24,
    lna: int = 32,
) -> TargetProfile:
    """Lock on a specific AdvA, collect for duration_s, return one TargetProfile.

    `adv_a` is passed to btle_rx as a filter, so the pcap stays small and we
    only get packets we care about.
    """
    agg, _ = asyncio.run(
        _live_collect([channel], duration_s, duration_s, gain, lna,
                      filter_adva=adv_a)
    )
    rec = agg.devices.get(adv_a.lower())
    if rec is None:
        # nothing seen — return empty profile so the LLM knows
        return TargetProfile(adv_a=adv_a, n_packets=0, duration_s=duration_s,
                             notes=["device not seen during capture window"])
    return _device_to_profile(rec, duration_s)


# ---------------- ops: offline (pcap-driven) ----------------


def profile_from_pcap(adv_a: str, pcap: Path) -> TargetProfile:
    cap = load_pcap(pcap)
    agg = _aggregator_from_pcap(cap)
    rec = agg.devices.get(adv_a.lower())
    if rec is None:
        return TargetProfile(adv_a=adv_a, duration_s=cap.duration_s,
                             notes=["device not found in pcap"])
    return _device_to_profile(rec, cap.duration_s)


def diff(pcap_a: Path, pcap_b: Path) -> DiffReport:
    """Compare two pcaps: device set delta, RSSI shifts, payload mutations."""
    a = _aggregator_from_pcap(load_pcap(pcap_a))
    b = _aggregator_from_pcap(load_pcap(pcap_b))

    keys_a = set(a.devices)
    keys_b = set(b.devices)
    only_a = sorted(keys_a - keys_b)
    only_b = sorted(keys_b - keys_a)
    common = keys_a & keys_b

    rssi_shifts: dict[str, int] = {}
    payload_changed: dict[str, str] = {}
    for k in sorted(common):
        ra, rb = a.devices[k], b.devices[k]
        if ra.last_rssi is not None and rb.last_rssi is not None:
            d = rb.last_rssi - ra.last_rssi
            if abs(d) >= 5:
                rssi_shifts[k] = d
        # byte-level payload diff (last seen payload only — small)
        pa = ra.last_payload_hex
        pb = rb.last_payload_hex
        if pa and pb and pa != pb:
            ba, bb = bytes.fromhex(pa), bytes.fromhex(pb)
            mn = min(len(ba), len(bb))
            diffs = [i for i in range(mn) if ba[i] != bb[i]]
            if len(ba) != len(bb):
                payload_changed[k] = f"length {len(ba)}→{len(bb)} bytes"
            elif diffs:
                # condense long runs into ranges, max 5 entries to save tokens
                payload_changed[k] = _ranges(diffs)

    notes = []
    if only_a:
        notes.append(f"{len(only_a)} device(s) disappeared")
    if only_b:
        notes.append(f"{len(only_b)} new device(s) appeared")
    if rssi_shifts:
        notes.append(f"{len(rssi_shifts)} device(s) shifted RSSI ≥5 dB")

    # truncate large diffs aggressively
    return DiffReport(
        only_in_a=only_a[:20],
        only_in_b=only_b[:20],
        common=len(common),
        rssi_shifts={k: v for k, v in list(rssi_shifts.items())[:15]},
        payload_changed={k: v for k, v in list(payload_changed.items())[:15]},
        notes=notes,
    )


def _ranges(positions: list[int]) -> str:
    """Condense [3,4,5,7,9,10] → 'byte 3..5, 7, 9..10', cap at 5 ranges."""
    if not positions:
        return ""
    out: list[str] = []
    start = prev = positions[0]
    for p in positions[1:] + [None]:
        if p is not None and p == prev + 1:
            prev = p
            continue
        out.append(f"{start}" if start == prev else f"{start}..{prev}")
        if p is not None:
            start = prev = p
    if len(out) > 5:
        return "byte " + ", ".join(out[:5]) + f", … (+{len(out)-5} more)"
    return "byte " + ", ".join(out)


def payload_entropy(pcap: Path, adv_a: str) -> PayloadEntropyReport:
    """Per-byte stats of a target's manuf-data over the capture.

    Detects: counter (strictly monotonic), random (high entropy), static.
    """
    cap = load_pcap(pcap)
    blobs: list[bytes] = []
    for p in cap.packets:
        if p.adv_a != adv_a.lower():
            continue
        pdu_type, _, _, plen, is_adv = p.pdu_header
        if not is_adv or pdu_type not in (0, 2, 4, 6):
            continue
        parsed = parse_ad_structures(p.packet_bytes[2:2 + plen].hex())
        if parsed.manufacturer_data_hex:
            blobs.append(bytes.fromhex(parsed.manufacturer_data_hex))

    if not blobs:
        return PayloadEntropyReport(
            adv_a=adv_a, n_samples=0, payload_length=0,
            static_prefix_bytes=0, static_suffix_bytes=0,
            changing_positions=[], likely_counter_positions=[],
            likely_random_positions=[],
        )

    # Align: take min length only
    L = min(len(b) for b in blobs)
    blobs = [b[:L] for b in blobs]
    cols = [[b[i] for b in blobs] for i in range(L)]
    static = [len(set(c)) == 1 for c in cols]

    static_prefix = next((i for i, s in enumerate(static) if not s), L)
    static_suffix = next((i for i, s in enumerate(reversed(static)) if not s), L)
    changing = [i for i, s in enumerate(static) if not s]

    counter_pos: list[int] = []
    random_pos: list[int] = []
    for i in changing:
        col = cols[i]
        # Counter: strictly monotonic (allowing wrap once) — simple check
        is_mono = all(col[j] >= col[j - 1] for j in range(1, len(col)))
        unique_ratio = len(set(col)) / len(col)
        if is_mono and unique_ratio > 0.5:
            counter_pos.append(i)
        elif unique_ratio > 0.7:
            random_pos.append(i)

    return PayloadEntropyReport(
        adv_a=adv_a,
        n_samples=len(blobs),
        payload_length=L,
        static_prefix_bytes=static_prefix,
        static_suffix_bytes=static_suffix,
        changing_positions=changing[:24],   # cap
        likely_counter_positions=counter_pos[:8],
        likely_random_positions=random_pos[:8],
        sample_hex_first=_short_hex(blobs[0]),
        sample_hex_last=_short_hex(blobs[-1]) if len(blobs) > 1 else None,
    )
