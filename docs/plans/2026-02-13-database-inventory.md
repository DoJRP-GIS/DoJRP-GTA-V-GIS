# gisdb Comprehensive Inventory — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create `review_db.js` that queries every aspect of the gisdb PostGIS database and writes a structured inventory to `docs/database-inventory.md`.

**Architecture:** Single script with query functions for each report section, collecting results into a markdown string, then writing to file. Uses the `pg` Client (already installed) with the same connection pattern as the existing `inspect_db.js`.

**Tech Stack:** Node.js, pg v8.18.0, PostgreSQL/PostGIS on localhost:5433

---

### Task 1: Create review_db.js scaffold with connection and file writing

**Files:**
- Create: `review_db.js`
- Modify: `.gitignore` (add `review_db.js` to the gitignored inspection scripts)

**Step 1: Create the script scaffold**

Create `review_db.js` with:
- `pg` Client connection (same creds as `inspect_db.js`: localhost:5433, gisdb, postgres, 567856)
- `const fs = require('fs')` for file writing
- `const path = require('path')` for output path
- Main `reviewDatabase()` async function with try/catch/finally
- At the end, write the collected markdown string to `docs/database-inventory.md`
- Console log progress as each section completes

```javascript
#!/usr/bin/env node
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const client = new Client({
  host: 'localhost',
  port: 5433,
  database: 'gisdb',
  user: 'postgres',
  password: '567856'
});

async function reviewDatabase() {
  let md = '';
  try {
    await client.connect();
    console.log('Connected to gisdb');

    // Section functions will append to md here
    // (Tasks 2-6 fill these in)

    const outPath = path.join(__dirname, 'docs', 'database-inventory.md');
    fs.mkdirSync(path.dirname(outPath), { recursive: true });
    fs.writeFileSync(outPath, md, 'utf8');
    console.log(`\nInventory written to ${outPath}`);
  } catch (error) {
    console.error('Error:', error.message);
    if (error.code) console.error('Code:', error.code);
  } finally {
    await client.end();
  }
}

reviewDatabase();
```

**Step 2: Add review_db.js to .gitignore**

The existing `.gitignore` already has `inspect_db.js` and `inspect_*.js`. Add `review_db.js` on the line after `inspect_*.js`:

```
review_db.js
```

**Step 3: Run the scaffold to verify connection**

Run: `node review_db.js`
Expected: "Connected to gisdb" and an empty `docs/database-inventory.md` file created.

**Step 4: Commit**

```bash
git add .gitignore
git commit -m "chore: add review_db.js to gitignore"
```

---

### Task 2: Section 1 — Database Overview

**Files:**
- Modify: `review_db.js`

**Step 1: Add database overview query function**

Add this function before `reviewDatabase()`:

```javascript
async function getDatabaseOverview(client) {
  let md = '# gisdb — Comprehensive Database Inventory\n\n';
  md += `*Generated: ${new Date().toISOString()}*\n\n`;
  md += '## 1. Database Overview\n\n';

  // PostgreSQL version
  const { rows: [{ version }] } = await client.query('SELECT version()');
  md += `**PostgreSQL Version:** ${version}\n\n`;

  // Database size
  const { rows: [{ size }] } = await client.query(
    "SELECT pg_size_pretty(pg_database_size('gisdb')) as size"
  );
  md += `**Database Size:** ${size}\n\n`;

  // Extensions
  const { rows: extensions } = await client.query(
    "SELECT extname, extversion FROM pg_extension ORDER BY extname"
  );
  md += '**Installed Extensions:**\n\n';
  md += '| Extension | Version |\n|---|---|\n';
  for (const ext of extensions) {
    md += `| ${ext.extname} | ${ext.extversion} |\n`;
  }
  md += '\n';

  // Schemas
  const { rows: schemas } = await client.query(
    "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('pg_catalog', 'information_schema', 'pg_toast') ORDER BY schema_name"
  );
  md += '**Schemas:**\n\n';
  for (const s of schemas) {
    md += `- ${s.schema_name}\n`;
  }
  md += '\n';

  return md;
}
```

**Step 2: Wire it into reviewDatabase()**

Replace the `// Section functions will append to md here` comment with:

```javascript
md += await getDatabaseOverview(client);
console.log('Section 1: Database Overview — done');
```

**Step 3: Run and verify**

Run: `node review_db.js`
Expected: Console shows "Section 1: Database Overview — done". `docs/database-inventory.md` contains the overview with version, size, extensions, and schemas.

---

### Task 3: Section 2 — Table Inventory

**Files:**
- Modify: `review_db.js`

**Step 1: Add table inventory query function**

Add this function:

```javascript
async function getTableInventory(client) {
  let md = '## 2. Table Inventory\n\n';

  // All user tables
  const { rows: tables } = await client.query(`
    SELECT
      schemaname as schema,
      tablename as table_name,
      pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) as total_size,
      pg_size_pretty(pg_relation_size(schemaname || '.' || tablename)) as table_size,
      pg_size_pretty(pg_indexes_size(schemaname || '.' || tablename)) as index_size
    FROM pg_tables
    WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
    ORDER BY schemaname, tablename
  `);

  for (const table of tables) {
    const fullName = `${table.schema}.${table.table_name}`;

    // Row count
    const { rows: [{ count }] } = await client.query(
      `SELECT COUNT(*) as count FROM ${fullName}`
    );

    md += `### ${fullName}\n\n`;
    md += `- **Rows:** ${Number(count).toLocaleString()}\n`;
    md += `- **Total Size:** ${table.total_size} (Table: ${table.table_size}, Indexes: ${table.index_size})\n\n`;

    // Columns
    const { rows: columns } = await client.query(`
      SELECT
        c.column_name,
        c.data_type,
        c.is_nullable,
        c.column_default,
        c.character_maximum_length
      FROM information_schema.columns c
      WHERE c.table_schema = $1 AND c.table_name = $2
      ORDER BY c.ordinal_position
    `, [table.schema, table.table_name]);

    md += '**Columns:**\n\n';
    md += '| Column | Type | Nullable | Default |\n|---|---|---|---|\n';
    for (const col of columns) {
      const type = col.character_maximum_length
        ? `${col.data_type}(${col.character_maximum_length})`
        : col.data_type;
      md += `| ${col.column_name} | ${type} | ${col.is_nullable} | ${col.column_default || ''} |\n`;
    }
    md += '\n';

    // Constraints (PK, unique, check, FK)
    const { rows: constraints } = await client.query(`
      SELECT
        tc.constraint_name,
        tc.constraint_type,
        kcu.column_name,
        ccu.table_schema AS ref_schema,
        ccu.table_name AS ref_table,
        ccu.column_name AS ref_column
      FROM information_schema.table_constraints tc
      LEFT JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
      LEFT JOIN information_schema.constraint_column_usage ccu
        ON tc.constraint_name = ccu.constraint_name AND tc.table_schema = ccu.table_schema
      WHERE tc.table_schema = $1 AND tc.table_name = $2
      ORDER BY tc.constraint_type, tc.constraint_name
    `, [table.schema, table.table_name]);

    if (constraints.length > 0) {
      md += '**Constraints:**\n\n';
      md += '| Constraint | Type | Column(s) | References |\n|---|---|---|---|\n';
      for (const c of constraints) {
        const ref = c.constraint_type === 'FOREIGN KEY'
          ? `${c.ref_schema}.${c.ref_table}(${c.ref_column})`
          : '';
        md += `| ${c.constraint_name} | ${c.constraint_type} | ${c.column_name || ''} | ${ref} |\n`;
      }
      md += '\n';
    }
  }

  return md;
}
```

**Step 2: Wire it into reviewDatabase()**

After the Section 1 line, add:

```javascript
md += await getTableInventory(client);
console.log('Section 2: Table Inventory — done');
```

**Step 3: Run and verify**

Run: `node review_db.js`
Expected: Inventory now includes all tables with columns, sizes, and constraints.

---

### Task 4: Section 3 — Spatial Data

**Files:**
- Modify: `review_db.js`

**Step 1: Add spatial data query function**

```javascript
async function getSpatialData(client) {
  let md = '## 3. Spatial Data\n\n';

  const { rows: geomCols } = await client.query(`
    SELECT
      f_table_schema as schema,
      f_table_name as table_name,
      f_geometry_column as geom_column,
      coord_dimension as dims,
      srid,
      type as geom_type
    FROM geometry_columns
    ORDER BY f_table_schema, f_table_name
  `);

  if (geomCols.length === 0) {
    md += '*No spatial tables found.*\n\n';
    return md;
  }

  md += `**${geomCols.length} spatial table(s) found.**\n\n`;

  for (const gc of geomCols) {
    const fullName = `${gc.schema}.${gc.table_name}`;
    md += `### ${fullName} — Spatial Details\n\n`;
    md += `- **Geometry Column:** ${gc.geom_column}\n`;
    md += `- **Geometry Type:** ${gc.geom_type}\n`;
    md += `- **SRID:** ${gc.srid}\n`;
    md += `- **Dimensions:** ${gc.dims}D\n`;

    // SRS details
    if (gc.srid > 0) {
      try {
        const { rows: srs } = await client.query(
          'SELECT auth_name, auth_srid, srtext, proj4text FROM spatial_ref_sys WHERE srid = $1',
          [gc.srid]
        );
        if (srs.length > 0) {
          md += `- **SRS Authority:** ${srs[0].auth_name}:${srs[0].auth_srid}\n`;
          md += `- **Proj4:** \`${srs[0].proj4text}\`\n`;
        }
      } catch (e) { /* spatial_ref_sys may not exist */ }
    }

    // Extent
    try {
      const { rows: [{ extent }] } = await client.query(
        `SELECT ST_AsText(ST_Extent(${gc.geom_column})) as extent FROM ${fullName}`
      );
      md += `- **Extent:** \`${extent || 'N/A'}\`\n`;
    } catch (e) {
      md += `- **Extent:** Could not calculate\n`;
    }

    // Sample geometry (first row)
    try {
      const { rows } = await client.query(
        `SELECT ST_AsText(${gc.geom_column}) as wkt FROM ${fullName} LIMIT 1`
      );
      if (rows.length > 0 && rows[0].wkt) {
        const sample = rows[0].wkt.length > 200
          ? rows[0].wkt.substring(0, 200) + '...'
          : rows[0].wkt;
        md += `- **Sample Geometry:** \`${sample}\`\n`;
      }
    } catch (e) { /* skip */ }

    md += '\n';
  }

  return md;
}
```

**Step 2: Wire it into reviewDatabase()**

```javascript
md += await getSpatialData(client);
console.log('Section 3: Spatial Data — done');
```

**Step 3: Run and verify**

Run: `node review_db.js`
Expected: Spatial tables show geometry details, SRID info, extents, and sample geometries.

---

### Task 5: Section 4 — Indexes

**Files:**
- Modify: `review_db.js`

**Step 1: Add indexes query function**

```javascript
async function getIndexes(client) {
  let md = '## 4. Indexes\n\n';

  const { rows: indexes } = await client.query(`
    SELECT
      schemaname as schema,
      tablename as table_name,
      indexname as index_name,
      indexdef as definition,
      pg_size_pretty(pg_relation_size(schemaname || '.' || indexname)) as size
    FROM pg_indexes
    WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
    ORDER BY schemaname, tablename, indexname
  `);

  if (indexes.length === 0) {
    md += '*No indexes found.*\n\n';
    return md;
  }

  md += `**${indexes.length} index(es) found.**\n\n`;
  md += '| Table | Index Name | Size | Type | Definition |\n|---|---|---|---|---|\n';

  for (const idx of indexes) {
    // Detect index type from definition
    let type = 'btree';
    if (idx.definition.includes('USING gist')) type = 'gist';
    else if (idx.definition.includes('USING gin')) type = 'gin';
    else if (idx.definition.includes('USING hash')) type = 'hash';
    else if (idx.definition.includes('USING brin')) type = 'brin';
    else if (idx.definition.includes('USING spgist')) type = 'spgist';

    const spatial = type === 'gist' ? ' (spatial)' : '';
    const shortDef = idx.definition.replace(/^CREATE (?:UNIQUE )?INDEX \S+ ON /, 'ON ');
    md += `| ${idx.schema}.${idx.table_name} | ${idx.index_name} | ${idx.size} | ${type}${spatial} | \`${shortDef}\` |\n`;
  }
  md += '\n';

  return md;
}
```

**Step 2: Wire it into reviewDatabase()**

```javascript
md += await getIndexes(client);
console.log('Section 4: Indexes — done');
```

**Step 3: Run and verify**

Run: `node review_db.js`
Expected: All indexes listed with types, sizes, and definitions. GiST indexes marked as spatial.

---

### Task 6: Section 5 — Views & Functions

**Files:**
- Modify: `review_db.js`

**Step 1: Add views and functions query function**

```javascript
async function getViewsAndFunctions(client) {
  let md = '## 5. Views & Functions\n\n';

  // Views
  const { rows: views } = await client.query(`
    SELECT schemaname, viewname, definition
    FROM pg_views
    WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
    ORDER BY schemaname, viewname
  `);

  md += `### Views (${views.length})\n\n`;
  if (views.length === 0) {
    md += '*No custom views found.*\n\n';
  } else {
    for (const v of views) {
      md += `#### ${v.schemaname}.${v.viewname}\n\n`;
      md += '```sql\n' + v.definition.trim() + '\n```\n\n';
    }
  }

  // Functions (exclude system/PostGIS built-in functions)
  const { rows: functions } = await client.query(`
    SELECT
      n.nspname as schema,
      p.proname as name,
      pg_get_function_arguments(p.oid) as args,
      pg_get_function_result(p.oid) as return_type,
      CASE p.prokind WHEN 'f' THEN 'function' WHEN 'p' THEN 'procedure' WHEN 'a' THEN 'aggregate' WHEN 'w' THEN 'window' END as kind,
      pg_get_functiondef(p.oid) as definition
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
      AND n.nspname NOT LIKE 'pg_toast%'
      AND p.proname NOT LIKE 'st_%'
      AND p.proname NOT LIKE '_st_%'
      AND p.proname NOT LIKE 'postgis%'
      AND p.proname NOT LIKE 'geometry%'
      AND p.proname NOT LIKE 'geography%'
      AND p.proname NOT LIKE 'box%'
      AND p.oid NOT IN (SELECT objid FROM pg_depend WHERE deptype = 'e')
    ORDER BY n.nspname, p.proname
  `);

  md += `### Custom Functions (${functions.length})\n\n`;
  if (functions.length === 0) {
    md += '*No custom functions found (PostGIS built-in functions excluded).*\n\n';
  } else {
    for (const f of functions) {
      md += `#### ${f.schema}.${f.name}(${f.args}) -> ${f.return_type} [${f.kind}]\n\n`;
      md += '```sql\n' + (f.definition || 'N/A').trim() + '\n```\n\n';
    }
  }

  return md;
}
```

**Step 2: Wire it into reviewDatabase()**

```javascript
md += await getViewsAndFunctions(client);
console.log('Section 5: Views & Functions — done');
```

**Step 3: Run and verify**

Run: `node review_db.js`
Expected: Views and custom functions listed (PostGIS built-ins excluded).

---

### Task 7: Section 6 — Summary Statistics

**Files:**
- Modify: `review_db.js`

**Step 1: Add summary statistics function**

```javascript
async function getSummaryStats(client) {
  let md = '## 6. Summary Statistics\n\n';

  // Table count
  const { rows: [{ table_count }] } = await client.query(`
    SELECT COUNT(*) as table_count FROM pg_tables
    WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
  `);

  // Spatial table count
  const { rows: [{ spatial_count }] } = await client.query(`
    SELECT COUNT(DISTINCT f_table_schema || '.' || f_table_name) as spatial_count
    FROM geometry_columns
  `);

  md += `- **Total Tables:** ${table_count}\n`;
  md += `- **Spatial Tables:** ${spatial_count}\n`;
  md += `- **Non-Spatial Tables:** ${Number(table_count) - Number(spatial_count)}\n\n`;

  // Size breakdown
  const { rows: sizes } = await client.query(`
    SELECT
      schemaname || '.' || tablename as full_name,
      pg_total_relation_size(schemaname || '.' || tablename) as raw_size,
      pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) as total_size
    FROM pg_tables
    WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
    ORDER BY pg_total_relation_size(schemaname || '.' || tablename) DESC
  `);

  md += '**Size Breakdown (largest first):**\n\n';
  md += '| Table | Size |\n|---|---|\n';
  for (const s of sizes) {
    md += `| ${s.full_name} | ${s.total_size} |\n`;
  }
  md += '\n';

  // Total rows across all tables
  let totalRows = 0;
  for (const s of sizes) {
    try {
      const { rows: [{ count }] } = await client.query(`SELECT COUNT(*) as count FROM ${s.full_name}`);
      totalRows += Number(count);
    } catch (e) { /* skip inaccessible tables */ }
  }
  md += `**Total Rows (all tables):** ${totalRows.toLocaleString()}\n\n`;

  return md;
}
```

**Step 2: Wire it into reviewDatabase()**

```javascript
md += await getSummaryStats(client);
console.log('Section 6: Summary Statistics — done');
```

**Step 3: Run and verify**

Run: `node review_db.js`
Expected: Full inventory report in `docs/database-inventory.md` with all 6 sections.

---

### Task 8: Final run, review output, commit report

**Step 1: Run the complete script**

Run: `node review_db.js`
Expected: All 6 sections complete, inventory written.

**Step 2: Review the generated report**

Read `docs/database-inventory.md` and scan for:
- All tables accounted for
- Column listings look correct
- Spatial data sections populated
- No errors or empty sections that should have data

**Step 3: Commit the report**

```bash
git add docs/database-inventory.md
git commit -m "docs: add comprehensive gisdb database inventory"
```
