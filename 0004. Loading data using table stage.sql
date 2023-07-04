-- stages 

--initial set up 
use role sysadmin;
create or replace database demo_data_loading;
use database demo_data_loading;

create or replace table customer (
    name STRING, 
    phone STRING,
    email STRING,
    address STRING,
    postalcode STRING,
    region STRING,
    country STRING
);

--Table stage 
-- each stage has its own table stage created by default, which we can query using LIST @%<table_name>

--it will be empty for the first time and hence there wont be any results. 
List @%customer;

--using SNOWSQL we can put the file into table stage with below command 
PUT 'FILE:///C:/path/to/your/file/customers.csv' @%customer;
-- +---------------+------------------+-------------+-------------+--------------------+--------------------+----------+---------+
-- | source        | target           | source_size | target_size | source_compression | target_compression | status   | message |
-- |---------------+------------------+-------------+-------------+--------------------+--------------------+----------+---------|
-- | customers.csv | customers.csv.gz |       10941 |        6192 | NONE               | GZIP               | UPLOADED |         |
-- +---------------+------------------+-------------+-------------+--------------------+--------------------+----------+---------+
-- 1 Row(s) produced. Time Elapsed: 1.715s

-- check for the list of files in table stage
List @%customer;
-- +------------------+------+----------------------------------+------------------------------+
-- | name             | size | md5                              | last_modified                |
-- |------------------+------+----------------------------------+------------------------------|
-- | customers.csv.gz | 6192 | 2f3baff00f0d146c82c7ef47b26eeff9 | Tue, 4 Jul 2023 03:40:44 GMT |
-- +------------------+------+----------------------------------+------------------------------+

--Load the data from table stage into table 
COPY INTO customer
FROM  @%customer
file_format = (type=csv field_delimiter='|' skip_header=1);
-- +------------------+--------+-------------+-------------+-------------+-------------+-------------+------------------+-----------------------+-------------------------+
-- | file             | status | rows_parsed | rows_loaded | error_limit | errors_seen | first_error | first_error_line | first_error_character | first_error_column_name |
-- |------------------+--------+-------------+-------------+-------------+-------------+-------------+------------------+-----------------------+-------------------------|
-- | customers.csv.gz | LOADED |         100 |         100 |           1 |           0 | NULL        |             NULL |                  NULL | NULL                    |
-- +------------------+--------+-------------+-------------+-------------+-------------+-------------+------------------+-----------------------+-------------------------+

-- check if the data has been loaded 
select * from CUSTOMER limit 10;

-- Now the data has been loaded, clear the stage files using below command 
remove @%customer;
-- +------------------+---------+
-- | name             | result  |
-- |------------------+---------|
-- | customers.csv.gz | removed |
-- +------------------+---------+

-- Confirm the removals 
list @%customer;
-- +------+------+-----+---------------+
-- | name | size | md5 | last_modified |
-- |------+------+-----+---------------|
-- +------+------+-----+---------------+
-- 0 Row(s) produced. Time Elapsed: 0.141s

-- check the load history: This view does not return the history of data loaded using snowpipe and has only 14 days history 
select SCHEMA_NAME, FILE_NAME, TABLE_NAME, LAST_LOAD_TIME, STATUS, ROW_COUNT, ROW_PARSED from information_schema.load_history where table_name = 'CUSTOMER';
-- +-------------+-----------------------------------------+------------+-------------------------------+--------+-----------+------------+
-- | SCHEMA_NAME | FILE_NAME                               | TABLE_NAME | LAST_LOAD_TIME                | STATUS | ROW_COUNT | ROW_PARSED |
-- |-------------+-----------------------------------------+------------+-------------------------------+--------+-----------+------------|
-- | PUBLIC      | tables/363792319995914/customers.csv.gz | CUSTOMER   | 2023-07-03 20:45:43.428 -0700 | LOADED |       100 |        100 |
-- +-------------+-----------------------------------------+------------+-------------------------------+--------+-----------+------------+

-- copy history: This includes data loaded using snowpipe as well.
select 
	FILE_NAME, STAGE_LOCATION, LAST_LOAD_TIME, ROW_COUNT, ROW_PARSED, FILE_SIZE, STATUS, TABLE_CATALOG_NAME, TABLE_SCHEMA_NAME, TABLE_NAME
from table(information_schema.copy_history(TABLE_NAME=>'CUSTOMER', START_TIME=> DATEADD(hours, -1, CURRENT_TIMESTAMP())));
-- +------------------+-------------------------+-------------------------------+-----------+------------+-----------+--------+--------------------+-------------------+------------+
-- | FILE_NAME        | STAGE_LOCATION          | LAST_LOAD_TIME                | ROW_COUNT | ROW_PARSED | FILE_SIZE | STATUS | TABLE_CATALOG_NAME | TABLE_SCHEMA_NAME | TABLE_NAME |
-- |------------------+-------------------------+-------------------------------+-----------+------------+-----------+--------+--------------------+-------------------+------------|
-- | customers.csv.gz | tables/363792319995914/ | 2023-07-03 20:45:43.428 -0700 |       100 |        100 |      6192 | Loaded | DEMO_DATA_LOADING  | PUBLIC            | CUSTOMER   |
-- +------------------+-------------------------+-------------------------------+-----------+------------+-----------+--------+--------------------+-------------------+------------+

