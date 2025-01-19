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

function upload_csv_file() {
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -c "\copy oltp.staging_$1 FROM '$SCRIPT_DIR/data/$1.csv' DELIMITER ',' CSV HEADER;"
  if [ $? -ne 0 ]; then
      echo "Error: Failed to execute SQL script."
      exit 1
  fi
}
echo "Creating database scheme..."
run_sql_file "initial.sql"
echo "Creating temp tables..."
run_sql_file "create.sql"
echo "Uploading data to temp tables..."
upload_csv_file 'airlines'
upload_csv_file 'airports'
upload_csv_file 'bookings'
upload_csv_file 'customers'
upload_csv_file 'flights'
upload_csv_file 'payments'
upload_csv_file 'flight_seats'
upload_csv_file 'services'
upload_csv_file 'booking_services'
echo "Migrating data to tables..."
run_sql_file "migrate.sql"
echo "Cleaning temp tables..."
run_sql_file "clean.sql"

echo "Data migration completed successfully!"
