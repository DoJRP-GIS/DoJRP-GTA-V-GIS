# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DoJRP-GTA-V-GIS is an early-stage Node.js project for PostGIS database inspection and GIS data management for a DoJRP (Department of Justice Roleplay) GTA-V game server. Currently consists of database inspection utilities connecting to a local PostgreSQL/PostGIS database.

## Tech Stack

- **Runtime:** Node.js (>= 16.0.0)
- **Database:** PostgreSQL with PostGIS spatial extension (port 5433)
- **Database Client:** pg v8.18.0
- **No build system, test framework, linting, or TypeScript configured yet**

## Commands

```bash
# Run database inspection
node inspect_db.js

# Install dependencies
npm install
```

There are no test, lint, or build commands configured.

## Architecture

- **Entry point:** `inspect_db.js` — connects to local PostGIS database, queries spatial metadata (`geometry_columns`, `ST_Extent()`, `ST_AsText()`), and reports on spatial tables, geometry types, SRIDs, dimensions, bounding boxes, and column schemas.
- **Database:** `gisdb` on localhost:5433 — PostgreSQL with PostGIS extension for spatial data storage.

## Environment Variables

Defined in `.env.example`:
- `LOCAL_DB_HOST`, `LOCAL_DB_PORT`, `LOCAL_DB_NAME`, `LOCAL_DB_USER`, `LOCAL_DB_PASSWORD` — local PostgreSQL connection
- `REMOTE_DB_URL` — planned remote database connection (not yet implemented)

**Note:** `inspect_db.js` currently has hardcoded credentials instead of reading from `.env`. The script is listed in `.gitignore` to prevent accidental credential commits.

## Key Conventions

- Async/await for all database operations with try/catch error handling
- Console output uses emoji indicators (✓, ⚠, 📍, 💾, ❌)
- Environment variables use UPPER_SNAKE_CASE
- Inspection scripts (`inspect_*.js`) are gitignored to protect credentials
