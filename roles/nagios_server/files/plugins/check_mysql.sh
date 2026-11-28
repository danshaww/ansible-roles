#!/bin/bash
#
# Nagios plugin to verify a MySQL database is accessible by querying a table.
#
# Usage: check_mysql.sh -H <host> [-P <port>] -u <user> -p <password> -d <database> -t <table>

usage() {
    echo "UNKNOWN - Usage: check_mysql.sh -H <host> [-P <port>] -u <user> -p <password> -d <database> -t <table>"
    exit 3
}

HOST="" PORT="3306" DBUSER="" PASSWORD="" DATABASE="" TABLE=""
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

# Table may be database-qualified (database.table).
if ! [[ "$TABLE" =~ ^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)?$ ]]; then
    echo "UNKNOWN - Invalid table name '$TABLE'"
    exit 3
fi

if ! command -v mysql >/dev/null 2>&1; then
    echo "UNKNOWN - mysql not found, install mysql-client"
    exit 3
fi

# Pass the password through a private option file rather than the mysql
# command line, where it would be visible in the process list.
OPTFILE=$(mktemp)
ERRFILE=$(mktemp)
trap 'rm -f "$OPTFILE" "$ERRFILE"' EXIT
ESCAPED_PASSWORD="${PASSWORD//\\/\\\\}"
printf '[client]\npassword="%s"\n' "$ESCAPED_PASSWORD" > "$OPTFILE"

START="${EPOCHREALTIME:-$(date +%s.%N)}"
if ! OUTPUT=$(mysql --defaults-file="$OPTFILE" -h "$HOST" -P "$PORT" -u "$DBUSER" \
        --connect-timeout=10 --batch --skip-column-names "$DATABASE" \
        -e "SELECT COUNT(*) FROM $TABLE" 2>"$ERRFILE"); then
    echo "CRITICAL - $DATABASE on $HOST:$PORT: $(grep -v '^mysql: \[Warning\]' "$ERRFILE" | head -n 1)"
    exit 2
fi
END="${EPOCHREALTIME:-$(date +%s.%N)}"
ELAPSED=$(awk -v s="$START" -v e="$END" 'BEGIN { printf "%.3f", e - s }')

echo "OK - $DATABASE table '$TABLE' is accessible ($OUTPUT rows, ${ELAPSED}s) | time=${ELAPSED}s;;;0 rows=$OUTPUT;;;0"
exit 0
