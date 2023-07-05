use role sysadmin;
use warehouse My_6XL_WH;
create or replace database test_db_so;
create or replace schema test_schema;
use schema test_db_so.test_schema;

create or replace table lineitem_no_so as select * from SNOWFLAKE_SAMPLE_DATA.TPCH_SF1000.LINEITEM;
create or replace table lineitem_so as select * from SNOWFLAKE_SAMPLE_DATA.TPCH_SF1000.LINEITEM;


select system$ESTIMATE_SEARCH_OPTIMIZATION_COSTS('lineitem_so');
-- {
--   "tableName" : "LINEITEM_SO",
--   "searchOptimizationEnabled" : false,
--   "costPositions" : [ {
--     "name" : "BuildCosts",
--     "costs" : {
--       "value" : 16.133878,
--       "unit" : "Credits"
--     },
--     "computationMethod" : "Estimated",
--     "comment" : "estimated via sampling"
--   }, {
--     "name" : "StorageCosts",
--     "costs" : {
--       "value" : 0.145807,
--       "unit" : "TB",
--       "perTimeUnit" : "MONTH"
--     },
--     "computationMethod" : "Estimated",
--     "comment" : "estimated via sampling"
--   }, {
--     "name" : "MaintenanceCosts",
--     "computationMethod" : "NotAvailable",
--     "comment" : "Insufficient data to compute estimate for maintenance cost. Table is too young. Requires 7 day(s) of history."
--   } ]
-- }

alter table lineitem_so add search optimization;
--observe the column search_optimization, it should be ON and the search_optimization_progress should be 100
show tables like 'lineitem_so';

ALTER SESSION SET USE_CACHED_RESULT = FALSE;
Select * from lineitem_no_so where l_orderkey='2412266214' limit 10; 
-- Warehouse 'MY_6XL_WH' cannot be resumed because resource monitor '{1}' has exceeded its quota

use warehouse my_first_vw;
ALTER SESSION SET USE_CACHED_RESULT = FALSE;
Select * from lineitem_no_so where l_orderkey='2412266214' limit 10; 
-- Query Profile 
-- time taken : 42s, Bytes scanned : 24.65GB
-- Partitions scanned : 9477, Partitions total : 9477

ALTER SESSION SET USE_CACHED_RESULT = FALSE;
-- Run this after the search_optimization is complete, i.e., search_optimization_progress is set to 100.
Select * from lineitem_so where l_orderkey='2412266214' limit 10; 

alter warehouse my_first_vw suspend;

drop database test_db_so;