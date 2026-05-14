"""Subprocess wrapper for btle_tx + plan-file glue."""

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import time
from pathlib import Path
from typing import Optional


def find_btle_tx() -> str:
    env = os.environ.get("BTLE_TX")
    if env and Path(env).is_file():
        return env
    here = Path(__file__).resolve()
    candidate = here.parents[4] / "build" / "btle-tools" / "src" / "btle_tx"
    if candidate.is_file():
        return str(candidate)
    on_path = shutil.which("btle_tx")
    if on_path:
        return on_path
    raise FileNotFoundError(
        "btle_tx not found. Build the C tools or set BTLE_TX=/path/to/btle_tx."
    )


def tx(plan_file: Path, repeat: int = 1, gain: int = 0):
    """Run btle_tx on either a typed plan (.json/.yaml — assembled to packets.txt)
    or a raw .txt file already in btle_tx's native format.

    Returns a TxResult (defined in btle_cli.cli) so CLI & MCP layers share the
    same dataclass.
    """
    from btle_cli.cli import TxResult  # local import to avoid circular dep

    plan_path = Path(plan_file)
    txt_path: Path
    cleanup: Optional[Path] = None

    if plan_path.suffix.lower() == ".txt":
        # User-supplied raw file — pass straight through.
        txt_path = plan_path
    else:
        from btle_cli.tx_builder import load_plan

        plan = load_plan(plan_path)
        if repeat > 1 and plan.repeat == 1:
            plan.repeat = repeat
        tmp = tempfile.NamedTemporaryFile(
            mode="w", suffix=".txt", prefix="btle_tx_plan_", delete=False, encoding="utf-8"
        )
        tmp.write(plan.to_packets_txt())
        tmp.close()
        txt_path = Path(tmp.name)
        cleanup = txt_path

    exe = find_btle_tx()
    argv = [exe, str(txt_path)]
    started = time.time()
    try:
        proc = subprocess.run(argv, capture_output=True, text=True, check=False)
        elapsed = time.time() - started
        # Estimate "sent_count" from stdout — btle_tx prints "tx ... pkt X" lines.
        # Be generous: count lines that look like packet send confirmations.
        sent = sum(1 for line in proc.stdout.splitlines() if "tx " in line.lower() and "pkt" in line.lower())
        stderr_tail = "\n".join((proc.stderr or "").splitlines()[-10:])
        return TxResult(
            sent_count=sent,
            duration_s=elapsed,
            returncode=proc.returncode,
            stderr_tail=stderr_tail,
        )
    finally:
        if cleanup is not None:
            try:
                cleanup.unlink()
            except OSError:
                pass
