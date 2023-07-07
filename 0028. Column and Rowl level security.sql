use role sysadmin;

create database sales_db;
create schema sales_schema;
use schema sales_db.sales_schema;

create table customers (
    ID number, 
    Name string,
    email string, 
    country_code string
);
INSERT INTO CUSTOMERS VALUES 
(138763, 'Kajal Yash','k-yash@gmail.com' ,'IN'), 
(896731, 'Iza Jacenty','jacentyi@stanford.edu','PL'),
(799521, 'Finn Conley','conley76@outlook.co.uk','IE');

-- Create reader role
USE ROLE ACCOUNTADMIN; 
grant usage on database sales_db to role analyst;
grant usage on schema sales_db.sales_schema to role analyst;
grant select on table sales_db.sales_schema.customers to role analyst;

-- Create a masking admin role 
create role masking_admin;
grant usage on database sales_db to role masking_admin;
grant usage on schema sales_db.sales_schema to role masking_admin;
grant create masking policy, create row access policy on schema sales_db.sales_schema to role masking_admin;
grant apply masking policy, apply row access policy on account to role masking_admin;
grant role masking_admin to user dattapadal;

-- create masking policy 
use role masking_admin;
use schema sales_db.sales_schema;

create or replace masking policy email_mask as (val string) returns string ->
    case 
        when current_role() in ('ANALYST') then val
        ELSE REGEXP_REPLACE(VAL, '.+\@','******@')
    end;

alter table customers modify column email set masking policy email_mask;

--verify masking
use role analyst;
select * from customers;
-- +--------+-------------+------------------------+--------------+
-- |     ID | NAME        | EMAIL                  | COUNTRY_CODE |
-- |--------+-------------+------------------------+--------------|
-- | 138763 | Kajal Yash  | k-yash@gmail.com       | IN           |
-- | 896731 | Iza Jacenty | jacentyi@stanford.edu  | PL           |
-- | 799521 | Finn Conley | conley76@outlook.co.uk | IE           |
-- +--------+-------------+------------------------+--------------+

use role sysadmin;
select * from customers;
-- +--------+-------------+----------------------+--------------+
-- |     ID | NAME        | EMAIL                | COUNTRY_CODE |
-- |--------+-------------+----------------------+--------------|
-- | 138763 | Kajal Yash  | ******@gmail.com     | IN           |
-- | 896731 | Iza Jacenty | ******@stanford.edu  | PL           |
-- | 799521 | Finn Conley | ******@outlook.co.uk | IE           |
-- +--------+-------------+----------------------+--------------+

-- create a simple row access policy
use role masking_admin;
use schema sales_db.sales_schema;
create or replace row access policy RAP as (val varchar) returns boolean ->
    case 
        when current_role() = 'ANALYST' then true
        else false
    end;

alter table customers add row access policy rap on (email);
-- error: Column 'EMAIL' cannot be used as policy argument because it is masked by another policy.
-- we can unset the column masking policy and set the row access policy 
-- ALTER TABLE CUSTOMERS MODIFY COLUMN EMAIL UNSET MASKING POLICY;
-- alter table customers add row access policy rap on (email);
-- OR, we can set row access policy on different column

alter table customers add row access policy rap on (name);

-- verify policy 
use role analyst;
select * from customers;
-- +--------+-------------+------------------------+--------------+
-- |     ID | NAME        | EMAIL                  | COUNTRY_CODE |
-- |--------+-------------+------------------------+--------------|
-- | 138763 | Kajal Yash  | k-yash@gmail.com       | IN           |
-- | 896731 | Iza Jacenty | jacentyi@stanford.edu  | PL           |
-- | 799521 | Finn Conley | conley76@outlook.co.uk | IE           |
-- +--------+-------------+------------------------+--------------+

use role sysadmin;

select * from customers;
-- +----+------+-------+--------------+
-- | ID | NAME | EMAIL | COUNTRY_CODE |   
-- |----+------+-------+--------------|   
-- +----+------+-------+--------------+ 

--create mapping table
create or replace table title_country_mapping (
    title string, 
    country_iso_code string
);

use role securityadmin;
grant usage on future schemas in database sales_db to role masking_admin;

use role sysadmin;
grant select on table title_country_mapping to role masking_Admin;
insert into title_country_mapping values ('ANALYST', 'PL');

use role masking_admin;
create or replace row access policy customer_policy as (country_code varchar) returns boolean ->
    current_role() = 'SYSADMIN' or exists (Select 1 from title_country_mapping 
                                            where title=current_role()
                                            and country_iso_code = country_code
                                        );

alter table customers add row access policy customer_policy on (country_code);
--Object CUSTOMERS already has a ROW_ACCESS_POLICY. Only one ROW_ACCESS_POLICY is allowed at a time.

alter table customers drop all row access policies;

alter table customers add row access policy customer_policy on (country_code);

--verify policy 
use role sysadmin;
select * from customers;
-- +--------+-------------+----------------------+--------------+
-- |     ID | NAME        | EMAIL                | COUNTRY_CODE |
-- |--------+-------------+----------------------+--------------|
-- | 138763 | Kajal Yash  | ******@gmail.com     | IN           |
-- | 896731 | Iza Jacenty | ******@stanford.edu  | PL           |
-- | 799521 | Finn Conley | ******@outlook.co.uk | IE           |
-- +--------+-------------+----------------------+--------------+

use role analyst;
select * from customers;
-- +--------+-------------+-----------------------+--------------+
-- |     ID | NAME        | EMAIL                 | COUNTRY_CODE |
-- |--------+-------------+-----------------------+--------------|
-- | 896731 | Iza Jacenty | jacentyi@stanford.edu | PL           |
-- +--------+-------------+-----------------------+--------------+

-- Clear-down resources
USE ROLE SYSADMIN;
DROP DATABASE SALES_DB;
