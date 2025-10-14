# Installation Guide - Task Management System

## Quick Start Installation

This guide will walk you through installing the Task Management System from scratch.

---

## Prerequisites

### Required Software
- ✅ Oracle Database 11g or higher
- ✅ Oracle APEX 19.2 or higher
- ✅ SQL*Plus, SQL Developer, or similar SQL client
- ✅ Web browser (Chrome, Firefox, Safari, or Edge)

### Required Privileges
```sql
-- Your database user needs these privileges:
GRANT CREATE TABLE TO your_schema;
GRANT CREATE SEQUENCE TO your_schema;
GRANT CREATE VIEW TO your_schema;
GRANT CREATE PROCEDURE TO your_schema;
GRANT CREATE TRIGGER TO your_schema;
GRANT UNLIMITED TABLESPACE TO your_schema;
```

---

## Installation Steps

### Step 1: Download Files

Ensure you have all SQL scripts:
```
01_create_tables.sql
02_create_sequences_triggers.sql
03_create_views.sql
04_create_package.sql
05_sample_data.sql
06_apex_application_setup.sql
07_apex_pages_structure.sql
```

### Step 2: Connect to Database

#### Using SQL*Plus
```bash
sqlplus username/password@database_connection_string
```

#### Using SQL Developer
1. Open SQL Developer
2. Create new connection
3. Enter connection details
4. Test and Connect

### Step 3: Execute Database Scripts

**Execute scripts IN ORDER:**

#### Script 1: Create Tables
```sql
@01_create_tables.sql
```

**Expected Output:**
```
Table APP_USERS created.
Table TASKS created.
Table TASK_APPROVALS created.
Table TASK_COMMENTS created.
Table TASK_NOTIFICATIONS created.
```

**Verify:**
```sql
SELECT COUNT(*) FROM user_tables 
WHERE table_name IN ('APP_USERS', 'TASKS', 'TASK_APPROVALS', 'TASK_COMMENTS', 'TASK_NOTIFICATIONS');
-- Should return 5
```

#### Script 2: Create Sequences and Triggers
```sql
@02_create_sequences_triggers.sql
```

**Expected Output:**
```
Sequence SEQ_APP_USERS created.
Sequence SEQ_TASKS created.
Sequence SEQ_TASK_APPROVALS created.
Sequence SEQ_TASK_COMMENTS created.
Sequence SEQ_TASK_NOTIFICATIONS created.
Trigger TRG_APP_USERS_BI compiled.
Trigger TRG_TASKS_BI compiled.
...
```

**Verify:**
```sql
SELECT sequence_name FROM user_sequences WHERE sequence_name LIKE 'SEQ_%';
-- Should return 5 sequences

SELECT trigger_name, status FROM user_triggers WHERE trigger_name LIKE 'TRG_%';
-- All should be ENABLED
```

#### Script 3: Create Views
```sql
@03_create_views.sql
```

**Expected Output:**
```
View V_TASK_DASHBOARD created.
View V_MY_TASKS created.
View V_PENDING_APPROVALS created.
View V_TASK_HISTORY created.
```

**Verify:**
```sql
SELECT view_name FROM user_views WHERE view_name LIKE 'V_%';
-- Should return 4 views
```

#### Script 4: Create PL/SQL Package
```sql
@04_create_package.sql
```

**Expected Output:**
```
Package PKG_TASK_MANAGEMENT compiled.
Package body PKG_TASK_MANAGEMENT compiled.
No errors.
```

**Verify:**
```sql
SELECT object_name, object_type, status 
FROM user_objects 
WHERE object_name = 'PKG_TASK_MANAGEMENT';
-- Both PACKAGE and PACKAGE BODY should be VALID
```

**If there are errors:**
```sql
SHOW ERRORS PACKAGE PKG_TASK_MANAGEMENT;
SHOW ERRORS PACKAGE BODY PKG_TASK_MANAGEMENT;
```

#### Script 5: Load Sample Data
```sql
@05_sample_data.sql
```

**Expected Output:**
```
Total Users: 74
PM: 1
Senior: 1
Team Leaders: 6
Team Members: 66
Total Tasks: 6
```

**Verify:**
```sql
-- Check users
SELECT role, COUNT(*) FROM app_users GROUP BY role ORDER BY role;

-- Check tasks
SELECT status, COUNT(*) FROM tasks GROUP BY status ORDER BY status;

-- Check notifications
SELECT COUNT(*) FROM task_notifications;
```

### Step 4: Database Installation Complete!

You should now have:
- ✅ 5 tables created
- ✅ 5 sequences created
- ✅ 8 triggers created
- ✅ 4 views created
- ✅ 1 PL/SQL package created
- ✅ 74 users loaded
- ✅ 6 sample tasks loaded

---

## APEX Application Setup

### Step 5: Access APEX

1. Open your web browser
2. Navigate to your APEX URL:
   ```
   http://your-apex-server:port/apex
   ```
3. Log in to your workspace

### Step 6: Create New Application

#### Method A: Import Application (If Export File Available)

1. Click **App Builder**
2. Click **Import**
3. Select the application export file (`.sql` file)
4. Click **Next**
5. Click **Install Application**
6. Skip to Step 12

#### Method B: Create Application Manually

Continue with the following steps...

### Step 7: Create Application

1. Click **App Builder**
2. Click **Create**
3. Select **New Application**
4. Enter Application Name: `Task Management System`
5. Click **Create Application**

### Step 8: Configure Authentication

1. Go to **Shared Components**
2. Click **Authentication Schemes**
3. Ensure "Application Express Accounts" is current
4. Click **Edit**
5. Set login page settings as needed
6. Click **Apply Changes**

### Step 9: Create Application Items

1. Go to **Shared Components**
2. Click **Application Items**
3. Create the following items:

| Name | Scope | Session State Protection |
|------|-------|-------------------------|
| G_USER_ID | Application | Unrestricted |
| G_USER_ROLE | Application | Unrestricted |
| G_USER_FULL_NAME | Application | Unrestricted |
| G_TEAM_ID | Application | Unrestricted |

### Step 10: Create Application Computation

1. Go to **Shared Components**
2. Click **Application Computations**
3. Click **Create**
4. Create 4 computations (one for each Application Item):

**Computation 1: G_USER_ID**
- Computation Point: `Before Header`
- Computation Item: `G_USER_ID`
- Computation Type: `SQL Query (return single value)`
- Computation:
  ```sql
  SELECT user_id FROM app_users WHERE username = :APP_USER
  ```

**Computation 2: G_USER_ROLE**
- Same settings as above, but:
  ```sql
  SELECT role FROM app_users WHERE username = :APP_USER
  ```

**Computation 3: G_USER_FULL_NAME**
- Same settings as above, but:
  ```sql
  SELECT full_name FROM app_users WHERE username = :APP_USER
  ```

**Computation 4: G_TEAM_ID**
- Same settings as above, but:
  ```sql
  SELECT team_id FROM app_users WHERE username = :APP_USER
  ```

### Step 11: Create Authorization Schemes

1. Go to **Shared Components**
2. Click **Authorization Schemes**
3. Create the following schemes:

**Scheme 1: IS_PM**
- Name: `IS_PM`
- Scheme Type: `Exists SQL Query`
- SQL Query:
  ```sql
  SELECT 1 FROM app_users WHERE username = :APP_USER AND role = 'PM' AND is_active = 'Y'
  ```
- Identify error message: `You must be a Project Manager to access this page`

**Scheme 2: IS_TL**
```sql
SELECT 1 FROM app_users WHERE username = :APP_USER AND role = 'TL' AND is_active = 'Y'
```

**Scheme 3: IS_TM**
```sql
SELECT 1 FROM app_users WHERE username = :APP_USER AND role = 'TM' AND is_active = 'Y'
```

**Scheme 4: IS_SENIOR**
```sql
SELECT 1 FROM app_users WHERE username = :APP_USER AND role = 'SENIOR' AND is_active = 'Y'
```

**Scheme 5: IS_PM_OR_TL**
```sql
SELECT 1 FROM app_users WHERE username = :APP_USER AND role IN ('PM', 'TL') AND is_active = 'Y'
```

**Scheme 6: IS_TL_OR_SENIOR**
```sql
SELECT 1 FROM app_users WHERE username = :APP_USER AND role IN ('TL', 'SENIOR') AND is_active = 'Y'
```

### Step 12: Create List of Values (LOVs)

1. Go to **Shared Components**
2. Click **List of Values**
3. Create the following LOVs:

**LOV 1: TEAM_LEADERS_LOV**
- Name: `TEAM_LEADERS_LOV`
- Type: `Dynamic`
- Query:
  ```sql
  SELECT full_name AS display_value, user_id AS return_value
  FROM app_users
  WHERE role = 'TL' AND is_active = 'Y'
  ORDER BY full_name
  ```

**LOV 2: TEAM_MEMBERS_LOV**
```sql
SELECT full_name AS display_value, user_id AS return_value
FROM app_users
WHERE role = 'TM' 
  AND is_active = 'Y'
  AND team_id = (SELECT team_id FROM app_users WHERE username = :APP_USER)
ORDER BY full_name
```

**LOV 3: ALL_TEAM_MEMBERS_LOV**
```sql
SELECT full_name || ' (Team ' || team_id || ')' AS display_value, 
       user_id AS return_value
FROM app_users
WHERE role = 'TM' AND is_active = 'Y'
ORDER BY team_id, full_name
```

**LOV 4: TASK_STATUS_LOV**
- Type: `Static`
- Static Values:
  ```
  STATIC:NEW;New,IN_PROGRESS;In Progress,READY_FOR_REVIEW;Ready for Review,PENDING_TL_APPROVAL;Pending TL Approval,PENDING_SENIOR_APPROVAL;Pending Senior Approval,APPROVED;Approved,REJECTED;Rejected,CANCELLED;Cancelled
  ```

**LOV 5: PRIORITY_LOV**
- Type: `Static`
- Static Values:
  ```
  STATIC:LOW;Low,MEDIUM;Medium,HIGH;High,URGENT;Urgent
  ```

**LOV 6: USER_ROLES_LOV**
- Type: `Static`
- Static Values:
  ```
  STATIC:PM;Project Manager,TL;Team Leader,TM;Team Member,SENIOR;Senior
  ```

### Step 13: Create Pages

Now create pages according to `07_apex_pages_structure.sql`.

**Key Pages to Create:**

1. **Page 1: Home Dashboard** - Blank page with welcome message and statistics
2. **Page 10: My Tasks** - Interactive Report for Team Members
3. **Page 11: Task Detail** - Form page with task details
4. **Page 20: Create Task** - Form for Project Manager
5. **Page 30: Manage Tasks** - Interactive Report for Team Leader
6. **Page 31: Assign Task** - Form for Team Leader
7. **Page 40: Pending Approvals** - Interactive Report for TL/Senior
8. **Page 41: Approve/Reject** - Form for approvals
9. **Page 50: All Tasks** - Interactive Report for PM/TL
10. **Page 60: Reports Dashboard** - Charts and analytics
11. **Page 70: Notifications** - Notification center

**Detailed page creation instructions are in `07_apex_pages_structure.sql`**

### Step 14: Create Navigation Menu

1. Go to **Shared Components**
2. Click **Navigation Menu** (or **Lists**)
3. Edit **Desktop Navigation Menu**
4. Add entries:
   - Home (Page 1)
   - My Tasks (Page 10)
   - Create Task (Page 20) - Auth: IS_PM
   - Manage Tasks (Page 30) - Auth: IS_TL
   - Pending Approvals (Page 40) - Auth: IS_TL_OR_SENIOR
   - All Tasks (Page 50) - Auth: IS_PM_OR_TL
   - Reports (Page 60)
   - Notifications (Page 70)

### Step 15: Add Navigation Badges

For menu items showing counts:

**My Tasks Badge:**
```sql
SELECT COUNT(*) FROM tasks 
WHERE assigned_to_tm = :G_USER_ID 
  AND status IN ('IN_PROGRESS', 'REJECTED')
```

**Manage Tasks Badge:**
```sql
SELECT COUNT(*) FROM tasks 
WHERE assigned_to_tl = :G_USER_ID 
  AND status = 'NEW'
```

**Pending Approvals Badge:**
```sql
SELECT COUNT(*) FROM tasks 
WHERE (status = 'PENDING_TL_APPROVAL' AND assigned_to_tl = :G_USER_ID AND :G_USER_ROLE = 'TL')
   OR (status = 'PENDING_SENIOR_APPROVAL' AND :G_USER_ROLE = 'SENIOR')
```

**Notifications Badge:**
```sql
SELECT COUNT(*) FROM task_notifications 
WHERE user_id = :G_USER_ID AND is_read = 'N'
```

---

## Step 16: Create APEX User Accounts

### Create Test Users

1. Go to **Administration** (top right)
2. Click **Manage Users and Groups**
3. Click **Create User**

Create these test accounts:

| Username | Email | Role |
|----------|-------|------|
| PM_JOHN | john.smith@company.com | Developer |
| TL_JAMES | james.williams@company.com | Developer |
| TM_TEAM1_01 | tm.team1.01@company.com | Developer |
| SENIOR_MARY | mary.johnson@company.com | Developer |

Set password for all: `Welcome123!`
Check: "Require Change of Password On First Use"

---

## Step 17: Test the Application

### Test 1: Login as Project Manager

1. Log out if logged in
2. Log in as `PM_JOHN` / `Welcome123!`
3. Verify:
   - ✅ Navigation menu shows "Create Task"
   - ✅ Can access Page 20 (Create Task)
   - ✅ Cannot access Team Member pages

### Test 2: Create a Task

1. Navigate to **Create Task**
2. Fill in:
   - Title: "Test Task Installation"
   - Description: "Testing the task creation process"
   - Assign to TL: Select "James Williams"
   - Priority: High
   - Due Date: Tomorrow
3. Click **Create Task**
4. Verify success message

### Test 3: Login as Team Leader

1. Log out
2. Log in as `TL_JAMES` / `Welcome123!`
3. Go to **Manage Tasks**
4. Verify:
   - ✅ See the test task with status NEW
   - ✅ Can click to assign to team member

### Test 4: Assign Task to Team Member

1. Click **Assign to Team Member**
2. Select "Team Member 1.01"
3. Click **Assign Task**
4. Verify success message
5. Verify status changed to IN_PROGRESS

### Test 5: Login as Team Member

1. Log out
2. Log in as `TM_TEAM1_01` / `Welcome123!`
3. Go to **My Tasks**
4. Verify:
   - ✅ See the assigned task
   - ✅ Status shows "Working" or "In Progress"
   - ✅ Can click to view details

### Test 6: Submit for Review

1. Open the task
2. Add a comment: "Task completed and ready for review"
3. Click **Submit for Review**
4. Verify status changed to PENDING_TL_APPROVAL

### Test 7: Team Leader Approval

1. Log out
2. Log in as `TL_JAMES`
3. Go to **Pending Approvals**
4. Verify task appears
5. Click to review
6. Select **APPROVE**
7. Add comment: "Good work!"
8. Submit
9. Verify status changed to PENDING_SENIOR_APPROVAL

### Test 8: Senior Approval

1. Log out
2. Log in as `SENIOR_MARY`
3. Go to **Pending Approvals**
4. Verify task appears
5. Click to review
6. Select **APPROVE**
7. Add comment: "Excellent!"
8. Submit
9. Verify status changed to APPROVED

### Test 9: Verify Notifications

1. Log in as any user
2. Click **Notifications**
3. Verify notifications appear for:
   - Task assignments
   - Approvals
   - Status changes

### Test 10: Test Rejection Workflow

1. Create another test task
2. Assign to TM
3. TM submits for review
4. TL rejects with comment
5. Verify:
   - ✅ Status changes to REJECTED
   - ✅ TM receives notification
   - ✅ TM can see rejection comment
   - ✅ TM can resubmit

---

## Troubleshooting

### Issue: "ORA-00942: table or view does not exist"

**Solution:**
```sql
-- Check if tables exist
SELECT table_name FROM user_tables WHERE table_name LIKE '%TASK%';

-- If missing, re-run:
@01_create_tables.sql
```

### Issue: "Package has errors"

**Solution:**
```sql
-- Check errors
SHOW ERRORS PACKAGE BODY PKG_TASK_MANAGEMENT;

-- Fix errors and recompile
ALTER PACKAGE pkg_task_management COMPILE BODY;
```

### Issue: "Authorization scheme fails"

**Solution:**
```sql
-- Verify user exists in APP_USERS
SELECT * FROM app_users WHERE username = 'PM_JOHN';

-- If missing, add user:
INSERT INTO app_users (username, full_name, email, role, is_active, created_by)
VALUES ('PM_JOHN', 'John Smith', 'john.smith@company.com', 'PM', 'Y', 'ADMIN');
COMMIT;
```

### Issue: "Cannot log in to APEX"

**Solution:**
1. Ensure APEX account exists
2. Check password
3. Verify workspace is correct
4. Reset password if needed

### Issue: "LOV returns no data"

**Solution:**
```sql
-- Test LOV query directly
SELECT full_name AS display_value, user_id AS return_value
FROM app_users
WHERE role = 'TL' AND is_active = 'Y'
ORDER BY full_name;

-- Should return 6 rows (team leaders)
```

### Issue: "Page not found"

**Solution:**
1. Verify page was created
2. Check page number matches navigation
3. Verify authorization scheme allows access

---

## Post-Installation

### Checklist

- ✅ All database objects created
- ✅ All views return data
- ✅ Package compiled successfully
- ✅ Sample data loaded
- ✅ APEX application created
- ✅ Authorization schemes working
- ✅ LOVs populated
- ✅ All pages created
- ✅ Navigation menu configured
- ✅ User accounts created
- ✅ Full workflow tested
- ✅ Notifications working
- ✅ Reports displaying data

### Next Steps

1. **Customize branding**: Update application logo and theme
2. **Add more users**: Create accounts for all team members
3. **Configure email**: Set up APEX email for notifications
4. **Backup**: Export application for backup
5. **Documentation**: Share user guides with team
6. **Training**: Conduct user training sessions

---

## Backup and Restore

### Backup Application

```bash
# Export from APEX
1. Go to App Builder
2. Click application
3. Click "Export/Import"
4. Click "Export"
5. Save .sql file
```

### Backup Database Objects

```sql
-- Export schema
expdp username/password@database schemas=YOUR_SCHEMA directory=EXPORT_DIR dumpfile=task_mgmt.dmp logfile=task_mgmt.log

-- Or use SQL Developer:
Tools > Database Export > Select objects > Export
```

### Restore

```sql
-- Import schema
impdp username/password@database schemas=YOUR_SCHEMA directory=EXPORT_DIR dumpfile=task_mgmt.dmp logfile=restore.log

-- Import APEX application
1. Go to App Builder
2. Click "Import"
3. Select .sql file
4. Click "Install"
```

---

## Performance Tuning

### Gather Statistics

```sql
-- After loading data
BEGIN
    DBMS_STATS.GATHER_SCHEMA_STATS(ownname => USER, cascade => TRUE);
END;
/
```

### Monitor Performance

```sql
-- Check slow queries
SELECT sql_text, elapsed_time, executions
FROM v$sql
WHERE sql_text LIKE '%tasks%'
ORDER BY elapsed_time DESC;

-- Check table statistics
SELECT table_name, num_rows, last_analyzed
FROM user_tables
WHERE table_name LIKE '%TASK%';
```

---

## Support

### Log Files

Check these locations for errors:
- APEX Debug Messages (turn on Debug mode)
- Database alert log
- APEX error logs

### Getting Help

1. Review README.md
2. Check troubleshooting section
3. Contact database administrator
4. Check Oracle APEX documentation
5. Visit Oracle APEX Community forums

---

## Conclusion

🎉 **Congratulations!** 

Your Task Management System is now installed and ready to use!

You have successfully:
- ✅ Created all database objects
- ✅ Built the APEX application
- ✅ Configured security and authorization
- ✅ Loaded sample data
- ✅ Tested the complete workflow

**Next**: Start using the system with your team!

---

**Installation Guide Version**: 1.0  
**Last Updated**: 2025-10-14  
**Estimated Installation Time**: 2-3 hours
