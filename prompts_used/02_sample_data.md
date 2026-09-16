# Prompt 02 — Sample Data Creation

## Context
After reviewing and approving the ontology design, created all 8 tables with DDL and populated them with realistic sample data that exercises all three canonical metrics.

## Prompt
```
this looks good, lets create a sample invetory data
```

## Outcome
- Created all 8 tables with proper FK constraints in dependency order
- Loaded sample data:
  - 5 suppliers (USA, China, Germany, India, Japan)
  - 4 plants (Detroit, Austin, Frankfurt, Pune)
  - 10 parts across 3 categories
  - 6 customers across 3 segments
  - 10 orders (Jan–May 2025)
  - 20 order lines (mix of FULFILLED, PARTIAL, PENDING, CANCELLED)
  - 16 plant-inventory positions
  - 15 shipments (on-time, late, in-transit, split)
- Data deliberately includes edge cases: partial fills, late deliveries, NULL delivery dates, split shipments, cancelled lines
