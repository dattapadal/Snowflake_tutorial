-- Different types of database tables in snowflake 
use role sysadmin;
use warehouse compute_wh;

--+-----------+--------------------------+------------------+-----------------------------------------------------------------------------------------------------+-------------+
--|    Type   |        Persistence       | Fail-Safe Period |                                          Time Travel Period                                         |   Workload  |
--+-----------+--------------------------+------------------+-----------------------------------------------------------------------------------------------------+-------------+
--| Temporary | Remainder of session     | 0                | 0 or 1 (default is 1)                                                                               | OLAP        |
--+-----------+--------------------------+------------------+-----------------------------------------------------------------------------------------------------+-------------+
--| Transient | Until explicitly dropped | 0                | 0 or 1 (default is 1)                                                                               | OLAP        |
--+-----------+--------------------------+------------------+-----------------------------------------------------------------------------------------------------+-------------+
--| Permanent | Until explicitly dropped | 7                | 0 or 1 (default is 1) - Standard Edition   OR  0 to 90 (default is configurable) Enterprise Edition | OLAP        |
--+-----------+--------------------------+------------------+-----------------------------------------------------------------------------------------------------+-------------+
--| Hybrid    | Until explicitly dropped | TBD              | TBD                                                                                                 | OLAP + OLTP |
--+-----------+--------------------------+------------------+-----------------------------------------------------------------------------------------------------+-------------+

-- temporary table 
create or replace temporary table as orders_tmp 
as select * from SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.ORDERS limit 50;


-- transient table
create transient table tran_customer 
as select * from snowflake_sample_data.tpch_sf10.customer limit 50;

-- transient schema; all the tables created in this schema are by default transient tables.
create transient schema tran_schema;

-- transient database; all the schemas and tables created in this database are by default transient 
create transient database tran_db;

-- convert permanent table to transient table; 
-- there is no direct way to convert a table from permanent to transient,
-- below are the steps involved.
use database temp_db;

create table perm_cust 
as select * from snowflake_sample_data.tpch_sf10.customer limit 50;

--copy data from permanent table into transient table 
create transient table trans_cust 
as select * from temp_db.public.perm_cust;

-- drop the permanent table
drop table perm_cust;

-- rename the temporary table
alter table trans_cust rename to perm_table;

--check for the 'kind' column in the show tables result
show tables like 'perm_table';
