"""Verify TX builder produces lines that match the btle_tx README examples."""

from __future__ import annotations

import json
from pathlib import Path

from btle_cli.tx_builder import (
    AdvInd,
    Discovery,
    IBeacon,
    Raw,
    TxPlan,
    load_plan,
)


def test_iBeacon_serialisation_matches_readme() -> None:
    p = IBeacon(
        channel=37,
        adv_a="010203040506",
        uuid="B9407F30F5F8466EAFF925556B57FE6D",
        major=0x0008,
        minor=0x0009,
        tx_power=0xC5,
        space_ms=100,
    )
    line = p.to_packets_txt_line()
    # The README shows:
    # 37-iBeacon-AdvA-010203040506-UUID-B9407F30F5F8466EAFF925556B57FE6D-Major-0008-Minor-0009-TxPower-C5-Space-100
    assert line == (
        "37-iBeacon-AdvA-010203040506-UUID-b9407f30f5f8466eaff925556b57fe6d-"
        "Major-0008-Minor-0009-TxPower-c5-Space-100"
    )


def test_advind_with_data() -> None:
    p = AdvInd(
        channel=37,
        adv_a="01:02:03:04:05:06",
        tx_add=1,
        rx_add=0,
        adv_data_hex="00112233445566778899AABBCCDDEEFF",
    )
    line = p.to_packets_txt_line()
    assert line == (
        "37-ADV_IND-TxAdd-1-RxAdd-0-AdvA-010203040506-AdvData-"
        "00112233445566778899aabbccddeeff"
    )


def test_discovery_with_localname_and_services() -> None:
    p = Discovery(
        channel=37,
        adv_a="010203040506",
        local_name="CA",   # 2 chars -> name_len = 3 = 0x03 -> LOCAL_NAME03
        services_16=["180D", "1810"],
        manuf_data_hex="0001FF",
        conn_interval=0x0006,
        flags=0x02,
        tx_power=0x03,
    )
    line = p.to_packets_txt_line()
    assert "LOCAL_NAME03-CA" in line
    assert "SERVICE03-180d1810" in line
    assert "MANUF_DATA-0001ff" in line
    assert "CONN_INTERVAL-0006" in line


def test_raw_packet() -> None:
    p = Raw(channel=37, raw_hex="aad6be898e8dc3ce")
    assert p.to_packets_txt_line() == "37-RAW-aad6be898e8dc3ce"


def test_plan_serialisation_and_load(tmp_path: Path) -> None:
    plan = TxPlan(
        packets=[
            IBeacon(channel=37, adv_a="010203040506", space_ms=100),
            AdvInd(channel=38, adv_a="010203040506", adv_data_hex="aa"),
        ],
        repeat=10,
    )
    text = plan.to_packets_txt()
    assert "r10" in text
    assert "37-iBeacon" in text
    assert "38-ADV_IND" in text

    # Round-trip via JSON
    plan_json = {
        "packets": [
            {"type": "iBeacon", "channel": 37, "fields": {"adv_a": "010203040506"}, "space_ms": 100},
            {"type": "AdvInd", "channel": 38, "fields": {"adv_a": "010203040506", "adv_data_hex": "aa"}},
        ],
        "repeat": 10,
    }
    p = tmp_path / "plan.json"
    p.write_text(json.dumps(plan_json), encoding="utf-8")
    loaded = load_plan(p)
    assert loaded.repeat == 10
    assert len(loaded.packets) == 2
    assert loaded.packets[0].to_packets_txt_line().startswith("37-iBeacon")
