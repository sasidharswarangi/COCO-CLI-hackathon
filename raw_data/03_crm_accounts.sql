-- =============================================================================
-- CRM Accounts — messy customer feed
-- Problems: segment inconsistencies, duplicates, inactive records
-- =============================================================================

CREATE OR REPLACE TABLE SUPPLY_CHAIN_ONTOLOGY.RAW.CRM_ACCOUNTS (
    ACCT_ID VARCHAR(30),
    ACCOUNT_NAME VARCHAR(300),
    ACCT_TYPE VARCHAR(100),
    BILLING_COUNTRY VARCHAR(100),
    CREATED_DT VARCHAR(50),
    IS_ACTIVE NUMBER(1)
);

INSERT INTO SUPPLY_CHAIN_ONTOLOGY.RAW.CRM_ACCOUNTS VALUES
    ('A-1001', 'Acme Manufacturing Inc.',   'Enterprise',     'United States', '2020-03-15', 1),
    ('A-1002', 'TechBuild Solutions',       'Small Business', 'Canada',        '2021-06-22', 1),
    ('A-1003', 'Federal Transit Agency',    'Govt',           'US',            '2019-01-10', 1),
    ('A-1004', 'EuroAuto GmbH',            'enterprise',     'Germany',       '2022-04-05', 1),
    ('A-1005', 'QuickFix Repairs Ltd',     'SMB',            'UK',            '2023-02-18', 1),
    ('A-1006', 'Hyderabad Rail Corp',      'GOVERNMENT',     'India',         '2021-11-30', 1),
    -- Duplicates
    ('A-1001B','Acme Manufacturing',        'Ent.',           'USA',           '2020-03-15', 1),
    ('A-1003B','Fed Transit Agency',        'Government',     'United States', '2019-01-10', 1),
    -- New customer not in canonical
    ('A-1007', 'Pacific Rim Logistics',     'Enterprise',     'Australia',     '2024-08-12', 1),
    -- Inactive (churned)
    ('A-9999', 'Old Corp Defunct',          'Enterprise',     'US',            '2015-01-01', 0);
