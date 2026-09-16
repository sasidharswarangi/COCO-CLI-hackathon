-- =============================================================================
-- Legacy Parts Master — messy parts feed
-- Problems: $ in costs, inconsistent UOM, abbreviated categories, vendor
--           name variations, duplicate parts
-- =============================================================================

CREATE OR REPLACE TABLE SUPPLY_CHAIN_ONTOLOGY.RAW.LEGACY_PARTS_MASTER (
    ITEM_NO VARCHAR(50),
    ITEM_DESC VARCHAR(300),
    PROD_CATEGORY VARCHAR(100),
    STD_COST VARCHAR(50),
    UOM VARCHAR(30),
    PRIMARY_VENDOR VARCHAR(300),
    VENDOR_REF VARCHAR(50)
);

INSERT INTO SUPPLY_CHAIN_ONTOLOGY.RAW.LEGACY_PARTS_MASTER VALUES
    ('P-101', 'Steel Plate A',         'Raw Matl',       '45.00',   'KG',       'Apex Steel Corp',         'V001'),
    ('P-102', 'Circuit Board X1',      'Electronics',    '120.50',  'ea',       'Shanghai Components',     'V002'),
    ('P-103', 'Precision Bearing',     'MECHANICAL',     '32.75',   'Each',     'Bavaria Precision GmbH',  'V003'),
    ('P-104', 'LED Panel 12V',         'Electronics',    '78',      'pcs',      'Mumbai Electronics',      'V004'),
    ('P-105', 'Drive Shaft Assy',      'Mechanical',     '$215.00', 'EACH',     'Osaka Motors Ltd',        'V005'),
    ('P-106', 'Copper Wire Spool',     'Raw Material',   '55.2',    'kgs',      'Shanghai Components',     'V002'),
    ('P-107', 'Hydraulic Pump',        'Mechanical',     '340.00',  'EA',       'Bavaria Precision',       'V003A'),
    ('P-108', 'Sensor Module V2',      'Elect.',         '95.00',   'piece',    'Mumbai Electronics',      'V004'),
    ('P-109', 'Aluminum Frame',        'raw material',   '88.50',   'Each',     'Apex Steel',              'V001A'),
    ('P-110', 'Gearbox Unit',          'MECH',           '410',     'ea',       'Osaka Motors',            'V005'),
    -- Duplicate with slightly different description
    ('P-101A','Steel Plate - Grade A', 'Raw',            '45.00',   'Kilogram', 'APEX STEEL CORP.',        'V001B'),
    -- New part not in canonical
    ('P-111', 'Titanium Bolt M8',      'Fastener',       '2.30',    'ea',       'Nordic Fasteners AB',     'V006'),
    -- Junk record
    ('P-XXX', 'SAMPLE - DELETE',       'TEST',           '0',       '',         'TEST',                    '');
