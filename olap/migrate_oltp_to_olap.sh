#!/bin/bash
export PGPASSWORD=$POSTGRES_PASSWORD
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

SCRIPT_FILE="$SCRIPT_DIR/sql/migrate.sql"

if ! command -v psql &> /dev/null; then
    echo "Error: psql is not installed or not in PATH."
    exit 1
fi

echo "Loading SQL script from $SCRIPT_FILE..."
SCRIPT_PARSED=$(<"$SCRIPT_FILE")
SCRIPT_PARSED="${SCRIPT_PARSED//\$SCRIPT_DIR/$SCRIPT_DIR}"

function run_sql_file() {
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -f "$SCRIPT_DIR/sql/$1"
  if [ $? -ne 0 ]; then
      echo "Error: Failed to execute SQL script."
      exit 1
  fi
}

echo "Creating database scheme..."
run_sql_file "initial.sql"
echo "Migrating OLTP to OLAP..."
run_sql_file "migrate.sql"

echo "Data migration completed successfully!"
