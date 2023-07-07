-- Virtual Warehouse creation
--                   sizes
--                   state properties
--                   behaviour

use role sysadmin;

create warehouse data_analysis_warehouse
warehouse_size = 'SMALL'
auto_suspend = 600 -- in seconds 
auto_resume = TRUE 
initially_suspended = TRUE; -- by default warehouse gets started as soon as its created, we can turn off that using this paramater. 

--set context
use warehouse data_analysis_warehouse;
use schema snowflake_sample_data.tpch_sf1000;

-- show state of virtyal warehouse 
show warehouses;
SELECT 
"name", "state", "type", "size", "min_cluster_count", "max_cluster_count",  "running", "queued", "is_default", "auto_suspend", "auto_resume", "scaling_policy"
FROM TABLE(result_scan(last_query_id()));
-- +-------------------------+-----------+----------+---------+-------------------+-------------------+---------+--------+------------+--------------+-------------+----------------+
-- | name                    | state     | type     | size    | min_cluster_count | max_cluster_count | running | queued | is_default | auto_suspend | auto_resume | scaling_policy |
-- |-------------------------+-----------+----------+---------+-------------------+-------------------+---------+--------+------------+--------------+-------------+----------------|
-- | COMPUTE_WH              | SUSPENDED | STANDARD | X-Small |                 1 |                 1 |       0 |      0 | Y          |          600 | true        | STANDARD       |
-- | DATA_ANALYSIS_WAREHOUSE | SUSPENDED | STANDARD | Small   |                 1 |                 1 |       0 |      0 | N          |          600 | true        | STANDARD       |
-- +-------------------------+-----------+----------+---------+-------------------+-------------------+---------+--------+------------+--------------+-------------+----------------+

alter warehouse data_analysis_warehouse resume;

-- manually suspend a warehouse
alter warehouse data_analysis_warehouse suspend;

-- alter the configurations on the fly 
alter warehouse data_analysis_warehouse set warehouse_size = 'LARGE';
alter warehouse data_analysis_warehouse set auto_suspend = 300;

alter warehouse data_analysis_warehouse set auto_resume = FALSE;
-- +-------------------------+-----------+----------+---------+-------------------+-------------------+---------+--------+------------+--------------+-------------+----------------+
-- | name                    | state     | type     | size    | min_cluster_count | max_cluster_count | running | queued | is_default | auto_suspend | auto_resume | scaling_policy |
-- |-------------------------+-----------+----------+---------+-------------------+-------------------+---------+--------+------------+--------------+-------------+----------------|
-- | COMPUTE_WH              | SUSPENDED | STANDARD | X-Small |                 1 |                 1 |       0 |      0 | Y          |          600 | true        | STANDARD       |
-- | DATA_ANALYSIS_WAREHOUSE | SUSPENDED | STANDARD | Large   |                 1 |                 1 |       0 |      0 | N          |          300 | false       | STANDARD       |
-- +-------------------------+-----------+----------+---------+-------------------+-------------------+---------+--------+------------+--------------+-------------+----------------+
-- Clear-down resources
DROP WAREHOUSE DATA_ANALYSIS_WAREHOUSE;