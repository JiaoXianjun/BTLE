"""Per-device detail screen: recent adverts, AD-structure breakdown, intervals."""

from __future__ import annotations

import statistics

from textual.app import ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, Vertical
from textual.screen import Screen
from textual.widgets import DataTable, Footer, Header, Static

from btle_cli.aggregate import DeviceRecord


class DeviceDetailScreen(Screen):
    BINDINGS = [
        Binding("c", "capture_this", "Capture this"),
        Binding("escape", "pop_screen", "Back"),
    ]

    def __init__(self, record: DeviceRecord) -> None:
        super().__init__()
        self.record = record

    def compose(self) -> ComposeResult:
        yield Header()
        yield Static(self._summary_text(), id="device-summary")
        with Horizontal():
            with Vertical():
                yield Static("[bold]Recent adverts[/bold]")
                self.history = DataTable(zebra_stripes=True)
                self.history.add_columns("ts", "ch", "pdu", "rssi", "payload")
                yield self.history
            with Vertical():
                yield Static("[bold]Intervals[/bold]")
                self.intervals_view = Static(self._intervals_text())
                yield self.intervals_view
        yield Footer()

    def on_mount(self) -> None:
        for e in list(self.record.history):
            self.history.add_row(
                f"{e.ts:.3f}",
                str(e.ch),
                e.pdu_name or "?",
                f"{e.rssi_est}" if e.rssi_est is not None else "-",
                e.payload_hex[:48] + ("…" if len(e.payload_hex) > 48 else ""),
            )

    def _summary_text(self) -> str:
        r = self.record
        ad = r.parsed_ad
        lines = [
            f"[bold cyan]{r.adv_a}[/bold cyan]   pkts={r.pkt_count} "
            f"crc_ok={r.crc_ok_ratio():.0%} last_rssi={r.last_rssi}dBm last_ch={r.last_channel}",
            f"name=[yellow]{ad.local_name or '-'}[/yellow] "
            f"vendor={r.vendor or '-'} "
            f"tx_power={ad.tx_power if ad.tx_power is not None else '-'}",
        ]
        if ad.service_uuids_16:
            lines.append("16-bit UUIDs: " + ", ".join(ad.service_uuids_16))
        if ad.service_uuids_128:
            lines.append("128-bit UUIDs: " + ", ".join(ad.service_uuids_128[:2]))
        if ad.manufacturer_id is not None:
            mfg_data = ad.manufacturer_data_hex or ""
            lines.append(f"manuf_id=0x{ad.manufacturer_id:04x} data={mfg_data[:32]}")
        return "\n".join(lines)

    def _intervals_text(self) -> str:
        ms = list(self.record.advert_intervals_ms)
        if not ms:
            return "(no interval data yet)"
        lines = [
            f"samples: {len(ms)}",
            f"min:     {min(ms):.1f} ms",
            f"median:  {statistics.median(ms):.1f} ms",
            f"max:     {max(ms):.1f} ms",
        ]
        # Crude inline histogram
        if len(ms) >= 5:
            ms_sorted = sorted(ms)
            buckets = 6
            lo, hi = ms_sorted[0], ms_sorted[-1]
            if hi > lo:
                edges = [lo + (hi - lo) * i / buckets for i in range(buckets + 1)]
                counts = [0] * buckets
                for v in ms:
                    for b in range(buckets):
                        if edges[b] <= v < edges[b + 1] or (b == buckets - 1 and v == edges[-1]):
                            counts[b] += 1
                            break
                cmax = max(counts) or 1
                lines.append("")
                for b in range(buckets):
                    bar = "█" * int(20 * counts[b] / cmax)
                    lines.append(f"  {edges[b]:6.1f}..{edges[b+1]:6.1f}ms │{bar}")
        return "\n".join(lines)

    def action_capture_this(self) -> None:
        from btle_cli.tui.screens.capture_select import CaptureSelectScreen

        self.app.push_screen(CaptureSelectScreen(filter_adva=self.record.adv_a))
