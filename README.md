# Claude Code Heartbeat

Automatically manage Claude Code session timers by scheduling heartbeats at optimal times based on your work schedule.

## The Problem

Claude Code has a 5-hour session timer. This script ensures your sessions reset at strategic times so you have maximum coverage during your work hours.

## How It Works

Define your work blocks, and the script calculates when to send heartbeats:

**Short blocks (≤ 5 hours):** Session expires at midpoint
```
Work: 08:00-12:00 (4hrs)
  → Heartbeat at 05:00
  → Session expires at 10:00 (midpoint)
```

**Long blocks (> 5 hours):** Chained sessions for full coverage
```
Work: 09:00-17:00 (8hrs)
  → Heartbeats at 07:00 and 12:00
  → Sessions chain: 07:00-12:00, 12:00-17:00
  → Full coverage!
```

## Installation

### macOS

1. Clone or download this repository
2. Edit `config.sh` to set your work blocks:
   ```bash
   WORK_BLOCKS=("08:00-12:00" "15:00-19:00")
   ```
3. Run the installer:
   ```bash
   ./install-heartbeat.sh
   ```

The installer will:
- Calculate optimal heartbeat times
- Create a launchd job to run automatically
- Show you the schedule before activating

### Uninstall

```bash
./uninstall-heartbeat.sh
```

## Configuration

Edit `config.sh`:

```bash
# Single continuous workday
WORK_BLOCKS=("09:00-17:00")

# Split workday (morning + afternoon)
WORK_BLOCKS=("08:00-12:00" "15:00-19:00")

# Multiple short blocks
WORK_BLOCKS=("06:00-09:00" "12:00-14:00" "19:00-22:00")
```

Times are in 24-hour format.

## Files

| File | Purpose |
|------|---------|
| `heartbeat.sh` | Sends "." to Claude using haiku model |
| `config.sh` | Your work block configuration |
| `install-heartbeat.sh` | Calculates times and installs scheduler |
| `uninstall-heartbeat.sh` | Removes the scheduled job |
| `logs/heartbeat.log` | Execution log |

## Manual Testing

```bash
# Test the heartbeat manually
./heartbeat.sh

# Check logs
cat logs/heartbeat.log
```

## Requirements

- macOS (uses launchd for scheduling)
- [Claude Code CLI](https://claude.ai/code) installed and authenticated

## How the Algorithm Works

For each work block:

1. **If duration ≤ 5 hours:**
   - Calculate midpoint of block
   - Schedule heartbeat 5 hours before midpoint
   - Session expires at midpoint

2. **If duration > 5 hours:**
   - Calculate number of segments needed: `ceil(duration / 5)`
   - Work backwards from end of block
   - Chain heartbeats so sessions hand off seamlessly

## License

MIT
