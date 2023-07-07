-- Different types of database tables in snowflake 
use role sysadmin;
use warehouse compute_wh;

create or replace database temp_db;
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
create or replace temporary table orders_tmp 
as select * from SNOWFLAKE_SAMPLE_DATA.TPCH_SF10.ORDERS limit 50;

-- transient table
create transient table tran_customer 
as select * from snowflake_sample_data.tpch_sf10.customer limit 50;

--permanent table
create or replace table nations_perm 
as select * from snowflake_sample_data.tpch_sf10.nation limit 50;

show tables; -- showing only few selected columns from the result query
-- +---------------+---------------+-------------+-----------+-------------+----------------+
-- | name          | database_name | schema_name | kind      | is_external | retention_time |
-- |---------------+---------------+-------------+-----------+-------------+----------------|
-- | NATIONS_PERM  | TEMP_DB       | PUBLIC      | TABLE     | N           | 1              |
-- | ORDERS_TMP    | TEMP_DB       | PUBLIC      | TEMPORARY | N           | 1              |
-- | TRAN_CUSTOMER | TEMP_DB       | PUBLIC      | TRANSIENT | N           | 1              |
-- +---------------+---------------+-------------+-----------+-------------+----------------+


alter table nations_perm set data_retention_time_in_days = 90; -- success
-- +---------------+---------------+-------------+-----------+-------------+----------------+
-- | name          | database_name | schema_name | kind      | is_external | retention_time |
-- |---------------+---------------+-------------+-----------+-------------+----------------|
-- | NATIONS_PERM  | TEMP_DB       | PUBLIC      | TABLE     | N           | 90             |
-- +---------------+---------------+-------------+-----------+-------------+----------------+

 -- SQL Compilation error -> Invalid value [2] for parameter 'DATA_RETENTION_TIME_IN_DAYS'
alter table ORDERS_TMP set data_retention_time_in_days = 2;

 -- SQL Compilation error -> Invalid value [2] for parameter 'DATA_RETENTION_TIME_IN_DAYS'
alter table TRAN_CUSTOMER set data_retention_time_in_days = 2;


-- transient schema; all the tables created in this schema are by default transient tables.
create or replace transient schema tran_schema;

-- transient database; all the schemas and tables created in this database are by default transient 
create or replace transient database tran_db;

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

-- Create external table - just the syntax for now.
CREATE EXTERNAL TABLE EXT_TABLE
(
 	
  col1 varchar as (value:col1::varchar),
  col2 varchar as (value:col2::int)
  col3 varchar as (value:col3::varchar)

)
LOCATION=@s1/logs/
FILE_FORMAT = (type = parquet);

-- Refresh external table metadata so it reflects latest changes in external cloud storage
ALTER EXTERNAL TABLE EXT_TABLE REFRESH;

drop database temp_db;
drop database tran_db;