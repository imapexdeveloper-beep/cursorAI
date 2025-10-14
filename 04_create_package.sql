-- =============================================
-- Task Management System - PL/SQL Package
-- =============================================

CREATE OR REPLACE PACKAGE pkg_task_management AS
    
    -- Task Management Procedures
    PROCEDURE create_task(
        p_title             IN VARCHAR2,
        p_description       IN CLOB,
        p_assigned_to_tl    IN NUMBER,
        p_priority          IN VARCHAR2 DEFAULT 'MEDIUM',
        p_due_date          IN DATE DEFAULT NULL,
        p_created_by        IN VARCHAR2,
        p_task_id           OUT NUMBER
    );
    
    PROCEDURE assign_task_to_tm(
        p_task_id           IN NUMBER,
        p_assigned_to_tm    IN NUMBER,
        p_assigned_by       IN VARCHAR2
    );
    
    PROCEDURE submit_task_for_review(
        p_task_id           IN NUMBER,
        p_submitted_by      IN VARCHAR2
    );
    
    PROCEDURE approve_task_tl(
        p_task_id           IN NUMBER,
        p_approver_id       IN NUMBER,
        p_comments          IN CLOB DEFAULT NULL
    );
    
    PROCEDURE reject_task_tl(
        p_task_id           IN NUMBER,
        p_approver_id       IN NUMBER,
        p_comments          IN CLOB
    );
    
    PROCEDURE approve_task_senior(
        p_task_id           IN NUMBER,
        p_approver_id       IN NUMBER,
        p_comments          IN CLOB DEFAULT NULL
    );
    
    PROCEDURE reject_task_senior(
        p_task_id           IN NUMBER,
        p_approver_id       IN NUMBER,
        p_comments          IN CLOB
    );
    
    PROCEDURE cancel_task(
        p_task_id           IN NUMBER,
        p_cancelled_by      IN VARCHAR2,
        p_reason            IN CLOB
    );
    
    PROCEDURE add_comment(
        p_task_id           IN NUMBER,
        p_comment_text      IN CLOB,
        p_comment_type      IN VARCHAR2 DEFAULT 'GENERAL',
        p_commented_by      IN VARCHAR2
    );
    
    -- Notification Procedures
    PROCEDURE send_notification(
        p_task_id           IN NUMBER,
        p_user_id           IN NUMBER,
        p_notification_type IN VARCHAR2,
        p_notification_text IN VARCHAR2
    );
    
    PROCEDURE mark_notification_read(
        p_notification_id   IN NUMBER
    );
    
    -- Utility Functions
    FUNCTION get_user_id(p_username IN VARCHAR2) RETURN NUMBER;
    FUNCTION get_user_role(p_username IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION get_task_status(p_task_id IN NUMBER) RETURN VARCHAR2;
    
END pkg_task_management;
/

CREATE OR REPLACE PACKAGE BODY pkg_task_management AS

    -- =============================================
    -- Create Task (PM only)
    -- =============================================
    PROCEDURE create_task(
        p_title             IN VARCHAR2,
        p_description       IN CLOB,
        p_assigned_to_tl    IN NUMBER,
        p_priority          IN VARCHAR2 DEFAULT 'MEDIUM',
        p_due_date          IN DATE DEFAULT NULL,
        p_created_by        IN VARCHAR2,
        p_task_id           OUT NUMBER
    ) IS
        v_created_by_user_id NUMBER;
    BEGIN
        -- Get creator user ID
        v_created_by_user_id := get_user_id(p_created_by);
        
        -- Insert task
        INSERT INTO tasks (
            title,
            description,
            status,
            priority,
            created_by,
            created_by_user_id,
            assigned_to_tl,
            assigned_to_tl_date,
            due_date,
            last_updated_by
        ) VALUES (
            p_title,
            p_description,
            'NEW',
            p_priority,
            p_created_by,
            v_created_by_user_id,
            p_assigned_to_tl,
            SYSDATE,
            p_due_date,
            p_created_by
        ) RETURNING task_id INTO p_task_id;
        
        -- Add comment
        add_comment(
            p_task_id => p_task_id,
            p_comment_text => 'Task created and assigned to Team Leader',
            p_comment_type => 'STATUS_CHANGE',
            p_commented_by => p_created_by
        );
        
        -- Send notification to TL
        send_notification(
            p_task_id => p_task_id,
            p_user_id => p_assigned_to_tl,
            p_notification_type => 'TASK_ASSIGNED',
            p_notification_text => 'New task assigned to you: ' || p_title
        );
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END create_task;

    -- =============================================
    -- Assign Task to Team Member (TL only)
    -- =============================================
    PROCEDURE assign_task_to_tm(
        p_task_id           IN NUMBER,
        p_assigned_to_tm    IN NUMBER,
        p_assigned_by       IN VARCHAR2
    ) IS
        v_task_title VARCHAR2(500);
    BEGIN
        -- Get task title
        SELECT title INTO v_task_title FROM tasks WHERE task_id = p_task_id;
        
        -- Update task
        UPDATE tasks
        SET status = 'IN_PROGRESS',
            assigned_to_tm = p_assigned_to_tm,
            assigned_to_tm_date = SYSDATE,
            last_updated_by = p_assigned_by,
            last_updated_date = SYSDATE
        WHERE task_id = p_task_id;
        
        -- Add comment
        add_comment(
            p_task_id => p_task_id,
            p_comment_text => 'Task assigned to Team Member',
            p_comment_type => 'STATUS_CHANGE',
            p_commented_by => p_assigned_by
        );
        
        -- Send notification to TM
        send_notification(
            p_task_id => p_task_id,
            p_user_id => p_assigned_to_tm,
            p_notification_type => 'TASK_ASSIGNED',
            p_notification_text => 'New task assigned to you: ' || v_task_title
        );
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END assign_task_to_tm;

    -- =============================================
    -- Submit Task for Review (TM only)
    -- =============================================
    PROCEDURE submit_task_for_review(
        p_task_id           IN NUMBER,
        p_submitted_by      IN VARCHAR2
    ) IS
        v_task_title VARCHAR2(500);
        v_tl_user_id NUMBER;
    BEGIN
        -- Get task info
        SELECT title, assigned_to_tl 
        INTO v_task_title, v_tl_user_id
        FROM tasks 
        WHERE task_id = p_task_id;
        
        -- Update task status
        UPDATE tasks
        SET status = 'PENDING_TL_APPROVAL',
            submitted_date = SYSDATE,
            last_updated_by = p_submitted_by,
            last_updated_date = SYSDATE
        WHERE task_id = p_task_id;
        
        -- Add comment
        add_comment(
            p_task_id => p_task_id,
            p_comment_text => 'Task submitted for Team Leader review',
            p_comment_type => 'STATUS_CHANGE',
            p_commented_by => p_submitted_by
        );
        
        -- Send notification to TL
        send_notification(
            p_task_id => p_task_id,
            p_user_id => v_tl_user_id,
            p_notification_type => 'APPROVAL_REQUIRED',
            p_notification_text => 'Task ready for your review: ' || v_task_title
        );
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END submit_task_for_review;

    -- =============================================
    -- Approve Task - Team Leader
    -- =============================================
    PROCEDURE approve_task_tl(
        p_task_id           IN NUMBER,
        p_approver_id       IN NUMBER,
        p_comments          IN CLOB DEFAULT NULL
    ) IS
        v_task_title VARCHAR2(500);
        v_senior_user_id NUMBER;
    BEGIN
        -- Get task title
        SELECT title INTO v_task_title FROM tasks WHERE task_id = p_task_id;
        
        -- Get senior user ID
        SELECT user_id INTO v_senior_user_id 
        FROM app_users 
        WHERE role = 'SENIOR' AND is_active = 'Y' AND ROWNUM = 1;
        
        -- Update task
        UPDATE tasks
        SET status = 'PENDING_SENIOR_APPROVAL',
            tl_approval_date = SYSDATE,
            tl_approved_by = p_approver_id,
            last_updated_by = (SELECT username FROM app_users WHERE user_id = p_approver_id),
            last_updated_date = SYSDATE
        WHERE task_id = p_task_id;
        
        -- Record approval
        INSERT INTO task_approvals (
            task_id, approval_level, approver_id, approval_status, comments
        ) VALUES (
            p_task_id, 'TL', p_approver_id, 'APPROVED', p_comments
        );
        
        -- Add comment
        add_comment(
            p_task_id => p_task_id,
            p_comment_text => NVL(p_comments, 'Approved by Team Leader'),
            p_comment_type => 'APPROVAL',
            p_commented_by => (SELECT username FROM app_users WHERE user_id = p_approver_id)
        );
        
        -- Send notification to Senior
        send_notification(
            p_task_id => p_task_id,
            p_user_id => v_senior_user_id,
            p_notification_type => 'APPROVAL_REQUIRED',
            p_notification_text => 'Task ready for Senior approval: ' || v_task_title
        );
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END approve_task_tl;

    -- =============================================
    -- Reject Task - Team Leader
    -- =============================================
    PROCEDURE reject_task_tl(
        p_task_id           IN NUMBER,
        p_approver_id       IN NUMBER,
        p_comments          IN CLOB
    ) IS
        v_task_title VARCHAR2(500);
        v_tm_user_id NUMBER;
    BEGIN
        -- Get task info
        SELECT title, assigned_to_tm 
        INTO v_task_title, v_tm_user_id
        FROM tasks 
        WHERE task_id = p_task_id;
        
        -- Update task
        UPDATE tasks
        SET status = 'REJECTED',
            last_updated_by = (SELECT username FROM app_users WHERE user_id = p_approver_id),
            last_updated_date = SYSDATE
        WHERE task_id = p_task_id;
        
        -- Record rejection
        INSERT INTO task_approvals (
            task_id, approval_level, approver_id, approval_status, comments
        ) VALUES (
            p_task_id, 'TL', p_approver_id, 'REJECTED', p_comments
        );
        
        -- Add comment
        add_comment(
            p_task_id => p_task_id,
            p_comment_text => p_comments,
            p_comment_type => 'REJECTION',
            p_commented_by => (SELECT username FROM app_users WHERE user_id = p_approver_id)
        );
        
        -- Send notification to TM
        send_notification(
            p_task_id => p_task_id,
            p_user_id => v_tm_user_id,
            p_notification_type => 'TASK_REJECTED',
            p_notification_text => 'Task rejected by Team Leader: ' || v_task_title || '. Please rework.'
        );
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END reject_task_tl;

    -- =============================================
    -- Approve Task - Senior
    -- =============================================
    PROCEDURE approve_task_senior(
        p_task_id           IN NUMBER,
        p_approver_id       IN NUMBER,
        p_comments          IN CLOB DEFAULT NULL
    ) IS
        v_task_title VARCHAR2(500);
        v_tm_user_id NUMBER;
        v_tl_user_id NUMBER;
    BEGIN
        -- Get task info
        SELECT title, assigned_to_tm, assigned_to_tl
        INTO v_task_title, v_tm_user_id, v_tl_user_id
        FROM tasks 
        WHERE task_id = p_task_id;
        
        -- Update task
        UPDATE tasks
        SET status = 'APPROVED',
            senior_approval_date = SYSDATE,
            senior_approved_by = p_approver_id,
            completed_date = SYSDATE,
            last_updated_by = (SELECT username FROM app_users WHERE user_id = p_approver_id),
            last_updated_date = SYSDATE
        WHERE task_id = p_task_id;
        
        -- Record approval
        INSERT INTO task_approvals (
            task_id, approval_level, approver_id, approval_status, comments
        ) VALUES (
            p_task_id, 'SENIOR', p_approver_id, 'APPROVED', p_comments
        );
        
        -- Add comment
        add_comment(
            p_task_id => p_task_id,
            p_comment_text => NVL(p_comments, 'Approved by Senior'),
            p_comment_type => 'APPROVAL',
            p_commented_by => (SELECT username FROM app_users WHERE user_id = p_approver_id)
        );
        
        -- Send notification to TM
        send_notification(
            p_task_id => p_task_id,
            p_user_id => v_tm_user_id,
            p_notification_type => 'TASK_APPROVED',
            p_notification_text => 'Congratulations! Task approved: ' || v_task_title
        );
        
        -- Send notification to TL
        send_notification(
            p_task_id => p_task_id,
            p_user_id => v_tl_user_id,
            p_notification_type => 'TASK_APPROVED',
            p_notification_text => 'Task approved by Senior: ' || v_task_title
        );
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END approve_task_senior;

    -- =============================================
    -- Reject Task - Senior
    -- =============================================
    PROCEDURE reject_task_senior(
        p_task_id           IN NUMBER,
        p_approver_id       IN NUMBER,
        p_comments          IN CLOB
    ) IS
        v_task_title VARCHAR2(500);
        v_tm_user_id NUMBER;
        v_tl_user_id NUMBER;
    BEGIN
        -- Get task info
        SELECT title, assigned_to_tm, assigned_to_tl
        INTO v_task_title, v_tm_user_id, v_tl_user_id
        FROM tasks 
        WHERE task_id = p_task_id;
        
        -- Update task
        UPDATE tasks
        SET status = 'REJECTED',
            last_updated_by = (SELECT username FROM app_users WHERE user_id = p_approver_id),
            last_updated_date = SYSDATE
        WHERE task_id = p_task_id;
        
        -- Record rejection
        INSERT INTO task_approvals (
            task_id, approval_level, approver_id, approval_status, comments
        ) VALUES (
            p_task_id, 'SENIOR', p_approver_id, 'REJECTED', p_comments
        );
        
        -- Add comment
        add_comment(
            p_task_id => p_task_id,
            p_comment_text => p_comments,
            p_comment_type => 'REJECTION',
            p_commented_by => (SELECT username FROM app_users WHERE user_id = p_approver_id)
        );
        
        -- Send notification to TM
        send_notification(
            p_task_id => p_task_id,
            p_user_id => v_tm_user_id,
            p_notification_type => 'TASK_REJECTED',
            p_notification_text => 'Task rejected by Senior: ' || v_task_title || '. Please rework.'
        );
        
        -- Send notification to TL
        send_notification(
            p_task_id => p_task_id,
            p_user_id => v_tl_user_id,
            p_notification_type => 'TASK_REJECTED',
            p_notification_text => 'Task rejected by Senior: ' || v_task_title
        );
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END reject_task_senior;

    -- =============================================
    -- Cancel Task
    -- =============================================
    PROCEDURE cancel_task(
        p_task_id           IN NUMBER,
        p_cancelled_by      IN VARCHAR2,
        p_reason            IN CLOB
    ) IS
    BEGIN
        UPDATE tasks
        SET status = 'CANCELLED',
            last_updated_by = p_cancelled_by,
            last_updated_date = SYSDATE
        WHERE task_id = p_task_id;
        
        add_comment(
            p_task_id => p_task_id,
            p_comment_text => 'Task cancelled. Reason: ' || p_reason,
            p_comment_type => 'STATUS_CHANGE',
            p_commented_by => p_cancelled_by
        );
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END cancel_task;

    -- =============================================
    -- Add Comment
    -- =============================================
    PROCEDURE add_comment(
        p_task_id           IN NUMBER,
        p_comment_text      IN CLOB,
        p_comment_type      IN VARCHAR2 DEFAULT 'GENERAL',
        p_commented_by      IN VARCHAR2
    ) IS
        v_user_id NUMBER;
    BEGIN
        v_user_id := get_user_id(p_commented_by);
        
        INSERT INTO task_comments (
            task_id,
            comment_text,
            comment_type,
            commented_by,
            commented_by_user_id
        ) VALUES (
            p_task_id,
            p_comment_text,
            p_comment_type,
            p_commented_by,
            v_user_id
        );
    END add_comment;

    -- =============================================
    -- Send Notification
    -- =============================================
    PROCEDURE send_notification(
        p_task_id           IN NUMBER,
        p_user_id           IN NUMBER,
        p_notification_type IN VARCHAR2,
        p_notification_text IN VARCHAR2
    ) IS
    BEGIN
        INSERT INTO task_notifications (
            task_id,
            user_id,
            notification_type,
            notification_text
        ) VALUES (
            p_task_id,
            p_user_id,
            p_notification_type,
            p_notification_text
        );
    END send_notification;

    -- =============================================
    -- Mark Notification Read
    -- =============================================
    PROCEDURE mark_notification_read(
        p_notification_id   IN NUMBER
    ) IS
    BEGIN
        UPDATE task_notifications
        SET is_read = 'Y',
            read_date = SYSDATE
        WHERE notification_id = p_notification_id;
        
        COMMIT;
    END mark_notification_read;

    -- =============================================
    -- Get User ID
    -- =============================================
    FUNCTION get_user_id(p_username IN VARCHAR2) RETURN NUMBER IS
        v_user_id NUMBER;
    BEGIN
        SELECT user_id INTO v_user_id
        FROM app_users
        WHERE username = p_username;
        
        RETURN v_user_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_user_id;

    -- =============================================
    -- Get User Role
    -- =============================================
    FUNCTION get_user_role(p_username IN VARCHAR2) RETURN VARCHAR2 IS
        v_role VARCHAR2(20);
    BEGIN
        SELECT role INTO v_role
        FROM app_users
        WHERE username = p_username;
        
        RETURN v_role;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_user_role;

    -- =============================================
    -- Get Task Status
    -- =============================================
    FUNCTION get_task_status(p_task_id IN NUMBER) RETURN VARCHAR2 IS
        v_status VARCHAR2(30);
    BEGIN
        SELECT status INTO v_status
        FROM tasks
        WHERE task_id = p_task_id;
        
        RETURN v_status;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_task_status;

END pkg_task_management;
/

SHOW ERRORS;

COMMIT;
