use role sysadmin;
use database snowflake_sample_data;
use schema tpch_sf1000;

SELECT C_CUSTKEY, C_NAME, C_ADDRESS, C_ACCTBAL FROM CUSTOMER 
ORDER BY C_ACCTBAL DESC
LIMIT 10000;

-- Account usage view (365 days of query history)
USE ROLE ACCOUNTADMIN;
-- Set context 
USE DATABASE SNOWFLAKE;
USE SCHEMA ACCOUNT_USAGE;
SELECT * FROM QUERY_HISTORY WHERE WAREHOUSE_SIZE IS NOT NULL LIMIT 100;

-- Ten longest running queries in seconds
SELECT 
  QUERY_ID, 
  QUERY_TEXT, 
  USER_NAME, 
  ROLE_NAME,
  EXECUTION_STATUS, 
  ROUND(TOTAL_ELAPSED_TIME / 1000,2) AS TOTAL_ELAPSED_TIME_SEC   
FROM QUERY_HISTORY
WHERE TOTAL_ELAPSED_TIME_SEC > 3
ORDER BY TOTAL_ELAPSED_TIME_SEC DESC
LIMIT 10;

-- Create temporary database for access to Information Schema
CREATE DATABASE DEMO_DB;
USE SCHEMA "DEMO_DB"."INFORMATION_SCHEMA";

-- Ten longest running queries in seconds. This will be realtime but has only history of last 7 days unlike the query_history from account schema which has 365 days history 
-- but with upto 45 minutes of latency. 
SELECT 
  QUERY_ID, 
  QUERY_TEXT, 
  USER_NAME, 
  ROLE_NAME,
  EXECUTION_STATUS, 
  ROUND(TOTAL_ELAPSED_TIME / 1000,2) AS TOTAL_ELAPSED_TIME_SEC   
FROM table(information_schema.query_history())
WHERE TOTAL_ELAPSED_TIME_SEC > 3
ORDER BY TOTAL_ELAPSED_TIME_SEC DESC
LIMIT 10;

-- Clear-down resources 
DROP DATABASE DEMO_DB;