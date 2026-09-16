-- =============================================================================
-- Salesforce Orders — messy orders + order lines feed (combined table)
-- Problems: merged order+line, mixed date formats, status naming mismatch,
--           orphan account, duplicate lines
-- =============================================================================

CREATE OR REPLACE TABLE SUPPLY_CHAIN_ONTOLOGY.RAW.SALESFORCE_ORDERS (
    SF_OPPORTUNITY_ID VARCHAR(50),
    ACCOUNT_REF VARCHAR(50),
    ACCOUNT_NM VARCHAR(300),
    PO_DATE VARCHAR(50),
    REQUESTED_SHIP_DT VARCHAR(50),
    STATUS VARCHAR(50),
    LINE_NO NUMBER,
    PRODUCT_SKU VARCHAR(50),
    PRODUCT_NAME VARCHAR(300),
    QTY NUMBER,
    QTY_SHIPPED NUMBER,
    LINE_STAT VARCHAR(50)
);

INSERT INTO SUPPLY_CHAIN_ONTOLOGY.RAW.SALESFORCE_ORDERS VALUES
    -- Order 1001 lines
    ('OPP-1001', 'A-1001', 'Acme Manufacturing Inc.', '2025-01-05', '01/20/2025', 'Closed Won',  1, 'P-101', 'Steel Plate A',       500, 500, 'Shipped'),
    ('OPP-1001', 'A-1001', 'Acme Manufacturing Inc.', '2025-01-05', '01/20/2025', 'Closed Won',  2, 'P-103', 'Precision Bearing',   200, 200, 'Shipped'),
    -- Order 1002 lines (partial)
    ('OPP-1002', 'A-1002', 'TechBuild Solutions',     '01/12/2025', '2025-01-30', 'Closed Won',  1, 'P-102', 'Circuit Board X1',    150, 120, 'Partial Ship'),
    ('OPP-1002', 'A-1002', 'TechBuild Solutions',     '01/12/2025', '2025-01-30', 'Closed Won',  2, 'P-106', 'Copper Wire Spool',   300, 300, 'Shipped'),
    -- Order 1003
    ('OPP-1003', 'A-1003', 'Federal Transit Agency',  '2025-02-01', '02/20/2025', 'Closed Won',  1, 'P-105', 'Drive Shaft Assy',    80,  80,  'Shipped'),
    ('OPP-1003', 'A-1003', 'Federal Transit Agency',  '2025-02-01', '02/20/2025', 'Closed Won',  2, 'P-107', 'Hydraulic Pump',      40,  40,  'Shipped'),
    -- Order 1004 (one line late)
    ('OPP-1004', 'A-1004', 'EuroAuto GmbH',           '15-Feb-2025','2025-03-05', 'Closed Won',  1, 'P-104', 'LED Panel 12V',       250, 250, 'Shipped'),
    ('OPP-1004', 'A-1004', 'EuroAuto GmbH',           '15-Feb-2025','2025-03-05', 'Closed Won',  2, 'P-108', 'Sensor Module V2',    100, 75,  'Partial Ship'),
    -- Order 1005
    ('OPP-1005', 'A-1001', 'Acme Manufacturing',      '2025-03-01', '03/15/2025', 'Closed Won',  1, 'P-109', 'Aluminum Frame',      120, 120, 'Shipped'),
    ('OPP-1005', 'A-1001', 'Acme Manufacturing',      '2025-03-01', '03/15/2025', 'Closed Won',  2, 'P-110', 'Gearbox Unit',        60,  60,  'Shipped'),
    -- Order 1006 (in transit)
    ('OPP-1006', 'A-1005', 'QuickFix Repairs',        '2025-03-10', '2025-03-28', 'In Progress', 1, 'P-101', 'Steel Plate A',       400, 400, 'Shipped'),
    ('OPP-1006', 'A-1005', 'QuickFix Repairs',        '2025-03-10', '2025-03-28', 'In Progress', 2, 'P-103', 'Precision Bearing',   180, 150, 'Partial Ship'),
    -- Order 1007 (in transit)
    ('OPP-1007', 'A-1006', 'Hyderabad Rail Corp',     '04/01/2025', '2025-04-18', 'In Progress', 1, 'P-102', 'Circuit Board X1',    200, 200, 'Shipped'),
    ('OPP-1007', 'A-1006', 'Hyderabad Rail Corp',     '04/01/2025', '2025-04-18', 'In Progress', 2, 'P-105', 'Drive Shaft Assembly', 50,  50,  'Shipped'),
    -- Order 1008 (open)
    ('OPP-1008', 'A-1002', 'TechBuild Solutions',     '2025-04-10', '04/25/2025', 'Open',        1, 'P-106', 'Copper Wire Spool',   250, 0,   'Pending'),
    ('OPP-1008', 'A-1002', 'TechBuild Solutions',     '2025-04-10', '04/25/2025', 'Open',        2, 'P-104', 'LED Panel 12V',       100, 0,   'Pending'),
    -- Order 1009 (open)
    ('OPP-1009', 'A-1003', 'Fed Transit Agency',      '05/01/2025', '2025-05-15', 'Open',        1, 'P-107', 'Hydraulic Pump',      30,  0,   'Pending'),
    ('OPP-1009', 'A-1003', 'Fed Transit Agency',      '05/01/2025', '2025-05-15', 'Open',        2, 'P-110', 'Gearbox Unit',        45,  0,   'Pending'),
    -- Order 1010 (one cancelled)
    ('OPP-1010', 'A-1004', 'EuroAuto GmbH',           '2025-05-10', '2025-05-30', 'Open',        1, 'P-109', 'Aluminum Frame',      90,  0,   'Pending'),
    ('OPP-1010', 'A-1004', 'EuroAuto GmbH',           '2025-05-10', '2025-05-30', 'Open',        2, 'P-108', 'Sensor Module V2',    60,  0,   'Cancelled'),
    -- Orphan: references unknown account
    ('OPP-9999', 'A-8888', 'Unknown Corp',            '2025-06-01', '2025-06-15', 'Open',        1, 'P-101', 'Steel Plate A',       100, 0,   'Pending'),
    -- Duplicate order line
    ('OPP-1001', 'A-1001', 'ACME MANUFACTURING INC',  '2025-01-05', '01/20/2025', 'Closed Won',  1, 'P-101', 'Steel Plate A',       500, 500, 'Complete');
