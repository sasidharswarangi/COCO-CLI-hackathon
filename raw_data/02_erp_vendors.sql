-- =============================================================================
-- ERP Vendor Master — messy supplier feed
-- Problems: duplicates, inconsistent country codes, mixed date formats, junk
-- =============================================================================

CREATE OR REPLACE TABLE SUPPLY_CHAIN_ONTOLOGY.RAW.ERP_VENDORS (
    VENDOR_NO VARCHAR(50),
    VENDOR_NM VARCHAR(300),
    CNTRY VARCHAR(100),
    LT_DAYS VARCHAR(20),
    VENDOR_TIER VARCHAR(50),
    LAST_UPDATED VARCHAR(50)
);

INSERT INTO SUPPLY_CHAIN_ONTOLOGY.RAW.ERP_VENDORS VALUES
    -- Clean records
    ('V001', 'Apex Steel Corp',        'US',       '7',   'Tier 1',  '2025-01-15'),
    ('V002', 'Shanghai Components',    'CN',       '21',  'Tier 2',  '01/20/2025'),
    ('V003', 'Bavaria Precision GmbH', 'DE',       '14',  'Tier 1',  '15-Jan-2025'),
    ('V004', 'Mumbai Electronics',     'IN',       '18',  'Tier 3',  '2025/01/22'),
    ('V005', 'Osaka Motors Ltd',       'JP',       '10',  'Tier 2',  '20250125'),
    -- Duplicates with slight variations
    ('V001A','Apex Steel',             'USA',      '7',   'Gold',    '2025-02-01'),
    ('V001B','APEX STEEL CORP.',       'United States', '7', 'TIER 1', '02/15/2025'),
    ('V003A','Bavaria Precision',      'Germany',  '14',  'tier 1',  '2025-02-10'),
    -- Extra vendor not in canonical (should be new)
    ('V006', 'Nordic Fasteners AB',    'SE',       '12',  'Tier 2',  '2025-03-01'),
    -- Junk / null records
    ('V999', NULL,                     NULL,       NULL,  NULL,      NULL),
    ('',     'TEST VENDOR DO NOT USE', 'XX',       '0',   'Test',    '1900-01-01'),
    -- Country code inconsistency
    ('V002A','Shanghai Components Co', 'China',    '21',  'Silver',  '03-15-2025');
