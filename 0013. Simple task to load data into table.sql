use role sysadmin;
create or replace database test_tasks;

-- create a customer_report table which contains total order price for each customer 
create or replace table customer_report (
    customer_name STRING, 
    total_price NUMBER
);

--task query
Select 
    c.c_name as customer_name, sum(o.o_totalprice) as totall_price
from 
    snowflake_sample_data.tpch_sf10.customer c join 
    snowflake_sample_data.tpch_sf10.orders o 
    on c.c_custkey = o.o_custkey
group by 
    c.c_name;

create task generate_customer_report
warehouse = 'MY_FIRST_VW'
schedule = '5 Minute' 
as
insert into customer_report 
Select 
    c.c_name as customer_name, sum(o.o_totalprice) as totall_price
from 
    snowflake_sample_data.tpch_sf10.customer c join 
    snowflake_sample_data.tpch_sf10.orders o 
    on c.c_custkey = o.o_custkey
group by 
    c.c_name;

show tasks;

--by default tasks will be in suspended status, hence we need to resume them after creation
alter task generate_customer_report resume;

--check for the task execution status in task_history table 
SELECT name, state,
completed_time, scheduled_time,
error_code, error_message
FROM TABLE(information_schema.task_history())
WHERE name = 'GENERATE_CUSTOMER_REPORT';

-- suspend task not to overload as it is practice only.
alter task generate_customer_report suspend;

Select * from customer_report;