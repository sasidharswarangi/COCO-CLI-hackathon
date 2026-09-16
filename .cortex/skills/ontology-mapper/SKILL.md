---
name: ontology-mapper
description: "Map raw/messy supply chain data into the governed SUPPLY_CHAIN_ONTOLOGY.CORE schema. Use when: ingesting new raw tables, mapping unknown columns to canonical entities, deduplicating supplier/part/plant names, resolving data quality issues before loading. Triggers: map raw data, ontology mapper, ingest raw, map to ontology, clean and load, map messy data, run ontology mapper."
---

# Ontology Mapper

Maps arbitrary raw/messy input tables into the canonical `SUPPLY_CHAIN_ONTOLOGY.CORE` schema. The target schema is never modified — it is read dynamically from Snowflake metadata at runtime.

## Prerequisites

- Database `SUPPLY_CHAIN_ONTOLOGY` with schema `CORE` must exist with all target tables already created.
- User must have INSERT privileges on the CORE tables and SELECT on the raw tables.

## Workflow

### Step 0: Discover Target Schema

Read the canonical schema dynamically — never hardcode it. This makes the skill reusable even if columns are added later.

```sql
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE, ORDINAL_POSITION
FROM SUPPLY_CHAIN_ONTOLOGY.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'CORE'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
```

Also read foreign key relationships:

```sql
SELECT
    tc.TABLE_NAME AS child_table,
    kcu.COLUMN_NAME AS fk_column,
    ccu.TABLE_NAME AS parent_table,
    ccu.COLUMN_NAME AS parent_column
FROM SUPPLY_CHAIN_ONTOLOGY.INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
JOIN SUPPLY_CHAIN_ONTOLOGY.INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
    ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
JOIN SUPPLY_CHAIN_ONTOLOGY.INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
    ON tc.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
JOIN SUPPLY_CHAIN_ONTOLOGY.INFORMATION_SCHEMA.KEY_COLUMN_USAGE ccu
    ON rc.UNIQUE_CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
WHERE tc.CONSTRAINT_TYPE = 'FOREIGN KEY'
    AND tc.TABLE_SCHEMA = 'CORE';
```

Store these results as your working reference for all subsequent steps.

### Step 1: INSPECT — Profile Raw Tables

For each raw table the user provides (fully qualified name):

1. **Schema profile:** Get column names, data types, sample values.
```sql
SELECT * FROM <raw_table> LIMIT 10;
```

2. **Null rates and distinct counts:**
```sql
SELECT
    '<col>' AS column_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN "<col>" IS NULL THEN 1 ELSE 0 END) AS null_count,
    ROUND(null_count / total_rows * 100, 1) AS null_pct,
    COUNT(DISTINCT "<col>") AS distinct_count
FROM <raw_table>;
```
Run this for every column (use a generated UNION ALL query).

3. **Key candidates:** Columns with high distinct counts and low null rates are PK candidates.

Present the profile as a table and confirm with the user before proceeding.

**STOP**: Show the profile results. Ask "Does this look right? Any columns I should ignore or treat specially?"

### Step 2: MAP — Infer Column Mappings

For each raw column, determine which canonical `TABLE.COLUMN` it maps to.

**Mapping strategy (in priority order):**
1. **Exact match:** Raw column name equals a canonical column name (case-insensitive).
2. **Synonym/abbreviation match:** Common patterns:
   - `supp_name`, `vendor_name`, `supplier_nm` → `SUPPLIER.SUPPLIER_NAME`
   - `qty`, `quantity`, `amt` → context-dependent (check which entity the table represents)
   - `dt`, `_date`, `_dt` suffix → DATE columns
   - `id`, `_id`, `_key`, `_no`, `_num` suffix → key columns
3. **Semantic inference:** Use the combination of column name + sample values + data type to infer mapping. For example, a column named `facility` with values like city names maps to `PLANT.CITY`, not `PLANT.PLANT_NAME`.
4. **Unmappable:** If confidence is below ~70%, flag the column as `UNMAPPED` rather than guessing.

Build a mapping table:

| Raw Column | Raw Type | Canonical Target | Confidence | Notes |
|------------|----------|-------------------|------------|-------|
| supp_name | VARCHAR | SUPPLIER.SUPPLIER_NAME | HIGH | Synonym match |
| fac_loc | VARCHAR | PLANT.CITY | MEDIUM | Inferred from sample values |
| mystery_col | NUMBER | UNMAPPED | LOW | No clear match |

**STOP**: Present the mapping table. Ask "Please review these mappings. Should I adjust any? What should I do with UNMAPPED columns — ignore or map them manually?"

### Step 3: RESOLVE — Clean and Deduplicate

After mappings are confirmed, resolve data quality issues.

#### 3a. Deduplication

For entity tables (SUPPLIER, PART, PLANT, CUSTOMER), detect near-duplicates:

```sql
-- Example: find potential duplicate suppliers
SELECT a.raw_supplier_name, b.raw_supplier_name,
       JAROWINKLER_SIMILARITY(a.raw_supplier_name, b.raw_supplier_name) AS similarity
FROM raw_suppliers a
JOIN raw_suppliers b
    ON a.rowid < b.rowid
    AND JAROWINKLER_SIMILARITY(a.raw_supplier_name, b.raw_supplier_name) > 85;
```

For each cluster of near-duplicates, pick the canonical form (longest, most complete name) and create a dedup mapping. Use a temporary mapping table:

```sql
CREATE OR REPLACE TEMP TABLE _dedup_supplier (
    raw_name VARCHAR,
    canonical_name VARCHAR
);
```

#### 3b. Unit/Format Standardization

- **Dates:** Convert all date-like columns to `DATE` using `TRY_TO_DATE()` with multiple format strings. Log failures.
- **Currency:** If raw data has currency columns, normalize to the unit_cost scale (NUMBER(12,2)).
- **Units of measure:** Map variations (`ea`, `each`, `EA`, `pcs`, `piece` → `EACH`; `kg`, `KG`, `kgs`, `kilogram` → `KG`).

#### 3c. Orphan Detection

Before loading dependent tables, verify referential integrity:

```sql
-- Example: find order lines referencing non-existent orders
SELECT ol.*
FROM staged_order_lines ol
LEFT JOIN SUPPLY_CHAIN_ONTOLOGY.CORE."ORDER" o ON ol.order_id = o.ORDER_ID
WHERE o.ORDER_ID IS NULL;
```

Route orphans to a rejection table:

```sql
CREATE TABLE IF NOT EXISTS SUPPLY_CHAIN_ONTOLOGY.CORE.REJECTED_RECORDS (
    REJECTION_ID INTEGER AUTOINCREMENT,
    SOURCE_TABLE VARCHAR,
    TARGET_TABLE VARCHAR,
    RECORD_DATA VARIANT,
    REJECTION_REASON VARCHAR,
    REJECTED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
```

Insert orphaned records as VARIANT with reason = `'ORPHANED_FK: <fk_column> value <value> not found in <parent_table>'`.

**STOP**: Show dedup clusters, unit mappings, and orphan counts. Ask "Should I proceed with loading?"

### Step 4: LOAD — Insert Clean Records

Load tables in dependency order to maintain referential integrity:

**Level 0 (no FKs):** SUPPLIER, PLANT, CUSTOMER
**Level 1 (depends on L0):** PART, "ORDER"
**Level 2 (depends on L1):** PLANT_INVENTORY, ORDER_LINE
**Level 3 (depends on L2):** SHIPMENT

For each table:
1. Build an INSERT...SELECT that applies the confirmed column mappings, dedup mappings, and format standardizations.
2. Use `INSERT INTO ... SELECT DISTINCT ...` to avoid loading duplicates.
3. Count rows before and after to report in Step 5.

Wrap all inserts in a transaction if possible, or load level by level and verify counts between levels.

### Step 5: REPORT — Output Mapping Report

Generate a structured report with these sections:

#### Column Mapping Summary
| Raw Table | Raw Column | → Target Table | → Target Column | Confidence | Method |
|-----------|-----------|----------------|-----------------|------------|--------|

#### Deduplication Summary
| Entity | Clusters Found | Records Merged | Example |
|--------|---------------|----------------|---------|

#### Rejection Summary
| Target Table | Records Rejected | Top Reasons |
|-------------|-----------------|-------------|

#### Load Summary
| Target Table | Records Before | Records Added | Records After |
|-------------|---------------|---------------|---------------|

#### Overall Confidence Score
Weighted average of per-column confidence scores (HIGH=1.0, MEDIUM=0.7, LOW=0.3), weighted by row volume. Report as a percentage.

Present this report to the user. Save it as a markdown file if requested.

## Stopping Points

- **After Step 1 (INSPECT):** User reviews raw data profile
- **After Step 2 (MAP):** User reviews and corrects column mappings
- **After Step 3 (RESOLVE):** User reviews dedup clusters, unit mappings, orphan counts
- **After Step 5 (REPORT):** User reviews final mapping report

## Output

- Clean records inserted into `SUPPLY_CHAIN_ONTOLOGY.CORE.*` tables
- Rejected records in `SUPPLY_CHAIN_ONTOLOGY.CORE.REJECTED_RECORDS`
- Mapping report (displayed and optionally saved as markdown)

## Notes

- The target schema is always read dynamically from `INFORMATION_SCHEMA` — never hardcoded. If new columns are added to the canonical schema, the skill picks them up automatically.
- The skill uses `JAROWINKLER_SIMILARITY` (built into Snowflake) for fuzzy dedup — no external dependencies.
- For very large raw datasets (>1M rows), consider running dedup on a sample first, then applying the mapping table to the full set.
- The `REJECTED_RECORDS` table accumulates across runs. Query it filtered by `REJECTED_AT` to see rejections from a specific run.
