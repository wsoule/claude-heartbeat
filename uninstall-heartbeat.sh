#!/bin/bash
#
# Claude Code Heartbeat Uninstaller
# Removes the launchd job and optionally cleans up logs
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_NAME="com.claude.heartbeat"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Claude Code Heartbeat Uninstaller${NC}"
echo "=================================="
echo

# Source config for LOG_DIR
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
fi

# Unload launchd job if running
if [ -f "$PLIST_PATH" ]; then
    echo "Unloading launchd job..."
    launchctl unload "$PLIST_PATH" 2>/dev/null || true

    echo "Removing plist file..."
    rm -f "$PLIST_PATH"
    echo -e "${GREEN}Launchd job removed${NC}"
else
    echo -e "${YELLOW}No launchd job found at $PLIST_PATH${NC}"
fi

echo

# Ask about logs
if [ -d "$LOG_DIR" ] && [ -n "$(ls -A "$LOG_DIR" 2>/dev/null)" ]; then
    echo -e "${YELLOW}Log files found in $LOG_DIR${NC}"
    read -p "Remove log files? (y/N): " remove_logs
    if [[ "$remove_logs" =~ ^[Yy]$ ]]; then
        rm -rf "$LOG_DIR"
        echo -e "${GREEN}Logs removed${NC}"
    else
        echo "Logs preserved"
    fi
fi

echo
echo -e "${GREEN}Uninstallation complete${NC}"
echo
echo "To reinstall: $SCRIPT_DIR/install-heartbeat.sh"
