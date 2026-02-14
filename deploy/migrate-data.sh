#!/bin/bash
# =============================================================================
# DoJRP GIS — Migrate Data to Supabase
# Run this from your LOCAL machine (where the source database lives)
#
# Prerequisites:
#   - Local PostgreSQL running on port 5433 with gisdb
#   - Supabase project created with PostGIS enabled
#   - supabase-setup.sql already run in Supabase SQL Editor
#   - .env file with local and remote credentials
#   - pg_dump and psql available locally
#
# Usage: bash deploy/migrate-data.sh
# =============================================================================

set -euo pipefail

# --- Add PostgreSQL to PATH if not already available ---
if ! command -v pg_dump &>/dev/null; then
    for pgdir in "/c/Program Files/PostgreSQL"/*/bin; do
        if [ -f "$pgdir/pg_dump.exe" ]; then
            export PATH="$pgdir:$PATH"
            echo "Found PostgreSQL at: $pgdir"
            break
        fi
    done
fi

if ! command -v pg_dump &>/dev/null; then
    echo "ERROR: pg_dump not found. Install PostgreSQL or add it to PATH."
    exit 1
fi

# --- Configuration (edit these or use .env) ---
if [ -f .env ]; then
    # Strip Windows \r from env values
    set -a
    while IFS='=' read -r key val; do
        [[ "$key" =~ ^#.* || -z "$key" ]] && continue
        val="${val%$'\r'}"
        export "$key=$val"
    done < .env
    set +a
fi

LOCAL_HOST="${LOCAL_DB_HOST:-localhost}"
LOCAL_PORT="${LOCAL_DB_PORT:-5433}"
LOCAL_DB="${LOCAL_DB_NAME:-gisdb}"
LOCAL_USER="${LOCAL_DB_USER:-postgres}"

# Supabase connection — must be set
REMOTE_HOST="${SUPABASE_DB_HOST:?Set SUPABASE_DB_HOST in .env}"
REMOTE_PORT="${SUPABASE_DB_PORT:-5432}"
REMOTE_DB="${SUPABASE_DB_NAME:-postgres}"
REMOTE_USER="${SUPABASE_DB_USER:-postgres}"
REMOTE_PASSWORD="${SUPABASE_DB_PASSWORD:?Set SUPABASE_DB_PASSWORD in .env}"

DUMP_DIR="./deploy/dumps"
mkdir -p "$DUMP_DIR"

# Core GTA V schemas to migrate
SCHEMAS=("address" "fire" "incidents" "map" "police" "street")

echo "=== DoJRP GIS Data Migration to Supabase ==="
echo "Source: ${LOCAL_USER}@${LOCAL_HOST}:${LOCAL_PORT}/${LOCAL_DB}"
echo "Target: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PORT}/${REMOTE_DB}"
echo ""

# --- Step 1: Dump each schema ---
echo "[1/4] Dumping core schemas from local database..."

for schema in "${SCHEMAS[@]}"; do
    echo "  Dumping ${schema}..."
    PGPASSWORD="${LOCAL_DB_PASSWORD}" pg_dump \
        -h "$LOCAL_HOST" \
        -p "$LOCAL_PORT" \
        -U "$LOCAL_USER" \
        -d "$LOCAL_DB" \
        -n "$schema" \
        -Fc \
        -f "${DUMP_DIR}/${schema}.dump"

    SIZE=$(du -h "${DUMP_DIR}/${schema}.dump" | cut -f1)
    echo "    -> ${SIZE}"
done

TOTAL_SIZE=$(du -sh "$DUMP_DIR" | cut -f1)
echo ""
echo "  Total dump size: ${TOTAL_SIZE}"

# --- Step 2: Restore to Supabase ---
echo ""
echo "[2/4] Restoring to Supabase..."
echo ""

for schema in "${SCHEMAS[@]}"; do
    echo "  Restoring ${schema}..."
    PGPASSWORD="${REMOTE_PASSWORD}" pg_restore \
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

# --- Step 3: Re-grant permissions (pg_restore --clean drops them) ---
echo ""
echo "[3/4] Granting PostgREST permissions..."

PGPASSWORD="${REMOTE_PASSWORD}" psql \
    -h "$REMOTE_HOST" \
    -p "$REMOTE_PORT" \
    -U "$REMOTE_USER" \
    -d "$REMOTE_DB" \
    -c "
$(for schema in "${SCHEMAS[@]}"; do
    echo "GRANT USAGE ON SCHEMA ${schema} TO anon, authenticated;"
    echo "GRANT SELECT ON ALL TABLES IN SCHEMA ${schema} TO anon, authenticated;"
done)
"
echo "    -> done"

# --- Step 4: Verify ---
echo ""
echo "[4/4] Verifying migration..."

PGPASSWORD="${REMOTE_PASSWORD}" psql \
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
echo "  Next steps:"
echo "    1. Run supabase-geojson.sql in the SQL Editor"
echo "    2. Add schemas to Supabase > Settings > API > Exposed schemas"
echo "    3. Test: curl https://<project>.supabase.co/rest/v1/rpc/geojson_jurisdictions"
echo "============================================="
