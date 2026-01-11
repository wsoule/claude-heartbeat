#!/bin/bash
#
# Claude Code Heartbeat Script
# Sends a minimal message to reset the 5-hour session timer
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/heartbeat.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "Heartbeat started"

# Send minimal message to Claude using haiku model
RESPONSE=$(claude --model haiku -p "only reply back with '.'" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    log "Claude response: $RESPONSE"
    log "Heartbeat completed successfully"
else
    log "ERROR: Claude command failed with exit code $EXIT_CODE"
    log "Error output: $RESPONSE"
fi

exit $EXIT_CODE
