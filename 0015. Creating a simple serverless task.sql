-- Creating a simple serveless task 

create table order_count (
    snapshot_time TIMESTAMP,
    total_orders NUMBER
);

-- Task query
Select 
    current_timestamp() as snapshot_time, 
    count(*) as total_orders 
from 
    snowflake_sample_data.tpch_sf1.orders 
group by 1;

use role accountadmin;
grant EXECUTE MANAGED TASK on account to role sysadmin; 

use role sysadmin;

--create a serverless task 
create or replace task generate_order_count
user_task_managed_initial_warehouse_size = 'XSMALL'
schedule='1 minute'
As
Insert into test_tasks.public.order_count
Select 
    current_timestamp() as snapshot_time, 
    count(*) as total_orders 
from 
    snowflake_sample_data.tpch_sf1.orders 
group by 1;

alter task generate_order_count resume;

show tasks;

SELECT name, state,
completed_time, scheduled_time,
error_code, error_message
FROM TABLE(information_schema.task_history());

Select * from order_count;

alter task generate_order_count suspend;