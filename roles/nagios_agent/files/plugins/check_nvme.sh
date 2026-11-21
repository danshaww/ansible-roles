#!/bin/bash
# Nagios health check for NVMe drives, using smartctl (consistent output
# across versions, unlike nvme-cli whose units and formats vary).
#
# smartctl needs root to read the NVMe health log, so NRPE runs this through
# sudo (see /etc/sudoers.d/nagios-plugins, managed by the nagios_agent role).
#
# CRITICAL: health FAILED, critical warning set, media errors, spare below
#           threshold, wear >= 90%, temperature >= 70C
# WARNING:  wear >= 80%, temperature >= 60C

export LC_ALL=C
DISK="$1"

WARN_TEMP=60
CRIT_TEMP=70
WARN_USED=80
CRIT_USED=90

if [[ ! "$DISK" =~ ^/dev/nvme[0-9]+(n[0-9]+)?$ ]]; then
    echo "UNKNOWN - Usage: check_nvme.sh /dev/nvmeXnY"
    exit 3
fi

if [ ! -e "$DISK" ]; then
    echo "CRITICAL - NVMe device '$DISK' not found"
    exit 2
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "UNKNOWN - check_nvme.sh must run as root (check the nagios sudo rule)"
    exit 3
fi

OUT=$(smartctl -H -A "$DISK" 2>&1)
RC=$?

if (( RC & 2 )); then
    echo "UNKNOWN - smartctl could not open $DISK: $(echo "$OUT" | tail -1)"
    exit 3
fi

# Value after "Label:" with commas removed, as a number
field() {
    echo "$OUT" | awk -F: -v label="$1" '$1 == label { gsub(/,/, "", $2); print $2 + 0; exit }'
}

HEALTH=$(echo "$OUT" | grep -i "overall-health" | awk -F: '{print $2}' | xargs)
CRIT_WARN=$(echo "$OUT" | awk -F: '$1 == "Critical Warning" { print $2; exit }' | xargs)
TEMP=$(field "Temperature")
SPARE=$(field "Available Spare")
SPARE_THRESH=$(field "Available Spare Threshold")
USED=$(field "Percentage Used")
MEDIA_ERR=$(field "Media and Data Integrity Errors")

if [ -z "$HEALTH" ] || [ -z "$CRIT_WARN" ]; then
    echo "UNKNOWN - Could not read NVMe health log for $DISK"
    exit 3
fi

PERF="temperature=${TEMP};${WARN_TEMP};${CRIT_TEMP} percentage_used=${USED}%;${WARN_USED};${CRIT_USED} available_spare=${SPARE}%;;${SPARE_THRESH} media_errors=${MEDIA_ERR}"
DETAIL="${TEMP}C, ${USED}% used, ${SPARE}% spare, ${MEDIA_ERR} media errors"

STATUS=0
REASONS=()
[ "$HEALTH" != "PASSED" ]                 && { STATUS=2; REASONS+=("health $HEALTH"); }
[ "$CRIT_WARN" != "0x00" ]                && { STATUS=2; REASONS+=("critical warning $CRIT_WARN"); }
[ "$MEDIA_ERR" -gt 0 ]                    && { STATUS=2; REASONS+=("media errors"); }
[ "$SPARE" -lt "$SPARE_THRESH" ]          && { STATUS=2; REASONS+=("spare below threshold"); }
[ "$USED" -ge "$CRIT_USED" ]              && { STATUS=2; REASONS+=("wear ${USED}%"); }
[ "$TEMP" -ge "$CRIT_TEMP" ]              && { STATUS=2; REASONS+=("temperature ${TEMP}C"); }
if [ "$STATUS" -lt 2 ]; then
    [ "$USED" -ge "$WARN_USED" ]          && { STATUS=1; REASONS+=("wear ${USED}%"); }
    [ "$TEMP" -ge "$WARN_TEMP" ]          && { STATUS=1; REASONS+=("temperature ${TEMP}C"); }
fi

case $STATUS in
    0) echo "OK - NVMe $DISK healthy ($DETAIL) | $PERF" ;;
    1) echo "WARNING - NVMe $DISK: $(IFS=,; echo "${REASONS[*]}") ($DETAIL) | $PERF" ;;
    2) echo "CRITICAL - NVMe $DISK: $(IFS=,; echo "${REASONS[*]}") ($DETAIL) | $PERF" ;;
esac
exit $STATUS
