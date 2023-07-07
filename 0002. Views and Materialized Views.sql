-- Views and Materialized views 

create or replace database temp_db;

create view Urgent_priority_orders 
as select * from snowflake_sample_data.tpch_sf10.orders where o_orderpriority = '1-URGENT';

show views like 'Urgent_priority_orders';

select * from Urgent_priority_orders limit 10;

-- secure view 
-- some internal optimizations will be turned off when we create views as secure i.e., pushdown
create secure view URGENT_PRIORITY_ORDERS_secure 
as select * from snowflake_sample_data.tpch_sf10.orders where o_orderpriority = '1-URGENT';

-- the 'is_secure' column should be true 
show views like 'Urgent_priority_orders_secure';

-- materialized view 
-- It is good practice to have aggregations in the Materialized view as the data is persisted in the disk and refreshed.
-- We cannot have joins in materialized views
create or replace materialized view vw_aggregated_orders as 
    select 
        count(1) as total_orders,
        O_ORDERSTATUS as order_status,
        O_ORDERDATE as order_date
    from 
       SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.ORDERS
    where 
        o_orderpriority= '1-URGENT'
    group by
        2, 3;

-- column 'is_materialized' should be true 
show views like 'vw_aggregated_orders';

-- more info about Materialized view like cluster by, rows, refresh details can be found by below
show materialized views like 'vw_aggregated_orders'; 

alter Materialized view vw_aggregated_orders cluster by(order_date);

-- columns 'cluster by' should have order_date populated and 'automatic_clustering' is ON
show materialized views like 'vw_aggregated_orders'; 

-- secure materialized Views
create or replace secure materialized view vw_aggregated_orders_secure as 
    select 
        count(1) as total_orders,
        O_ORDERSTATUS as order_status,
        O_ORDERDATE as order_date
    from 
       SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.ORDERS
    where 
        o_orderpriority= '1-URGENT'
    group by
        2, 3;

show views like 'vw_aggregated_orders_secure';

show Materialized views like 'vw_aggregated_orders_secure';

show views;
-- SELECT "name", "database_name", "schema_name", "is_secure", "is_materialized" FROM TABLE(result_scan(last_query_id()));
-- +-------------------------------+---------------+-------------+-----------+-----------------+
-- | name                          | database_name | schema_name | is_secure | is_materialized |
-- |-------------------------------+---------------+-------------+-----------+-----------------|
-- | URGENT_PRIORITY_ORDERS        | TEMP_DB       | PUBLIC      | false     | false           |
-- | URGENT_PRIORITY_ORDERS_SECURE | TEMP_DB       | PUBLIC      | true      | false           |
-- | VW_AGGREGATED_ORDERS          | TEMP_DB       | PUBLIC      | false     | true            |
-- | VW_AGGREGATED_ORDERS_SECURE   | TEMP_DB       | PUBLIC      | true      | true            |
-- +-------------------------------+---------------+-------------+-----------+-----------------+

-- create role to test the secure view functionality
use role securityadmin;
create role custom_role;
grant usage on database temp_db to role custom_role;

use role sysadmin;
grant select, references on table URGENT_PRIORITY_ORDERS to role custom_role;
grant select, references on table URGENT_PRIORITY_ORDERS_SECURE to role custom_role;
grant select, references on table VW_AGGREGATED_ORDERS to role custom_role;
grant select, references on table VW_AGGREGATED_ORDERS_SECURE to role custom_role;

show grants to role custom_role;
-- +-------------------------------+------------+-------------------+----------------------------------------------+------------+--------------+--------------+------------+
-- | created_on                    | privilege  | granted_on        | name                                         | granted_to | grantee_name | grant_option | granted_by |
-- |-------------------------------+------------+-------------------+----------------------------------------------+------------+--------------+--------------+------------|
-- | 2023-07-05 16:40:05.251 -0700 | USAGE      | DATABASE          | TEMP_DB                                      | ROLE       | CUSTOM_ROLE  | false        | SYSADMIN   |
-- | 2023-07-05 16:41:47.048 -0700 | REFERENCES | MATERIALIZED_VIEW | TEMP_DB.PUBLIC.VW_AGGREGATED_ORDERS          | ROLE       | CUSTOM_ROLE  | false        | SYSADMIN   |
-- | 2023-07-05 16:41:47.038 -0700 | SELECT     | MATERIALIZED_VIEW | TEMP_DB.PUBLIC.VW_AGGREGATED_ORDERS          | ROLE       | CUSTOM_ROLE  | false        | SYSADMIN   |
-- | 2023-07-05 16:41:58.114 -0700 | REFERENCES | MATERIALIZED_VIEW | TEMP_DB.PUBLIC.VW_AGGREGATED_ORDERS_SECURE   | ROLE       | CUSTOM_ROLE  | false        | SYSADMIN   |
-- | 2023-07-05 16:41:58.104 -0700 | SELECT     | MATERIALIZED_VIEW | TEMP_DB.PUBLIC.VW_AGGREGATED_ORDERS_SECURE   | ROLE       | CUSTOM_ROLE  | false        | SYSADMIN   |
-- | 2023-07-05 16:41:11.505 -0700 | REFERENCES | VIEW              | TEMP_DB.PUBLIC.URGENT_PRIORITY_ORDERS        | ROLE       | CUSTOM_ROLE  | false        | SYSADMIN   |
-- | 2023-07-05 16:41:11.492 -0700 | SELECT     | VIEW              | TEMP_DB.PUBLIC.URGENT_PRIORITY_ORDERS        | ROLE       | CUSTOM_ROLE  | false        | SYSADMIN   |
-- | 2023-07-05 16:41:34.829 -0700 | REFERENCES | VIEW              | TEMP_DB.PUBLIC.URGENT_PRIORITY_ORDERS_SECURE | ROLE       | CUSTOM_ROLE  | false        | SYSADMIN   |
-- | 2023-07-05 16:41:34.816 -0700 | SELECT     | VIEW              | TEMP_DB.PUBLIC.URGENT_PRIORITY_ORDERS_SECURE | ROLE       | CUSTOM_ROLE  | false        | SYSADMIN   |
-- +-------------------------------+------------+-------------------+----------------------------------------------+------------+--------------+--------------+------------+

use role accountadmin;
use database snowflake;
use schema account_usage;
Select * from materialized_view_refresh_history;

use role sysadmin;
use temp_db;
alter materialized view VW_AGGREGATED_ORDERS suspend;
alter materialized view VW_AGGREGATED_ORDERS resume;