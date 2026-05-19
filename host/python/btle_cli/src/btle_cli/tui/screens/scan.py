"""Scan screen: live device discovery on ADV channels (37/38/39 rotating)."""

from __future__ import annotations

import asyncio
from typing import Optional

from textual.app import ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, Vertical
from textual.screen import Screen
from textual.widgets import DataTable, Footer, Header, Static

from btle_cli.aggregate import DeviceRecord, ScanAggregator
from btle_cli.events import PktEvent
from btle_cli.rx_proc import RxOptions, RxProcess


class ScanScreen(Screen):
    BINDINGS = [
        Binding("enter", "open_detail", "Detail"),
        Binding("c", "capture_one", "Capture (this)"),
        Binding("shift+c", "capture_all", "Capture (all)"),
        Binding("s", "cycle_sort", "Sort"),
        Binding("p", "toggle_pause", "Pause"),
        Binding("escape", "pop_screen", "Back"),
    ]

    def __init__(self) -> None:
        super().__init__()
        self.agg = ScanAggregator()
        self._channels = [37, 38, 39]
        self._chan_idx = 0
        self._dwell_s = 2.0
        self._paused = False
        self._rx: Optional[RxProcess] = None
        self._sort_modes = ["pkts", "last_seen", "rssi", "name"]
        self._sort_idx = 0
        self._refresh_handle: Optional[asyncio.TimerHandle] = None

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        self.status_bar = Static("", id="status-bar")
        yield self.status_bar
        with Horizontal():
            with Vertical():
                self.table = DataTable(zebra_stripes=True, cursor_type="row")
                self.table.add_columns("AdvA", "Name", "Vendor", "Ch", "RSSI", "Pkts")
                yield self.table
        yield Footer()

    async def on_mount(self) -> None:
        self.set_interval(1.0, self._refresh_table)
        # Start the first rotation tick immediately
        self.run_worker(self._rotation_loop(), exclusive=True)

    async def _rotation_loop(self) -> None:
        while True:
            if self._paused:
                await asyncio.sleep(0.5)
                continue
            ch = self._channels[self._chan_idx % len(self._channels)]
            self._chan_idx += 1
            opts = RxOptions(channel=ch, rssi_est=True)
            try:
                rx = RxProcess(opts)
                await rx.start()
                self._rx = rx
            except FileNotFoundError as e:
                self.notify(f"btle_rx not found: {e}", severity="error", timeout=10)
                await asyncio.sleep(2.0)
                continue

            async def consume(rx_inst: RxProcess) -> None:
                async for evt in rx_inst.stream():
                    self.agg.update(evt)

            task = asyncio.create_task(consume(rx))
            try:
                await asyncio.sleep(self._dwell_s)
            finally:
                await rx.stop()
                try:
                    await asyncio.wait_for(task, timeout=1.0)
                except asyncio.TimeoutError:
                    task.cancel()
                self._rx = None

    def _refresh_table(self) -> None:
        sort = self._sort_modes[self._sort_idx]
        records = self.agg.snapshot(sort=sort)

        # Remember which device the cursor is on, so we can restore after the
        # rebuild (clear() resets cursor to row 0).
        prev_key = self._current_adva()

        self.table.clear()
        for r in records[:120]:
            self.table.add_row(
                r.adv_a,
                (r.name or "")[:24],
                (r.vendor or "")[:14],
                str(r.last_channel),
                f"{r.last_rssi}" if r.last_rssi is not None else "-",
                str(r.pkt_count),
                key=r.adv_a,
            )

        # Restore the cursor onto the same AdvA if it's still in view.
        if prev_key is not None:
            try:
                new_row = self.table.get_row_index(prev_key)
            except Exception:
                new_row = None
            if new_row is not None:
                self.table.move_cursor(row=new_row, animate=False)
        ch_now = self._channels[(self._chan_idx - 1) % len(self._channels)] if self._chan_idx else self._channels[0]
        rssis = [r.last_rssi for r in records if r.last_rssi is not None]
        rssi_min = min(rssis) if rssis else 0
        rssi_max = max(rssis) if rssis else 0
        paused = " [PAUSED]" if self._paused else ""
        self.status_bar.update(
            f"ch={ch_now} dwell={self._dwell_s:.1f}s · "
            f"devices={len(records)} · total_pkts={self.agg.total_pkts} · "
            f"rssi {rssi_min}..{rssi_max}dBm · sort={sort}{paused}"
        )

    def action_cycle_sort(self) -> None:
        self._sort_idx = (self._sort_idx + 1) % len(self._sort_modes)
        self._refresh_table()

    def action_toggle_pause(self) -> None:
        self._paused = not self._paused

    def _current_adva(self) -> Optional[str]:
        if self.table.cursor_row is None or self.table.row_count == 0:
            return None
        row_key = self.table.coordinate_to_cell_key((self.table.cursor_row, 0)).row_key
        return row_key.value if row_key else None

    def action_open_detail(self) -> None:
        adva = self._current_adva()
        if adva is None:
            return
        from btle_cli.tui.screens.device_detail import DeviceDetailScreen

        rec = self.agg.devices.get(adva)
        if rec is None:
            return
        self.app.push_screen(DeviceDetailScreen(rec))

    def action_capture_one(self) -> None:
        adva = self._current_adva()
        if adva is None:
            self.notify("No device selected", severity="warning")
            return
        from btle_cli.tui.screens.capture_select import CaptureSelectScreen

        self.app.push_screen(CaptureSelectScreen(filter_adva=adva))

    def action_capture_all(self) -> None:
        from btle_cli.tui.screens.capture_select import CaptureSelectScreen

        self.app.push_screen(CaptureSelectScreen())
