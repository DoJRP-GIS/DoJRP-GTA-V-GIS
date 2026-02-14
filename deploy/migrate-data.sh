#!/bin/bash
# =============================================================================
# DoJRP GIS — Migrate Core GTA V Data to Remote Server
# Run this from your LOCAL machine (where the source database lives)
#
# Prerequisites:
#   - Local PostgreSQL running on port 5433 with gisdb
#   - Remote server set up via setup-server.sh
#   - pg_dump and pg_restore available locally
#
# Usage: bash deploy/migrate-data.sh
# =============================================================================

set -euo pipefail

# --- Configuration (edit these or use .env) ---
if [ -f .env ]; then
    source .env
fi

LOCAL_HOST="${LOCAL_DB_HOST:-localhost}"
LOCAL_PORT="${LOCAL_DB_PORT:-5433}"
LOCAL_DB="${LOCAL_DB_NAME:-gisdb}"
LOCAL_USER="${LOCAL_DB_USER:-postgres}"

# Remote connection — must be set
REMOTE_HOST="${REMOTE_DB_HOST:?Set REMOTE_DB_HOST in .env}"
REMOTE_PORT="${REMOTE_DB_PORT:-5432}"
REMOTE_DB="${REMOTE_DB_NAME:-gisdb}"
REMOTE_USER="${REMOTE_DB_USER:-gisuser}"

DUMP_DIR="./deploy/dumps"
mkdir -p "$DUMP_DIR"

# Core GTA V schemas to migrate
SCHEMAS=("address" "fire" "incidents" "map" "police" "street")

# Tables to EXCLUDE (reference data, backups, test tables)
EXCLUDE_TABLES=(
    "address.la_cams_address_lines"
    "address.la_cams_address_points"
    "address.la_lacounty_parcels"
    "address.address_cids_info_cross_backup"
    "address.address_cids_info_test"
)

echo "=== DoJRP GIS Data Migration ==="
echo "Source: ${LOCAL_USER}@${LOCAL_HOST}:${LOCAL_PORT}/${LOCAL_DB}"
echo "Target: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PORT}/${REMOTE_DB}"
echo ""

# Build exclude flags
EXCLUDE_FLAGS=""
for table in "${EXCLUDE_TABLES[@]}"; do
    EXCLUDE_FLAGS="$EXCLUDE_FLAGS --exclude-table=$table"
done

# --- Step 1: Dump each schema ---
echo "[1/3] Dumping core schemas from local database..."

for schema in "${SCHEMAS[@]}"; do
    echo "  Dumping ${schema}..."
    PGPASSWORD="${LOCAL_DB_PASSWORD}" pg_dump \
        -h "$LOCAL_HOST" \
        -p "$LOCAL_PORT" \
        -U "$LOCAL_USER" \
        -d "$LOCAL_DB" \
        -n "$schema" \
        $EXCLUDE_FLAGS \
        -Fc \
        -f "${DUMP_DIR}/${schema}.dump"

    SIZE=$(du -h "${DUMP_DIR}/${schema}.dump" | cut -f1)
    echo "    -> ${SIZE}"
done

TOTAL_SIZE=$(du -sh "$DUMP_DIR" | cut -f1)
echo ""
echo "  Total dump size: ${TOTAL_SIZE}"

# --- Step 2: Restore to remote ---
echo ""
echo "[2/3] Restoring to remote database..."
echo "  (You will be prompted for the remote password)"
echo ""

for schema in "${SCHEMAS[@]}"; do
    echo "  Restoring ${schema}..."
    PGPASSWORD="${REMOTE_DB_PASSWORD}" pg_restore \
        -h "$REMOTE_HOST" \
        -p "$REMOTE_PORT" \
        -U "$REMOTE_USER" \
        -d "$REMOTE_DB" \
        --no-owner \
        --no-privileges \
        --if-exists \
        --clean \
        "${DUMP_DIR}/${schema}.dump" 2>&1 | grep -v "does not exist, skipping" || true

    echo "    -> done"
done

# --- Step 3: Verify ---
echo ""
echo "[3/3] Verifying migration..."

PGPASSWORD="${REMOTE_DB_PASSWORD}" psql \
    -h "$REMOTE_HOST" \
    -p "$REMOTE_PORT" \
    -U "$REMOTE_USER" \
    -d "$REMOTE_DB" \
    -c "
SELECT
    n.nspname AS schema,
    c.relname AS table_name,
    c.reltuples::bigint AS approx_rows
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname IN ('address','fire','incidents','map','police','street')
  AND c.relkind = 'r'
ORDER BY n.nspname, c.relname;
"

echo ""
echo "============================================="
echo "  Migration complete!"
echo ""
echo "  Dump files saved in ${DUMP_DIR}/"
echo "  You can delete them after verifying."
echo ""
echo "  Next: Run setup-featureserv.sh on the server."
echo "============================================="
