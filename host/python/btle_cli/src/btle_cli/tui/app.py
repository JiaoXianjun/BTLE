"""Textual app entry point: routes between Scan / DeviceDetail / CaptureSelect /
CaptureLive / Analyze screens. State is shared via the App instance."""

from __future__ import annotations

from textual.app import App, ComposeResult
from textual.widgets import Footer, Header

from btle_cli.aggregate import ScanAggregator


class BtleApp(App):
    CSS = """
    Screen {
        background: $background;
    }
    Header { dock: top; }
    Footer { dock: bottom; }
    .stat-label { color: $text-muted; }
    """

    BINDINGS = [
        ("q", "quit", "Quit"),
        ("?", "help", "Help"),
        ("a", "open_analyze", "Analyze"),
    ]

    TITLE = "btle-cli — Bluetooth Low Energy explorer"

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        yield Footer()

    def on_mount(self) -> None:
        from btle_cli.tui.screens.scan import ScanScreen

        self.push_screen(ScanScreen())

    def action_help(self) -> None:
        self.notify(
            "↑/↓ navigate · Enter open · C capture all · s sort · f filter · a analyze · q quit",
            title="Keys",
            timeout=4,
        )

    def action_open_analyze(self) -> None:
        from btle_cli.tui.screens.analyze import AnalyzeScreen

        self.push_screen(AnalyzeScreen())
