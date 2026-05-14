"""Typer CLI surface.

Every command is a free function with typed args returning a typed dataclass.
This shape is what a future MCP server can wrap directly:

    from btle_cli.cli import scan, capture, analyze
    @mcp.tool()
    async def btle_scan(duration_s: float = 10.0) -> dict:
        return scan(duration_s=duration_s).model_dump()
"""

from __future__ import annotations

import asyncio
import json
import sys
import time
from dataclasses import asdict
from datetime import datetime
from pathlib import Path
from typing import Optional

import typer
from rich.console import Console
from rich.table import Table

from btle_cli.aggregate import DeviceRecord, ScanAggregator
from btle_cli.analyze import render_all, summary as cap_summary
from btle_cli.events import HopEvent, PktEvent, StatusEvent
from btle_cli.pcap_loader import load as load_pcap
from btle_cli.rx_proc import RxOptions, RxProcess


app = typer.Typer(
    name="btle",
    help="HackRF BTLE sniffer: scan / capture / analyze / tx / tui",
    no_args_is_help=True,
    add_completion=False,
)

console = Console()


# ---------------- structured results (MCP-friendly) ----------------


from pydantic import BaseModel


class DeviceRecordDTO(BaseModel):
    adv_a: str
    name: str = ""
    vendor: str = ""
    pkt_count: int = 0
    crc_ok_ratio: float = 0.0
    first_seen: float = 0.0
    last_seen: float = 0.0
    last_rssi: Optional[int] = None
    last_channel: int = 0
    tx_power: Optional[int] = None
    service_uuids_16: list[str] = []
    service_uuids_128: list[str] = []
    manufacturer_id: Optional[int] = None


class ScanResult(BaseModel):
    devices: list[DeviceRecordDTO] = []
    duration_s: float = 0.0
    total_packets: int = 0
    crc_ok_ratio: float = 0.0
    channels_scanned: list[int] = []


class CaptureResult(BaseModel):
    pcap_path: str = ""
    pkt_count: int = 0
    crc_ok_count: int = 0
    duration_s: float = 0.0
    hop_followed_aa: Optional[str] = None


class AnalyzeResult(BaseModel):
    summary: dict = {}
    plot_paths: dict[str, str] = {}


class TxResult(BaseModel):
    sent_count: int = 0
    duration_s: float = 0.0
    returncode: int = 0
    stderr_tail: str = ""


def _dto(rec: DeviceRecord) -> DeviceRecordDTO:
    return DeviceRecordDTO(
        adv_a=rec.adv_a,
        name=rec.name,
        vendor=rec.vendor,
        pkt_count=rec.pkt_count,
        crc_ok_ratio=rec.crc_ok_ratio(),
        first_seen=rec.first_seen,
        last_seen=rec.last_seen,
        last_rssi=rec.last_rssi,
        last_channel=rec.last_channel,
        tx_power=rec.parsed_ad.tx_power,
        service_uuids_16=rec.parsed_ad.service_uuids_16,
        service_uuids_128=rec.parsed_ad.service_uuids_128,
        manufacturer_id=rec.parsed_ad.manufacturer_id,
    )


# ---------------- scan ----------------


async def _run_scan(
    duration_s: float,
    channels: list[int],
    dwell_s: float,
    gain: int,
    lna: int,
) -> ScanResult:
    agg = ScanAggregator()
    started = time.time()
    deadline = started + duration_s
    chan_idx = 0
    visited: list[int] = []

    while time.time() < deadline:
        ch = channels[chan_idx % len(channels)]
        visited.append(ch)
        chan_idx += 1
        opts = RxOptions(channel=ch, gain=gain, lna=lna, rssi_est=True)
        proc = RxProcess(opts)
        try:
            await proc.start()
        except FileNotFoundError as e:
            raise typer.Exit(f"btle_rx not found: {e}") from e

        async def reader():
            async for evt in proc.stream():
                agg.update(evt)

        task = asyncio.create_task(reader())
        try:
            remaining = deadline - time.time()
            await asyncio.sleep(min(dwell_s, max(0.0, remaining)))
        finally:
            await proc.stop()
            try:
                await asyncio.wait_for(task, timeout=1.5)
            except asyncio.TimeoutError:
                task.cancel()

    snap = agg.snapshot(sort="pkts")
    return ScanResult(
        devices=[_dto(r) for r in snap],
        duration_s=time.time() - started,
        total_packets=agg.total_pkts,
        crc_ok_ratio=(agg.crc_ok_pkts / agg.total_pkts) if agg.total_pkts else 0.0,
        channels_scanned=sorted(set(visited)),
    )


def scan(
    duration_s: float = 10.0,
    channels: Optional[list[int]] = None,
    dwell_s: float = 2.0,
    gain: int = 24,
    lna: int = 32,
) -> ScanResult:
    """Programmatic entry: scan ADV channels and return a ScanResult."""
    if channels is None:
        channels = [37, 38, 39]
    return asyncio.run(_run_scan(duration_s, channels, dwell_s, gain, lna))


@app.command("scan")
def scan_cmd(
    duration_s: float = typer.Option(10.0, "--duration-s", "-d", help="Total scan duration."),
    channels: str = typer.Option("37,38,39", "--channels", help="CSV of ADV channels."),
    dwell_s: float = typer.Option(2.0, "--dwell-s", help="Per-channel dwell before rotation."),
    gain: int = typer.Option(24, "--gain", "-g", help="HackRF rxvga gain (default 24 — see README notes on gain tuning)."),
    lna: int = typer.Option(32, "--lna", "-l"),
    json_out: bool = typer.Option(False, "--json", help="Print ScanResult as JSON."),
) -> None:
    """Rotate-scan ADV channels and print a device table."""
    ch_list = [int(x) for x in channels.split(",")]
    result = scan(duration_s=duration_s, channels=ch_list, dwell_s=dwell_s, gain=gain, lna=lna)

    if json_out:
        typer.echo(result.model_dump_json(indent=2))
        return

    table = Table(title=f"Scan ({result.duration_s:.1f}s, {result.total_packets} pkts, "
                        f"crc_ok={result.crc_ok_ratio:.0%})")
    table.add_column("AdvA")
    table.add_column("Name")
    table.add_column("Vendor")
    table.add_column("Ch", justify="right")
    table.add_column("RSSI", justify="right")
    table.add_column("Pkts", justify="right")
    for d in result.devices:
        table.add_row(
            d.adv_a,
            (d.name or "")[:20],
            (d.vendor or "")[:14],
            str(d.last_channel),
            f"{d.last_rssi}" if d.last_rssi is not None else "-",
            str(d.pkt_count),
        )
    console.print(table)


# ---------------- capture ----------------


async def _run_capture(
    output: Path,
    mode: str,
    channel: int,
    filter_adva: Optional[str],
    filter_pdu_type: Optional[str],
    duration_s: Optional[float],
    gain: int,
    lna: int,
    rssi_est: bool,
) -> CaptureResult:
    output.parent.mkdir(parents=True, exist_ok=True)
    opts = RxOptions(
        channel=channel,
        gain=gain,
        lna=lna,
        rssi_est=rssi_est,
        filter_adva=filter_adva,
        filter_pdu_type=filter_pdu_type,
        hop=(mode == "hop"),
        pcap_out=output,
    )
    proc = RxProcess(opts)
    agg = ScanAggregator()
    started = time.time()
    await proc.start()

    async def reader() -> None:
        async for evt in proc.stream():
            agg.update(evt)

    task = asyncio.create_task(reader())
    try:
        if duration_s is None:
            await proc._proc.wait()  # run until SIGINT (Ctrl-C → KeyboardInterrupt)
        else:
            await asyncio.sleep(duration_s)
    except KeyboardInterrupt:
        pass
    finally:
        await proc.stop()
        try:
            await asyncio.wait_for(task, timeout=2.0)
        except asyncio.TimeoutError:
            task.cancel()

    return CaptureResult(
        pcap_path=str(output),
        pkt_count=agg.total_pkts,
        crc_ok_count=agg.crc_ok_pkts,
        duration_s=time.time() - started,
        hop_followed_aa=agg.hop.following_aa,
    )


def capture(
    output: Path,
    mode: str = "adv",  # "adv" | "hop" | "single"
    channel: int = 37,
    filter_adva: Optional[str] = None,
    filter_pdu_type: Optional[str] = None,
    duration_s: Optional[float] = None,
    gain: int = 24,
    lna: int = 32,
    rssi_est: bool = True,
) -> CaptureResult:
    return asyncio.run(
        _run_capture(
            output=output, mode=mode, channel=channel,
            filter_adva=filter_adva, filter_pdu_type=filter_pdu_type,
            duration_s=duration_s, gain=gain, lna=lna, rssi_est=rssi_est,
        )
    )


@app.command("capture")
def capture_cmd(
    output: Path = typer.Argument(..., help="Path to write the pcap."),
    mode: str = typer.Option("adv", help="adv | hop | single"),
    channel: int = typer.Option(37, "--channel", "-c"),
    filter_adva: Optional[str] = typer.Option(None, "--filter-adva", "-F"),
    filter_pdu_type: Optional[str] = typer.Option(None, "--filter-pdu-type", "-T"),
    duration_s: Optional[float] = typer.Option(None, "--duration-s", "-d"),
    gain: int = typer.Option(24, "--gain", "-g", help="HackRF rxvga gain (default 24 — see README notes on gain tuning)."),
    lna: int = typer.Option(32, "--lna", "-l"),
    rssi_est: bool = typer.Option(True, "--rssi-est/--no-rssi-est"),
    json_out: bool = typer.Option(False, "--json"),
) -> None:
    """Capture BLE packets to a pcap file."""
    result = capture(
        output=output, mode=mode, channel=channel,
        filter_adva=filter_adva, filter_pdu_type=filter_pdu_type,
        duration_s=duration_s, gain=gain, lna=lna, rssi_est=rssi_est,
    )
    if json_out:
        typer.echo(result.model_dump_json(indent=2))
    else:
        console.print(f"Saved {result.pkt_count} pkts ({result.crc_ok_count} CRC-OK) "
                      f"to [bold]{result.pcap_path}[/bold] in {result.duration_s:.1f}s")
        if result.hop_followed_aa:
            console.print(f"  Hop-followed AA: [cyan]{result.hop_followed_aa}[/cyan]")


# ---------------- analyze ----------------


def analyze(
    pcap: Path,
    out_dir: Path = Path("./analysis"),
    plots: Optional[list[str]] = None,
) -> AnalyzeResult:
    if plots is None:
        plots = ["timeline", "intervals", "vendors"]
    cap = load_pcap(pcap)
    paths = render_all(cap, out_dir, plots)
    return AnalyzeResult(
        summary=cap_summary(cap),
        plot_paths={k: str(v) for k, v in paths.items()},
    )


@app.command("analyze")
def analyze_cmd(
    pcap: Path = typer.Argument(..., exists=True, dir_okay=False),
    out_dir: Path = typer.Option(Path("./analysis"), "--out-dir", "-o"),
    plots: str = typer.Option("timeline,intervals,vendors", "--plots"),
    json_out: bool = typer.Option(False, "--json"),
) -> None:
    """Analyze a pcap: emit summary + matplotlib plots."""
    plot_list = [p.strip() for p in plots.split(",") if p.strip()]
    result = analyze(pcap=pcap, out_dir=out_dir, plots=plot_list)
    if json_out:
        typer.echo(result.model_dump_json(indent=2))
    else:
        s = result.summary
        console.print(f"[bold]{pcap}[/bold]: {s['n_packets']} pkts, "
                      f"{s['n_devices']} devices, {s['duration_s']:.1f}s")
        if s.get("avg_advertising_interval_ms") is not None:
            console.print(f"  avg ADV interval: {s['avg_advertising_interval_ms']:.1f} ms")
        if s.get("rssi_avg_dbm") is not None:
            console.print(f"  avg RSSI: {s['rssi_avg_dbm']:.1f} dBm")
        console.print("  channels: " + ", ".join(f"ch{c}={n}" for c, n in s["channel_distribution"].items()))
        if s["top_vendors"]:
            console.print("  top vendors: " + ", ".join(f"{v}={n}" for v, n in s["top_vendors"][:5]))
        for kind, path in result.plot_paths.items():
            console.print(f"  📊 {kind}: [cyan]{path}[/cyan]")


# ---------------- tui ----------------


recon_app = typer.Typer(
    name="recon",
    help="Reverse-engineering helpers — compact, structured output for LLM/MCP.",
    no_args_is_help=True,
)
app.add_typer(recon_app, name="recon")


@recon_app.command("profile")
def recon_profile_cmd(
    adv_a: str = typer.Argument(..., help="Target AdvA (AA:BB:CC:DD:EE:FF)."),
    duration_s: float = typer.Option(20.0, "--duration-s", "-d"),
    channel: int = typer.Option(37, "--channel", "-c"),
    pcap: Optional[Path] = typer.Option(
        None, "--pcap", help="Profile from a pcap instead of live capture."
    ),
    gain: int = typer.Option(24, "--gain", "-g"),
    lna: int = typer.Option(32, "--lna", "-l"),
) -> None:
    """One-shot device profile. Always emits compact JSON to stdout."""
    from btle_cli import recon

    if pcap is not None:
        result = recon.profile_from_pcap(adv_a=adv_a, pcap=pcap)
    else:
        result = recon.profile(
            adv_a=adv_a, duration_s=duration_s, channel=channel, gain=gain, lna=lna
        )
    typer.echo(result.model_dump_json(exclude_none=True))


@recon_app.command("quickscan")
def recon_quickscan_cmd(
    duration_s: float = typer.Option(10.0, "--duration-s", "-d"),
    channels: str = typer.Option("37,38,39", "--channels"),
    top_n: int = typer.Option(15, "--top-n"),
    dwell_s: float = typer.Option(2.0, "--dwell-s"),
    gain: int = typer.Option(24, "--gain", "-g"),
) -> None:
    """Short scan → top-N devices + fingerprint histogram. Compact JSON only."""
    from btle_cli import recon

    chs = [int(x) for x in channels.split(",")]
    result = recon.quickscan(
        duration_s=duration_s, channels=chs, top_n=top_n,
        dwell_s=dwell_s, gain=gain,
    )
    typer.echo(result.model_dump_json(exclude_none=True))


@recon_app.command("diff")
def recon_diff_cmd(
    pcap_a: Path = typer.Argument(..., exists=True, dir_okay=False),
    pcap_b: Path = typer.Argument(..., exists=True, dir_okay=False),
) -> None:
    """Diff two pcaps. Compact JSON only."""
    from btle_cli import recon

    typer.echo(recon.diff(pcap_a, pcap_b).model_dump_json(exclude_none=True))


@recon_app.command("entropy")
def recon_entropy_cmd(
    pcap: Path = typer.Argument(..., exists=True, dir_okay=False),
    adv_a: str = typer.Argument(..., help="Target AdvA in the pcap."),
) -> None:
    """Per-byte entropy of a target's manuf-data within a pcap."""
    from btle_cli import recon

    typer.echo(recon.payload_entropy(pcap, adv_a).model_dump_json(exclude_none=True))


@app.command("tui")
def tui_cmd() -> None:
    """Launch the interactive Textual TUI."""
    from btle_cli.tui.app import BtleApp

    BtleApp().run()


# ---------------- tx (forward decl; impl in tx_proc/tx_builder) ----------------


@app.command("tx")
def tx_cmd(
    plan_file: Path = typer.Argument(..., exists=True, dir_okay=False),
    repeat: int = typer.Option(1, "--repeat", "-r"),
    gain: int = typer.Option(0, "--gain", "-g"),
    json_out: bool = typer.Option(False, "--json"),
) -> None:
    """Transmit packets defined in a JSON/YAML/.txt plan via btle_tx."""
    from btle_cli.tx_proc import tx

    result = tx(plan_file=plan_file, repeat=repeat, gain=gain)
    if json_out:
        typer.echo(result.model_dump_json(indent=2))
    else:
        console.print(f"TX done: {result.sent_count} pkts in {result.duration_s:.1f}s "
                      f"(returncode={result.returncode})")
        if result.stderr_tail:
            console.print(f"[yellow]stderr tail:[/yellow] {result.stderr_tail}")
