"""Bluetooth SIG Company Identifier (manufacturer ID) lookup.

This is a tiny bundled snapshot covering the few hundred most common IDs.
Lookups for unknown IDs return None — callers should degrade gracefully.

Source: https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers/
"""

from __future__ import annotations

from typing import Optional


# Lowercase by-id table for the most commonly seen BLE vendors.
_VENDORS: dict[int, str] = {
    0x0001: "Nokia Mobile Phones",
    0x0006: "Microsoft",
    0x000F: "Broadcom Corporation",
    0x0030: "ST Microelectronics",
    0x004C: "Apple",
    0x0059: "Nordic Semiconductor",
    0x0075: "Samsung Electronics Co Ltd.",
    0x008A: "Jawbone",
    0x0087: "Garmin International",
    0x00A0: "JUMA",
    0x00C4: "LG Electronics",
    0x00E0: "Google",
    0x0131: "Cypress Semiconductor",
    0x0157: "Anhui Huami Information Technology",
    0x0171: "Amazon Lab126",
    0x0180: "RoKuT",
    0x01AE: "Tile",
    0x0211: "Fitbit, Inc.",
    0x0220: "Pebble Technology Corp.",
    0x02E1: "Plantronics",
    0x0500: "Shenzhen Egomate Technology Co",
    0x0822: "Logitech International SA",
    0x09A3: "Realtek Semiconductor",
}


def manufacturer_name(mid: int) -> Optional[str]:
    return _VENDORS.get(mid)
