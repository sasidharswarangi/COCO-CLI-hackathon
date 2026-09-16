# Target Schema Reference

This file documents the canonical entity model for quick reference during mapping.
The skill reads the actual schema from `INFORMATION_SCHEMA` at runtime — this is
for human review and for the agent to understand entity semantics.

## Entity Hierarchy (load order)

```
Level 0:  SUPPLIER    PLANT    CUSTOMER
              │          │         │
Level 1:    PART       "ORDER"────┘
              │    ┌─────┤
Level 2: PLANT_INVENTORY  ORDER_LINE
                             │
Level 3:                  SHIPMENT───── PLANT
```

## Entity Definitions

### SUPPLIER — A vendor that furnishes parts
- `SUPPLIER_ID` (PK, INTEGER) — surrogate key
- `SUPPLIER_NAME` (VARCHAR) — legal entity name
- `COUNTRY` (VARCHAR) — country of incorporation
- `LEAD_TIME_DAYS` (INTEGER) — standard lead time in calendar days
- `RATING` (VARCHAR) — internal tier: GOLD, SILVER, BRONZE

### PART — A component or material
- `PART_ID` (PK, INTEGER) — surrogate key
- `PART_NAME` (VARCHAR) — descriptive name
- `CATEGORY` (VARCHAR) — product family: Raw Material, Electronics, Mechanical
- `UNIT_COST` (NUMBER 12,2) — standard cost per unit
- `UNIT_OF_MEASURE` (VARCHAR) — EACH, KG, LITER
- `SUPPLIER_ID` (FK → SUPPLIER) — primary supplier

### PLANT — A facility that stores parts and ships orders
- `PLANT_ID` (PK, INTEGER) — surrogate key
- `PLANT_NAME` (VARCHAR) — facility name
- `CITY` (VARCHAR)
- `COUNTRY` (VARCHAR)
- `CAPACITY` (INTEGER) — max units storable

### CUSTOMER — An entity that places orders
- `CUSTOMER_ID` (PK, INTEGER) — surrogate key
- `CUSTOMER_NAME` (VARCHAR)
- `SEGMENT` (VARCHAR) — ENTERPRISE, SMB, GOVERNMENT
- `COUNTRY` (VARCHAR)

### ORDER — A purchase order from a customer
- `ORDER_ID` (PK, INTEGER) — surrogate key
- `CUSTOMER_ID` (FK → CUSTOMER)
- `ORDER_DATE` (DATE) — date the order was placed
- `REQUESTED_DELIVERY_DATE` (DATE) — customer-requested delivery
- `ORDER_STATUS` (VARCHAR) — OPEN, SHIPPED, DELIVERED, CANCELLED

### ORDER_LINE — A single line item within an order
- `ORDER_LINE_ID` (PK, INTEGER) — surrogate key
- `ORDER_ID` (FK → ORDER)
- `PART_ID` (FK → PART)
- `QUANTITY_ORDERED` (INTEGER) — units requested
- `QUANTITY_FULFILLED` (INTEGER) — units actually shipped
- `LINE_STATUS` (VARCHAR) — PENDING, FULFILLED, PARTIAL, CANCELLED

### PLANT_INVENTORY — Stock position for a part at a plant
- `PLANT_ID` (PK, FK → PLANT)
- `PART_ID` (PK, FK → PART)
- `QUANTITY_ON_HAND` (INTEGER) — current stock level
- `REORDER_POINT` (INTEGER) — replenishment threshold
- `DAILY_USAGE_RATE` (NUMBER 10,2) — average daily consumption

### SHIPMENT — A physical movement of goods
- `SHIPMENT_ID` (PK, INTEGER) — surrogate key
- `ORDER_LINE_ID` (FK → ORDER_LINE) — line being fulfilled
- `PLANT_ID` (FK → PLANT) — originating plant
- `SHIP_DATE` (DATE) — date left the plant
- `ACTUAL_DELIVERY_DATE` (DATE) — date arrived (NULL if in transit)
- `QUANTITY_SHIPPED` (INTEGER) — units in this shipment
- `CARRIER` (VARCHAR) — logistics provider

## Common Synonyms (mapping hints)

| Canonical Column | Common Raw Variants |
|-----------------|-------------------|
| SUPPLIER_NAME | vendor_name, supp_name, supplier_nm, vendor, company |
| PART_NAME | item_name, component, product_name, material, sku_desc |
| PLANT_NAME | facility, warehouse, location_name, site, plant |
| CUSTOMER_NAME | buyer, client, account_name, cust_name |
| ORDER_DATE | po_date, purchase_date, order_dt, created_date |
| QUANTITY_ORDERED | qty_ordered, order_qty, qty, quantity |
| QUANTITY_FULFILLED | qty_shipped, qty_filled, shipped_qty |
| UNIT_COST | price, cost, unit_price, std_cost |
| CARRIER | shipper, logistics_provider, freight_carrier |
