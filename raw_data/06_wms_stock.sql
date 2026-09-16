-- =============================================================================
-- WMS Stock Levels — messy inventory feed
-- Problems: comma-formatted quantities, mixed date formats, orphan warehouse,
--           duplicate snapshots
-- =============================================================================

CREATE OR REPLACE TABLE SUPPLY_CHAIN_ONTOLOGY.RAW.WMS_STOCK_LEVELS (
    WAREHOUSE_CODE VARCHAR(20),
    WAREHOUSE_NAME VARCHAR(200),
    SKU VARCHAR(50),
    QTY_ON_HAND VARCHAR(30),
    REORDER_QTY VARCHAR(30),
    AVG_DAILY_CONSUMPTION VARCHAR(30),
    SNAPSHOT_DATE VARCHAR(50)
);

INSERT INTO SUPPLY_CHAIN_ONTOLOGY.RAW.WMS_STOCK_LEVELS VALUES
    -- Detroit Assembly (F01)
    ('F01', 'Detroit Assembly Plant', 'P-101', '2500',  '500',  '85.0',   '2025-05-01'),
    ('F01', 'Detroit Assembly Plant', 'P-103', '800',   '200',  '28.5',   '2025-05-01'),
    ('F01', 'Detroit Assembly Plant', 'P-105', '300',   '100',  '12.0',   '2025-05-01'),
    ('F01', 'Detroit Assembly Plant', 'P-109', '600',   '150',  '22.0',   '2025-05-01'),
    -- Austin Warehouse (F02)
    ('F02', 'Austin TX Warehouse',    'P-102', '450',   '100',  '18.0',   '05/01/2025'),
    ('F02', 'Austin TX Warehouse',    'P-104', '1,200', '300',  '45.0',   '05/01/2025'),
    ('F02', 'Austin TX Warehouse',    'P-106', '1800',  '400',  '60.0',   '05/01/2025'),
    ('F02', 'Austin TX Warehouse',    'P-108', '350',   '80',   '15.0',   '05/01/2025'),
    -- Frankfurt Hub (F03)
    ('F03', 'Frankfurt Hub',          'P-103', '1100',  '250',  '35.0',   '01-May-2025'),
    ('F03', 'Frankfurt Hub',          'P-105', '200',   '80',   '8.5',    '01-May-2025'),
    ('F03', 'Frankfurt Hub',          'P-107', '180',   '50',   '6.0',    '01-May-2025'),
    ('F03', 'Frankfurt Hub',          'P-110', '250',   '70',   '9.0',    '01-May-2025'),
    -- Pune Distribution (F04)
    ('F04', 'Pune Dist. Center',      'P-101', '3,000', '600',  '95.0',   '2025/05/01'),
    ('F04', 'Pune Dist. Center',      'P-102', '600',   '150',  '20.0',   '2025/05/01'),
    ('F04', 'Pune Dist. Center',      'P-104', '900',   '200',  '32.0',   '2025/05/01'),
    ('F04', 'Pune Dist. Center',      'P-108', '500',   '100',  '18.5',   '2025/05/01'),
    -- Orphan warehouse
    ('F99', 'Ghost Warehouse',        'P-101', '100',   '50',   '5.0',    '2025-05-01'),
    -- Duplicate snapshot
    ('F01', 'Detroit Assembly',        'P-101', '2500',  '500',  '85.0',   '20250501');
