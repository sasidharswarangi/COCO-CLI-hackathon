-- =============================================================================
-- Facility List — messy plant/warehouse feed
-- Problems: comma-formatted capacity, combined city+state, Y/N/Yes flags, dupes
-- =============================================================================

CREATE OR REPLACE TABLE SUPPLY_CHAIN_ONTOLOGY.RAW.FACILITY_LIST (
    FAC_ID VARCHAR(20),
    FAC_NAME VARCHAR(200),
    CITY_STATE VARCHAR(200),
    CNTRY_CODE VARCHAR(50),
    MAX_CAPACITY VARCHAR(50),
    ACTIVE_FLAG VARCHAR(10)
);

INSERT INTO SUPPLY_CHAIN_ONTOLOGY.RAW.FACILITY_LIST VALUES
    ('F01', 'Detroit Assembly Plant',  'Detroit, MI',    'US',  '50000',  'Y'),
    ('F02', 'Austin TX Warehouse',     'Austin, TX',     'US',  '30,000', 'Y'),
    ('F03', 'Frankfurt Hub',           'Frankfurt',      'DE',  '40000',  'Y'),
    ('F04', 'Pune Dist. Center',       'Pune, MH',       'IN',  '25000',  'Y'),
    -- Duplicate with different name
    ('F01A','Detroit Assembly',         'Detroit',        'USA', '50000',  'Yes'),
    -- Inactive plant
    ('F05', 'Legacy Chicago Depot',    'Chicago, IL',    'US',  '15000',  'N'),
    -- Junk
    ('',    'TBD',                     NULL,             NULL,  NULL,     NULL);
