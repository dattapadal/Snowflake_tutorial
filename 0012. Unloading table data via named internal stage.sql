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



-- Unloading the data directly to cloud storage, using storage integration 
show integrations;
desc integration AWS_SF_ITG;

-- Extract/Unload data  ---
copy into s3://datta-snowflake-data/unloaded_data/lineitem/
from
(
  select * from LINEITEM limit 100000
)
storage_integration=aws_sf_itg
single=false
file_format = csv_load_format;

-- Extract/Unload data using partition by 
copy into s3://datta-snowflake-data/unloaded_data/lineitem/
from
(
  select * from LINEITEM limit 100000
)
partition by L_SHIPDATE
storage_integration=aws_sf_itg
single=false
file_format = csv_load_format;

-- Unloading using parquet format
copy into s3://datta-snowflake-data/unloaded_data/lineitem/
from
(
  select * from LINEITEM limit 100000
)
storage_integration=aws_sf_itg
single=false
file_format = parquet_load_format;

-- Unloading using OBJECT_CONSTRUCT in JSON format
copy into s3://datta-snowflake-data/unloaded_data/lineitem_json/
from
(
  select 
  object_construct(
                'L_ORDERKEY',L_ORDERKEY,
                'L_PARTKEY',L_PARTKEY,
                'L_SUPPKEY',L_SUPPKEY,
                'L_LINENUMBER',L_LINENUMBER,
                'L_QUANTITY',L_QUANTITY,
                'L_EXTENDEDPRICE',L_EXTENDEDPRICE,
                'L_DISCOUNT',L_DISCOUNT,
                'L_TAX',L_TAX,
                'L_RETURNFLAG',L_RETURNFLAG,
                'L_LINESTATUS',L_LINESTATUS,
                'L_SHIPDATE',L_SHIPDATE,
                'L_COMMITDATE',L_COMMITDATE,
                'L_RECEIPTDATE',L_RECEIPTDATE,
                'L_SHIPINSTRUCT',L_SHIPINSTRUCT,
                'L_SHIPMODE',L_SHIPMODE,
                'L_COMMENT',L_COMMENT
  )
  from LINEITEM
  limit 1000000
)
storage_integration=aws_sf_stg
single=false
file_format = json_load_format;
