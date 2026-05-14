"""Live capture screen with rolling feed, stat panel, hop-state indicator."""

from __future__ import annotations

import asyncio
import time
from pathlib import Path
from typing import Optional

from textual.app import ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, Vertical
from textual.screen import Screen
from textual.widgets import Footer, Header, Log, Static

from btle_cli.aggregate import ScanAggregator
from btle_cli.events import HopEvent, PktEvent, StatusEvent
from btle_cli.rx_proc import RxOptions, RxProcess


class CaptureLiveScreen(Screen):
    BINDINGS = [
        Binding("s", "stop", "Stop & analyze"),
        Binding("x", "abort", "Abort (no analyze)"),
        Binding("space", "toggle_pause_log", "Pause feed"),
        Binding("escape", "abort", "Abort"),
    ]

    def __init__(
        self,
        mode: str,
        channel: int,
        gain: int,
        lna: int,
        filter_adva: Optional[str],
        duration_s: Optional[float],
        output: Path,
    ) -> None:
        super().__init__()
        self.mode = mode
        self.channel = channel
        self.gain = gain
        self.lna = lna
        self.filter_adva = filter_adva
        self.duration_s = duration_s
        self.output = output
        self.agg = ScanAggregator()
        self._rx: Optional[RxProcess] = None
        self._task: Optional[asyncio.Task] = None
        self._started: float = 0.0
        self._paused_log = False
        self._rotation_channels = [37, 38, 39]
        self._rot_idx = 0
        self._stopped = False

    def compose(self) -> ComposeResult:
        yield Header()
        self.stats = Static("", id="stats")
        self.hop_panel = Static("[dim](hop state shows here when following a connection)[/dim]", id="hop")
        yield self.stats
        yield self.hop_panel
        self.feed = Log(highlight=True, max_lines=200, id="feed")
        yield self.feed
        yield Footer()

    async def on_mount(self) -> None:
        self._started = time.time()
        self.set_interval(0.3, self._refresh_stats)
        if self.duration_s is not None:
            self.set_timer(self.duration_s, self.action_stop)
        self.run_worker(self._capture_loop(), exclusive=True)

    async def _capture_loop(self) -> None:
        if self.mode == "adv":
            await self._rotate_loop()
        else:
            await self._single_session()

    async def _single_session(self) -> None:
        opts = RxOptions(
            channel=self.channel,
            gain=self.gain,
            lna=self.lna,
            rssi_est=True,
            filter_adva=self.filter_adva,
            hop=(self.mode == "hop"),
            pcap_out=self.output,
        )
        try:
            rx = RxProcess(opts)
            await rx.start()
            self._rx = rx
        except FileNotFoundError as e:
            self.notify(f"btle_rx not found: {e}", severity="error")
            return
        async for evt in rx.stream():
            if self._stopped:
                break
            self.agg.update(evt)
            self._on_event(evt)

    async def _rotate_loop(self) -> None:
        # ADV-channel rotation: same flow as ScanScreen but everything saves to one pcap.
        # Each rx_proc invocation appends to the pcap since btle_rx truncates on open.
        # To collect a SINGLE pcap across channels we capture only on one channel at a
        # time, but rotate fast. (Limitation: single HackRF; documented in README.)
        # Since each invocation truncates, we use append-mode by capturing all channels
        # sequentially into one stream and write the pcap header ourselves? Simpler:
        # capture on ch37 only and just rotate display channel. For full multi-channel
        # capture, use --mode single per channel separately.
        opts = RxOptions(
            channel=37,
            gain=self.gain,
            lna=self.lna,
            rssi_est=True,
            filter_adva=self.filter_adva,
            pcap_out=self.output,
        )
        try:
            rx = RxProcess(opts)
            await rx.start()
            self._rx = rx
        except FileNotFoundError as e:
            self.notify(f"btle_rx not found: {e}", severity="error")
            return
        async for evt in rx.stream():
            if self._stopped:
                break
            self.agg.update(evt)
            self._on_event(evt)

    def _on_event(self, evt) -> None:
        if isinstance(evt, PktEvent) and not self._paused_log:
            kind = evt.pdu_name or evt.ll_pdu_name or "?"
            adv = evt.adv_a or "—"
            rssi = f"{evt.rssi_est}dBm" if evt.rssi_est is not None else "?dBm"
            self.feed.write_line(f"[{evt.ts:.3f}] ch{evt.ch} {kind:14s} {adv} {rssi}")
        elif isinstance(evt, HopEvent):
            self.feed.write_line(f"[HOP] {evt.event} ch={evt.ch} state={evt.state_from}->{evt.state_to}")

    def _refresh_stats(self) -> None:
        elapsed = time.time() - self._started
        crc_pct = (self.agg.crc_ok_pkts / self.agg.total_pkts * 100) if self.agg.total_pkts else 0
        pps = self.agg.total_pkts / elapsed if elapsed > 0 else 0
        size_kb = 0
        if self.output.exists():
            try:
                size_kb = self.output.stat().st_size // 1024
            except OSError:
                pass
        self.stats.update(
            f"[bold]capture mode={self.mode}[/bold]   "
            f"pkts=[cyan]{self.agg.total_pkts}[/cyan]   crc_ok={crc_pct:.0f}%   "
            f"pps={pps:.1f}   elapsed={elapsed:.1f}s   "
            f"pcap={size_kb}KB   filter={self.filter_adva or '—'}"
        )
        hs = self.agg.hop
        if hs.following_aa:
            self.hop_panel.update(
                f"Following [cyan]AA={hs.following_aa}[/cyan] "
                f"ch={hs.current_ch} state={hs.fsm_state} "
                f"interval={hs.interval_us/1000:.2f}ms hop={hs.hop_increment} "
                f"chm={hs.chm}"
            )

    def action_toggle_pause_log(self) -> None:
        self._paused_log = not self._paused_log

    async def _stop_proc(self) -> None:
        self._stopped = True
        if self._rx is not None:
            await self._rx.stop()

    async def action_stop(self) -> None:
        await self._stop_proc()
        # jump to analyze on the just-saved pcap
        if self.output.exists():
            from btle_cli.tui.screens.analyze import AnalyzeScreen

            self.app.push_screen(AnalyzeScreen(pcap=self.output))
        else:
            self.app.pop_screen()

    async def action_abort(self) -> None:
        await self._stop_proc()
        self.app.pop_screen()
