# Schema Simplification Design

## Goal

Reorganize gisdb from ~120+ tables across 11 schemas into 18 clean tables across 6 domain schemas, with real-world reference data (pgco, tiger, tiger_data) moved to a separate database.

## Naming Conventions

- snake_case for all identifiers
- No abbreviations (`building` not `bldg`, `street` not `st`)
- Booleans prefixed with `is_`
- All geometry columns named `geom`, SRID 3857
- Singular table names (`fire_station` not `fire_stations`)
- Domain-prefixed where helpful (`fire_box`, `police_primary`)

---

## Schema: `address` (2 tables, down from 12)

### `address.address_point` — 18,945 rows

Source: `address.address_cids_info_cross`

| Column | Type | Source Column | Notes |
|---|---|---|---|
| id | serial PK | fid | |
| geom | geometry(Point, 3857) | geom | NOT NULL |
| building_name | text | bldg_name | |
| building_name_alt | text | bldg_name_alt | |
| building_type | text | bldg_type | |
| building_number | text | bldg_num | |
| floor_number | text | floor_num | |
| unit_number | text | unit_num | |
| street_number | integer | st_num | |
| street_name | text | st_name | |
| street_address | text | st_address | full street line |
| full_address | text | full_address | complete formatted address |
| cross_street_1 | text | street_1 | |
| cross_street_2 | text | street_2 | |
| jurisdiction | text | jurisdiction | |
| zip_code | text | zip_code | text for consistency |
| nearest_postal_code | text | nearest_postal | |
| fire_box | text | fire_box | |
| fire_district | integer | fire_district | |
| fire_run_card | text | box_run_card | |
| police_primary | text | police_primary | |
| police_secondary | text | police_secondary | |
| police_shared | text | police_shared | |
| police_other | text | police_other | |
| police_reporting_district | text | police_reporting_district | |
| coord_x | double precision | coord_x | |
| coord_y | double precision | coord_y | |
| display_text | text | display_text | |
| updated_at | timestamptz | update_time | |

### `address.building_cids` — FK to address_point

Source: CIDS columns from `address.address_cids_info_cross` (only rows with CIDS data)

| Column | Type | Source Column |
|---|---|---|
| id | serial PK | |
| address_id | integer FK → address_point(id) | |
| fire_designation | text | cids_fd_designation |
| occupancy_type | text | cids_occupancy |
| height_stories | text | cids_bldg_height_stories |
| building_dimensions | text | cids_bldg_dimensions |
| construction_class | text | cids_class |
| construction_class_description | text | cids_class_description |
| hazards | text | cids_hazards |
| minimum_response | text | cids_minresp |
| transmitted_data | text | cids_transmitted_data |
| is_available | boolean | cids_availability |

### Dropped address tables

- `address_cids_info` — subset of cross (9,641 rows)
- `address_cids_info_cross_backup` — backup copy
- `address_cids_info_test` — test data (41 rows)
- `address_cids_police` — police-filtered subset (3,875 rows)
- `address_cids_police_fire` — police+fire subset (3,239 rows)
- `address_raster` — fire station distance analysis (9,230 rows, derivable)
- `street_address` — road centerline data (moved to street schema)
- `cadastre` — mostly empty (89 rows)
- `la_cams_address_lines` — LA real-world data → reference DB
- `la_cams_address_points` — LA real-world data → reference DB
- `la_lacounty_parcels` — LA real-world data → reference DB

---

## Schema: `street` (2 tables, down from 8)

### `street.street_segment` — ~9,663 rows

Source: `street.cross_streets` (richest per-segment table with cross-street data)

| Column | Type | Source Column | Notes |
|---|---|---|---|
| id | serial PK | fid | |
| geom | geometry(LineString, 3857) | geom | NOT NULL |
| street_name | text | name | full composed name |
| name_prefix | text | name_direction_prefix | e.g. "N", "S" |
| name_base | text | name_base | core name |
| name_type | text | name_type | e.g. "St", "Ave" |
| name_suffix | text | name_direction_suffix | e.g. "NW" |
| alt_street_name | text | name_1 | alternate name |
| alt_name_prefix | text | name_1_direction_prefix | |
| alt_name_base | text | name_1_base | |
| alt_name_type | text | name_1_type | |
| alt_name_suffix | text | name_1_direction_suffix | |
| address_range_left_from | integer | from_address_left | |
| address_range_left_to | integer | to_address_left | |
| address_range_right_from | integer | from_address_right | |
| address_range_right_to | integer | to_address_right | |
| zip_code_left | integer | zip_left | |
| zip_code_right | integer | zip_right | |
| road_class | text | tiger:cfcc | CFCC classification |
| lane_count | integer | lanes | |
| lane_count_left | integer | lanes_left | |
| lane_count_right | integer | lanes_right | |
| is_oneway | boolean | oneway | |
| speed_limit_mph | integer | max_speed_mph | |
| directionality | smallint | directionality | |
| cross_street_low | text | cross_intersection_name | |
| cross_street_low_id | text | cross_intersection_id | |
| cross_street_high | text | high_cross_intersection_name | |
| cross_street_high_id | text | high_cross_intersection_id | |
| display_text | text | display_text | |

### `street.street_dissolved` — ~1,258 rows

Source: `street.street_network_dissolved`

| Column | Type | Source Column |
|---|---|---|
| id | serial PK | |
| geom | geometry(MultiLineString, 3857) | geom |
| street_name | text | name |
| name_base | text | name_base |
| name_type | text | name_type |
| display_text | text | display_text |

### Dropped street tables

- `street_network` (1,139) — absorbed into street_segment
- `street_network_4` (12) — test data
- `street_crosses` (3,881) — redundant with cross_streets
- `street_crosses_postal` (6,694) — derivable join
- `street_crosses_4` (0) — empty
- `postal_centroids` (5,818) — derivable from postal_zone centroids

---

## Schema: `map` (8 tables, down from 14)

### `map.jurisdiction` — 36 rows

Source: `map.jurisdiction`

| Column | Type | Source Column |
|---|---|---|
| id | serial PK | fid |
| geom | geometry(MultiPolygon, 3857) | geom |
| jurisdiction_name | text | jurisdiction |
| full_jurisdiction_name | text | full_jurisdiction |
| jurisdiction_type | text | type |
| section | text | section |

### `map.neighborhood` — 100 rows

Source: `map.neighborhood` (unchanged structure)

| Column | Type |
|---|---|
| id | serial PK |
| geom | geometry(MultiPolygon, 3857) |
| neighborhood_name | text |
| neighborhood_code | text |
| district_name | text |
| district_code | text |

### `map.area_of_patrol` — 30 rows

Source: `map.aop`

| Column | Type | Source Column |
|---|---|---|
| id | serial PK | id |
| geom | geometry(MultiPolygon, 3857) | geom |
| valid_aops | text | valid_aops |
| invalid_aops | text | invalid_aops |

### `map.gang_territory` — 75 rows

Source: `map.gang`

| Column | Type | Source Column |
|---|---|---|
| id | serial PK | id |
| geom | geometry(MultiPolygon, 3857) | geom |
| is_disputed | boolean | disputed |
| gang_names | text[] | gang_1..gang_5 → array |

### `map.zip_code` — 92 rows

Source: `map.zip`

| Column | Type |
|---|---|
| id | serial PK |
| geom | geometry(MultiPolygon, 3857) |
| zip_code | text |
| display_text | text |

### `map.postal_zone` — 1,044 rows

Source: `map.postal_voronoi`

| Column | Type |
|---|---|
| id | serial PK |
| geom | geometry(Polygon, 3857) |
| postal_number | text |
| display_text | text |

### `map.point_of_interest` — ~537 rows

Source: `map.chain_markers` (431) + `map.radio_towers` (22) + `map.transit` points (84)

| Column | Type |
|---|---|
| id | serial PK |
| geom | geometry(Point, 3857) |
| poi_type | text |
| name | text |
| description | text |
| metadata | jsonb |

### `map.transit_route` — line geometries

Source: `map.transit` (if line geometries exist)

| Column | Type |
|---|---|
| id | serial PK |
| geom | geometry(MultiLineString, 3857) |
| route_name | text |
| route_type | text |

### Dropped map tables

- `map.cpn` (17,640) — denormalized join table, recreatable as view
- `map.postals` (13,228) — postal variant
- `map.postals_cids` (824) — postal+CIDS join
- `map.postals_cids_address` (1,772) — postal+address join
- `map.postals_cids_police_fire` (1,130) — postal+police+fire join
- `map.postals_staging` (0) — empty staging
- `map.postal_numbers` (1,044) — redundant with postal_zone

---

## Schema: `fire` (4 tables, down from 5)

### `fire.fire_district` — 194 rows

Source: `fire.fire_area` (renamed)

| Column | Type | Source Column |
|---|---|---|
| id | serial PK | fid |
| geom | geometry(MultiPolygon, 3857) | geom |
| station_name | text | fire_station |
| station_number | integer | station |
| box_code | text | box |
| fire_box | text | fire_box |
| first_due | text | fire_first_due |
| running_order | text | running_order |
| is_hydrant_area | boolean | hydrant_area |

### `fire.fire_box` — 1,611 rows

Source: `fire.fire_box`

| Column | Type | Source Column |
|---|---|---|
| id | serial PK | fid |
| geom | geometry(MultiPolygon, 3857) | geom |
| station_name | text | fire_station |
| station_number | integer | station |
| box_code | text | box |
| fire_box | text | fire_box |
| is_hydrant_area | boolean | hydrant_area |
| running_order | text | running_order |
| display_text | text | display_text |

### `fire.fire_station` — 9 rows

Source: `fire.fire_stations` (singularized)

| Column | Type | Source Column |
|---|---|---|
| id | serial PK | fid |
| geom | geometry(Point, 3857) | geom |
| first_due_district | integer | fire_first_due |
| station_name | text | location |
| street_name | text | street |
| full_address | text | full_address |
| jurisdiction | text | jurisdiction |
| nearest_postal_code | text | nearest_postal |
| police_primary | text | police_primary |

### `fire.water_supply` — ~1,342 rows

Source: `fire.hydrants` (947) + `fire.fdc` (395)

| Column | Type | Source Column |
|---|---|---|
| id | serial PK | fid |
| geom | geometry(Point, 3857) | geom |
| supply_type | text | — 'hydrant' or 'fdc' |
| status | text | status |
| nearest_postal_code | text | nearest_postal |
| fire_box | text | fire_box |

---

## Schema: `police` (1 table)

### `police.police_zone` — 827 rows

Source: `police.police_jurisdiction` (renamed)

| Column | Type | Source Column |
|---|---|---|
| id | serial PK | fid |
| geom | geometry(MultiPolygon, 3857) | geom |
| primary_jurisdiction | text | primary_jurisdiction |
| primary_jurisdiction_code | text | primary_jurisdiction_code |
| secondary_jurisdiction | text | secondary_jurisdiction |
| secondary_jurisdiction_code | text | secondary_jurisdiction_code |
| shared_jurisdiction | text | shared_jurisdiction |
| shared_jurisdiction_code | text | shared_jurisdiction_code |
| other_jurisdiction | text | other_jurisdiction |
| other_jurisdiction_code | text | other_jurisdiction_code |
| reporting_district | smallint | reporting_district |
| precinct | smallint | precinct |
| beat | smallint | beat |
| bureau | text | bureau |

---

## Schema: `incidents` (1 table)

### `incidents.dispatched_incident` — 1,401 rows

Source: `incidents.dispatched_incidents` (singularized, structure preserved)

---

## Reference Data Migration

Move these schemas to a separate `gisdb_reference` database:
- `pgco` — PG County data (268K parcels, parks, roads, utilities)
- `tiger` — Census TIGER framework tables
- `tiger_data` — Real-world MD/NY/AA/PG datasets

Also drop:
- `address.la_cams_address_lines` (391K rows)
- `address.la_cams_address_points` (2.7M rows)
- `address.la_lacounty_parcels` (2.4M rows)
- `public.test` (empty)
- `topology.*` (empty PostGIS topology tables)

---

## Summary

| Schema | Before | After |
|---|---|---|
| address | 12 tables | 2 tables |
| street | 8 tables | 2 tables |
| map | 14 tables | 8 tables |
| fire | 5 tables | 4 tables |
| police | 1 table | 1 table |
| incidents | 1 table | 1 table |
| pgco/tiger/tiger_data | 80+ tables | → separate reference DB |
| **Total** | **~120+ tables** | **18 tables** |
