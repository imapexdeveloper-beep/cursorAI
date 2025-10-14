-- Import this script in APEX SQL Workshop (Run). It will create an application
-- with minimal pages wired to task_workflow package.
-- Works in most APEX versions 19.2+ using apex_application_api.

set define off

begin
  -- Prepare install context
  apex_application_install.generate_application_id;
  apex_application_install.generate_offset;
  apex_application_install.set_application_alias('TASK_MGMT_2STEP');
  apex_application_install.set_application_name('Task Management (2-Step)');
  -- Use current parsing schema
  apex_application_install.set_schema(sys_context('USERENV','CURRENT_SCHEMA'));
  apex_application_install.set_auto_install_sup_obj(true);
end;
/

declare
  l_app_id number := apex_application_install.get_application_id;
  l_pm_auth number := 1000 + wwv_flow_api.g_id_offset;
  l_tl_auth number := 1001 + wwv_flow_api.g_id_offset;
  l_tm_auth number := 1002 + wwv_flow_api.g_id_offset;
  l_sr_auth number := 1003 + wwv_flow_api.g_id_offset;
begin
  -- Create application
  apex_application_api.create_application(
    p_id         => l_app_id,
    p_name       => apex_application_install.get_application_name,
    p_alias      => apex_application_install.get_application_alias,
    p_flow_language => 'en',
    p_flow_language_derived_from => 'FLOW_PRIMARY_LANGUAGE',
    p_default_page_template => null,
    p_default_region_template => null,
    p_default_label_template => null,
    p_default_list_template => null,
    p_default_button_template => null,
    p_default_report_template => null,
    p_authentication_scheme => 'Application Express Accounts'
  );

  -- Authorization schemes
  apex_application_api.create_security_scheme(
    p_id => l_pm_auth,
    p_flow_id => l_app_id,
    p_name => 'PM Only',
    p_scheme_type => 'NATIVE_FUNCTION_BODY',
    p_attribute_01 => 'return security_util.is_pm;'
  );

  apex_application_api.create_security_scheme(
    p_id => l_tl_auth,
    p_flow_id => l_app_id,
    p_name => 'TL Only',
    p_scheme_type => 'NATIVE_FUNCTION_BODY',
    p_attribute_01 => 'return security_util.is_tl;'
  );

  apex_application_api.create_security_scheme(
    p_id => l_tm_auth,
    p_flow_id => l_app_id,
    p_name => 'TM Only',
    p_scheme_type => 'NATIVE_FUNCTION_BODY',
    p_attribute_01 => 'return security_util.is_tm;'
  );

  apex_application_api.create_security_scheme(
    p_id => l_sr_auth,
    p_flow_id => l_app_id,
    p_name => 'Senior Only',
    p_scheme_type => 'NATIVE_FUNCTION_BODY',
    p_attribute_01 => 'return security_util.is_senior;'
  );

  -- Page 1: Home
  apex_application_api.create_page(
    p_flow_id    => l_app_id,
    p_page_id    => 1,
    p_name       => 'Home',
    p_step_title => 'Home',
    p_autocomplete_on_off => 'ON',
    p_page_template_options => null,
    p_required_role => null,
    p_protection_level => 'C'
  );

  apex_application_api.create_page_plug(
    p_flow_id => l_app_id,
    p_page_id => 1,
    p_plug_name => 'Navigation',
    p_region_template_options => null,
    p_plug_template => null,
    p_plug_display_sequence => 10,
    p_plug_source_type => 'NATIVE_STATIC_CONTENT',
    p_plug_source => q'[
      <ul>
        <li><a href="f?p=&APP_ID.:10:&SESSION.">PM - Create Task</a></li>
        <li><a href="f?p=&APP_ID.:20:&SESSION.">TL - Assign Member</a></li>
        <li><a href="f?p=&APP_ID.:21:&SESSION.">TL - Review Submission</a></li>
        <li><a href="f?p=&APP_ID.:30:&SESSION.">TM - Submit for Review</a></li>
        <li><a href="f?p=&APP_ID.:40:&SESSION.">Senior - Final Approval</a></li>
        <li><a href="f?p=&APP_ID.:50:&SESSION.">Notifications</a></li>
      </ul>
    ]'
  );

  -- Page 10: PM Create Task
  apex_application_api.create_page(
    p_flow_id    => l_app_id,
    p_page_id    => 10,
    p_name       => 'Create Task',
    p_step_title => 'Create Task',
    p_required_role => l_pm_auth,
    p_protection_level => 'C'
  );

  -- Container region
  apex_application_api.create_page_plug(
    p_flow_id => l_app_id,
    p_page_id => 10,
    p_plug_name => 'Task Details',
    p_plug_display_sequence => 10,
    p_plug_source_type => 'NATIVE_STATIC_CONTENT'
  );

  -- Items on page 10
  apex_application_api.create_page_item(
    p_flow_id => l_app_id, p_flow_step_id => 10,
    p_name => 'P10_TITLE', p_item_sequence => 10, p_prompt => 'Title',
    p_display_as => 'NATIVE_TEXT_FIELD', p_is_required => 'Y'
  );
  apex_application_api.create_page_item(
    p_flow_id => l_app_id, p_flow_step_id => 10,
    p_name => 'P10_DESCRIPTION', p_item_sequence => 20, p_prompt => 'Description',
    p_display_as => 'NATIVE_TEXTAREA'
  );
  apex_application_api.create_page_item(
    p_flow_id => l_app_id, p_flow_step_id => 10,
    p_name => 'P10_ASSIGNED_TL', p_item_sequence => 30, p_prompt => 'Assign to Team Leader',
    p_display_as => 'NATIVE_SELECT_LIST',
    p_lov_definition => 'select full_name d, user_id r from v_users where role_code = ''TL'' and is_active=1 order by 1',
    p_lov_display_null => 'YES'
  );
  apex_application_api.create_page_item(
    p_flow_id => l_app_id, p_flow_step_id => 10,
    p_name => 'P10_TASK_ID', p_item_sequence => 40,
    p_display_as => 'NATIVE_HIDDEN'
  );

  apex_application_api.create_page_button(
    p_flow_id => l_app_id, p_flow_step_id => 10, p_button_name => 'CREATE',
    p_button_sequence => 10, p_button_action => 'SUBMIT', p_button_is_hot => 'Y', p_button_label => 'Create'
  );

  apex_application_api.create_page_process(
    p_flow_id => l_app_id, p_flow_step_id => 10, p_process_sequence => 10,
    p_process_point => 'AFTER_SUBMIT', p_process_type => 'NATIVE_PLSQL',
    p_process_name => 'Create Task',
    p_process_sql_clob => q'[
      declare v_task number; v_pm number; begin
        select user_id into v_pm from users where username = :APP_USER;
        task_workflow.pm_create_task(:P10_TITLE, :P10_DESCRIPTION, :P10_ASSIGNED_TL, v_pm, v_task);
        :P10_TASK_ID := v_task;
      end;]'
    , p_process_success_message => 'Task created.'
  );

  -- Page 20: TL Assign Member
  apex_application_api.create_page(
    p_flow_id    => l_app_id,
    p_page_id    => 20,
    p_name       => 'Assign Member',
    p_step_title => 'Assign Member',
    p_required_role => l_tl_auth,
    p_protection_level => 'C'
  );
  apex_application_api.create_page_plug(
    p_flow_id => l_app_id, p_page_id => 20,
    p_plug_name => 'Assign', p_plug_display_sequence => 10,
    p_plug_source_type => 'NATIVE_STATIC_CONTENT'
  );
  apex_application_api.create_page_item(
    p_flow_id => l_app_id, p_flow_step_id => 20,
    p_name => 'P20_TASK_ID', p_item_sequence => 10, p_prompt => 'Task',
    p_display_as => 'NATIVE_SELECT_LIST',
    p_lov_definition => q'[
      select t.title||'': ''||t.task_id d, t.task_id r
        from v_tasks t
        join v_users me on me.username = :APP_USER and me.role_code = 'TL'
       where t.assigned_tl_id = me.user_id
         and (t.assigned_tm_id is null or t.status_code in ('NEW','IN_PROGRESS'))
       order by t.created_at desc]'
    , p_lov_display_null => 'YES', p_is_required => 'Y'
  );
  apex_application_api.create_page_item(
    p_flow_id => l_app_id, p_flow_step_id => 20,
    p_name => 'P20_TM_ID', p_item_sequence => 20, p_prompt => 'Team Member',
    p_display_as => 'NATIVE_SELECT_LIST',
    p_lov_definition => q'[
      select u.full_name d, u.user_id r
        from v_users u
        join v_users me on me.username = :APP_USER and me.role_code='TL' and u.team_id = me.team_id
       where u.role_code = 'TM' and u.is_active = 1
       order by 1]'
    , p_lov_display_null => 'YES', p_is_required => 'Y'
  );
  apex_application_api.create_page_button(
    p_flow_id => l_app_id, p_flow_step_id => 20, p_button_name => 'ASSIGN',
    p_button_sequence => 10, p_button_action => 'SUBMIT', p_button_is_hot => 'Y', p_button_label => 'Assign'
  );
  apex_application_api.create_page_process(
    p_flow_id => l_app_id, p_flow_step_id => 20, p_process_sequence => 10,
    p_process_point => 'AFTER_SUBMIT', p_process_type => 'NATIVE_PLSQL',
    p_process_name => 'Assign TM',
    p_process_sql_clob => q'[
      declare v_tl number; begin
        select user_id into v_tl from users where username = :APP_USER;
        task_workflow.tl_assign_member(:P20_TASK_ID, :P20_TM_ID, v_tl);
      end;]'
    , p_process_success_message => 'Assigned.'
  );

  -- Page 21: TL Review
  apex_application_api.create_page(
    p_flow_id => l_app_id, p_page_id => 21,
    p_name => 'TL Review', p_step_title => 'TL Review',
    p_required_role => l_tl_auth, p_protection_level => 'C'
  );
  apex_application_api.create_page_plug(
    p_flow_id => l_app_id, p_page_id => 21, p_plug_name => 'Review',
    p_plug_display_sequence => 10, p_plug_source_type => 'NATIVE_STATIC_CONTENT'
  );
  apex_application_api.create_page_item(
    p_flow_id => l_app_id, p_flow_step_id => 21,
    p_name => 'P21_TASK_ID', p_item_sequence => 10, p_prompt => 'Task',
    p_display_as => 'NATIVE_SELECT_LIST',
    p_lov_definition => q'[
      select t.title||'': ''||t.task_id d, t.task_id r
        from v_tasks t
        join v_users me on me.username = :APP_USER and me.role_code='TL'
       where t.assigned_tl_id = me.user_id and t.status_code = 'READY_FOR_REVIEW'
       order by t.created_at desc]'
    , p_lov_display_null => 'YES', p_is_required => 'Y'
  );
  apex_application_api.create_page_item(
    p_flow_id => l_app_id, p_flow_step_id => 21,
    p_name => 'P21_DECISION', p_item_sequence => 20, p_prompt => 'Decision',
    p_display_as => 'NATIVE_RADIOGROUP',
    p_lov_definition => 'static2:Approve;APPROVE,Reject;REJECT', p_is_required => 'Y'
  );
  apex_application_api.create_page_item(
    p_flow_id => l_app_id, p_flow_step_id => 21,
    p_name => 'P21_COMMENTS', p_item_sequence => 30, p_prompt => 'Comments',
    p_display_as => 'NATIVE_TEXTAREA'
  );
  apex_application_api.create_page_button(
    p_flow_id => l_app_id, p_flow_step_id => 21, p_button_name => 'REVIEW_SUBMIT',
    p_button_sequence => 10, p_button_action => 'SUBMIT', p_button_is_hot => 'Y', p_button_label => 'Submit Review'
  );
  apex_application_api.create_page_process(
    p_flow_id => l_app_id, p_flow_step_id => 21, p_process_sequence => 10,
    p_process_point => 'AFTER_SUBMIT', p_process_type => 'NATIVE_PLSQL',
    p_process_name => 'TL Review',
    p_process_sql_clob => q'[
      declare v_tl number; begin
        select user_id into v_tl from users where username = :APP_USER;
        task_workflow.tl_review(:P21_TASK_ID, v_tl, :P21_DECISION, :P21_COMMENTS);
      end;]'
    , p_process_success_message => 'Review recorded.'
  );

  -- Page 30: TM Submit for Review
  apex_application_api.create_page(
    p_flow_id => l_app_id, p_page_id => 30,
    p_name => 'Submit for Review', p_step_title => 'Submit for Review',
    p_required_role => l_tm_auth, p_protection_level => 'C'
  );
  apex_application_api.create_page_plug(
    p_flow_id => l_app_id, p_page_id => 30, p_plug_name => 'Submit',
    p_plug_display_sequence => 10, p_plug_source_type => 'NATIVE_STATIC_CONTENT'
  );
  apex_application_api.create_page_item(
    p_flow_id => l_app_id, p_flow_step_id => 30,
    p_name => 'P30_TASK_ID', p_item_sequence => 10, p_prompt => 'Task',
    p_display_as => 'NATIVE_SELECT_LIST',
    p_lov_definition => q'[
      select t.title||'': ''||t.task_id d, t.task_id r
        from v_tasks t
        join v_users me on me.username = :APP_USER and me.role_code='TM'
       where t.assigned_tm_id = me.user_id and t.status_code in ('IN_PROGRESS','REJECTED')
       order by t.created_at desc]'
    , p_lov_display_null => 'YES', p_is_required => 'Y'
  );
  apex_application_api.create_page_button(
    p_flow_id => l_app_id, p_flow_step_id => 30, p_button_name => 'SUBMIT_REVIEW',
    p_button_sequence => 10, p_button_action => 'SUBMIT', p_button_is_hot => 'Y', p_button_label => 'Submit'
  );
  apex_application_api.create_page_process(
    p_flow_id => l_app_id, p_flow_step_id => 30, p_process_sequence => 10,
    p_process_point => 'AFTER_SUBMIT', p_process_type => 'NATIVE_PLSQL',
    p_process_name => 'TM Submit',
    p_process_sql_clob => q'[
      declare v_tm number; begin
        select user_id into v_tm from users where username = :APP_USER;
        task_workflow.tm_submit_for_review(:P30_TASK_ID, v_tm);
      end;]'
    , p_process_success_message => 'Submitted for TL review.'
  );

  -- Page 40: Senior Final Approval
  apex_application_api.create_page(
    p_flow_id => l_app_id, p_page_id => 40,
    p_name => 'Senior Approval', p_step_title => 'Senior Approval',
    p_required_role => l_sr_auth, p_protection_level => 'C'
  );
  apex_application_api.create_page_plug(
    p_flow_id => l_app_id, p_page_id => 40, p_plug_name => 'Approval',
    p_plug_display_sequence => 10, p_plug_source_type => 'NATIVE_STATIC_CONTENT'
  );
  apex_application_api.create_page_item(
    p_flow_id => l_app_id, p_flow_step_id => 40,
    p_name => 'P40_TASK_ID', p_item_sequence => 10, p_prompt => 'Task',
    p_display_as => 'NATIVE_SELECT_LIST',
    p_lov_definition => q'[
      select t.title||'': ''||t.task_id d, t.task_id r
        from v_tasks t
       where t.status_code = 'PENDING'
       order by t.created_at desc]'
    , p_lov_display_null => 'YES', p_is_required => 'Y'
  );
  apex_application_api.create_page_item(
    p_flow_id => l_app_id, p_flow_step_id => 40,
    p_name => 'P40_DECISION', p_item_sequence => 20, p_prompt => 'Decision',
    p_display_as => 'NATIVE_RADIOGROUP',
    p_lov_definition => 'static2:Approve;APPROVE,Reject;REJECT', p_is_required => 'Y'
  );
  apex_application_api.create_page_item(
    p_flow_id => l_app_id, p_flow_step_id => 40,
    p_name => 'P40_COMMENTS', p_item_sequence => 30, p_prompt => 'Comments',
    p_display_as => 'NATIVE_TEXTAREA'
  );
  apex_application_api.create_page_button(
    p_flow_id => l_app_id, p_flow_step_id => 40, p_button_name => 'FINALIZE',
    p_button_sequence => 10, p_button_action => 'SUBMIT', p_button_is_hot => 'Y', p_button_label => 'Finalize'
  );
  apex_application_api.create_page_process(
    p_flow_id => l_app_id, p_flow_step_id => 40, p_process_sequence => 10,
    p_process_point => 'AFTER_SUBMIT', p_process_type => 'NATIVE_PLSQL',
    p_process_name => 'Senior Review',
    p_process_sql_clob => q'[
      declare v_sr number; begin
        select user_id into v_sr from users where username = :APP_USER;
        task_workflow.senior_review(:P40_TASK_ID, v_sr, :P40_DECISION, :P40_COMMENTS);
      end;]'
    , p_process_success_message => 'Decision recorded.'
  );

  -- Page 50: Notifications
  apex_application_api.create_page(
    p_flow_id => l_app_id, p_page_id => 50,
    p_name => 'Notifications', p_step_title => 'Notifications',
    p_protection_level => 'C'
  );
  apex_application_api.create_page_plug(
    p_flow_id => l_app_id, p_page_id => 50, p_plug_name => 'My Notifications',
    p_plug_display_sequence => 10, p_plug_source_type => 'NATIVE_SQL_REPORT',
    p_plug_source => q'[
      select created_at, title, body, case when is_read=1 then '||q'['Yes']'||' else '||q'['No']'||' end as read
        from notifications
       where user_id = (select user_id from users where username = :APP_USER)
       order by created_at desc]'
  );

end;
/

prompt Application created. Use App Builder to run it.
