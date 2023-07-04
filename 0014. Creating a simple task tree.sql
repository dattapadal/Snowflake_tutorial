create task delete_customer_report 
warehouse = 'My_FIRST_VW'
schedule = '1 minute'
as 
delete from customer_report;

alter task test_tasks.public.generate_customer_report unset schedule;

alter task test_tasks.public.generate_customer_report add after DELETE_CUSTOMER_REPORT;


-- child tasks need to be resumed first as once the parent task is resumed, you cannot change child task status
-- So resuming should  be from bottom_up and
--    suspending should be from top_to_bottom
alter task Generate_customer_report resume;
alter task Delete_customer_report resume;
-- OR 
-- we can use below function to enable tasks from root task instead of manually enabling each invidual task
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('DELETE_CUSTOMER_REPORT');
SELECT name, state,
completed_time, scheduled_time,
error_code, error_message
FROM TABLE(information_schema.task_history());

alter task Delete_customer_report suspend;
alter task Generate_customer_report suspend;

show tasks;


