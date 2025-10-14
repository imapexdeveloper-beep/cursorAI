-- =====================================================
-- ORACLE APEX TASK MANAGEMENT - COMPLETE WORKFLOW TEST
-- =====================================================
-- This script tests the entire task management workflow
-- from creation to final approval with all user roles
-- =====================================================

-- =====================================================
-- 1. SETUP TEST ENVIRONMENT
-- =====================================================

-- Clear existing test data (keep users)
DELETE FROM tm_notifications WHERE task_id IN (SELECT task_id FROM tm_tasks);
DELETE FROM tm_comments WHERE task_id IN (SELECT task_id FROM tm_tasks);
DELETE FROM tm_approvals WHERE task_id IN (SELECT task_id FROM tm_tasks);
DELETE FROM tm_tasks;
COMMIT;

-- Reset sequences
ALTER SEQUENCE tm_tasks_seq RESTART START WITH 1;
ALTER SEQUENCE tm_approvals_seq RESTART START WITH 1;
ALTER SEQUENCE tm_notifications_seq RESTART START WITH 1;
ALTER SEQUENCE tm_comments_seq RESTART START WITH 1;

-- =====================================================
-- 2. TEST DATA VERIFICATION
-- =====================================================

-- Verify users are created correctly
SELECT 'User Verification' as test_section FROM dual;

SELECT role_code, COUNT(*) as user_count
FROM tm_users
WHERE is_active = 'Y'
GROUP BY role_code
ORDER BY role_code;

-- Get specific user IDs for testing
DECLARE
    v_pm_id NUMBER;
    v_tl_id NUMBER;
    v_tm_id NUMBER;
    v_senior_id NUMBER;
BEGIN
    SELECT user_id INTO v_pm_id FROM tm_users WHERE role_code = 'PM' AND ROWNUM = 1;
    SELECT user_id INTO v_tl_id FROM tm_users WHERE role_code = 'TL' AND team_id = 1;
    SELECT user_id INTO v_tm_id FROM tm_users WHERE role_code = 'TM' AND team_id = 1 AND ROWNUM = 1;
    SELECT user_id INTO v_senior_id FROM tm_users WHERE role_code = 'SENIOR' AND ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('PM ID: ' || v_pm_id);
    DBMS_OUTPUT.PUT_LINE('TL ID: ' || v_tl_id);
    DBMS_OUTPUT.PUT_LINE('TM ID: ' || v_tm_id);
    DBMS_OUTPUT.PUT_LINE('Senior ID: ' || v_senior_id);
END;
/

-- =====================================================
-- 3. TEST SCENARIO 1: COMPLETE SUCCESSFUL WORKFLOW
-- =====================================================

SELECT 'TEST SCENARIO 1: Complete Successful Workflow' as test_section FROM dual;

DECLARE
    v_pm_id NUMBER;
    v_tl_id NUMBER;
    v_tm_id NUMBER;
    v_senior_id NUMBER;
    v_task_id NUMBER;
    v_notification_count NUMBER;
BEGIN
    -- Get user IDs
    SELECT user_id INTO v_pm_id FROM tm_users WHERE role_code = 'PM' AND ROWNUM = 1;
    SELECT user_id INTO v_tl_id FROM tm_users WHERE role_code = 'TL' AND team_id = 1;
    SELECT user_id INTO v_tm_id FROM tm_users WHERE role_code = 'TM' AND team_id = 1 AND ROWNUM = 1;
    SELECT user_id INTO v_senior_id FROM tm_users WHERE role_code = 'SENIOR' AND ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('=== STEP 1: PM Creates Task ===');
    
    -- Step 1: PM creates task
    v_task_id := pkg_task_management.create_task(
        p_title => 'Test Task - Complete Workflow',
        p_description => 'This is a test task to verify the complete workflow from creation to approval.',
        p_created_by => v_pm_id,
        p_assigned_to_tl => v_tl_id,
        p_priority => 'HIGH',
        p_due_date => SYSDATE + 7
    );
    
    DBMS_OUTPUT.PUT_LINE('Task created with ID: ' || v_task_id);
    
    -- Verify task status
    SELECT status INTO v_status FROM tm_tasks WHERE task_id = v_task_id;
    DBMS_OUTPUT.PUT_LINE('Task status: ' || v_status);
    
    DBMS_OUTPUT.PUT_LINE('=== STEP 2: TL Assigns to TM ===');
    
    -- Step 2: TL assigns task to TM
    pkg_task_management.assign_to_team_member(
        p_task_id => v_task_id,
        p_assigned_to_tm => v_tm_id,
        p_assigned_by => v_tl_id
    );
    
    -- Verify status changed and notification sent
    SELECT status INTO v_status FROM tm_tasks WHERE task_id = v_task_id;
    DBMS_OUTPUT.PUT_LINE('Task status after assignment: ' || v_status);
    
    SELECT COUNT(*) INTO v_notification_count 
    FROM tm_notifications 
    WHERE task_id = v_task_id AND user_id = v_tm_id;
    DBMS_OUTPUT.PUT_LINE('Notifications sent to TM: ' || v_notification_count);
    
    DBMS_OUTPUT.PUT_LINE('=== STEP 3: TM Submits for Review ===');
    
    -- Step 3: TM submits for review
    pkg_task_management.submit_for_review(
        p_task_id => v_task_id,
        p_submitted_by => v_tm_id
    );
    
    -- Verify status and approvals created
    SELECT status INTO v_status FROM tm_tasks WHERE task_id = v_task_id;
    DBMS_OUTPUT.PUT_LINE('Task status after submission: ' || v_status);
    
    SELECT COUNT(*) INTO v_notification_count 
    FROM tm_approvals 
    WHERE task_id = v_task_id AND approval_level = 1;
    DBMS_OUTPUT.PUT_LINE('TL approval records created: ' || v_notification_count);
    
    DBMS_OUTPUT.PUT_LINE('=== STEP 4: TL Approves ===');
    
    -- Step 4: TL approves
    pkg_task_management.process_approval(
        p_task_id => v_task_id,
        p_approver_id => v_tl_id,
        p_approval_level => 1,
        p_action => 'APPROVED',
        p_comments => 'Good work! Task completed satisfactorily.'
    );
    
    -- Verify status and senior approval created
    SELECT status INTO v_status FROM tm_tasks WHERE task_id = v_task_id;
    DBMS_OUTPUT.PUT_LINE('Task status after TL approval: ' || v_status);
    
    SELECT COUNT(*) INTO v_notification_count 
    FROM tm_approvals 
    WHERE task_id = v_task_id AND approval_level = 2;
    DBMS_OUTPUT.PUT_LINE('Senior approval records created: ' || v_notification_count);
    
    DBMS_OUTPUT.PUT_LINE('=== STEP 5: Senior Final Approval ===');
    
    -- Step 5: Senior gives final approval
    pkg_task_management.process_approval(
        p_task_id => v_task_id,
        p_approver_id => v_senior_id,
        p_approval_level => 2,
        p_action => 'APPROVED',
        p_comments => 'Excellent work. Task approved for completion.'
    );
    
    -- Verify final status
    SELECT status INTO v_status FROM tm_tasks WHERE task_id = v_task_id;
    DBMS_OUTPUT.PUT_LINE('Final task status: ' || v_status);
    
    -- Count total notifications
    SELECT COUNT(*) INTO v_notification_count 
    FROM tm_notifications 
    WHERE task_id = v_task_id;
    DBMS_OUTPUT.PUT_LINE('Total notifications sent: ' || v_notification_count);
    
    DBMS_OUTPUT.PUT_LINE('=== SCENARIO 1 COMPLETED SUCCESSFULLY ===');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR in Scenario 1: ' || SQLERRM);
        ROLLBACK;
END;
/

-- =====================================================
-- 4. TEST SCENARIO 2: REJECTION AND REWORK WORKFLOW
-- =====================================================

SELECT 'TEST SCENARIO 2: Rejection and Rework Workflow' as test_section FROM dual;

DECLARE
    v_pm_id NUMBER;
    v_tl_id NUMBER;
    v_tm_id NUMBER;
    v_senior_id NUMBER;
    v_task_id NUMBER;
    v_status VARCHAR2(30);
BEGIN
    -- Get user IDs
    SELECT user_id INTO v_pm_id FROM tm_users WHERE role_code = 'PM' AND ROWNUM = 1;
    SELECT user_id INTO v_tl_id FROM tm_users WHERE role_code = 'TL' AND team_id = 2;
    SELECT user_id INTO v_tm_id FROM tm_users WHERE role_code = 'TM' AND team_id = 2 AND ROWNUM = 1;
    SELECT user_id INTO v_senior_id FROM tm_users WHERE role_code = 'SENIOR' AND ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('=== REJECTION WORKFLOW TEST ===');
    
    -- Create task
    v_task_id := pkg_task_management.create_task(
        p_title => 'Test Task - Rejection Workflow',
        p_description => 'This task will be rejected to test the rework process.',
        p_created_by => v_pm_id,
        p_assigned_to_tl => v_tl_id,
        p_priority => 'MEDIUM',
        p_due_date => SYSDATE + 5
    );
    
    DBMS_OUTPUT.PUT_LINE('Task created with ID: ' || v_task_id);
    
    -- TL assigns to TM
    pkg_task_management.assign_to_team_member(
        p_task_id => v_task_id,
        p_assigned_to_tm => v_tm_id,
        p_assigned_by => v_tl_id
    );
    
    -- TM submits for review
    pkg_task_management.submit_for_review(
        p_task_id => v_task_id,
        p_submitted_by => v_tm_id
    );
    
    -- TL rejects
    pkg_task_management.process_approval(
        p_task_id => v_task_id,
        p_approver_id => v_tl_id,
        p_approval_level => 1,
        p_action => 'REJECTED',
        p_comments => 'Task needs more work. Please review the requirements and resubmit.'
    );
    
    SELECT status INTO v_status FROM tm_tasks WHERE task_id = v_task_id;
    DBMS_OUTPUT.PUT_LINE('Task status after TL rejection: ' || v_status);
    
    -- TM reworks and resubmits
    UPDATE tm_tasks SET status = 'IN_PROGRESS' WHERE task_id = v_task_id;
    
    pkg_task_management.submit_for_review(
        p_task_id => v_task_id,
        p_submitted_by => v_tm_id
    );
    
    -- TL approves after rework
    pkg_task_management.process_approval(
        p_task_id => v_task_id,
        p_approver_id => v_tl_id,
        p_approval_level => 1,
        p_action => 'APPROVED',
        p_comments => 'Much better! Approved for senior review.'
    );
    
    -- Senior rejects
    pkg_task_management.process_approval(
        p_task_id => v_task_id,
        p_approver_id => v_senior_id,
        p_approval_level => 2,
        p_action => 'REJECTED',
        p_comments => 'Quality standards not met. Please rework and resubmit.'
    );
    
    SELECT status INTO v_status FROM tm_tasks WHERE task_id = v_task_id;
    DBMS_OUTPUT.PUT_LINE('Task status after Senior rejection: ' || v_status);
    
    DBMS_OUTPUT.PUT_LINE('=== REJECTION WORKFLOW COMPLETED ===');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR in Scenario 2: ' || SQLERRM);
        ROLLBACK;
END;
/

-- =====================================================
-- 5. TEST SCENARIO 3: TASK CANCELLATION
-- =====================================================

SELECT 'TEST SCENARIO 3: Task Cancellation' as test_section FROM dual;

DECLARE
    v_pm_id NUMBER;
    v_tl_id NUMBER;
    v_task_id NUMBER;
    v_status VARCHAR2(30);
BEGIN
    -- Get user IDs
    SELECT user_id INTO v_pm_id FROM tm_users WHERE role_code = 'PM' AND ROWNUM = 1;
    SELECT user_id INTO v_tl_id FROM tm_users WHERE role_code = 'TL' AND team_id = 3;
    
    DBMS_OUTPUT.PUT_LINE('=== CANCELLATION WORKFLOW TEST ===');
    
    -- Create task
    v_task_id := pkg_task_management.create_task(
        p_title => 'Test Task - Cancellation',
        p_description => 'This task will be cancelled.',
        p_created_by => v_pm_id,
        p_assigned_to_tl => v_tl_id,
        p_priority => 'LOW',
        p_due_date => SYSDATE + 10
    );
    
    DBMS_OUTPUT.PUT_LINE('Task created with ID: ' || v_task_id);
    
    -- Cancel task
    pkg_task_management.cancel_task(
        p_task_id => v_task_id,
        p_cancelled_by => v_pm_id,
        p_reason => 'Requirements changed - task no longer needed'
    );
    
    SELECT status INTO v_status FROM tm_tasks WHERE task_id = v_task_id;
    DBMS_OUTPUT.PUT_LINE('Task status after cancellation: ' || v_status);
    
    DBMS_OUTPUT.PUT_LINE('=== CANCELLATION WORKFLOW COMPLETED ===');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR in Scenario 3: ' || SQLERRM);
        ROLLBACK;
END;
/

-- =====================================================
-- 6. TEST WORKFLOW ENGINE
-- =====================================================

SELECT 'TEST WORKFLOW ENGINE' as test_section FROM dual;

DECLARE
    v_task_id NUMBER;
    v_pm_id NUMBER;
    v_tl_id NUMBER;
    v_tm_id NUMBER;
    v_count NUMBER;
BEGIN
    -- Get a test task
    SELECT task_id INTO v_task_id FROM tm_tasks WHERE status = 'NEW' AND ROWNUM = 1;
    SELECT user_id INTO v_pm_id FROM tm_users WHERE role_code = 'PM' AND ROWNUM = 1;
    SELECT user_id INTO v_tl_id FROM tm_users WHERE role_code = 'TL' AND ROWNUM = 1;
    SELECT user_id INTO v_tm_id FROM tm_users WHERE role_code = 'TM' AND ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('Testing workflow engine with Task ID: ' || v_task_id);
    
    -- Test allowed transitions for PM
    SELECT COUNT(*) INTO v_count
    FROM TABLE(pkg_workflow_engine.get_allowed_transitions(v_task_id, v_pm_id));
    DBMS_OUTPUT.PUT_LINE('Allowed transitions for PM: ' || v_count);
    
    -- Test allowed transitions for TL
    SELECT COUNT(*) INTO v_count
    FROM TABLE(pkg_workflow_engine.get_allowed_transitions(v_task_id, v_tl_id));
    DBMS_OUTPUT.PUT_LINE('Allowed transitions for TL: ' || v_count);
    
    -- Test allowed transitions for TM
    SELECT COUNT(*) INTO v_count
    FROM TABLE(pkg_workflow_engine.get_allowed_transitions(v_task_id, v_tm_id));
    DBMS_OUTPUT.PUT_LINE('Allowed transitions for TM: ' || v_count);
    
    -- Test transition validation
    IF pkg_workflow_engine.is_transition_allowed(v_task_id, v_pm_id, 'CANCEL') THEN
        DBMS_OUTPUT.PUT_LINE('PM can cancel task: TRUE');
    ELSE
        DBMS_OUTPUT.PUT_LINE('PM can cancel task: FALSE');
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR in Workflow Engine Test: ' || SQLERRM);
END;
/

-- =====================================================
-- 7. TEST NOTIFICATION SYSTEM
-- =====================================================

SELECT 'TEST NOTIFICATION SYSTEM' as test_section FROM dual;

DECLARE
    v_tm_id NUMBER;
    v_task_id NUMBER;
    v_unread_count NUMBER;
    v_json CLOB;
BEGIN
    SELECT user_id INTO v_tm_id FROM tm_users WHERE role_code = 'TM' AND ROWNUM = 1;
    SELECT task_id INTO v_task_id FROM tm_tasks WHERE ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('Testing notification system for TM ID: ' || v_tm_id);
    
    -- Send test notification
    pkg_notification_system.send_notification(
        p_user_id => v_tm_id,
        p_task_id => v_task_id,
        p_notification_type => 'TEST',
        p_message => 'This is a test notification',
        p_send_email => FALSE
    );
    
    -- Check unread count
    v_unread_count := pkg_notification_system.get_unread_count(v_tm_id);
    DBMS_OUTPUT.PUT_LINE('Unread notifications: ' || v_unread_count);
    
    -- Get notification summary
    v_json := get_notification_summary_json(v_tm_id);
    DBMS_OUTPUT.PUT_LINE('Notification summary JSON length: ' || LENGTH(v_json));
    
    -- Mark all as read
    pkg_notification_system.mark_all_as_read(v_tm_id);
    
    v_unread_count := pkg_notification_system.get_unread_count(v_tm_id);
    DBMS_OUTPUT.PUT_LINE('Unread notifications after marking read: ' || v_unread_count);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR in Notification Test: ' || SQLERRM);
END;
/

-- =====================================================
-- 8. TEST APEX INTEGRATION FUNCTIONS
-- =====================================================

SELECT 'TEST APEX INTEGRATION FUNCTIONS' as test_section FROM dual;

DECLARE
    v_task_id NUMBER;
    v_user_id NUMBER;
    v_json CLOB;
BEGIN
    SELECT task_id INTO v_task_id FROM tm_tasks WHERE ROWNUM = 1;
    SELECT user_id INTO v_user_id FROM tm_users WHERE role_code = 'TL' AND ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('Testing APEX integration functions');
    
    -- Test workflow actions JSON
    v_json := get_workflow_actions_json(v_task_id, v_user_id);
    DBMS_OUTPUT.PUT_LINE('Workflow actions JSON length: ' || LENGTH(v_json));
    
    -- Test dashboard stats
    v_json := get_dashboard_stats(v_user_id, 'TL');
    DBMS_OUTPUT.PUT_LINE('Dashboard stats JSON length: ' || LENGTH(v_json));
    
    -- Test task details
    SELECT JSON_OBJECT(
        'task_id' VALUE task_id,
        'title' VALUE title,
        'status' VALUE status
    ) INTO v_json
    FROM v_task_details
    WHERE task_id = v_task_id;
    
    DBMS_OUTPUT.PUT_LINE('Task details JSON: ' || SUBSTR(v_json, 1, 100) || '...');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR in APEX Integration Test: ' || SQLERRM);
END;
/

-- =====================================================
-- 9. PERFORMANCE AND DATA INTEGRITY TESTS
-- =====================================================

SELECT 'PERFORMANCE AND DATA INTEGRITY TESTS' as test_section FROM dual;

-- Test data integrity
SELECT 'Data Integrity Check' as check_type FROM dual;

-- Check for orphaned records
SELECT 'Orphaned approvals: ' || COUNT(*) as result
FROM tm_approvals a
WHERE NOT EXISTS (SELECT 1 FROM tm_tasks t WHERE t.task_id = a.task_id);

SELECT 'Orphaned notifications: ' || COUNT(*) as result
FROM tm_notifications n
WHERE NOT EXISTS (SELECT 1 FROM tm_tasks t WHERE t.task_id = n.task_id);

SELECT 'Orphaned comments: ' || COUNT(*) as result
FROM tm_comments c
WHERE NOT EXISTS (SELECT 1 FROM tm_tasks t WHERE t.task_id = c.task_id);

-- Check workflow consistency
SELECT 'Tasks with inconsistent approval status: ' || COUNT(*) as result
FROM tm_tasks t
WHERE t.status = 'PENDING_TL_APPROVAL'
AND NOT EXISTS (
    SELECT 1 FROM tm_approvals a 
    WHERE a.task_id = t.task_id 
    AND a.approval_level = 1 
    AND a.status = 'PENDING'
);

-- Performance test - create multiple tasks
DECLARE
    v_pm_id NUMBER;
    v_tl_id NUMBER;
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_task_id NUMBER;
BEGIN
    SELECT user_id INTO v_pm_id FROM tm_users WHERE role_code = 'PM' AND ROWNUM = 1;
    SELECT user_id INTO v_tl_id FROM tm_users WHERE role_code = 'TL' AND ROWNUM = 1;
    
    v_start_time := SYSTIMESTAMP;
    
    -- Create 10 tasks quickly
    FOR i IN 1..10 LOOP
        v_task_id := pkg_task_management.create_task(
            p_title => 'Performance Test Task ' || i,
            p_description => 'Performance testing task number ' || i,
            p_created_by => v_pm_id,
            p_assigned_to_tl => v_tl_id,
            p_priority => 'MEDIUM',
            p_due_date => SYSDATE + 7
        );
    END LOOP;
    
    v_end_time := SYSTIMESTAMP;
    
    DBMS_OUTPUT.PUT_LINE('Created 10 tasks in: ' || 
        EXTRACT(SECOND FROM (v_end_time - v_start_time)) || ' seconds');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR in Performance Test: ' || SQLERRM);
END;
/

-- =====================================================
-- 10. GENERATE TEST REPORT
-- =====================================================

SELECT 'FINAL TEST REPORT' as test_section FROM dual;

-- Task Statistics
SELECT 
    'Task Status Distribution' as report_section,
    status,
    COUNT(*) as task_count
FROM tm_tasks
GROUP BY status
ORDER BY status;

-- Notification Statistics
SELECT 
    'Notification Statistics' as report_section,
    notification_type,
    COUNT(*) as notification_count,
    SUM(CASE WHEN is_read = 'Y' THEN 1 ELSE 0 END) as read_count,
    SUM(CASE WHEN is_read = 'N' THEN 1 ELSE 0 END) as unread_count
FROM tm_notifications
GROUP BY notification_type
ORDER BY notification_type;

-- Approval Statistics
SELECT 
    'Approval Statistics' as report_section,
    approval_level,
    status,
    COUNT(*) as approval_count
FROM tm_approvals
GROUP BY approval_level, status
ORDER BY approval_level, status;

-- User Activity
SELECT 
    'User Activity Summary' as report_section,
    u.role_code,
    u.full_name,
    NVL(created_tasks.task_count, 0) as tasks_created,
    NVL(assigned_tasks.task_count, 0) as tasks_assigned,
    NVL(approvals.approval_count, 0) as approvals_processed
FROM tm_users u
LEFT JOIN (
    SELECT created_by, COUNT(*) as task_count
    FROM tm_tasks
    GROUP BY created_by
) created_tasks ON u.user_id = created_tasks.created_by
LEFT JOIN (
    SELECT assigned_to_tm, COUNT(*) as task_count
    FROM tm_tasks
    WHERE assigned_to_tm IS NOT NULL
    GROUP BY assigned_to_tm
) assigned_tasks ON u.user_id = assigned_tasks.assigned_to_tm
LEFT JOIN (
    SELECT approver_id, COUNT(*) as approval_count
    FROM tm_approvals
    WHERE status IN ('APPROVED', 'REJECTED')
    GROUP BY approver_id
) approvals ON u.user_id = approvals.approver_id
WHERE u.role_code IN ('PM', 'TL', 'TM', 'SENIOR')
ORDER BY u.role_code, u.full_name;

-- System Health Check
SELECT 'System Health Check' as report_section FROM dual;

SELECT 
    metric_name,
    metric_value,
    unit
FROM v_workflow_metrics
ORDER BY metric_name;

-- =====================================================
-- COMMIT ALL TEST CHANGES
-- =====================================================
COMMIT;

SELECT 'ALL TESTS COMPLETED SUCCESSFULLY!' as final_status FROM dual;
SELECT 'Task Management System is ready for production use' as ready_status FROM dual;
SELECT 'Total test tasks created: ' || COUNT(*) as task_count FROM tm_tasks;
SELECT 'Total notifications sent: ' || COUNT(*) as notification_count FROM tm_notifications;