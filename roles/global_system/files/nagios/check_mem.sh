#!/bin/bash

# Nagios memory check for Linux
# Outputs: OK/WARNING/CRITICAL + perfdata

WARN=$1
CRIT=$2

# Get memory stats from /proc/meminfo
TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
AVAILABLE=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
USED=$((TOTAL - AVAILABLE))

# Convert to percentage
PERCENT=$(( USED * 100 / TOTAL ))

if [ -z "$WARN" ] || [ -z "$CRIT" ]; then
    echo "UNKNOWN - Usage: check_mem.sh <warn%> <crit%>"
    exit 3
fi

if [ "$PERCENT" -ge "$CRIT" ]; then
    echo "CRITICAL - Memory usage at ${PERCENT}% | mem=${PERCENT}%"
    exit 2
elif [ "$PERCENT" -ge "$WARN" ]; then
    echo "WARNING - Memory usage at ${PERCENT}% | mem=${PERCENT}%"
    exit 1
else
    echo "OK - Memory usage at ${PERCENT}% | mem=${PERCENT}%"
    exit 0
fi