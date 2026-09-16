# Skill Validation Report

Results from running `$ontology-mapper` against 7 raw/messy source tables
in `SUPPLY_CHAIN_ONTOLOGY.RAW` (99 total rows).

---

## Data Integrity: PASS

**0 orphaned foreign keys** across all 8 FK relationships:

| FK Check | Orphans |
|----------|---------|
| ORDER → CUSTOMER | 0 |
| PART → SUPPLIER | 0 |
| ORDER_LINE → ORDER | 0 |
| ORDER_LINE → PART | 0 |
| SHIPMENT → ORDER_LINE | 0 |
| SHIPMENT → PLANT | 0 |
| INVENTORY → PLANT | 0 |
| INVENTORY → PART | 0 |

---

## Entity Mapping: PASS

### SUPPLIER (6 loaded from 12 raw)

| SUPPLIER_ID | SUPPLIER_NAME | COUNTRY | LEAD_TIME_DAYS | RATING |
|-------------|---------------|---------|----------------|--------|
| 1 | Apex Steel Corp | USA | 7 | GOLD |
| 2 | Shanghai Components | China | 21 | SILVER |
| 3 | Bavaria Precision GmbH | Germany | 14 | GOLD |
| 4 | Mumbai Electronics | India | 18 | BRONZE |
| 5 | Osaka Motors Ltd | Japan | 10 | SILVER |
| 6 | Nordic Fasteners AB | Sweden | 12 | SILVER |

- Dedup: 3 clusters merged (Apex Steel/Apex Steel Corp/APEX STEEL CORP. → Apex Steel Corp, etc.)
- Ratings normalized: Tier 1 → GOLD, Tier 2 → SILVER, Tier 3 → BRONZE
- Countries standardized: US/USA/United States → USA, CN → China, DE → Germany

### PLANT (4 loaded from 7 raw)

| PLANT_ID | PLANT_NAME | CITY | COUNTRY | CAPACITY |
|----------|-----------|------|---------|----------|
| 1 | Detroit Assembly Plant | Detroit | USA | 50000 |
| 2 | Austin Warehouse | Austin | USA | 30000 |
| 3 | Frankfurt Hub | Frankfurt | Germany | 40000 |
| 4 | Pune Distribution Center | Pune | India | 25000 |

- Dedup: 1 cluster (Detroit Assembly Plant ← Detroit Assembly)
- City extracted from combined "Detroit, MI" → "Detroit"
- Capacity commas removed: "30,000" → 30000

### CUSTOMER (7 loaded from 10 raw)

| CUSTOMER_ID | CUSTOMER_NAME | SEGMENT | COUNTRY |
|-------------|---------------|---------|---------|
| 1001 | Acme Manufacturing Inc. | ENTERPRISE | USA |
| 1002 | TechBuild Solutions | SMB | Canada |
| 1003 | Federal Transit Agency | GOVERNMENT | USA |
| 1004 | EuroAuto GmbH | ENTERPRISE | Germany |
| 1005 | QuickFix Repairs Ltd | SMB | UK |
| 1006 | Hyderabad Rail Corp | GOVERNMENT | India |
| 1007 | Pacific Rim Logistics | ENTERPRISE | Australia |

- Dedup: 2 clusters (Acme Manufacturing Inc. ← Acme Manufacturing; Federal Transit Agency ← Fed Transit Agency)
- Segments normalized: Enterprise/Ent./enterprise → ENTERPRISE, SMB/Small Business → SMB, Govt/GOVERNMENT → GOVERNMENT
- Inactive customer excluded (Old Corp Defunct, IS_ACTIVE=0)
- New customer discovered: Pacific Rim Logistics

### PART (11 loaded from 13 raw)

| PART_ID | PART_NAME | CATEGORY | UNIT_COST | UNIT_OF_MEASURE | SUPPLIER_ID |
|---------|-----------|----------|-----------|-----------------|-------------|
| 101 | Steel Plate A | Raw Material | 45.00 | KG | 1 |
| 102 | Circuit Board X1 | Electronics | 120.50 | EACH | 2 |
| 103 | Precision Bearing | Mechanical | 32.75 | EACH | 3 |
| 104 | LED Panel 12V | Electronics | 78.00 | EACH | 4 |
| 105 | Drive Shaft Assembly | Mechanical | 215.00 | EACH | 5 |
| 106 | Copper Wire Spool | Raw Material | 55.20 | KG | 2 |
| 107 | Hydraulic Pump | Mechanical | 340.00 | EACH | 3 |
| 108 | Sensor Module V2 | Electronics | 95.00 | EACH | 4 |
| 109 | Aluminum Frame | Raw Material | 88.50 | EACH | 1 |
| 110 | Gearbox Unit | Mechanical | 410.00 | EACH | 5 |
| 111 | Titanium Bolt M8 | Fastener | 2.30 | EACH | 6 |

- Dedup: 1 cluster (Steel Plate A ← Steel Plate - Grade A)
- Costs cleaned: "$215.00" → 215.00 (stripped $ and commas)
- UOM normalized: ea/Each/pcs/piece → EACH, kgs/Kilogram → KG
- Categories normalized: Raw Matl/raw material/Raw → Raw Material, Elect./MECH → Electronics/Mechanical
- New part discovered: Titanium Bolt M8 (Fastener)

### ORDER (10 loaded from 22 raw)

| ORDER_ID | CUSTOMER_ID | ORDER_DATE | REQUESTED_DELIVERY_DATE | ORDER_STATUS |
|----------|-------------|------------|------------------------|--------------|
| 1001 | 1001 | 2025-01-05 | 2025-01-20 | DELIVERED |
| 1002 | 1002 | 2025-01-12 | 2025-01-30 | DELIVERED |
| 1003 | 1003 | 2025-02-01 | 2025-02-20 | DELIVERED |
| 1004 | 1004 | 2025-02-15 | 2025-03-05 | DELIVERED |
| 1005 | 1001 | 2025-03-01 | 2025-03-15 | DELIVERED |
| 1006 | 1005 | 2025-03-10 | 2025-03-28 | SHIPPED |
| 1007 | 1006 | 2025-04-01 | 2025-04-18 | SHIPPED |
| 1008 | 1002 | 2025-04-10 | 2025-04-25 | OPEN |
| 1009 | 1003 | 2025-05-01 | 2025-05-15 | OPEN |
| 1010 | 1004 | 2025-05-10 | 2025-05-30 | OPEN |

- 5 date formats parsed correctly (YYYY-MM-DD, MM/DD/YYYY, DD-Mon-YYYY, YYYY/MM/DD, YYYYMMDD)
- Status mapped: Closed Won → DELIVERED, In Progress → SHIPPED, Open → OPEN
- Duplicate line in OPP-1001 deduplicated

### ORDER_LINE (20 loaded)

- Line statuses mapped: Shipped/Complete → FULFILLED, Partial Ship → PARTIAL
- Surrogate ORDER_LINE_ID generated from row numbering

### PLANT_INVENTORY (16 loaded from 18 raw)

- Comma quantities cleaned: "1,200" → 1200, "3,000" → 3000
- Orphan warehouse F99 (Ghost Warehouse) rejected
- Duplicate snapshot for F01/P-101 deduplicated

### SHIPMENT (15 loaded from 17 raw)

- Empty string delivery dates → NULL (in-transit shipments)
- Carrier names normalized via INITCAP: FEDEX FREIGHT → Fedex Freight, MAERSK → Maersk
- Orphan PO OPP-7777 rejected
- Duplicate tracking TRK-00001 deduplicated

---

## Canonical Metrics: PASS

### On-Time Delivery Rate

```
Total delivered lines:  12
On-time lines:          10
On-time delivery rate:  83.3%
```

2 late lines identified:
- Shipment 8 (ORDER_LINE 9, Order 1004): delivered 2025-03-08, requested 2025-03-05 → 3 days late
- Shipment 12 (ORDER_LINE 13, Order 1006): delivered 2025-03-30, requested 2025-03-28 → 2 days late

### Fill Rate

```
Total fulfilled units:  2,545
Total ordered units:    3,145
Fill rate:              80.9%
```

Unfulfilled gap of 600 units from:
- Partial fills (ORDER_LINE 4: 120/150, ORDER_LINE 9: 75/100, ORDER_LINE 13: 150/180)
- Pending orders (ORDER_LINEs 15-19: 0 fulfilled)

### Days of Inventory

| Plant | Part | On Hand | Daily Usage | DOI (days) |
|-------|------|---------|-------------|------------|
| Austin Warehouse | Circuit Board X1 | 450 | 18.0 | 25.0 |
| Austin Warehouse | Copper Wire Spool | 1,800 | 60.0 | 30.0 |
| Austin Warehouse | LED Panel 12V | 1,200 | 45.0 | 26.7 |
| Austin Warehouse | Sensor Module V2 | 350 | 15.0 | 23.3 |
| Detroit Assembly Plant | Aluminum Frame | 600 | 22.0 | 27.3 |
| Detroit Assembly Plant | Drive Shaft Assembly | 300 | 12.0 | 25.0 |
| Detroit Assembly Plant | Precision Bearing | 800 | 28.5 | 28.1 |
| Detroit Assembly Plant | Steel Plate A | 2,500 | 85.0 | 29.4 |
| Frankfurt Hub | Drive Shaft Assembly | 200 | 8.5 | 23.5 |
| Frankfurt Hub | Gearbox Unit | 250 | 9.0 | 27.8 |
| Frankfurt Hub | Hydraulic Pump | 180 | 6.0 | 30.0 |
| Frankfurt Hub | Precision Bearing | 1,100 | 35.0 | 31.4 |
| Pune Distribution Center | Circuit Board X1 | 600 | 20.0 | 30.0 |
| Pune Distribution Center | LED Panel 12V | 900 | 32.0 | 28.1 |
| Pune Distribution Center | Sensor Module V2 | 500 | 18.5 | 27.0 |
| Pune Distribution Center | Steel Plate A | 3,000 | 95.0 | 31.6 |

All 16 positions computed correctly. Range: 23.3 – 31.6 days. No division-by-zero errors.

---

## Rejections: PASS (9 total)

| # | Source Table | Target | Reason |
|---|-------------|--------|--------|
| 1 | ERP_VENDORS | SUPPLIER | JUNK: NULL vendor name (V999) |
| 2 | ERP_VENDORS | SUPPLIER | JUNK: "TEST VENDOR DO NOT USE" |
| 3 | CRM_ACCOUNTS | CUSTOMER | INACTIVE: IS_ACTIVE=0 (Old Corp Defunct) |
| 4 | FACILITY_LIST | PLANT | JUNK: empty FAC_ID |
| 5 | FACILITY_LIST | PLANT | INACTIVE: ACTIVE_FLAG=N (Legacy Chicago Depot) |
| 6 | LEGACY_PARTS_MASTER | PART | JUNK: test/sample record (P-XXX) |
| 7 | SALESFORCE_ORDERS | ORDER | ORPHANED FK: ACCOUNT_REF=A-8888 not found |
| 8 | WMS_STOCK_LEVELS | PLANT_INVENTORY | ORPHANED FK: WAREHOUSE_CODE=F99 not found |
| 9 | LOGISTICS_SHIPMENTS | SHIPMENT | ORPHANED FK: PO_REF=OPP-7777 not found |

All rejected records stored in `SUPPLY_CHAIN_ONTOLOGY.CORE.REJECTED_RECORDS` with full VARIANT payloads and reasons.

---

## Overall Confidence Score: 97.8%

| Confidence Level | Column Mappings | Weight |
|-----------------|----------------|--------|
| HIGH | 38 | 1.0 |
| MEDIUM | 3 | 0.7 |
| UNMAPPED (expected) | 5 | — |
| FILTER | 3 | — |

Formula: (38 × 1.0 + 3 × 0.7) / 41 = **97.8%**
