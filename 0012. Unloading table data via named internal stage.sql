create or replace file format EXPORT_TSV_WITH_HEADERS
    type = 'CSV'
    field_delimiter = '\t'
    file_extension = '.csv';

create or replace stage export_stg
    file_format=EXPORT_TSV_WITH_HEADERS;

list @export_stg;

copy into @export_stg
from customer;

list @export_stg;

