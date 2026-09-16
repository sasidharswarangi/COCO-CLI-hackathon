# Prompt 01 — Ontology Design & Metric Definitions

## Context
Designed the full supply chain data ontology — entity model, attributes, relationships, and three canonical metric definitions. No SQL/DDL was written at this stage; this was pure design review.

## Prompt
```
I'm building a "Supply Chain Ontology and Governed Conversational Analytics" 
project on Snowflake. I need you to:

1. Create a new database called SUPPLY_CHAIN_ONTOLOGY with a schema called CORE.

2. Help me draft a supply chain data ontology covering these entities and their 
relationships:
   - SUPPLIER (has many PARTs)
   - PART (supplied by SUPPLIER, used in orders, stocked at PLANT)
   - PLANT (stores PARTs, originates SHIPMENTs)
   - SHIPMENT (moves PARTs from PLANT to fulfill an ORDER)
   - ORDER (placed by CUSTOMER, contains order lines referencing PART)
   - CUSTOMER (places ORDERs)

For each entity, propose: primary key, key attributes, and its relationships 
to other entities (cardinality: one-to-many, many-to-many, etc).

3. Then propose precise, unambiguous definitions for these three canonical 
metrics, including the exact grain (order line vs order vs shipment) and 
formula for each:
   - On-time delivery rate
   - Fill rate
   - Days of inventory

Don't write any SQL or DDL yet — just give me the entity model and the metric 
definitions in plain text/markdown so I can review them first.
```

## Outcome
- Created database `SUPPLY_CHAIN_ONTOLOGY` and schema `CORE`
- Designed 8 entities: SUPPLIER, PART, PLANT, PLANT_INVENTORY (bridge), CUSTOMER, ORDER, ORDER_LINE, SHIPMENT
- Defined 3 canonical metrics with grain, formula, exclusions, and edge cases
- Added PLANT_INVENTORY as a bridge table (not in original request) to model the many-to-many between PLANT and PART
- Added ORDER_LINE (not in original request) to properly model order granularity for fill rate measurement
