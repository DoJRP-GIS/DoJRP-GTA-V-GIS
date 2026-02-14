-- =============================================================================
-- DoJRP GIS — Supabase Database Setup
-- Run this in the Supabase SQL Editor after creating your project
-- =============================================================================

-- 1. Enable PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Create schemas
CREATE SCHEMA IF NOT EXISTS address;
CREATE SCHEMA IF NOT EXISTS fire;
CREATE SCHEMA IF NOT EXISTS incidents;
CREATE SCHEMA IF NOT EXISTS map;
CREATE SCHEMA IF NOT EXISTS police;
CREATE SCHEMA IF NOT EXISTS street;

-- 3. Expose schemas to PostgREST (Supabase API)
-- This makes tables in these schemas accessible via the REST API
ALTER DEFAULT PRIVILEGES IN SCHEMA address GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA fire GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA incidents GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA map GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA police GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA street GRANT SELECT ON TABLES TO anon;

-- Grant usage on schemas to PostgREST roles
GRANT USAGE ON SCHEMA address TO anon, authenticated;
GRANT USAGE ON SCHEMA fire TO anon, authenticated;
GRANT USAGE ON SCHEMA incidents TO anon, authenticated;
GRANT USAGE ON SCHEMA map TO anon, authenticated;
GRANT USAGE ON SCHEMA police TO anon, authenticated;
GRANT USAGE ON SCHEMA street TO anon, authenticated;

-- Expose these schemas in the API (add to PostgREST search path)
-- NOTE: This must also be set in Supabase Dashboard > Settings > API > Exposed schemas
-- Add: address, fire, incidents, map, police, street

-- 4. Grant SELECT on all future and existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA address TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA fire TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA incidents TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA map TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA police TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA street TO anon, authenticated;

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
