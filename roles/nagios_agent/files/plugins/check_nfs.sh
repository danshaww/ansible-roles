#!/bin/bash

MOUNTPOINT="$1"

if [ -z "$MOUNTPOINT" ]; then
    echo "UNKNOWN - Usage: check_nfs_mount.sh <mountpoint>"
    exit 3
fi

# Check if mountpoint exists
if [ ! -d "$MOUNTPOINT" ]; then
    echo "CRITICAL - Mountpoint '$MOUNTPOINT' does not exist"
    exit 2
fi

# Check if it's mounted and specifically NFS
if mountpoint -q "$MOUNTPOINT"; then
    # Check filesystem type
    FSTYPE=$(stat -f -c %T "$MOUNTPOINT" 2>/dev/null)

    case "$FSTYPE" in
        nfs|nfs4)
            echo "OK - NFS mount '$MOUNTPOINT' is mounted"
            exit 0
            ;;
        *)
            echo "CRITICAL - '$MOUNTPOINT' is mounted but not NFS (type: $FSTYPE)"
            exit 2
            ;;
    esac
else
    echo "CRITICAL - NFS mount '$MOUNTPOINT' is NOT mounted"
    exit 2
fi