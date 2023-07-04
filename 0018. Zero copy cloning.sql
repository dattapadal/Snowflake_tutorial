-- Zero copy cloning

-- cloning table
create database if not exists test_cloning;
use database test_cloning;

create table test_cloning.public.customer as 
select * from snowflake_sample_data.tpch_sf10.customer;

select count(*) from customer; -- 1,500,000

create table customer_copy clone customer;

select count(*) from customer_copy; -- 1,500,000

update customer_copy Set c_mktsegment = 'STRUCTURE' where c_mktsegment = 'BUILDING';

Select * from customer limit 10;

Select C_MKTSEGMENT, count(*) from customer_copy group by C_MKTSEGMENT;

Select C_MKTSEGMENT, count(*) from customer group by C_MKTSEGMENT;

-- cloning database
use database test_cloning;

create table test_cloning.public.nation 
as select * from snowflake_sample_data.tpch_sf10.nation;

create schema sub_schema;
create table test_cloning.sub_schema.region as
select * from snowflake_sample_data.tpch_sf10.region;

create database cloned_database clone test_cloning;

-- A cloned object does not inherit any of the privileges from the source object; for example, a cloned table does not inherit 
-- any granted privileges. However, if a database or schema is cloned, privileges on the child objects are inherited.


-- cloning with time travel 
create table test_cloning.public.supplier
as select * from snowflake_sample_data.tpch_sf10.supplier;

update test_cloning.public.supplier set S_name = Null; -- 01ad5f47-3201-7b4f-0001-4ade0002107a

select * from supplier where s_name is not null; -- no result

create table supplier_copy clone supplier
before (statement => '01ad5f47-3201-7b4f-0001-4ade0002107a');

select * from supplier_copy where s_name is not null; -- will have all the data before update statement