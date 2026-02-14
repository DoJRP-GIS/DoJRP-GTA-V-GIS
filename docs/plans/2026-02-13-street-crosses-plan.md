# Street Crossings Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Compute street intersection points from `street_segment` geometry and expose them via a GeoJSON API endpoint.

**Architecture:** Pure SQL approach — DDL for the new `street.street_crossing` table, a `compute_street_crossings()` function that spatially computes all intersection points from `street_segment` pairs, and a `geojson_street_crossings()` RPC function for the API. No application code or external dependencies.

**Tech Stack:** PostgreSQL 15, PostGIS 3.3, Supabase PostgREST

**Local DB:** `localhost:5433`, user `postgres`, password `567856`, database `gisdb`

**psql path:** `"C:/Program Files/PostgreSQL/18/bin/psql.exe"`

---

### Task 1: Add table DDL to supabase-setup.sql

**Files:**
- Modify: `deploy/supabase-setup.sql` (append before end of file)

**Step 1: Add street_crossing table DDL**

Append the following after line 44 (after the last `GRANT SELECT` block):

```sql
-- 5. Street crossing table (computed intersections)
CREATE TABLE IF NOT EXISTS street.street_crossing (
    id              serial PRIMARY KEY,
    geom            geometry(Point, 3857) NOT NULL,
    street_name_1   text NOT NULL,
    street_name_2   text NOT NULL,
    display_text    text NOT NULL,
    is_valid        boolean NOT NULL DEFAULT true
);

CREATE INDEX IF NOT EXISTS idx_street_crossing_geom ON street.street_crossing USING gist (geom);
CREATE INDEX IF NOT EXISTS idx_street_crossing_street_name_1 ON street.street_crossing (street_name_1);
CREATE INDEX IF NOT EXISTS idx_street_crossing_street_name_2 ON street.street_crossing (street_name_2);
```

**Step 2: Verify DDL runs on local database**

```bash
PGPASSWORD=567856 "C:/Program Files/PostgreSQL/18/bin/psql.exe" -h localhost -p 5433 -U postgres -d gisdb -c "
CREATE TABLE IF NOT EXISTS street.street_crossing (
    id              serial PRIMARY KEY,
    geom            geometry(Point, 3857) NOT NULL,
    street_name_1   text NOT NULL,
    street_name_2   text NOT NULL,
    display_text    text NOT NULL,
    is_valid        boolean NOT NULL DEFAULT true
);
CREATE INDEX IF NOT EXISTS idx_street_crossing_geom ON street.street_crossing USING gist (geom);
CREATE INDEX IF NOT EXISTS idx_street_crossing_street_name_1 ON street.street_crossing (street_name_1);
CREATE INDEX IF NOT EXISTS idx_street_crossing_street_name_2 ON street.street_crossing (street_name_2);
"
```

Expected: `CREATE TABLE` / `CREATE INDEX` (no errors)

**Step 3: Verify table exists**

```bash
PGPASSWORD=567856 "C:/Program Files/PostgreSQL/18/bin/psql.exe" -h localhost -p 5433 -U postgres -d gisdb -c "\d street.street_crossing"
```

Expected: Table with columns `id`, `geom`, `street_name_1`, `street_name_2`, `display_text`, `is_valid`

**Step 4: Commit**

```bash
git add deploy/supabase-setup.sql
git commit -m "feat: add street_crossing table DDL to setup script"
```

---

### Task 2: Create compute_street_crossings() function

**Files:**
- Create: `deploy/supabase-compute-crossings.sql`

**Step 1: Write the computation function**

Create `deploy/supabase-compute-crossings.sql` with:

```sql
-- =============================================================================
-- DoJRP GIS — Street Crossing Computation
-- Computes intersection points from street_segment geometry pairs.
-- Idempotent: truncates and repopulates street.street_crossing on each call.
--
-- Usage: SELECT compute_street_crossings();
-- =============================================================================

CREATE OR REPLACE FUNCTION public.compute_street_crossings()
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    row_count integer;
BEGIN
    -- Clear existing data
    TRUNCATE street.street_crossing RESTART IDENTITY;

    -- Compute pairwise intersections from street_segment
    INSERT INTO street.street_crossing (geom, street_name_1, street_name_2, display_text, is_valid)
    WITH raw_crossings AS (
        SELECT
            -- Extract individual points from intersection results
            (ST_Dump(
                CASE
                    WHEN GeometryType(ST_Intersection(a.geom, b.geom)) IN ('POINT', 'MULTIPOINT')
                    THEN ST_Intersection(a.geom, b.geom)
                END
            )).geom AS geom,
            LEAST(a.street_name, b.street_name) AS street_name_1,
            GREATEST(a.street_name, b.street_name) AS street_name_2,
            -- Track if either segment is likely grade-separated
            bool_or(
                a.road_class IN ('A15', 'A63', 'B11', 'B12', 'B13', 'B19')
                OR b.road_class IN ('A15', 'A63', 'B11', 'B12', 'B13', 'B19')
            ) AS has_grade_sep
        FROM street.street_segment a
        JOIN street.street_segment b
            ON ST_Intersects(a.geom, b.geom)
            AND a.street_name < b.street_name  -- canonical order + avoid self/duplicate pairs
        WHERE GeometryType(ST_Intersection(a.geom, b.geom)) IN ('POINT', 'MULTIPOINT')
        GROUP BY (ST_Dump(
            CASE
                WHEN GeometryType(ST_Intersection(a.geom, b.geom)) IN ('POINT', 'MULTIPOINT')
                THEN ST_Intersection(a.geom, b.geom)
            END
        )).geom, LEAST(a.street_name, b.street_name), GREATEST(a.street_name, b.street_name)
    )
    SELECT
        ST_Centroid(ST_Collect(rc.geom)) AS geom,
        rc.street_name_1,
        rc.street_name_2,
        rc.street_name_1 || ' & ' || rc.street_name_2 AS display_text,
        NOT bool_or(rc.has_grade_sep) AS is_valid
    FROM raw_crossings rc
    GROUP BY rc.street_name_1, rc.street_name_2, ST_SnapToGrid(rc.geom, 1);

    GET DIAGNOSTICS row_count = ROW_COUNT;
    RETURN row_count;
END;
$$;
```

**NOTE:** The CTE above has a flaw — the `ST_Dump` + `GROUP BY` pattern won't work cleanly in a single pass because `ST_Dump` is a set-returning function. The actual implementation should use a cleaner two-CTE approach:

```sql
CREATE OR REPLACE FUNCTION public.compute_street_crossings()
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    row_count integer;
BEGIN
    TRUNCATE street.street_crossing RESTART IDENTITY;

    INSERT INTO street.street_crossing (geom, street_name_1, street_name_2, display_text, is_valid)
    WITH pairs AS (
        -- Find all segment pairs that spatially intersect with different street names
        SELECT
            ST_Intersection(a.geom, b.geom) AS raw_geom,
            LEAST(a.street_name, b.street_name) AS street_name_1,
            GREATEST(a.street_name, b.street_name) AS street_name_2,
            a.road_class IN ('A15', 'A63', 'B11', 'B12', 'B13', 'B19')
                OR b.road_class IN ('A15', 'A63', 'B11', 'B12', 'B13', 'B19') AS is_grade_sep
        FROM street.street_segment a
        JOIN street.street_segment b
            ON ST_Intersects(a.geom, b.geom)
            AND a.street_name < b.street_name
        WHERE GeometryType(ST_Intersection(a.geom, b.geom)) IN ('POINT', 'MULTIPOINT')
    ),
    points AS (
        -- Extract individual points from any multipoint results
        SELECT
            (ST_Dump(raw_geom)).geom AS geom,
            street_name_1,
            street_name_2,
            is_grade_sep
        FROM pairs
    )
    -- Deduplicate: snap to 1m grid, collect, take centroid
    SELECT
        ST_Centroid(ST_Collect(p.geom)) AS geom,
        p.street_name_1,
        p.street_name_2,
        p.street_name_1 || ' & ' || p.street_name_2 AS display_text,
        NOT bool_or(p.is_grade_sep) AS is_valid
    FROM points p
    GROUP BY p.street_name_1, p.street_name_2, ST_SnapToGrid(p.geom, 1);

    GET DIAGNOSTICS row_count = ROW_COUNT;
    RETURN row_count;
END;
$$;
```

Use the second (corrected) version.

**Step 2: Deploy the function to local database**

```bash
PGPASSWORD=567856 "C:/Program Files/PostgreSQL/18/bin/psql.exe" -h localhost -p 5433 -U postgres -d gisdb -f deploy/supabase-compute-crossings.sql
```

Expected: `CREATE FUNCTION`

**Step 3: Run the computation**

```bash
PGPASSWORD=567856 "C:/Program Files/PostgreSQL/18/bin/psql.exe" -h localhost -p 5433 -U postgres -d gisdb -c "SELECT compute_street_crossings();"
```

Expected: Returns a row count (the number of crossing rows inserted). Should be in the hundreds to low thousands.

**Step 4: Verify results**

```bash
PGPASSWORD=567856 "C:/Program Files/PostgreSQL/18/bin/psql.exe" -h localhost -p 5433 -U postgres -d gisdb -c "
SELECT COUNT(*) AS total,
       COUNT(*) FILTER (WHERE is_valid) AS valid,
       COUNT(*) FILTER (WHERE NOT is_valid) AS flagged
FROM street.street_crossing;
"
```

Expected: Non-zero counts. `flagged` should be > 0 (freeways/ramps/railroads auto-flagged).

**Step 5: Spot-check some results**

```bash
PGPASSWORD=567856 "C:/Program Files/PostgreSQL/18/bin/psql.exe" -h localhost -p 5433 -U postgres -d gisdb -c "
SELECT display_text, is_valid FROM street.street_crossing ORDER BY display_text LIMIT 20;
"
```

Expected: Alphabetically ordered display text like "Adam's Apple Blvd & Alta St", with mix of `t`/`f` for `is_valid`.

**Step 6: Verify bidirectional lookups work**

```bash
PGPASSWORD=567856 "C:/Program Files/PostgreSQL/18/bin/psql.exe" -h localhost -p 5433 -U postgres -d gisdb -c "
-- Pick a street that appears and search both columns
SELECT display_text, is_valid
FROM street.street_crossing
WHERE street_name_1 ILIKE '%alta%' OR street_name_2 ILIKE '%alta%'
LIMIT 10;
"
```

Expected: All intersections involving streets matching "alta" regardless of which column.

**Step 7: Verify idempotency**

```bash
PGPASSWORD=567856 "C:/Program Files/PostgreSQL/18/bin/psql.exe" -h localhost -p 5433 -U postgres -d gisdb -c "
SELECT compute_street_crossings();
SELECT COUNT(*) FROM street.street_crossing;
"
```

Expected: Same count as Step 4.

**Step 8: Commit**

```bash
git add deploy/supabase-compute-crossings.sql
git commit -m "feat: add compute_street_crossings() function"
```

---

### Task 3: Add GeoJSON endpoint to supabase-geojson.sql

**Files:**
- Modify: `deploy/supabase-geojson.sql` (add after line 56, after `geojson_street_dissolved`)

**Step 1: Add the GeoJSON function**

Insert after the `geojson_street_dissolved` function (line 82) and before the `-- === MAP ===` comment (line 84):

```sql
CREATE OR REPLACE FUNCTION public.geojson_street_crossings(
    bbox_xmin float DEFAULT NULL,
    bbox_ymin float DEFAULT NULL,
    bbox_xmax float DEFAULT NULL,
    bbox_ymax float DEFAULT NULL,
    street_name_filter text DEFAULT NULL,
    include_invalid boolean DEFAULT false,
    lim int DEFAULT 1000
)
RETURNS jsonb
LANGUAGE sql STABLE
AS $$
    SELECT jsonb_build_object(
        'type', 'FeatureCollection',
        'features', COALESCE(jsonb_agg(
            jsonb_build_object(
                'type', 'Feature',
                'id', id,
                'geometry', ST_AsGeoJSON(ST_Transform(geom, 4326))::jsonb,
                'properties', jsonb_build_object(
                    'id', id,
                    'street_name_1', street_name_1,
                    'street_name_2', street_name_2,
                    'display_text', display_text,
                    'is_valid', is_valid
                )
            )
        ), '[]'::jsonb)
    )
    FROM (
        SELECT * FROM street.street_crossing s
        WHERE (bbox_xmin IS NULL OR s.geom && ST_Transform(
            ST_MakeEnvelope(bbox_xmin, bbox_ymin, bbox_xmax, bbox_ymax, 4326), 3857))
          AND (street_name_filter IS NULL
               OR s.street_name_1 ILIKE '%' || street_name_filter || '%'
               OR s.street_name_2 ILIKE '%' || street_name_filter || '%')
          AND (include_invalid OR s.is_valid = true)
        LIMIT lim
    ) sub;
$$;
```

Also add the GRANT at the end of the file with the other grants:

```sql
GRANT EXECUTE ON FUNCTION public.geojson_street_crossings TO anon, authenticated;
```

**Step 2: Deploy to local database**

```bash
PGPASSWORD=567856 "C:/Program Files/PostgreSQL/18/bin/psql.exe" -h localhost -p 5433 -U postgres -d gisdb -f deploy/supabase-geojson.sql
```

Expected: Multiple `CREATE FUNCTION` outputs (all 18 functions recreated), no errors.

**Step 3: Test the endpoint — default (valid only)**

```bash
PGPASSWORD=567856 "C:/Program Files/PostgreSQL/18/bin/psql.exe" -h localhost -p 5433 -U postgres -d gisdb -c "
SELECT jsonb_array_length(result->'features') AS feature_count
FROM geojson_street_crossings() AS result;
"
```

Expected: A number matching the `valid` count from Task 2 Step 4 (capped at 1000 by default limit).

**Step 4: Test the endpoint — with include_invalid**

```bash
PGPASSWORD=567856 "C:/Program Files/PostgreSQL/18/bin/psql.exe" -h localhost -p 5433 -U postgres -d gisdb -c "
SELECT jsonb_array_length(result->'features') AS feature_count
FROM geojson_street_crossings(include_invalid := true, lim := 5000) AS result;
"
```

Expected: A number matching the `total` count from Task 2 Step 4.

**Step 5: Test the endpoint — street name filter**

```bash
PGPASSWORD=567856 "C:/Program Files/PostgreSQL/18/bin/psql.exe" -h localhost -p 5433 -U postgres -d gisdb -c "
SELECT result->'features'->0->'properties'->>'display_text' AS first_match
FROM geojson_street_crossings(street_name_filter := 'Alta') AS result;
"
```

Expected: A display_text containing "Alta" in one of the street names.

**Step 6: Commit**

```bash
git add deploy/supabase-geojson.sql
git commit -m "feat: add geojson_street_crossings() API endpoint"
```

---

### Task 4: Update documentation

**Files:**
- Modify: `CLAUDE.md` (update table count and key files)
- Modify: `docs/database-inventory.md` (add street_crossing table documentation)

**Step 1: Update CLAUDE.md**

- Change `18 tables` to `19 tables` in the Database Schema section
- Under `street (2)`, change to `street (3)` and add `street_crossing`
- Add `deploy/supabase-compute-crossings.sql` to Key Files
- Update `17 endpoints` to `18 endpoints` in supabase-geojson.sql description

**Step 2: Update docs/database-inventory.md**

Add `street.street_crossing` table documentation matching the existing format for other tables.

**Step 3: Commit**

```bash
git add CLAUDE.md docs/database-inventory.md
git commit -m "docs: add street_crossing to schema documentation"
```
