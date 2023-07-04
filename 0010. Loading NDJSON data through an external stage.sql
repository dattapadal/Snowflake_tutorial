create or replace table employee_temp (
    rj variant
);

create or replace stage employee_ndjson_stg
    url = 's3://snowpro-core-study-guide/dataloading/ndjson/'
    file_format = (type = 'JSON');

list @employee_ndjson_stg;

select * from  @employee_ndjson_stg limit 10;

copy into employee_temp
from @employee_ndjson_stg;

select rj from employee_temp limit 10;

--notice the values enclosed in double quotes as it is still in variant format
SELECT rj:ssn, rj:dob, rj:email, rj:first_name, rj:last_name,
rj:city, rj:phone, rj:job
FROM employee_temp;

--convert fields from variant format to individual data types
select 
    $1:ssn::STRING,
    $1:dob::DATE, 
    $1:email::STRING, 
    $1:first_name::STRING, 
    $1:last_name::STRING, 
    $1:city::STRING, 
    $1:phone::STRING, 
    $1:job::STRING
from employee_temp;

-- The above select query can be used to load the temp data from employee_temp to original employee data or 
-- we can built view over above select query.
