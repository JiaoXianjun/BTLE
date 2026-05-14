"""Analyze screen: pick a pcap, render summary + plots.

Plots are rendered with matplotlib to PNG. Inline graphical display is
terminal-dependent (Kitty / iTerm protocols); we keep things simple and tell
the user the path so they can open it.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Optional

from textual.app import ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, Vertical
from textual.screen import Screen
from textual.widgets import Footer, Header, ListItem, ListView, Static


DEFAULT_OUT_DIR = Path.home() / "btle_captures"


class AnalyzeScreen(Screen):
    BINDINGS = [
        Binding("enter", "render", "Render"),
        Binding("o", "open_external", "Open viewer"),
        Binding("escape", "pop_screen", "Back"),
    ]

    def __init__(self, pcap: Optional[Path] = None) -> None:
        super().__init__()
        self.initial_pcap = pcap
        self.selected: Optional[Path] = pcap
        self.last_plot_paths: dict[str, Path] = {}

    def compose(self) -> ComposeResult:
        yield Header()
        with Horizontal():
            with Vertical():
                yield Static("[bold]pcaps[/bold]")
                self.list = ListView(id="pcaps")
                yield self.list
            with Vertical():
                self.summary = Static("", id="summary")
                yield self.summary
                self.plots_view = Static("", id="plots")
                yield self.plots_view
        yield Footer()

    def on_mount(self) -> None:
        self._populate_list()
        if self.initial_pcap is not None:
            self.selected = self.initial_pcap
            self.render_selected()

    def _populate_list(self) -> None:
        DEFAULT_OUT_DIR.mkdir(parents=True, exist_ok=True)
        candidates = sorted(
            list(DEFAULT_OUT_DIR.glob("*.pcap")) + ([self.initial_pcap] if self.initial_pcap else []),
            key=lambda p: p.stat().st_mtime if p.exists() else 0,
            reverse=True,
        )
        seen: set[Path] = set()
        for p in candidates:
            if p in seen or not p.exists():
                continue
            seen.add(p)
            self.list.append(ListItem(Static(p.name)))

    def on_list_view_selected(self, event: ListView.Selected) -> None:
        # Look up the path by name (rebuild relationships from sorted listing)
        items = list(DEFAULT_OUT_DIR.glob("*.pcap"))
        if self.initial_pcap is not None and self.initial_pcap.exists():
            items.append(self.initial_pcap)
        items = sorted(items, key=lambda p: p.stat().st_mtime, reverse=True)
        if event.list_view.index is None:
            return
        try:
            self.selected = items[event.list_view.index]
        except IndexError:
            return
        self.render_selected()

    def action_render(self) -> None:
        self.render_selected()

    def render_selected(self) -> None:
        if self.selected is None:
            return
        from btle_cli.analyze import render_all, summary
        from btle_cli.pcap_loader import load

        try:
            cap = load(self.selected)
        except Exception as e:
            self.summary.update(f"[red]Failed to load {self.selected}: {e}[/red]")
            return
        s = summary(cap)
        out_dir = self.selected.parent / "analysis"
        paths = render_all(cap, out_dir, ["timeline", "intervals", "vendors"])
        self.last_plot_paths = paths

        lines = [
            f"[bold cyan]{self.selected.name}[/bold cyan]",
            f"  n_packets={s['n_packets']}   n_devices={s['n_devices']}   duration={s['duration_s']:.1f}s",
            f"  channels: " + ", ".join(f"ch{c}={n}" for c, n in s["channel_distribution"].items()),
        ]
        if s.get("avg_advertising_interval_ms") is not None:
            lines.append(f"  avg interval: {s['avg_advertising_interval_ms']:.1f} ms")
        if s.get("rssi_avg_dbm") is not None:
            lines.append(f"  avg RSSI: {s['rssi_avg_dbm']:.1f} dBm")
        if s["top_vendors"]:
            lines.append("  top vendors: " + ", ".join(f"{v}={n}" for v, n in s["top_vendors"][:5]))
        self.summary.update("\n".join(lines))

        plot_lines = ["[bold]Plots[/bold]"]
        for kind, path in paths.items():
            plot_lines.append(f"  {kind}: [cyan]{path}[/cyan]")
        plot_lines.append("\n[dim]Press 'o' to open the timeline in the system viewer.[/dim]")
        self.plots_view.update("\n".join(plot_lines))

    def action_open_external(self) -> None:
        import subprocess
        import sys

        target = self.last_plot_paths.get("timeline")
        if target is None:
            self.notify("No plot rendered yet — press Enter first", severity="warning")
            return
        if sys.platform == "darwin":
            subprocess.Popen(["open", str(target)])
        elif sys.platform.startswith("linux"):
            subprocess.Popen(["xdg-open", str(target)])
        else:
            self.notify(f"Opening external viewer not supported on {sys.platform}", severity="warning")
