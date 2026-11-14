#!/bin/bash

DISK="$1"

if [ -z "$DISK" ]; then
    echo "UNKNOWN - Usage: check_nvme.sh <nvme-device>"
    exit 3
fi

# Check device exists
if [ ! -b "$DISK" ]; then
    echo "CRITICAL - NVMe device '$DISK' not found"
    exit 2
fi

# Query NVMe health
INFO=$(nvme smart-log "$DISK" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "CRITICAL - Unable to read NVMe SMART log for '$DISK'"
    exit 2
fi

# Extract fields
TEMP=$(echo "$INFO" | grep -i "temperature" | awk '{print $2}')
MEDIA_ERR=$(echo "$INFO" | grep -i "media_errors" | awk '{print $3}')
CRIT_WARN=$(echo "$INFO" | grep -i "critical_warning" | awk '{print $3}')

# Evaluate health
if [ "$CRIT_WARN" != "0x00" ]; then
    echo "CRITICAL - NVMe critical warning on $DISK (code: $CRIT_WARN)"
    exit 2
fi

if [ "$MEDIA_ERR" -gt 0 ]; then
    echo "CRITICAL - NVMe media errors detected on $DISK ($MEDIA_ERR errors)"
    exit 2
fi

# Temperature thresholds (customisable)
WARN_TEMP=60
CRIT_TEMP=70

if [ "$TEMP" -ge "$CRIT_TEMP" ]; then
    echo "CRITICAL - NVMe temperature $TEMP°C on $DISK"
    exit 2
fi

if [ "$TEMP" -ge "$WARN_TEMP" ]; then
    echo "WARNING - NVMe temperature $TEMP°C on $DISK"
    exit 1
fi

echo "OK - NVMe '$DISK' healthy | temp=${TEMP}C media_errors=${MEDIA_ERR}"
exit 0
