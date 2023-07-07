use role sysadmin;
use schema snowflake_sample_data.tpch_sf1000;

--Clustering information
--------------------------------------------------------------------------------------------------------------------------
-- Using inbuilt system function to understand the cluster information of the table.
select system$clustering_information('LINEITEM');
-- {
--   "cluster_by_keys" : "LINEAR(L_SHIPDATE)",
--   "total_partition_count" : 10336,
--   "total_constant_partition_count" : 8349,       --> higher the value, the better it is for table
--   "average_overlaps" : 0.6908,                   
--   "average_depth" : 1.4082,                      --> lower the value, the better it is for pruning. Ideal scenario is 1, but highly unlikely
--   "partition_depth_histogram" : {
--     "00000" : 0,
--     "00001" : 8310,                              --> This tells that 8310 partitions with average cluster depth of 1
--     "00002" : 599,                               -->                  599 partitions with average cluster depth of 2 etc., 
--     "00003" : 844,
--     "00004" : 417,
--     "00005" : 149,
--     "00006" : 17,
--     "00007" : 0,
--     "00008" : 0,
--     "00009" : 0,
--     "00010" : 0,
--     "00011" : 0,
--     "00012" : 0,
--     "00013" : 0,
--     "00014" : 0,
--     "00015" : 0,
--     "00016" : 0
--   }
-- }

-- Set context
USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE;
USE SCHEMA ACCOUNT_USAGE;

-- Monitoring Automatic Clustering serverless feature costs 
SELECT 
  START_TIME, 
  END_TIME, 
  CREDITS_USED, 
  NUM_BYTES_RECLUSTERED,
  TABLE_NAME, 
  SCHEMA_NAME,
  DATABASE_NAME
FROM AUTOMATIC_CLUSTERING_HISTORY;

show tables like '%line%';

-- clear the cache; generally used to wipe the data for query benchmarking
alter session set use_cached_result = FALSE;

Select * from lineitem limit 50000; --> 01ad69fa-3201-7cb2-0001-4ade0003f036

-- we can see the same result of previous query using query ID like below.
desc result '01ad69fa-3201-7cb2-0001-4ade0003f036';

-- By running multiple select statements with different where conditions by clearing the cache each time and navigating 
-- through query profile, understanding the profile overview ans statistics in each step, we can accurately
-- identify if there is any improvement in the query performance after addition of clusters.
Select * from lineitem where L_SHIPDATE = '1998-12-01' limit 50000;

select * from "SNOWFLAKE_SAMPLE_DATA"."TPCH_SF1000"."LINEITEM" where l_shipdate in ('1998-12-01','1998-09-20') limit 50000;

show tables like 'PARTSUPP'; 
-- Below is an example of incorrect clustering, observe the 'notes' tag in the response
select system$clustering_information('PARTSUPP','ps_suppkey');
-- {
--   "cluster_by_keys" : "LINEAR(PS_SUPPKEY)",
--   "notes" : "Clustering key columns contain high cardinality key PS_SUPPKEY which might result in expensive re-clustering. Consider reducing the cardinality of clustering keys. Please refer to https://docs.snowflake.net/manuals/user-guide/tables-clustering-keys.html for more information.",
--   "total_partition_count" : 2315,
--   "total_constant_partition_count" : 0,
--   "average_overlaps" : 1.8721,
--   "average_depth" : 2.0043,
--   "partition_depth_histogram" : {
--     "00000" : 0,
--     "00001" : 4,
--     "00002" : 2303,
--     "00003" : 2,
--     "00004" : 6,
--     "00005" : 0,
--     "00006" : 0,
--     "00007" : 0,
--     "00008" : 0,
--     "00009" : 0,
--     "00010" : 0,
--     "00011" : 0,
--     "00012" : 0,
--     "00013" : 0,
--     "00014" : 0,
--     "00015" : 0,
--     "00016" : 0
--   }
-- }

--checking for the cardinality of the clustered column
-- It is always advised to check the cardinality of the column that we are planning to cluster by
-- and if there are multiple clustering columns, always include lower cardinality columns first.
select count(1),count(distinct ps_suppkey) from SNOWFLAKE_SAMPLE_DATA.TPCH_SF1000.PARTSUPP; 

--  Get credit usage from automatic reclustering that happens in the background and managed by snowflake ---
use role accountadmin;
select * 
from table(
        snowflake.information_schema.automatic_clustering_history
        (
            date_range_start=>dateadd(h, -12, current_timestamp)
        )
        );
-- Disable automatic re-clustering ---
alter table LINEITEM suspend recluster;  -
