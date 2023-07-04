
create or replace database test_timetravel;

create table test_timetravel.public.CUSTOMER as
SELECT * from SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER;

Select current_timestamp; -- 2023-07-04 00:34:34.368 -0700

update customer set c_phone = NULL; -- query ID : 01ad6586-3201-7c07-0001-4ade00038142

Select * from customer;

Select * from customer Before(TIMESTAMP => '2023-07-04 00:34:34.368 -0700'::timestamp_ltz);

Select * from customer Before(OFFSET => -90); -- here 90 is seconds offset

-- Retrieve data as it existed before a DML query 

Select * from customer Before(STATEMENT => '01ad6586-3201-7c07-0001-4ade00038142');
-- query ID of NULL execution 01ad6586-3201-7c07-0001-4ade00038142

-- undrop a table
drop table customer;

Select * from customer; -- results in SQL compilation error as table is not found

undrop table customer;

Select * from customer; -- can see all the data now.

-- Similarly we can undrop database, schema and tables.

--The Time Travel period can be changed for an object by running the
--ALTER command and specifying the Time Travel days through
--data_retention_time_in_days. For example:

ALTER TABLE <table_name> SET data_retention_time_in_days=<number_of_days>;
