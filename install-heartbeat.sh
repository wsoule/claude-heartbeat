#!/bin/bash
#
# Claude Code Heartbeat Installer
# Calculates optimal heartbeat times and sets up launchd scheduler
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_NAME="com.claude.heartbeat"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Claude Code Heartbeat Installer${NC}"
echo "================================"
echo

# Source config
if [ ! -f "$SCRIPT_DIR/config.sh" ]; then
    echo -e "${RED}Error: config.sh not found${NC}"
    echo "Please create config.sh with your WORK_BLOCKS array"
    exit 1
fi

source "$SCRIPT_DIR/config.sh"

if [ ${#WORK_BLOCKS[@]} -eq 0 ]; then
    echo -e "${RED}Error: No work blocks defined in config.sh${NC}"
    exit 1
fi

# Function to convert HH:MM to minutes since midnight
time_to_minutes() {
    local time=$1
    local hours=${time%%:*}
    local mins=${time##*:}
    # Remove leading zeros
    hours=$((10#$hours))
    mins=$((10#$mins))
    echo $((hours * 60 + mins))
}

# Function to convert minutes since midnight to HH:MM
minutes_to_time() {
    local total_mins=$1
    # Handle negative values (wrap to previous day)
    while [ $total_mins -lt 0 ]; do
        total_mins=$((total_mins + 1440))
    done
    # Handle values >= 24 hours
    total_mins=$((total_mins % 1440))
    printf "%02d:%02d" $((total_mins / 60)) $((total_mins % 60))
}

# Function to calculate heartbeat times for a work block
calculate_heartbeats() {
    local block=$1
    local start_time=${block%%-*}
    local end_time=${block##*-}

    local start_mins=$(time_to_minutes "$start_time")
    local end_mins=$(time_to_minutes "$end_time")

    # Handle overnight blocks (end < start)
    if [ $end_mins -le $start_mins ]; then
        end_mins=$((end_mins + 1440))
    fi

    local duration=$((end_mins - start_mins))
    local session_length=300  # 5 hours in minutes

    local heartbeats=()

    if [ $duration -le $session_length ]; then
        # Short block: midpoint strategy
        local midpoint=$((start_mins + duration / 2))
        local heartbeat=$((midpoint - session_length))
        heartbeats+=("$(minutes_to_time $heartbeat)")
        echo -e "  ${YELLOW}Block $block (${duration} mins):${NC}"
        echo "    Strategy: Midpoint expiry"
        echo "    Midpoint: $(minutes_to_time $midpoint)"
        echo "    Heartbeat: ${heartbeats[-1]} -> expires $(minutes_to_time $midpoint)"
    else
        # Long block: chain strategy
        local num_segments=$(( (duration + session_length - 1) / session_length ))
        echo -e "  ${YELLOW}Block $block (${duration} mins):${NC}"
        echo "    Strategy: Chained sessions ($num_segments segments)"

        # Work backwards from end
        local expire_time=$end_mins
        for ((i=num_segments; i>=1; i--)); do
            local heartbeat=$((expire_time - session_length))
            heartbeats+=("$(minutes_to_time $heartbeat)")
            echo "    Segment $i: Heartbeat $(minutes_to_time $heartbeat) -> expires $(minutes_to_time $expire_time)"
            expire_time=$heartbeat
        done
    fi

    # Return heartbeats (space-separated)
    echo "${heartbeats[@]}"
}

echo "Analyzing work blocks..."
echo

ALL_HEARTBEATS=()

for block in "${WORK_BLOCKS[@]}"; do
    # Capture the heartbeat times from calculate_heartbeats
    # The function outputs info to stderr, heartbeats to stdout
    output=$(calculate_heartbeats "$block" 2>&1)

    # Parse output - display lines and collect heartbeat times
    while IFS= read -r line; do
        if [[ "$line" =~ ^[0-9]{2}:[0-9]{2} ]]; then
            # This is a heartbeat time (space-separated list)
            for time in $line; do
                ALL_HEARTBEATS+=("$time")
            done
        else
            # Display line
            echo "$line"
        fi
    done <<< "$output"
done

# Remove duplicates and sort
IFS=$'\n' UNIQUE_HEARTBEATS=($(printf "%s\n" "${ALL_HEARTBEATS[@]}" | sort -u))
unset IFS

echo
echo -e "${GREEN}Scheduled heartbeat times:${NC}"
for time in "${UNIQUE_HEARTBEATS[@]}"; do
    echo "  - $time"
done
echo

# Generate launchd plist
echo "Generating launchd configuration..."

CALENDAR_INTERVALS=""
for time in "${UNIQUE_HEARTBEATS[@]}"; do
    hour=${time%%:*}
    minute=${time##*:}
    # Remove leading zeros for plist
    hour=$((10#$hour))
    minute=$((10#$minute))
    CALENDAR_INTERVALS+="        <dict>
            <key>Hour</key>
            <integer>$hour</integer>
            <key>Minute</key>
            <integer>$minute</integer>
        </dict>
"
done

cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$SCRIPT_DIR/heartbeat.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <array>
$CALENDAR_INTERVALS    </array>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/launchd-stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/launchd-stderr.log</string>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
EOF

# Make heartbeat.sh executable
chmod +x "$SCRIPT_DIR/heartbeat.sh"

# Create log directory
mkdir -p "$LOG_DIR"

# Unload existing job if present
if launchctl list | grep -q "$PLIST_NAME"; then
    echo "Unloading existing job..."
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
fi

# Load new job
echo "Loading launchd job..."
launchctl load "$PLIST_PATH"

echo
echo -e "${GREEN}Installation complete!${NC}"
echo
echo "Heartbeat will run at: ${UNIQUE_HEARTBEATS[*]}"
echo "Logs: $LOG_DIR/heartbeat.log"
echo "Plist: $PLIST_PATH"
echo
echo "To test manually: $SCRIPT_DIR/heartbeat.sh"
echo "To uninstall: $SCRIPT_DIR/uninstall-heartbeat.sh"
