set define off
whenever sqlerror exit sql.sqlcode rollback

prompt Installing APEX application: Teacher Dashboard

begin
  -- Optional: set these for SQL*Plus/SQLcl installs. When importing via APEX UI, these may be ignored/overridden.
  apex_application_install.set_workspace(/* e.g. */ 'YOUR_WORKSPACE');
  apex_application_install.set_schema(/* e.g. */ 'YOUR_SCHEMA');
  apex_application_install.set_application_id(92500);
  apex_application_install.set_application_alias('TEACHER_DASH');
  apex_application_install.set_application_name('Teacher Dashboard');
  apex_application_install.generate_offset;
end;
/

begin
  -- Begin import context
  wwv_flow_api.import_begin (
    p_version_yyyy_mm_dd => '2020.03.31',
    p_release             => '23.1',
    p_default_workspace_id=> null,
    p_default_application_id => apex_application_install.get_application_id,
    p_default_owner       => apex_application_install.get_schema
  );

  -- Create application
  wwv_flow_api.create_flow(
    p_id                  => apex_application_install.get_application_id,
    p_display_id          => apex_application_install.get_application_id,
    p_owner               => apex_application_install.get_schema,
    p_name                => 'Teacher Dashboard',
    p_alias               => apex_application_install.get_application_alias,
    p_page_view_logging   => 'YES',
    p_flow_language       => 'en',
    p_flow_language_derived_from => 'FLOW_PRIMARY_LANGUAGE',
    p_authentication      => 'NOBODY',
    p_flow_version        => '1.0',
    p_group_id            => null,
    p_flow_image_prefix   => null,
    p_documentation_banner=> null,
    p_theme_id            => 42,
    p_theme_name          => 'Universal Theme',
    p_flow_status         => 'AVAILABLE'
  );

  -- Create a single UI (Universal Theme)
  wwv_flow_api.create_user_interface(
    p_id                         => 4200000000000000,
    p_flow_id                    => apex_application_install.get_application_id,
    p_ui_type_name               => 'DESKTOP',
    p_display_name               => 'Desktop',
    p_is_default                 => 'Y',
    p_theme_id                   => 42,
    p_home_link_target           => 'f?p=&APP_ID.:200:&SESSION.'
  );

  -- Create Teacher Dashboard page 200
  wwv_flow_api.create_page(
    p_id                   => 200,
    p_flow_id              => apex_application_install.get_application_id,
    p_user_interface_id    => 4200000000000000,
    p_name                 => 'Teacher Dashboard',
    p_step_title           => 'Teacher Dashboard',
    p_autocomplete_on_off  => 'OFF',
    p_page_template        => null,
    p_last_updated_by      => apex_application_install.get_schema,
    p_last_upd_yyyymmddhh24miss => to_char(sysdate,'YYYYMMDDHH24MISS')
  );

  -- Region: Filters
  wwv_flow_api.create_page_plug(
    p_id                     => 200010,
    p_flow_id                => apex_application_install.get_application_id,
    p_page_id                => 200,
    p_plug_name              => 'Filters',
    p_region_css_classes     => 't-Region--noPadding',
    p_plug_display_sequence  => 10,
    p_plug_source_type       => 'NATIVE_HTML_REGION'
  );

  -- Items: P200_STAFF_ID, P200_FROM_DATE, P200_TO_DATE
  wwv_flow_api.create_page_item(
    p_id                    => 200011,
    p_flow_id               => apex_application_install.get_application_id,
    p_page_id               => 200,
    p_name                  => 'P200_STAFF_ID',
    p_item_sequence         => 10,
    p_item_plug_id          => 200010,
    p_prompt                => 'Teacher',
    p_display_as            => 'NATIVE_SELECT_LIST',
    p_lov                   => q'[SELECT FIRSTNAME || ' ' || LASTNAME AS display_value,
                                         STAFFID                     AS return_value
                                    FROM TBLSTAFF
                                   ORDER BY 1]',
    p_lov_display_null      => 'YES',
    p_lov_null_text         => 'Select teacher…',
    p_attribute_01          => 'NONE' -- escape special chars
  );

  wwv_flow_api.create_page_item(
    p_id                    => 200012,
    p_flow_id               => apex_application_install.get_application_id,
    p_page_id               => 200,
    p_name                  => 'P200_FROM_DATE',
    p_item_sequence         => 20,
    p_item_plug_id          => 200010,
    p_prompt                => 'From Date',
    p_display_as            => 'NATIVE_DATE_PICKER_JET',
    p_item_default          => 'TRUNC(SYSDATE) - 30',
    p_item_default_type     => 'PLSQL_EXPRESSION'
  );

  wwv_flow_api.create_page_item(
    p_id                    => 200013,
    p_flow_id               => apex_application_install.get_application_id,
    p_page_id               => 200,
    p_name                  => 'P200_TO_DATE',
    p_item_sequence         => 30,
    p_item_plug_id          => 200010,
    p_prompt                => 'To Date',
    p_display_as            => 'NATIVE_DATE_PICKER_JET',
    p_item_default          => 'TRUNC(SYSDATE)',
    p_item_default_type     => 'PLSQL_EXPRESSION'
  );

  -- Button: Apply Filters (submits page)
  wwv_flow_api.create_page_button(
    p_id                    => 200014,
    p_flow_id               => apex_application_install.get_application_id,
    p_page_id               => 200,
    p_button_sequence       => 40,
    p_button_plug_id        => 200010,
    p_button_name           => 'APPLY_FILTERS',
    p_button_label          => 'Apply Filters',
    p_button_action         => 'SUBMIT',
    p_button_position       => 'NEXT'
  );

  -- Region: Dashboard (Dynamic Content)
  wwv_flow_api.create_page_plug(
    p_id                     => 200020,
    p_flow_id                => apex_application_install.get_application_id,
    p_page_id                => 200,
    p_plug_name              => 'Dashboard',
    p_plug_display_sequence  => 20,
    p_plug_source_type       => 'NATIVE_DYNAMIC_CONTENT',
    p_plug_source            => q'[
DECLARE
  l_staff_id   NUMBER := TO_NUMBER(:P200_STAFF_ID);
  l_from_date  DATE   := :P200_FROM_DATE;
  l_to_date    DATE   := :P200_TO_DATE;
  l_classes    NUMBER := 0;
  l_hours      NUMBER := 0;
  l_avg        NUMBER := 0;
  l_upcoming   NUMBER := 0;
  l_conflicts  NUMBER := 0;
  l_att_days   NUMBER := 0;
  l_on_time    NUMBER := 0;

  PROCEDURE print(p_str VARCHAR2) IS BEGIN htp.p(p_str); END; 
BEGIN
  print('<div class="t-Region">');
  print('<div class="t-Region-header"><h2 class="t-Region-title">Teacher Dashboard</h2></div>');
  print('<div class="t-Region-body">');

  IF l_staff_id IS NULL THEN
    print('<p>Please select a teacher and click Apply Filters.</p>');
    print('</div></div>');
    RETURN;
  END IF;

  -- KPI calculations
  SELECT NVL(COUNT(*),0), NVL(SUM((END_DATE - START_DATE) * 24),0)
    INTO l_classes, l_hours
    FROM TBLCLASS_TIMERS a
   WHERE a.STAFF_ID = l_staff_id
     AND (l_from_date IS NULL OR a.START_DATE >= l_from_date)
     AND (l_to_date   IS NULL OR a.START_DATE <  l_to_date + 1);

  IF l_classes > 0 THEN
    l_avg := ROUND(l_hours / l_classes, 2);
  ELSE
    l_avg := 0;
  END IF;

  SELECT NVL(COUNT(DISTINCT TRUNC(CHECK_DATE)),0)
    INTO l_att_days
    FROM TBLCHECKINOUT
   WHERE USER_ID = l_staff_id
     AND (l_from_date IS NULL OR TRUNC(CHECK_DATE) >= l_from_date)
     AND (l_to_date   IS NULL OR TRUNC(CHECK_DATE) <= l_to_date);

  SELECT NVL(SUM(on_time_flag),0)
    INTO l_on_time
    FROM (
      SELECT TRUNC(CHECK_DATE) d,
             CASE
               WHEN (MAX(CASE WHEN TYPE = 2 THEN CHECKTIME END)
                  -  MAX(CASE WHEN TYPE = 1 THEN CHECKTIME END)) * 24 >= 9 THEN 1
               ELSE 0
             END on_time_flag
        FROM TBLCHECKINOUT
       WHERE USER_ID = l_staff_id
         AND (l_from_date IS NULL OR TRUNC(CHECK_DATE) >= l_from_date)
         AND (l_to_date   IS NULL OR TRUNC(CHECK_DATE) <= l_to_date)
       GROUP BY TRUNC(CHECK_DATE)
    );

  SELECT NVL(COUNT(*),0)
    INTO l_upcoming
    FROM TBLCLASS_TIMERS a
   WHERE a.STAFF_ID = l_staff_id
     AND a.START_DATE >= SYSDATE
     AND a.START_DATE < SYSDATE + 30;

  SELECT NVL(COUNT(*),0)
    INTO l_conflicts
    FROM (
      SELECT tt.DAY, tt.TIME_SESSION
        FROM (
          SELECT ca.STAFFID,
                 ct.DAY,
                 TO_CHAR(TO_TIMESTAMP(ct.TIME, 'HH24:MI:SS'),'HH:MI AM') AS TIME_SESSION
            FROM TBLCLASS_ASSIGNED ca
            JOIN TBLCLASS_TIMINGS ct ON ca.TASKID = ct.TASK_ID
            JOIN TBLCLASSES c ON ca.TASKID = c.ID
           WHERE c.STATUS IN (1,4,6,7)
             AND ca.STAFFID = l_staff_id
        ) tt
       GROUP BY tt.DAY, tt.TIME_SESSION
      HAVING COUNT(*) > 1
    );

  -- KPI cards (simple responsive grid)
  print('<div class="t-Container t-Container--responsive t-Container--gap">');
  print('<div class="t-Form-fieldContainer t-Form-fieldContainer--stretch">');
  print('<div class="t-Cards t-Cards--displayIcons t-Cards--spanColumns">');

  print('<div class="t-Card"><span class="t-Card-icon fa fa-chalkboard-teacher"></span><div class="t-Card-title">Classes</div><div class="t-Card-desc">'||TO_CHAR(l_classes)||'</div></div>');
  print('<div class="t-Card"><span class="t-Card-icon fa fa-clock"></span><div class="t-Card-title">Hours</div><div class="t-Card-desc">'||TO_CHAR(ROUND(l_hours,2))||'</div></div>');
  print('<div class="t-Card"><span class="t-Card-icon fa fa-gauge-high"></span><div class="t-Card-title">Avg hrs/class</div><div class="t-Card-desc">'||TO_CHAR(l_avg)||'</div></div>');
  print('<div class="t-Card"><span class="t-Card-icon fa fa-user-check"></span><div class="t-Card-title">On-time %</div><div class="t-Card-desc">'||CASE WHEN l_att_days=0 THEN '0' ELSE TO_CHAR(ROUND(l_on_time*100/l_att_days,0)) END||'%</div></div>');
  print('<div class="t-Card"><span class="t-Card-icon fa fa-calendar-days"></span><div class="t-Card-title">Upcoming (30d)</div><div class="t-Card-desc">'||TO_CHAR(l_upcoming)||'</div></div>');
  print('<div class="t-Card"><span class="t-Card-icon fa fa-triangle-exclamation"></span><div class="t-Card-title">Conflicts</div><div class="t-Card-desc">'||TO_CHAR(l_conflicts)||'</div></div>');

  print('</div></div></div>');

  -- Teacher profile
  print('<h3>Teacher Profile</h3>');
  FOR r IN (
    SELECT STAFFID,
           FIRSTNAME || ' ' || LASTNAME AS FULL_NAME,
           EMAIL, PHONENUMBER,
           JOB_POSITION, WORKPLACE,
           HOURLY_RATE,
           CURRENT_ADDRESS, PERMANENT_ADDRESS,
           TO_CHAR(BIRTHDAY,'DD-MON-YYYY') AS BIRTHDAY,
           RELIGION, NATION, STATUS_WORK,
           TO_CHAR(DATE_UPDATE,'DD-MON-YYYY') AS DATE_UPDATE
      FROM TBLSTAFF
     WHERE STAFFID = l_staff_id
  ) LOOP
    print('<table class="t-Report-report"><tbody>');
    print('<tr><th>Full Name</th><td>'||apex_escape.html(r.full_name)||'</td></tr>');
    print('<tr><th>Email</th><td>'||apex_escape.html(r.email)||'</td></tr>');
    print('<tr><th>Phone</th><td>'||apex_escape.html(r.phonenumber)||'</td></tr>');
    print('<tr><th>Job</th><td>'||apex_escape.html(r.job_position)||' @ '||apex_escape.html(r.workplace)||'</td></tr>');
    print('<tr><th>Hourly Rate</th><td>'||TO_CHAR(r.hourly_rate)||'</td></tr>');
    print('<tr><th>Current Address</th><td>'||apex_escape.html(r.current_address)||'</td></tr>');
    print('<tr><th>Permanent Address</th><td>'||apex_escape.html(r.permanent_address)||'</td></tr>');
    print('<tr><th>Birthday</th><td>'||apex_escape.html(r.birthday)||'</td></tr>');
    print('<tr><th>Religion</th><td>'||apex_escape.html(r.religion)||'</td></tr>');
    print('<tr><th>Nation</th><td>'||apex_escape.html(r.nation)||'</td></tr>');
    print('<tr><th>Status</th><td>'||apex_escape.html(r.status_work)||'</td></tr>');
    print('<tr><th>Updated</th><td>'||apex_escape.html(r.date_update)||'</td></tr>');
    print('</tbody></table>');
  END LOOP;

  -- Attendance details
  print('<h3>Attendance</h3>');
  print('<table class="t-Report-report"><thead><tr>');
  print('<th>Date</th><th>Check-in</th><th>Check-out</th><th>Working Hours</th><th>Total Hours</th><th>Status</th></tr></thead><tbody>');
  FOR r IN (
    SELECT X.ATTENDANCE_DATE,
           X.CHECKIN_TIME,
           X.CHECKOUT_TIME,
           X.WORKING_HOURS,
           X.TOTAL_HOURS,
           X.ATTENDANCE_STATUS
      FROM (
        SELECT TRUNC(CHECK_DATE) AS ATTENDANCE_DATE,
               MAX(CASE WHEN TYPE = 1 THEN TO_CHAR(CHECKTIME, 'HH12:MI AM') END) AS CHECKIN_TIME,
               MAX(CASE WHEN TYPE = 2 THEN TO_CHAR(CHECKTIME, 'HH12:MI AM') END) AS CHECKOUT_TIME,
               B.WORKING_HOURS,
               ROUND((MAX(CASE WHEN TYPE = 2 THEN CHECKTIME END) - MAX(CASE WHEN TYPE = 1 THEN CHECKTIME END)) * 24, 2) AS TOTAL_HOURS,
               CASE 
                 WHEN (MAX(CASE WHEN TYPE = 1 THEN CHECKTIME END) - MIN(CASE WHEN TYPE = 1 THEN CHECKTIME END)) * 24 < 9
                 THEN 'Late In' ELSE 'On Time' END AS ATTENDANCE_STATUS
          FROM TBLCHECKINOUT A
          JOIN TBLSTAFF C ON A.USER_ID = C.STAFFID
          JOIN TBLSTAFF_WORKING_HOURS B ON C.STAFFID = B.STAFFID
         WHERE C.STAFFID = l_staff_id
           AND (l_from_date IS NULL OR TRUNC(CHECK_DATE) >= l_from_date)
           AND (l_to_date   IS NULL OR TRUNC(CHECK_DATE) <= l_to_date)
         GROUP BY TRUNC(CHECK_DATE), B.WORKING_HOURS
      ) X
     ORDER BY X.ATTENDANCE_DATE DESC
  ) LOOP
    print('<tr>');
    print('<td>'||TO_CHAR(r.ATTENDANCE_DATE,'DD-MON-YYYY')||'</td>');
    print('<td>'||NVL(apex_escape.html(r.CHECKIN_TIME),'')||'</td>');
    print('<td>'||NVL(apex_escape.html(r.CHECKOUT_TIME),'')||'</td>');
    print('<td>'||NVL(TO_CHAR(r.WORKING_HOURS),'')||'</td>');
    print('<td>'||NVL(TO_CHAR(r.TOTAL_HOURS),'0')||'</td>');
    print('<td>'||NVL(apex_escape.html(r.ATTENDANCE_STATUS),'')||'</td>');
    print('</tr>');
  END LOOP;
  print('</tbody></table>');

  -- Classes
  print('<h3>Classes / Sessions</h3>');
  print('<table class="t-Report-report"><thead><tr>');
  print('<th>Class Date</th><th>Start</th><th>End</th><th>Student</th><th>Teacher</th><th>Status</th><th>Feedback</th><th>Course</th><th>Contents</th><th>Note</th></tr></thead><tbody>');
  FOR r IN (
    SELECT 
      TO_CHAR(A.START_DATE,'DD-MON-YYYY') AS CLASS_DATE,
      TO_CHAR(A.START_DATE,'HH12:MI AM') AS START_TIME,
      TO_CHAR(A.END_DATE,'HH12:MI AM') AS END_TIME,
      B.ID||'-'||B.NAME AS STUDENT_NAME,
      G.FIRSTNAME || ' ' || G.LASTNAME AS TEACHER_NAME,
      F.TIME_SHEET_DESC AS CLASS_STATUS,
      E.FEEDBACK_NAME AS TEACHER_FEEDBACK,
      FUNC_GET_COURSE_TIMER(H.TIMER_ID) AS COURSE_NAME,
      FUNC_GET_COURSE_CONTENTS(A.ID) AS COURSE_CONTENTS,
      A.NOTE
    FROM TBLCLASS_TIMERS A
    JOIN TBLCLASSES B ON A.TASK_ID = B.ID
    JOIN TBLSTAFF G ON A.STAFF_ID = G.STAFFID
    LEFT JOIN TBLTEACHER_FEEDBACK E ON A.TEACHER_FEEDBACK = E.FEEDBACK_ID
    LEFT JOIN TIME_SHEET_STATUS F ON A.CLASS_STATUS = F.TIME_SHEET_ID
    LEFT JOIN ( SELECT a.COURSE_ID, a.TIMER_ID FROM TBLCLASS_TIMER_DETAILS a ) H
      ON A.ID = H.TIMER_ID
   WHERE A.STAFF_ID = l_staff_id
     AND (l_from_date IS NULL OR A.START_DATE >= l_from_date)
     AND (l_to_date   IS NULL OR A.START_DATE <  l_to_date + 1)
   ORDER BY A.START_DATE DESC
  ) LOOP
    print('<tr>');
    print('<td>'||r.CLASS_DATE||'</td>');
    print('<td>'||r.START_TIME||'</td>');
    print('<td>'||r.END_TIME||'</td>');
    print('<td>'||apex_escape.html(r.STUDENT_NAME)||'</td>');
    print('<td>'||apex_escape.html(r.TEACHER_NAME)||'</td>');
    print('<td>'||apex_escape.html(r.CLASS_STATUS)||'</td>');
    print('<td>'||apex_escape.html(NVL(r.TEACHER_FEEDBACK,' '))||'</td>');
    print('<td>'||apex_escape.html(NVL(r.COURSE_NAME,' '))||'</td>');
    print('<td>'||apex_escape.html(NVL(r.COURSE_CONTENTS,' '))||'</td>');
    print('<td>'||apex_escape.html(NVL(r.NOTE,' '))||'</td>');
    print('</tr>');
  END LOOP;
  print('</tbody></table>');

  -- Schedule conflicts
  print('<h3>Schedule Conflicts</h3>');
  print('<table class="t-Report-report"><thead><tr><th>Day</th><th>Time</th><th>Status</th></tr></thead><tbody>');
  FOR r IN (
    SELECT 
      tt.DAY,
      tt.TIME_SESSION,
      CASE WHEN COUNT(*) OVER (PARTITION BY tt.DAY, tt.TIME_SESSION) > 1 THEN 'Duplicate' END AS STATUS
    FROM (
      SELECT 
        ca.STAFFID,
        ct.DAY,
        TO_CHAR(TO_TIMESTAMP(ct.TIME, 'HH24:MI:SS'), 'HH:MI AM') AS TIME_SESSION
      FROM TBLCLASS_ASSIGNED ca
      JOIN TBLCLASS_TIMINGS ct ON ca.TASKID = ct.TASK_ID
      JOIN TBLCLASSES c ON ca.TASKID = c.ID
      WHERE c.STATUS IN (1, 4, 6, 7)
        AND ca.STAFFID = l_staff_id
    ) tt
    ORDER BY tt.DAY, tt.TIME_SESSION
  ) LOOP
    print('<tr>');
    print('<td>'||apex_escape.html(r.DAY)||'</td>');
    print('<td>'||apex_escape.html(r.TIME_SESSION)||'</td>');
    print('<td>'||NVL(apex_escape.html(r.STATUS),'')||'</td>');
    print('</tr>');
  END LOOP;
  print('</tbody></table>');

  print('</div></div>');
END;]'
  );

  -- End import
  wwv_flow_api.import_end;
end;
/

commit;

prompt Application installed. Open:  f?p=92500:200

set define on
