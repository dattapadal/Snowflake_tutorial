create or replace table flights_temp (
    rj variant
);

create or replace stage flights_json_stg
    url = 's3://snowpro-core-study-guide/dataloading/json/'
    file_format = (type =json);

list @flights_json_stg;

select $1 from @flights_json_stg;

copy into flights_temp
from @flights_json_stg;

select * from flights_temp;

--we can parse the root tags, but not the nested tags i.e., flights tag values
Select 
    rj:data_set::STRING, 
    rj:provide_date::DATE,
    rj:provided_by::STRING, 
    rj:world_wide::boolean
from 
    flights_temp;

Select 
    rj:data_set::STRING, 
    rj:provide_date::DATE,
    rj:provided_by::STRING, 
    rj:world_wide::boolean,
    value
from 
    flights_temp, lateral flatten(input => rj:flights);

Select 
    rj:data_set::STRING, 
    rj:provide_date::DATE,
    rj:provided_by::STRING, 
    rj:world_wide::boolean,
    value:airline::String,
    value:origin.airport::String as orig_airport,
    value:origin.city::String as orig_city,
    value:destination.airport::String as dest_airport,
    value:destination.city::String as dest_city
from 
    flights_temp, lateral flatten(input => rj:flights);            
