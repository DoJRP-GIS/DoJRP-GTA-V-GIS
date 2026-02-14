-- =============================================================================
-- DoJRP GIS — Street Crossing Computation
-- Computes intersection points from street_segment geometry pairs.
-- Idempotent: truncates and repopulates street.street_crossing on each call.
--
-- Usage: SELECT compute_street_crossings();
--
-- NOTE: No GRANT EXECUTE — this function mutates data and should only be
-- called by the database owner (via SQL Editor or migration scripts).
-- =============================================================================

CREATE OR REPLACE FUNCTION public.compute_street_crossings()
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    row_count integer;
BEGIN
    -- Runs in a single transaction: TRUNCATE + INSERT are atomic
    TRUNCATE street.street_crossing RESTART IDENTITY;

    INSERT INTO street.street_crossing (geom, street_name_1, street_name_2, display_text, is_valid)
    WITH raw AS (
        -- Compute intersection geometry once per segment pair
        SELECT
            ST_Intersection(a.geom, b.geom) AS raw_geom,
            LEAST(a.street_name, b.street_name) AS street_name_1,
            GREATEST(a.street_name, b.street_name) AS street_name_2,
            a.road_class IN ('B11', 'B12', 'B13', 'B19')
                OR b.road_class IN ('B11', 'B12', 'B13', 'B19') AS is_railroad,
            a.road_class IN ('A15', 'A63')
                OR b.road_class IN ('A15', 'A63') AS is_highway_or_ramp
        FROM street.street_segment a
        JOIN street.street_segment b
            ON ST_Intersects(a.geom, b.geom)
            AND a.street_name < b.street_name
    ),
    pairs AS (
        -- Filter to point-type intersection results only
        SELECT * FROM raw
        WHERE GeometryType(raw_geom) IN ('POINT', 'MULTIPOINT')
    ),
    points AS (
        SELECT
            (ST_Dump(raw_geom)).geom AS geom,
            street_name_1,
            street_name_2,
            is_railroad,
            is_highway_or_ramp
        FROM pairs
    )
    SELECT
        ST_Centroid(ST_Collect(p.geom)) AS geom,
        p.street_name_1,
        p.street_name_2,
        p.street_name_1 || ' & ' || p.street_name_2 AS display_text,
        CASE
            -- Railroad crossings: always invalid
            WHEN bool_or(p.is_railroad) THEN false
            -- No highway/ramp involved: always valid
            WHEN NOT bool_or(p.is_highway_or_ramp) THEN true
            -- Ramp connected to its origin or destination road
            WHEN p.street_name_1 LIKE '%RAMP TO%'
                 AND p.street_name_1 LIKE '%' || p.street_name_2 || '%' THEN true
            WHEN p.street_name_2 LIKE '%RAMP TO%'
                 AND p.street_name_2 LIKE '%' || p.street_name_1 || '%' THEN true
            -- Ramp split/merge: shared origin or destination
            WHEN p.street_name_1 LIKE '%RAMP TO%'
                 AND p.street_name_2 LIKE '%RAMP TO%'
                 AND (split_part(p.street_name_1, ' RAMP TO ', 1)
                      = split_part(p.street_name_2, ' RAMP TO ', 1)
                   OR split_part(p.street_name_1, ' RAMP TO ', 2)
                      = split_part(p.street_name_2, ' RAMP TO ', 2))
            THEN true
            -- Remaining highway/ramp crossings: likely overpass
            ELSE false
        END AS is_valid
    FROM points p
    GROUP BY p.street_name_1, p.street_name_2, ST_SnapToGrid(p.geom, 1);

    GET DIAGNOSTICS row_count = ROW_COUNT;
    RETURN row_count;
END;
$$;
