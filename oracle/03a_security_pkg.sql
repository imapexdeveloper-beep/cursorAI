create or replace package security_util as
  function get_current_username return varchar2;
  function get_current_user_id return number;
  function has_role(p_role_code in varchar2) return boolean;
  function is_pm return boolean;
  function is_tl return boolean;
  function is_tm return boolean;
  function is_senior return boolean;
end security_util;
/
create or replace package body security_util as
  function get_current_username return varchar2 is
  begin
    return coalesce(apex_util.get_session_state('APP_USER'), sys_context('APEX$SESSION','APP_USER'));
  exception when others then return null; end;

  function get_current_user_id return number is
    v_id number;
  begin
    select user_id into v_id from users where username = get_current_username();
    return v_id;
  exception when no_data_found then return null; end;

  function has_role(p_role_code in varchar2) return boolean is
    v_dummy number;
  begin
    select 1 into v_dummy from v_users where username = get_current_username() and role_code = upper(p_role_code);
    return true;
  exception when no_data_found then return false; end;

  function is_pm return boolean is begin return has_role('PM'); end;
  function is_tl return boolean is begin return has_role('TL'); end;
  function is_tm return boolean is begin return has_role('TM'); end;
  function is_senior return boolean is begin return has_role('SENIOR'); end;
end security_util;
/