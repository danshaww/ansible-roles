#!/bin/bash
# Nagios SMART health check for SATA, SAS and USB disks.
#
# smartctl needs root to talk to the disk, so NRPE runs this through sudo
# (see /etc/sudoers.d/nagios-plugins, managed by the nagios_agent role).
#
# CRITICAL: SMART health FAILED, or SMART is disabled
# WARNING:  more than REALLOC_WARN reallocated sectors, or any pending or
#           offline-uncorrectable sectors

export LC_ALL=C
DISK="$1"

# A few reallocated sectors are common and often stable, so only warn above this
REALLOC_WARN=10

if [[ ! "$DISK" =~ ^/dev/sd[a-z]+$ ]]; then
    echo "UNKNOWN - Usage: check_smart.sh /dev/sdX"
    exit 3
fi

if [ ! -b "$DISK" ]; then
    echo "CRITICAL - Disk '$DISK' not found"
    exit 2
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "UNKNOWN - check_smart.sh must run as root (check the nagios sudo rule)"
    exit 3
fi

OUT=$(smartctl -i -H -A "$DISK" 2>&1)
RC=$?

# smartctl exit status is a bitmask; bit 1 means the device could not be opened
if (( RC & 2 )); then
    echo "UNKNOWN - smartctl could not open $DISK: $(echo "$OUT" | tail -1)"
    exit 3
fi

if echo "$OUT" | grep -q "SMART support is: Unavailable"; then
    echo "UNKNOWN - SMART is not supported on $DISK"
    exit 3
fi

if ! echo "$OUT" | grep -q "SMART support is: Enabled"; then
    echo "CRITICAL - SMART is disabled on $DISK"
    exit 2
fi

HEALTH=$(echo "$OUT" | grep -i "overall-health" | awk -F: '{print $2}' | xargs)

# Raw value of a SMART attribute by ID (leading digits only, e.g. "34 (0 23 0)" -> 34)
attr() {
    echo "$OUT" | awk -v id="$1" '$1 == id { print $10; exit }' | grep -oE '^[0-9]+'
}

REALLOC=$(attr 5)
HOURS=$(attr 9)
TEMP=$(attr 194)
[ -z "$TEMP" ] && TEMP=$(attr 190)
PENDING=$(attr 197)
UNCORR=$(attr 198)

PERF=""
[ -n "$TEMP" ] && PERF+="temperature=${TEMP} "
[ -n "$REALLOC" ] && PERF+="reallocated=${REALLOC};${REALLOC_WARN} "
[ -n "$PENDING" ] && PERF+="pending=${PENDING} "
[ -n "$UNCORR" ] && PERF+="uncorrectable=${UNCORR} "
[ -n "$HOURS" ] && PERF+="power_on_hours=${HOURS} "
PERF="${PERF% }"

DETAIL="${TEMP:-?}C, ${REALLOC:-?} reallocated, ${PENDING:-?} pending, ${UNCORR:-?} uncorrectable"

if [ "$HEALTH" = "FAILED!" ] || [ "$HEALTH" = "FAILED" ] || (( RC & 8 )); then
    echo "CRITICAL - SMART health FAILED for $DISK ($DETAIL) | $PERF"
    exit 2
fi

if [ "$HEALTH" != "PASSED" ]; then
    echo "UNKNOWN - SMART health state for $DISK: '${HEALTH:-not reported}' | $PERF"
    exit 3
fi

if [ "${PENDING:-0}" -gt 0 ] || [ "${UNCORR:-0}" -gt 0 ] || [ "${REALLOC:-0}" -gt "$REALLOC_WARN" ]; then
    echo "WARNING - SMART health PASSED but $DISK has bad sectors ($DETAIL) | $PERF"
    exit 1
fi

echo "OK - SMART health PASSED for $DISK ($DETAIL) | $PERF"
exit 0
