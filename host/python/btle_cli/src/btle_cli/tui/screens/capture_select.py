"""Capture-mode selector form."""

from __future__ import annotations

from datetime import datetime
from pathlib import Path
from typing import Optional

from textual.app import ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, Vertical
from textual.screen import Screen
from textual.widgets import Footer, Header, Input, Label, RadioButton, RadioSet, Static


DEFAULT_OUT_DIR = Path.home() / "btle_captures"


class CaptureSelectScreen(Screen):
    BINDINGS = [
        Binding("escape", "pop_screen", "Back"),
        # priority=True lets Enter fire from any focused widget (RadioSet, Input).
        Binding("enter", "start_capture", "Start", priority=True),
        # Belt-and-braces alternative shortcut.
        Binding("ctrl+s", "start_capture", "Start", priority=True),
    ]

    def __init__(self, filter_adva: Optional[str] = None) -> None:
        super().__init__()
        self.filter_adva = filter_adva or ""

    def compose(self) -> ComposeResult:
        yield Header()
        with Vertical():
            yield Static("[bold]Capture configuration[/bold]\n")
            yield Label("Mode")
            with RadioSet(id="mode"):
                yield RadioButton("ADV channels (37/38/39 rotating)", value=True, id="mode-adv")
                yield RadioButton("Single channel", id="mode-single")
                yield RadioButton("Hop-follow (track a connection)", id="mode-hop")
            yield Label("Channel (single mode)")
            self.channel_input = Input(value="37", id="channel")
            yield self.channel_input
            yield Label("Gain (dB) — 24 is the default sweet spot; raise to 32+ only if RSSI < -85 dBm")
            self.gain_input = Input(value="24", id="gain")
            yield self.gain_input
            yield Label("LNA (dB)")
            self.lna_input = Input(value="32", id="lna")
            yield self.lna_input
            yield Label("Filter AdvA (optional, AA:BB:CC:DD:EE:FF)")
            self.filter_input = Input(value=self.filter_adva, id="filter")
            yield self.filter_input
            yield Label("Duration (seconds, 0 = until stopped)")
            self.duration_input = Input(value="30", id="duration")
            yield self.duration_input
            yield Label("Output pcap path")
            default_path = DEFAULT_OUT_DIR / datetime.now().strftime("%Y%m%d-%H%M%S.pcap")
            self.output_input = Input(value=str(default_path), id="output")
            yield self.output_input
            yield Static(
                "\n[bold green]Enter[/bold green] or [bold green]Ctrl+S[/bold green] = start    "
                "[bold red]Esc[/bold red] = cancel"
            )
        yield Footer()

    def action_start_capture(self) -> None:
        try:
            mode_radio = self.query_one("#mode", RadioSet)
            mode_id = mode_radio.pressed_button.id if mode_radio.pressed_button else "mode-adv"
        except Exception:
            mode_id = "mode-adv"
        mode_map = {"mode-adv": "adv", "mode-single": "single", "mode-hop": "hop"}
        mode = mode_map.get(mode_id, "adv")

        try:
            channel = int(self.channel_input.value)
            gain = int(self.gain_input.value)
            lna = int(self.lna_input.value)
            duration_v = float(self.duration_input.value or "0")
            duration: Optional[float] = duration_v if duration_v > 0 else None
        except ValueError:
            self.notify("Invalid numeric field", severity="error")
            return

        filter_adva = self.filter_input.value.strip() or None
        output = Path(self.output_input.value.strip())
        output.parent.mkdir(parents=True, exist_ok=True)

        from btle_cli.tui.screens.capture_live import CaptureLiveScreen

        self.app.push_screen(
            CaptureLiveScreen(
                mode=mode,
                channel=channel,
                gain=gain,
                lna=lna,
                filter_adva=filter_adva,
                duration_s=duration,
                output=output,
            )
        )
