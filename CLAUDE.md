# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DoJRP-GTA-V-GIS is a GIS data platform for a DoJRP (Department of Justice Roleplay) GTA-V game server. It manages spatial data for streets, jurisdictions, fire/police zones, addresses, and incidents — served as GeoJSON via Supabase PostgREST.

## Tech Stack

- **Runtime:** Node.js (>= 16.0.0)
- **Local Database:** PostgreSQL 15 + PostGIS 3.3 (port 5433)
- **Remote Database:** Supabase (free tier, PostGIS enabled)
- **API:** Supabase PostgREST (auto-generated REST) + custom GeoJSON SQL functions
- **Database Client:** pg v8.18.0

## Database Schema (19 tables, 50 MB)

- **address** (2): `address_point` (18,945 rows), `building_cids` (1,446 — FK to address_point)
- **street** (3): `street_segment` (9,663), `street_dissolved` (1,258), `street_crossing` (2,175)
- **map** (8): `jurisdiction` (36), `neighborhood` (100), `area_of_patrol` (30), `gang_territory` (75), `zip_code` (92), `postal_zone` (1,044), `point_of_interest` (453), `transit_route` (84)
- **fire** (4): `fire_district` (194), `fire_box` (1,610), `fire_station` (9), `water_supply` (1,342)
- **police** (1): `police_zone` (827)
- **incidents** (1): `dispatched_incident` (1,401)

All spatial data uses SRID 3857 (Web Mercator). GeoJSON functions transform to 4326 (WGS84) for output.

## Commands

```bash
# Install dependencies
npm install

# Run data migration to Supabase
bash deploy/migrate-data.sh
```

There are no test, lint, or build commands configured.

## Key Files

- `deploy/supabase-setup.sql` — Creates schemas, grants permissions for PostgREST
- `deploy/supabase-geojson.sql` — GeoJSON API functions (18 endpoints)
- `deploy/supabase-compute-crossings.sql` — Street crossing computation function
- `deploy/migrate-data.sh` — pg_dump local → pg_restore to Supabase
- `docs/database-inventory.md` — Full schema documentation
- `.env.example` — Connection variable template

## Environment Variables

Defined in `.env.example`:
- `LOCAL_DB_*` — local PostgreSQL connection (source)
- `SUPABASE_DB_*` — Supabase direct connection (for migration)
- `SUPABASE_URL`, `SUPABASE_ANON_KEY` — Supabase API access

## Key Conventions

- Snake_case, singular table names, no abbreviations
- `is_` prefix for booleans (`is_oneway`, `is_disputed`, `is_hydrant_area`)
- Consistent field names across schemas (`nearest_postal_code`, `fire_box`, `jurisdiction`)
- Geometry normalization: `ST_Force2D(ST_Multi(geom))` for polygons/lines, `ST_Force2D(geom)` for points
- All inspection/migration scripts with credentials are gitignored
- **Never commit credentials to git or git history**
