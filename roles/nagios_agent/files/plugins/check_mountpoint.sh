#!/bin/bash
# Usage: check_mountpoint.sh <mountpoint> [fstype[,fstype...]]
#
# OK when <mountpoint> is mounted, responsive and (if given) of one of the
# expected filesystem types. "nfs" also matches nfs4.

MOUNTPOINT="$1"
EXPECTED="$2"

if [ -z "$MOUNTPOINT" ]; then
    echo "UNKNOWN - Usage: check_mountpoint.sh <mountpoint> [fstype[,fstype...]]"
    exit 3
fi

if [ ! -d "$MOUNTPOINT" ]; then
    echo "CRITICAL - Mountpoint '$MOUNTPOINT' does not exist"
    exit 2
fi

FSTYPE=$(findmnt -n -o FSTYPE --mountpoint "$MOUNTPOINT" 2>/dev/null | tail -n1)
if [ -z "$FSTYPE" ]; then
    echo "CRITICAL - '$MOUNTPOINT' is NOT mounted"
    exit 2
fi

# A hung network/virtio filesystem blocks stat rather than failing it
if ! timeout 10 stat -t "$MOUNTPOINT" >/dev/null 2>&1; then
    echo "CRITICAL - $FSTYPE mount '$MOUNTPOINT' is not responding"
    exit 2
fi

if [ -n "$EXPECTED" ]; then
    MATCH=0
    IFS=',' read -ra TYPES <<< "$EXPECTED"
    for t in "${TYPES[@]}"; do
        if [ "$FSTYPE" = "$t" ] || { [ "$t" = "nfs" ] && [ "$FSTYPE" = "nfs4" ]; }; then
            MATCH=1
            break
        fi
    done
    if [ "$MATCH" -eq 0 ]; then
        echo "CRITICAL - '$MOUNTPOINT' is mounted but type is $FSTYPE, expected $EXPECTED"
        exit 2
    fi
fi

echo "OK - $FSTYPE mount '$MOUNTPOINT' is mounted"
exit 0
