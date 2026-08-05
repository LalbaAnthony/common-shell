# shellcheck shell=bash
# shellcheck disable=SC1091,SC2034,SC2142,SC2154

__mysql_require_cnf() {
    local CNF="$HOME/.my.cnf"

    if [ ! -f "$CNF" ]; then
        echo "Missing $CNF"
        echo "Create it with:"
        echo ""
        echo "[client]"
        echo "user=your_user"
        echo "password=your_password"
        echo ""
        echo "Then secure it:"
        echo "chmod 600 ~/.my.cnf"
        return 1
    fi
}


sqlimport() {
    local FILE=$1
    local DB=$2

    __mysql_require_cnf || { echo "Requires $HOME/.my.cnf"; return 1; }

    if [ -z "$FILE" ] || [ -z "$DB" ]; then
        echo "Usage: sqlimport <sql_file.sql.gz> <database_name>"
        return 1
    fi

    mysql -e "DROP DATABASE IF EXISTS \`${DB}\`;" || return 1
    mysql -e "CREATE DATABASE \`${DB}\` CHARACTER SET utf8 COLLATE utf8_general_ci" || return 1

    # zcat -f handles both gzipped and plain .sql
    # sed strips the MariaDB sandbox-mode line that the client rejects with "Unknown command '\-'"
    # pipefail makes a mysql failure propagate instead of being masked by zcat's exit code
    set -o pipefail
    zcat -f "${FILE}" \
        | sed '1{/enable the sandbox mode/d}' \
        | mysql --max_allowed_packet=512M "${DB}"
    local rc=$?
    set +o pipefail

    if [ "$rc" -ne 0 ]; then
        echo "Import FAILED for '${FILE}' (exit ${rc})"
        return "$rc"
    fi
    echo "Imported '${FILE}' into database '${DB}'"
}

sqlexport() {
    local DB=$1
    local OUTFILE=$2

    __mysql_require_cnf || (echo "Requires $HOME/.my.cnf"; return 1)

    if [ -z "$DB" ]; then
        echo "Usage: sqlexport <database_name> <output_sql_file.sql.gz>"
        return 1
    fi

    if [ -z "$OUTFILE" ]; then
        OUTFILE="${DB}_$(date +%F_%H-%M-%S).sql.gz"
    fi

    mysqldump  --single-transaction --quick --lock-tables=false "${DB}" | gzip > "${OUTFILE}"

    echo "Exported database '${DB}' to '${OUTFILE}'"
}
