# MCP Integration

`btle-cli-mcp` exposes the `recon` layer of this project as **Model Context
Protocol** tools, so an LLM (e.g. Claude Code, Claude Desktop, any MCP-capable
client) can drive your HackRF One directly.

```
┌─────────────────────────┐         stdio JSON-RPC
│ Claude Code / Desktop   │ ──────────────────────────┐
└─────────────────────────┘                           │
                                                      ▼
                                       ┌─────────────────────────┐
                                       │ btle-cli-mcp (FastMCP)  │
                                       │  • ble_quickscan        │
                                       │  • ble_profile          │
                                       │  • ble_capture_to_pcap  │
                                       │  • ble_diff_pcaps       │
                                       │  • ble_payload_entropy  │
                                       └────────────┬────────────┘
                                                    │ Python imports
                                                    ▼
                                       ┌─────────────────────────┐
                                       │ btle_cli.recon          │
                                       │ → btle_rx (HackRF One)  │
                                       └─────────────────────────┘
```

## Token budget per tool

Each tool returns a single JSON object via `model_dump(exclude_none=True)`.

| Tool | Typical size | What it answers |
|---|---|---|
| `ble_quickscan` | 250-600 tokens | "What's around me?" |
| `ble_profile` | ~150 tokens | "What is this device?" |
| `ble_capture_to_pcap` | ~80 tokens | "Save a pcap" |
| `ble_diff_pcaps` | 200-400 tokens | "What changed between two pcaps?" |
| `ble_payload_entropy` | 100-200 tokens | "Which bytes vary? Counter or random?" |

## Setup (Claude Code)

### One-line install (recommended)

```bash
cd host/python/btle_cli
python -m venv .venv && source .venv/bin/activate
pip install -e .

claude mcp add --scope user --transport stdio btle-cli \
    -- "$(pwd)/.venv/bin/btle-cli-mcp"
```

`--scope user` makes the server available in every project. Use `--scope project`
to limit it to a single repo (writes a `.mcp.json` in the project root) or omit
`--scope` for local-only (current project, in `~/.claude.json`).

### Verify

```bash
claude mcp list | grep btle-cli
# → btle-cli: /path/to/.venv/bin/btle-cli-mcp  - ✓ Connected
```

Then in Claude Code, ask things like:
- *"Quickscan BLE for 8 seconds and tell me what you see"*
- *"Profile the device with AdvA fe:f8:fd:f9:2b:c7"*
- *"Find counter bytes in /tmp/raph.pcap for fe:f8:fd:f9:2b:c7"*

## Setup (Claude Desktop or other MCP clients)

Add to the client's MCP server config (Claude Desktop: `~/Library/Application
Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "btle-cli": {
      "type": "stdio",
      "command": "/absolute/path/to/host/python/btle_cli/.venv/bin/btle-cli-mcp"
    }
  }
}
```

## Tool reference

### `ble_quickscan`
```python
ble_quickscan(
    duration_s: float = 10.0,
    top_n: int = 15,
    channels: str = "37,38,39",
    dwell_s: float = 2.0,
    gain: int = 24,
) -> ScanSummary
```

Rotate-scan ADV channels and return the top-N most-active devices with
fingerprint histogram. No per-packet history. Capped at 30 devices.

### `ble_profile`
```python
ble_profile(
    adv_a: str,                # "fe:f8:fd:f9:2b:c7"
    duration_s: float = 20.0,  # ignored if pcap is set
    channel: int = 37,
    pcap: str | None = None,   # offline mode: profile from disk
    gain: int = 24,
) -> TargetProfile
```

Lock onto a specific AdvA. Returns name, vendor, fingerprint, flags, TxPower,
average advertising interval, RSSI range, PDU types observed, connectable /
scan-responsive booleans, mfg-data sample (truncated), and analyst notes.

### `ble_capture_to_pcap`
```python
ble_capture_to_pcap(
    output_path: str,
    adv_a: str | None = None,        # AdvA filter
    channel: int = 37,
    duration_s: float = 30.0,
    mode: str = "single",            # "single" | "hop"
    gain: int = 24,
) -> CaptureResult
```

Run `btle_rx` for `duration_s` seconds and save a pcap. Parent dirs are created
automatically. The pcap is in `DLT_BLUETOOTH_LE_LL_WITH_PHDR` (256) format,
opens directly in Wireshark.

### `ble_diff_pcaps`
```python
ble_diff_pcaps(pcap_a: str, pcap_b: str) -> DiffReport
```

Device-set delta, RSSI shifts ≥5 dB, byte-level payload changes (condensed to
ranges like `byte 3..5, 7, 9..10`). Lists capped at 15-20 entries.

### `ble_payload_entropy`
```python
ble_payload_entropy(pcap: str, adv_a: str) -> PayloadEntropyReport
```

Per-byte analysis of a target's manufacturer-data over the capture. Identifies:
- `static_prefix_bytes` / `static_suffix_bytes` — never change
- `changing_positions` — vary across samples
- `likely_counter_positions` — strictly monotonic
- `likely_random_positions` — high entropy, not monotonic

Useful for replay-attack design, identifying sensor channels, or fingerprinting
firmware behaviour.

## Gain tuning (important)

HackRF has an 8-bit ADC. **Default `--gain 24`** is the sweet spot for near
BLE devices. Raise to 32-40 only for distant signals (RSSI ≤ -85 dBm). If a
tool reports `crc_ok_ratio < 0.3`, halve the gain and try again before
suspecting noise.

Real example: `Raph_2BC7` at -68 dBm with `--gain 40` → 0% CRC OK; with
`--gain 24` → 80% CRC OK.

## Limitations

- **Single HackRF**: only one channel can be sniffed at a time. ADV scan
  rotates 37/38/39 with ~30 ms tune latency per switch.
- **MCP tools block while sniffing**: `ble_quickscan(duration_s=10)` takes
  10 seconds wall-clock. Long durations will exceed the MCP client's default
  request timeout — keep `duration_s` ≤ 60 s.
- **Read-only sniffer**: no GATT layer here. For active connection (read
  characteristics, subscribe to notifications) use `bleak` or `nRF Connect` —
  HackRF is a wideband SDR, not a BLE host stack.
- **Privileges**: HackRF on macOS needs no sudo; on Linux you need either a
  udev rule or `sudo`.

## Troubleshooting

```bash
# Server fails to start
btle-cli-mcp                # should hang waiting for stdio input — that's normal
# Ctrl-C to exit; if there's a traceback, install issues are at fault.

# Check Claude Code can see it
claude mcp list | grep btle-cli

# Re-register with verbose path
claude mcp remove btle-cli
claude mcp add --scope user --transport stdio btle-cli \
    -- "$(pwd)/.venv/bin/btle-cli-mcp"

# Check HackRF visible to the system
hackrf_info
```
