-- =============================================
-- Task Management System - APEX Application Setup
-- =============================================
-- This script contains the configuration for creating
-- the APEX application manually through the APEX builder
-- =============================================

/*
APPLICATION DETAILS:
- Application Name: Task Management System
- Application Type: Database
- Authentication: Application Express Accounts
- Application ID: (Auto-assigned by APEX)

SHARED COMPONENTS TO CREATE:
1. Application Items
2. Application Processes
3. Lists
4. LOVs (List of Values)
5. Navigation Bar Entries
6. Authorization Schemes
*/

-- =============================================
-- LOVs (Create these in Shared Components > List of Values)
-- =============================================

/*
LOV 1: TEAM_LEADERS_LOV
Type: Dynamic
Query:
*/
SELECT full_name AS display_value, user_id AS return_value
FROM app_users
WHERE role = 'TL' AND is_active = 'Y'
ORDER BY full_name;

/*
LOV 2: TEAM_MEMBERS_LOV
Type: Dynamic
Query (for TL):
*/
SELECT full_name AS display_value, user_id AS return_value
FROM app_users
WHERE role = 'TM' 
  AND is_active = 'Y'
  AND team_id = (SELECT team_id FROM app_users WHERE username = :APP_USER)
ORDER BY full_name;

/*
LOV 3: ALL_TEAM_MEMBERS_LOV
Type: Dynamic
Query:
*/
SELECT full_name || ' (Team ' || team_id || ')' AS display_value, 
       user_id AS return_value
FROM app_users
WHERE role = 'TM' AND is_active = 'Y'
ORDER BY team_id, full_name;

/*
LOV 4: TASK_STATUS_LOV
Type: Static
Values:
*/
-- NEW - New
-- IN_PROGRESS - In Progress
-- READY_FOR_REVIEW - Ready for Review
-- PENDING_TL_APPROVAL - Pending TL Approval
-- PENDING_SENIOR_APPROVAL - Pending Senior Approval
-- APPROVED - Approved
-- REJECTED - Rejected
-- CANCELLED - Cancelled

/*
LOV 5: PRIORITY_LOV
Type: Static
Values:
*/
-- LOW - Low
-- MEDIUM - Medium
-- HIGH - High
-- URGENT - Urgent

/*
LOV 6: USER_ROLES_LOV
Type: Static
Values:
*/
-- PM - Project Manager
-- TL - Team Leader
-- TM - Team Member
-- SENIOR - Senior

-- =============================================
-- Authorization Schemes
-- =============================================

/*
AUTH_SCHEME 1: IS_PM
Type: Exists SQL Query
Query:
*/
SELECT 1 FROM app_users 
WHERE username = :APP_USER AND role = 'PM' AND is_active = 'Y';

/*
AUTH_SCHEME 2: IS_TL
Type: Exists SQL Query
Query:
*/
SELECT 1 FROM app_users 
WHERE username = :APP_USER AND role = 'TL' AND is_active = 'Y';

/*
AUTH_SCHEME 3: IS_TM
Type: Exists SQL Query
Query:
*/
SELECT 1 FROM app_users 
WHERE username = :APP_USER AND role = 'TM' AND is_active = 'Y';

/*
AUTH_SCHEME 4: IS_SENIOR
Type: Exists SQL Query
Query:
*/
SELECT 1 FROM app_users 
WHERE username = :APP_USER AND role = 'SENIOR' AND is_active = 'Y';

/*
AUTH_SCHEME 5: IS_PM_OR_TL
Type: Exists SQL Query
Query:
*/
SELECT 1 FROM app_users 
WHERE username = :APP_USER AND role IN ('PM', 'TL') AND is_active = 'Y';

/*
AUTH_SCHEME 6: IS_TL_OR_SENIOR
Type: Exists SQL Query
Query:
*/
SELECT 1 FROM app_users 
WHERE username = :APP_USER AND role IN ('TL', 'SENIOR') AND is_active = 'Y';

-- =============================================
-- Application Items
-- =============================================

/*
Create these Application Items:
- G_USER_ID (Number)
- G_USER_ROLE (VARCHAR2)
- G_USER_FULL_NAME (VARCHAR2)
- G_TEAM_ID (Number)
*/

-- =============================================
-- Application Computation (Set User Context)
-- =============================================

/*
Create Application Computation:
Computation Point: Before Header
Items to Compute: G_USER_ID, G_USER_ROLE, G_USER_FULL_NAME, G_TEAM_ID

Computation Type: SQL Query (return single value)
For G_USER_ID:
*/
SELECT user_id FROM app_users WHERE username = :APP_USER;

/*
For G_USER_ROLE:
*/
SELECT role FROM app_users WHERE username = :APP_USER;

/*
For G_USER_FULL_NAME:
*/
SELECT full_name FROM app_users WHERE username = :APP_USER;

/*
For G_TEAM_ID:
*/
SELECT team_id FROM app_users WHERE username = :APP_USER;

-- =============================================
-- Navigation Menu
-- =============================================

/*
Create Navigation Menu with following entries:

1. Home (Page 1)
   - Authorization: None

2. My Tasks (Page 10)
   - Authorization: None
   - Badge (SQL): SELECT COUNT(*) FROM tasks WHERE assigned_to_tm = :G_USER_ID AND status IN ('IN_PROGRESS', 'REJECTED')

3. Create Task (Page 20)
   - Authorization: IS_PM
   
4. Manage Tasks (Page 30)
   - Authorization: IS_TL
   - Badge (SQL): SELECT COUNT(*) FROM tasks WHERE assigned_to_tl = :G_USER_ID AND status = 'NEW'

5. Pending Approvals (Page 40)
   - Authorization: IS_TL_OR_SENIOR
   - Badge (SQL): 
     SELECT COUNT(*) FROM tasks 
     WHERE (status = 'PENDING_TL_APPROVAL' AND assigned_to_tl = :G_USER_ID AND :G_USER_ROLE = 'TL')
        OR (status = 'PENDING_SENIOR_APPROVAL' AND :G_USER_ROLE = 'SENIOR')

6. All Tasks (Page 50)
   - Authorization: IS_PM_OR_TL

7. Reports (Page 60)
   - Authorization: None

8. Notifications (Page 70)
   - Authorization: None
   - Badge (SQL): SELECT COUNT(*) FROM task_notifications WHERE user_id = :G_USER_ID AND is_read = 'N'
*/

-- =============================================
-- Email Templates (Optional - for notifications)
-- =============================================

-- Create these as Static Application Files or in mail templates

COMMIT;
