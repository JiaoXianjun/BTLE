"""Tiny OUI vendor lookup.

Bundles a snapshot of IEEE's OUI list as `data/oui.tsv.gz`. If the file is
missing (development checkout), returns None for every lookup — callers should
treat None as "unknown vendor" and degrade gracefully.

File format: one entry per line, tab-separated: `AABBCC\tVendor Name`.
"""

from __future__ import annotations

import functools
import gzip
from pathlib import Path
from typing import Optional


_DATA_PATH = Path(__file__).parent / "data" / "oui.tsv.gz"


@functools.lru_cache(maxsize=1)
def _table() -> dict[str, str]:
    if not _DATA_PATH.is_file():
        return {}
    table: dict[str, str] = {}
    with gzip.open(_DATA_PATH, "rt", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split("\t", 1)
            if len(parts) != 2:
                continue
            prefix, vendor = parts
            table[prefix.upper().replace(":", "").replace("-", "")] = vendor
    return table


def normalize_mac_prefix(mac: str) -> Optional[str]:
    """Return the 6-hex-char OUI prefix (uppercase) from a MAC, or None."""
    if not mac:
        return None
    clean = mac.replace(":", "").replace("-", "").upper()
    if len(clean) < 6:
        return None
    return clean[:6]


def lookup(mac: str) -> Optional[str]:
    """Return the vendor name for a MAC address, or None if unknown / missing data."""
    prefix = normalize_mac_prefix(mac)
    if prefix is None:
        return None
    return _table().get(prefix)
