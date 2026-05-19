# btle-cli

CLI + TUI front-end for the HackRF / bladeRF BTLE sniffer (`btle_rx`), with
offline pcap analysis and a typed TX plan builder.

```
┌─────────────────┐
│  btle_rx (C)    │  HackRF/bladeRF → demod → parse PDU
│  --json --filter-adva --rssi-est
└────────┬────────┘
         │ NDJSON over stdout
         │ pcap on disk
         ▼
┌─────────────────┐
│ btle_cli (Py)   │  scan / capture / analyze / tx / tui
└────────┬────────┘
         │ Typed dataclasses (pydantic) — MCP-ready
         ▼
   future: MCP server → LLM
```

## Prerequisites

1. **HackRF One** (the only board verified in v1) with [hackrf](https://github.com/greatscottgadgets/hackrf) installed.
2. **C tools built** — from the repo root:
   ```bash
   cd host && mkdir -p build && cd build
   cmake .. -DCMAKE_POLICY_VERSION_MINIMUM=3.5
   make btle_rx
   ```
3. **Python 3.11+** and this package:
   ```bash
   cd host/python/btle_cli
   python -m venv .venv && source .venv/bin/activate
   pip install -e ".[dev]"
   ```

The Python wrapper auto-locates `btle_rx` at `host/build/btle-tools/src/btle_rx`
or via `$BTLE_RX`.

## Usage

### Scan (rotate ADV channels 37/38/39)

```bash
python -m btle_cli scan --duration-s 10 --dwell-s 2
```

```
┏━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━┳━━━━━┳━━━━━━┳━━━━━━┓
┃ AdvA              ┃ Vendor       ┃  Ch ┃ RSSI ┃ Pkts ┃
┣━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━╋━━━━━╋━━━━━━╋━━━━━━┫
│ 60:0a:be:c0:ab:d0 │ Apple        │  38 │  -52 │   10 │
│ 7e:33:22:a9:c9:ab │ Samsung Elec │  38 │  -60 │    5 │
│ 20:df:b9:2e:a2:66 │ Google, Inc. │  38 │  -54 │    5 │
...
```

Add `--json` to get structured output suitable for piping to `jq` (or a future
MCP wrapper).

### Capture a specific device to a pcap

```bash
python -m btle_cli capture /tmp/iphone.pcap \
    --channel 37 --duration-s 30 \
    --filter-adva AA:BB:CC:DD:EE:FF
```

Modes:
- `--mode adv` (default): stay on ADV channels (single ch37 in v1)
- `--mode single`: any channel
- `--mode hop`: follow a connection after CONNECT_REQ (data-channel hopping)

### Analyze a pcap → summary + plots

```bash
python -m btle_cli analyze /tmp/iphone.pcap --out-dir /tmp/analysis
```

Emits `timeline.png`, `intervals.png`, `vendors.png` plus a summary on stdout.

### Transmit packets via btle_tx (typed plan)

`plan.json`:
```json
{
  "packets": [
    {"type": "iBeacon", "channel": 37, "space_ms": 100,
     "fields": {"adv_a": "010203040506", "uuid": "B9407F30F5F8466EAFF925556B57FE6D",
                "major": 8, "minor": 9, "tx_power": 197}}
  ],
  "repeat": 50
}
```

```bash
python -m btle_cli tx plan.json
```

Power users can also pass btle_tx's native `.txt` format directly.

### Interactive TUI

```bash
python -m btle_cli tui
```

Walks you through **scan → device detail → capture select → live capture →
analyze**. Keys are shown in the footer (`?` for full help, `q` to quit).

## NDJSON schema (v1)

`btle_rx --json --quiet-text` emits one of these per line. The schema is
documented in `host/btle-tools/src/btle_json.h`. Python models live in
`btle_cli.events`.

```jsonc
// pkt (ADV)
{"v":1,"t":"pkt","ts":...,"pkt":42,"ch":37,"aa":"8e89bed6",
 "crc_ok":true,"kind":"adv","pdu_type":0,"pdu_name":"ADV_IND",
 "tx_add":1,"rx_add":0,"plen":31,"adv_a":"aa:bb:cc:dd:ee:ff",
 "payload_hex":"...","rssi_est":-58}

// pkt (DATA, AdvA absent)
{"v":1,"t":"pkt","ts":...,"kind":"data","ll_pdu_type":1,
 "ll_pdu_name":"LL_DATA","nesn":0,"sn":1,"md":0,"plen":4,
 "payload_hex":"03000000","rssi_est":null,...}

// hop FSM transition
{"v":1,"t":"hop","ts":...,"event":"track_start","state_from":0,
 "state_to":1,"ch":7,"freq_mhz":2410,"aa":"60850a1b",
 "crc_init":"a77b22","interval_us":18750,"hop":5,"chm":"1fffffffff"}

// status (lifecycle)
{"v":1,"t":"status","ts":...,"event":"start","board":"HackRF",...}
```

## Gain tuning (important)

HackRF's 8-bit ADC clips when input is too strong. For BLE devices closer than
~3 m (typical RSSI ≥ -70 dBm), **default `--gain 24`** works best. Push to 32-40
only for distant / weak signals (RSSI ≤ -85 dBm). If CRC-OK ratio is < 30 %,
the first thing to try is **halving the gain**, not noise mitigation.

Hard-won example: capturing a beacon at -68 dBm with `--gain 40` → 6 pkts /
30 s / 0 CRC-OK. Same setup with `--gain 24` → 28 pkts / 15 s / 22 CRC-OK.

## `recon` — reverse-engineering helpers (token-optimized)

Higher-level wrappers around scan/capture aimed at security RE workflows and
LLM/MCP consumption. Every command emits compact JSON (`exclude_none`, top-N
truncation, hex shortened to 16 bytes) so an agent gets the verdict in one
shot without burning context.

| Command | Question it answers | Typical size |
|---|---|---|
| `recon profile <AdvA>` | "What is this device?" | ~150 tokens |
| `recon quickscan` | "What's around me?" | ~250-600 tokens (top-N) |
| `recon diff a.pcap b.pcap` | "What changed across runs?" | ~200-400 tokens |
| `recon entropy <pcap> <AdvA>` | "Which bytes are dynamic? counter or sensor?" | ~100-200 tokens |

Examples:

```bash
# Live profile of one device for 20 s
python -m btle_cli recon profile fe:f8:fd:f9:2b:c7 -d 20

# Same, but from a previously-captured pcap (no SDR needed)
python -m btle_cli recon profile fe:f8:fd:f9:2b:c7 --pcap /tmp/x.pcap

# Quick survey
python -m btle_cli recon quickscan -d 8 --top-n 10

# Find counter bytes in a target's manuf data
python -m btle_cli recon entropy /tmp/x.pcap fe:f8:fd:f9:2b:c7

# Diff a pcap before vs after a firmware update / pairing
python -m btle_cli recon diff before.pcap after.pcap
```

Protocol fingerprints recognised (no connection required):
- `ibeacon`, `apple_continuity`, `microsoft_swift_pair`, `nordic_proprietary`
- `nordic_lbs`, `nordic_uart`, `mcumgr_smp`, `eddystone`
- `apple_findmy`, `google_fast_pair`, `tile`, `dev_or_hobby_0x1337`

## Limitations

- **Single HackRF**: multi-channel concurrent capture is not supported. Scan
  rotates one channel at a time with a ~30 ms tune-latency hit.
- **RSSI is a coarse estimate**: `|I|+|Q|` over the access-address window
  mapped to a rough dB scale. Useful for sorting nearby vs. far devices, not
  for precise measurements. Disable with `--no-rssi-est` if not needed.
- **CRC errors are common in dense environments**: HackRF is a wideband SDR;
  expect noisy CRC results on busy 2.4 GHz bands.
- **TX builder coverage**: ADV_IND, iBeacon, DISCOVERY, RAW are implemented;
  other DATA-channel control PDUs (LL_*) fall back to `RAW` + hand-rolled hex.

## Development

```bash
ruff check src tests
mypy src
pytest
```

The package layout (`src/btle_cli/`):

- `events.py`, `rx_proc.py` — NDJSON parsing & subprocess wrapper
- `aggregate.py` — device records & hop FSM state from event stream
- `pcap_loader.py` — DLT 256 (BLE LL with PHDR) reader, no scapy needed
- `analyze.py` — matplotlib summaries
- `oui.py`, `vendors.py` — IEEE OUI + Bluetooth SIG company IDs (bundled)
- `tx_builder.py`, `tx_proc.py` — typed TX plans → btle_tx
- `cli.py` — Typer commands
- `tui/` — Textual screens

## MCP integration

The `recon` layer is exposed as a Model Context Protocol server so Claude Code
(or any MCP client) can drive your HackRF directly. Five tools:
`ble_quickscan`, `ble_profile`, `ble_capture_to_pcap`, `ble_diff_pcaps`,
`ble_payload_entropy` — each returns ≤ 600 tokens.

Setup (Claude Code, global):

```bash
claude mcp add --scope user --transport stdio btle-cli \
    -- "$(pwd)/.venv/bin/btle-cli-mcp"
claude mcp list | grep btle-cli   # → ✓ Connected
```

See [docs/MCP.md](docs/MCP.md) for tool reference, Claude Desktop config, and
troubleshooting.

## Programmatic use

The CLI commands are free functions returning pydantic models, so calling
them directly from Python is straightforward:

```python
from btle_cli.recon import profile, quickscan
from btle_cli.cli import capture

summary = quickscan(duration_s=10)
prof = profile(adv_a="fe:f8:fd:f9:2b:c7", duration_s=20)
```
