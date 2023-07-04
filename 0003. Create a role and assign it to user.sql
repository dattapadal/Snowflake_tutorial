-- create a new role,  grant privileges and assign it to user 
use role accountadmin;

create or replace role read_only;
grant usage on warehouse my_first_vw to role read_only;
grant usage on database temp_db to role read_only;

grant role read_only to user <new_user>;
