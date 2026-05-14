"""Offline analysis & matplotlib visualizations for capture files.

Pure functions; each returns a `matplotlib.figure.Figure` so callers (CLI &
TUI) can choose to savefig() or display inline. Heavy matplotlib import is
done lazily inside the functions to avoid startup cost when only the loader is
needed (e.g. inside an MCP tool that just returns summaries).
"""

from __future__ import annotations

import collections
from pathlib import Path
from typing import Any, Optional

from btle_cli.aggregate import ParsedAd, parse_ad_structures
from btle_cli.oui import lookup as oui_lookup
from btle_cli.pcap_loader import CaptureFile, PcapPkt
from btle_cli.vendors import manufacturer_name


def _pkt_adv_a(pkt: PcapPkt) -> Optional[str]:
    return pkt.adv_a


def _pkt_payload_after_adva(pkt: PcapPkt) -> str:
    pdu_type, _, _, plen, is_adv = pkt.pdu_header
    if not is_adv:
        return ""
    payload = pkt.packet_bytes[2 : 2 + plen]
    return payload.hex()


def summary(cap: CaptureFile) -> dict[str, Any]:
    n = len(cap.packets)
    if n == 0:
        return {
            "n_packets": 0,
            "n_devices": 0,
            "duration_s": 0.0,
            "channel_distribution": {},
            "top_vendors": [],
            "avg_advertising_interval_ms": None,
        }

    ch_counter: collections.Counter[int] = collections.Counter()
    vendor_counter: collections.Counter[str] = collections.Counter()
    devices: dict[str, list[float]] = collections.defaultdict(list)
    rssi_samples: list[int] = []

    for p in cap.packets:
        ch_counter[p.channel] += 1
        if p.rssi_dbm is not None:
            rssi_samples.append(p.rssi_dbm)
        adv_a = _pkt_adv_a(p)
        if adv_a is None:
            continue
        devices[adv_a].append(p.ts)
        # Vendor: prefer manufacturer ID from AD struct; fall back to OUI
        parsed = parse_ad_structures(_pkt_payload_after_adva(p))
        if parsed.manufacturer_id is not None:
            name = manufacturer_name(parsed.manufacturer_id)
            vendor_counter[name or f"MFG-{parsed.manufacturer_id:04x}"] += 1
        else:
            v = oui_lookup(adv_a) or "Unknown"
            vendor_counter[v] += 1

    avg_intervals: list[float] = []
    for adv_a, ts_list in devices.items():
        if len(ts_list) < 2:
            continue
        deltas = [(b - a) * 1000.0 for a, b in zip(ts_list, ts_list[1:])]
        deltas = [d for d in deltas if 0 < d < 60_000]
        if deltas:
            avg_intervals.extend(deltas)

    return {
        "n_packets": n,
        "n_devices": len(devices),
        "duration_s": cap.duration_s,
        "channel_distribution": dict(ch_counter.most_common()),
        "top_vendors": vendor_counter.most_common(10),
        "avg_advertising_interval_ms": (
            sum(avg_intervals) / len(avg_intervals) if avg_intervals else None
        ),
        "rssi_avg_dbm": (sum(rssi_samples) / len(rssi_samples)) if rssi_samples else None,
    }


def timeline(cap: CaptureFile, top_n: int = 20):
    import matplotlib.pyplot as plt

    counts: collections.Counter[str] = collections.Counter()
    by_dev: dict[str, list[tuple[float, int]]] = collections.defaultdict(list)
    if not cap.packets:
        fig, ax = plt.subplots()
        ax.set_title("Timeline (empty capture)")
        return fig
    t0 = cap.packets[0].ts
    for p in cap.packets:
        adv_a = _pkt_adv_a(p)
        if adv_a is None:
            continue
        counts[adv_a] += 1
        by_dev[adv_a].append((p.ts - t0, p.channel))

    top = [a for a, _ in counts.most_common(top_n)]
    fig, ax = plt.subplots(figsize=(12, max(3, 0.4 * len(top))))
    for i, adv_a in enumerate(top):
        xs = [t for t, _ in by_dev[adv_a]]
        chs = [c for _, c in by_dev[adv_a]]
        ax.scatter(xs, [i] * len(xs), c=chs, s=8, cmap="viridis", vmin=37, vmax=39)
    ax.set_yticks(range(len(top)))
    ax.set_yticklabels(top, fontsize=8, fontfamily="monospace")
    ax.set_xlabel("Time (s)")
    ax.set_title(f"Per-device timeline (top {len(top)} by packet count, colored by channel)")
    ax.grid(True, axis="x", alpha=0.3)
    fig.tight_layout()
    return fig


def intervals(cap: CaptureFile, adv_a: Optional[str] = None):
    import matplotlib.pyplot as plt

    by_dev: dict[str, list[float]] = collections.defaultdict(list)
    for p in cap.packets:
        a = _pkt_adv_a(p)
        if a:
            by_dev[a].append(p.ts)

    deltas_ms: list[float] = []
    if adv_a:
        ts = by_dev.get(adv_a, [])
        deltas_ms = [(b - a) * 1000 for a, b in zip(ts, ts[1:]) if 0 < (b - a) * 1000 < 60_000]
        title = f"Advertising intervals for {adv_a}"
    else:
        for ts in by_dev.values():
            for a, b in zip(ts, ts[1:]):
                ms = (b - a) * 1000
                if 0 < ms < 60_000:
                    deltas_ms.append(ms)
        title = "Advertising intervals (all devices)"

    fig, ax = plt.subplots(figsize=(10, 4))
    if deltas_ms:
        ax.hist(deltas_ms, bins=60, log=True, edgecolor="black", alpha=0.7)
        median = sorted(deltas_ms)[len(deltas_ms) // 2]
        ax.axvline(median, color="red", linestyle="--", label=f"median ≈ {median:.1f} ms")
        ax.legend()
    ax.set_xlabel("Interval (ms)")
    ax.set_ylabel("Count (log)")
    ax.set_title(title)
    ax.grid(True, alpha=0.3)
    fig.tight_layout()
    return fig


def vendors(cap: CaptureFile):
    import matplotlib.pyplot as plt

    counter: collections.Counter[str] = collections.Counter()
    for p in cap.packets:
        a = _pkt_adv_a(p)
        if a is None:
            continue
        parsed = parse_ad_structures(_pkt_payload_after_adva(p))
        if parsed.manufacturer_id is not None:
            name = manufacturer_name(parsed.manufacturer_id) or f"MFG-{parsed.manufacturer_id:04x}"
        else:
            name = oui_lookup(a) or "Unknown"
        counter[name] += 1

    fig, ax = plt.subplots(figsize=(8, 8))
    if counter:
        top = counter.most_common(8)
        other = sum(c for _, c in counter.most_common()[8:])
        labels = [n for n, _ in top]
        sizes = [c for _, c in top]
        if other:
            labels.append("Other")
            sizes.append(other)
        ax.pie(sizes, labels=labels, autopct="%1.1f%%", startangle=140, textprops={"fontsize": 9})
        ax.set_title("Packets by vendor")
    else:
        ax.set_title("Vendors (empty capture)")
    fig.tight_layout()
    return fig


def render_all(cap: CaptureFile, out_dir: Path, plots: list[str]) -> dict[str, Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    paths: dict[str, Path] = {}
    if "timeline" in plots:
        fig = timeline(cap)
        p = out_dir / "timeline.png"
        fig.savefig(p, dpi=120)
        paths["timeline"] = p
    if "intervals" in plots:
        fig = intervals(cap)
        p = out_dir / "intervals.png"
        fig.savefig(p, dpi=120)
        paths["intervals"] = p
    if "vendors" in plots:
        fig = vendors(cap)
        p = out_dir / "vendors.png"
        fig.savefig(p, dpi=120)
        paths["vendors"] = p
    return paths
