# Raw / Messy Source Data

Deliberately messy data simulating **7 different source systems** feeding into
the supply chain. Each table has its own quality problems for the ontology-mapper
skill to resolve.

**Total: 99 raw records across 7 tables → target: 8 canonical CORE tables**

---

## Data Flow: Raw Sources → Canonical Schema

```
  ┌─────────────────────────────────────────────────────────────────────┐
  │                     RAW SOURCE SYSTEMS                             │
  │                                                                     │
  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
  │  │  ERP_VENDORS  │  │ CRM_ACCOUNTS │  │ FACILITY_LIST│             │
  │  │  (12 rows)    │  │  (10 rows)   │  │  (7 rows)    │             │
  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘             │
  │         │                  │                  │                      │
  │  ┌──────┴──────────┐      │          ┌───────┴────────┐            │
  │  │ LEGACY_PARTS     │      │          │ WMS_STOCK      │            │
  │  │ _MASTER (13 rows)│      │          │ _LEVELS(18 rows)│            │
  │  └──────┬──────────┘      │          └───────┬────────┘            │
  │         │                  │                  │                      │
  │  ┌──────┴──────────────────┴──────────────────┴──────┐             │
  │  │          SALESFORCE_ORDERS (22 rows)               │             │
  │  │     (merged order headers + line items)            │             │
  │  └──────────────────────┬────────────────────────────┘             │
  │                         │                                           │
  │  ┌──────────────────────┴────────────────────────────┐             │
  │  │        LOGISTICS_SHIPMENTS (17 rows)               │             │
  │  └───────────────────────────────────────────────────┘             │
  └─────────────────────────────┬───────────────────────────────────────┘
                                │
                    ┌───────────▼───────────┐
                    │  ONTOLOGY-MAPPER SKILL │
                    │  (INSPECT → MAP →      │
                    │   RESOLVE → LOAD →     │
                    │   REPORT)              │
                    └───────────┬───────────┘
                                │
  ┌─────────────────────────────▼───────────────────────────────────────┐
  │              SUPPLY_CHAIN_ONTOLOGY.CORE (Governed)                 │
  │                                                                     │
  │  Level 0:   SUPPLIER ─────── PLANT ─────── CUSTOMER               │
  │                │                │               │                   │
  │  Level 1:    PART            (bridge)        "ORDER"               │
  │                │                │               │                   │
  │  Level 2:    PLANT_INVENTORY ───┘          ORDER_LINE              │
  │                                                │                   │
  │  Level 3:                                   SHIPMENT               │
  │                                                                     │
  │  + REJECTED_RECORDS (orphans & failures)                           │
  └─────────────────────────────────────────────────────────────────────┘
```

---

## Source Tables

| # | Raw Table | Source System | Rows | Maps To |
|---|-----------|---------------|------|---------|
| 1 | `ERP_VENDORS` | ERP vendor master | 12 | → SUPPLIER |
| 2 | `CRM_ACCOUNTS` | Salesforce CRM | 10 | → CUSTOMER |
| 3 | `FACILITY_LIST` | Facilities register | 7 | → PLANT |
| 4 | `LEGACY_PARTS_MASTER` | Legacy ERP | 13 | → PART |
| 5 | `WMS_STOCK_LEVELS` | Warehouse mgmt | 18 | → PLANT_INVENTORY |
| 6 | `SALESFORCE_ORDERS` | Salesforce opps | 22 | → ORDER + ORDER_LINE |
| 7 | `LOGISTICS_SHIPMENTS` | 3PL logistics | 17 | → SHIPMENT |

---

## Quality Problems by Category

### 🔀 Duplicates & Near-Duplicates

```
ERP_VENDORS:
  "Apex Steel Corp"  ←→  "Apex Steel"  ←→  "APEX STEEL CORP."
  "Bavaria Precision GmbH"  ←→  "Bavaria Precision"

CRM_ACCOUNTS:
  "Acme Manufacturing Inc."  ←→  "Acme Manufacturing"
  "Federal Transit Agency"  ←→  "Fed Transit Agency"

FACILITY_LIST:
  "Detroit Assembly Plant"  ←→  "Detroit Assembly"

LEGACY_PARTS_MASTER:
  "P-101 Steel Plate A"  ←→  "P-101A Steel Plate - Grade A"

SALESFORCE_ORDERS:
  OPP-1001 line 1 appears twice (different line status: "Shipped" vs "Complete")

LOGISTICS_SHIPMENTS:
  TRK-00001 appears twice (different carrier casing)
```

### 📅 Inconsistent Date Formats

```
Source              Examples                          Formats Present
─────────────────   ───────────────────────────────   ─────────────────
ERP_VENDORS         2025-01-15, 01/20/2025,           YYYY-MM-DD
                    15-Jan-2025, 2025/01/22,           MM/DD/YYYY
                    20250125                           DD-Mon-YYYY
                                                       YYYY/MM/DD
                                                       YYYYMMDD

WMS_STOCK_LEVELS    2025-05-01, 05/01/2025,           YYYY-MM-DD
                    01-May-2025, 2025/05/01,           MM/DD/YYYY
                    20250501                           DD-Mon-YYYY
                                                       YYYY/MM/DD
                                                       YYYYMMDD

SALESFORCE_ORDERS   2025-01-05, 01/20/2025,           YYYY-MM-DD
                    15-Feb-2025, 04/01/2025            MM/DD/YYYY
                                                       DD-Mon-YYYY

LOGISTICS_SHIPMENTS 2025-01-10, 01/18/2025,           YYYY-MM-DD
                    17-Feb-2025, 04/05/2025            MM/DD/YYYY
                                                       DD-Mon-YYYY
```

### 📏 Unit & Format Inconsistencies

```
LEGACY_PARTS_MASTER — Unit of Measure:
  KG, ea, Each, pcs, EACH, kgs, EA, piece, Kilogram
  All need normalization → EACH | KG | LITER

LEGACY_PARTS_MASTER — Cost formatting:
  "45.00"  "120.50"  "78"  "$215.00"  "55.2"  "410"
  Dollar signs, missing decimals need cleanup

LEGACY_PARTS_MASTER — Category abbreviations:
  "Raw Matl" "Electronics" "MECHANICAL" "Elect." "MECH" "raw material" "Raw"
  Need → Raw Material | Electronics | Mechanical

WMS_STOCK_LEVELS — Comma-formatted numbers:
  "1,200"  "3,000"  (strings, not integers)

FACILITY_LIST — Capacity formatting:
  "30,000" (comma-formatted string)

CRM_ACCOUNTS — Segment naming:
  Enterprise, enterprise, Ent., Small Business, SMB, Govt, GOVERNMENT, Government
  Need → ENTERPRISE | SMB | GOVERNMENT
```

### 🔗 Orphaned Foreign Keys

```
Table                 Orphan Record           Missing Parent
────────────────────  ──────────────────────  ──────────────────
SALESFORCE_ORDERS     OPP-9999 → A-8888      No such customer
LOGISTICS_SHIPMENTS   TRK-99999 → OPP-7777   No such order
WMS_STOCK_LEVELS      F99 → Ghost Warehouse   No such plant
```

### 🗑️ Junk & Invalid Records

```
ERP_VENDORS:     V999 (NULL name), '' (TEST VENDOR DO NOT USE)
FACILITY_LIST:   '' (TBD, all NULLs)
LEGACY_PARTS:    P-XXX (SAMPLE - DELETE, category=TEST)
CRM_ACCOUNTS:    A-9999 (Old Corp Defunct, IS_ACTIVE=0)
FACILITY_LIST:   F05 (Legacy Chicago Depot, ACTIVE_FLAG=N)
```

### 🌍 Country Code Inconsistencies

```
ERP_VENDORS:   US, USA, United States, CN, China, DE, Germany, IN, JP, SE
CRM_ACCOUNTS:  United States, US, USA, Canada, Germany, UK, India, Australia
FACILITY_LIST: US, USA, DE, IN
```

---

## Expected Mapping (Raw Column → Canonical)

### ERP_VENDORS → SUPPLIER

| Raw Column | → Canonical Column | Confidence | Notes |
|------------|-------------------|------------|-------|
| VENDOR_NO | SUPPLIER_ID | HIGH | Needs integer extraction |
| VENDOR_NM | SUPPLIER_NAME | HIGH | Synonym match |
| CNTRY | COUNTRY | HIGH | Needs standardization |
| LT_DAYS | LEAD_TIME_DAYS | HIGH | Cast VARCHAR → INTEGER |
| VENDOR_TIER | RATING | MEDIUM | Tier 1→GOLD, Tier 2→SILVER, Tier 3→BRONZE |
| LAST_UPDATED | — | UNMAPPED | No target column |

### CRM_ACCOUNTS → CUSTOMER

| Raw Column | → Canonical Column | Confidence | Notes |
|------------|-------------------|------------|-------|
| ACCT_ID | CUSTOMER_ID | HIGH | Strip "A-" prefix |
| ACCOUNT_NAME | CUSTOMER_NAME | HIGH | Direct match |
| ACCT_TYPE | SEGMENT | HIGH | Normalize values |
| BILLING_COUNTRY | COUNTRY | HIGH | Standardize codes |
| CREATED_DT | — | UNMAPPED | No target column |
| IS_ACTIVE | — | FILTER | Exclude inactive |

### FACILITY_LIST → PLANT

| Raw Column | → Canonical Column | Confidence | Notes |
|------------|-------------------|------------|-------|
| FAC_ID | PLANT_ID | HIGH | Strip "F" prefix |
| FAC_NAME | PLANT_NAME | HIGH | Synonym match |
| CITY_STATE | CITY | MEDIUM | Split on comma, take first part |
| CNTRY_CODE | COUNTRY | HIGH | Standardize |
| MAX_CAPACITY | CAPACITY | HIGH | Remove commas, cast to INTEGER |
| ACTIVE_FLAG | — | FILTER | Exclude N/inactive |

### LEGACY_PARTS_MASTER → PART

| Raw Column | → Canonical Column | Confidence | Notes |
|------------|-------------------|------------|-------|
| ITEM_NO | PART_ID | HIGH | Strip "P-" prefix |
| ITEM_DESC | PART_NAME | HIGH | Synonym match |
| PROD_CATEGORY | CATEGORY | HIGH | Normalize abbreviations |
| STD_COST | UNIT_COST | HIGH | Strip "$", cast to NUMBER |
| UOM | UNIT_OF_MEASURE | HIGH | Normalize (ea→EACH, kgs→KG) |
| PRIMARY_VENDOR | — | LOOKUP | Resolve to SUPPLIER_ID |
| VENDOR_REF | SUPPLIER_ID | HIGH | Resolve via dedup map |

### SALESFORCE_ORDERS → ORDER + ORDER_LINE

| Raw Column | → Canonical Column | Confidence | Notes |
|------------|-------------------|------------|-------|
| SF_OPPORTUNITY_ID | ORDER.ORDER_ID | HIGH | Strip "OPP-" prefix |
| ACCOUNT_REF | ORDER.CUSTOMER_ID | HIGH | Strip "A-" prefix |
| PO_DATE | ORDER.ORDER_DATE | HIGH | Multi-format parse |
| REQUESTED_SHIP_DT | ORDER.REQUESTED_DELIVERY_DATE | HIGH | Multi-format parse |
| STATUS | ORDER.ORDER_STATUS | HIGH | Closed Won→DELIVERED, In Progress→SHIPPED, Open→OPEN |
| LINE_NO | ORDER_LINE.ORDER_LINE_ID | MEDIUM | Composite key needed |
| PRODUCT_SKU | ORDER_LINE.PART_ID | HIGH | Strip "P-" prefix |
| QTY | ORDER_LINE.QUANTITY_ORDERED | HIGH | Direct |
| QTY_SHIPPED | ORDER_LINE.QUANTITY_FULFILLED | HIGH | Direct |
| LINE_STAT | ORDER_LINE.LINE_STATUS | HIGH | Shipped→FULFILLED, Partial Ship→PARTIAL, etc. |

### LOGISTICS_SHIPMENTS → SHIPMENT

| Raw Column | → Canonical Column | Confidence | Notes |
|------------|-------------------|------------|-------|
| TRACKING_NO | SHIPMENT_ID | HIGH | Strip "TRK-" prefix |
| PO_REF + PO_LINE | ORDER_LINE_ID | MEDIUM | Composite lookup |
| ORIGIN_FAC_CODE | PLANT_ID | HIGH | Strip "F" prefix |
| SHIP_DT | SHIP_DATE | HIGH | Multi-format parse |
| DELIVERY_DT | ACTUAL_DELIVERY_DATE | HIGH | '' → NULL, multi-format |
| QTY | QUANTITY_SHIPPED | HIGH | Cast to INTEGER |
| FREIGHT_CARRIER | CARRIER | HIGH | Normalize casing |

### WMS_STOCK_LEVELS → PLANT_INVENTORY

| Raw Column | → Canonical Column | Confidence | Notes |
|------------|-------------------|------------|-------|
| WAREHOUSE_CODE | PLANT_ID | HIGH | Strip "F" prefix |
| SKU | PART_ID | HIGH | Strip "P-" prefix |
| QTY_ON_HAND | QUANTITY_ON_HAND | HIGH | Remove commas, cast |
| REORDER_QTY | REORDER_POINT | HIGH | Cast to INTEGER |
| AVG_DAILY_CONSUMPTION | DAILY_USAGE_RATE | HIGH | Cast to NUMBER |
| SNAPSHOT_DATE | — | UNMAPPED | No target column |

---

## Schema

All tables live in `SUPPLY_CHAIN_ONTOLOGY.RAW`.

## Files

| File | Description |
|------|-------------|
| `README.md` | This file |
| `01_raw_schema.sql` | Schema creation |
| `02_erp_vendors.sql` | Vendor/supplier feed (12 rows) |
| `03_crm_accounts.sql` | Customer feed (10 rows) |
| `04_facility_list.sql` | Plant/facility feed (7 rows) |
| `05_legacy_parts.sql` | Parts master feed (13 rows) |
| `06_wms_stock.sql` | Inventory/stock feed (18 rows) |
| `07_salesforce_orders.sql` | Orders + order lines feed (22 rows) |
| `08_logistics_shipments.sql` | Shipments feed (17 rows) |
