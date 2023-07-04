-- User stage 

create table vehicle(
  make STRING,
  model STRING,
  year NUMBER,
  Category STRING
 );

-- List user stage: which can be accessed by @~
LIST @~;
-- +------+------+-----+---------------+
-- | name | size | md5 | last_modified |
-- |------+------+-----+---------------|
-- +------+------+-----+---------------+

-- put the local file into user stage 
PUT 'FILE:///C:/Users/DELL/Desktop/vehicles.csv' @~;
-- +--------------+-----------------+-------------+-------------+--------------------+--------------------+----------+---------+
-- | source       | target          | source_size | target_size | source_compression | target_compression | status   | message |
-- |--------------+-----------------+-------------+-------------+--------------------+--------------------+----------+---------|
-- | vehicles.csv | vehicles.csv.gz |       20400 |        4992 | NONE               | GZIP               | UPLOADED |         |
-- +--------------+-----------------+-------------+-------------+--------------------+--------------------+----------+---------+

-- list the user stage 
List @~;
-- +-----------------+------+----------------------------------+------------------------------+
-- | name            | size | md5                              | last_modified                |
-- |-----------------+------+----------------------------------+------------------------------|
-- | vehicles.csv.gz | 4992 | 6675513135755966534f1ac33a7ea567 | Tue, 4 Jul 2023 04:14:57 GMT |
-- +-----------------+------+----------------------------------+------------------------------+

-- create a file format with specific parameters 
create or replace file format CSV_NO_HEADER_BLANK_LINES
   type = 'csv'
   field_delimiter = ','
   field_optionally_enclosed_by = '"'
   skip_header = 0
   skip_blank_lines = true;

-- +-------------------------------------------------------------+
-- | status                                                      |
-- |-------------------------------------------------------------|
-- | File format CSV_NO_HEADER_BLANK_LINES successfully created. |
-- +-------------------------------------------------------------+

--Load data into table using user stage 
copy into VEHICLE
   from @~/vehicles.csv.gz
   file_format = CSV_NO_HEADER_BLANK_LINES;

-- +-----------------+--------+-------------+-------------+-------------+-------------+-------------+------------------+-----------------------+-------------------------+
-- | file            | status | rows_parsed | rows_loaded | error_limit | errors_seen | first_error | first_error_line | first_error_character | first_error_column_name |
-- |-----------------+--------+-------------+-------------+-------------+-------------+-------------+------------------+-----------------------+-------------------------|
-- | vehicles.csv.gz | LOADED |         512 |         500 |           1 |           0 | NULL        |             NULL |                  NULL | NULL                    |
-- +-----------------+--------+-------------+-------------+-------------+-------------+-------------+------------------+-----------------------+-------------------------+   

--Check for the data
select * from vehicle limit 10;

--clean up user storage 
remove @~/vehicles.csv.gz;
-- +-----------------+---------+
-- | name            | result  |
-- |-----------------+---------|
-- | vehicles.csv.gz | removed |
-- +-----------------+---------+

-- confirm the removal 
list @~;
-- +------+------+-----+---------------+
-- | name | size | md5 | last_modified |
-- |------+------+-----+---------------|
-- +------+------+-----+---------------+

-- check the load history: This view does not return the history of data loaded using snowpipe and has only 14 days history 
select SCHEMA_NAME, FILE_NAME, TABLE_NAME, LAST_LOAD_TIME, STATUS, ROW_COUNT, ROW_PARSED from information_schema.load_history where table_name = 'VEHICLE';
-- +-------------+--------------------------------+------------+-------------------------------+--------+-----------+------------+
-- | SCHEMA_NAME | FILE_NAME                      | TABLE_NAME | LAST_LOAD_TIME                | STATUS | ROW_COUNT | ROW_PARSED |
-- |-------------+--------------------------------+------------+-------------------------------+--------+-----------+------------|
-- | PUBLIC      | users/21683716/vehicles.csv.gz | VEHICLE    | 2023-07-03 21:22:38.940 -0700 | LOADED |       500 |        512 |
-- +-------------+--------------------------------+------------+-------------------------------+--------+-----------+------------+

-- copy history: This includes data loaded using snowpipe as well.
select 
	FILE_NAME, STAGE_LOCATION, LAST_LOAD_TIME, ROW_COUNT, ROW_PARSED, FILE_SIZE, STATUS, TABLE_CATALOG_NAME, TABLE_SCHEMA_NAME, TABLE_NAME
from table(information_schema.copy_history(TABLE_NAME=>'VEHICLE', START_TIME=> DATEADD(hours, -1, CURRENT_TIMESTAMP())));
-- +-----------------+-----------------+-------------------------------+-----------+------------+-----------+--------+--------------------+-------------------+------------+
-- | FILE_NAME       | STAGE_LOCATION  | LAST_LOAD_TIME                | ROW_COUNT | ROW_PARSED | FILE_SIZE | STATUS | TABLE_CATALOG_NAME | TABLE_SCHEMA_NAME | TABLE_NAME |
-- |-----------------+-----------------+-------------------------------+-----------+------------+-----------+--------+--------------------+-------------------+------------|
-- | vehicles.csv.gz | users/21683716/ | 2023-07-03 21:22:38.940 -0700 |       500 |        512 |      4992 | Loaded | DEMO_DATA_LOADING  | PUBLIC            | VEHICLE    |
-- +-----------------+-----------------+-------------------------------+-----------+------------+-----------+--------+--------------------+-------------------+------------+

