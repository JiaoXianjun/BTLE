"""NDJSON event models matching btle_rx --json output (schema v1)."""

from __future__ import annotations

import json
from typing import Literal, Optional, Union

from pydantic import BaseModel, ConfigDict, Field, ValidationError


class _Base(BaseModel):
    model_config = ConfigDict(extra="allow")  # tolerate future schema additions

    v: int
    t: str
    ts: float


class PktEvent(_Base):
    t: Literal["pkt"]
    pkt: int
    ch: int
    aa: str
    crc_ok: bool
    kind: Literal["adv", "data"]
    plen: int
    payload_hex: str
    rssi_est: Optional[int] = None

    # ADV-only
    pdu_type: Optional[int] = None
    pdu_name: Optional[str] = None
    tx_add: Optional[int] = None
    rx_add: Optional[int] = None
    adv_a: Optional[str] = None  # "aa:bb:cc:dd:ee:ff" or None

    # DATA-only
    ll_pdu_type: Optional[int] = None
    ll_pdu_name: Optional[str] = None
    nesn: Optional[int] = None
    sn: Optional[int] = None
    md: Optional[int] = None


class HopEvent(_Base):
    t: Literal["hop"]
    event: str  # "track_start" | "chan_change" | "track_drop"
    state_from: int
    state_to: int
    ch: int
    freq_mhz: int
    aa: str
    crc_init: str
    interval_us: int
    hop: int = Field(alias="hop")
    chm: Optional[str] = None


class StatusEvent(_Base):
    t: Literal["status"]
    event: str  # "start" | "stop" | "error"
    board: str = ""
    ch: int = 0
    freq_hz: int = 0
    gain: int = 0
    lna: int = 0
    amp: int = 0
    filter_adva: Optional[str] = None
    msg: Optional[str] = None


Event = Union[PktEvent, HopEvent, StatusEvent]


def parse_line(line: str) -> Optional[Event]:
    """Parse a single NDJSON line. Returns None for blank lines, non-JSON,
    unknown event types, future schema versions we can't model, or any
    validation error. Never raises."""
    s = line.strip()
    if not s or s[0] != "{":
        return None
    try:
        obj = json.loads(s)
    except (json.JSONDecodeError, ValueError):
        return None

    t = obj.get("t")
    try:
        if t == "pkt":
            return PktEvent.model_validate(obj)
        if t == "hop":
            return HopEvent.model_validate(obj)
        if t == "status":
            return StatusEvent.model_validate(obj)
    except ValidationError:
        return None
    return None
