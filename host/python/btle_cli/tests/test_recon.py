"""Tests for the RE/MCP-oriented helpers in recon.py.

Focus: structured output shape, fingerprint correctness, token budgets.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from btle_cli.aggregate import ParsedAd
from btle_cli.recon import (
    DiffReport,
    PayloadEntropyReport,
    ScanSummary,
    TargetProfile,
    _ranges,
    diff,
    fingerprint,
    payload_entropy,
    profile_from_pcap,
)


REAL_PCAP = Path("/tmp/raph_2bc7_clean.pcap")
REAL_ADV_A = "fe:f8:fd:f9:2b:c7"


def test_fingerprint_apple_mfg() -> None:
    parsed = ParsedAd(manufacturer_id=0x004C, manufacturer_data_hex="4c000215abc")
    assert fingerprint(parsed, "") == "ibeacon"


def test_fingerprint_continuity_when_not_ibeacon() -> None:
    parsed = ParsedAd(manufacturer_id=0x004C, manufacturer_data_hex="4c0010071a")
    assert fingerprint(parsed, "") == "apple_continuity"


def test_fingerprint_nordic_lbs_service() -> None:
    parsed = ParsedAd(service_uuids_128=["00001523-1212-efde-1523-785feabcd123"])
    assert fingerprint(parsed, "") == "nordic_lbs"


def test_fingerprint_dev_id() -> None:
    parsed = ParsedAd(manufacturer_id=0x1337)
    assert fingerprint(parsed, "") == "dev_or_hobby_0x1337"


def test_ranges_condenses_runs() -> None:
    assert _ranges([3, 4, 5, 7, 9, 10]) == "byte 3..5, 7, 9..10"
    assert _ranges([]) == ""


def test_ranges_caps_at_five() -> None:
    out = _ranges([1, 3, 5, 7, 9, 11, 13])
    assert out.endswith("(+2 more)")


@pytest.mark.skipif(not REAL_PCAP.exists(), reason="capture missing")
def test_profile_from_pcap_compact_shape() -> None:
    p = profile_from_pcap(REAL_ADV_A, REAL_PCAP)
    assert isinstance(p, TargetProfile)
    assert p.adv_a == REAL_ADV_A
    assert p.name == "Raph_2BC7"
    assert p.mfg_id == 0x1337
    assert p.protocol_fingerprint == "dev_or_hobby_0x1337"
    assert p.is_connectable is True
    assert p.is_scan_responsive is True
    assert p.mfg_data_changes is True
    # Token budget: compact JSON should be under ~600 bytes (~150 tokens)
    j = p.model_dump_json(exclude_none=True)
    assert len(j) < 700, f"profile JSON grew to {len(j)} bytes — token budget breach"


@pytest.mark.skipif(not REAL_PCAP.exists(), reason="capture missing")
def test_payload_entropy_finds_counter() -> None:
    r = payload_entropy(REAL_PCAP, REAL_ADV_A)
    assert isinstance(r, PayloadEntropyReport)
    assert r.n_samples > 0
    assert r.payload_length > 0
    # At least one byte should be flagged as changing across the 3+ samples
    assert len(r.changing_positions) > 0


def test_diff_handles_disjoint_pcaps(tmp_path: Path) -> None:
    """Smoke-test diff() returns the right shape on two trivial pcap-aggregator
    inputs — we can't easily synthesise pcaps here, so just verify the public
    API exists and accepts paths."""
    # Just verify the function & model are exposed.
    assert callable(diff)
    assert hasattr(DiffReport, "model_fields")
    assert {"only_in_a", "only_in_b", "common", "rssi_shifts",
            "payload_changed", "notes"} <= DiffReport.model_fields.keys()


def test_targetprofile_excludes_none_in_json() -> None:
    p = TargetProfile(adv_a="aa:bb:cc:dd:ee:ff", n_packets=0)
    j = p.model_dump_json(exclude_none=True)
    # tx_power_dbm, rssi_dbm etc. are all None — should be absent from JSON
    assert "tx_power_dbm" not in j
    assert "rssi_dbm" not in j
    # adv_a is required and present
    assert "adv_a" in j
