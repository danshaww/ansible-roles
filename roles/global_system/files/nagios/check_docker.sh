#!/bin/bash

CONTAINER="$1"

if [ -z "$CONTAINER" ]; then
    echo "UNKNOWN - Usage: check_docker.sh <container-name-or-id>"
    exit 3
fi

# Query Docker for container state
STATE=$(sudo docker inspect -f '{{.State.Status}}' "$CONTAINER" 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "CRITICAL - Container '$CONTAINER' not found"
    exit 2
fi

case "$STATE" in
    running)
        echo "OK - Container '$CONTAINER' is running"
        exit 0
        ;;
    exited)
        echo "CRITICAL - Container '$CONTAINER' has exited"
        exit 2
        ;;
    paused)
        echo "WARNING - Container '$CONTAINER' is paused"
        exit 1
        ;;
    restarting)
        echo "WARNING - Container '$CONTAINER' is restarting"
        exit 1
        ;;
    *)
        echo "UNKNOWN - Container '$CONTAINER' state: $STATE"
        exit 3
        ;;
esac