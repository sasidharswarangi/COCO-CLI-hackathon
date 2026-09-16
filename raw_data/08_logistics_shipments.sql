-- =============================================================================
-- Logistics Shipments — messy 3PL shipment feed
-- Problems: empty string vs NULL delivery dates, carrier name variations,
--           facility name variations, orphan PO ref, duplicate tracking
-- =============================================================================

CREATE OR REPLACE TABLE SUPPLY_CHAIN_ONTOLOGY.RAW.LOGISTICS_SHIPMENTS (
    TRACKING_NO VARCHAR(50),
    PO_REF VARCHAR(50),
    PO_LINE VARCHAR(20),
    ORIGIN_FACILITY VARCHAR(200),
    ORIGIN_FAC_CODE VARCHAR(20),
    SHIP_DT VARCHAR(50),
    DELIVERY_DT VARCHAR(50),
    QTY VARCHAR(30),
    FREIGHT_CARRIER VARCHAR(200)
);

INSERT INTO SUPPLY_CHAIN_ONTOLOGY.RAW.LOGISTICS_SHIPMENTS VALUES
    -- Order 1001 shipments (on time)
    ('TRK-00001', 'OPP-1001', '1', 'Detroit Assembly Plant',  'F01', '2025-01-10', '01/18/2025', '500', 'FedEx Freight'),
    ('TRK-00002', 'OPP-1001', '2', 'Detroit Assembly Plant',  'F01', '2025-01-10', '01/19/2025', '200', 'FedEx Freight'),
    -- Order 1002 shipments
    ('TRK-00003', 'OPP-1002', '1', 'Austin TX Warehouse',     'F02', '01/20/2025', '2025-01-28', '120', 'UPS Supply Chain'),
    ('TRK-00004', 'OPP-1002', '2', 'Austin TX Warehouse',     'F02', '01/20/2025', '2025-01-29', '300', 'UPS Supply Chain'),
    -- Order 1003 shipments (on time)
    ('TRK-00005', 'OPP-1003', '1', 'Frankfurt Hub',           'F03', '2025-02-08', '17-Feb-2025','80',  'DHL Global'),
    ('TRK-00006', 'OPP-1003', '2', 'Frankfurt Hub',           'F03', '2025-02-08', '18-Feb-2025','40',  'DHL Global'),
    -- Order 1004 (line 2 LATE)
    ('TRK-00007', 'OPP-1004', '1', 'Austin Warehouse',        'F02', '2025-02-22', '03/03/2025', '250', 'XPO Logistics'),
    ('TRK-00008', 'OPP-1004', '2', 'Austin Warehouse',        'F02', '2025-02-22', '03/08/2025', '75',  'XPO Logistics'),
    -- Order 1005 (on time)
    ('TRK-00009', 'OPP-1005', '1', 'Detroit Assembly',        'F01', '2025-03-05', '2025-03-13', '120', 'FedEx Freight'),
    ('TRK-00010', 'OPP-1005', '2', 'Detroit Assembly',        'F01', '2025-03-05', '2025-03-14', '60',  'FEDEX FREIGHT'),
    -- Order 1006 (split shipment on line 2, one in transit)
    ('TRK-00011', 'OPP-1006', '1', 'Pune Dist. Center',       'F04', '2025-03-15', '2025-03-26', '400', 'Maersk'),
    ('TRK-00012', 'OPP-1006', '2', 'Pune Dist. Center',       'F04', '2025-03-15', '2025-03-30', '100', 'Maersk'),
    ('TRK-00013', 'OPP-1006', '2', 'Frankfurt Hub',           'F03', '2025-03-18', '',           '50',  'DHL Global'),
    -- Order 1007 (in transit)
    ('TRK-00014', 'OPP-1007', '1', 'Pune Distribution',       'F04', '04/05/2025', NULL,         '200', 'MAERSK'),
    ('TRK-00015', 'OPP-1007', '2', 'Frankfurt Hub',           'F03', '04/05/2025', NULL,         '50',  'DHL'),
    -- Orphan: references a PO that doesn't exist
    ('TRK-99999', 'OPP-7777', '1', 'Ghost Facility',          'F99', '2025-06-01', '2025-06-05', '999', 'Unknown Carrier'),
    -- Duplicate tracking number
    ('TRK-00001', 'OPP-1001', '1', 'DETROIT ASSEMBLY PLANT',  'F01', '2025-01-10', '2025-01-18', '500', 'Fedex Freight');
