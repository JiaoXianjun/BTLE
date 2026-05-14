"""Typed builders for btle_tx packets.txt entries.

Each Packet subclass corresponds to a packet_type understood by btle_tx and
knows how to serialise itself as one packets.txt line. A TxPlan groups packets
with an optional repeat count.

Plan files may be JSON with the schema:
    {
      "packets": [
        {"type": "iBeacon", "channel": 37, "fields": {...}, "space_ms": 100},
        ...
      ],
      "repeat": 100
    }

or YAML, or — for power users — a raw .txt file passed straight to btle_tx.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, ClassVar, Literal


# ---------------- helpers ----------------


def _hex_no_dash(s: str) -> str:
    return s.replace(":", "").replace("-", "").lower()


def _q(value: Any) -> str:
    """Sanitise a field value: replace spaces (forbidden in CLI form per README)."""
    return str(value).replace(" ", "/").replace("-", "_")


# ---------------- packet base ----------------


@dataclass
class Packet:
    channel: int
    space_ms: int = 0  # 0 = no Space- suffix
    packet_type: ClassVar[str] = "RAW"

    def fields(self) -> list[tuple[str, str]]:
        """Override in subclasses to produce ordered (name, value) pairs.
        Names that end with a digit (e.g. LOCAL_NAME09) follow btle_tx convention.
        Empty name means "value-only" (used by Service03-XXX etc.)."""
        return []

    def to_packets_txt_line(self) -> str:
        parts = [str(self.channel), self.packet_type]
        for k, v in self.fields():
            if k:
                parts += [k, _q(v)]
            else:
                parts.append(_q(v))
        if self.space_ms:
            parts += ["Space", str(self.space_ms)]
        return "-".join(parts)


# ---------------- common ADV channel packets ----------------


@dataclass
class AdvInd(Packet):
    adv_a: str = "010203040506"
    tx_add: int = 1
    rx_add: int = 0
    adv_data_hex: str = ""
    packet_type: ClassVar[str] = "ADV_IND"

    def fields(self) -> list[tuple[str, str]]:
        return [
            ("TxAdd", self.tx_add),
            ("RxAdd", self.rx_add),
            ("AdvA", _hex_no_dash(self.adv_a)),
            ("AdvData", _hex_no_dash(self.adv_data_hex)),
        ]


@dataclass
class IBeacon(Packet):
    adv_a: str = "010203040506"
    uuid: str = "B9407F30F5F8466EAFF925556B57FE6D"
    major: int = 0x0008
    minor: int = 0x0009
    tx_power: int = 0xC5
    packet_type: ClassVar[str] = "iBeacon"

    def fields(self) -> list[tuple[str, str]]:
        return [
            ("AdvA", _hex_no_dash(self.adv_a)),
            ("UUID", _hex_no_dash(self.uuid)),
            ("Major", f"{self.major:04x}"),
            ("Minor", f"{self.minor:04x}"),
            ("TxPower", f"{self.tx_power:02x}"),
        ]


@dataclass
class Discovery(Packet):
    """High-level convenience: assembles a discoverable broadcaster.

    All optional fields default to "omit". Set just what you need.
    """
    adv_a: str = "010203040506"
    tx_add: int = 1
    rx_add: int = 0
    flags: int | None = 0x06
    local_name: str | None = None
    tx_power: int | None = None
    services_16: list[str] = field(default_factory=list)        # ["180D", "1810"]
    service_data_16: tuple[str, str] | None = None              # ("180D", "40")
    manuf_data_hex: str | None = None                            # "0001FF..."
    conn_interval: int | None = None
    packet_type: ClassVar[str] = "DISCOVERY"

    def fields(self) -> list[tuple[str, str]]:
        out: list[tuple[str, str]] = [
            ("TxAdd", self.tx_add),
            ("RxAdd", self.rx_add),
            ("AdvA", _hex_no_dash(self.adv_a)),
        ]
        if self.flags is not None:
            out.append(("FLAGS", f"{self.flags:02x}"))
        if self.local_name:
            name_len = len(self.local_name) + 1  # plus 1-byte type
            out.append((f"LOCAL_NAME{name_len:02x}", self.local_name))
        if self.tx_power is not None:
            out.append(("TXPOWER", f"{self.tx_power:02x}"))
        if self.services_16:
            joined = "".join(_hex_no_dash(u) for u in self.services_16)
            out.append(("SERVICE03", joined))
        if self.service_data_16:
            uuid16, data = self.service_data_16
            out.append(("SERVICE_DATA", _hex_no_dash(uuid16) + _hex_no_dash(data)))
        if self.manuf_data_hex:
            out.append(("MANUF_DATA", _hex_no_dash(self.manuf_data_hex)))
        if self.conn_interval is not None:
            out.append(("CONN_INTERVAL", f"{self.conn_interval:04x}"))
        return out


@dataclass
class Raw(Packet):
    raw_hex: str = ""
    packet_type: ClassVar[str] = "RAW"

    def to_packets_txt_line(self) -> str:
        parts = [str(self.channel), self.packet_type, _hex_no_dash(self.raw_hex)]
        if self.space_ms:
            parts += ["Space", str(self.space_ms)]
        return "-".join(parts)


# ---------------- plan ----------------


@dataclass
class TxPlan:
    packets: list[Packet] = field(default_factory=list)
    repeat: int = 1  # 1 = play once; e.g. 30 = `r30` appended

    def to_packets_txt(self) -> str:
        lines = ["# generated by btle_cli.tx_builder"]
        for p in self.packets:
            lines.append(p.to_packets_txt_line())
        if self.repeat > 1:
            lines.append(f"r{self.repeat}")
        return "\n".join(lines) + "\n"


# ---------------- plan loader (JSON; YAML support is optional) ----------------


_TYPE_MAP: dict[str, type[Packet]] = {
    "AdvInd": AdvInd,
    "ADV_IND": AdvInd,
    "IBeacon": IBeacon,
    "iBeacon": IBeacon,
    "Discovery": Discovery,
    "DISCOVERY": Discovery,
    "Raw": Raw,
    "RAW": Raw,
}


def load_plan(plan_path: Path) -> TxPlan:
    """Load a TxPlan from JSON. (YAML is optional and only attempted if PyYAML
    is installed; plain .txt files bypass this loader — see tx_proc.tx())."""
    text = Path(plan_path).read_text(encoding="utf-8")
    suffix = Path(plan_path).suffix.lower()
    if suffix in (".yaml", ".yml"):
        try:
            import yaml  # type: ignore[import-untyped]
        except ImportError as e:
            raise RuntimeError(
                "PyYAML not installed; use a .json plan file or `pip install pyyaml`."
            ) from e
        data = yaml.safe_load(text)
    else:
        data = json.loads(text)

    if not isinstance(data, dict) or "packets" not in data:
        raise ValueError(f"{plan_path}: plan must be an object with a 'packets' array")

    pkts: list[Packet] = []
    for entry in data["packets"]:
        if not isinstance(entry, dict):
            raise ValueError(f"{plan_path}: each packet must be an object")
        ptype = entry.get("type", "AdvInd")
        cls = _TYPE_MAP.get(ptype)
        if cls is None:
            raise ValueError(f"{plan_path}: unknown packet type {ptype!r}")
        channel = int(entry.get("channel", 37))
        space_ms = int(entry.get("space_ms", 0))
        fields = entry.get("fields", {}) or {}
        try:
            pkts.append(cls(channel=channel, space_ms=space_ms, **fields))
        except TypeError as e:
            raise ValueError(f"{plan_path}: bad fields for {ptype}: {e}") from e
    repeat = int(data.get("repeat", 1))
    return TxPlan(packets=pkts, repeat=repeat)
