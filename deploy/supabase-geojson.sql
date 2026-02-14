-- =============================================================================
-- DoJRP GIS — GeoJSON API Functions for Supabase
-- Run this AFTER migrating data. These functions are exposed via PostgREST RPC.
--
-- Usage: POST https://<project>.supabase.co/rest/v1/rpc/geojson_street_segments
--        with header: apikey: <your-anon-key>
--
-- All functions return GeoJSON FeatureCollections with geometry in EPSG:4326
-- (WGS84 lat/lon) for web map compatibility.
-- =============================================================================

-- Helper: Generic GeoJSON builder for any spatial table
-- This avoids repeating the same pattern for every table.

-- === STREET ===

CREATE OR REPLACE FUNCTION public.geojson_street_segments(
    bbox_xmin float DEFAULT NULL,
    bbox_ymin float DEFAULT NULL,
    bbox_xmax float DEFAULT NULL,
    bbox_ymax float DEFAULT NULL,
    street_name_filter text DEFAULT NULL,
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
                    'street_name', street_name,
                    'road_class', road_class,
                    'speed_limit_mph', speed_limit_mph,
                    'is_oneway', is_oneway,
                    'lane_count', lane_count,
                    'cross_street_low', cross_street_low,
                    'cross_street_high', cross_street_high,
                    'display_text', display_text
                )
            )
        ), '[]'::jsonb)
    )
    FROM (
        SELECT * FROM street.street_segment s
        WHERE (bbox_xmin IS NULL OR s.geom && ST_Transform(
            ST_MakeEnvelope(bbox_xmin, bbox_ymin, bbox_xmax, bbox_ymax, 4326), 3857))
          AND (street_name_filter IS NULL OR s.street_name ILIKE '%' || street_name_filter || '%')
        LIMIT lim
    ) sub;
$$;

CREATE OR REPLACE FUNCTION public.geojson_street_dissolved(
    lim int DEFAULT 2000
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
                    'street_name', street_name,
                    'name_base', name_base,
                    'name_type', name_type,
                    'display_text', display_text
                )
            )
        ), '[]'::jsonb)
    )
    FROM (SELECT * FROM street.street_dissolved LIMIT lim) sub;
$$;

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

-- === MAP ===

CREATE OR REPLACE FUNCTION public.geojson_jurisdictions()
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
                    'jurisdiction_name', jurisdiction_name,
                    'full_jurisdiction_name', full_jurisdiction_name,
                    'jurisdiction_type', jurisdiction_type,
                    'section', section
                )
            )
        ), '[]'::jsonb)
    )
    FROM map.jurisdiction;
$$;

CREATE OR REPLACE FUNCTION public.geojson_neighborhoods()
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
                    'neighborhood_name', neighborhood_name,
                    'neighborhood_code', neighborhood_code,
                    'district_name', district_name,
                    'district_code', district_code
                )
            )
        ), '[]'::jsonb)
    )
    FROM map.neighborhood;
$$;

CREATE OR REPLACE FUNCTION public.geojson_gang_territories()
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
                    'is_disputed', is_disputed,
                    'gang_names', gang_names
                )
            )
        ), '[]'::jsonb)
    )
    FROM map.gang_territory;
$$;

CREATE OR REPLACE FUNCTION public.geojson_zip_codes()
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
                    'zip_code', zip_code,
                    'display_text', display_text
                )
            )
        ), '[]'::jsonb)
    )
    FROM map.zip_code;
$$;

CREATE OR REPLACE FUNCTION public.geojson_postal_zones(
    bbox_xmin float DEFAULT NULL,
    bbox_ymin float DEFAULT NULL,
    bbox_xmax float DEFAULT NULL,
    bbox_ymax float DEFAULT NULL
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
                    'postal_number', postal_number,
                    'display_text', display_text
                )
            )
        ), '[]'::jsonb)
    )
    FROM map.postal_zone p
    WHERE bbox_xmin IS NULL OR p.geom && ST_Transform(
        ST_MakeEnvelope(bbox_xmin, bbox_ymin, bbox_xmax, bbox_ymax, 4326), 3857);
$$;

CREATE OR REPLACE FUNCTION public.geojson_areas_of_patrol()
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
                    'valid_aops', valid_aops,
                    'invalid_aops', invalid_aops
                )
            )
        ), '[]'::jsonb)
    )
    FROM map.area_of_patrol;
$$;

CREATE OR REPLACE FUNCTION public.geojson_points_of_interest(
    poi_type_filter text DEFAULT NULL,
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
                    'poi_type', poi_type,
                    'name', name,
                    'description', description,
                    'metadata', metadata
                )
            )
        ), '[]'::jsonb)
    )
    FROM (
        SELECT * FROM map.point_of_interest p
        WHERE poi_type_filter IS NULL OR p.poi_type = poi_type_filter
        LIMIT lim
    ) sub;
$$;

CREATE OR REPLACE FUNCTION public.geojson_transit_routes()
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
                    'route_name', route_name,
                    'route_type', route_type
                )
            )
        ), '[]'::jsonb)
    )
    FROM map.transit_route;
$$;

-- === FIRE ===

CREATE OR REPLACE FUNCTION public.geojson_fire_boxes(
    bbox_xmin float DEFAULT NULL,
    bbox_ymin float DEFAULT NULL,
    bbox_xmax float DEFAULT NULL,
    bbox_ymax float DEFAULT NULL
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
                    'station_name', station_name,
                    'station_number', station_number,
                    'box_code', box_code,
                    'fire_box', fire_box,
                    'is_hydrant_area', is_hydrant_area,
                    'running_order', running_order,
                    'display_text', display_text
                )
            )
        ), '[]'::jsonb)
    )
    FROM fire.fire_box f
    WHERE bbox_xmin IS NULL OR f.geom && ST_Transform(
        ST_MakeEnvelope(bbox_xmin, bbox_ymin, bbox_xmax, bbox_ymax, 4326), 3857);
$$;

CREATE OR REPLACE FUNCTION public.geojson_fire_districts()
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
                    'station_name', station_name,
                    'station_number', station_number,
                    'first_due', first_due,
                    'running_order', running_order,
                    'is_hydrant_area', is_hydrant_area
                )
            )
        ), '[]'::jsonb)
    )
    FROM fire.fire_district;
$$;

CREATE OR REPLACE FUNCTION public.geojson_fire_stations()
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
                    'station_name', station_name,
                    'first_due_district', first_due_district,
                    'full_address', full_address,
                    'jurisdiction', jurisdiction
                )
            )
        ), '[]'::jsonb)
    )
    FROM fire.fire_station;
$$;

CREATE OR REPLACE FUNCTION public.geojson_water_supply(
    supply_type_filter text DEFAULT NULL
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
                    'supply_type', supply_type,
                    'status', status,
                    'fire_box', fire_box
                )
            )
        ), '[]'::jsonb)
    )
    FROM fire.water_supply w
    WHERE supply_type_filter IS NULL OR w.supply_type = supply_type_filter;
$$;

-- === POLICE ===

CREATE OR REPLACE FUNCTION public.geojson_police_zones(
    jurisdiction_filter text DEFAULT NULL,
    bbox_xmin float DEFAULT NULL,
    bbox_ymin float DEFAULT NULL,
    bbox_xmax float DEFAULT NULL,
    bbox_ymax float DEFAULT NULL
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
                    'primary_jurisdiction', primary_jurisdiction,
                    'primary_jurisdiction_code', primary_jurisdiction_code,
                    'secondary_jurisdiction', secondary_jurisdiction,
                    'reporting_district', reporting_district,
                    'precinct', precinct,
                    'beat', beat,
                    'bureau', bureau
                )
            )
        ), '[]'::jsonb)
    )
    FROM police.police_zone p
    WHERE (jurisdiction_filter IS NULL OR p.primary_jurisdiction_code = jurisdiction_filter)
      AND (bbox_xmin IS NULL OR p.geom && ST_Transform(
            ST_MakeEnvelope(bbox_xmin, bbox_ymin, bbox_xmax, bbox_ymax, 4326), 3857));
$$;

-- === ADDRESS ===

CREATE OR REPLACE FUNCTION public.geojson_address_points(
    bbox_xmin float DEFAULT NULL,
    bbox_ymin float DEFAULT NULL,
    bbox_xmax float DEFAULT NULL,
    bbox_ymax float DEFAULT NULL,
    street_name_filter text DEFAULT NULL,
    jurisdiction_filter text DEFAULT NULL,
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
                    'building_name', building_name,
                    'building_type', building_type,
                    'street_address', street_address,
                    'full_address', full_address,
                    'jurisdiction', jurisdiction,
                    'zip_code', zip_code,
                    'fire_box', fire_box,
                    'display_text', display_text
                )
            )
        ), '[]'::jsonb)
    )
    FROM (
        SELECT * FROM address.address_point a
        WHERE (bbox_xmin IS NULL OR a.geom && ST_Transform(
            ST_MakeEnvelope(bbox_xmin, bbox_ymin, bbox_xmax, bbox_ymax, 4326), 3857))
          AND (street_name_filter IS NULL OR a.street_name ILIKE '%' || street_name_filter || '%')
          AND (jurisdiction_filter IS NULL OR a.jurisdiction = jurisdiction_filter)
        LIMIT lim
    ) sub;
$$;

-- === INCIDENTS ===

CREATE OR REPLACE FUNCTION public.geojson_incidents(
    lim int DEFAULT 500
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
                    'incident_number', incident_number,
                    'agency', agency,
                    'jurisdiction', jurisdiction,
                    'fire_box', fire_box,
                    'dispatched_determinant', dispatched_determinant,
                    'units_dispatched', units_dispatched
                )
            )
        ), '[]'::jsonb)
    )
    FROM (
        SELECT * FROM incidents.dispatched_incident
        WHERE geom IS NOT NULL
        LIMIT lim
    ) sub;
$$;

-- === GRANT EXECUTE on all functions to anon ===
-- PostgREST needs this to expose them via RPC

GRANT EXECUTE ON FUNCTION public.geojson_street_segments TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.geojson_street_dissolved TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.geojson_street_crossings TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.geojson_jurisdictions TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.geojson_neighborhoods TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.geojson_gang_territories TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.geojson_zip_codes TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.geojson_postal_zones TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.geojson_areas_of_patrol TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.geojson_points_of_interest TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.geojson_transit_routes TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.geojson_fire_boxes TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.geojson_fire_districts TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.geojson_fire_stations TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.geojson_water_supply TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.geojson_police_zones TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.geojson_address_points TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.geojson_incidents TO anon, authenticated;
