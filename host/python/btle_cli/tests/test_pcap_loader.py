"""Test pcap_loader against a known-good btle_rx pcap captured earlier."""

from __future__ import annotations

import os
from pathlib import Path

import pytest

from btle_cli.aggregate import ScanAggregator, parse_ad_structures
from btle_cli.pcap_loader import DLT_BLUETOOTH_LE_LL_WITH_PHDR, load


REAL_PCAP = Path("/tmp/btle_capture.pcap")


@pytest.mark.skipif(not REAL_PCAP.exists(), reason="real capture not present")
def test_load_real_capture() -> None:
    cap = load(REAL_PCAP)
    assert cap.linktype == DLT_BLUETOOTH_LE_LL_WITH_PHDR
    assert len(cap.packets) > 0
    # at least one ADV channel packet with an AdvA
    have_adv_a = [p for p in cap.packets if p.adv_a is not None]
    assert len(have_adv_a) > 0
    # channels should be ADV
    for p in cap.packets[:5]:
        assert p.channel in (37, 38, 39)


def test_parse_ad_structures_minimal() -> None:
    # AdvA (6) + Flags AD (3 bytes: 02 01 06) + name AD (Hi)
    # Encoded as payload_hex *with* AdvA prefix (parse_ad_structures strips it)
    hex_str = "010203040506" + "020106" + "030948" + "69"  # name "Hi" with length 3
    parsed = parse_ad_structures(hex_str)
    assert parsed.flags == 0x06
    assert parsed.local_name == "Hi"


def test_scan_aggregator_basic() -> None:
    from btle_cli.events import PktEvent

    agg = ScanAggregator()
    e1 = PktEvent(
        v=1, t="pkt", ts=1000.0, pkt=1, ch=37, aa="8e89bed6",
        crc_ok=True, kind="adv", pdu_type=0, pdu_name="ADV_IND",
        tx_add=1, rx_add=0, plen=12,
        adv_a="aa:bb:cc:dd:ee:01",
        payload_hex="010203040506" + "020106" + "030948" + "69",
        rssi_est=-50,
    )
    e2 = e1.model_copy(update={"ts": 1000.1, "pkt": 2})
    agg.update(e1)
    agg.update(e2)
    snap = agg.snapshot()
    assert len(snap) == 1
    rec = snap[0]
    assert rec.adv_a == "aa:bb:cc:dd:ee:01"
    assert rec.pkt_count == 2
    assert rec.last_rssi == -50
    assert rec.parsed_ad.local_name == "Hi"
    assert len(rec.advert_intervals_ms) == 1  # one delta computed
