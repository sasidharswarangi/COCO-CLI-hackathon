# Supply Chain Ontology and Governed Conversational Analytics

## Overview

This project builds a **Supply Chain Ontology** on Snowflake with governed conversational analytics. The data model captures suppliers, parts, plants, inventory, customers, orders, and shipments — along with three canonical supply chain metrics.

- **Database:** `SUPPLY_CHAIN_ONTOLOGY`
- **Schema:** `CORE`

---

## Entity Model

### SUPPLIER

| Attribute | Type | Notes |
|-----------|------|-------|
| **SUPPLIER_ID** (PK) | INTEGER | Surrogate key |
| SUPPLIER_NAME | VARCHAR | Legal entity name |
| COUNTRY | VARCHAR | Country of incorporation |
| LEAD_TIME_DAYS | INTEGER | Standard lead time in calendar days |
| RATING | VARCHAR | Internal tier (GOLD, SILVER, BRONZE) |

**Relationships:**
- SUPPLIER 1 ──< M PART (one supplier furnishes many parts; each part has exactly one primary supplier)

---

### PART

| Attribute | Type | Notes |
|-----------|------|-------|
| **PART_ID** (PK) | INTEGER | Surrogate key |
| PART_NAME | VARCHAR | Descriptive name |
| CATEGORY | VARCHAR | Product family / group |
| UNIT_COST | NUMBER(12,2) | Standard cost per unit |
| UNIT_OF_MEASURE | VARCHAR | e.g. EACH, KG, LITER |
| SUPPLIER_ID (FK) | INTEGER | Primary supplier |

**Relationships:**
- PART M >── 1 SUPPLIER (each part has one primary supplier)
- PART M ──< M PLANT (many-to-many via PLANT_INVENTORY bridge)
- PART 1 ──< M ORDER_LINE (a part appears on many order lines)

---

### PLANT

| Attribute | Type | Notes |
|-----------|------|-------|
| **PLANT_ID** (PK) | INTEGER | Surrogate key |
| PLANT_NAME | VARCHAR | Facility name |
| CITY | VARCHAR | |
| COUNTRY | VARCHAR | |
| CAPACITY | INTEGER | Max units storable |

**Relationships:**
- PLANT M ──< M PART (many-to-many via PLANT_INVENTORY)
- PLANT 1 ──< M SHIPMENT (a plant originates many shipments)

---

### PLANT_INVENTORY (bridge table)

| Attribute | Type | Notes |
|-----------|------|-------|
| **PLANT_ID** (PK, FK) | INTEGER | |
| **PART_ID** (PK, FK) | INTEGER | |
| QUANTITY_ON_HAND | INTEGER | Current stock level |
| REORDER_POINT | INTEGER | Threshold triggering replenishment |
| DAILY_USAGE_RATE | NUMBER(10,2) | Average units consumed per day |

**Grain:** One row per (plant, part) combination.

---

### CUSTOMER

| Attribute | Type | Notes |
|-----------|------|-------|
| **CUSTOMER_ID** (PK) | INTEGER | Surrogate key |
| CUSTOMER_NAME | VARCHAR | |
| SEGMENT | VARCHAR | ENTERPRISE, SMB, GOVERNMENT |
| COUNTRY | VARCHAR | |

**Relationships:**
- CUSTOMER 1 ──< M ORDER (a customer places many orders)

---

### ORDER

| Attribute | Type | Notes |
|-----------|------|-------|
| **ORDER_ID** (PK) | INTEGER | Surrogate key |
| CUSTOMER_ID (FK) | INTEGER | |
| ORDER_DATE | DATE | Date the order was placed |
| REQUESTED_DELIVERY_DATE | DATE | Customer-requested delivery date |
| ORDER_STATUS | VARCHAR | OPEN, SHIPPED, DELIVERED, CANCELLED |

**Relationships:**
- ORDER M >── 1 CUSTOMER
- ORDER 1 ──< M ORDER_LINE (an order contains many lines)

---

### ORDER_LINE

| Attribute | Type | Notes |
|-----------|------|-------|
| **ORDER_LINE_ID** (PK) | INTEGER | Surrogate key |
| ORDER_ID (FK) | INTEGER | |
| PART_ID (FK) | INTEGER | |
| QUANTITY_ORDERED | INTEGER | Units requested |
| QUANTITY_FULFILLED | INTEGER | Units actually shipped |
| LINE_STATUS | VARCHAR | PENDING, FULFILLED, PARTIAL, CANCELLED |

**Grain:** One row per (order, part) combination. Atomic fact for fill-rate measurement.

**Relationships:**
- ORDER_LINE M >── 1 ORDER
- ORDER_LINE M >── 1 PART
- ORDER_LINE 1 ──< M SHIPMENT (a line may be fulfilled across multiple shipments)

---

### SHIPMENT

| Attribute | Type | Notes |
|-----------|------|-------|
| **SHIPMENT_ID** (PK) | INTEGER | Surrogate key |
| ORDER_LINE_ID (FK) | INTEGER | The order line being fulfilled |
| PLANT_ID (FK) | INTEGER | Originating plant |
| SHIP_DATE | DATE | Date shipment left the plant |
| ACTUAL_DELIVERY_DATE | DATE | Date shipment arrived at customer (NULL if in transit) |
| QUANTITY_SHIPPED | INTEGER | Units in this shipment |
| CARRIER | VARCHAR | Logistics provider |

**Grain:** One row per physical shipment. Multiple shipments can fulfill a single order line (split shipments).

**Relationships:**
- SHIPMENT M >── 1 ORDER_LINE
- SHIPMENT M >── 1 PLANT

---

## Canonical Metric Definitions

### 1. On-Time Delivery Rate

| Property | Definition |
|----------|------------|
| **Grain** | Order line |
| **Condition** | An order line is "on time" if every shipment for that line has `ACTUAL_DELIVERY_DATE <= ORDER.REQUESTED_DELIVERY_DATE`. If any shipment is late, the entire line is late. |
| **Formula** | `COUNT(on-time order lines) / COUNT(all delivered order lines) * 100` |
| **Exclusions** | Lines with `LINE_STATUS = 'CANCELLED'` are excluded. Only lines where all shipments have a non-null `ACTUAL_DELIVERY_DATE` are eligible. |
| **Why order-line grain** | Measuring at the order level would mask partial failures. Line-level gives actionable visibility per part. |

### 2. Fill Rate

| Property | Definition |
|----------|------------|
| **Grain** | Order line |
| **Formula** | `SUM(QUANTITY_FULFILLED) / SUM(QUANTITY_ORDERED) * 100` |
| **Scope** | Computed over all non-cancelled order lines within the reporting period (based on `ORDER_DATE`). |
| **Interpretation** | Percentage of demanded units that were actually shipped. A fill rate of 95% means 5% of ordered units went unfulfilled. |

### 3. Days of Inventory (DOI)

| Property | Definition |
|----------|------------|
| **Grain** | (Plant, Part) — one value per inventory position |
| **Formula** | `QUANTITY_ON_HAND / DAILY_USAGE_RATE` |
| **Source** | Both values come from PLANT_INVENTORY. |
| **Interpretation** | How many days current stock will last at the current consumption rate. |
| **Edge cases** | If `DAILY_USAGE_RATE = 0`, DOI is NULL — not infinity — to flag stale inventory. |
| **Aggregation** | Roll up via weighted average: `SUM(QUANTITY_ON_HAND) / SUM(DAILY_USAGE_RATE)`. |

---

## Sample Data Summary

| Table | Rows | Highlights |
|-------|------|------------|
| SUPPLIER | 5 | USA, China, Germany, India, Japan — GOLD/SILVER/BRONZE ratings |
| PART | 10 | Raw Materials, Electronics, Mechanical — costs $32–$410 |
| PLANT | 4 | Detroit, Austin, Frankfurt, Pune |
| PLANT_INVENTORY | 16 | 4 parts per plant, varied stock levels and usage rates |
| CUSTOMER | 6 | ENTERPRISE, SMB, GOVERNMENT segments across 4 countries |
| ORDER | 10 | Jan–May 2025, mix of DELIVERED / SHIPPED / OPEN |
| ORDER_LINE | 20 | FULFILLED, PARTIAL, PENDING, and 1 CANCELLED |
| SHIPMENT | 15 | On-time, late, in-transit, and split shipments |

## Files

- `README.md` — This file (ontology design + metric definitions)
- `01_ddl.sql` — Table creation DDL
- `02_sample_data.sql` — INSERT statements for all sample data
