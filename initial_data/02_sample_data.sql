-- =============================================================================
-- Supply Chain Ontology — Sample Data
-- Run after 01_ddl.sql
-- =============================================================================

-- ---------------------------------------------------------------------------
-- SUPPLIER (5 rows)
-- ---------------------------------------------------------------------------
INSERT INTO SUPPLY_CHAIN_ONTOLOGY.CORE.SUPPLIER VALUES
    (1, 'Apex Steel Corp',        'USA',     7,  'GOLD'),
    (2, 'Shanghai Components',    'China',   21, 'SILVER'),
    (3, 'Bavaria Precision GmbH', 'Germany', 14, 'GOLD'),
    (4, 'Mumbai Electronics',     'India',   18, 'BRONZE'),
    (5, 'Osaka Motors Ltd',       'Japan',   10, 'SILVER');

-- ---------------------------------------------------------------------------
-- PLANT (4 rows)
-- ---------------------------------------------------------------------------
INSERT INTO SUPPLY_CHAIN_ONTOLOGY.CORE.PLANT VALUES
    (1, 'Detroit Assembly',  'Detroit',   'USA',     50000),
    (2, 'Austin Warehouse',  'Austin',    'USA',     30000),
    (3, 'Frankfurt Hub',     'Frankfurt', 'Germany', 40000),
    (4, 'Pune Distribution', 'Pune',      'India',   25000);

-- ---------------------------------------------------------------------------
-- PART (10 rows)
-- ---------------------------------------------------------------------------
INSERT INTO SUPPLY_CHAIN_ONTOLOGY.CORE.PART VALUES
    (101, 'Steel Plate A',        'Raw Material', 45.00,  'KG',   1),
    (102, 'Circuit Board X1',     'Electronics',  120.50, 'EACH', 2),
    (103, 'Precision Bearing',    'Mechanical',   32.75,  'EACH', 3),
    (104, 'LED Panel 12V',        'Electronics',  78.00,  'EACH', 4),
    (105, 'Drive Shaft Assembly', 'Mechanical',   215.00, 'EACH', 5),
    (106, 'Copper Wire Spool',    'Raw Material', 55.20,  'KG',   2),
    (107, 'Hydraulic Pump',       'Mechanical',   340.00, 'EACH', 3),
    (108, 'Sensor Module V2',     'Electronics',  95.00,  'EACH', 4),
    (109, 'Aluminum Frame',       'Raw Material', 88.50,  'EACH', 1),
    (110, 'Gearbox Unit',         'Mechanical',   410.00, 'EACH', 5);

-- ---------------------------------------------------------------------------
-- CUSTOMER (6 rows)
-- ---------------------------------------------------------------------------
INSERT INTO SUPPLY_CHAIN_ONTOLOGY.CORE.CUSTOMER VALUES
    (1, 'Acme Manufacturing',     'ENTERPRISE',  'USA'),
    (2, 'TechBuild Solutions',    'SMB',         'Canada'),
    (3, 'Federal Transit Agency', 'GOVERNMENT',  'USA'),
    (4, 'EuroAuto GmbH',          'ENTERPRISE',  'Germany'),
    (5, 'QuickFix Repairs',       'SMB',         'UK'),
    (6, 'Hyderabad Rail Corp',    'GOVERNMENT',  'India');

-- ---------------------------------------------------------------------------
-- ORDER (10 rows — Jan to May 2025)
-- ---------------------------------------------------------------------------
INSERT INTO SUPPLY_CHAIN_ONTOLOGY.CORE."ORDER" VALUES
    (1001, 1, '2025-01-05', '2025-01-20', 'DELIVERED'),
    (1002, 2, '2025-01-12', '2025-01-30', 'DELIVERED'),
    (1003, 3, '2025-02-01', '2025-02-20', 'DELIVERED'),
    (1004, 4, '2025-02-15', '2025-03-05', 'DELIVERED'),
    (1005, 1, '2025-03-01', '2025-03-15', 'DELIVERED'),
    (1006, 5, '2025-03-10', '2025-03-28', 'SHIPPED'),
    (1007, 6, '2025-04-01', '2025-04-18', 'SHIPPED'),
    (1008, 2, '2025-04-10', '2025-04-25', 'OPEN'),
    (1009, 3, '2025-05-01', '2025-05-15', 'OPEN'),
    (1010, 4, '2025-05-10', '2025-05-30', 'OPEN');

-- ---------------------------------------------------------------------------
-- ORDER_LINE (20 rows — varied fulfillment statuses)
-- ---------------------------------------------------------------------------
INSERT INTO SUPPLY_CHAIN_ONTOLOGY.CORE.ORDER_LINE VALUES
    -- Order 1001: fully fulfilled
    (1,  1001, 101, 500, 500, 'FULFILLED'),
    (2,  1001, 103, 200, 200, 'FULFILLED'),
    -- Order 1002: partial fill on line 3
    (3,  1002, 102, 150, 120, 'PARTIAL'),
    (4,  1002, 106, 300, 300, 'FULFILLED'),
    -- Order 1003: fully fulfilled
    (5,  1003, 105, 80,  80,  'FULFILLED'),
    (6,  1003, 107, 40,  40,  'FULFILLED'),
    -- Order 1004: line 8 short-shipped
    (7,  1004, 104, 250, 250, 'FULFILLED'),
    (8,  1004, 108, 100, 75,  'PARTIAL'),
    -- Order 1005: fully fulfilled
    (9,  1005, 109, 120, 120, 'FULFILLED'),
    (10, 1005, 110, 60,  60,  'FULFILLED'),
    -- Order 1006: in transit, line 12 partial
    (11, 1006, 101, 400, 400, 'FULFILLED'),
    (12, 1006, 103, 180, 150, 'PARTIAL'),
    -- Order 1007: in transit
    (13, 1007, 102, 200, 200, 'FULFILLED'),
    (14, 1007, 105, 50,  50,  'FULFILLED'),
    -- Order 1008: pending (not yet shipped)
    (15, 1008, 106, 250, 0,   'PENDING'),
    (16, 1008, 104, 100, 0,   'PENDING'),
    -- Order 1009: pending
    (17, 1009, 107, 30,  0,   'PENDING'),
    (18, 1009, 110, 45,  0,   'PENDING'),
    -- Order 1010: one pending, one cancelled
    (19, 1010, 109, 90,  0,   'PENDING'),
    (20, 1010, 108, 60,  0,   'CANCELLED');

-- ---------------------------------------------------------------------------
-- PLANT_INVENTORY (16 rows — 4 parts per plant)
-- ---------------------------------------------------------------------------
INSERT INTO SUPPLY_CHAIN_ONTOLOGY.CORE.PLANT_INVENTORY VALUES
    -- Detroit Assembly (Plant 1)
    (1, 101, 2500, 500,  85.00),
    (1, 103, 800,  200,  28.50),
    (1, 105, 300,  100,  12.00),
    (1, 109, 600,  150,  22.00),
    -- Austin Warehouse (Plant 2)
    (2, 102, 450,  100,  18.00),
    (2, 104, 1200, 300,  45.00),
    (2, 106, 1800, 400,  60.00),
    (2, 108, 350,  80,   15.00),
    -- Frankfurt Hub (Plant 3)
    (3, 103, 1100, 250,  35.00),
    (3, 105, 200,  80,   8.50),
    (3, 107, 180,  50,   6.00),
    (3, 110, 250,  70,   9.00),
    -- Pune Distribution (Plant 4)
    (4, 101, 3000, 600,  95.00),
    (4, 102, 600,  150,  20.00),
    (4, 104, 900,  200,  32.00),
    (4, 108, 500,  100,  18.50);

-- ---------------------------------------------------------------------------
-- SHIPMENT (15 rows — on-time, late, in-transit, split)
-- ---------------------------------------------------------------------------
INSERT INTO SUPPLY_CHAIN_ONTOLOGY.CORE.SHIPMENT VALUES
    -- Order 1001 (requested 2025-01-20) — both on time
    (1,  1,  1, '2025-01-10', '2025-01-18', 500, 'FedEx Freight'),
    (2,  2,  1, '2025-01-10', '2025-01-19', 200, 'FedEx Freight'),
    -- Order 1002 (requested 2025-01-30) — on time
    (3,  3,  2, '2025-01-20', '2025-01-28', 120, 'UPS Supply Chain'),
    (4,  4,  2, '2025-01-20', '2025-01-29', 300, 'UPS Supply Chain'),
    -- Order 1003 (requested 2025-02-20) — on time
    (5,  5,  3, '2025-02-08', '2025-02-17', 80,  'DHL Global'),
    (6,  6,  3, '2025-02-08', '2025-02-18', 40,  'DHL Global'),
    -- Order 1004 (requested 2025-03-05) — line 7 on time, line 8 LATE
    (7,  7,  2, '2025-02-22', '2025-03-03', 250, 'XPO Logistics'),
    (8,  8,  2, '2025-02-22', '2025-03-08', 75,  'XPO Logistics'),
    -- Order 1005 (requested 2025-03-15) — on time
    (9,  9,  1, '2025-03-05', '2025-03-13', 120, 'FedEx Freight'),
    (10, 10, 1, '2025-03-05', '2025-03-14', 60,  'FedEx Freight'),
    -- Order 1006 (requested 2025-03-28) — line 12 split, one late, one in transit
    (11, 11, 4, '2025-03-15', '2025-03-26', 400, 'Maersk'),
    (12, 12, 4, '2025-03-15', '2025-03-30', 100, 'Maersk'),
    (13, 12, 3, '2025-03-18', NULL,          50,  'DHL Global'),
    -- Order 1007 — in transit (no delivery date yet)
    (14, 13, 4, '2025-04-05', NULL,          200, 'Maersk'),
    (15, 14, 3, '2025-04-05', NULL,          50,  'DHL Global');
