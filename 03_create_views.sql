-- =============================================
-- Task Management System - Views
-- =============================================

-- Drop existing views
BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW v_task_dashboard';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW v_my_tasks';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW v_pending_approvals';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW v_task_history';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- =============================================
-- Main Task Dashboard View
-- =============================================
CREATE OR REPLACE VIEW v_task_dashboard AS
SELECT 
    t.task_id,
    t.title,
    t.description,
    t.status,
    t.priority,
    t.created_by,
    t.created_date,
    t.due_date,
    
    -- Creator info
    creator.full_name as created_by_name,
    creator.role as creator_role,
    
    -- Team Leader info
    tl.user_id as tl_user_id,
    tl.full_name as assigned_tl_name,
    tl.email as assigned_tl_email,
    t.assigned_to_tl_date,
    
    -- Team Member info
    tm.user_id as tm_user_id,
    tm.full_name as assigned_tm_name,
    tm.email as assigned_tm_email,
    tm.team_id as tm_team_id,
    t.assigned_to_tm_date,
    
    -- Approval info
    t.submitted_date,
    t.tl_approval_date,
    tl_approver.full_name as tl_approver_name,
    t.senior_approval_date,
    senior_approver.full_name as senior_approver_name,
    
    -- Time calculations
    CASE 
        WHEN t.status = 'APPROVED' THEN t.completed_date
        ELSE NULL 
    END as completed_date,
    
    CASE 
        WHEN t.due_date IS NOT NULL AND t.status NOT IN ('APPROVED', 'CANCELLED') THEN
            ROUND(t.due_date - SYSDATE, 1)
        ELSE NULL 
    END as days_until_due,
    
    ROUND(SYSDATE - t.created_date, 1) as days_since_created,
    
    -- Status indicators
    CASE 
        WHEN t.due_date < SYSDATE AND t.status NOT IN ('APPROVED', 'CANCELLED') THEN 'OVERDUE'
        WHEN t.due_date - SYSDATE <= 2 AND t.status NOT IN ('APPROVED', 'CANCELLED') THEN 'DUE_SOON'
        ELSE 'ON_TIME'
    END as status_indicator,
    
    t.last_updated_date,
    t.last_updated_by
FROM tasks t
LEFT JOIN app_users creator ON t.created_by_user_id = creator.user_id
LEFT JOIN app_users tl ON t.assigned_to_tl = tl.user_id
LEFT JOIN app_users tm ON t.assigned_to_tm = tm.user_id
LEFT JOIN app_users tl_approver ON t.tl_approved_by = tl_approver.user_id
LEFT JOIN app_users senior_approver ON t.senior_approved_by = senior_approver.user_id;

-- =============================================
-- My Tasks View (for current user)
-- =============================================
CREATE OR REPLACE VIEW v_my_tasks AS
SELECT 
    vt.*,
    CASE 
        WHEN vt.creator_role = 'PM' AND vt.created_by = :APP_USER THEN 'CREATED'
        WHEN vt.tl_user_id = (SELECT user_id FROM app_users WHERE username = :APP_USER) THEN 'ASSIGNED_AS_TL'
        WHEN vt.tm_user_id = (SELECT user_id FROM app_users WHERE username = :APP_USER) THEN 'ASSIGNED_AS_TM'
        ELSE 'OTHER'
    END as user_relationship
FROM v_task_dashboard vt;

-- =============================================
-- Pending Approvals View
-- =============================================
CREATE OR REPLACE VIEW v_pending_approvals AS
SELECT 
    t.task_id,
    t.title,
    t.description,
    t.status,
    t.priority,
    t.submitted_date,
    
    -- Submitter info
    tm.full_name as submitted_by,
    tm.email as submitted_by_email,
    
    -- Approval level
    CASE 
        WHEN t.status = 'PENDING_TL_APPROVAL' THEN 'TL'
        WHEN t.status = 'PENDING_SENIOR_APPROVAL' THEN 'SENIOR'
        ELSE NULL
    END as required_approval_level,
    
    -- Team Leader info (for senior approval)
    tl.full_name as team_leader_name,
    tl.email as team_leader_email,
    
    ROUND(SYSDATE - t.submitted_date, 1) as days_pending
FROM tasks t
LEFT JOIN app_users tm ON t.assigned_to_tm = tm.user_id
LEFT JOIN app_users tl ON t.assigned_to_tl = tl.user_id
WHERE t.status IN ('PENDING_TL_APPROVAL', 'PENDING_SENIOR_APPROVAL');

-- =============================================
-- Task History View (with comments and approvals)
-- =============================================
CREATE OR REPLACE VIEW v_task_history AS
SELECT 
    t.task_id,
    t.title,
    'TASK_CREATED' as event_type,
    t.created_by as event_by,
    t.created_date as event_date,
    'Task created and assigned to ' || tl.full_name as event_description,
    NULL as event_comment
FROM tasks t
LEFT JOIN app_users tl ON t.assigned_to_tl = tl.user_id

UNION ALL

SELECT 
    t.task_id,
    t.title,
    'ASSIGNED_TO_TM' as event_type,
    tl.username as event_by,
    t.assigned_to_tm_date as event_date,
    'Task assigned to team member: ' || tm.full_name as event_description,
    NULL as event_comment
FROM tasks t
LEFT JOIN app_users tm ON t.assigned_to_tm = tm.user_id
LEFT JOIN app_users tl ON t.assigned_to_tl = tl.user_id
WHERE t.assigned_to_tm_date IS NOT NULL

UNION ALL

SELECT 
    tc.task_id,
    t.title,
    'COMMENT' as event_type,
    tc.commented_by as event_by,
    tc.comment_date as event_date,
    'Comment added (' || tc.comment_type || ')' as event_description,
    tc.comment_text as event_comment
FROM task_comments tc
JOIN tasks t ON tc.task_id = t.task_id

UNION ALL

SELECT 
    ta.task_id,
    t.title,
    'APPROVAL_' || ta.approval_level as event_type,
    u.username as event_by,
    ta.approval_date as event_date,
    ta.approval_level || ' ' || ta.approval_status as event_description,
    ta.comments as event_comment
FROM task_approvals ta
JOIN tasks t ON ta.task_id = t.task_id
JOIN app_users u ON ta.approver_id = u.user_id

ORDER BY task_id, event_date DESC;

COMMIT;
