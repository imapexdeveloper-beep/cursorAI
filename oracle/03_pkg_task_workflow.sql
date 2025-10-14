create or replace package task_workflow as
  -- Transition APIs
  procedure pm_create_task(
    p_title         in tasks.title%type,
    p_description   in tasks.description%type,
    p_assigned_tl   in users.user_id%type,
    p_created_by    in users.user_id%type,
    p_project_id    in projects.project_id%type default null,
    p_task_id       out tasks.task_id%type
  );

  procedure tl_assign_member(
    p_task_id     in tasks.task_id%type,
    p_assigned_tm in users.user_id%type,
    p_tl_user     in users.user_id%type
  );

  procedure tm_submit_for_review(
    p_task_id   in tasks.task_id%type,
    p_tm_user   in users.user_id%type
  );

  procedure tl_review(
    p_task_id   in tasks.task_id%type,
    p_tl_user   in users.user_id%type,
    p_decision  in varchar2, -- 'APPROVE'|'REJECT'
    p_comments  in varchar2 default null
  );

  procedure senior_review(
    p_task_id   in tasks.task_id%type,
    p_senior    in users.user_id%type,
    p_decision  in varchar2, -- 'APPROVE'|'REJECT'
    p_comments  in varchar2 default null
  );

  procedure pm_cancel_task(
    p_task_id in tasks.task_id%type,
    p_pm_user in users.user_id%type
  );

  -- Utility
  function can_user_see_task(p_task_id in number, p_user_id in number) return number;
end task_workflow;
/

create or replace package body task_workflow as

  procedure notify(p_user_id in number, p_task_id in number, p_title in varchar2, p_body in varchar2) is
  begin
    insert into notifications(user_id, task_id, title, body)
    values (p_user_id, p_task_id, p_title, p_body);
  end;

  function get_tl_for_task(p_task_id in number) return number is
    v_tl number;
  begin
    select assigned_tl_id into v_tl from tasks where task_id = p_task_id;
    return v_tl;
  exception when no_data_found then return null; end;

  procedure assert_role(p_user_id in number, p_role in varchar2) is
    v_count number;
  begin
    select count(*) into v_count from users where user_id = p_user_id and role_code = p_role and is_active = 1;
    if v_count = 0 then
      raise_application_error(-20001, 'User does not have role '||p_role);
    end if;
  end;

  procedure pm_create_task(
    p_title         in tasks.title%type,
    p_description   in tasks.description%type,
    p_assigned_tl   in users.user_id%type,
    p_created_by    in users.user_id%type,
    p_project_id    in projects.project_id%type default null,
    p_task_id       out tasks.task_id%type
  ) is
  begin
    assert_role(p_created_by, 'PM');
    assert_role(p_assigned_tl, 'TL');

    insert into tasks(project_id, title, description, status_code, created_by, assigned_tl_id)
    values (p_project_id, p_title, p_description, 'NEW', p_created_by, p_assigned_tl)
    returning task_id into p_task_id;

    -- Notify TL
    notify(p_assigned_tl, p_task_id, 'New task assigned by PM', p_title);
  end;

  procedure tl_assign_member(
    p_task_id     in tasks.task_id%type,
    p_assigned_tm in users.user_id%type,
    p_tl_user     in users.user_id%type
  ) is
    v_tl number;
  begin
    assert_role(p_tl_user, 'TL');
    assert_role(p_assigned_tm, 'TM');

    v_tl := get_tl_for_task(p_task_id);
    if v_tl is null or v_tl <> p_tl_user then
      raise_application_error(-20002, 'Only task''s TL can assign member');
    end if;

    update tasks
       set assigned_tm_id = p_assigned_tm,
           status_code = 'IN_PROGRESS',
           updated_at = systimestamp,
           updated_by = p_tl_user
     where task_id = p_task_id;

    notify(p_assigned_tm, p_task_id, 'You have a new assignment', 'Please start work');
  end;

  procedure tm_submit_for_review(
    p_task_id   in tasks.task_id%type,
    p_tm_user   in users.user_id%type
  ) is
    v_tm number;
    v_tl number;
  begin
    assert_role(p_tm_user, 'TM');
    select assigned_tm_id, assigned_tl_id into v_tm, v_tl from tasks where task_id = p_task_id;
    if v_tm is null or v_tm <> p_tm_user then
      raise_application_error(-20003, 'Only the assigned TM can submit');
    end if;

    update tasks set status_code='READY_FOR_REVIEW', updated_at = systimestamp, updated_by = p_tm_user
    where task_id = p_task_id;

    notify(v_tl, p_task_id, 'Task submitted for your review', 'Please approve or reject');
  end;

  procedure record_approval(p_task_id in number, p_step in number, p_approver in number, p_decision in varchar2, p_comments in varchar2) is
  begin
    merge into task_approvals d
    using (select p_task_id task_id, p_step step_no from dual) s
    on (d.task_id = s.task_id and d.step_no = s.step_no)
    when matched then update set approver_id = p_approver, decision = p_decision, decision_at = systimestamp, comments = p_comments
    when not matched then insert (task_id, step_no, approver_id, decision, decision_at, comments)
         values (p_task_id, p_step, p_approver, p_decision, systimestamp, p_comments);
  end;

  procedure tl_review(
    p_task_id   in tasks.task_id%type,
    p_tl_user   in users.user_id%type,
    p_decision  in varchar2,
    p_comments  in varchar2 default null
  ) is
    v_tl number;
    v_tm number;
    v_senior number;
  begin
    assert_role(p_tl_user, 'TL');
    select assigned_tl_id, assigned_tm_id into v_tl, v_tm from tasks where task_id = p_task_id;
    if v_tl <> p_tl_user then
      raise_application_error(-20004, 'Only the assigned TL can review');
    end if;

    if upper(p_decision) = 'APPROVE' then
      -- Step 1 approved -> set pending and notify senior
      update tasks set status_code='PENDING', updated_at = systimestamp, updated_by = p_tl_user where task_id = p_task_id;
      record_approval(p_task_id, 1, p_tl_user, 'APPROVE', p_comments);
      -- One senior in system
      select user_id into v_senior from users where role_code='SENIOR' and is_active=1 fetch first 1 row only;
      notify(v_senior, p_task_id, 'Task requires senior approval', 'Approve or reject');
    else
      -- Rejected by TL -> REJECTED and notify TM to rework
      update tasks set status_code='REJECTED', updated_at = systimestamp, updated_by = p_tl_user where task_id = p_task_id;
      record_approval(p_task_id, 1, p_tl_user, 'REJECT', p_comments);
      if v_tm is not null then
        notify(v_tm, p_task_id, 'Task rejected by TL', nvl(p_comments,'Please rework and resubmit'));
      end if;
    end if;
  end;

  procedure senior_review(
    p_task_id   in tasks.task_id%type,
    p_senior    in users.user_id%type,
    p_decision  in varchar2,
    p_comments  in varchar2 default null
  ) is
    v_tm number;
    v_tl number;
  begin
    assert_role(p_senior, 'SENIOR');
    select assigned_tm_id, assigned_tl_id into v_tm, v_tl from tasks where task_id = p_task_id;

    if upper(p_decision) = 'APPROVE' then
      update tasks set status_code='APPROVED', updated_at = systimestamp, updated_by = p_senior where task_id = p_task_id;
      record_approval(p_task_id, 2, p_senior, 'APPROVE', p_comments);
      if v_tm is not null then
        notify(v_tm, p_task_id, 'Task fully approved', 'You can see APPROVED status');
      end if;
      notify(v_tl, p_task_id, 'Task fully approved', 'Approved by Senior');
    else
      update tasks set status_code='REJECTED', updated_at = systimestamp, updated_by = p_senior where task_id = p_task_id;
      record_approval(p_task_id, 2, p_senior, 'REJECT', p_comments);
      if v_tm is not null then
        notify(v_tm, p_task_id, 'Task rejected by Senior', nvl(p_comments,'Please rework'));
      end if;
      notify(v_tl, p_task_id, 'Task rejected by Senior', nvl(p_comments,'Please review'));
    end if;
  end;

  procedure pm_cancel_task(
    p_task_id in tasks.task_id%type,
    p_pm_user in users.user_id%type
  ) is
    v_creator number;
  begin
    assert_role(p_pm_user, 'PM');
    select created_by into v_creator from tasks where task_id = p_task_id;
    if v_creator <> p_pm_user then
      raise_application_error(-20005, 'Only the creating PM can cancel');
    end if;

    update tasks set status_code='CANCELLED', updated_at = systimestamp, updated_by = p_pm_user where task_id = p_task_id;
  end;

  function can_user_see_task(p_task_id in number, p_user_id in number) return number is
    v_cnt number;
  begin
    select count(*) into v_cnt
      from tasks t
     where t.task_id = p_task_id
       and (t.created_by = p_user_id or t.assigned_tl_id = p_user_id or t.assigned_tm_id = p_user_id or exists (
         select 1 from users u where u.user_id = p_user_id and u.role_code = 'SENIOR'
       ));
    return case when v_cnt > 0 then 1 else 0 end;
  end;

end task_workflow;
/