-- creating resource monitor

use role accountadmin;

-- creating a resource monitor with 10 credits to reset every week with appropriate actions and notifications
create resource monitor "VW_10" with Credit_quota = 10, frequency ='WEEKLY'
start_timestamp = 'IMMEDIATELY' end_timestamp = NULL 
triggers 
on 95 percent do suspend_immediate
on 50 percent do notify;

-- set the 
alter warehouse "COMPUTE_WH" SET REsource_monitor = 'VW_10';

-- adding additional roles to view and alter the configuration of above resource monitor
grant monitor, modify on resource monitor "VW_10" to role sysadmin;