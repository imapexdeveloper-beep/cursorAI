-- =====================================================
-- ORACLE APEX TASK MANAGEMENT - DETAILED PAGE STRUCTURES
-- =====================================================
-- This script provides detailed specifications for each APEX page
-- including regions, items, processes, and dynamic actions
-- =====================================================

-- =====================================================
-- PAGE 1: LOGIN PAGE
-- =====================================================
/*
Page Properties:
- Page Number: 1
- Page Name: Login
- Page Template: Login
- Authentication: Not Required

Regions:
1. Login Region
   - Template: Login
   - Source: Static Content

Items:
1. P1_USERNAME
   - Type: Text Field
   - Label: Username
   - Required: Yes
   - Maximum Length: 100

2. P1_PASSWORD
   - Type: Password
   - Label: Password
   - Required: Yes
   - Maximum Length: 100

Buttons:
1. LOGIN
   - Button Template: Hot
   - Hot: Yes
   - Action: Submit Page

Processes:
1. Login Process
   - Type: PL/SQL Code
   - Point: Processing
   - Code: See below
*/

-- Login Process Code
CREATE OR REPLACE PROCEDURE process_login
IS
    v_username VARCHAR2(100) := :P1_USERNAME;
    v_password VARCHAR2(100) := :P1_PASSWORD;
    v_user_id NUMBER;
    v_role VARCHAR2(10);
    v_full_name VARCHAR2(200);
    v_team_id NUMBER;
BEGIN
    -- Validate user (in real implementation, check hashed password)
    SELECT user_id, role_code, full_name, team_id
    INTO v_user_id, v_role, v_full_name, v_team_id
    FROM tm_users
    WHERE UPPER(username) = UPPER(v_username)
    AND is_active = 'Y';
    
    -- Set session state
    APEX_UTIL.SET_SESSION_STATE('G_USER_ID', v_user_id);
    APEX_UTIL.SET_SESSION_STATE('G_USER_ROLE', v_role);
    APEX_UTIL.SET_SESSION_STATE('G_USER_FULL_NAME', v_full_name);
    APEX_UTIL.SET_SESSION_STATE('G_USER_TEAM_ID', v_team_id);
    
    -- Set APEX username
    APEX_UTIL.SET_AUTHENTICATION_RESULT(0);
    
    -- Redirect based on role
    CASE v_role
        WHEN 'PM' THEN
            APEX_UTIL.REDIRECT_URL('f?p=&APP_ID.:100:&SESSION.');
        WHEN 'TL' THEN
            APEX_UTIL.REDIRECT_URL('f?p=&APP_ID.:200:&SESSION.');
        WHEN 'TM' THEN
            APEX_UTIL.REDIRECT_URL('f?p=&APP_ID.:300:&SESSION.');
        WHEN 'SENIOR' THEN
            APEX_UTIL.REDIRECT_URL('f?p=&APP_ID.:400:&SESSION.');
        ELSE
            APEX_UTIL.REDIRECT_URL('f?p=&APP_ID.:10:&SESSION.');
    END CASE;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        APEX_UTIL.SET_SESSION_STATE('P1_LOGIN_MESSAGE', 'Invalid username or password');
    WHEN OTHERS THEN
        APEX_UTIL.SET_SESSION_STATE('P1_LOGIN_MESSAGE', 'Login error occurred');
END;
/

-- =====================================================
-- PAGE 10: MAIN DASHBOARD
-- =====================================================
/*
Page Properties:
- Page Number: 10
- Page Name: Dashboard
- Page Template: Standard
- Authentication: Required

Regions:
1. Welcome Region
   - Template: Hero
   - Title: Welcome &G_USER_FULL_NAME.
   - Content: Dynamic based on role

2. Quick Stats
   - Template: Cards Container
   - Source: Function returning JSON

3. Recent Activities
   - Template: Interactive Report
   - Source: Query based on user role

Navigation:
- Based on user role, show appropriate menu items
*/

-- =====================================================
-- PAGE 100: PROJECT MANAGER DASHBOARD
-- =====================================================
/*
Page Properties:
- Page Number: 100
- Page Name: Project Manager Dashboard
- Authorization: PM Only
- Page Template: Standard

Regions:
1. Page Header
   - Template: Hero
   - Title: Project Manager Dashboard
   - Subtitle: Manage tasks and monitor team performance

2. Quick Actions
   - Template: Buttons Container
   - Buttons: Create Task, View All Tasks, Reports

3. Create New Task Form
   - Template: Standard
   - Items: See below

4. All Tasks Report
   - Template: Interactive Report
   - Source: rpt_pm_all_tasks view

5. Team Performance Charts
   - Template: Chart
   - Chart Type: Donut
   - Source: Task status distribution
*/

-- Create Task Form Items for PM Dashboard
/*
Items for Create Task Form:
1. P100_TITLE
   - Type: Text Field
   - Label: Task Title
   - Required: Yes
   - Maximum Length: 500

2. P100_DESCRIPTION
   - Type: Textarea
   - Label: Description
   - Height: 5 rows

3. P100_ASSIGNED_TO_TL
   - Type: Select List
   - Label: Assign to Team Leader
   - LOV: lov_team_leaders
   - Display Null: Yes
   - Null Display Value: -- Select Team Leader --

4. P100_PRIORITY
   - Type: Select List
   - Label: Priority
   - LOV: lov_priorities
   - Default: MEDIUM

5. P100_DUE_DATE
   - Type: Date Picker
   - Label: Due Date
   - Format: DD-MON-YYYY
*/

-- Process to Create Task (PM)
CREATE OR REPLACE PROCEDURE process_create_task_pm
IS
    v_task_id NUMBER;
BEGIN
    v_task_id := pkg_task_management.create_task(
        p_title => :P100_TITLE,
        p_description => :P100_DESCRIPTION,
        p_created_by => TO_NUMBER(:G_USER_ID),
        p_assigned_to_tl => :P100_ASSIGNED_TO_TL,
        p_priority => :P100_PRIORITY,
        p_due_date => :P100_DUE_DATE
    );
    
    -- Clear form
    :P100_TITLE := NULL;
    :P100_DESCRIPTION := NULL;
    :P100_ASSIGNED_TO_TL := NULL;
    :P100_PRIORITY := 'MEDIUM';
    :P100_DUE_DATE := NULL;
    
    -- Show success message
    APEX_APPLICATION.G_PRINT_SUCCESS_MESSAGE := 'Task created successfully with ID: ' || v_task_id;
END;
/

-- =====================================================
-- PAGE 200: TEAM LEADER DASHBOARD
-- =====================================================
/*
Page Properties:
- Page Number: 200
- Page Name: Team Leader Dashboard
- Authorization: TL Only
- Page Template: Standard

Regions:
1. Page Header
   - Template: Hero
   - Title: Team Leader Dashboard
   - Subtitle: Manage your team tasks and approvals

2. My Team Tasks
   - Template: Interactive Report
   - Source: rpt_tl_team_tasks view
   - Filters: Tasks assigned to current TL

3. Task Assignment Form
   - Template: Standard
   - Condition: When task is selected for assignment

4. Approval Queue
   - Template: Interactive Report
   - Source: Tasks pending TL approval
   - Action buttons: Approve/Reject

5. Team Performance Summary
   - Template: Cards
   - Show team statistics
*/

-- Task Assignment Form Items for TL Dashboard
/*
Items for Task Assignment:
1. P200_TASK_ID
   - Type: Hidden
   - Source: Selected task

2. P200_TASK_TITLE
   - Type: Display Only
   - Label: Task Title

3. P200_ASSIGNED_TO_TM
   - Type: Select List
   - Label: Assign to Team Member
   - LOV: lov_team_members (filtered by TL)
   - Cascading LOV Parent: G_USER_ID

4. P200_ASSIGNMENT_COMMENTS
   - Type: Textarea
   - Label: Assignment Comments
   - Height: 3 rows
*/

-- Process to Assign Task to Team Member
CREATE OR REPLACE PROCEDURE process_assign_to_tm
IS
BEGIN
    pkg_task_management.assign_to_team_member(
        p_task_id => :P200_TASK_ID,
        p_assigned_to_tm => :P200_ASSIGNED_TO_TM,
        p_assigned_by => TO_NUMBER(:G_USER_ID)
    );
    
    -- Add assignment comment if provided
    IF :P200_ASSIGNMENT_COMMENTS IS NOT NULL THEN
        INSERT INTO tm_comments (comment_id, task_id, user_id, comment_text, comment_type)
        VALUES (tm_comments_seq.NEXTVAL, :P200_TASK_ID, TO_NUMBER(:G_USER_ID), 
                :P200_ASSIGNMENT_COMMENTS, 'GENERAL');
    END IF;
    
    COMMIT;
    
    -- Clear form
    :P200_TASK_ID := NULL;
    :P200_ASSIGNED_TO_TM := NULL;
    :P200_ASSIGNMENT_COMMENTS := NULL;
    
    APEX_APPLICATION.G_PRINT_SUCCESS_MESSAGE := 'Task assigned successfully';
END;
/

-- Process for TL Approval/Rejection
CREATE OR REPLACE PROCEDURE process_tl_approval
IS
    v_action VARCHAR2(10) := :REQUEST;
BEGIN
    pkg_task_management.process_approval(
        p_task_id => :P200_TASK_ID,
        p_approver_id => TO_NUMBER(:G_USER_ID),
        p_approval_level => 1, -- TL Level
        p_action => CASE WHEN v_action = 'APPROVE' THEN 'APPROVED' ELSE 'REJECTED' END,
        p_comments => :P200_APPROVAL_COMMENTS
    );
    
    APEX_APPLICATION.G_PRINT_SUCCESS_MESSAGE := 'Task ' || LOWER(v_action) || 'd successfully';
END;
/

-- =====================================================
-- PAGE 300: TEAM MEMBER DASHBOARD
-- =====================================================
/*
Page Properties:
- Page Number: 300
- Page Name: Team Member Dashboard
- Authorization: TM Only
- Page Template: Standard

Regions:
1. Page Header
   - Template: Hero
   - Title: My Tasks
   - Subtitle: Complete your assigned tasks

2. My Active Tasks
   - Template: Interactive Report
   - Source: rpt_tm_my_tasks view
   - Filters: Tasks assigned to current TM

3. Task Work Form
   - Template: Standard
   - Condition: When task is selected

4. My Performance Summary
   - Template: Cards
   - Show personal statistics
*/

-- Task Work Form Items for TM Dashboard
/*
Items for Task Work:
1. P300_TASK_ID
   - Type: Hidden
   - Source: Selected task

2. P300_TASK_DETAILS
   - Type: Display Only
   - Label: Task Details
   - Format: HTML
   - Source: Task title and description

3. P300_WORK_COMMENTS
   - Type: Rich Text Editor
   - Label: Work Progress/Comments
   - Height: 200px

4. P300_COMPLETION_STATUS
   - Type: Radio Group
   - Label: Status
   - LOV: In Progress, Ready for Review
   - Default: In Progress
*/

-- Process to Submit Task for Review
CREATE OR REPLACE PROCEDURE process_submit_for_review
IS
BEGIN
    -- Add work comments
    IF :P300_WORK_COMMENTS IS NOT NULL THEN
        INSERT INTO tm_comments (comment_id, task_id, user_id, comment_text, comment_type)
        VALUES (tm_comments_seq.NEXTVAL, :P300_TASK_ID, TO_NUMBER(:G_USER_ID), 
                :P300_WORK_COMMENTS, 'GENERAL');
    END IF;
    
    -- Submit for review if status is ready
    IF :P300_COMPLETION_STATUS = 'READY_FOR_REVIEW' THEN
        pkg_task_management.submit_for_review(
            p_task_id => :P300_TASK_ID,
            p_submitted_by => TO_NUMBER(:G_USER_ID)
        );
        
        APEX_APPLICATION.G_PRINT_SUCCESS_MESSAGE := 'Task submitted for review successfully';
    ELSE
        -- Just update with progress comments
        COMMIT;
        APEX_APPLICATION.G_PRINT_SUCCESS_MESSAGE := 'Work progress saved successfully';
    END IF;
    
    -- Clear form
    :P300_TASK_ID := NULL;
    :P300_WORK_COMMENTS := NULL;
    :P300_COMPLETION_STATUS := 'IN_PROGRESS';
END;
/

-- =====================================================
-- PAGE 400: SENIOR DASHBOARD
-- =====================================================
/*
Page Properties:
- Page Number: 400
- Page Name: Senior Dashboard
- Authorization: Senior Only
- Page Template: Standard

Regions:
1. Page Header
   - Template: Hero
   - Title: Senior Management Dashboard
   - Subtitle: Final approvals and system oversight

2. Pending Senior Approvals
   - Template: Interactive Report
   - Source: rpt_senior_approvals view
   - Priority sorting: Urgent first

3. Final Approval Form
   - Template: Standard
   - Condition: When task is selected for approval

4. System Analytics
   - Template: Chart Container
   - Multiple charts: Completion rates, team performance, etc.

5. All Tasks Overview
   - Template: Interactive Report
   - Source: All tasks with comprehensive filters
*/

-- Final Approval Form Items for Senior Dashboard
/*
Items for Final Approval:
1. P400_TASK_ID
   - Type: Hidden
   - Source: Selected task

2. P400_TASK_SUMMARY
   - Type: Display Only
   - Label: Task Summary
   - Format: HTML
   - Source: Complete task details

3. P400_TL_APPROVAL_COMMENTS
   - Type: Display Only
   - Label: Team Leader Comments
   - Source: TL approval comments

4. P400_APPROVAL_COMMENTS
   - Type: Textarea
   - Label: Senior Approval Comments
   - Height: 4 rows

5. P400_FINAL_DECISION
   - Type: Radio Group
   - Label: Final Decision
   - LOV: Approve, Reject
   - Required: Yes
*/

-- Process for Senior Final Approval
CREATE OR REPLACE PROCEDURE process_senior_approval
IS
BEGIN
    pkg_task_management.process_approval(
        p_task_id => :P400_TASK_ID,
        p_approver_id => TO_NUMBER(:G_USER_ID),
        p_approval_level => 2, -- Senior Level
        p_action => CASE WHEN :P400_FINAL_DECISION = 'Approve' THEN 'APPROVED' ELSE 'REJECTED' END,
        p_comments => :P400_APPROVAL_COMMENTS
    );
    
    -- Clear form
    :P400_TASK_ID := NULL;
    :P400_APPROVAL_COMMENTS := NULL;
    :P400_FINAL_DECISION := NULL;
    
    APEX_APPLICATION.G_PRINT_SUCCESS_MESSAGE := 'Final approval processed successfully';
END;
/

-- =====================================================
-- PAGE 500: TASK DETAILS (UNIVERSAL)
-- =====================================================
/*
Page Properties:
- Page Number: 500
- Page Name: Task Details
- Authorization: Role-based access check
- Page Template: Modal Dialog

Regions:
1. Task Information
   - Template: Standard
   - Display all task details

2. Comments History
   - Template: Comments
   - Source: tm_comments for this task
   - Chronological order

3. Approval History
   - Template: Timeline
   - Source: tm_approvals for this task

4. Status Timeline
   - Template: Timeline
   - Show status changes with timestamps

5. Actions
   - Template: Buttons Container
   - Conditional buttons based on user role and task status
*/

-- Task Details Query
CREATE OR REPLACE VIEW v_task_details AS
SELECT 
    t.task_id,
    t.title,
    t.description,
    t.status,
    t.priority,
    t.due_date,
    t.created_date,
    t.updated_date,
    t.completed_date,
    creator.full_name as created_by_name,
    creator.email as created_by_email,
    tl.full_name as team_leader_name,
    tl.email as team_leader_email,
    tm.full_name as team_member_name,
    tm.email as team_member_email,
    -- Status badge HTML
    CASE t.status
        WHEN 'NEW' THEN '<span class="t-Badge t-Badge--info">New</span>'
        WHEN 'IN_PROGRESS' THEN '<span class="t-Badge t-Badge--warning">In Progress</span>'
        WHEN 'PENDING_TL_APPROVAL' THEN '<span class="t-Badge t-Badge--warning">Pending TL Approval</span>'
        WHEN 'PENDING_SENIOR_APPROVAL' THEN '<span class="t-Badge t-Badge--warning">Pending Senior Approval</span>'
        WHEN 'APPROVED' THEN '<span class="t-Badge t-Badge--success">Approved</span>'
        WHEN 'REJECTED' THEN '<span class="t-Badge t-Badge--danger">Rejected</span>'
        WHEN 'CANCELLED' THEN '<span class="t-Badge">Cancelled</span>'
    END as status_badge,
    -- Priority badge HTML
    CASE t.priority
        WHEN 'LOW' THEN '<span class="t-Badge t-Badge--info">Low</span>'
        WHEN 'MEDIUM' THEN '<span class="t-Badge t-Badge--warning">Medium</span>'
        WHEN 'HIGH' THEN '<span class="t-Badge t-Badge--hot">High</span>'
        WHEN 'URGENT' THEN '<span class="t-Badge t-Badge--danger">Urgent</span>'
    END as priority_badge,
    -- Due status
    CASE 
        WHEN t.due_date < SYSDATE AND t.status NOT IN ('APPROVED', 'CANCELLED') THEN 'OVERDUE'
        WHEN t.due_date <= SYSDATE + 2 AND t.status NOT IN ('APPROVED', 'CANCELLED') THEN 'DUE_SOON'
        ELSE 'ON_TIME'
    END as due_status
FROM tm_tasks t
LEFT JOIN tm_users creator ON t.created_by = creator.user_id
LEFT JOIN tm_users tl ON t.assigned_to_tl = tl.user_id
LEFT JOIN tm_users tm ON t.assigned_to_tm = tm.user_id;

-- =====================================================
-- JAVASCRIPT FOR DYNAMIC ACTIONS
-- =====================================================

-- JavaScript for task actions (to be included in page)
/*
// Function to assign task to TL
function assignToTL(taskId) {
    apex.item('P100_TASK_ID').setValue(taskId);
    apex.region('assign_tl_region').refresh();
    $('#assign_tl_dialog').dialog('open');
}

// Function to assign task to TM
function assignToTM(taskId) {
    apex.item('P200_TASK_ID').setValue(taskId);
    // Refresh team members LOV based on current TL
    apex.item('P200_ASSIGNED_TO_TM').refresh();
    $('#assign_tm_dialog').dialog('open');
}

// Function to submit task for review
function submitForReview(taskId) {
    apex.item('P300_TASK_ID').setValue(taskId);
    $('#submit_review_dialog').dialog('open');
}

// Function to approve task
function approveTask(taskId) {
    apex.item('P200_TASK_ID').setValue(taskId);
    apex.item('P200_ACTION').setValue('APPROVE');
    $('#approval_dialog').dialog('open');
}

// Function to reject task
function rejectTask(taskId) {
    apex.item('P200_TASK_ID').setValue(taskId);
    apex.item('P200_ACTION').setValue('REJECT');
    $('#approval_dialog').dialog('open');
}

// Function for final approval (Senior)
function approveFinalTask(taskId) {
    apex.item('P400_TASK_ID').setValue(taskId);
    apex.item('P400_FINAL_DECISION').setValue('Approve');
    $('#final_approval_dialog').dialog('open');
}

// Function for final rejection (Senior)
function rejectFinalTask(taskId) {
    apex.item('P400_TASK_ID').setValue(taskId);
    apex.item('P400_FINAL_DECISION').setValue('Reject');
    $('#final_approval_dialog').dialog('open');
}

// Function to view task details
function viewTask(taskId) {
    var url = 'f?p=&APP_ID.:500:&SESSION.::NO::P500_TASK_ID:' + taskId;
    apex.navigation.dialog(url, {
        title: 'Task Details',
        height: 600,
        width: 800,
        maxWidth: 1000,
        modal: true,
        dialog: null
    });
}

// Function to refresh notifications
function refreshNotifications() {
    apex.region('notifications_region').refresh();
    // Update notification count badge
    var count = apex.item('G_NOTIFICATION_COUNT').getValue();
    if (count > 0) {
        $('#notification_badge').text(count).show();
    } else {
        $('#notification_badge').hide();
    }
}

// Auto-refresh notifications every 30 seconds
setInterval(refreshNotifications, 30000);
*/

-- =====================================================
-- CSS STYLING
-- =====================================================

-- CSS to be added to application (inline CSS or file)
/*
/* Task Status Colors */
.task-status-new { background-color: #e3f2fd; color: #1976d2; }
.task-status-in-progress { background-color: #fff3e0; color: #f57c00; }
.task-status-pending { background-color: #fce4ec; color: #c2185b; }
.task-status-approved { background-color: #e8f5e8; color: #388e3c; }
.task-status-rejected { background-color: #ffebee; color: #d32f2f; }

/* Priority Colors */
.priority-low { border-left: 4px solid #4caf50; }
.priority-medium { border-left: 4px solid #ff9800; }
.priority-high { border-left: 4px solid #f44336; }
.priority-urgent { border-left: 4px solid #9c27b0; animation: blink 1s infinite; }

/* Overdue Tasks */
.task-overdue {
    background-color: #ffebee;
    border: 1px solid #f44336;
}

/* Notification Badge */
.notification-badge {
    background-color: #f44336;
    color: white;
    border-radius: 50%;
    padding: 2px 6px;
    font-size: 12px;
    position: absolute;
    top: -8px;
    right: -8px;
}

/* Timeline Styles */
.timeline-item {
    border-left: 2px solid #e0e0e0;
    padding-left: 20px;
    margin-bottom: 20px;
    position: relative;
}

.timeline-item::before {
    content: '';
    width: 12px;
    height: 12px;
    background-color: #2196f3;
    border-radius: 50%;
    position: absolute;
    left: -7px;
    top: 0;
}

/* Dashboard Cards */
.dashboard-card {
    background: white;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    padding: 20px;
    margin-bottom: 20px;
}

.dashboard-card h3 {
    margin-top: 0;
    color: #333;
}

.stat-number {
    font-size: 2em;
    font-weight: bold;
    color: #2196f3;
}

/* Responsive Design */
@media (max-width: 768px) {
    .dashboard-card {
        margin-bottom: 10px;
        padding: 15px;
    }
    
    .stat-number {
        font-size: 1.5em;
    }
}
*/

-- =====================================================
-- COMMIT ALL CHANGES
-- =====================================================
COMMIT;

SELECT 'Detailed APEX page structures created successfully!' as status FROM dual;
SELECT 'All forms, reports, and processes defined' as forms_status FROM dual;
SELECT 'JavaScript and CSS styling included' as ui_status FROM dual;
SELECT 'Ready for APEX Builder implementation' as ready_status FROM dual;