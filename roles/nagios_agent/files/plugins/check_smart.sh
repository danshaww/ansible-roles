#!/bin/bash

DISK="$1"

if [ -z "$DISK" ]; then
    echo "UNKNOWN - Usage: check_smart.sh <disk>"
    exit 3
fi

# Check if disk exists
if [ ! -b "$DISK" ]; then
    echo "CRITICAL - Disk '$DISK' not found"
    exit 2
fi

# Check SMART support
SMART_OK=$(smartctl -i "$DISK" 2>/dev/null | grep -i "SMART support is: Enabled")
if [ -z "$SMART_OK" ]; then
    echo "CRITICAL - SMART not enabled on '$DISK'"
    exit 2
fi

# Get SMART health
HEALTH=$(smartctl -H "$DISK" 2>/dev/null | grep -i "SMART overall-health" | awk -F: '{print $2}' | xargs)

case "$HEALTH" in
    PASSED)
        echo "OK - SMART health PASSED for $DISK"
        exit 0
        ;;
    FAILED)
        echo "CRITICAL - SMART health FAILED for $DISK"
        exit 2
        ;;
    *)
        echo "UNKNOWN - SMART health state for $DISK: $HEALTH"
        exit 3
        ;;
esac
