-- Seed data: 1 Senior, 6 Team Leaders, 66 Team Members, 1 PM
set define off

prompt Inserting teams...
insert into teams (team_name) select 'Team '||level from dual connect by level <= 6;

prompt Inserting users...
-- Project Manager
insert into users (username, full_name, email, role_code)
values ('PM1', 'Project Manager', 'pm@example.com', 'PM');

-- One Senior
insert into users (username, full_name, email, role_code)
values ('SENIOR1', 'Senior Approver', 'senior@example.com', 'SENIOR');

-- Six Team Leaders mapped to teams
insert into users (username, full_name, email, role_code, team_id)
select 'TL'||team_id, 'Team Leader '||team_id, 'tl'||team_id||'@example.com', 'TL', team_id
from teams
order by team_id;

-- Update teams.leader_user_id after TLs inserted
merge into teams t
using (
  select u.team_id, u.user_id from users u where u.role_code='TL'
) src on (t.team_id = src.team_id)
when matched then update set t.leader_user_id = src.user_id;

-- 66 Team Members: 11 per team (6x11=66)
insert /*+ append */ into users (username, full_name, email, role_code, team_id)
select 'TM'||team_id||'_'||rn, 'Team Member '||team_id||'-'||rn,
       'tm'||team_id||'_'||rn||'@example.com', 'TM', team_id
from (
  select t.team_id, level rn from teams t connect by level <= 11 and prior t.team_id = t.team_id and prior sys_guid() is not null
)
order by team_id, rn;

commit;

prompt Sample task for smoke test...
-- Map PM and first TL/TM ids for demo
declare
  v_pm users.user_id;
  v_tl users.user_id;
  v_tm users.user_id;
  v_task_id tasks.task_id;
begin
  select user_id into v_pm from users where role_code='PM' fetch first 1 row only;
  select user_id into v_tl from users where role_code='TL' and team_id = 1 fetch first 1 row only;
  select user_id into v_tm from users where role_code='TM' and team_id = 1 fetch first 1 row only;

  insert into tasks (title, description, created_by, assigned_tl_id, assigned_tm_id)
  values ('Initial Task', 'Demo task seeded', v_pm, v_tl, v_tm)
  returning task_id into v_task_id;

  commit;
end;
/
