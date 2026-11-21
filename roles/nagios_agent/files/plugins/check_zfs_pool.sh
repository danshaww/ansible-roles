#!/bin/bash

POOL="$1"

if [ -z "$POOL" ]; then
    echo "UNKNOWN - Usage: check_zfs_pool.sh <pool-name>"
    exit 3
fi

# Check if pool exists
if ! zpool list "$POOL" >/dev/null 2>&1; then
    echo "CRITICAL - ZFS pool '$POOL' not found"
    exit 2
fi

# Get pool health
HEALTH=$(zpool list -H -o health "$POOL" 2>/dev/null)

case "$HEALTH" in
    ONLINE)
        echo "OK - ZFS pool '$POOL' is ONLINE"
        exit 0
        ;;
    DEGRADED)
        echo "WARNING - ZFS pool '$POOL' is DEGRADED"
        exit 1
        ;;
    FAULTED|OFFLINE|UNAVAIL|REMOVED)
        echo "CRITICAL - ZFS pool '$POOL' state: $HEALTH"
        exit 2
        ;;
    *)
        echo "UNKNOWN - ZFS pool '$POOL' state: $HEALTH"
        exit 3
        ;;
esac
