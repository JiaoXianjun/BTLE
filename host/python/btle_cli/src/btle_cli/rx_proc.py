"""Async wrapper around `btle_rx --json --quiet-text`.

Spawns the C sniffer as a subprocess, streams NDJSON lines from its stdout, and
parses each into an Event. Non-JSON banner lines (e.g. hackrf lib's "Setting
VGA gain ...") are silently skipped — never an error.
"""

from __future__ import annotations

import asyncio
import collections
import os
import shutil
import signal
from collections.abc import AsyncIterator
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

from btle_cli.events import Event, parse_line


def find_btle_rx() -> str:
    """Locate the btle_rx binary.

    Resolution order:
      1) $BTLE_RX env var (absolute path)
      2) ../host/build/btle-tools/src/btle_rx relative to this file
      3) `btle_rx` on PATH
    """
    env = os.environ.get("BTLE_RX")
    if env and Path(env).is_file():
        return env

    # repo-relative: src/btle_cli/rx_proc.py → ../../../../host/build/btle-tools/src/btle_rx
    here = Path(__file__).resolve()
    candidate = here.parents[4] / "build" / "btle-tools" / "src" / "btle_rx"
    if candidate.is_file():
        return str(candidate)

    on_path = shutil.which("btle_rx")
    if on_path:
        return on_path

    raise FileNotFoundError(
        "btle_rx binary not found. Build it (cd host && mkdir build && cd build && "
        "cmake .. && make btle_rx) or set BTLE_RX=/path/to/btle_rx."
    )


@dataclass
class RxOptions:
    channel: int = 37
    gain: int = 24  # HackRF rxvga sweet spot for nearby BLE; see notes in README
    lna: int = 32
    amp: bool = False
    filter_adva: Optional[str] = None  # "AA:BB:CC:DD:EE:FF"
    filter_pdu_type: Optional[str] = None  # CSV
    pcap_out: Optional[Path] = None
    hop: bool = False
    rssi_est: bool = True
    extra_args: list[str] = field(default_factory=list)

    def to_argv(self, exe: str) -> list[str]:
        argv = [exe, "-c", str(self.channel), "-g", str(self.gain), "-l", str(self.lna)]
        if self.amp:
            argv.append("-b")
        if self.filter_adva:
            argv += ["--filter-adva", self.filter_adva]
        if self.filter_pdu_type:
            argv += ["--filter-pdu-type", self.filter_pdu_type]
        if self.pcap_out:
            argv += ["-s", str(self.pcap_out)]
        if self.hop:
            argv.append("-o")
        if self.rssi_est:
            argv.append("--rssi-est")
        # Always JSON + quiet-text for programmatic consumers.
        argv += ["--json", "--quiet-text"]
        argv += self.extra_args
        return argv


class RxProcess:
    """Spawn btle_rx and stream parsed events."""

    def __init__(self, options: RxOptions, exe: Optional[str] = None) -> None:
        self.options = options
        self.exe = exe or find_btle_rx()
        self._proc: Optional[asyncio.subprocess.Process] = None
        # Ring buffer of recent non-JSON stderr/stdout lines (banner, libhackrf chatter)
        self.banner: collections.deque[str] = collections.deque(maxlen=64)

    @property
    def argv(self) -> list[str]:
        return self.options.to_argv(self.exe)

    async def start(self) -> None:
        if self._proc is not None:
            raise RuntimeError("RxProcess already started")
        self._proc = await asyncio.create_subprocess_exec(
            *self.argv,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )

    async def stop(self, timeout: float = 2.0) -> int:
        """Send SIGINT (matches the C handler), wait, then SIGKILL if needed."""
        if self._proc is None or self._proc.returncode is not None:
            return self._proc.returncode if self._proc else 0
        try:
            self._proc.send_signal(signal.SIGINT)
            await asyncio.wait_for(self._proc.wait(), timeout=timeout)
        except asyncio.TimeoutError:
            self._proc.kill()
            await self._proc.wait()
        return self._proc.returncode or 0

    async def stream(self) -> AsyncIterator[Event]:
        """Yield parsed Events until the subprocess exits."""
        if self._proc is None:
            await self.start()
        assert self._proc is not None and self._proc.stdout is not None

        while True:
            raw = await self._proc.stdout.readline()
            if not raw:
                break
            line = raw.decode("utf-8", errors="replace")
            evt = parse_line(line)
            if evt is None:
                # banner / libhackrf chatter / blank — keep a short tail for debugging
                stripped = line.rstrip("\n")
                if stripped:
                    self.banner.append(stripped)
                continue
            yield evt

    async def __aenter__(self) -> "RxProcess":
        await self.start()
        return self

    async def __aexit__(self, exc_type, exc, tb) -> None:
        await self.stop()


async def collect_for(
    options: RxOptions, duration_s: float, exe: Optional[str] = None
) -> list[Event]:
    """Convenience: run btle_rx for `duration_s` seconds and collect all events."""
    out: list[Event] = []
    proc = RxProcess(options, exe=exe)
    await proc.start()

    async def reader() -> None:
        async for evt in proc.stream():
            out.append(evt)

    task = asyncio.create_task(reader())
    try:
        await asyncio.sleep(duration_s)
    finally:
        await proc.stop()
        try:
            await asyncio.wait_for(task, timeout=2.0)
        except asyncio.TimeoutError:
            task.cancel()
    return out
