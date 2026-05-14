"""Smoke-test RxProcess against a fake `btle_rx` that just `cat`s a fixture."""

from __future__ import annotations

import os
from pathlib import Path

import pytest

from btle_cli.events import HopEvent, PktEvent, StatusEvent
from btle_cli.rx_proc import RxOptions, RxProcess

FIXTURE = Path(__file__).parent / "fixtures" / "sample.ndjson"


@pytest.fixture()
def fake_btle_rx(tmp_path: Path) -> str:
    """Create a tiny shell script that pretends to be btle_rx: ignores its
    arguments and pumps the fixture file to stdout. Lives in tmp_path so it
    doesn't pollute the repo."""
    script = tmp_path / "fake_btle_rx"
    script.write_text(
        f"#!/bin/sh\nexec cat {FIXTURE}\n",
        encoding="utf-8",
    )
    script.chmod(0o755)
    return str(script)


async def test_rx_proc_yields_all_events(fake_btle_rx: str) -> None:
    proc = RxProcess(RxOptions(channel=37), exe=fake_btle_rx)
    events = []
    async for evt in proc.stream():
        events.append(evt)
    await proc.stop()

    # 2 status + 3 pkt + 1 hop
    pkts = [e for e in events if isinstance(e, PktEvent)]
    hops = [e for e in events if isinstance(e, HopEvent)]
    statuses = [e for e in events if isinstance(e, StatusEvent)]
    assert len(statuses) == 2
    assert len(hops) == 1
    assert len(pkts) == 3
    # Order preserved
    assert statuses[0].event == "start"
    assert statuses[-1].event == "stop"
    # Banner captured
    assert any("Setting VGA" in line for line in proc.banner)


async def test_rx_proc_filter_adva_argv() -> None:
    opts = RxOptions(
        channel=38,
        filter_adva="AA:BB:CC:DD:EE:FF",
        rssi_est=True,
        pcap_out=Path("/tmp/x.pcap"),
    )
    argv = opts.to_argv("/bin/echo")
    assert "--filter-adva" in argv
    assert "AA:BB:CC:DD:EE:FF" in argv
    assert "--json" in argv and "--quiet-text" in argv
    assert "-s" in argv and "/tmp/x.pcap" in argv
    assert "--rssi-est" in argv
