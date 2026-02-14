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
    TRUNCATE street.street_crossing RESTART IDENTITY;

    INSERT INTO street.street_crossing (geom, street_name_1, street_name_2, display_text, is_valid)
    WITH pairs AS (
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
        SELECT
            (ST_Dump(raw_geom)).geom AS geom,
            street_name_1,
            street_name_2,
            is_grade_sep
        FROM pairs
    )
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
