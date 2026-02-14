# gisdb — Comprehensive Database Inventory

> Generated: 2026-02-14 01:13:57 UTC

**PostgreSQL Version:** PostgreSQL 15.1, compiled by Visual C++ build 1914, 64-bit

**Database Size:** 50 MB

## Extensions

| Extension | Version |
| --- | --- |
| address_standardizer | 3.3.1 |
| address_standardizer_data_us | 3.3.1 |
| fuzzystrmatch | 1.1 |
| plpgsql | 1.0 |
| postgis | 3.3.1 |
| postgis_raster | 3.3.1 |
| postgis_sfcgal | 3.3.1 |

## Schemas

- `address`
- `fire`
- `incidents`
- `map`
- `police`
- `public`
- `street`

## Table Inventory

### `address.address_point`

- **Rows:** 18,945
- **Total Size:** 9032 kB  |  **Table:** 7176 kB  |  **Indexes:** 1856 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('address.address_point_id_seq'::regclass) |  |
| geom | USER-DEFINED | NO |  |  |
| building_name | text | YES |  |  |
| building_name_alt | text | YES |  |  |
| building_type | text | YES |  |  |
| building_number | text | YES |  |  |
| floor_number | text | YES |  |  |
| unit_number | text | YES |  |  |
| street_number | integer | YES |  |  |
| street_name | text | YES |  |  |
| street_address | text | YES |  |  |
| full_address | text | YES |  |  |
| cross_street_1 | text | YES |  |  |
| cross_street_2 | text | YES |  |  |
| jurisdiction | text | YES |  |  |
| zip_code | text | YES |  |  |
| nearest_postal_code | text | YES |  |  |
| fire_box | text | YES |  |  |
| fire_district | integer | YES |  |  |
| fire_run_card | text | YES |  |  |
| police_primary | text | YES |  |  |
| police_secondary | text | YES |  |  |
| police_shared | text | YES |  |  |
| police_other | text | YES |  |  |
| police_reporting_district | text | YES |  |  |
| coord_x | double precision | YES |  |  |
| coord_y | double precision | YES |  |  |
| display_text | text | YES |  |  |
| updated_at | timestamp with time zone | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| address_point_pkey | PRIMARY KEY | id |  |

### `address.building_cids`

- **Rows:** 1,446
- **Total Size:** 416 kB  |  **Table:** 320 kB  |  **Indexes:** 96 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('address.building_cids_id_seq'::regclass) |  |
| address_id | integer | NO |  |  |
| fire_designation | text | YES |  |  |
| occupancy_type | text | YES |  |  |
| height_stories | text | YES |  |  |
| building_dimensions | text | YES |  |  |
| construction_class | text | YES |  |  |
| construction_class_description | text | YES |  |  |
| hazards | text | YES |  |  |
| minimum_response | text | YES |  |  |
| transmitted_data | text | YES |  |  |
| is_available | boolean | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| building_cids_address_id_fkey | FOREIGN KEY | address_id | address.address_point(id) |
| building_cids_pkey | PRIMARY KEY | id |  |

### `fire.fire_box`

- **Rows:** 1,610
- **Total Size:** 1472 kB  |  **Table:** 1296 kB  |  **Indexes:** 176 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('fire.fire_box_id_seq'::regclass) |  |
| geom | USER-DEFINED | NO |  |  |
| station_name | text | YES |  |  |
| station_number | integer | YES |  |  |
| box_code | text | YES |  |  |
| fire_box | text | YES |  |  |
| is_hydrant_area | boolean | YES |  |  |
| running_order | text | YES |  |  |
| display_text | text | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| fire_box_pkey | PRIMARY KEY | id |  |

### `fire.fire_district`

- **Rows:** 194
- **Total Size:** 264 kB  |  **Table:** 240 kB  |  **Indexes:** 24 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('fire.fire_district_id_seq'::regclass) |  |
| geom | USER-DEFINED | NO |  |  |
| station_name | text | YES |  |  |
| station_number | integer | YES |  |  |
| box_code | text | YES |  |  |
| fire_box | text | YES |  |  |
| first_due | text | YES |  |  |
| running_order | text | YES |  |  |
| is_hydrant_area | boolean | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| fire_district_pkey | PRIMARY KEY | id |  |

### `fire.fire_station`

- **Rows:** 9
- **Total Size:** 40 kB  |  **Table:** 16 kB  |  **Indexes:** 24 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('fire.fire_station_id_seq'::regclass) |  |
| geom | USER-DEFINED | NO |  |  |
| first_due_district | integer | YES |  |  |
| station_name | text | YES |  |  |
| street_name | text | YES |  |  |
| full_address | text | YES |  |  |
| jurisdiction | text | YES |  |  |
| nearest_postal_code | text | YES |  |  |
| police_primary | text | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| fire_station_pkey | PRIMARY KEY | id |  |

### `fire.water_supply`

- **Rows:** 1,342
- **Total Size:** 296 kB  |  **Table:** 160 kB  |  **Indexes:** 136 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('fire.water_supply_id_seq'::regclass) |  |
| geom | USER-DEFINED | NO |  |  |
| supply_type | text | NO |  |  |
| status | text | YES |  |  |
| nearest_postal_code | text | YES |  |  |
| fire_box | text | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| water_supply_pkey | PRIMARY KEY | id |  |

### `incidents.dispatched_incident`

- **Rows:** 1,401
- **Total Size:** 1968 kB  |  **Table:** 1856 kB  |  **Indexes:** 112 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('incidents.dispatched_incident_id_seq'::regclass) |  |
| geom | USER-DEFINED | YES |  |  |
| jurisdiction | text | YES |  |  |
| zip_code | text | YES |  |  |
| nearest_postal_code | text | YES |  |  |
| fire_box | text | YES |  |  |
| coord_x | double precision | YES |  |  |
| coord_y | double precision | YES |  |  |
| fire_district | integer | YES |  |  |
| police_primary | text | YES |  |  |
| police_secondary | text | YES |  |  |
| police_shared | text | YES |  |  |
| police_other | text | YES |  |  |
| fire_run_card | text | YES |  |  |
| police_reporting_district | text | YES |  |  |
| incident_number | integer | YES |  |  |
| server_number | character varying | YES |  | 2 |
| agency | character varying | YES |  | 2 |
| units_recommended | ARRAY | YES |  |  |
| units_dispatched | ARRAY | YES |  |  |
| modifying_circumstances | ARRAY | YES |  |  |
| dispatched_determinant | text | YES |  |  |
| dispatched_protocol | character varying | YES |  | 3 |
| dispatched_level | character varying | YES |  | 2 |
| cad_notes | text | YES |  |  |
| time_created | time without time zone | YES |  |  |
| time_dispatched | time without time zone | YES |  |  |
| time_en_route | time without time zone | YES |  |  |
| time_on_scene | time without time zone | YES |  |  |
| time_under_control | time without time zone | YES |  |  |
| time_cleared | time without time zone | YES |  |  |
| time_closed | time without time zone | YES |  |  |
| duration_on_scene | real | YES |  |  |
| patient_transport | text | YES |  |  |
| patient_arrival | text | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| dispatched_incident_pkey | PRIMARY KEY | id |  |

### `map.area_of_patrol`

- **Rows:** 30
- **Total Size:** 368 kB  |  **Table:** 344 kB  |  **Indexes:** 24 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('map.area_of_patrol_id_seq'::regclass) |  |
| geom | USER-DEFINED | NO |  |  |
| valid_aops | text | YES |  |  |
| invalid_aops | text | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| area_of_patrol_pkey | PRIMARY KEY | id |  |

### `map.gang_territory`

- **Rows:** 75
- **Total Size:** 96 kB  |  **Table:** 72 kB  |  **Indexes:** 24 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('map.gang_territory_id_seq'::regclass) |  |
| geom | USER-DEFINED | NO |  |  |
| is_disputed | boolean | YES |  |  |
| gang_names | ARRAY | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| gang_territory_pkey | PRIMARY KEY | id |  |

### `map.jurisdiction`

- **Rows:** 36
- **Total Size:** 288 kB  |  **Table:** 264 kB  |  **Indexes:** 24 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('map.jurisdiction_id_seq'::regclass) |  |
| geom | USER-DEFINED | NO |  |  |
| jurisdiction_name | text | YES |  |  |
| full_jurisdiction_name | text | YES |  |  |
| jurisdiction_type | text | YES |  |  |
| section | text | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| jurisdiction_pkey | PRIMARY KEY | id |  |

### `map.neighborhood`

- **Rows:** 100
- **Total Size:** 448 kB  |  **Table:** 424 kB  |  **Indexes:** 24 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('map.neighborhood_id_seq'::regclass) |  |
| geom | USER-DEFINED | NO |  |  |
| neighborhood_name | text | YES |  |  |
| neighborhood_code | text | YES |  |  |
| district_name | text | YES |  |  |
| district_code | text | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| neighborhood_pkey | PRIMARY KEY | id |  |

### `map.point_of_interest`

- **Rows:** 453
- **Total Size:** 256 kB  |  **Table:** 184 kB  |  **Indexes:** 72 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('map.point_of_interest_id_seq'::regclass) |  |
| geom | USER-DEFINED | NO |  |  |
| poi_type | text | NO |  |  |
| name | text | YES |  |  |
| description | text | YES |  |  |
| metadata | jsonb | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| point_of_interest_pkey | PRIMARY KEY | id |  |

### `map.postal_zone`

- **Rows:** 1,044
- **Total Size:** 376 kB  |  **Table:** 248 kB  |  **Indexes:** 128 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('map.postal_zone_id_seq'::regclass) |  |
| geom | USER-DEFINED | NO |  |  |
| postal_number | text | YES |  |  |
| display_text | text | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| postal_zone_pkey | PRIMARY KEY | id |  |

### `map.transit_route`

- **Rows:** 84
- **Total Size:** 224 kB  |  **Table:** 200 kB  |  **Indexes:** 24 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('map.transit_route_id_seq'::regclass) |  |
| geom | USER-DEFINED | NO |  |  |
| route_name | text | YES |  |  |
| route_type | text | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| transit_route_pkey | PRIMARY KEY | id |  |

### `map.zip_code`

- **Rows:** 92
- **Total Size:** 296 kB  |  **Table:** 272 kB  |  **Indexes:** 24 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('map.zip_code_id_seq'::regclass) |  |
| geom | USER-DEFINED | NO |  |  |
| zip_code | text | YES |  |  |
| display_text | text | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| zip_code_pkey | PRIMARY KEY | id |  |

### `police.police_zone`

- **Rows:** 827
- **Total Size:** 1112 kB  |  **Table:** 1016 kB  |  **Indexes:** 96 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('police.police_zone_id_seq'::regclass) |  |
| geom | USER-DEFINED | NO |  |  |
| primary_jurisdiction | text | YES |  |  |
| primary_jurisdiction_code | text | YES |  |  |
| secondary_jurisdiction | text | YES |  |  |
| secondary_jurisdiction_code | text | YES |  |  |
| shared_jurisdiction | text | YES |  |  |
| shared_jurisdiction_code | text | YES |  |  |
| other_jurisdiction | text | YES |  |  |
| other_jurisdiction_code | text | YES |  |  |
| reporting_district | smallint | YES |  |  |
| precinct | smallint | YES |  |  |
| beat | smallint | YES |  |  |
| bureau | text | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| police_zone_pkey | PRIMARY KEY | id |  |

### `public.spatial_ref_sys`

- **Rows:** 8,500
- **Total Size:** 7144 kB  |  **Table:** 6936 kB  |  **Indexes:** 208 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| srid | integer | NO |  |  |
| auth_name | character varying | YES |  | 256 |
| auth_srid | integer | YES |  |  |
| srtext | character varying | YES |  | 2048 |
| proj4text | character varying | YES |  | 2048 |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| spatial_ref_sys_pkey | PRIMARY KEY | srid |  |

### `public.us_gaz`

- **Rows:** 1,074
- **Total Size:** 160 kB  |  **Table:** 120 kB  |  **Indexes:** 40 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('us_gaz_id_seq'::regclass) |  |
| seq | integer | YES |  |  |
| word | text | YES |  |  |
| stdword | text | YES |  |  |
| token | integer | YES |  |  |
| is_custom | boolean | NO | true |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| pk_us_gaz | PRIMARY KEY | id |  |

### `public.us_lex`

- **Rows:** 2,938
- **Total Size:** 304 kB  |  **Table:** 224 kB  |  **Indexes:** 80 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('us_lex_id_seq'::regclass) |  |
| seq | integer | YES |  |  |
| word | text | YES |  |  |
| stdword | text | YES |  |  |
| token | integer | YES |  |  |
| is_custom | boolean | NO | true |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| pk_us_lex | PRIMARY KEY | id |  |

### `public.us_rules`

- **Rows:** 4,369
- **Total Size:** 456 kB  |  **Table:** 344 kB  |  **Indexes:** 112 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('us_rules_id_seq'::regclass) |  |
| rule | text | YES |  |  |
| is_custom | boolean | NO | true |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| pk_us_rules | PRIMARY KEY | id |  |

### `street.street_dissolved`

- **Rows:** 1,258
- **Total Size:** 600 kB  |  **Table:** 488 kB  |  **Indexes:** 112 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('street.street_dissolved_id_seq'::regclass) |  |
| geom | USER-DEFINED | NO |  |  |
| street_name | text | YES |  |  |
| name_base | text | YES |  |  |
| name_type | text | YES |  |  |
| display_text | text | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| street_dissolved_pkey | PRIMARY KEY | id |  |

### `street.street_crossing`

- **Rows:** 2,175

Computed intersection points where streets meet. Canonical alphabetical ordering (street_name_1 < street_name_2). N-way intersections produce pairwise rows. is_valid auto-flagged false for likely grade-separated crossings (freeways A15, ramps A63, railroads B1x).

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('street.street_crossing_id_seq'::regclass) |  |
| geom | USER-DEFINED | NO |  |  |
| street_name_1 | text | YES |  |  |
| street_name_2 | text | YES |  |  |
| display_text | text | YES |  |  |
| is_valid | boolean | YES | true |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| street_crossing_pkey | PRIMARY KEY | id |  |

### `street.street_segment`

- **Rows:** 9,663
- **Total Size:** 4520 kB  |  **Table:** 3792 kB  |  **Indexes:** 728 kB

**Columns**

| Column | Type | Nullable | Default | Max Length |
| --- | --- | --- | --- | --- |
| id | integer | NO | nextval('street.street_segment_id_seq'::regclass) |  |
| geom | USER-DEFINED | NO |  |  |
| street_name | text | YES |  |  |
| name_prefix | text | YES |  |  |
| name_base | text | YES |  |  |
| name_type | text | YES |  |  |
| name_suffix | text | YES |  |  |
| alt_street_name | text | YES |  |  |
| alt_name_prefix | text | YES |  |  |
| alt_name_base | text | YES |  |  |
| alt_name_type | text | YES |  |  |
| alt_name_suffix | text | YES |  |  |
| address_range_left_from | integer | YES |  |  |
| address_range_left_to | integer | YES |  |  |
| address_range_right_from | integer | YES |  |  |
| address_range_right_to | integer | YES |  |  |
| zip_code_left | integer | YES |  |  |
| zip_code_right | integer | YES |  |  |
| road_class | text | YES |  |  |
| lane_count | integer | YES |  |  |
| lane_count_left | integer | YES |  |  |
| lane_count_right | integer | YES |  |  |
| is_oneway | boolean | YES |  |  |
| speed_limit_mph | integer | YES |  |  |
| directionality | smallint | YES |  |  |
| cross_street_low | text | YES |  |  |
| cross_street_low_id | text | YES |  |  |
| cross_street_high | text | YES |  |  |
| cross_street_high_id | text | YES |  |  |
| display_text | text | YES |  |  |

**Constraints**

| Constraint | Type | Columns | FK Reference |
| --- | --- | --- | --- |
| street_segment_pkey | PRIMARY KEY | id |  |

## Spatial Data

### `address.address_point` — `geom`

- **Geometry Type:** POINT
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`
- **Extent:** `POLYGON((-4097.192591102321 -3733.8323442129213,-4097.192591102321 9282.804678445718,4296.694525164903 9282.804678445718,4296.694525164903 -3733.8323442129213,-4097.192591102321 -3733.8323442129213))`
- **Sample:** `POINT(241.1744920844847 -1028.9737397377423)`

### `fire.fire_box` — `geom`

- **Geometry Type:** MULTIPOLYGON
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`
- **Extent:** `POLYGON((-4144.951547399392 -4083.225030508888,-4144.951547399392 9361.328464152177,4854.730044835465 9361.328464152177,4854.730044835465 -4083.225030508888,-4144.951547399392 -4083.225030508888))`
- **Sample:** `MULTIPOLYGON(((429.61855058862074 2604.944912295209,369.7601365184456 2592.8387161911287,320.8308065509707 2566.7513318745955,319.64738325240467 2566.0677995154474,318.0898969134101 2561.485539598299,...`

### `fire.fire_district` — `geom`

- **Geometry Type:** MULTIPOLYGON
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`
- **Extent:** `POLYGON((-4144.951547399392 -4083.225030508888,-4144.951547399392 9361.328464152177,4854.730044835465 9361.328464152177,4854.730044835465 -4083.225030508888,-4144.951547399392 -4083.225030508888))`
- **Sample:** `MULTIPOLYGON(((1030.5969891419425 321.93201893415704,1058.6289908948102 355.41705446265837,1099.1007259483422 400.61759224349834,1117.302263589982 393.16983554393363,1118.015936857572 385.153129270411...`

### `fire.fire_station` — `geom`

- **Geometry Type:** POINT
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`
- **Extent:** `POLYGON((-1582.446707052181 -2423.0924024682818,-1582.446707052181 6119.348253569535,1792.9017147945804 6119.348253569535,1792.9017147945804 -2423.0924024682818,-1582.446707052181 -2423.0924024682818))`
- **Sample:** `POINT(1706.6921633944442 3553.7141179075925)`

### `fire.water_supply` — `geom`

- **Geometry Type:** POINT
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`
- **Extent:** `POLYGON((-3549.593197361943 -4544.139877166135,-3549.593197361943 8239.87966603761,4540.051460554194 8239.87966603761,4540.051460554194 -4544.139877166135,-3549.593197361943 -4544.139877166135))`
- **Sample:** `POINT(-593.4603202255474 6848.606969716922)`

### `incidents.dispatched_incident` — `geom`

- **Geometry Type:** POINT
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`
- **Extent:** `POLYGON((-3226.5183801750954 -3156.529646269435,-3226.5183801750954 7800.487306988247,3761.7387534075397 7800.487306988247,3761.7387534075397 -3156.529646269435,-3226.5183801750954 -3156.529646269435))`
- **Sample:** `POINT(-382.0796873105395 338.20721991255823)`

### `map.area_of_patrol` — `geom`

- **Geometry Type:** MULTIPOLYGON
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`
- **Extent:** `POLYGON((-4029.4242237952453 -4083.2250000000004,-4029.4242237952453 8154.152609256079,4814.801700915159 8154.152609256079,4814.801700915159 -4083.2250000000004,-4029.4242237952453 -4083.2250000000004))`
- **Sample:** `MULTIPOLYGON(((-429.76851864572916 -1068.1062371188837,-428.2823990828121 -1040.3653386110993,-428.23351022172767 -1039.7777193124152,-424.06959009999684 -1002.9193152719091,-427.97354760828665 -993.3...`

### `map.gang_territory` — `geom`

- **Geometry Type:** MULTIPOLYGON
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`
- **Extent:** `POLYGON((-3416.143957531509 -3547.2397919898226,-3416.143957531509 7626.4359629469245,2607.9126155368795 7626.4359629469245,2607.9126155368795 -3547.2397919898226,-3416.143957531509 -3547.2397919898226))`
- **Sample:** `MULTIPOLYGON(((-324.9459444123381 4340.922563879801,-371.6282084575135 4373.973606823785,-411.90358661275985 4317.087479485867,-365.87209490625105 4286.172419275681,-324.9459444123381 4340.92256387980...`

### `map.jurisdiction` — `geom`

- **Geometry Type:** MULTIPOLYGON
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`
- **Extent:** `POLYGON((-3879.0635611072903 -3608.911696594271,-3879.0635611072903 9102.50365635997,4262.799421757527 9102.50365635997,4262.799421757527 -3608.911696594271,-3879.0635611072903 -3608.911696594271))`
- **Sample:** `MULTIPOLYGON(((2752.6230209096348 4125.297868732723,2750.7160183614096 4088.4291528003737,2711.940299880836 4085.4627043920236,2715.542415805261 4135.044770645873,2706.21929223616 4210.9010942308205,2...`

### `map.neighborhood` — `geom`

- **Geometry Type:** MULTIPOLYGON
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`
- **Extent:** `POLYGON((-4144.951547399392 -4083.225030508888,-4144.951547399392 9361.328464152177,4814.801700915159 9361.328464152177,4814.801700915159 -4083.225030508888,-4144.951547399392 -4083.225030508888))`
- **Sample:** `MULTIPOLYGON(((-132.93430305210526 4260.208772203455,-148.29980314006923 4246.137550600065,-152.23704047935146 4250.0144169667965,-165.76623223480937 4260.751870740969,-173.4971989522139 4270.63032821...`

### `map.point_of_interest` — `geom`

- **Geometry Type:** POINT
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`
- **Extent:** `POLYGON((-2267.9223468577934 -3269.569008973233,-2267.9223468577934 6670.8592772984875,3511.184692559079 6670.8592772984875,3511.184692559079 -3269.569008973233,-2267.9223468577934 -3269.569008973233))`
- **Sample:** `POINT(2785.643277131892 3224.5909183095705)`

### `map.postal_zone` — `geom`

- **Geometry Type:** POLYGON
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`
- **Extent:** `POLYGON((-5670.308316788396 -6638.7255452557,-5670.308316788396 12028.22202234649,5714.4815269401 12028.22202234649,5714.4815269401 -6638.7255452557,-5670.308316788396 -6638.7255452557))`
- **Sample:** `POLYGON((-1826.9792530400591 -1808.9824574001445,-1633.1037121173256 -1844.6151545017178,-1394.642792043965 -1985.116776422876,-1282.1366334509014 -2142.9308450375806,-1374.003633770833 -2375.58104065...`

### `map.transit_route` — `geom`

- **Geometry Type:** MULTILINESTRING
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`
- **Extent:** `POLYGON((-3217.3536357349035 -2973.1563161643207,-3217.3536357349035 6553.763259125844,2649.5484679233023 6553.763259125844,2649.5484679233023 -2973.1563161643207,-3217.3536357349035 -2973.1563161643207))`
- **Sample:** `MULTILINESTRING((-1454.6309906481765 -761.3035372481551,-1445.8441643001502 -752.1154423101339,-1484.127638196995 -723.1128105700998,-1528.7143507253415 -684.7519963219481,-1599.2100809414503 -627.984...`

### `map.zip_code` — `geom`

- **Geometry Type:** MULTIPOLYGON
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`
- **Extent:** `POLYGON((-3416.143957531509 -3608.911697206677,-3416.143957531509 7696.101862778689,4262.799421757527 7696.101862778689,4262.799421757527 -3608.911697206677,-3416.143957531509 -3608.911697206677))`
- **Sample:** `MULTIPOLYGON(((636.0177474329937 -1764.4205597211978,636.0177474329938 -1722.376577227657,640.1947669267444 -1642.0492792709158,640.1947669267444 -1638.5148781608193,642.76524046136 -1636.265713818030...`

### `police.police_zone` — `geom`

- **Geometry Type:** MULTIPOLYGON
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`
- **Extent:** `POLYGON((-4144.951547399392 -4083.225030508888,-4144.951547399392 9361.328464152177,4814.801700915159 9361.328464152177,4814.801700915159 -4083.225030508888,-4144.951547399392 -4083.225030508888))`
- **Sample:** `MULTIPOLYGON(((2339.2109280936656 1179.7377113736636,2345.7589912933827 1172.1003761429633,2350.2718194721997 1171.2794649721804,2347.50585961023 1168.852067289322,2352.48939248354 1161.4998031824962,...`

### `street.street_dissolved` — `geom`

- **Geometry Type:** MULTILINESTRING
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`
- **Extent:** `POLYGON((-3217.3536357349035 -3355.060647551135,-3217.3536357349035 7011.699609476209,3818.6702215793157 7011.699609476209,3818.6702215793157 -3355.060647551135,-3217.3536357349035 -3355.060647551135))`
- **Sample:** `MULTILINESTRING((-590.3415123052756 6085.524747411921,-572.7090193672908 6062.796158249085,-555.586136051791 6045.367509160094,-544.4766462816156 6034.56378516341,-532.4498591909669 6030.996517806014,...`

### `street.street_crossing` — `geom`

- **Geometry Type:** POINT
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`

### `street.street_segment` — `geom`

- **Geometry Type:** MULTILINESTRING
- **SRID:** 3857
- **Dimensions:** 2
- **SRS:** EPSG:3857
- **Proj4:** `+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs`
- **Extent:** `POLYGON((-3217.3536357349035 -3355.060647551135,-3217.3536357349035 7011.699609476209,3818.6702215793157 7011.699609476209,3818.6702215793157 -3355.060647551135,-3217.3536357349035 -3355.060647551135))`
- **Sample:** `MULTILINESTRING((755.1770445418421 1180.3901712053578,766.1912612684766 1188.9142171937967,786.5055580318761 1193.8569749530436,800.1445813744197 1199.5184563405146,810.6955239601609 1205.951957917186...`

## Indexes

| Table | Index | Size | Type | Definition |
| --- | --- | --- | --- | --- |
| address.address_point | address_point_pkey | 432 kB | btree | USING btree (id) |
| address.address_point | idx_address_point_fire_box | 160 kB | btree | USING btree (fire_box) |
| address.address_point | idx_address_point_geom | 760 kB | gist (spatial) | USING gist (geom) |
| address.address_point | idx_address_point_jurisdiction | 160 kB | btree | USING btree (jurisdiction) |
| address.address_point | idx_address_point_street_name | 192 kB | btree | USING btree (street_name) |
| address.address_point | idx_address_point_zip_code | 152 kB | btree | USING btree (zip_code) |
| address.building_cids | building_cids_pkey | 48 kB | btree | USING btree (id) |
| address.building_cids | idx_building_cids_address_id | 48 kB | btree | USING btree (address_id) |
| fire.fire_box | fire_box_pkey | 56 kB | btree | USING btree (id) |
| fire.fire_box | idx_fire_box_code | 48 kB | btree | USING btree (fire_box) |
| fire.fire_box | idx_fire_box_geom | 72 kB | gist (spatial) | USING gist (geom) |
| fire.fire_district | fire_district_pkey | 16 kB | btree | USING btree (id) |
| fire.fire_district | idx_fire_district_geom | 8192 bytes | gist (spatial) | USING gist (geom) |
| fire.fire_station | fire_station_pkey | 16 kB | btree | USING btree (id) |
| fire.fire_station | idx_fire_station_geom | 8192 bytes | gist (spatial) | USING gist (geom) |
| fire.water_supply | idx_water_supply_geom | 56 kB | gist (spatial) | USING gist (geom) |
| fire.water_supply | idx_water_supply_type | 32 kB | btree | USING btree (supply_type) |
| fire.water_supply | water_supply_pkey | 48 kB | btree | USING btree (id) |
| incidents.dispatched_incident | dispatched_incident_pkey | 48 kB | btree | USING btree (id) |
| incidents.dispatched_incident | idx_dispatched_incident_geom | 64 kB | gist (spatial) | USING gist (geom) |
| map.area_of_patrol | area_of_patrol_pkey | 16 kB | btree | USING btree (id) |
| map.area_of_patrol | idx_area_of_patrol_geom | 8192 bytes | gist (spatial) | USING gist (geom) |
| map.gang_territory | gang_territory_pkey | 16 kB | btree | USING btree (id) |
| map.gang_territory | idx_gang_territory_geom | 8192 bytes | gist (spatial) | USING gist (geom) |
| map.jurisdiction | idx_jurisdiction_geom | 8192 bytes | gist (spatial) | USING gist (geom) |
| map.jurisdiction | jurisdiction_pkey | 16 kB | btree | USING btree (id) |
| map.neighborhood | idx_neighborhood_geom | 8192 bytes | gist (spatial) | USING gist (geom) |
| map.neighborhood | neighborhood_pkey | 16 kB | btree | USING btree (id) |
| map.point_of_interest | idx_poi_geom | 24 kB | gist (spatial) | USING gist (geom) |
| map.point_of_interest | idx_poi_type | 16 kB | btree | USING btree (poi_type) |
| map.point_of_interest | point_of_interest_pkey | 32 kB | btree | USING btree (id) |
| map.postal_zone | idx_postal_zone_geom | 48 kB | gist (spatial) | USING gist (geom) |
| map.postal_zone | idx_postal_zone_number | 40 kB | btree | USING btree (postal_number) |
| map.postal_zone | postal_zone_pkey | 40 kB | btree | USING btree (id) |
| map.transit_route | idx_transit_route_geom | 8192 bytes | gist (spatial) | USING gist (geom) |
| map.transit_route | transit_route_pkey | 16 kB | btree | USING btree (id) |
| map.zip_code | idx_zip_code_geom | 8192 bytes | gist (spatial) | USING gist (geom) |
| map.zip_code | zip_code_pkey | 16 kB | btree | USING btree (id) |
| police.police_zone | idx_police_zone_geom | 40 kB | gist (spatial) | USING gist (geom) |
| police.police_zone | idx_police_zone_primary | 16 kB | btree | USING btree (primary_jurisdiction_code) |
| police.police_zone | police_zone_pkey | 40 kB | btree | USING btree (id) |
| public.spatial_ref_sys | spatial_ref_sys_pkey | 208 kB | btree | USING btree (srid) |
| public.us_gaz | pk_us_gaz | 40 kB | btree | USING btree (id) |
| public.us_lex | pk_us_lex | 80 kB | btree | USING btree (id) |
| public.us_rules | pk_us_rules | 112 kB | btree | USING btree (id) |
| street.street_dissolved | idx_street_dissolved_geom | 64 kB | gist (spatial) | USING gist (geom) |
| street.street_dissolved | street_dissolved_pkey | 48 kB | btree | USING btree (id) |
| street.street_crossing | idx_street_crossing_geom | 56 kB | gist (spatial) | USING gist (geom) |
| street.street_crossing | idx_street_crossing_street_name_1 | 56 kB | btree | USING btree (street_name_1) |
| street.street_crossing | idx_street_crossing_street_name_2 | 56 kB | btree | USING btree (street_name_2) |
| street.street_crossing | street_crossing_pkey | 48 kB | btree | USING btree (id) |
| street.street_segment | idx_street_segment_geom | 392 kB | gist (spatial) | USING gist (geom) |
| street.street_segment | idx_street_segment_name | 104 kB | btree | USING btree (street_name) |
| street.street_segment | street_segment_pkey | 232 kB | btree | USING btree (id) |

## Views

### `public.geography_columns`

```sql
SELECT current_database() AS f_table_catalog,
    n.nspname AS f_table_schema,
    c.relname AS f_table_name,
    a.attname AS f_geography_column,
    postgis_typmod_dims(a.atttypmod) AS coord_dimension,
    postgis_typmod_srid(a.atttypmod) AS srid,
    postgis_typmod_type(a.atttypmod) AS type
   FROM pg_class c,
    pg_attribute a,
    pg_type t,
    pg_namespace n
  WHERE ((t.typname = 'geography'::name) AND (a.attisdropped = false) AND (a.atttypid = t.oid) AND (a.attrelid = c.oid) AND (c.relnamespace = n.oid) AND (c.relkind = ANY (ARRAY['r'::"char", 'v'::"char", 'm'::"char", 'f'::"char", 'p'::"char"])) AND (NOT pg_is_other_temp_schema(c.relnamespace)) AND has_table_privilege(c.oid, 'SELECT'::text));
```

### `public.geometry_columns`

```sql
SELECT (current_database())::character varying(256) AS f_table_catalog,
    n.nspname AS f_table_schema,
    c.relname AS f_table_name,
    a.attname AS f_geometry_column,
    COALESCE(postgis_typmod_dims(a.atttypmod), sn.ndims, 2) AS coord_dimension,
    COALESCE(NULLIF(postgis_typmod_srid(a.atttypmod), 0), sr.srid, 0) AS srid,
    (replace(replace(COALESCE(NULLIF(upper(postgis_typmod_type(a.atttypmod)), 'GEOMETRY'::text), st.type, 'GEOMETRY'::text), 'ZM'::text, ''::text), 'Z'::text, ''::text))::character varying(30) AS type
   FROM ((((((pg_class c
     JOIN pg_attribute a ON (((a.attrelid = c.oid) AND (NOT a.attisdropped))))
     JOIN pg_namespace n ON ((c.relnamespace = n.oid)))
     JOIN pg_type t ON ((a.atttypid = t.oid)))
     LEFT JOIN ( SELECT s.connamespace,
            s.conrelid,
            s.conkey,
            replace(split_part(s.consrc, ''''::text, 2), ')'::text, ''::text) AS type
           FROM ( SELECT pg_constraint.connamespace,
                    pg_constraint.conrelid,
                    pg_constraint.conkey,
                    pg_get_constraintdef(pg_constraint.oid) AS consrc
                   FROM pg_constraint) s
          WHERE (s.consrc ~~* '%geometrytype(% = %'::text)) st ON (((st.connamespace = n.oid) AND (st.conrelid = c.oid) AND (a.attnum = ANY (st.conkey)))))
     LEFT JOIN ( SELECT s.connamespace,
            s.conrelid,
            s.conkey,
            (replace(split_part(s.consrc, ' = '::text, 2), ')'::text, ''::text))::integer AS ndims
           FROM ( SELECT pg_constraint.connamespace,
                    pg_constraint.conrelid,
                    pg_constraint.conkey,
                    pg_get_constraintdef(pg_constraint.oid) AS consrc
                   FROM pg_constraint) s
          WHERE (s.consrc ~~* '%ndims(% = %'::text)) sn ON (((sn.connamespace = n.oid) AND (sn.conrelid = c.oid) AND (a.attnum = ANY (sn.conkey)))))
     LEFT JOIN ( SELECT s.connamespace,
            s.conrelid,
            s.conkey,
            (replace(replace(split_part(s.consrc, ' = '::text, 2), ')'::text, ''::text), '('::text, ''::text))::integer AS srid
           FROM ( SELECT pg_constraint.connamespace,
                    pg_constraint.conrelid,
                    pg_constraint.conkey,
                    pg_get_constraintdef(pg_constraint.oid) AS consrc
                   FROM pg_constraint) s
          WHERE (s.consrc ~~* '%srid(% = %'::text)) sr ON (((sr.connamespace = n.oid) AND (sr.conrelid = c.oid) AND (a.attnum = ANY (sr.conkey)))))
  WHERE ((c.relkind = ANY (ARRAY['r'::"char", 'v'::"char", 'm'::"char", 'f'::"char", 'p'::"char"])) AND (NOT (c.relname = 'raster_columns'::name)) AND (t.typname = 'geometry'::name) AND (NOT pg_is_other_temp_schema(c.relnamespace)) AND has_table_privilege(c.oid, 'SELECT'::text));
```

### `public.raster_columns`

```sql
SELECT current_database() AS r_table_catalog,
    n.nspname AS r_table_schema,
    c.relname AS r_table_name,
    a.attname AS r_raster_column,
    COALESCE(_raster_constraint_info_srid(n.nspname, c.relname, a.attname), ( SELECT st_srid('010100000000000000000000000000000000000000'::geometry) AS st_srid)) AS srid,
    _raster_constraint_info_scale(n.nspname, c.relname, a.attname, 'x'::bpchar) AS scale_x,
    _raster_constraint_info_scale(n.nspname, c.relname, a.attname, 'y'::bpchar) AS scale_y,
    _raster_constraint_info_blocksize(n.nspname, c.relname, a.attname, 'width'::text) AS blocksize_x,
    _raster_constraint_info_blocksize(n.nspname, c.relname, a.attname, 'height'::text) AS blocksize_y,
    COALESCE(_raster_constraint_info_alignment(n.nspname, c.relname, a.attname), false) AS same_alignment,
    COALESCE(_raster_constraint_info_regular_blocking(n.nspname, c.relname, a.attname), false) AS regular_blocking,
    _raster_constraint_info_num_bands(n.nspname, c.relname, a.attname) AS num_bands,
    _raster_constraint_info_pixel_types(n.nspname, c.relname, a.attname) AS pixel_types,
    _raster_constraint_info_nodata_values(n.nspname, c.relname, a.attname) AS nodata_values,
    _raster_constraint_info_out_db(n.nspname, c.relname, a.attname) AS out_db,
    _raster_constraint_info_extent(n.nspname, c.relname, a.attname) AS extent,
    COALESCE(_raster_constraint_info_index(n.nspname, c.relname, a.attname), false) AS spatial_index
   FROM pg_class c,
    pg_attribute a,
    pg_type t,
    pg_namespace n
  WHERE ((t.typname = 'raster'::name) AND (a.attisdropped = false) AND (a.atttypid = t.oid) AND (a.attrelid = c.oid) AND (c.relnamespace = n.oid) AND (c.relkind = ANY (ARRAY['r'::"char", 'v'::"char", 'm'::"char", 'f'::"char", 'p'::"char"])) AND (NOT pg_is_other_temp_schema(c.relnamespace)) AND has_table_privilege(c.oid, 'SELECT'::text));
```

### `public.raster_overviews`

```sql
SELECT current_database() AS o_table_catalog,
    n.nspname AS o_table_schema,
    c.relname AS o_table_name,
    a.attname AS o_raster_column,
    current_database() AS r_table_catalog,
    (split_part(split_part(s.consrc, '''::name'::text, 1), ''''::text, 2))::name AS r_table_schema,
    (split_part(split_part(s.consrc, '''::name'::text, 2), ''''::text, 2))::name AS r_table_name,
    (split_part(split_part(s.consrc, '''::name'::text, 3), ''''::text, 2))::name AS r_raster_column,
    (TRIM(BOTH FROM split_part(s.consrc, ','::text, 2)))::integer AS overview_factor
   FROM pg_class c,
    pg_attribute a,
    pg_type t,
    pg_namespace n,
    ( SELECT pg_constraint.connamespace,
            pg_constraint.conrelid,
            pg_constraint.conkey,
            pg_get_constraintdef(pg_constraint.oid) AS consrc
           FROM pg_constraint) s
  WHERE ((t.typname = 'raster'::name) AND (a.attisdropped = false) AND (a.atttypid = t.oid) AND (a.attrelid = c.oid) AND (c.relnamespace = n.oid) AND ((c.relkind)::text = ANY ((ARRAY['r'::character(1), 'v'::character(1), 'm'::character(1), 'f'::character(1)])::text[])) AND (s.connamespace = n.oid) AND (s.conrelid = c.oid) AND (s.consrc ~~ '%_overview_constraint(%'::text) AND (NOT pg_is_other_temp_schema(c.relnamespace)) AND has_table_privilege(c.oid, 'SELECT'::text));
```

## Custom Functions

_No custom functions found (PostGIS built-ins excluded)._

## Summary Statistics

- **Total Tables:** 23
- **Spatial Tables:** 18
- **Non-Spatial Tables:** 5

### Size Breakdown

| Table | Total Size | Rows |
| --- | --- | --- |
| address.address_point | 9032 kB | 18,945 |
| public.spatial_ref_sys | 7144 kB | 8,500 |
| street.street_segment | 4520 kB | 9,663 |
| incidents.dispatched_incident | 1968 kB | 1,401 |
| fire.fire_box | 1472 kB | 1,610 |
| police.police_zone | 1112 kB | 827 |
| street.street_dissolved | 600 kB | 1,258 |
| street.street_crossing | 504 kB | 2,175 |
| public.us_rules | 456 kB | 4,369 |
| map.neighborhood | 448 kB | 100 |
| address.building_cids | 416 kB | 1,446 |
| map.postal_zone | 376 kB | 1,044 |
| map.area_of_patrol | 368 kB | 30 |
| public.us_lex | 304 kB | 2,938 |
| map.zip_code | 296 kB | 92 |
| fire.water_supply | 296 kB | 1,342 |
| map.jurisdiction | 288 kB | 36 |
| fire.fire_district | 264 kB | 194 |
| map.point_of_interest | 256 kB | 453 |
| map.transit_route | 224 kB | 84 |
| public.us_gaz | 160 kB | 1,074 |
| map.gang_territory | 96 kB | 75 |
| fire.fire_station | 40 kB | 9 |

**Total Row Count:** 57,665

