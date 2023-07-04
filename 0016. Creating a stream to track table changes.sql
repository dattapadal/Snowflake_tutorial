create or replace database test_streams;

create table customer(
    customer_name string,
    email string, 
    discount_voucher boolean
);

create table discount_voucher_list (
    customer_email STRING
);

create stream customer_stream on table customer;

insert into customer 
values ('Datta', 'Dattapadal@abcd.com', True);

select * from customer;
select * from customer_stream;
-- +---------------+---------------------+------------------+-----------------+-------------------+------------------------------------------+
-- | CUSTOMER_NAME | EMAIL               | DISCOUNT_VOUCHER | METADATA$ACTION | METADATA$ISUPDATE | METADATA$ROW_ID                          |
-- |---------------+---------------------+------------------+-----------------+-------------------+------------------------------------------|
-- | Datta         | Dattapadal@abcd.com | True             | INSERT          | False             | e175188443898b1ed949d3d50c2f106cb96203c7 |
-- +---------------+---------------------+------------------+-----------------+-------------------+------------------------------------------+

Select email from customer_stream where DISCOUNT_voucher = TRUE and METADATA$ACTION = 'INSERT' and METADATA$ISUPDATE = 'FALSE';

insert into discount_voucher_list
Select email from customer_stream where DISCOUNT_voucher = TRUE and METADATA$ACTION = 'INSERT' and METADATA$ISUPDATE = 'FALSE';

Select * from customer;
select * from discount_voucher_list;
Select * from customer_stream; -- no records as the stream is consumed

--to see if the stream has any data
Select SYSTEM$STREAM_HAS_DATA('CUSTOMER_stream');

--combination of streams and tasks 
create or replace task process_new_customers
user_task_managed_initial_warehouse_size = 'XSMALL'
schedule = '1 Minute'
WHEN 
SYSTEM$STREAM_HAS_DATA('CUSTOMER_STREAM')
AS
insert into discount_voucher_list
Select email from customer_stream where DISCOUNT_voucher = TRUE and METADATA$ACTION = 'INSERT' and METADATA$ISUPDATE = 'FALSE';

alter task process_new_customers resume;


SELECT name, state,
completed_time, scheduled_time,
error_code, error_message
FROM TABLE(information_schema.task_history());

alter task process_new_customers suspend;

