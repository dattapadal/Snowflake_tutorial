-- we can download SNOWSQL from snowflake official website and start using snowflake command line tool.
-- once atfer downloading from C:/Users/<user_name>/.snowsql/config and edit this file to add account_locator, username, database,
-- schema, password etc.,
-- Or we can pass them as a command line argument.

snowsql -a <account_locator>.<region>.{aws/azure/gcp} -u <user_name> -r <role_name> -d <database_name> -s <schema_name> -w <warehouse_name>;

--querying 
snowsql -q "select current_date()"
-- * SnowSQL * v1.2.27
-- Type SQL statements or !help
-- +----------------+
-- | CURRENT_DATE() |
-- |----------------|
-- | 2023-07-05     |
-- +----------------+
-- 1 Row(s) produced. Time Elapsed: 0.123s
-- Goodbye!

-- variables 
---------------
snowsql -D table_name=DEMO_TABLE -o variable_substitution=true
-- * SnowSQL * v1.2.27
-- Type SQL statements or !help

select $table_name;
-- 002211 (02000): SQL compilation error: error line 1 at position 7
-- Session variable '$TABLE_NAME' does not exist

select '&table_name';
-- +--------------+
-- | 'DEMO_TABLE' |
-- |--------------|
-- | DEMO_TABLE   |
-- +--------------+
-- 1 Row(s) produced. Time Elapsed: 0.093s

!define table_name_two=DEMO_TABLE_TWO
!variables

-- +----------------+--------------------------------------+
-- | Name           | Value                                |
-- |----------------+--------------------------------------|
-- | __rowcount     | 1                                    |
-- | __sfqid        | 01ad6f54-3201-7da9-0001-4c1200017012 |
-- | table_name     | DEMO_TABLE                           |
-- | table_name_two | DEMO_TABLE_TWO                       |
-- +----------------+--------------------------------------+