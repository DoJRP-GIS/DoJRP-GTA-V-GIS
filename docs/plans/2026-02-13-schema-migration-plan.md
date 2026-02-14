# Schema Simplification Migration — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate gisdb from ~120+ tables to 18 tables across 6 domain schemas, moving reference data to a separate database.

**Architecture:** A series of Node.js migration scripts using `pg`. Each script creates new tables, migrates data with INSERT...SELECT, verifies row counts, then renames old schemas out of the way (no destructive drops until fully verified). Reference data is exported via `pg_dump` to a new `gisdb_reference` database.

**Tech Stack:** Node.js, pg v8.18.0, PostgreSQL 15.1/PostGIS 3.3.1, localhost:5433

**Design doc:** `docs/plans/2026-02-13-schema-simplification-design.md`

---

### Task 1: Create migration script scaffold

**Files:**
- Create: `migrate/run_migration.js`
- Modify: `.gitignore` — add `migrate/` to gitignored scripts section

**Step 1: Create the migrate directory and scaffold**

Create `migrate/run_migration.js` — a reusable runner that:
- Connects to gisdb (localhost:5433, postgres, 567856)
- Accepts a migration step number via CLI arg (`node migrate/run_migration.js 1`)
- Imports and runs the corresponding step module from `migrate/steps/`
- Logs timing, wraps each step in a transaction (BEGIN/COMMIT/ROLLBACK on error)

```javascript
#!/usr/bin/env node
const { Client } = require('pg');
const path = require('path');

const client = new Client({
  host: 'localhost', port: 5433, database: 'gisdb',
  user: 'postgres', password: '567856'
});

async function run() {
  const stepNum = process.argv[2];
  if (!stepNum) {
    console.log('Usage: node migrate/run_migration.js <step_number>');
    console.log('Steps: 1=reference_export, 2=address, 3=street, 4=map, 5=fire, 6=police_incidents, 7=indexes, 8=cleanup');
    process.exit(1);
  }

  const stepFile = path.join(__dirname, 'steps', `step${stepNum}.js`);
  let stepFn;
  try {
    stepFn = require(stepFile);
  } catch (e) {
    console.error(`Step ${stepNum} not found at ${stepFile}`);
    process.exit(1);
  }

  await client.connect();
  console.log(`\n=== Migration Step ${stepNum} ===\n`);
  const start = Date.now();

  try {
    await client.query('BEGIN');
    await stepFn(client);
    await client.query('COMMIT');
    console.log(`\nStep ${stepNum} completed in ${((Date.now() - start) / 1000).toFixed(1)}s`);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(`\nStep ${stepNum} FAILED — rolled back`);
    console.error(err.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

run();
```

**Step 2: Add migrate/ to .gitignore**

Add after the `review_db.js` line:

```
migrate/
```

**Step 3: Create steps directory**

```bash
mkdir -p migrate/steps
```

**Step 4: Verify scaffold runs**

Run: `node migrate/run_migration.js`
Expected: Shows usage message with step list.

**Step 5: Commit**

```bash
git add .gitignore
git commit -m "chore: add migrate/ to gitignore for schema migration scripts"
```

---

### Task 2: Step 1 — Export reference data to separate database

**Files:**
- Create: `migrate/steps/step1.js`

This step uses `pg_dump`/`pg_restore` via shell commands (not the pg client) to copy pgco, tiger, tiger_data schemas to a new database. This step runs OUTSIDE a transaction since it uses shell tools.

**Step 1: Create step1.js**

```javascript
const { execSync } = require('child_process');

module.exports = async function step1(client) {
  console.log('Step 1: Export reference data to gisdb_reference\n');

  const PG_HOST = 'localhost';
  const PG_PORT = '5433';
  const PG_USER = 'postgres';
  const env = { ...process.env, PGPASSWORD: '567856' };

  // Create the reference database if it doesn't exist
  try {
    await client.query('COMMIT'); // exit the transaction from runner
    await client.query("CREATE DATABASE gisdb_reference");
    console.log('Created database: gisdb_reference');
  } catch (e) {
    if (e.code === '42P04') {
      console.log('Database gisdb_reference already exists, continuing...');
      await client.query('BEGIN'); // re-enter transaction for runner
    } else {
      await client.query('BEGIN');
      throw e;
    }
  }
  await client.query('BEGIN'); // re-enter transaction for runner

  // Enable PostGIS on reference db
  console.log('Enabling PostGIS on gisdb_reference...');
  execSync(
    `psql -h ${PG_HOST} -p ${PG_PORT} -U ${PG_USER} -d gisdb_reference -c "CREATE EXTENSION IF NOT EXISTS postgis;"`,
    { env, stdio: 'pipe' }
  );

  // Dump and restore each reference schema
  const schemas = ['pgco', 'tiger', 'tiger_data'];
  for (const schema of schemas) {
    console.log(`Exporting schema: ${schema}...`);
    try {
      execSync(
        `pg_dump -h ${PG_HOST} -p ${PG_PORT} -U ${PG_USER} -d gisdb -n ${schema} | psql -h ${PG_HOST} -p ${PG_PORT} -U ${PG_USER} -d gisdb_reference`,
        { env, stdio: 'pipe', timeout: 600000 }
      );
      console.log(`  ${schema} exported successfully`);
    } catch (e) {
      console.error(`  WARNING: ${schema} export had issues: ${e.message}`);
    }
  }

  // Also export LA county data from address schema
  console.log('Exporting LA county tables...');
  const laTables = [
    'address.la_cams_address_lines',
    'address.la_cams_address_points',
    'address.la_lacounty_parcels'
  ];
  for (const table of laTables) {
    console.log(`  Exporting ${table}...`);
    try {
      execSync(
        `pg_dump -h ${PG_HOST} -p ${PG_PORT} -U ${PG_USER} -d gisdb -t "${table}" | psql -h ${PG_HOST} -p ${PG_PORT} -U ${PG_USER} -d gisdb_reference`,
        { env, stdio: 'pipe', timeout: 600000 }
      );
      console.log(`  ${table} exported`);
    } catch (e) {
      console.error(`  WARNING: ${table} export had issues: ${e.message}`);
    }
  }

  // Verify counts in reference db
  console.log('\nVerifying reference database...');
  const { Client: PgClient } = require('pg');
  const refClient = new PgClient({
    host: PG_HOST, port: parseInt(PG_PORT), database: 'gisdb_reference',
    user: PG_USER, password: '567856'
  });
  await refClient.connect();

  for (const schema of schemas) {
    const { rows } = await refClient.query(
      `SELECT count(*) as cnt FROM pg_tables WHERE schemaname = $1`, [schema]
    );
    console.log(`  ${schema}: ${rows[0].cnt} tables`);
  }
  await refClient.end();

  console.log('\nReference data export complete.');
  console.log('Run step 2 next to migrate address data.');
};
```

**Step 2: Run step 1**

Run: `node migrate/run_migration.js 1`
Expected: Creates gisdb_reference database, exports pgco/tiger/tiger_data/LA tables. Prints table counts from reference DB.

**Note:** This step will take several minutes due to the 4+ GB of data. The LA county tables (2.4M + 2.7M rows) are the largest.

---

### Task 3: Step 2 — Migrate address schema

**Files:**
- Create: `migrate/steps/step2.js`

**Step 1: Create step2.js**

```javascript
module.exports = async function step2(client) {
  console.log('Step 2: Migrate address schema\n');

  // Get pre-migration count
  const { rows: [{ count: srcCount }] } = await client.query(
    'SELECT count(*) as count FROM address.address_cids_info_cross'
  );
  console.log(`Source: address.address_cids_info_cross = ${srcCount} rows`);

  // Rename old address schema
  console.log('Renaming address -> _old_address...');
  await client.query('ALTER SCHEMA address RENAME TO _old_address');

  // Create new address schema
  console.log('Creating new address schema...');
  await client.query('CREATE SCHEMA address');

  // Create address_point table
  console.log('Creating address.address_point...');
  await client.query(`
    CREATE TABLE address.address_point (
      id serial PRIMARY KEY,
      geom geometry(Point, 3857) NOT NULL,
      building_name text,
      building_name_alt text,
      building_type text,
      building_number text,
      floor_number text,
      unit_number text,
      street_number integer,
      street_name text,
      street_address text,
      full_address text,
      cross_street_1 text,
      cross_street_2 text,
      jurisdiction text,
      zip_code text,
      nearest_postal_code text,
      fire_box text,
      fire_district integer,
      fire_run_card text,
      police_primary text,
      police_secondary text,
      police_shared text,
      police_other text,
      police_reporting_district text,
      coord_x double precision,
      coord_y double precision,
      display_text text,
      updated_at timestamptz
    )
  `);

  // Populate address_point
  console.log('Populating address.address_point...');
  await client.query(`
    INSERT INTO address.address_point (
      geom, building_name, building_name_alt, building_type,
      building_number, floor_number, unit_number,
      street_number, street_name, street_address, full_address,
      cross_street_1, cross_street_2,
      jurisdiction, zip_code, nearest_postal_code,
      fire_box, fire_district, fire_run_card,
      police_primary, police_secondary, police_shared, police_other,
      police_reporting_district,
      coord_x, coord_y, display_text, updated_at
    )
    SELECT
      geom, bldg_name, bldg_name_alt, bldg_type,
      bldg_num, floor_num, unit_num,
      st_num, st_name, st_address, full_address,
      street_1, street_2,
      jurisdiction, zip_code, nearest_postal,
      fire_box, fire_district, box_run_card,
      police_primary, police_secondary, police_shared, police_other,
      police_reporting_district::text,
      coord_x, coord_y, display_text, update_time
    FROM _old_address.address_cids_info_cross
  `);

  // Verify count
  const { rows: [{ count: destCount }] } = await client.query(
    'SELECT count(*) as count FROM address.address_point'
  );
  console.log(`Migrated: address.address_point = ${destCount} rows`);
  if (destCount !== srcCount) {
    throw new Error(`Row count mismatch! Source: ${srcCount}, Dest: ${destCount}`);
  }

  // Create building_cids table
  console.log('Creating address.building_cids...');
  await client.query(`
    CREATE TABLE address.building_cids (
      id serial PRIMARY KEY,
      address_id integer NOT NULL REFERENCES address.address_point(id),
      fire_designation text,
      occupancy_type text,
      height_stories text,
      building_dimensions text,
      construction_class text,
      construction_class_description text,
      hazards text,
      minimum_response text,
      transmitted_data text,
      is_available boolean
    )
  `);

  // Populate building_cids — only rows that have at least one CIDS field populated
  console.log('Populating address.building_cids...');
  await client.query(`
    INSERT INTO address.building_cids (
      address_id, fire_designation, occupancy_type,
      height_stories, building_dimensions,
      construction_class, construction_class_description,
      hazards, minimum_response, transmitted_data, is_available
    )
    SELECT
      ap.id,
      src.cids_fd_designation,
      src.cids_occupancy,
      src.cids_bldg_height_stories,
      src.cids_bldg_dimensions,
      src.cids_class,
      src.cids_class_description,
      src.cids_hazards,
      src.cids_minresp,
      src.cids_transmitted_data,
      src.cids_availability
    FROM _old_address.address_cids_info_cross src
    JOIN address.address_point ap
      ON ap.street_number = src.st_num
      AND ap.street_name = src.st_name
      AND ap.coord_x = src.coord_x
      AND ap.coord_y = src.coord_y
    WHERE src.cids_fd_designation IS NOT NULL
       OR src.cids_occupancy IS NOT NULL
       OR src.cids_class IS NOT NULL
       OR src.cids_hazards IS NOT NULL
       OR src.cids_minresp IS NOT NULL
  `);

  const { rows: [{ count: cidsCount }] } = await client.query(
    'SELECT count(*) as count FROM address.building_cids'
  );
  console.log(`Migrated: address.building_cids = ${cidsCount} rows`);

  console.log('\nAddress migration complete.');
  console.log('Run step 3 next to migrate street data.');
};
```

**Step 2: Run step 2**

Run: `node migrate/run_migration.js 2`
Expected: Old address schema renamed to `_old_address`. New `address.address_point` has 18,945 rows. `address.building_cids` has rows for addresses with CIDS data.

---

### Task 4: Step 3 — Migrate street schema

**Files:**
- Create: `migrate/steps/step3.js`

**Step 1: Create step3.js**

```javascript
module.exports = async function step3(client) {
  console.log('Step 3: Migrate street schema\n');

  // Pre-migration counts
  const { rows: [{ count: segSrc }] } = await client.query(
    'SELECT count(*) as count FROM street.cross_streets'
  );
  const { rows: [{ count: disSrc }] } = await client.query(
    'SELECT count(*) as count FROM street.street_network_dissolved'
  );
  console.log(`Source: cross_streets = ${segSrc}, street_network_dissolved = ${disSrc}`);

  // Rename old schema
  console.log('Renaming street -> _old_street...');
  await client.query('ALTER SCHEMA street RENAME TO _old_street');

  // Create new street schema
  console.log('Creating new street schema...');
  await client.query('CREATE SCHEMA street');

  // Create street_segment
  console.log('Creating street.street_segment...');
  await client.query(`
    CREATE TABLE street.street_segment (
      id serial PRIMARY KEY,
      geom geometry(LineString, 3857) NOT NULL,
      street_name text,
      name_prefix text,
      name_base text,
      name_type text,
      name_suffix text,
      alt_street_name text,
      alt_name_prefix text,
      alt_name_base text,
      alt_name_type text,
      alt_name_suffix text,
      address_range_left_from integer,
      address_range_left_to integer,
      address_range_right_from integer,
      address_range_right_to integer,
      zip_code_left integer,
      zip_code_right integer,
      road_class text,
      lane_count integer,
      lane_count_left integer,
      lane_count_right integer,
      is_oneway boolean,
      speed_limit_mph integer,
      directionality smallint,
      cross_street_low text,
      cross_street_low_id text,
      cross_street_high text,
      cross_street_high_id text,
      display_text text
    )
  `);

  // Populate from cross_streets
  console.log('Populating street.street_segment...');
  await client.query(`
    INSERT INTO street.street_segment (
      geom, street_name, name_prefix, name_base, name_type, name_suffix,
      alt_street_name, alt_name_prefix, alt_name_base, alt_name_type, alt_name_suffix,
      address_range_left_from, address_range_left_to,
      address_range_right_from, address_range_right_to,
      zip_code_left, zip_code_right,
      road_class, lane_count, lane_count_left, lane_count_right,
      is_oneway, speed_limit_mph, directionality,
      cross_street_low, cross_street_low_id,
      cross_street_high, cross_street_high_id,
      display_text
    )
    SELECT
      geom, name, name_direction_prefix, name_base, name_type, name_direction_suffix,
      name_1, name_1_direction_prefix, name_1_base, name_1_type, name_1_direction_suffix,
      from_address_left, to_address_left,
      from_address_right, to_address_right,
      zip_left, zip_right,
      "tiger:cfcc", lanes, lanes_left, lanes_right,
      oneway, max_speed_mph, directionality::smallint,
      cross_intersection_name, cross_intersection_id,
      high_cross_intersection_name, high_cross_intersection_id,
      display_text
    FROM _old_street.cross_streets
  `);

  const { rows: [{ count: segDest }] } = await client.query(
    'SELECT count(*) as count FROM street.street_segment'
  );
  console.log(`Migrated: street.street_segment = ${segDest} rows`);
  if (segDest !== segSrc) {
    throw new Error(`Row count mismatch! Source: ${segSrc}, Dest: ${segDest}`);
  }

  // Create street_dissolved
  console.log('Creating street.street_dissolved...');
  await client.query(`
    CREATE TABLE street.street_dissolved (
      id serial PRIMARY KEY,
      geom geometry(MultiLineString, 3857) NOT NULL,
      street_name text,
      name_base text,
      name_type text,
      display_text text
    )
  `);

  // Populate
  console.log('Populating street.street_dissolved...');
  await client.query(`
    INSERT INTO street.street_dissolved (geom, street_name, name_base, name_type, display_text)
    SELECT geom, name, name_base, name_type, display_text
    FROM _old_street.street_network_dissolved
  `);

  const { rows: [{ count: disDest }] } = await client.query(
    'SELECT count(*) as count FROM street.street_dissolved'
  );
  console.log(`Migrated: street.street_dissolved = ${disDest} rows`);
  if (disDest !== disSrc) {
    throw new Error(`Row count mismatch! Source: ${disSrc}, Dest: ${disDest}`);
  }

  console.log('\nStreet migration complete.');
  console.log('Run step 4 next to migrate map data.');
};
```

**Step 2: Run step 3**

Run: `node migrate/run_migration.js 3`
Expected: `_old_street` archived. `street.street_segment` = 9,663 rows. `street.street_dissolved` = 1,258 rows.

---

### Task 5: Step 4 — Migrate map schema

**Files:**
- Create: `migrate/steps/step4.js`

**Step 1: Create step4.js**

```javascript
module.exports = async function step4(client) {
  console.log('Step 4: Migrate map schema\n');

  // Pre-migration counts
  const counts = {};
  const srcTables = {
    jurisdiction: 'map.jurisdiction',
    neighborhood: 'map.neighborhood',
    aop: 'map.aop',
    gang: 'map.gang',
    zip: 'map.zip',
    postal_voronoi: 'map.postal_voronoi',
    chain_markers: 'map.chain_markers',
    radio_towers: 'map.radio_towers',
    transit: 'map.transit'
  };
  for (const [key, table] of Object.entries(srcTables)) {
    const { rows: [{ count }] } = await client.query(`SELECT count(*) as count FROM ${table}`);
    counts[key] = count;
    console.log(`Source: ${table} = ${count}`);
  }

  // Rename old schema
  console.log('\nRenaming map -> _old_map...');
  await client.query('ALTER SCHEMA map RENAME TO _old_map');
  await client.query('CREATE SCHEMA map');

  // --- jurisdiction ---
  console.log('Creating map.jurisdiction...');
  await client.query(`
    CREATE TABLE map.jurisdiction (
      id serial PRIMARY KEY,
      geom geometry(MultiPolygon, 3857) NOT NULL,
      jurisdiction_name text,
      full_jurisdiction_name text,
      jurisdiction_type text,
      section text
    )
  `);
  await client.query(`
    INSERT INTO map.jurisdiction (geom, jurisdiction_name, full_jurisdiction_name, jurisdiction_type, section)
    SELECT geom, jurisdiction, full_jurisdiction, type, section
    FROM _old_map.jurisdiction
  `);

  // --- neighborhood ---
  console.log('Creating map.neighborhood...');
  await client.query(`
    CREATE TABLE map.neighborhood (
      id serial PRIMARY KEY,
      geom geometry(MultiPolygon, 3857) NOT NULL,
      neighborhood_name text,
      neighborhood_code text,
      district_name text,
      district_code text
    )
  `);
  await client.query(`
    INSERT INTO map.neighborhood (geom, neighborhood_name, neighborhood_code, district_name, district_code)
    SELECT geom, neighborhood_name, neighborhood_code, district_name, district_code
    FROM _old_map.neighborhood
  `);

  // --- area_of_patrol ---
  console.log('Creating map.area_of_patrol...');
  await client.query(`
    CREATE TABLE map.area_of_patrol (
      id serial PRIMARY KEY,
      geom geometry(MultiPolygon, 3857) NOT NULL,
      valid_aops text,
      invalid_aops text
    )
  `);
  await client.query(`
    INSERT INTO map.area_of_patrol (geom, valid_aops, invalid_aops)
    SELECT geom, valid_aops, invalid_aops
    FROM _old_map.aop
  `);

  // --- gang_territory ---
  console.log('Creating map.gang_territory...');
  await client.query(`
    CREATE TABLE map.gang_territory (
      id serial PRIMARY KEY,
      geom geometry(MultiPolygon, 3857) NOT NULL,
      is_disputed boolean,
      gang_names text[]
    )
  `);
  await client.query(`
    INSERT INTO map.gang_territory (geom, is_disputed, gang_names)
    SELECT geom, disputed,
      ARRAY_REMOVE(ARRAY[gang_1, gang_2, gang_3, gang_4, gang_5], NULL)
    FROM _old_map.gang
  `);

  // --- zip_code ---
  console.log('Creating map.zip_code...');
  await client.query(`
    CREATE TABLE map.zip_code (
      id serial PRIMARY KEY,
      geom geometry(MultiPolygon, 3857) NOT NULL,
      zip_code text,
      display_text text
    )
  `);
  await client.query(`
    INSERT INTO map.zip_code (geom, zip_code, display_text)
    SELECT geom, zip, zip
    FROM _old_map.zip
  `);

  // --- postal_zone ---
  console.log('Creating map.postal_zone...');
  await client.query(`
    CREATE TABLE map.postal_zone (
      id serial PRIMARY KEY,
      geom geometry(Polygon, 3857) NOT NULL,
      postal_number text,
      display_text text
    )
  `);
  await client.query(`
    INSERT INTO map.postal_zone (geom, postal_number, display_text)
    SELECT geom, postal_number, display_text
    FROM _old_map.postal_voronoi
  `);

  // --- point_of_interest (consolidate chain_markers + radio_towers + transit points) ---
  console.log('Creating map.point_of_interest...');
  await client.query(`
    CREATE TABLE map.point_of_interest (
      id serial PRIMARY KEY,
      geom geometry(Point, 3857) NOT NULL,
      poi_type text NOT NULL,
      name text,
      description text,
      metadata jsonb
    )
  `);

  // chain_markers
  await client.query(`
    INSERT INTO map.point_of_interest (geom, poi_type, name, description, metadata)
    SELECT geom, 'chain_marker', bldg_name, full_address,
      jsonb_build_object(
        'street_number', st_num,
        'street_name', st_name,
        'jurisdiction', jurisdiction,
        'fire_box', fire_box,
        'nearest_postal', nearest_postal,
        'police_primary', police_primary
      )
    FROM _old_map.chain_markers
  `);

  // radio_towers
  await client.query(`
    INSERT INTO map.point_of_interest (geom, poi_type, name, description, metadata)
    SELECT geom, 'radio_tower', 'Radio Tower #' || id, nearest_postal,
      jsonb_build_object(
        'elevation', elevation,
        'base_elevation', base_elevation,
        'total_elevation', total_elevation,
        'radius', radius,
        'coord_x', coord_x,
        'coord_y', coord_y
      )
    FROM _old_map.radio_towers
  `);

  // transit (as points — only if they have point geometry, otherwise skip)
  await client.query(`
    INSERT INTO map.point_of_interest (geom, poi_type, name, description, metadata)
    SELECT
      ST_Centroid(geom), 'transit_stop', route_name, operator,
      jsonb_build_object(
        'route_num', route_num,
        'segments_and_fares', segments_and_fares,
        'operating_hours', operating_hours
      )
    FROM _old_map.transit
    WHERE GeometryType(geom) = 'POINT'
  `);

  // --- transit_route (line geometries) ---
  console.log('Creating map.transit_route...');
  await client.query(`
    CREATE TABLE map.transit_route (
      id serial PRIMARY KEY,
      geom geometry(MultiLineString, 3857) NOT NULL,
      route_name text,
      route_type text
    )
  `);
  await client.query(`
    INSERT INTO map.transit_route (geom, route_name, route_type)
    SELECT
      CASE WHEN GeometryType(geom) = 'MULTILINESTRING' THEN geom
           WHEN GeometryType(geom) = 'LINESTRING' THEN ST_Multi(geom)
      END,
      route_name, operator
    FROM _old_map.transit
    WHERE GeometryType(geom) IN ('LINESTRING', 'MULTILINESTRING')
  `);

  // --- Verify counts ---
  console.log('\nVerifying counts...');
  const verify = {
    'map.jurisdiction': counts.jurisdiction,
    'map.neighborhood': counts.neighborhood,
    'map.area_of_patrol': counts.aop,
    'map.gang_territory': counts.gang,
    'map.zip_code': counts.zip,
    'map.postal_zone': counts.postal_voronoi,
  };
  for (const [table, expected] of Object.entries(verify)) {
    const { rows: [{ count }] } = await client.query(`SELECT count(*) as count FROM ${table}`);
    const ok = count === expected ? 'OK' : 'MISMATCH';
    console.log(`  ${table}: ${count} (expected ${expected}) — ${ok}`);
    if (count !== expected) {
      throw new Error(`Count mismatch on ${table}: got ${count}, expected ${expected}`);
    }
  }

  // POI is a merge, just report
  const { rows: [{ count: poiCount }] } = await client.query(
    'SELECT count(*) as count FROM map.point_of_interest'
  );
  console.log(`  map.point_of_interest: ${poiCount} (merged from chain_markers + radio_towers + transit)`);

  const { rows: [{ count: routeCount }] } = await client.query(
    'SELECT count(*) as count FROM map.transit_route'
  );
  console.log(`  map.transit_route: ${routeCount}`);

  console.log('\nMap migration complete.');
  console.log('Run step 5 next to migrate fire data.');
};
```

**Step 2: Run step 4**

Run: `node migrate/run_migration.js 4`
Expected: All map tables created and verified. `_old_map` archived.

---

### Task 6: Step 5 — Migrate fire schema

**Files:**
- Create: `migrate/steps/step5.js`

**Step 1: Create step5.js**

```javascript
module.exports = async function step5(client) {
  console.log('Step 5: Migrate fire schema\n');

  // Pre-migration counts
  const srcCounts = {};
  for (const t of ['fire_area', 'fire_box', 'fire_stations', 'hydrants', 'fdc']) {
    const { rows: [{ count }] } = await client.query(`SELECT count(*) as count FROM fire.${t}`);
    srcCounts[t] = count;
    console.log(`Source: fire.${t} = ${count}`);
  }

  // Rename old schema
  console.log('\nRenaming fire -> _old_fire...');
  await client.query('ALTER SCHEMA fire RENAME TO _old_fire');
  await client.query('CREATE SCHEMA fire');

  // --- fire_district ---
  console.log('Creating fire.fire_district...');
  await client.query(`
    CREATE TABLE fire.fire_district (
      id serial PRIMARY KEY,
      geom geometry(MultiPolygon, 3857) NOT NULL,
      station_name text,
      station_number integer,
      box_code text,
      fire_box text,
      first_due text,
      running_order text,
      is_hydrant_area boolean
    )
  `);
  await client.query(`
    INSERT INTO fire.fire_district (geom, station_name, station_number, box_code, fire_box, first_due, running_order, is_hydrant_area)
    SELECT geom, fire_station, station, box, fire_box, fire_first_due, running_order, hydrant_area
    FROM _old_fire.fire_area
  `);

  // --- fire_box ---
  console.log('Creating fire.fire_box...');
  await client.query(`
    CREATE TABLE fire.fire_box (
      id serial PRIMARY KEY,
      geom geometry(MultiPolygon, 3857) NOT NULL,
      station_name text,
      station_number integer,
      box_code text,
      fire_box text,
      is_hydrant_area boolean,
      running_order text,
      display_text text
    )
  `);
  await client.query(`
    INSERT INTO fire.fire_box (geom, station_name, station_number, box_code, fire_box, is_hydrant_area, running_order, display_text)
    SELECT geom, fire_station, station, box, fire_box, hydrant_area, running_order, display_text
    FROM _old_fire.fire_box
  `);

  // --- fire_station ---
  console.log('Creating fire.fire_station...');
  await client.query(`
    CREATE TABLE fire.fire_station (
      id serial PRIMARY KEY,
      geom geometry(Point, 3857) NOT NULL,
      first_due_district integer,
      station_name text,
      street_name text,
      full_address text,
      jurisdiction text,
      nearest_postal_code text,
      police_primary text
    )
  `);
  await client.query(`
    INSERT INTO fire.fire_station (geom, first_due_district, station_name, street_name, full_address, jurisdiction, nearest_postal_code, police_primary)
    SELECT geom, fire_first_due, location, street, full_address, jurisdiction, nearest_postal, police_primary
    FROM _old_fire.fire_stations
  `);

  // --- water_supply (merge hydrants + fdc) ---
  console.log('Creating fire.water_supply...');
  await client.query(`
    CREATE TABLE fire.water_supply (
      id serial PRIMARY KEY,
      geom geometry(Point, 3857) NOT NULL,
      supply_type text NOT NULL,
      status text,
      nearest_postal_code text,
      fire_box text
    )
  `);
  await client.query(`
    INSERT INTO fire.water_supply (geom, supply_type, status, nearest_postal_code, fire_box)
    SELECT geom, 'hydrant', status, nearest_postal, fire_box
    FROM _old_fire.hydrants
  `);
  await client.query(`
    INSERT INTO fire.water_supply (geom, supply_type, status, nearest_postal_code, fire_box)
    SELECT geom, 'fdc', status::text, nearest_postal::text, fire_box::text
    FROM _old_fire.fdc
  `);

  // Verify
  console.log('\nVerifying counts...');
  const verify = {
    'fire.fire_district': srcCounts.fire_area,
    'fire.fire_box': srcCounts.fire_box,
    'fire.fire_station': srcCounts.fire_stations,
  };
  for (const [table, expected] of Object.entries(verify)) {
    const { rows: [{ count }] } = await client.query(`SELECT count(*) as count FROM ${table}`);
    const ok = count === expected ? 'OK' : 'MISMATCH';
    console.log(`  ${table}: ${count} (expected ${expected}) — ${ok}`);
    if (count !== expected) throw new Error(`Count mismatch: ${table}`);
  }

  const { rows: [{ count: wsCount }] } = await client.query(
    'SELECT count(*) as count FROM fire.water_supply'
  );
  const expectedWs = String(Number(srcCounts.hydrants) + Number(srcCounts.fdc));
  console.log(`  fire.water_supply: ${wsCount} (expected ${expectedWs} = hydrants + fdc)`);
  if (wsCount !== expectedWs) throw new Error('water_supply count mismatch');

  console.log('\nFire migration complete.');
  console.log('Run step 6 next to migrate police and incidents data.');
};
```

**Step 2: Run step 5**

Run: `node migrate/run_migration.js 5`
Expected: `fire.fire_district`=194, `fire.fire_box`=1611, `fire.fire_station`=9, `fire.water_supply`=1342.

---

### Task 7: Step 6 — Migrate police and incidents schemas

**Files:**
- Create: `migrate/steps/step6.js`

**Step 1: Create step6.js**

```javascript
module.exports = async function step6(client) {
  console.log('Step 6: Migrate police and incidents schemas\n');

  // --- Police ---
  const { rows: [{ count: policeSrc }] } = await client.query(
    'SELECT count(*) as count FROM police.police_jurisdiction'
  );
  console.log(`Source: police.police_jurisdiction = ${policeSrc}`);

  console.log('Renaming police -> _old_police...');
  await client.query('ALTER SCHEMA police RENAME TO _old_police');
  await client.query('CREATE SCHEMA police');

  console.log('Creating police.police_zone...');
  await client.query(`
    CREATE TABLE police.police_zone (
      id serial PRIMARY KEY,
      geom geometry(MultiPolygon, 3857) NOT NULL,
      primary_jurisdiction text,
      primary_jurisdiction_code text,
      secondary_jurisdiction text,
      secondary_jurisdiction_code text,
      shared_jurisdiction text,
      shared_jurisdiction_code text,
      other_jurisdiction text,
      other_jurisdiction_code text,
      reporting_district smallint,
      precinct smallint,
      beat smallint,
      bureau text
    )
  `);
  await client.query(`
    INSERT INTO police.police_zone (
      geom, primary_jurisdiction, primary_jurisdiction_code,
      secondary_jurisdiction, secondary_jurisdiction_code,
      shared_jurisdiction, shared_jurisdiction_code,
      other_jurisdiction, other_jurisdiction_code,
      reporting_district, precinct, beat, bureau
    )
    SELECT
      geom, primary_jurisdiction, primary_jurisdiction_code,
      secondary_jurisdiction, secondary_jurisdiction_code,
      shared_jurisdiction, shared_jurisdiction_code,
      other_jurisdiction, other_jurisdiction_code,
      reporting_district, precinct, beat, bureau
    FROM _old_police.police_jurisdiction
  `);

  const { rows: [{ count: policeDest }] } = await client.query(
    'SELECT count(*) as count FROM police.police_zone'
  );
  console.log(`Migrated: police.police_zone = ${policeDest}`);
  if (policeDest !== policeSrc) throw new Error('Police count mismatch');

  // --- Incidents ---
  const { rows: [{ count: incSrc }] } = await client.query(
    'SELECT count(*) as count FROM incidents.dispatched_incidents'
  );
  console.log(`\nSource: incidents.dispatched_incidents = ${incSrc}`);

  console.log('Renaming incidents -> _old_incidents...');
  await client.query('ALTER SCHEMA incidents RENAME TO _old_incidents');
  await client.query('CREATE SCHEMA incidents');

  console.log('Creating incidents.dispatched_incident...');
  await client.query(`
    CREATE TABLE incidents.dispatched_incident (
      id serial PRIMARY KEY,
      geom geometry(Point, 3857),
      jurisdiction text,
      zip_code text,
      nearest_postal_code text,
      fire_box text,
      coord_x double precision,
      coord_y double precision,
      fire_district integer,
      police_primary text,
      police_secondary text,
      police_shared text,
      police_other text,
      fire_run_card text,
      police_reporting_district text,
      incident_number integer,
      server_number varchar(2),
      agency varchar(2),
      units_recommended text[],
      units_dispatched text[],
      modifying_circumstances text[],
      dispatched_determinant text,
      dispatched_protocol varchar(3),
      dispatched_level varchar(2),
      cad_notes text,
      time_created time,
      time_dispatched time,
      time_en_route time,
      time_on_scene time,
      time_under_control time,
      time_cleared time,
      time_closed time,
      duration_on_scene real,
      patient_transport text,
      patient_arrival text
    )
  `);
  await client.query(`
    INSERT INTO incidents.dispatched_incident (
      geom, jurisdiction, zip_code, nearest_postal_code, fire_box,
      coord_x, coord_y, fire_district,
      police_primary, police_secondary, police_shared, police_other,
      fire_run_card, police_reporting_district,
      incident_number, server_number, agency,
      units_recommended, units_dispatched, modifying_circumstances,
      dispatched_determinant, dispatched_protocol, dispatched_level,
      cad_notes,
      time_created, time_dispatched, time_en_route, time_on_scene,
      time_under_control, time_cleared, time_closed,
      duration_on_scene, patient_transport, patient_arrival
    )
    SELECT
      geom, jurisdiction, zip_code, nearest_postal, fire_box,
      coord_x, coord_y, fire_district,
      police_primary, police_secondary, police_shared, police_other,
      box_run_card, police_reporting_district,
      inc_number, server_number, agency,
      units_rec, units_dsp, modifying_circumstances,
      dispatched_determinant, dispatched_protocol, dispatched_level,
      cad_notes,
      t_created, t_dispatched, t_en_route, t_on_scene,
      t_under_control, t_cleared, t_closed,
      d_ons, patient_txpt, patient_arrival
    FROM _old_incidents.dispatched_incidents
  `);

  const { rows: [{ count: incDest }] } = await client.query(
    'SELECT count(*) as count FROM incidents.dispatched_incident'
  );
  console.log(`Migrated: incidents.dispatched_incident = ${incDest}`);
  if (incDest !== incSrc) throw new Error('Incidents count mismatch');

  console.log('\nPolice and incidents migration complete.');
  console.log('Run step 7 next to create spatial indexes.');
};
```

**Step 2: Run step 6**

Run: `node migrate/run_migration.js 6`
Expected: `police.police_zone`=827, `incidents.dispatched_incident`=1401.

---

### Task 8: Step 7 — Create spatial indexes

**Files:**
- Create: `migrate/steps/step7.js`

**Step 1: Create step7.js**

```javascript
module.exports = async function step7(client) {
  console.log('Step 7: Create spatial and attribute indexes\n');

  const indexes = [
    // Spatial indexes (GiST)
    'CREATE INDEX idx_address_point_geom ON address.address_point USING gist (geom)',
    'CREATE INDEX idx_building_cids_address_id ON address.building_cids (address_id)',
    'CREATE INDEX idx_street_segment_geom ON street.street_segment USING gist (geom)',
    'CREATE INDEX idx_street_dissolved_geom ON street.street_dissolved USING gist (geom)',
    'CREATE INDEX idx_jurisdiction_geom ON map.jurisdiction USING gist (geom)',
    'CREATE INDEX idx_neighborhood_geom ON map.neighborhood USING gist (geom)',
    'CREATE INDEX idx_area_of_patrol_geom ON map.area_of_patrol USING gist (geom)',
    'CREATE INDEX idx_gang_territory_geom ON map.gang_territory USING gist (geom)',
    'CREATE INDEX idx_zip_code_geom ON map.zip_code USING gist (geom)',
    'CREATE INDEX idx_postal_zone_geom ON map.postal_zone USING gist (geom)',
    'CREATE INDEX idx_poi_geom ON map.point_of_interest USING gist (geom)',
    'CREATE INDEX idx_transit_route_geom ON map.transit_route USING gist (geom)',
    'CREATE INDEX idx_fire_district_geom ON fire.fire_district USING gist (geom)',
    'CREATE INDEX idx_fire_box_geom ON fire.fire_box USING gist (geom)',
    'CREATE INDEX idx_fire_station_geom ON fire.fire_station USING gist (geom)',
    'CREATE INDEX idx_water_supply_geom ON fire.water_supply USING gist (geom)',
    'CREATE INDEX idx_police_zone_geom ON police.police_zone USING gist (geom)',
    'CREATE INDEX idx_dispatched_incident_geom ON incidents.dispatched_incident USING gist (geom)',

    // Key attribute indexes for common lookups
    'CREATE INDEX idx_address_point_street_name ON address.address_point (street_name)',
    'CREATE INDEX idx_address_point_zip_code ON address.address_point (zip_code)',
    'CREATE INDEX idx_address_point_fire_box ON address.address_point (fire_box)',
    'CREATE INDEX idx_address_point_jurisdiction ON address.address_point (jurisdiction)',
    'CREATE INDEX idx_street_segment_name ON street.street_segment (street_name)',
    'CREATE INDEX idx_postal_zone_number ON map.postal_zone (postal_number)',
    'CREATE INDEX idx_fire_box_code ON fire.fire_box (fire_box)',
    'CREATE INDEX idx_water_supply_type ON fire.water_supply (supply_type)',
    'CREATE INDEX idx_police_zone_primary ON police.police_zone (primary_jurisdiction_code)',
    'CREATE INDEX idx_poi_type ON map.point_of_interest (poi_type)',
  ];

  for (const ddl of indexes) {
    const name = ddl.match(/INDEX (\S+)/)[1];
    console.log(`Creating ${name}...`);
    await client.query(ddl);
  }

  console.log(`\nCreated ${indexes.length} indexes.`);
  console.log('Run step 8 next to clean up old schemas.');
};
```

**Step 2: Run step 7**

Run: `node migrate/run_migration.js 7`
Expected: All indexes created successfully.

---

### Task 9: Step 8 — Clean up old schemas and reference data

**Files:**
- Create: `migrate/steps/step8.js`

**Step 1: Create step8.js**

```javascript
module.exports = async function step8(client) {
  console.log('Step 8: Clean up old schemas and reference data\n');
  console.log('This step drops the archived _old_* schemas and reference data from gisdb.');
  console.log('Make sure gisdb_reference has been verified (step 1) before running this.\n');

  // Final verification — compare new schema row counts
  console.log('=== Final Verification ===\n');
  const tables = [
    'address.address_point',
    'address.building_cids',
    'street.street_segment',
    'street.street_dissolved',
    'map.jurisdiction',
    'map.neighborhood',
    'map.area_of_patrol',
    'map.gang_territory',
    'map.zip_code',
    'map.postal_zone',
    'map.point_of_interest',
    'map.transit_route',
    'fire.fire_district',
    'fire.fire_box',
    'fire.fire_station',
    'fire.water_supply',
    'police.police_zone',
    'incidents.dispatched_incident',
  ];

  let totalRows = 0;
  for (const t of tables) {
    const { rows: [{ count }] } = await client.query(`SELECT count(*) as count FROM ${t}`);
    totalRows += Number(count);
    console.log(`  ${t}: ${Number(count).toLocaleString()}`);
  }
  console.log(`\n  Total: ${totalRows.toLocaleString()} rows across ${tables.length} tables`);

  // Drop old schemas
  console.log('\n=== Dropping archived schemas ===\n');
  const oldSchemas = ['_old_address', '_old_street', '_old_map', '_old_fire', '_old_police', '_old_incidents'];
  for (const schema of oldSchemas) {
    try {
      await client.query(`DROP SCHEMA IF EXISTS ${schema} CASCADE`);
      console.log(`  Dropped ${schema}`);
    } catch (e) {
      console.log(`  ${schema}: ${e.message}`);
    }
  }

  // Drop reference schemas (already exported to gisdb_reference)
  console.log('\n=== Dropping reference data schemas ===\n');
  for (const schema of ['pgco', 'tiger_data', 'tiger']) {
    try {
      await client.query(`DROP SCHEMA IF EXISTS ${schema} CASCADE`);
      console.log(`  Dropped ${schema}`);
    } catch (e) {
      console.log(`  ${schema}: ${e.message}`);
    }
  }

  // Drop misc tables
  console.log('\n=== Dropping misc tables ===\n');
  await client.query('DROP TABLE IF EXISTS public.test');
  console.log('  Dropped public.test');

  // Drop empty topology schema
  try {
    await client.query('DROP SCHEMA IF EXISTS topology CASCADE');
    console.log('  Dropped topology');
  } catch (e) {
    console.log(`  topology: ${e.message}`);
  }

  // Report final database size
  const { rows: [{ size }] } = await client.query(
    "SELECT pg_size_pretty(pg_database_size('gisdb')) as size"
  );
  console.log(`\n=== Final database size: ${size} ===`);
  console.log('\nMigration complete! gisdb now has 18 tables across 6 schemas.');
};
```

**Step 2: Run step 8**

Run: `node migrate/run_migration.js 8`
Expected: Old schemas dropped. Database size significantly reduced. 18 tables remaining.

---

### Task 10: Regenerate database inventory and commit

**Step 1: Re-run the inventory script**

Run: `node review_db.js`
Expected: New `docs/database-inventory.md` reflecting the simplified 18-table schema.

**Step 2: Verify the inventory looks correct**

Read `docs/database-inventory.md` and confirm:
- Only 6 schemas remain (address, street, map, fire, police, incidents)
- 18 tables total
- All spatial indexes present
- No reference data or old schemas

**Step 3: Commit the updated inventory and design docs**

```bash
git add docs/
git commit -m "docs: add schema simplification design and updated database inventory"
```
