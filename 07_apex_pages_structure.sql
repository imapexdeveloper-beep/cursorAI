-- =============================================
-- Task Management System - APEX Pages Structure
-- =============================================
-- Detailed structure for each page in the application
-- =============================================

-- =============================================
-- PAGE 1: HOME DASHBOARD
-- =============================================
/*
Page Type: Blank Page
Authorization: None

Regions:
1. Welcome Message (Static Content)
   - Display welcome message with user name: :G_USER_FULL_NAME
   - Show current role
   
2. My Task Statistics (Cards Region)
   SQL Query:
*/
SELECT 
    (SELECT COUNT(*) FROM tasks WHERE assigned_to_tm = :G_USER_ID AND status = 'IN_PROGRESS') as in_progress_count,
    (SELECT COUNT(*) FROM tasks WHERE assigned_to_tm = :G_USER_ID AND status = 'REJECTED') as rejected_count,
    (SELECT COUNT(*) FROM tasks WHERE assigned_to_tm = :G_USER_ID AND status = 'APPROVED') as approved_count,
    (SELECT COUNT(*) FROM task_notifications WHERE user_id = :G_USER_ID AND is_read = 'N') as unread_notifications
FROM dual;

/*
3. Tasks Requiring Action (Interactive Report)
   Authorization: Based on role
   SQL Query:
*/
SELECT 
    task_id,
    title,
    status,
    priority,
    CASE 
        WHEN :G_USER_ROLE = 'PM' THEN 'Tasks Assigned to Team Leaders'
        WHEN :G_USER_ROLE = 'TL' AND status = 'NEW' THEN 'New Tasks to Assign'
        WHEN :G_USER_ROLE = 'TL' AND status = 'PENDING_TL_APPROVAL' THEN 'Tasks Awaiting Your Approval'
        WHEN :G_USER_ROLE = 'TM' THEN 'Your Active Tasks'
        WHEN :G_USER_ROLE = 'SENIOR' AND status = 'PENDING_SENIOR_APPROVAL' THEN 'Tasks Awaiting Your Approval'
    END as action_required,
    assigned_tl_name,
    assigned_tm_name,
    days_until_due
FROM v_task_dashboard
WHERE (
    (:G_USER_ROLE = 'PM' AND created_by = :APP_USER)
    OR (:G_USER_ROLE = 'TL' AND tl_user_id = :G_USER_ID AND status IN ('NEW', 'PENDING_TL_APPROVAL'))
    OR (:G_USER_ROLE = 'TM' AND tm_user_id = :G_USER_ID AND status IN ('IN_PROGRESS', 'REJECTED'))
    OR (:G_USER_ROLE = 'SENIOR' AND status = 'PENDING_SENIOR_APPROVAL')
)
ORDER BY 
    CASE status 
        WHEN 'PENDING_SENIOR_APPROVAL' THEN 1
        WHEN 'PENDING_TL_APPROVAL' THEN 2
        WHEN 'REJECTED' THEN 3
        WHEN 'NEW' THEN 4
        WHEN 'IN_PROGRESS' THEN 5
    END,
    created_date DESC;

-- =============================================
-- PAGE 10: MY TASKS (Team Member View)
-- =============================================
/*
Page Type: Interactive Report
Authorization: None

Main Region: My Tasks (Interactive Report)
SQL Query:
*/
SELECT 
    task_id,
    title,
    description,
    status,
    priority,
    assigned_tl_name as "Team Leader",
    created_date,
    assigned_to_tm_date as "Assigned Date",
    submitted_date,
    due_date,
    days_until_due,
    status_indicator,
    CASE 
        WHEN status = 'IN_PROGRESS' THEN 'Working'
        WHEN status = 'REJECTED' THEN 'Rework Required'
        WHEN status = 'PENDING_TL_APPROVAL' THEN 'Under Review'
        WHEN status = 'PENDING_SENIOR_APPROVAL' THEN 'Senior Review'
        WHEN status = 'APPROVED' THEN 'Completed'
    END as my_status
FROM v_task_dashboard
WHERE tm_user_id = :G_USER_ID
ORDER BY 
    CASE status 
        WHEN 'REJECTED' THEN 1
        WHEN 'IN_PROGRESS' THEN 2
        WHEN 'PENDING_TL_APPROVAL' THEN 3
        WHEN 'PENDING_SENIOR_APPROVAL' THEN 4
        WHEN 'APPROVED' THEN 5
    END,
    due_date NULLS LAST;

/*
Buttons:
- Submit for Review (Condition: status = 'IN_PROGRESS')
- View Details (Always visible)

Interactive Report Actions:
- Link to Page 11 (Task Detail) passing TASK_ID
*/

-- =============================================
-- PAGE 11: TASK DETAIL (All Users)
-- =============================================
/*
Page Type: Form
Authorization: None
Primary Key: TASK_ID (Page Item: P11_TASK_ID)

Regions:
1. Task Information (Form Region)
   Source: v_task_dashboard
   
Items:
- P11_TASK_ID (Hidden)
- P11_TITLE (Display Only)
- P11_DESCRIPTION (Display Only - Rich Text Editor)
- P11_STATUS (Display Only with badge)
- P11_PRIORITY (Display Only with badge)
- P11_CREATED_BY_NAME (Display Only)
- P11_CREATED_DATE (Display Only)
- P11_ASSIGNED_TL_NAME (Display Only)
- P11_ASSIGNED_TM_NAME (Display Only)
- P11_DUE_DATE (Display Only)
- P11_DAYS_UNTIL_DUE (Display Only)

2. Task Comments (Interactive Report)
   SQL Query:
*/
SELECT 
    comment_date,
    commented_by,
    u.full_name as commenter_name,
    comment_type,
    comment_text
FROM task_comments tc
JOIN app_users u ON tc.commented_by_user_id = u.user_id
WHERE task_id = :P11_TASK_ID
ORDER BY comment_date DESC;

/*
3. Add Comment (Form Region - Visible based on authorization)
Items:
- P11_COMMENT_TEXT (Textarea)
- P11_COMMENT_TYPE (Select List - GENERAL, REJECTION, APPROVAL, STATUS_CHANGE)

4. Approval History (Interactive Report)
   SQL Query:
*/
SELECT 
    approval_date,
    approval_level,
    u.full_name as approver_name,
    approval_status,
    comments
FROM task_approvals ta
JOIN app_users u ON ta.approver_id = u.user_id
WHERE task_id = :P11_TASK_ID
ORDER BY approval_date DESC;

/*
Buttons (Dynamic based on role and status):
- Submit for Review (TM, status = IN_PROGRESS)
- Approve (TL/Senior, status = PENDING_*_APPROVAL)
- Reject (TL/Senior, status = PENDING_*_APPROVAL)
- Cancel Task (PM, status not in APPROVED/CANCELLED)
- Back (Always)

Processes:
- Submit for Review Process
- Approve Process
- Reject Process
- Add Comment Process
*/

-- =============================================
-- PAGE 20: CREATE TASK (Project Manager)
-- =============================================
/*
Page Type: Form
Authorization: IS_PM

Region: Create New Task
Items:
- P20_TITLE (Text Field - Required)
- P20_DESCRIPTION (Rich Text Editor - Required)
- P20_ASSIGNED_TO_TL (Select List - LOV: TEAM_LEADERS_LOV - Required)
- P20_PRIORITY (Select List - LOV: PRIORITY_LOV - Default: MEDIUM)
- P20_DUE_DATE (Date Picker)

Buttons:
- Create Task
- Cancel

Process: Create Task
Type: PL/SQL
*/
DECLARE
    v_task_id NUMBER;
BEGIN
    pkg_task_management.create_task(
        p_title => :P20_TITLE,
        p_description => :P20_DESCRIPTION,
        p_assigned_to_tl => :P20_ASSIGNED_TO_TL,
        p_priority => :P20_PRIORITY,
        p_due_date => :P20_DUE_DATE,
        p_created_by => :APP_USER,
        p_task_id => v_task_id
    );
    
    apex_application.g_print_success_message := 'Task created successfully! Task ID: ' || v_task_id;
END;

-- =============================================
-- PAGE 30: MANAGE TASKS (Team Leader)
-- =============================================
/*
Page Type: Interactive Report
Authorization: IS_TL

Region: My Team Tasks
SQL Query:
*/
SELECT 
    task_id,
    title,
    status,
    priority,
    assigned_tm_name,
    created_by_name,
    created_date,
    assigned_to_tm_date,
    due_date,
    days_until_due,
    status_indicator,
    CASE 
        WHEN status = 'NEW' THEN 'Assign to Team Member'
        WHEN status = 'IN_PROGRESS' THEN 'In Progress'
        WHEN status = 'PENDING_TL_APPROVAL' THEN 'Review Required'
        ELSE status
    END as action_status
FROM v_task_dashboard
WHERE tl_user_id = :G_USER_ID
  AND status NOT IN ('CANCELLED', 'APPROVED')
ORDER BY 
    CASE status 
        WHEN 'PENDING_TL_APPROVAL' THEN 1
        WHEN 'NEW' THEN 2
        WHEN 'IN_PROGRESS' THEN 3
        ELSE 4
    END,
    priority DESC,
    due_date NULLS LAST;

/*
Actions:
- Assign to Team Member (for NEW tasks) - Opens Page 31
- Review Task (for PENDING_TL_APPROVAL) - Opens Page 11
- View Details - Opens Page 11
*/

-- =============================================
-- PAGE 31: ASSIGN TASK TO TEAM MEMBER (Team Leader)
-- =============================================
/*
Page Type: Form
Authorization: IS_TL
Primary Key: P31_TASK_ID

Items:
- P31_TASK_ID (Hidden)
- P31_TITLE (Display Only)
- P31_DESCRIPTION (Display Only)
- P31_ASSIGNED_TO_TM (Select List - LOV: TEAM_MEMBERS_LOV - Required)

Buttons:
- Assign Task
- Cancel

Process: Assign Task to TM
*/
BEGIN
    pkg_task_management.assign_task_to_tm(
        p_task_id => :P31_TASK_ID,
        p_assigned_to_tm => :P31_ASSIGNED_TO_TM,
        p_assigned_by => :APP_USER
    );
    
    apex_application.g_print_success_message := 'Task assigned successfully!';
END;

-- =============================================
-- PAGE 40: PENDING APPROVALS (TL & Senior)
-- =============================================
/*
Page Type: Interactive Report
Authorization: IS_TL_OR_SENIOR

Region: Tasks Pending My Approval
SQL Query:
*/
SELECT 
    t.task_id,
    t.title,
    t.description,
    t.status,
    t.priority,
    t.submitted_by,
    t.submitted_by_email,
    t.required_approval_level,
    t.team_leader_name,
    t.days_pending,
    CASE 
        WHEN t.days_pending > 2 THEN 'Urgent Review'
        WHEN t.days_pending > 1 THEN 'Review Soon'
        ELSE 'Recently Submitted'
    END as urgency
FROM v_pending_approvals t
WHERE (
    (t.status = 'PENDING_TL_APPROVAL' AND t.required_approval_level = 'TL' 
     AND EXISTS (SELECT 1 FROM tasks WHERE task_id = t.task_id AND assigned_to_tl = :G_USER_ID))
    OR 
    (t.status = 'PENDING_SENIOR_APPROVAL' AND t.required_approval_level = 'SENIOR' AND :G_USER_ROLE = 'SENIOR')
)
ORDER BY t.days_pending DESC, t.priority DESC;

/*
Actions:
- Review & Approve/Reject - Opens Page 41
*/

-- =============================================
-- PAGE 41: APPROVE/REJECT TASK (TL & Senior)
-- =============================================
/*
Page Type: Form
Authorization: IS_TL_OR_SENIOR

Items:
- P41_TASK_ID (Hidden)
- P41_TITLE (Display Only)
- P41_DESCRIPTION (Display Only - Rich Text)
- P41_PRIORITY (Display Only)
- P41_SUBMITTED_BY (Display Only)
- P41_SUBMITTED_DATE (Display Only)
- P41_COMMENTS (Textarea - Required for Rejection)
- P41_ACTION (Radio Group - APPROVE/REJECT)

Buttons:
- Submit Decision
- Cancel

Process: Process Approval Decision
*/
DECLARE
    v_approver_id NUMBER;
BEGIN
    v_approver_id := :G_USER_ID;
    
    IF :P41_ACTION = 'APPROVE' THEN
        IF :G_USER_ROLE = 'TL' THEN
            pkg_task_management.approve_task_tl(
                p_task_id => :P41_TASK_ID,
                p_approver_id => v_approver_id,
                p_comments => :P41_COMMENTS
            );
        ELSIF :G_USER_ROLE = 'SENIOR' THEN
            pkg_task_management.approve_task_senior(
                p_task_id => :P41_TASK_ID,
                p_approver_id => v_approver_id,
                p_comments => :P41_COMMENTS
            );
        END IF;
        apex_application.g_print_success_message := 'Task approved successfully!';
    ELSIF :P41_ACTION = 'REJECT' THEN
        IF :P41_COMMENTS IS NULL THEN
            raise_application_error(-20001, 'Comments are required for rejection');
        END IF;
        
        IF :G_USER_ROLE = 'TL' THEN
            pkg_task_management.reject_task_tl(
                p_task_id => :P41_TASK_ID,
                p_approver_id => v_approver_id,
                p_comments => :P41_COMMENTS
            );
        ELSIF :G_USER_ROLE = 'SENIOR' THEN
            pkg_task_management.reject_task_senior(
                p_task_id => :P41_TASK_ID,
                p_approver_id => v_approver_id,
                p_comments => :P41_COMMENTS
            );
        END IF;
        apex_application.g_print_success_message := 'Task rejected. Team member has been notified.';
    END IF;
END;

-- =============================================
-- PAGE 50: ALL TASKS (PM & TL)
-- =============================================
/*
Page Type: Interactive Report
Authorization: IS_PM_OR_TL

Region: All Tasks Overview
SQL Query:
*/
SELECT 
    task_id,
    title,
    description,
    status,
    priority,
    created_by_name,
    created_date,
    assigned_tl_name,
    assigned_tm_name,
    submitted_date,
    tl_approval_date,
    tl_approver_name,
    senior_approval_date,
    senior_approver_name,
    due_date,
    days_until_due,
    status_indicator,
    completed_date
FROM v_task_dashboard
WHERE (:G_USER_ROLE = 'PM' AND created_by_user_id = :G_USER_ID)
   OR (:G_USER_ROLE = 'TL' AND tl_user_id = :G_USER_ID)
ORDER BY created_date DESC;

/*
Features:
- Search across all columns
- Filter by status, priority
- Sort by any column
- Export to Excel/PDF
*/

-- =============================================
-- PAGE 60: REPORTS DASHBOARD
-- =============================================
/*
Page Type: Multiple Regions

1. Tasks by Status (Chart - Pie)
*/
SELECT status, COUNT(*) as count
FROM tasks
WHERE (:G_USER_ROLE = 'PM' AND created_by = :APP_USER)
   OR (:G_USER_ROLE = 'TL' AND assigned_to_tl = :G_USER_ID)
   OR (:G_USER_ROLE = 'TM' AND assigned_to_tm = :G_USER_ID)
   OR :G_USER_ROLE = 'SENIOR'
GROUP BY status;

/*
2. Tasks by Priority (Chart - Bar)
*/
SELECT priority, COUNT(*) as count
FROM tasks
WHERE (:G_USER_ROLE = 'PM' AND created_by = :APP_USER)
   OR (:G_USER_ROLE = 'TL' AND assigned_to_tl = :G_USER_ID)
   OR (:G_USER_ROLE = 'TM' AND assigned_to_tm = :G_USER_ID)
   OR :G_USER_ROLE = 'SENIOR'
GROUP BY priority
ORDER BY CASE priority 
    WHEN 'URGENT' THEN 1 
    WHEN 'HIGH' THEN 2 
    WHEN 'MEDIUM' THEN 3 
    WHEN 'LOW' THEN 4 
END;

/*
3. Team Performance (for PM/Senior)
*/
SELECT 
    tl.full_name as team_leader,
    COUNT(t.task_id) as total_tasks,
    SUM(CASE WHEN t.status = 'APPROVED' THEN 1 ELSE 0 END) as approved_tasks,
    SUM(CASE WHEN t.status = 'REJECTED' THEN 1 ELSE 0 END) as rejected_tasks,
    SUM(CASE WHEN t.status IN ('IN_PROGRESS', 'PENDING_TL_APPROVAL', 'PENDING_SENIOR_APPROVAL') THEN 1 ELSE 0 END) as in_progress_tasks
FROM tasks t
JOIN app_users tl ON t.assigned_to_tl = tl.user_id
GROUP BY tl.full_name
ORDER BY total_tasks DESC;

-- =============================================
-- PAGE 70: NOTIFICATIONS
-- =============================================
/*
Page Type: Interactive Report

Region: My Notifications
SQL Query:
*/
SELECT 
    notification_id,
    task_id,
    notification_type,
    notification_text,
    is_read,
    created_date,
    read_date,
    CASE WHEN is_read = 'N' THEN 'Unread' ELSE 'Read' END as status
FROM task_notifications
WHERE user_id = :G_USER_ID
ORDER BY 
    CASE WHEN is_read = 'N' THEN 0 ELSE 1 END,
    created_date DESC;

/*
Actions:
- Mark as Read
- View Task (Link to Page 11)
- Mark All as Read (Page Button)
*/

COMMIT;
