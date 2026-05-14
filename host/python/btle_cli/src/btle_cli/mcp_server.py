"""MCP server exposing btle_cli.recon as tools for Claude Code / any MCP host.

Run with `btle-cli-mcp` (after `pip install -e .`) or
`python -m btle_cli.mcp_server`. Talks stdio JSON-RPC; the Claude Code CLI
will launch this binary, write its JSON-RPC frames over stdin, and read
responses from stdout.

Token discipline: every tool wraps a `recon` function and returns
`model.model_dump(exclude_none=True)` so unset fields don't pollute the
LLM context. See `recon.py` for the actual budgets.
"""

from __future__ import annotations

import asyncio
from pathlib import Path
from typing import Any

from mcp.server.fastmcp import FastMCP

from btle_cli import recon


mcp = FastMCP(
    "btle-cli",
    instructions=(
        "Tools for sniffing & reverse-engineering BLE devices via a HackRF One. "
        "Use `ble_quickscan` to survey nearby devices. "
        "Use `ble_profile` once you have a target AdvA. "
        "`ble_payload_entropy` and `ble_diff_pcaps` analyse stored captures. "
        "Outputs are intentionally compact (≤600 tokens per call)."
    ),
)


@mcp.tool()
async def ble_quickscan(
    duration_s: float = 10.0,
    top_n: int = 15,
    channels: str = "37,38,39",
    dwell_s: float = 2.0,
    gain: int = 24,
) -> dict[str, Any]:
    """Rotate-scan ADV channels and return top-N devices + a protocol-fingerprint
    histogram. No payload bytes; no per-packet history. Typical ~250-600 tokens.

    Args:
        duration_s: total wall-clock duration of the scan.
        top_n: cap on devices returned (max 30 enforced).
        channels: CSV of ADV channels, e.g. "37,38,39".
        dwell_s: per-channel dwell before rotating.
        gain: HackRF rxvga gain. Default 24 = sweet spot for nearby devices;
            push to 32-40 only for distant signals (RSSI ≤ -85 dBm).
    """
    chs = [int(x) for x in channels.split(",")]
    top_n = max(1, min(top_n, 30))
    # recon.quickscan() calls asyncio.run() internally — fine to run in a thread
    # so it doesn't fight FastMCP's own loop.
    result = await asyncio.to_thread(
        recon.quickscan,
        duration_s=duration_s,
        channels=chs,
        dwell_s=dwell_s,
        gain=gain,
        top_n=top_n,
    )
    return result.model_dump(exclude_none=True)


@mcp.tool()
async def ble_profile(
    adv_a: str,
    duration_s: float = 20.0,
    channel: int = 37,
    pcap: str | None = None,
    gain: int = 24,
) -> dict[str, Any]:
    """One-shot device profile: name, vendor, protocol fingerprint, advertising
    interval, RSSI range, mfg-data variability, analyst notes. ~150 tokens.

    Args:
        adv_a: target advertising address, e.g. "fe:f8:fd:f9:2b:c7".
        duration_s: live-capture window (ignored if `pcap` is provided).
        channel: which ADV channel (37/38/39) when capturing live.
        pcap: optional pcap file path — skip live capture and profile from disk.
        gain: HackRF gain. See ble_quickscan for tuning notes.
    """
    if pcap is not None:
        result = await asyncio.to_thread(
            recon.profile_from_pcap, adv_a, Path(pcap)
        )
    else:
        result = await asyncio.to_thread(
            recon.profile,
            adv_a=adv_a,
            duration_s=duration_s,
            channel=channel,
            gain=gain,
        )
    return result.model_dump(exclude_none=True)


@mcp.tool()
async def ble_diff_pcaps(pcap_a: str, pcap_b: str) -> dict[str, Any]:
    """Compare two BLE pcaps: device-set delta, RSSI shifts ≥5 dB, byte-level
    payload changes (condensed to ranges). ~200-400 tokens.

    Args:
        pcap_a: first pcap path (the "before").
        pcap_b: second pcap path (the "after").
    """
    result = await asyncio.to_thread(recon.diff, Path(pcap_a), Path(pcap_b))
    return result.model_dump(exclude_none=True)


@mcp.tool()
async def ble_payload_entropy(pcap: str, adv_a: str) -> dict[str, Any]:
    """Identify which bytes of a target device's manufacturer-data vary across
    samples in a pcap. Flags static prefix/suffix, counter-like positions
    (strictly monotonic), and random-like positions. ~100-200 tokens.

    Args:
        pcap: pcap file path containing the target.
        adv_a: target advertising address.
    """
    result = await asyncio.to_thread(recon.payload_entropy, Path(pcap), adv_a)
    return result.model_dump(exclude_none=True)


@mcp.tool()
async def ble_capture_to_pcap(
    output_path: str,
    adv_a: str | None = None,
    channel: int = 37,
    duration_s: float = 30.0,
    mode: str = "single",
    gain: int = 24,
) -> dict[str, Any]:
    """Run btle_rx for `duration_s` seconds and save a pcap. Returns a small
    summary: path, pkt_count, crc_ok_count, duration. ~80 tokens.

    Args:
        output_path: where to write the pcap (parent dirs auto-created).
        adv_a: optional AdvA filter — only matching packets are kept.
        channel: 37/38/39 for ADV, 0..36 for data channels.
        duration_s: capture wall-clock duration.
        mode: "single" (one channel), "hop" (follow CONNECT_REQ).
        gain: HackRF rxvga.
    """
    from btle_cli.cli import capture as cli_capture

    out = Path(output_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    result = await asyncio.to_thread(
        cli_capture,
        output=out,
        mode=mode,
        channel=channel,
        filter_adva=adv_a,
        duration_s=duration_s,
        gain=gain,
    )
    return result.model_dump(exclude_none=True)


def main() -> None:
    """Console-script entry: run the MCP server over stdio."""
    mcp.run()


if __name__ == "__main__":
    main()
