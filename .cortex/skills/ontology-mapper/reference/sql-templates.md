# SQL Templates

Reusable SQL patterns for each phase of the ontology-mapper workflow.
Replace `<placeholders>` with actual values at runtime.

---

## Step 0: Schema Discovery

```sql
-- Get all columns in the target schema
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE, ORDINAL_POSITION
FROM SUPPLY_CHAIN_ONTOLOGY.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'CORE'
  AND TABLE_NAME != 'REJECTED_RECORDS'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
```

---

## Step 1: Profiling

```sql
-- Column-level profile (generate one SELECT per column, UNION ALL together)
SELECT
    '<col_name>' AS column_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN "<col_name>" IS NULL THEN 1 ELSE 0 END) AS null_count,
    ROUND(null_count / NULLIF(total_rows, 0) * 100, 1) AS null_pct,
    COUNT(DISTINCT "<col_name>") AS distinct_count,
    MIN("<col_name>"::VARCHAR) AS min_val,
    MAX("<col_name>"::VARCHAR) AS max_val
FROM <raw_table>;
```

---

## Step 3a: Fuzzy Deduplication

```sql
-- Find near-duplicate entity names using Jaro-Winkler
SELECT
    a."<name_col>" AS name_a,
    b."<name_col>" AS name_b,
    JAROWINKLER_SIMILARITY(a."<name_col>", b."<name_col>") AS similarity
FROM <raw_table> a
JOIN <raw_table> b
    ON a."<pk_col>" < b."<pk_col>"
WHERE JAROWINKLER_SIMILARITY(a."<name_col>", b."<name_col>") > 85
ORDER BY similarity DESC;
```

```sql
-- Create dedup mapping table
CREATE OR REPLACE TEMP TABLE _dedup_<entity> (
    raw_name VARCHAR,
    canonical_name VARCHAR
);
```

---

## Step 3b: Date Standardization

```sql
-- Try multiple date formats, pick the first that works
SELECT
    COALESCE(
        TRY_TO_DATE("<col>", 'YYYY-MM-DD'),
        TRY_TO_DATE("<col>", 'MM/DD/YYYY'),
        TRY_TO_DATE("<col>", 'DD-MON-YYYY'),
        TRY_TO_DATE("<col>", 'YYYYMMDD'),
        TRY_TO_DATE("<col>", 'MM-DD-YYYY')
    ) AS standardized_date
FROM <raw_table>;
```

---

## Step 3b: Unit of Measure Standardization

```sql
-- Normalize UOM values
CASE UPPER(TRIM("<uom_col>"))
    WHEN 'EA'        THEN 'EACH'
    WHEN 'EACH'      THEN 'EACH'
    WHEN 'PCS'       THEN 'EACH'
    WHEN 'PIECE'     THEN 'EACH'
    WHEN 'PIECES'    THEN 'EACH'
    WHEN 'KG'        THEN 'KG'
    WHEN 'KGS'       THEN 'KG'
    WHEN 'KILOGRAM'  THEN 'KG'
    WHEN 'KILOGRAMS' THEN 'KG'
    WHEN 'LTR'       THEN 'LITER'
    WHEN 'LITER'     THEN 'LITER'
    WHEN 'LITRE'     THEN 'LITER'
    WHEN 'L'         THEN 'LITER'
    ELSE UPPER(TRIM("<uom_col>"))
END AS unit_of_measure
```

---

## Step 3c: Orphan Detection

```sql
-- Generic FK orphan check
SELECT src.*
FROM <staging_table> src
LEFT JOIN <parent_table> p ON src.<fk_col> = p.<pk_col>
WHERE p.<pk_col> IS NULL;
```

---

## Step 3c: Rejected Records Table

```sql
CREATE TABLE IF NOT EXISTS SUPPLY_CHAIN_ONTOLOGY.CORE.REJECTED_RECORDS (
    REJECTION_ID INTEGER AUTOINCREMENT,
    SOURCE_TABLE VARCHAR(500),
    TARGET_TABLE VARCHAR(500),
    RECORD_DATA VARIANT,
    REJECTION_REASON VARCHAR(2000),
    REJECTED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
```

```sql
-- Insert a rejected record
INSERT INTO SUPPLY_CHAIN_ONTOLOGY.CORE.REJECTED_RECORDS
    (SOURCE_TABLE, TARGET_TABLE, RECORD_DATA, REJECTION_REASON)
SELECT
    '<raw_table>',
    '<target_table>',
    OBJECT_CONSTRUCT(*),
    '<reason>'
FROM <orphan_query>;
```

---

## Step 4: Load Template

```sql
-- Generic insert pattern (adapt columns per entity)
INSERT INTO SUPPLY_CHAIN_ONTOLOGY.CORE.<target_table>
    (<col1>, <col2>, ...)
SELECT DISTINCT
    <mapped_expr_1>,
    <mapped_expr_2>,
    ...
FROM <raw_table> r
LEFT JOIN _dedup_<entity> d ON r."<raw_name_col>" = d.raw_name
WHERE <not_in_rejected>;
```
