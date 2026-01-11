#!/bin/bash
#
# Claude Code Heartbeat Configuration
#
# Define your work blocks below. The install script will calculate
# optimal heartbeat times based on these blocks.
#
# Format: "HH:MM-HH:MM" (24-hour format)
#
# Examples:
#   - Split workday: ("08:00-12:00" "15:00-19:00")
#   - Standard 9-to-5: ("09:00-17:00")
#   - Single morning block: ("08:00-12:00")
#

WORK_BLOCKS=("08:00-12:00" "15:00-19:00")

# Log directory (relative to script location)
LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logs"
