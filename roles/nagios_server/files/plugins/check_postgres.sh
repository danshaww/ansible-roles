#!/bin/bash
#
# Nagios plugin to verify a PostgreSQL database is accessible by querying a
# table.
#
# Usage: check_postgres.sh -H <host> [-P <port>] -u <user> -p <password> -d <database> -t <table>

usage() {
    echo "UNKNOWN - Usage: check_postgres.sh -H <host> [-P <port>] -u <user> -p <password> -d <database> -t <table>"
    exit 3
}

HOST="" PORT="5432" DBUSER="" PASSWORD="" DATABASE="" TABLE=""
while getopts ":H:P:u:p:d:t:" opt; do
    case "$opt" in
        H) HOST="$OPTARG" ;;
        P) PORT="$OPTARG" ;;
        u) DBUSER="$OPTARG" ;;
        p) PASSWORD="$OPTARG" ;;
        d) DATABASE="$OPTARG" ;;
        t) TABLE="$OPTARG" ;;
        *) usage ;;
    esac
done

if [ -z "$HOST" ] || [ -z "$DBUSER" ] || [ -z "$DATABASE" ] || [ -z "$TABLE" ]; then
    usage
fi

if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
    echo "UNKNOWN - Invalid port '$PORT'"
    exit 3
fi

# Table may be schema-qualified (schema.table).
if ! [[ "$TABLE" =~ ^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)?$ ]]; then
    echo "UNKNOWN - Invalid table name '$TABLE'"
    exit 3
fi

if ! command -v psql >/dev/null 2>&1; then
    echo "UNKNOWN - psql not found, install postgresql-client"
    exit 3
fi

# Pass the password via the environment rather than the command line, where
# it would be visible in the process list. Ignore any ~/.pgpass or service file.
export PGPASSWORD="$PASSWORD"
export PGPASSFILE=/dev/null
export PGCONNECT_TIMEOUT="${PGCONNECT_TIMEOUT:-10}"
export PGAPPNAME="nagios"
unset PGSERVICE PGSERVICEFILE

START="${EPOCHREALTIME:-$(date +%s.%N)}"
if ! OUTPUT=$(psql -h "$HOST" -p "$PORT" -U "$DBUSER" -d "$DATABASE" -w \
        -X -A -t -q -v ON_ERROR_STOP=1 -c "SELECT count(*) FROM $TABLE" 2>&1); then
    echo "CRITICAL - $DATABASE on $HOST:$PORT: $(echo "$OUTPUT" | head -n 1)"
    exit 2
fi
END="${EPOCHREALTIME:-$(date +%s.%N)}"
ELAPSED=$(awk -v s="$START" -v e="$END" 'BEGIN { printf "%.3f", e - s }')

echo "OK - $DATABASE table '$TABLE' is accessible ($OUTPUT rows, ${ELAPSED}s) | time=${ELAPSED}s;;;0 rows=$OUTPUT;;;0"
exit 0
