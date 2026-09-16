# Prompt 07 — Testing the Ontology Mapper Skill

## Context
Generated deliberately messy raw data simulating 7 different source systems, then ran the ontology-mapper skill end-to-end to validate it could INSPECT, MAP, RESOLVE, LOAD, and REPORT against real messy inputs.

## Prompts

### 7a. Generating Raw/Messy Test Data
```
yes generate some
```
(In response to "Want me to generate those messy raw tables now so we can test the skill end-to-end?")

### 7b. Understanding How to Run the Skill
```
so how to run this skill
```

### 7c. Invoking the Skill
```
$ontology-mapper
```
(Typed directly in the CoCo CLI prompt to invoke the skill)

### 7d. Proceeding Through All Phases
```
yes
```
(In response to "Shall I proceed to Step 3: RESOLVE and then straight through to loading?")

## Raw Data Generated

7 tables created in `SUPPLY_CHAIN_ONTOLOGY.RAW` with 99 total rows:

| Raw Table | Rows | Source System | Key Problems |
|-----------|------|---------------|--------------|
| ERP_VENDORS | 12 | ERP vendor master | Duplicate vendors, mixed country codes, junk/null records |
| CRM_ACCOUNTS | 10 | Salesforce CRM | Segment inconsistencies, duplicate accounts, inactive records |
| FACILITY_LIST | 7 | Facilities register | Comma-formatted capacity, Y/N/Yes flags, dupes |
| LEGACY_PARTS_MASTER | 13 | Legacy ERP | $ in costs, inconsistent UOM, abbreviated categories |
| WMS_STOCK_LEVELS | 18 | Warehouse mgmt | Comma quantities, orphan warehouse, dupe snapshots |
| SALESFORCE_ORDERS | 22 | Salesforce opps | Merged order+line, mixed dates, status mismatches, orphan account |
| LOGISTICS_SHIPMENTS | 17 | 3PL logistics | Empty vs NULL dates, carrier variations, orphan PO, dupe tracking |

## Skill Execution Results

### Load Summary
| Target Table | Raw Rows | Loaded | Rejected | Deduped |
|-------------|----------|--------|----------|---------|
| SUPPLIER | 12 | 6 | 2 | 4 |
| PLANT | 7 | 4 | 2 | 1 |
| CUSTOMER | 10 | 7 | 1 | 2 |
| PART | 13 | 11 | 1 | 1 |
| ORDER | 22 | 10 | 1 | 1 |
| ORDER_LINE | 22 | 20 | — | 1 |
| PLANT_INVENTORY | 18 | 16 | 1 | 1 |
| SHIPMENT | 17 | 15 | 1 | 1 |
| **TOTAL** | **99** | **89** | **9** | |

### Dedup Clusters Resolved
- SUPPLIER: Apex Steel Corp ← {Apex Steel, APEX STEEL CORP.}; Shanghai Components ← {Shanghai Components Co}; Bavaria Precision GmbH ← {Bavaria Precision}
- CUSTOMER: Acme Manufacturing Inc. ← {Acme Manufacturing}; Federal Transit Agency ← {Fed Transit Agency}
- PLANT: Detroit Assembly Plant ← {Detroit Assembly}
- PART: Steel Plate A ← {Steel Plate - Grade A}

### Records Rejected (9 total)
- 3 junk (null/test records)
- 2 inactive (churned customer, decommissioned plant)
- 3 orphaned FKs (unknown customer A-8888, ghost warehouse F99, unknown PO OPP-7777)
- 1 duplicate line

### Standardizations Applied
- 5 date formats → DATE
- Country codes (US/USA/United States → USA, CN → China, etc.)
- UOM (ea/Each/pcs/piece/kgs/Kilogram → EACH/KG)
- Costs (stripped $ and commas)
- Segments (Enterprise/Ent./Small Business/Govt → ENTERPRISE/SMB/GOVERNMENT)
- Ratings (Tier 1/Gold → GOLD, etc.)
- Order/line statuses (Closed Won → DELIVERED, Partial Ship → PARTIAL, etc.)

### Overall Confidence Score: 97.8%
