-- Loading data from named stage

-- create table locations
Create or replace table locations (
    latitude DECIMAL(8,6), 
    longitude DECIMAL(9,6), 
    place STRING, 
    CountryCode STRING, 
    TimeZone STRING
);

--create file format 
create or replace file format TSV_NO_HEADERS
    type = 'CSV'
    field_delimiter = '\t'
    skip_header = 0
    error_on_column_count_mismatch=false;

--create an internal named stage, here we can associated file_format to the stage 
-- which cannot be done when using table or user stages and hence can simply use COPY into 
-- command with no file_format parameter
create or replace stage ETL_Stage 
file_format = TSV_NO_HEADERS;

list @ETL_Stage;

PUT 'FILE:///F:/Snowflake_tutorial/0000. Data/locations.csv' @ETL_Stage;
-- +---------------+------------------+-------------+-------------+--------------------+--------------------+----------+---------+
-- | source        | target           | source_size | target_size | source_compression | target_compression | status   | message |
-- |---------------+------------------+-------------+-------------+--------------------+--------------------+----------+---------|
-- | locations.csv | locations.csv.gz |        7051 |        3296 | NONE               | GZIP               | UPLOADED |         |
-- +---------------+------------------+-------------+-------------+--------------------+--------------------+----------+---------+
-- 1 Row(s) produced. Time Elapsed: 2.543s

List @ETL_Stage;

copy into locations 
from @ETL_Stage;

Select * from locations limit 10;

remove @ETL_Stage;

select SCHEMA_NAME, FILE_NAME, TABLE_NAME, LAST_LOAD_TIME, STATUS, ROW_COUNT, ROW_PARSED from information_schema.load_history where table_name = 'LOCATIONS';

select 
	FILE_NAME, STAGE_LOCATION, LAST_LOAD_TIME, ROW_COUNT, ROW_PARSED, FILE_SIZE, STATUS, TABLE_CATALOG_NAME, TABLE_SCHEMA_NAME, TABLE_NAME
from table(information_schema.copy_history(TABLE_NAME=>'LOCATIONS', START_TIME=> DATEADD(hours, -1, CURRENT_TIMESTAMP())));