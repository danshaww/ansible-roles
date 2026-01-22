#!/bin/bash

# Nagios CPU usage check for Linux
# Uses /proc/stat to calculate CPU busy percentage

WARN=$1
CRIT=$2

if [ -z "$WARN" ] || [ -z "$CRIT" ]; then
    echo "UNKNOWN - Usage: check_cpu.sh <warn%> <crit%>"
    exit 3
fi

# Read first CPU line
CPU=($(grep '^cpu ' /proc/stat))
# Fields: user nice system idle iowait irq softirq steal guest guest_nice
IDLE=${CPU[4]}
TOTAL=0
for VALUE in "${CPU[@]:1}"; do
    TOTAL=$((TOTAL + VALUE))
done

# Sleep briefly to calculate delta
sleep 1

CPU2=($(grep '^cpu ' /proc/stat))
IDLE2=${CPU2[4]}
TOTAL2=0
for VALUE in "${CPU2[@]:1}"; do
    TOTAL2=$((TOTAL2 + VALUE))
done

# Calculate deltas
DIFF_IDLE=$((IDLE2 - IDLE))
DIFF_TOTAL=$((TOTAL2 - TOTAL))
DIFF_USAGE=$((100 * (DIFF_TOTAL - DIFF_IDLE) / DIFF_TOTAL))

# Evaluate thresholds
if [ "$DIFF_USAGE" -ge "$CRIT" ]; then
    echo "CRITICAL - CPU usage at ${DIFF_USAGE}% | cpu=${DIFF_USAGE}%"
    exit 2
elif [ "$DIFF_USAGE" -ge "$WARN" ]; then
    echo "WARNING - CPU usage at ${DIFF_USAGE}% | cpu=${DIFF_USAGE}%"
    exit 1
else
    echo "OK - CPU usage at ${DIFF_USAGE}% | cpu=${DIFF_USAGE}%"
    exit 0
fi