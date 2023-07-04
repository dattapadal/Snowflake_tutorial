-- loading data from external stage
create table prospects(
    first_name STRING, 
    last_name STRING,
    email STRING,
    phone STRING,
    acquired_date_time DATETIME, 
    city STRING,
    ssn STRING,
    job STRING
);

-- create an external named storage using publicly shared s3 file
create or replace stage prospects_stage
    url = 's3://snowpro-core-study-guide/dataloading/prospects/'
    file_format = (type='CSV' field_delimiter=',' field_optionally_enclosed_by='"' skip_header=0);

list @prospects_stage;

copy into prospects
from @prospects_stage;

select SCHEMA_NAME, FILE_NAME, TABLE_NAME, LAST_LOAD_TIME, STATUS, ROW_COUNT, ROW_PARSED from information_schema.load_history where table_name = 'PROSPECTS';
select 
	FILE_NAME, STAGE_LOCATION, LAST_LOAD_TIME, ROW_COUNT, ROW_PARSED, FILE_SIZE, STATUS, TABLE_CATALOG_NAME, TABLE_SCHEMA_NAME, TABLE_NAME
from table(information_schema.copy_history(TABLE_NAME=>'PROSPECTS', START_TIME=> DATEADD(hours, -1, CURRENT_TIMESTAMP())));