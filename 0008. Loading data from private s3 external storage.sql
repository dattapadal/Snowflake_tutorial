-- We can easily create an external stage from publicly shared cloud storage links, 
-- however, that is rarely the case in production environments.
-- most of the times, we will be processing privately shared data within company infrasture

-- Below are the steps to load data from AWS S3 storage with specific roles and access. 
-- 1. Create an IAM Role for snowflake to access data in S3 buckets 
--      Role --> Create Role --> AWS Account (require external ID with random placeholders for now)
--           --> Add permissions (S3 Readonly access) --> Role name --> create role 
-- 2. Create S3 bucket in AWS and upoad sample files to the bucket
-- 3. Create an integration object in Snowflake for authentication (Use AccountAdmin role)
-- 4. Create a file format object  (using sysadmin/custom role)
-- 5. Create a stage object referencing the location from which the data needs to be ingested 
-- 6. Load the data into snowflake tables using COPY INTO FROM

--Step 3: Create a storage integration object 
use role accountadmin;
Create or replace storage integration aws_sf_itg
    type = EXTERNAL_STAGE
    STORAGE_PROVIDER = S3
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::897213760800:role/snowflake_role'
    STORAGE_ALLOWED_LOCATIONS = ('s3://dattasnowpropractice/');

grant usage on integration aws_sf_itg to role sysadmin;

use role sysadmin;

-- copy ROW#5 STORAGE_AWS_IAM_USER_ARN value and go to AWS Roles --> Trust Relationships --> 
--  EDIT Trust policy --> replace the AWS value under principal with the above copied value
-- copy ROW#7 STORAGE_AWS_EXTERNAL_ID and add it to the external ID in the edit trust policy
desc integration aws_sf_itg;

--create stage 
create or replace stage prospect_stg
    storage_integration = aws_sf_itg
    url = 's3://dattasnowpropractice/prospects/'
    file_format = (type='CSV'  field_delimiter=',' field_optionally_enclosed_by='"', skip_header=0); 

list @prospect_stg;

create or replace table prospects(
    first_name STRING,
    last_name STRING,
    email STRING,
    phone STRING,
    acquired_date_time DATETIME, 
    city STRING,
    ssn STRING,
    job STRING
);

-- read content from stage 
select $1, $2, $3, $4, $5, $6, $7, $8 from @prospect_stg limit 10;

--copy data into table 
copy into prospects
from @prospect_stg
on_error = ABORT_STATEMENT;

select * from prospects limit 10;

select * from information_schema.load_history where table_name='PROSPECTS' order by last_load_time desc limit 10; 
select *
from table(
        information_schema.copy_history(
            table_name => 'prospects',
            start_time => dateadd(hours, -1, current_timestamp())
        )
    );