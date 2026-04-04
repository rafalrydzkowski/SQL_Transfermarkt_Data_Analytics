/*
===============================================================================
Data Warehouse Environment Setup
===============================================================================
Purpose:
    This script initializes the database environment for the Medallion 
    Architecture (Bronze, Silver, Gold). It handles the creation of the 
    core database and the logical separation of layers through schemas.
===============================================================================
*/

-- Fresh environment deployment:

DROP DATABASE IF EXISTS transfermarkt;
CREATE DATABASE transfermarkt;

-- Verify existing non-system schemas:

SELECT schema_name, schema_owner 
FROM information_schema.schemata
WHERE schema_name NOT IN ('information_schema', 'pg_catalog');

-- Initialize Medallion Layering:
-- CASCADE ensures removal of all dependent objects during re-deployment

DROP SCHEMA IF EXISTS bronze CASCADE; CREATE SCHEMA bronze;
DROP SCHEMA IF EXISTS silver CASCADE; CREATE SCHEMA silver;
DROP SCHEMA IF EXISTS gold   CASCADE; CREATE SCHEMA gold;

