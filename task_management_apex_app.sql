-- =====================================================
-- ORACLE APEX TASK MANAGEMENT APPLICATION
-- =====================================================
-- This script creates a complete APEX application for task management
-- with approval workflow and role-based access control
-- =====================================================

-- =====================================================
-- 1. APPLICATION CREATION SCRIPT
-- =====================================================

-- Note: This script provides the structure and components.
-- The actual APEX application should be created through APEX Builder
-- using the following specifications:

/*
APPLICATION SPECIFICATIONS:
- Application Name: Task Management System
- Application Alias: TASK_MGMT
- Authentication: Custom (using tm_users table)
- Authorization: Role-based (PM, TL, TM, SENIOR)
- Theme: Universal Theme 42
*/

-- =====================================================
-- 2. AUTHENTICATION SCHEME
-- =====================================================

-- Custom Authentication Function
CREATE OR REPLACE FUNCTION custom_auth_function (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2
) RETURN BOOLEAN
IS
    v_count NUMBER;
    v_user_id NUMBER;
BEGIN
    -- In a real implementation, you would hash the password
    -- For demo purposes, we'll use simple username validation
    SELECT COUNT(*), MAX(user_id)
    INTO v_count, v_user_id
    FROM tm_users 
    WHERE UPPER(username) = UPPER(p_username)
    AND is_active = 'Y';
    
    IF v_count = 1 THEN
        -- Set APEX application items
        APEX_UTIL.SET_SESSION_STATE('G_USER_ID', v_user_id);
        APEX_UTIL.SET_SESSION_STATE('G_USERNAME', UPPER(p_username));
        
        -- Get user role and set session state
        DECLARE
            v_role VARCHAR2(10);
            v_full_name VARCHAR2(200);
        BEGIN
            SELECT role_code, full_name
            INTO v_role, v_full_name
            FROM tm_users
            WHERE user_id = v_user_id;
            
            APEX_UTIL.SET_SESSION_STATE('G_USER_ROLE', v_role);
            APEX_UTIL.SET_SESSION_STATE('G_USER_FULL_NAME', v_full_name);
        END;
        
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
/

-- =====================================================
-- 3. AUTHORIZATION SCHEMES
-- =====================================================

-- Authorization function for Project Managers
CREATE OR REPLACE FUNCTION auth_is_pm RETURN BOOLEAN
IS
BEGIN
    RETURN NVL(APEX_UTIL.GET_SESSION_STATE('G_USER_ROLE'), 'NONE') = 'PM';
END;
/

-- Authorization function for Team Leaders
CREATE OR REPLACE FUNCTION auth_is_tl RETURN BOOLEAN
IS
BEGIN
    RETURN NVL(APEX_UTIL.GET_SESSION_STATE('G_USER_ROLE'), 'NONE') = 'TL';
END;
/

-- Authorization function for Team Members
CREATE OR REPLACE FUNCTION auth_is_tm RETURN BOOLEAN
IS
BEGIN
    RETURN NVL(APEX_UTIL.GET_SESSION_STATE('G_USER_ROLE'), 'NONE') = 'TM';
END;
/

-- Authorization function for Senior
CREATE OR REPLACE FUNCTION auth_is_senior RETURN BOOLEAN
IS
BEGIN
    RETURN NVL(APEX_UTIL.GET_SESSION_STATE('G_USER_ROLE'), 'NONE') = 'SENIOR';
END;
/

-- Authorization function for PM or Senior (admin roles)
CREATE OR REPLACE FUNCTION auth_is_admin RETURN BOOLEAN
IS
BEGIN
    RETURN NVL(APEX_UTIL.GET_SESSION_STATE('G_USER_ROLE'), 'NONE') IN ('PM', 'SENIOR');
END;
/

-- =====================================================
-- 4. APPLICATION PROCESSES
-- =====================================================

-- Process to set user context on login
CREATE OR REPLACE PROCEDURE set_user_context
IS
    v_user_id NUMBER;
    v_role VARCHAR2(10);
    v_full_name VARCHAR2(200);
    v_team_id NUMBER;
BEGIN
    -- Get user details
    SELECT user_id, role_code, full_name, team_id
    INTO v_user_id, v_role, v_full_name, v_team_id
    FROM tm_users
    WHERE UPPER(username) = UPPER(:APP_USER)
    AND is_active = 'Y';
    
    -- Set application items
    :G_USER_ID := v_user_id;
    :G_USER_ROLE := v_role;
    :G_USER_FULL_NAME := v_full_name;
    :G_USER_TEAM_ID := v_team_id;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :G_USER_ID := NULL;
        :G_USER_ROLE := NULL;
        :G_USER_FULL_NAME := NULL;
        :G_USER_TEAM_ID := NULL;
END;
/

-- =====================================================
-- 5. PAGE CREATION TEMPLATES
-- =====================================================

-- The following are the page structures to be created in APEX Builder:

/*
PAGE 1: LOGIN PAGE
- Page Type: Login Page
- Authentication: Not Required
- Template: Login
- Items:
  - P1_USERNAME (Text Field)
  - P1_PASSWORD (Password)
- Buttons:
  - LOGIN (Submit)
- Process: Custom Authentication using custom_auth_function

PAGE 10: DASHBOARD (Home Page)
- Page Type: Blank Page
- Authentication: Required
- Template: Standard
- Regions:
  - Welcome Region (Static Content)
  - Quick Stats (Cards)
  - Recent Tasks (Interactive Report)
- Navigation: Based on user role

PAGE 100: PROJECT MANAGER DASHBOARD
- Authorization: PM Only
- Regions:
  - Task Creation Form
  - All Tasks Report
  - Team Performance Charts
- Items:
  - P100_TITLE (Text Field)
  - P100_DESCRIPTION (Textarea)
  - P100_ASSIGNED_TO_TL (Select List - Team Leaders)
  - P100_PRIORITY (Select List)
  - P100_DUE_DATE (Date Picker)

PAGE 200: TEAM LEADER DASHBOARD
- Authorization: TL Only
- Regions:
  - My Team Tasks
  - Assignment Form
  - Approval Queue
- Items:
  - P200_TASK_ID (Hidden)
  - P200_ASSIGNED_TO_TM (Select List - Team Members)
  - P200_APPROVAL_COMMENTS (Textarea)

PAGE 300: TEAM MEMBER DASHBOARD
- Authorization: TM Only
- Regions:
  - My Tasks
  - Task Details
  - Submit for Review
- Items:
  - P300_TASK_ID (Hidden)
  - P300_WORK_COMMENTS (Textarea)

PAGE 400: SENIOR DASHBOARD
- Authorization: Senior Only
- Regions:
  - Pending Senior Approvals
  - All Tasks Overview
  - Reports and Analytics
- Items:
  - P400_TASK_ID (Hidden)
  - P400_APPROVAL_COMMENTS (Textarea)

PAGE 500: TASK DETAILS
- Authorization: Role-based access
- Regions:
  - Task Information
  - Comments History
  - Approval History
  - Status Timeline
*/

-- =====================================================
-- 6. SHARED COMPONENTS
-- =====================================================

-- List of Values for Team Leaders
CREATE OR REPLACE VIEW lov_team_leaders AS
SELECT user_id as return_value,
       full_name as display_value
FROM tm_users
WHERE role_code = 'TL'
AND is_active = 'Y'
ORDER BY full_name;

-- List of Values for Team Members by Team Leader
CREATE OR REPLACE VIEW lov_team_members AS
SELECT tm.user_id as return_value,
       tm.full_name as display_value,
       tm.manager_id as team_leader_id
FROM tm_users tm
WHERE tm.role_code = 'TM'
AND tm.is_active = 'Y'
ORDER BY tm.full_name;

-- List of Values for Priorities
CREATE OR REPLACE VIEW lov_priorities AS
SELECT 'LOW' as return_value, 'Low' as display_value, 1 as sort_order FROM dual
UNION ALL
SELECT 'MEDIUM' as return_value, 'Medium' as display_value, 2 as sort_order FROM dual
UNION ALL
SELECT 'HIGH' as return_value, 'High' as display_value, 3 as sort_order FROM dual
UNION ALL
SELECT 'URGENT' as return_value, 'Urgent' as display_value, 4 as sort_order FROM dual
ORDER BY sort_order;

-- List of Values for Task Status
CREATE OR REPLACE VIEW lov_task_status AS
SELECT 'NEW' as return_value, 'New' as display_value, 1 as sort_order FROM dual
UNION ALL
SELECT 'IN_PROGRESS' as return_value, 'In Progress' as display_value, 2 as sort_order FROM dual
UNION ALL
SELECT 'READY_FOR_REVIEW' as return_value, 'Ready for Review' as display_value, 3 as sort_order FROM dual
UNION ALL
SELECT 'PENDING_TL_APPROVAL' as return_value, 'Pending TL Approval' as display_value, 4 as sort_order FROM dual
UNION ALL
SELECT 'PENDING_SENIOR_APPROVAL' as return_value, 'Pending Senior Approval' as display_value, 5 as sort_order FROM dual
UNION ALL
SELECT 'APPROVED' as return_value, 'Approved' as display_value, 6 as sort_order FROM dual
UNION ALL
SELECT 'REJECTED' as return_value, 'Rejected' as display_value, 7 as sort_order FROM dual
UNION ALL
SELECT 'CANCELLED' as return_value, 'Cancelled' as display_value, 8 as sort_order FROM dual
ORDER BY sort_order;

-- =====================================================
-- 7. AJAX CALLBACKS AND DYNAMIC ACTIONS
-- =====================================================

-- Function to get team members for a specific team leader
CREATE OR REPLACE FUNCTION get_team_members_json(p_team_leader_id IN NUMBER)
RETURN CLOB
IS
    v_json CLOB;
BEGIN
    SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
            'value' VALUE user_id,
            'label' VALUE full_name
        )
    )
    INTO v_json
    FROM tm_users
    WHERE role_code = 'TM'
    AND manager_id = p_team_leader_id
    AND is_active = 'Y'
    ORDER BY full_name;
    
    RETURN v_json;
END;
/

-- Function to get task details
CREATE OR REPLACE FUNCTION get_task_details_json(p_task_id IN NUMBER)
RETURN CLOB
IS
    v_json CLOB;
BEGIN
    SELECT JSON_OBJECT(
        'task_id' VALUE t.task_id,
        'title' VALUE t.title,
        'description' VALUE t.description,
        'status' VALUE t.status,
        'priority' VALUE t.priority,
        'due_date' VALUE TO_CHAR(t.due_date, 'YYYY-MM-DD'),
        'created_by_name' VALUE creator.full_name,
        'team_leader_name' VALUE tl.full_name,
        'team_member_name' VALUE tm.full_name,
        'created_date' VALUE TO_CHAR(t.created_date, 'YYYY-MM-DD HH24:MI:SS'),
        'updated_date' VALUE TO_CHAR(t.updated_date, 'YYYY-MM-DD HH24:MI:SS')
    )
    INTO v_json
    FROM tm_tasks t
    LEFT JOIN tm_users creator ON t.created_by = creator.user_id
    LEFT JOIN tm_users tl ON t.assigned_to_tl = tl.user_id
    LEFT JOIN tm_users tm ON t.assigned_to_tm = tm.user_id
    WHERE t.task_id = p_task_id;
    
    RETURN v_json;
END;
/

-- =====================================================
-- 8. REPORTS AND QUERIES
-- =====================================================

-- Query for PM Dashboard - All Tasks
CREATE OR REPLACE VIEW rpt_pm_all_tasks AS
SELECT 
    t.task_id,
    t.title,
    t.status,
    t.priority,
    t.due_date,
    t.created_date,
    creator.full_name as created_by_name,
    tl.full_name as team_leader_name,
    tm.full_name as team_member_name,
    CASE 
        WHEN t.due_date < SYSDATE AND t.status NOT IN ('APPROVED', 'CANCELLED') THEN 'OVERDUE'
        WHEN t.due_date <= SYSDATE + 2 AND t.status NOT IN ('APPROVED', 'CANCELLED') THEN 'DUE_SOON'
        ELSE 'ON_TIME'
    END as due_status,
    -- Action buttons based on status
    CASE 
        WHEN t.status = 'NEW' THEN 
            '<button type="button" class="t-Button t-Button--small t-Button--hot" onclick="assignToTL(' || t.task_id || ')">Assign to TL</button>'
        WHEN t.status IN ('PENDING_TL_APPROVAL', 'PENDING_SENIOR_APPROVAL') THEN
            '<button type="button" class="t-Button t-Button--small" onclick="viewTask(' || t.task_id || ')">View</button>'
        ELSE
            '<button type="button" class="t-Button t-Button--small" onclick="viewTask(' || t.task_id || ')">View</button>'
    END as actions
FROM tm_tasks t
LEFT JOIN tm_users creator ON t.created_by = creator.user_id
LEFT JOIN tm_users tl ON t.assigned_to_tl = tl.user_id
LEFT JOIN tm_users tm ON t.assigned_to_tm = tm.user_id
ORDER BY t.created_date DESC;

-- Query for TL Dashboard - Team Tasks
CREATE OR REPLACE VIEW rpt_tl_team_tasks AS
SELECT 
    t.task_id,
    t.title,
    t.status,
    t.priority,
    t.due_date,
    t.created_date,
    creator.full_name as created_by_name,
    tm.full_name as team_member_name,
    CASE 
        WHEN t.due_date < SYSDATE AND t.status NOT IN ('APPROVED', 'CANCELLED') THEN 'OVERDUE'
        WHEN t.due_date <= SYSDATE + 2 AND t.status NOT IN ('APPROVED', 'CANCELLED') THEN 'DUE_SOON'
        ELSE 'ON_TIME'
    END as due_status,
    -- Action buttons based on status
    CASE 
        WHEN t.status = 'NEW' THEN 
            '<button type="button" class="t-Button t-Button--small t-Button--hot" onclick="assignToTM(' || t.task_id || ')">Assign to TM</button>'
        WHEN t.status = 'PENDING_TL_APPROVAL' THEN
            '<button type="button" class="t-Button t-Button--small t-Button--success" onclick="approveTask(' || t.task_id || ')">Approve</button> ' ||
            '<button type="button" class="t-Button t-Button--small t-Button--danger" onclick="rejectTask(' || t.task_id || ')">Reject</button>'
        ELSE
            '<button type="button" class="t-Button t-Button--small" onclick="viewTask(' || t.task_id || ')">View</button>'
    END as actions
FROM tm_tasks t
LEFT JOIN tm_users creator ON t.created_by = creator.user_id
LEFT JOIN tm_users tm ON t.assigned_to_tm = tm.user_id
WHERE t.assigned_to_tl = TO_NUMBER(:G_USER_ID)
ORDER BY t.created_date DESC;

-- Query for TM Dashboard - My Tasks
CREATE OR REPLACE VIEW rpt_tm_my_tasks AS
SELECT 
    t.task_id,
    t.title,
    t.description,
    t.status,
    t.priority,
    t.due_date,
    t.created_date,
    creator.full_name as created_by_name,
    tl.full_name as team_leader_name,
    CASE 
        WHEN t.due_date < SYSDATE AND t.status NOT IN ('APPROVED', 'CANCELLED') THEN 'OVERDUE'
        WHEN t.due_date <= SYSDATE + 2 AND t.status NOT IN ('APPROVED', 'CANCELLED') THEN 'DUE_SOON'
        ELSE 'ON_TIME'
    END as due_status,
    -- Action buttons based on status
    CASE 
        WHEN t.status = 'IN_PROGRESS' THEN 
            '<button type="button" class="t-Button t-Button--small t-Button--hot" onclick="submitForReview(' || t.task_id || ')">Submit for Review</button>'
        WHEN t.status = 'REJECTED' THEN
            '<button type="button" class="t-Button t-Button--small t-Button--hot" onclick="reworkTask(' || t.task_id || ')">Rework</button>'
        ELSE
            '<button type="button" class="t-Button t-Button--small" onclick="viewTask(' || t.task_id || ')">View</button>'
    END as actions
FROM tm_tasks t
LEFT JOIN tm_users creator ON t.created_by = creator.user_id
LEFT JOIN tm_users tl ON t.assigned_to_tl = tl.user_id
WHERE t.assigned_to_tm = TO_NUMBER(:G_USER_ID)
ORDER BY t.created_date DESC;

-- Query for Senior Dashboard - Pending Approvals
CREATE OR REPLACE VIEW rpt_senior_approvals AS
SELECT 
    t.task_id,
    t.title,
    t.status,
    t.priority,
    t.due_date,
    t.created_date,
    creator.full_name as created_by_name,
    tl.full_name as team_leader_name,
    tm.full_name as team_member_name,
    a.created_date as approval_requested_date,
    CASE 
        WHEN t.due_date < SYSDATE AND t.status NOT IN ('APPROVED', 'CANCELLED') THEN 'OVERDUE'
        WHEN t.due_date <= SYSDATE + 2 AND t.status NOT IN ('APPROVED', 'CANCELLED') THEN 'DUE_SOON'
        ELSE 'ON_TIME'
    END as due_status,
    -- Action buttons
    '<button type="button" class="t-Button t-Button--small t-Button--success" onclick="approveFinalTask(' || t.task_id || ')">Approve</button> ' ||
    '<button type="button" class="t-Button t-Button--small t-Button--danger" onclick="rejectFinalTask(' || t.task_id || ')">Reject</button>' as actions
FROM tm_tasks t
LEFT JOIN tm_users creator ON t.created_by = creator.user_id
LEFT JOIN tm_users tl ON t.assigned_to_tl = tl.user_id
LEFT JOIN tm_users tm ON t.assigned_to_tm = tm.user_id
LEFT JOIN tm_approvals a ON t.task_id = a.task_id AND a.approval_level = 2 AND a.status = 'PENDING'
WHERE t.status = 'PENDING_SENIOR_APPROVAL'
ORDER BY a.created_date ASC;

-- =====================================================
-- 9. NOTIFICATION FUNCTIONS
-- =====================================================

-- Function to get unread notification count
CREATE OR REPLACE FUNCTION get_unread_notification_count(p_user_id IN NUMBER)
RETURN NUMBER
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM tm_notifications
    WHERE user_id = p_user_id
    AND is_read = 'N';
    
    RETURN v_count;
END;
/

-- Function to mark notification as read
CREATE OR REPLACE PROCEDURE mark_notification_read(p_notification_id IN NUMBER)
IS
BEGIN
    UPDATE tm_notifications
    SET is_read = 'Y',
        read_date = SYSDATE
    WHERE notification_id = p_notification_id;
    
    COMMIT;
END;
/

-- =====================================================
-- 10. DASHBOARD STATISTICS
-- =====================================================

-- Function to get dashboard statistics
CREATE OR REPLACE FUNCTION get_dashboard_stats(p_user_id IN NUMBER, p_role IN VARCHAR2)
RETURN CLOB
IS
    v_stats CLOB;
BEGIN
    CASE p_role
        WHEN 'PM' THEN
            SELECT JSON_OBJECT(
                'total_tasks' VALUE COUNT(*),
                'new_tasks' VALUE SUM(CASE WHEN status = 'NEW' THEN 1 ELSE 0 END),
                'in_progress' VALUE SUM(CASE WHEN status = 'IN_PROGRESS' THEN 1 ELSE 0 END),
                'pending_approval' VALUE SUM(CASE WHEN status LIKE 'PENDING%' THEN 1 ELSE 0 END),
                'approved' VALUE SUM(CASE WHEN status = 'APPROVED' THEN 1 ELSE 0 END),
                'overdue' VALUE SUM(CASE WHEN due_date < SYSDATE AND status NOT IN ('APPROVED', 'CANCELLED') THEN 1 ELSE 0 END)
            )
            INTO v_stats
            FROM tm_tasks
            WHERE created_by = p_user_id;
            
        WHEN 'TL' THEN
            SELECT JSON_OBJECT(
                'total_tasks' VALUE COUNT(*),
                'assigned_to_me' VALUE SUM(CASE WHEN assigned_to_tl = p_user_id THEN 1 ELSE 0 END),
                'pending_my_approval' VALUE SUM(CASE WHEN status = 'PENDING_TL_APPROVAL' AND assigned_to_tl = p_user_id THEN 1 ELSE 0 END),
                'team_in_progress' VALUE SUM(CASE WHEN status = 'IN_PROGRESS' AND assigned_to_tl = p_user_id THEN 1 ELSE 0 END),
                'team_completed' VALUE SUM(CASE WHEN status = 'APPROVED' AND assigned_to_tl = p_user_id THEN 1 ELSE 0 END)
            )
            INTO v_stats
            FROM tm_tasks;
            
        WHEN 'TM' THEN
            SELECT JSON_OBJECT(
                'my_tasks' VALUE COUNT(*),
                'in_progress' VALUE SUM(CASE WHEN status = 'IN_PROGRESS' THEN 1 ELSE 0 END),
                'pending_review' VALUE SUM(CASE WHEN status LIKE 'PENDING%' THEN 1 ELSE 0 END),
                'completed' VALUE SUM(CASE WHEN status = 'APPROVED' THEN 1 ELSE 0 END),
                'rejected' VALUE SUM(CASE WHEN status = 'REJECTED' THEN 1 ELSE 0 END)
            )
            INTO v_stats
            FROM tm_tasks
            WHERE assigned_to_tm = p_user_id;
            
        WHEN 'SENIOR' THEN
            SELECT JSON_OBJECT(
                'total_tasks' VALUE COUNT(*),
                'pending_my_approval' VALUE SUM(CASE WHEN status = 'PENDING_SENIOR_APPROVAL' THEN 1 ELSE 0 END),
                'approved_by_me' VALUE (SELECT COUNT(*) FROM tm_approvals WHERE approver_id = p_user_id AND approval_level = 2 AND status = 'APPROVED'),
                'rejected_by_me' VALUE (SELECT COUNT(*) FROM tm_approvals WHERE approver_id = p_user_id AND approval_level = 2 AND status = 'REJECTED'),
                'overall_completion_rate' VALUE ROUND((SUM(CASE WHEN status = 'APPROVED' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2)
            )
            INTO v_stats
            FROM tm_tasks;
    END CASE;
    
    RETURN v_stats;
END;
/

-- =====================================================
-- COMMIT ALL CHANGES
-- =====================================================
COMMIT;

-- Display completion message
SELECT 'APEX Application components created successfully!' as status FROM dual;
SELECT 'Authentication and authorization functions ready' as auth_status FROM dual;
SELECT 'Views and reports created for all user roles' as views_status FROM dual;
SELECT 'Business logic functions and procedures ready' as logic_status FROM dual;