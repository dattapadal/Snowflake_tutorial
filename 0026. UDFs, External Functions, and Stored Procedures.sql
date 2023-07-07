use role sysadmin;
use warehouse compute_wh;

--create a demo database and schema
create or replace database demo_db;
create or replace schema demo_schema;

--set context
use schema demo_db.demo_schema;

-- user defined functions 

--SQL UDF to return the name of the day of the week on a future date.
create or replace function day_name_on(num_of_days int)
returns string -- no need to mention language as by default it will be SQL
as
$$
    Select 'In ' || CAST(num_of_days AS string) || ' days it will be a ' || dayname(dateadd(day, num_of_days, current_date()))
$$;    

show functions like 'day_name_on';
-- SELECT 
-- "name", "schema_name", "is_builtin", "is_aggregate", "arguments", "description", "catalog_name", "is_table_function", "is_secure", "is_external_function", "language"
--  FROM TABLE(result_scan(last_query_id()));
-- +-------------+-------------+------------+--------------+------------------------------------+-----------------------+--------------+-------------------+-----------+----------------------+----------+
-- | name        | schema_name | is_builtin | is_aggregate | arguments                          | description           | catalog_name | is_table_function | is_secure | is_external_function | language |
-- |-------------+-------------+------------+--------------+------------------------------------+-----------------------+--------------+-------------------+-----------+----------------------+----------|
-- | DAY_NAME_ON | DEMO_SCHEMA | N          | N            | DAY_NAME_ON(NUMBER) RETURN VARCHAR | user-defined function | DEMO_DB      | N                 | N         | N                    | SQL      |
-- +-------------+-------------+------------+--------------+------------------------------------+-----------------------+--------------+-------------------+-----------+----------------------+----------+

Select day_name_on(100);
--In 100 days it will be a Fri

-- Javascript UDF to return the name of the day of the week on a future date.
create or replace function JS_DAY_NAME_ON(num_of_days float)
returns string 
language JAVASCRIPT 
AS 
$$
    const weekday= ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
    const date = new Date();
    date.setDate(date.getDate() + NUM_OF_DAYS);
    let day = weekday[date.getDay()];

    var result = 'In ' + NUM_OF_DAYS + ' days it will be a ' + day;
    return result;
$$;

Select js_day_name_on(100);
-- In 100 days it will be a day.


show functions like 'JS_day_name_on';
-- +----------------+-------------+------------+--------------+--------------------------------------+-----------------------+--------------+-------------------+-----------+----------------------+------------+
-- | name           | schema_name | is_builtin | is_aggregate | arguments                            | description           | catalog_name | is_table_function | is_secure | is_external_function | language   |
-- |----------------+-------------+------------+--------------+--------------------------------------+-----------------------+--------------+-------------------+-----------+----------------------+------------|
-- | JS_DAY_NAME_ON | DEMO_SCHEMA | N          | N            | JS_DAY_NAME_ON(FLOAT) RETURN VARCHAR | user-defined function | DEMO_DB      | N                 | N         | N                    | JAVASCRIPT |
-- +----------------+-------------+------------+--------------+--------------------------------------+-----------------------+--------------+-------------------+-----------+----------------------+------------+


-- All UDFs can be overloaded.
-- Below is an example of Javascript UDF overload with different number of parameters
CREATE OR REPLACE FUNCTION JS_DAY_NAME_ON(num_of_days float, is_abbr boolean)
RETURNS STRING
LANGUAGE JAVASCRIPT
  AS
  $$
    if (IS_ABBR === 1){
        var weekday = ["Sun","Mon","Tues","Wed","Thu","Fri","Sat"];
    } else {
        var weekday = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
    }    
    
    const date = new Date();
    date.setDate(date.getDate() + NUM_OF_DAYS);
    
    
    let day = weekday[date.getDay()];
    
    var result = 'In ' + NUM_OF_DAYS + ' days it will be a '+ day; 
   
    return result;
  $$;

  -- Use the JavaScript UDF as part of a query. 
SELECT JS_DAY_NAME_ON(100,TRUE);
-- In 100 days it will be a Fri
SELECT JS_DAY_NAME_ON(100,FALSE);
-- In 100 days it will be a Friday

show functions like 'JS_day_name_on';
-- +----------------+-------------+------------+--------------+-----------------------------------------------+-----------------------+--------------+-------------------+-----------+----------------------+------------+
-- | name           | schema_name | is_builtin | is_aggregate | arguments                                     | description           | catalog_name | is_table_function | is_secure | is_external_function 
-- |----------------+-------------+------------+--------------+-----------------------------------------------+-----------------------+--------------+-------------------+-----------+----------------------+------------|
-- | JS_DAY_NAME_ON | DEMO_SCHEMA | N          | N            | JS_DAY_NAME_ON(FLOAT) RETURN VARCHAR          | user-defined function | DEMO_DB      | N                 | N         | N
-- | JS_DAY_NAME_ON | DEMO_SCHEMA | N          | N            | JS_DAY_NAME_ON(FLOAT, BOOLEAN) RETURN VARCHAR | user-defined function | DEMO_DB      | N                 | N         | N
-- +----------------+-------------+------------+--------------+-----------------------------------------------+-----------------------+--------------+-------------------+-----------+----------------------+------------+

-- External function - just the template for now 
    
CREATE OR REPLACE API INTEGRATION demonstration_external_api_integration_01
    API_PROVIDER=aws_api_gateway
    API_AWS_ROLE_ARN='arn:aws:iam::123456789012:role/my_cloud_account_role'
    API_ALLOWED_PREFIXES=('https://xyz.execute-api.us-west-2.amazonaws.com/production')
    ENABLED=true;

CREATE OR REPLACE EXTERNAL FUNCTION local_echo(string_col varchar)
    RETURNS variant
    API_INTEGRATION = demonstration_external_api_integration_01 -- API Integration object
    AS 'https://xyz.execute-api.us-west-2.amazonaws.com/production/remote_echo'; -- Proxy service URL

SELECT my_external_function(34, 56);

-- Stored procedure JavaScript
-- Create demo tables and insert data to test procedure
CREATE TABLE DEMO_TABLE 
(
NAME STRING, 
AGE INT
);

CREATE TABLE DEMO_TABLE_2 
(
NAME STRING, 
AGE INT
);
    
INSERT INTO DEMO_TABLE VALUES ('Edric',56),('Jayanthi',23),('Chloe',51),('Rowland',50),('Lorna',33),('Satish',19);
INSERT INTO DEMO_TABLE_2 VALUES ('Edric',56),('Jayanthi',23),('Chloe',51),('Rowland',50),('Lorna',33),('Satish',19);

SELECT COUNT(*) FROM DEMO_TABLE;
SELECT COUNT(*) FROM DEMO_TABLE_2;

CREATE OR REPLACE PROCEDURE TRUNCATE_ALL_TABLES_IN_SCHEMA(DATABASE_NAME STRING, SCHEMA_NAME STRING)
    RETURNS STRING
    LANGUAGE JAVASCRIPT
    EXECUTE AS OWNER -- can also be executed as 'caller'
    AS
    $$
    var result = [];
    var namespace = DATABASE_NAME + '.' + SCHEMA_NAME;
    var sql_command = 'SHOW TABLES in ' + namespace ; 
    var result_set = snowflake.execute({sqlText: sql_command});
    while (result_set.next()){
        var table_name = result_set.getColumnValue(2);
        var truncate_result = snowflake.execute({sqlText: 'TRUNCATE TABLE ' + table_name});
        result.push(namespace + '.' + table_name + ' has been sucessfully truncated.');
        
    }
    return result.join("\n"); 
    $$;

-- Calling a stored procedure cannot be used as part of a SQL statement, dissimilar to a UDF. 
CALL TRUNCATE_ALL_TABLES_IN_SCHEMA('DEMO_DB', 'DEMO_SCHEMA');
-- DEMO_DB.DEMO_SCHEMA.DEMO_TABLE has been sucessfully truncated.
-- DEMO_DB.DEMO_SCHEMA.DEMO_TABLE_2 has been sucessfully truncated.

SELECT COUNT(*) FROM DEMO_TABLE;
SELECT COUNT(*) FROM DEMO_TABLE_2;

-- Clear-down objects
DROP DATABASE DEMO_DB;