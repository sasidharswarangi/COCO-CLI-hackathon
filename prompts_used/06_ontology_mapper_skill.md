# Prompt 06 — Ontology Mapper Skill

## Context
Built a reusable CoCo skill that can take any raw/messy input tables and map them into the canonical SUPPLY_CHAIN_ONTOLOGY.CORE schema. This is the core "agent" of the hackathon project.

## Prompt
```
I have a canonical, governed target schema already built in Snowflake at 
SUPPLY_CHAIN_ONTOLOGY.CORE (tables: SUPPLIER, PLANT, CUSTOMER, PART, "ORDER", 
ORDER_LINE, PLANT_INVENTORY, SHIPMENT — full DDL attached/pasted below).

I want you to build a reusable CoCo skill called "ontology-mapper" that takes 
ANY raw/messy input table(s) — from unknown source systems, with unknown 
column names, formats, and quality issues — and maps them into this canonical 
schema. The target schema should be treated as fixed and known; never modify it.

The skill should do the following, in order:

1. INSPECT: Profile the incoming raw table(s) — column names, data types, 
   sample values, null rates, apparent key candidates.

2. MAP: For each raw column, infer which canonical entity and attribute it 
   corresponds to (e.g. "vendor_nm" or "supp_name" -> SUPPLIER.SUPPLIER_NAME), 
   using semantic similarity, not just exact name matching. Flag any column 
   it cannot confidently map, rather than guessing silently.

3. RESOLVE: Handle common raw-data problems before loading:
   - Deduplicate entities that refer to the same real-world thing (e.g. 
     "Apex Steel" vs "Apex Steel Corp")
   - Standardize units/formats (dates, currency, measurement units) to match 
     the target schema's conventions
   - Handle orphaned foreign keys (a shipment referencing an order_line that 
     doesn't exist) by flagging them into a REJECTED_RECORDS table rather 
     than silently dropping or inserting broken references

4. LOAD: Write clean, validated records into the corresponding 
   SUPPLY_CHAIN_ONTOLOGY.CORE tables, preserving referential integrity.

5. REPORT: Output a mapping report showing: which raw columns mapped to 
   which canonical fields, how many records were deduplicated, how many 
   were rejected and why, and a confidence score per mapping.

Make this genuinely reusable — it should work on a NEW raw dataset I hand it 
later without me re-specifying the target schema each time (read the schema 
directly from SUPPLY_CHAIN_ONTOLOGY.CORE via Snowflake metadata rather than 
hardcoding it into the skill).

Package this as a CoCo skill named "ontology-mapper" so it can be invoked 
on-demand against any new raw table.

Don't run it against real data yet — first show me the skill definition/plan 
so I can review the mapping logic before we test it.
```

## Outcome
Created `.cortex/skills/ontology-mapper/` with:
- `SKILL.md` (222 lines) — 5-phase workflow: INSPECT → MAP → RESOLVE → LOAD → REPORT
- `reference/target-schema.md` — Entity definitions + common synonym lookup table
- `reference/sql-templates.md` — Reusable SQL for profiling, dedup, orphan detection, loading

Key design decisions:
- Target schema read dynamically from INFORMATION_SCHEMA (never hardcoded)
- JAROWINKLER_SIMILARITY for fuzzy dedup (Snowflake-native, no dependencies)
- Orphaned FKs routed to REJECTED_RECORDS table as VARIANT
- 4 user checkpoints (after INSPECT, MAP, RESOLVE, and REPORT)
- Load order follows FK dependency levels (L0 → L1 → L2 → L3)
- Confidence scoring: HIGH=1.0, MEDIUM=0.7, LOW=0.3, weighted by row volume
