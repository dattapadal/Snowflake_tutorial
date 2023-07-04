--create a stage 
create or replace stage customer_stg
    url = 's3://snowpro-core-study-guide/dataloading/external/';

list @customer_stg;

create or replace external table customer_external
    with location = @customer_stg
    file_format = (type='CSV' field_delimiter='|' skip_header=1);

-- observe the data in key value pairs 
select * from customer_external limit 10;

Select 
    $1:c1 as Name, $1:c2 as SSN, $1:c3 as emailAddress, 
    $1:c4 as Address, $1:c5 as Zip, $1:c6 as Location, 
    $1:c7 as Country 
from customer_external;

--Instead of querying table like above, we can change the external_table definition to include the column details
CREATE OR REPLACE EXTERNAL TABLE customer_external
(
    Name STRING as (value:c1::STRING),
    Phone STRING as(value:c2::STRING),
    Email STRING as(value:c3::STRING),
    Address STRING as(value:c4::STRING),
    PostalCode STRING as(value:c5::STRING),
    City STRING as(value:c6::STRING),
    Country STRING as(value:c7::STRING)
) WITH location =@customer_stg
file_format = (type = CSV field_delimiter = '|' skip_header = 1);

select * from customer_external limit 10;

--query performance on external table can be improved by creating materialized view on the external cable and refreshing it periodically
