-- create a new role,  grant privileges and assign it to user 
use role accountadmin;
show roles;
SELECT "name", "comment" FROM TABLE(result_scan(last_query_id()));
-- +---------------+-----------------------------------------------------------------------------------+
-- | name          | comment                                                                           |
-- |---------------+-----------------------------------------------------------------------------------|
-- | ACCOUNTADMIN  | Account administrator can manage all aspects of the account.                      |
-- | ORGADMIN      | Organization administrator can manage organizations and accounts in organizations |
-- | PUBLIC        | Public role is automatically available to every user in the account.              |
-- | SECURITYADMIN | Security administrator can manage security aspects of the account.                |
-- | SYSADMIN      | System administrator can create and manage databases and warehouses.              |
-- | USERADMIN     | User administrator can create and manage users and roles                          |
-- +---------------+-----------------------------------------------------------------------------------+
-- 6 Row(s) produced. Time Elapsed: 0.703s

show grants to role securityadmin;
-- +-------------------------------+-----------------------+------------+-----------+------------+---------------+--------------+------------+
-- | created_on                    | privilege             | granted_on | name      | granted_to | grantee_name  | grant_option | granted_by |
-- |-------------------------------+-----------------------+------------+-----------+------------+---------------+--------------+------------|
-- | 2023-07-05 02:32:30.508 -0700 | APPLY PASSWORD POLICY | ACCOUNT    | AI09146   | ROLE       | SECURITYADMIN | true         |            |
-- | 2023-07-05 02:32:30.507 -0700 | APPLY SESSION POLICY  | ACCOUNT    | AI09146   | ROLE       | SECURITYADMIN | true         |            |
-- | 2023-07-05 02:32:30.505 -0700 | ATTACH POLICY         | ACCOUNT    | AI09146   | ROLE       | SECURITYADMIN | true         |            |
-- | 2023-07-05 02:32:30.505 -0700 | CREATE NETWORK POLICY | ACCOUNT    | AI09146   | ROLE       | SECURITYADMIN | true         |            |
-- | 2023-07-05 02:32:30.506 -0700 | MANAGE GRANTS         | ACCOUNT    | AI09146   | ROLE       | SECURITYADMIN | true         |            |
-- | 2023-07-05 02:32:30.398 -0700 | USAGE                 | ROLE       | USERADMIN | ROLE       | SECURITYADMIN | true         |            |
-- +-------------------------------+-----------------------+------------+-----------+------------+---------------+--------------+------------+

use role sysadmin;

CREATE DATABASE FILMS_DB;
CREATE SCHEMA FILMS_SCHEMA;
CREATE TABLE FILMS_SYSADMIN
(
  ID STRING, 
  TITLE STRING,  
  RELEASE_DATE DATE,
  RATING INT
);

-- Create custom role inherited by SYSADMIN system-defined role
USE ROLE SECURITYADMIN;

CREATE ROLE ANALYST;

GRANT USAGE
  ON DATABASE FILMS_DB
  TO ROLE ANALYST;

GRANT USAGE, CREATE TABLE
  ON SCHEMA FILMS_DB.FILMS_SCHEMA
  TO ROLE ANALYST;

GRANT USAGE
  ON WAREHOUSE COMPUTE_WH
  TO ROLE ANALYST;
  
GRANT ROLE ANALYST TO ROLE SYSADMIN;

GRANT ROLE ANALYST TO USER dattapadal;

show grants to role analyst;

-- +-------------------------------+--------------+------------+-----------------------+------------+--------------+--------------+------------+
-- | created_on                    | privilege    | granted_on | name                  | granted_to | grantee_name | grant_option | granted_by |
-- |-------------------------------+--------------+------------+-----------------------+------------+--------------+--------------+------------|
-- | 2023-07-05 19:05:30.107 -0700 | USAGE        | DATABASE   | FILMS_DB              | ROLE       | ANALYST      | false        | SYSADMIN   |
-- | 2023-07-05 19:05:36.256 -0700 | CREATE TABLE | SCHEMA     | FILMS_DB.FILMS_SCHEMA | ROLE       | ANALYST      | false        | SYSADMIN   |
-- | 2023-07-05 19:05:36.242 -0700 | USAGE        | SCHEMA     | FILMS_DB.FILMS_SCHEMA | ROLE       | ANALYST      | false        | SYSADMIN   |
-- | 2023-07-05 19:05:39.128 -0700 | USAGE        | WAREHOUSE  | COMPUTE_WH            | ROLE       | ANALYST      | false        | SYSADMIN   |
-- +-------------------------------+--------------+------------+-----------------------+------------+--------------+--------------+------------+

show grants on role analyst;
-- +-------------------------------+-----------+------------+---------+------------+---------------+--------------+---------------+
-- | created_on                    | privilege | granted_on | name    | granted_to | grantee_name  | grant_option | granted_by    |
-- |-------------------------------+-----------+------------+---------+------------+---------------+--------------+---------------|
-- | 2023-07-05 19:05:25.653 -0700 | OWNERSHIP | ROLE       | ANALYST | ROLE       | SECURITYADMIN | true         | SECURITYADMIN |
-- | 2023-07-05 19:05:42.271 -0700 | USAGE     | ROLE       | ANALYST | ROLE       | SYSADMIN      | false        | SECURITYADMIN |
-- +-------------------------------+-----------+------------+---------+------------+---------------+--------------+---------------+

show grants of role analyst;
-- +-------------------------------+---------+------------+--------------+---------------+
-- | created_on                    | role    | granted_to | grantee_name | granted_by    |
-- |-------------------------------+---------+------------+--------------+---------------|
-- | 2023-07-05 19:05:49.041 -0700 | ANALYST | USER       | DATTAPADAL   | SECURITYADMIN |
-- | 2023-07-05 19:05:42.271 -0700 | ANALYST | ROLE       | SYSADMIN     | SECURITYADMIN |
-- +-------------------------------+---------+------------+--------------+---------------+

-- Set context
USE ROLE ANALYST;
USE SCHEMA FILMS_DB.FILMS_SCHEMA;

CREATE TABLE FILMS_ANALYST
(
  ID STRING, 
  TITLE STRING,  
  RELEASE_DATE DATE,
  RATING INT
);

SHOW TABLES;
SHOW DATABASES;
SELECT "name", "owner" FROM TABLE(result_scan(last_query_id()));
-- +-----------------------+--------------+
-- | name                  | owner        |
-- |-----------------------+--------------|
-- | FILMS_DB              | SYSADMIN     |
-- | SNOWFLAKE             |              |
-- | SNOWFLAKE_SAMPLE_DATA | ACCOUNTADMIN |
--+-----------------------+--------------+

use role securityadmin;
GRANT OWNERSHIP ON DATABASE FILMS_DB TO ROLE ANALYST; -- error 
--SQL execution error: Dependent grant of privilege 'USAGE' on securable 'FILMS_DB' to role 'ANALYST' exists.  
-- It must be revoked first.  More than one dependent grant may exist: use 'SHOW GRANTS' command to view them.  
-- To revoke all dependent grants while transferring object ownership,
-- use convenience command 'GRANT OWNERSHIP ON <target_objects> TO <target_role> REVOKE CURRENT GRANTS'.

GRANT OWNERSHIP on database films_db to role analyst revoke current grants;

use role analyst;
SHOW DATABASES;
-- +-----------------------+--------------+
-- | name                  | owner        |
-- |-----------------------+--------------|
-- | FILMS_DB              | ANALYST      |
-- | SNOWFLAKE             |              |
-- | SNOWFLAKE_SAMPLE_DATA | ACCOUNTADMIN |
-- +-----------------------+--------------+

-- Future grants 
use role securityadmin;
grant usage on future schemas in database films_db to role analyst;

use role sysadmin;
create schema music_schema;
create schema books_schema;
show schemas;

use role analyst;
show schemas; -- can see above two created schemas

SHOW GRANTS TO ROLE ANALYST;
-- +-------------------------------+--------------+------------+-------------------------------------+------------+--------------+--------------+------------+
-- | created_on                    | privilege    | granted_on | name                                | granted_to | grantee_name | grant_option | granted_by |
-- |-------------------------------+--------------+------------+-------------------------------------+------------+--------------+--------------+------------|
-- | 2023-07-05 19:21:35.680 -0700 | OWNERSHIP    | DATABASE   | FILMS_DB                            | ROLE       | ANALYST      | true         | ANALYST    |
-- | 2023-07-05 19:26:07.540 -0700 | USAGE        | SCHEMA     | FILMS_DB.BOOKS_SCHEMA               | ROLE       | ANALYST      | false        | SYSADMIN   |
-- | 2023-07-05 19:05:36.256 -0700 | CREATE TABLE | SCHEMA     | FILMS_DB.FILMS_SCHEMA               | ROLE       | ANALYST      | false        | SYSADMIN   |
-- | 2023-07-05 19:05:36.242 -0700 | USAGE        | SCHEMA     | FILMS_DB.FILMS_SCHEMA               | ROLE       | ANALYST      | false        | SYSADMIN   |
-- | 2023-07-05 19:25:56.440 -0700 | USAGE        | SCHEMA     | FILMS_DB.MUSIC_SCHEMA               | ROLE       | ANALYST      | false        | SYSADMIN   |
-- | 2023-07-05 19:15:55.517 -0700 | OWNERSHIP    | TABLE      | FILMS_DB.FILMS_SCHEMA.FILMS_ANALYST | ROLE       | ANALYST      | true         | ANALYST    |
-- | 2023-07-05 19:05:39.128 -0700 | USAGE        | WAREHOUSE  | COMPUTE_WH                          | ROLE       | ANALYST      | false        | SYSADMIN   |
-- +-------------------------------+--------------+------------+-------------------------------------+------------+--------------+--------------+------------+

-- create user 
use role useradmin;

create user datta2 password='password' default_role=analyst default_warehouse = 'COMPUTE_WH' MUST_CHANGE_PASSWORD = TRUE;

use role sysadmin;
drop database films_db;
