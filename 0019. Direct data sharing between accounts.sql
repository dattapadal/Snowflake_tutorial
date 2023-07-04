-- Direct data sharing between accounts 

-- A share can be created only by the ACCOUNTADMIN role or roles that have been explicitly 
-- granted CREATE SHARE privilege.
-- As a consumer account, a read only database on the share can be created only by the ACCOUNTADMIN
-- role or roles that have been explicitly granted IMPORT SHARE privilege. 

-- Producer account = YCIQQGN.FC84395
-- Consumer account = QQHDOBP.JT74754

create database if not exists test_sharing;
use database test_sharing;

create table test_sharing.public.customer 
as select * from snowflake_sample_data.tpch_sf10.customer;

use role accountadmin;
grant create share  on account to role sysadmin;
use role sysadmin;

create share shr_customer;
-- to add a table to a share, the required syntax is to grant the few access all the way from database, schema and table levels.
grant usage on database test_sharing to share shr_customer;
grant usage on schema test_sharing.public to share shr_customer;
grant select on table test_sharing.public.customer to share shr_customer;

alter share shr_customer add account = QQHDOBP.JT74754;

-- it is possible to add multiple consumer accounts to a single share, simultaneously sharing the data with several consumers;

use role accountadmin;
create database customer_data from share YCIQQGN.FC84395.shr_customer;

Select * from customer_data.public.customer;

-- if you need to share data from multiple tables that exist in different databases, creating a secure view is an option.
-- Since multiple databases cannot be added to a single share, snowflake's suggested approach is to create secure views in a single database. 

-- sharing view is almost identical to sharing a table; however, an additional step is required to provide the share object with REFERENCE USAGE privilege on the databases underlying the secure views.

GRANT REFERENCE USAGE ON DATABASE <database_name> TO SHARE <share_name>;

-- we can share the data with non-snowflake user by creating a reader account and the producer will be charged for all the compute costs incurred by reader account.
