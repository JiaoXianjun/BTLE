"""Golden + error tolerance tests for events.parse_line."""

from __future__ import annotations

import pytest

from btle_cli.events import HopEvent, PktEvent, StatusEvent, parse_line


GOLDEN_ADV = (
    '{"v":1,"t":"pkt","ts":1715680000.123456,"pkt":42,"ch":37,'
    '"aa":"8e89bed6","crc_ok":true,"kind":"adv","pdu_type":0,'
    '"pdu_name":"ADV_IND","tx_add":1,"rx_add":0,"plen":31,'
    '"adv_a":"aa:bb:cc:dd:ee:ff","payload_hex":"02011a","rssi_est":-58}'
)

GOLDEN_DATA = (
    '{"v":1,"t":"pkt","ts":1715680001.5,"pkt":99,"ch":12,'
    '"aa":"60850a1b","crc_ok":true,"kind":"data","ll_pdu_type":1,'
    '"ll_pdu_name":"LL_DATA","nesn":0,"sn":1,"md":0,"plen":4,'
    '"payload_hex":"03000000","rssi_est":null}'
)

GOLDEN_HOP = (
    '{"v":1,"t":"hop","ts":1715680002.0,"event":"track_start",'
    '"state_from":0,"state_to":1,"ch":7,"freq_mhz":2410,'
    '"aa":"60850a1b","crc_init":"a77b22","interval_us":18750,'
    '"hop":5,"chm":"1fffffffff"}'
)

GOLDEN_STATUS = (
    '{"v":1,"t":"status","ts":1715680000.0,"event":"start",'
    '"board":"HackRF","ch":37,"freq_hz":2402000000,"gain":40,'
    '"lna":32,"amp":0,"filter_adva":null,"msg":null}'
)


def test_parse_adv_pkt() -> None:
    evt = parse_line(GOLDEN_ADV)
    assert isinstance(evt, PktEvent)
    assert evt.kind == "adv"
    assert evt.adv_a == "aa:bb:cc:dd:ee:ff"
    assert evt.pdu_name == "ADV_IND"
    assert evt.rssi_est == -58
    assert evt.crc_ok is True


def test_parse_data_pkt() -> None:
    evt = parse_line(GOLDEN_DATA)
    assert isinstance(evt, PktEvent)
    assert evt.kind == "data"
    assert evt.ll_pdu_name == "LL_DATA"
    assert evt.rssi_est is None
    assert evt.adv_a is None


def test_parse_hop() -> None:
    evt = parse_line(GOLDEN_HOP)
    assert isinstance(evt, HopEvent)
    assert evt.event == "track_start"
    assert evt.chm == "1fffffffff"
    assert evt.hop == 5


def test_parse_status() -> None:
    evt = parse_line(GOLDEN_STATUS)
    assert isinstance(evt, StatusEvent)
    assert evt.event == "start"
    assert evt.board == "HackRF"
    assert evt.filter_adva is None


@pytest.mark.parametrize(
    "line",
    [
        "",
        "\n",
        "not json at all",
        "Setting VGA gain to 40",  # hackrf banner
        "{invalid json",
        "{}",  # no t/v fields
        '{"v":1,"t":"unknown_type","ts":0}',
        '{"v":1,"t":"pkt"}',  # missing required fields
    ],
)
def test_parse_garbage_returns_none(line: str) -> None:
    assert parse_line(line) is None


def test_future_v2_does_not_crash() -> None:
    # Future schema with new top-level field; we accept thanks to extra="allow"
    future = (
        '{"v":2,"t":"pkt","ts":1715680000.0,"pkt":1,"ch":37,'
        '"aa":"8e89bed6","crc_ok":true,"kind":"adv","pdu_type":0,'
        '"pdu_name":"ADV_IND","tx_add":1,"rx_add":0,"plen":6,'
        '"adv_a":"aa:bb:cc:dd:ee:ff","payload_hex":"010203","rssi_est":null,'
        '"new_field_in_v2":"hi"}'
    )
    evt = parse_line(future)
    assert isinstance(evt, PktEvent)
    assert evt.v == 2
