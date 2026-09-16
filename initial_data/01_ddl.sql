-- =============================================================================
-- Supply Chain Ontology — DDL
-- Database: SUPPLY_CHAIN_ONTOLOGY | Schema: CORE
-- =============================================================================

CREATE DATABASE IF NOT EXISTS SUPPLY_CHAIN_ONTOLOGY;
CREATE SCHEMA IF NOT EXISTS SUPPLY_CHAIN_ONTOLOGY.CORE;

-- ---------------------------------------------------------------------------
-- Base tables (no foreign key dependencies)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE TABLE SUPPLY_CHAIN_ONTOLOGY.CORE.SUPPLIER (
    SUPPLIER_ID    INTEGER      PRIMARY KEY,
    SUPPLIER_NAME  VARCHAR(200) NOT NULL,
    COUNTRY        VARCHAR(100),
    LEAD_TIME_DAYS INTEGER,
    RATING         VARCHAR(20)
);

CREATE OR REPLACE TABLE SUPPLY_CHAIN_ONTOLOGY.CORE.PLANT (
    PLANT_ID   INTEGER      PRIMARY KEY,
    PLANT_NAME VARCHAR(200) NOT NULL,
    CITY       VARCHAR(100),
    COUNTRY    VARCHAR(100),
    CAPACITY   INTEGER
);

CREATE OR REPLACE TABLE SUPPLY_CHAIN_ONTOLOGY.CORE.CUSTOMER (
    CUSTOMER_ID   INTEGER      PRIMARY KEY,
    CUSTOMER_NAME VARCHAR(200) NOT NULL,
    SEGMENT       VARCHAR(50),
    COUNTRY       VARCHAR(100)
);

-- ---------------------------------------------------------------------------
-- Dependent tables (level 1)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE TABLE SUPPLY_CHAIN_ONTOLOGY.CORE.PART (
    PART_ID         INTEGER        PRIMARY KEY,
    PART_NAME       VARCHAR(200)   NOT NULL,
    CATEGORY        VARCHAR(100),
    UNIT_COST       NUMBER(12,2),
    UNIT_OF_MEASURE VARCHAR(20),
    SUPPLIER_ID     INTEGER        REFERENCES SUPPLY_CHAIN_ONTOLOGY.CORE.SUPPLIER(SUPPLIER_ID)
);

CREATE OR REPLACE TABLE SUPPLY_CHAIN_ONTOLOGY.CORE."ORDER" (
    ORDER_ID               INTEGER     PRIMARY KEY,
    CUSTOMER_ID            INTEGER     REFERENCES SUPPLY_CHAIN_ONTOLOGY.CORE.CUSTOMER(CUSTOMER_ID),
    ORDER_DATE             DATE,
    REQUESTED_DELIVERY_DATE DATE,
    ORDER_STATUS           VARCHAR(20)
);

-- ---------------------------------------------------------------------------
-- Dependent tables (level 2)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE TABLE SUPPLY_CHAIN_ONTOLOGY.CORE.PLANT_INVENTORY (
    PLANT_ID         INTEGER       REFERENCES SUPPLY_CHAIN_ONTOLOGY.CORE.PLANT(PLANT_ID),
    PART_ID          INTEGER       REFERENCES SUPPLY_CHAIN_ONTOLOGY.CORE.PART(PART_ID),
    QUANTITY_ON_HAND INTEGER,
    REORDER_POINT    INTEGER,
    DAILY_USAGE_RATE NUMBER(10,2),
    PRIMARY KEY (PLANT_ID, PART_ID)
);

CREATE OR REPLACE TABLE SUPPLY_CHAIN_ONTOLOGY.CORE.ORDER_LINE (
    ORDER_LINE_ID      INTEGER     PRIMARY KEY,
    ORDER_ID           INTEGER     REFERENCES SUPPLY_CHAIN_ONTOLOGY.CORE."ORDER"(ORDER_ID),
    PART_ID            INTEGER     REFERENCES SUPPLY_CHAIN_ONTOLOGY.CORE.PART(PART_ID),
    QUANTITY_ORDERED   INTEGER,
    QUANTITY_FULFILLED INTEGER,
    LINE_STATUS        VARCHAR(20)
);

-- ---------------------------------------------------------------------------
-- Dependent tables (level 3)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE TABLE SUPPLY_CHAIN_ONTOLOGY.CORE.SHIPMENT (
    SHIPMENT_ID        INTEGER      PRIMARY KEY,
    ORDER_LINE_ID      INTEGER      REFERENCES SUPPLY_CHAIN_ONTOLOGY.CORE.ORDER_LINE(ORDER_LINE_ID),
    PLANT_ID           INTEGER      REFERENCES SUPPLY_CHAIN_ONTOLOGY.CORE.PLANT(PLANT_ID),
    SHIP_DATE          DATE,
    ACTUAL_DELIVERY_DATE DATE,
    QUANTITY_SHIPPED   INTEGER,
    CARRIER            VARCHAR(100)
);
