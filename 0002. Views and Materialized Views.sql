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
