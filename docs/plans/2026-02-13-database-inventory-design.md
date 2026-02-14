# Database Inventory Design

## Goal

Create a comprehensive, reproducible inventory of the `gisdb` PostGIS database as a structured markdown report.

## Approach

A single `review_db.js` Node.js script that queries all database metadata and writes `docs/database-inventory.md`.

## Report Sections

### 1. Database Overview
- Database name, total size, PostgreSQL version
- Installed extensions with versions (PostGIS, etc.)
- All schemas

### 2. Table Inventory (per table)
- Schema, name, row count, disk size (table + indexes)
- All columns: name, data type, nullable, default, constraints
- Primary keys, unique constraints, check constraints
- Foreign keys (references to/from)

### 3. Spatial Data (per spatial table)
- Geometry column, type, SRID, coordinate dimensions
- Bounding box extent via `ST_Extent()`
- Sample geometry (first row as WKT via `ST_AsText()`)
- Spatial reference system details from `spatial_ref_sys`

### 4. Indexes
- All indexes: name, table, columns, type (btree/gist/gin), size
- Spatial index identification

### 5. Views & Functions
- Custom views with definitions
- Custom functions/procedures

### 6. Summary Statistics
- Total tables, spatial tables, total row count
- Size breakdown sorted largest-first

## Technical Details

- **Connection:** localhost:5433, database `gisdb`, user `postgres` (hardcoded, script gitignored)
- **Output:** `docs/database-inventory.md` (committed to repo)
- **Dependencies:** `pg` (already installed)
