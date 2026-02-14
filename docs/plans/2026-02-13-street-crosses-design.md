# Street Crossings Design

## Problem

The existing cross-street data (`cross_street_low/high` on `street_segment`, `cross_street_1/2` on `address_point`) is static text imported from source data. It's inaccurate and not reproducible. We need spatially computed intersections derived from actual geometry.

## Requirements

- **Dispatch:** "Respond to Elm St & Main St" — bidirectional lookup (either name order works)
- **Map display:** Point geometry for each intersection, displayable on a web map
- **Geocoding/lookup:** Given a street name, return all intersections involving that street
- **Reproducible:** Re-runnable computation from source geometry, no manual data entry
- **N-way intersections:** Where 3+ streets meet, produce pairwise rows (3 streets = 3 rows, 4 = 6)
- **Multiple crossings:** If two streets genuinely cross at 2+ distinct locations, store each

## Approach: SQL Computation + SQL Populate (Approach C)

Two-part SQL solution matching the existing deploy pattern:

1. **DDL script** — creates the `street.street_crossing` table
2. **Populate function** — `compute_street_crossings()` computes intersections from `street_segment` geometry, idempotent (truncate + repopulate)

No external dependencies beyond PostGIS.

## Table Schema

```sql
CREATE TABLE street.street_crossing (
    id              serial PRIMARY KEY,
    geom            geometry(Point, 3857) NOT NULL,
    street_name_1   text NOT NULL,  -- alphabetically first
    street_name_2   text NOT NULL,  -- alphabetically second
    display_text    text NOT NULL   -- "Elm St & Main St"
);

CREATE INDEX idx_street_crossing_geom ON street.street_crossing USING gist (geom);
CREATE INDEX idx_street_crossing_street_name_1 ON street.street_crossing (street_name_1);
CREATE INDEX idx_street_crossing_street_name_2 ON street.street_crossing (street_name_2);
```

- **Canonical ordering:** `street_name_1 < street_name_2` alphabetically
- **Pairwise rows:** N-way intersections produce N*(N-1)/2 rows sharing the same geometry
- **No unique constraint** on `(street_name_1, street_name_2)` — same pair can cross at multiple distinct locations

## Computation Logic

`compute_street_crossings()`:

1. Pairwise `ST_Intersection` on `street_segment` where `ST_Intersects(a.geom, b.geom)` and `a.street_name <> b.street_name`
2. Filter to point results only (`ST_GeometryType = 'ST_Point'`, extract points from multipoints)
3. Canonical name ordering: `LEAST(a.street_name, b.street_name)`, `GREATEST(a.street_name, b.street_name)`
4. Deduplicate: `GROUP BY (street_name_1, street_name_2, ST_SnapToGrid(geom, 1))` — 1m snap handles floating-point noise
5. Representative point: `ST_Centroid(ST_Collect(geom))` per group
6. Generate `display_text`: `street_name_1 || ' & ' || street_name_2`

Idempotent — truncates `street.street_crossing` before repopulating.

## GeoJSON API Endpoint

```sql
CREATE OR REPLACE FUNCTION public.geojson_street_crossings(
    bbox_xmin float DEFAULT NULL,
    bbox_ymin float DEFAULT NULL,
    bbox_xmax float DEFAULT NULL,
    bbox_ymax float DEFAULT NULL,
    street_name_filter text DEFAULT NULL,
    lim int DEFAULT 1000
)
RETURNS jsonb
```

- `street_name_filter` matches against EITHER `street_name_1` or `street_name_2`
- Geometry transformed to SRID 4326 for GeoJSON output
- Returns FeatureCollection with properties: `id`, `street_name_1`, `street_name_2`, `display_text`

## Deliverables

1. Add DDL to `deploy/supabase-setup.sql` — table, indexes, grants
2. New `deploy/supabase-compute-crossings.sql` — the `compute_street_crossings()` function
3. Add endpoint to `deploy/supabase-geojson.sql` — the `geojson_street_crossings()` RPC function

No changes to existing tables. No new dependencies.
