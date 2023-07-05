create or replace database test_streams;

create table customer(
    customer_name string,
    email string, 
    discount_voucher boolean
);

create table discount_voucher_list (
    customer_email STRING
);
-- create a standard (delta) stream on the table :customer , any stream created by defaut would be standard streams 
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
--- Check the stream offset ---- 
SELECT SYSTEM$STREAM_GET_TABLE_TIMESTAMP('customer_stream') as customer_table_st_offset;

SELECT to_timestamp(SYSTEM$STREAM_GET_TABLE_TIMESTAMP('customer_stream')) as customer_table_st_offset;

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

--- Create a append-only stream on the raw table :customer_table--- here updates will be ignored.
CREATE OR REPLACE STREAM Customer_streams_apnd  ON TABLE customer append_only=true;

--we can consume streams under one transaction by using begin and commit - Atomocity is supported

begin;
    insert into <table_name>
    select a,b,c from <stream_name>;

    insert into <table_name_2>
    select d,e from <stream_name>;

commit;

