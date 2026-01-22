#!/bin/bash

SERVICE="$1"

if [ -z "$SERVICE" ]; then
    echo "UNKNOWN - Usage: check_systemd.sh <service-name>"
    exit 3
fi

# Query systemd
STATUS=$(systemctl is-active "$SERVICE" 2>/dev/null)

case "$STATUS" in
    active)
        echo "OK - $SERVICE is running"
        exit 0
        ;;
    inactive)
        echo "CRITICAL - $SERVICE is inactive"
        exit 2
        ;;
    failed)
        echo "CRITICAL - $SERVICE has failed"
        exit 2
        ;;
    activating)
        echo "WARNING - $SERVICE is starting up"
        exit 1
        ;;
    deactivating)
        echo "WARNING - $SERVICE is stopping"
        exit 1
        ;;
    *)
        echo "UNKNOWN - $SERVICE returned state: $STATUS"
        exit 3
        ;;
esac