-- =====================================================
-- ORACLE APEX TASK MANAGEMENT - WORKFLOW & NOTIFICATIONS
-- =====================================================
-- This script implements the complete workflow engine and
-- notification system for the task management application
-- =====================================================

-- =====================================================
-- 1. WORKFLOW STATE MACHINE
-- =====================================================

-- Package for Workflow Management
CREATE OR REPLACE PACKAGE pkg_workflow_engine AS
    
    -- Workflow state transitions
    TYPE t_transition IS RECORD (
        from_status VARCHAR2(30),
        to_status VARCHAR2(30),
        required_role VARCHAR2(10),
        action_name VARCHAR2(50)
    );
    
    TYPE t_transitions IS TABLE OF t_transition;
    
    -- Get allowed transitions for a task
    FUNCTION get_allowed_transitions(
        p_task_id IN NUMBER,
        p_user_id IN NUMBER
    ) RETURN t_transitions PIPELINED;
    
    -- Execute workflow transition
    PROCEDURE execute_transition(
        p_task_id IN NUMBER,
        p_user_id IN NUMBER,
        p_action IN VARCHAR2,
        p_comments IN CLOB DEFAULT NULL
    );
    
    -- Check if transition is allowed
    FUNCTION is_transition_allowed(
        p_task_id IN NUMBER,
        p_user_id IN NUMBER,
        p_action IN VARCHAR2
    ) RETURN BOOLEAN;
    
    -- Get next approver
    FUNCTION get_next_approver(
        p_task_id IN NUMBER,
        p_current_status IN VARCHAR2
    ) RETURN NUMBER;
    
END pkg_workflow_engine;
/

CREATE OR REPLACE PACKAGE BODY pkg_workflow_engine AS

    FUNCTION get_allowed_transitions(
        p_task_id IN NUMBER,
        p_user_id IN NUMBER
    ) RETURN t_transitions PIPELINED IS
        
        v_task_status VARCHAR2(30);
        v_user_role VARCHAR2(10);
        v_is_creator BOOLEAN := FALSE;
        v_is_assigned_tl BOOLEAN := FALSE;
        v_is_assigned_tm BOOLEAN := FALSE;
        v_transition t_transition;
        
    BEGIN
        -- Get task details and user role
        SELECT t.status, u.role_code,
               CASE WHEN t.created_by = p_user_id THEN 1 ELSE 0 END,
               CASE WHEN t.assigned_to_tl = p_user_id THEN 1 ELSE 0 END,
               CASE WHEN t.assigned_to_tm = p_user_id THEN 1 ELSE 0 END
        INTO v_task_status, v_user_role, v_is_creator, v_is_assigned_tl, v_is_assigned_tm
        FROM tm_tasks t, tm_users u
        WHERE t.task_id = p_task_id
        AND u.user_id = p_user_id;
        
        v_is_creator := (v_is_creator = 1);
        v_is_assigned_tl := (v_is_assigned_tl = 1);
        v_is_assigned_tm := (v_is_assigned_tm = 1);
        
        -- Define allowed transitions based on current status and user role
        CASE v_task_status
            WHEN 'NEW' THEN
                -- PM can assign to TL, TL can assign to TM
                IF v_user_role = 'PM' AND v_is_creator THEN
                    v_transition.from_status := 'NEW';
                    v_transition.to_status := 'NEW';
                    v_transition.required_role := 'PM';
                    v_transition.action_name := 'ASSIGN_TO_TL';
                    PIPE ROW(v_transition);
                    
                    v_transition.action_name := 'CANCEL';
                    v_transition.to_status := 'CANCELLED';
                    PIPE ROW(v_transition);
                END IF;
                
                IF v_user_role = 'TL' AND v_is_assigned_tl THEN
                    v_transition.from_status := 'NEW';
                    v_transition.to_status := 'IN_PROGRESS';
                    v_transition.required_role := 'TL';
                    v_transition.action_name := 'ASSIGN_TO_TM';
                    PIPE ROW(v_transition);
                END IF;
                
            WHEN 'IN_PROGRESS' THEN
                -- TM can submit for review
                IF v_user_role = 'TM' AND v_is_assigned_tm THEN
                    v_transition.from_status := 'IN_PROGRESS';
                    v_transition.to_status := 'PENDING_TL_APPROVAL';
                    v_transition.required_role := 'TM';
                    v_transition.action_name := 'SUBMIT_FOR_REVIEW';
                    PIPE ROW(v_transition);
                END IF;
                
                -- PM can cancel
                IF v_user_role = 'PM' AND v_is_creator THEN
                    v_transition.from_status := 'IN_PROGRESS';
                    v_transition.to_status := 'CANCELLED';
                    v_transition.required_role := 'PM';
                    v_transition.action_name := 'CANCEL';
                    PIPE ROW(v_transition);
                END IF;
                
            WHEN 'PENDING_TL_APPROVAL' THEN
                -- TL can approve or reject
                IF v_user_role = 'TL' AND v_is_assigned_tl THEN
                    v_transition.from_status := 'PENDING_TL_APPROVAL';
                    v_transition.to_status := 'PENDING_SENIOR_APPROVAL';
                    v_transition.required_role := 'TL';
                    v_transition.action_name := 'APPROVE';
                    PIPE ROW(v_transition);
                    
                    v_transition.to_status := 'REJECTED';
                    v_transition.action_name := 'REJECT';
                    PIPE ROW(v_transition);
                END IF;
                
            WHEN 'PENDING_SENIOR_APPROVAL' THEN
                -- Senior can approve or reject
                IF v_user_role = 'SENIOR' THEN
                    v_transition.from_status := 'PENDING_SENIOR_APPROVAL';
                    v_transition.to_status := 'APPROVED';
                    v_transition.required_role := 'SENIOR';
                    v_transition.action_name := 'FINAL_APPROVE';
                    PIPE ROW(v_transition);
                    
                    v_transition.to_status := 'REJECTED';
                    v_transition.action_name := 'FINAL_REJECT';
                    PIPE ROW(v_transition);
                END IF;
                
            WHEN 'REJECTED' THEN
                -- TM can rework
                IF v_user_role = 'TM' AND v_is_assigned_tm THEN
                    v_transition.from_status := 'REJECTED';
                    v_transition.to_status := 'IN_PROGRESS';
                    v_transition.required_role := 'TM';
                    v_transition.action_name := 'REWORK';
                    PIPE ROW(v_transition);
                END IF;
                
            ELSE
                NULL; -- No transitions for APPROVED or CANCELLED
        END CASE;
        
        RETURN;
    END get_allowed_transitions;

    PROCEDURE execute_transition(
        p_task_id IN NUMBER,
        p_user_id IN NUMBER,
        p_action IN VARCHAR2,
        p_comments IN CLOB DEFAULT NULL
    ) IS
        v_new_status VARCHAR2(30);
        v_approval_level NUMBER;
    BEGIN
        -- Determine new status based on action
        CASE p_action
            WHEN 'ASSIGN_TO_TL' THEN
                v_new_status := 'NEW';
            WHEN 'ASSIGN_TO_TM' THEN
                v_new_status := 'IN_PROGRESS';
            WHEN 'SUBMIT_FOR_REVIEW' THEN
                v_new_status := 'PENDING_TL_APPROVAL';
                v_approval_level := 1;
            WHEN 'APPROVE' THEN
                v_new_status := 'PENDING_SENIOR_APPROVAL';
                v_approval_level := 2;
            WHEN 'REJECT' THEN
                v_new_status := 'REJECTED';
                v_approval_level := 1;
            WHEN 'FINAL_APPROVE' THEN
                v_new_status := 'APPROVED';
                v_approval_level := 2;
            WHEN 'FINAL_REJECT' THEN
                v_new_status := 'REJECTED';
                v_approval_level := 2;
            WHEN 'REWORK' THEN
                v_new_status := 'IN_PROGRESS';
            WHEN 'CANCEL' THEN
                v_new_status := 'CANCELLED';
            ELSE
                RAISE_APPLICATION_ERROR(-20001, 'Invalid action: ' || p_action);
        END CASE;
        
        -- Update task status
        UPDATE tm_tasks 
        SET status = v_new_status,
            completed_date = CASE WHEN v_new_status = 'APPROVED' THEN SYSDATE ELSE completed_date END
        WHERE task_id = p_task_id;
        
        -- Handle approvals
        IF v_approval_level IS NOT NULL THEN
            -- Update or insert approval record
            MERGE INTO tm_approvals a
            USING (SELECT p_task_id as task_id, p_user_id as approver_id, v_approval_level as approval_level FROM dual) src
            ON (a.task_id = src.task_id AND a.approval_level = src.approval_level)
            WHEN MATCHED THEN
                UPDATE SET 
                    status = CASE WHEN p_action IN ('APPROVE', 'FINAL_APPROVE') THEN 'APPROVED' ELSE 'REJECTED' END,
                    comments = p_comments,
                    action_date = SYSDATE
            WHEN NOT MATCHED THEN
                INSERT (approval_id, task_id, approver_id, approval_level, status, comments, action_date)
                VALUES (tm_approvals_seq.NEXTVAL, src.task_id, src.approver_id, src.approval_level,
                       CASE WHEN p_action IN ('APPROVE', 'FINAL_APPROVE') THEN 'APPROVED' ELSE 'REJECTED' END,
                       p_comments, SYSDATE);
            
            -- Create next level approval if needed
            IF p_action = 'SUBMIT_FOR_REVIEW' THEN
                INSERT INTO tm_approvals (approval_id, task_id, approver_id, approval_level, status)
                SELECT tm_approvals_seq.NEXTVAL, p_task_id, assigned_to_tl, 1, 'PENDING'
                FROM tm_tasks WHERE task_id = p_task_id;
            ELSIF p_action = 'APPROVE' THEN
                INSERT INTO tm_approvals (approval_id, task_id, approver_id, approval_level, status)
                SELECT tm_approvals_seq.NEXTVAL, p_task_id, user_id, 2, 'PENDING'
                FROM tm_users WHERE role_code = 'SENIOR' AND ROWNUM = 1;
            END IF;
        END IF;
        
        -- Add comment
        INSERT INTO tm_comments (comment_id, task_id, user_id, comment_text, comment_type)
        VALUES (tm_comments_seq.NEXTVAL, p_task_id, p_user_id, 
                NVL(p_comments, 'Action: ' || p_action), 
                CASE WHEN p_action IN ('APPROVE', 'FINAL_APPROVE') THEN 'APPROVAL' 
                     WHEN p_action IN ('REJECT', 'FINAL_REJECT') THEN 'REJECTION' 
                     ELSE 'STATUS_CHANGE' END);
        
        COMMIT;
    END execute_transition;

    FUNCTION is_transition_allowed(
        p_task_id IN NUMBER,
        p_user_id IN NUMBER,
        p_action IN VARCHAR2
    ) RETURN BOOLEAN IS
        v_count NUMBER := 0;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM TABLE(get_allowed_transitions(p_task_id, p_user_id))
        WHERE action_name = p_action;
        
        RETURN v_count > 0;
    END is_transition_allowed;

    FUNCTION get_next_approver(
        p_task_id IN NUMBER,
        p_current_status IN VARCHAR2
    ) RETURN NUMBER IS
        v_approver_id NUMBER;
    BEGIN
        CASE p_current_status
            WHEN 'PENDING_TL_APPROVAL' THEN
                SELECT assigned_to_tl INTO v_approver_id FROM tm_tasks WHERE task_id = p_task_id;
            WHEN 'PENDING_SENIOR_APPROVAL' THEN
                SELECT user_id INTO v_approver_id FROM tm_users WHERE role_code = 'SENIOR' AND ROWNUM = 1;
            ELSE
                v_approver_id := NULL;
        END CASE;
        
        RETURN v_approver_id;
    END get_next_approver;

END pkg_workflow_engine;
/

-- =====================================================
-- 2. ENHANCED NOTIFICATION SYSTEM
-- =====================================================

-- Package for Notification Management
CREATE OR REPLACE PACKAGE pkg_notification_system AS
    
    -- Notification types
    SUBTYPE t_notification_type IS VARCHAR2(50);
    
    c_task_assigned CONSTANT t_notification_type := 'TASK_ASSIGNED';
    c_task_submitted CONSTANT t_notification_type := 'TASK_SUBMITTED';
    c_approval_required CONSTANT t_notification_type := 'APPROVAL_REQUIRED';
    c_task_approved CONSTANT t_notification_type := 'TASK_APPROVED';
    c_task_rejected CONSTANT t_notification_type := 'TASK_REJECTED';
    c_task_overdue CONSTANT t_notification_type := 'TASK_OVERDUE';
    c_task_cancelled CONSTANT t_notification_type := 'TASK_CANCELLED';
    
    -- Send notification
    PROCEDURE send_notification(
        p_user_id IN NUMBER,
        p_task_id IN NUMBER,
        p_notification_type IN VARCHAR2,
        p_message IN VARCHAR2,
        p_send_email IN BOOLEAN DEFAULT FALSE
    );
    
    -- Send email notification
    PROCEDURE send_email_notification(
        p_user_id IN NUMBER,
        p_task_id IN NUMBER,
        p_subject IN VARCHAR2,
        p_body IN CLOB
    );
    
    -- Mark notification as read
    PROCEDURE mark_as_read(
        p_notification_id IN NUMBER,
        p_user_id IN NUMBER
    );
    
    -- Mark all notifications as read for user
    PROCEDURE mark_all_as_read(p_user_id IN NUMBER);
    
    -- Get unread count
    FUNCTION get_unread_count(p_user_id IN NUMBER) RETURN NUMBER;
    
    -- Clean old notifications
    PROCEDURE cleanup_old_notifications(p_days_old IN NUMBER DEFAULT 30);
    
    -- Send overdue task notifications
    PROCEDURE send_overdue_notifications;
    
END pkg_notification_system;
/

CREATE OR REPLACE PACKAGE BODY pkg_notification_system AS

    PROCEDURE send_notification(
        p_user_id IN NUMBER,
        p_task_id IN NUMBER,
        p_notification_type IN VARCHAR2,
        p_message IN VARCHAR2,
        p_send_email IN BOOLEAN DEFAULT FALSE
    ) IS
        v_user_email VARCHAR2(200);
        v_task_title VARCHAR2(500);
    BEGIN
        -- Insert notification
        INSERT INTO tm_notifications (
            notification_id, user_id, task_id, message, notification_type
        ) VALUES (
            tm_notifications_seq.NEXTVAL, p_user_id, p_task_id, p_message, p_notification_type
        );
        
        -- Send email if requested
        IF p_send_email THEN
            SELECT u.email, t.title
            INTO v_user_email, v_task_title
            FROM tm_users u, tm_tasks t
            WHERE u.user_id = p_user_id
            AND t.task_id = p_task_id;
            
            send_email_notification(
                p_user_id => p_user_id,
                p_task_id => p_task_id,
                p_subject => 'Task Management: ' || v_task_title,
                p_body => p_message
            );
        END IF;
        
        COMMIT;
    END send_notification;

    PROCEDURE send_email_notification(
        p_user_id IN NUMBER,
        p_task_id IN NUMBER,
        p_subject IN VARCHAR2,
        p_body IN CLOB
    ) IS
        v_user_email VARCHAR2(200);
        v_user_name VARCHAR2(200);
        v_email_body CLOB;
    BEGIN
        -- Get user details
        SELECT email, full_name
        INTO v_user_email, v_user_name
        FROM tm_users
        WHERE user_id = p_user_id;
        
        -- Build email body with HTML template
        v_email_body := '
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; }
                .header { background-color: #2196F3; color: white; padding: 20px; }
                .content { padding: 20px; }
                .footer { background-color: #f5f5f5; padding: 10px; font-size: 12px; }
                .button { background-color: #2196F3; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px; }
            </style>
        </head>
        <body>
            <div class="header">
                <h2>Task Management System</h2>
            </div>
            <div class="content">
                <p>Dear ' || v_user_name || ',</p>
                <p>' || p_body || '</p>
                <p><a href="' || apex_util.host_url || apex_application.g_flow_alias || '" class="button">View Task</a></p>
            </div>
            <div class="footer">
                <p>This is an automated notification from the Task Management System.</p>
            </div>
        </body>
        </html>';
        
        -- Send email using APEX_MAIL
        apex_mail.send(
            p_to => v_user_email,
            p_from => 'noreply@taskmanagement.com',
            p_subject => p_subject,
            p_body => v_email_body,
            p_body_html => v_email_body
        );
        
        -- Push the email queue
        apex_mail.push_queue;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Log email error but don't fail the notification
            INSERT INTO tm_comments (comment_id, task_id, user_id, comment_text, comment_type)
            VALUES (tm_comments_seq.NEXTVAL, p_task_id, p_user_id, 
                    'Email notification failed: ' || SQLERRM, 'GENERAL');
            COMMIT;
    END send_email_notification;

    PROCEDURE mark_as_read(
        p_notification_id IN NUMBER,
        p_user_id IN NUMBER
    ) IS
    BEGIN
        UPDATE tm_notifications
        SET is_read = 'Y',
            read_date = SYSDATE
        WHERE notification_id = p_notification_id
        AND user_id = p_user_id;
        
        COMMIT;
    END mark_as_read;

    PROCEDURE mark_all_as_read(p_user_id IN NUMBER) IS
    BEGIN
        UPDATE tm_notifications
        SET is_read = 'Y',
            read_date = SYSDATE
        WHERE user_id = p_user_id
        AND is_read = 'N';
        
        COMMIT;
    END mark_all_as_read;

    FUNCTION get_unread_count(p_user_id IN NUMBER) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM tm_notifications
        WHERE user_id = p_user_id
        AND is_read = 'N';
        
        RETURN v_count;
    END get_unread_count;

    PROCEDURE cleanup_old_notifications(p_days_old IN NUMBER DEFAULT 30) IS
    BEGIN
        DELETE FROM tm_notifications
        WHERE created_date < SYSDATE - p_days_old
        AND is_read = 'Y';
        
        COMMIT;
    END cleanup_old_notifications;

    PROCEDURE send_overdue_notifications IS
        CURSOR c_overdue_tasks IS
            SELECT t.task_id, t.title, t.due_date, t.assigned_to_tm, t.assigned_to_tl,
                   tm.full_name as tm_name, tl.full_name as tl_name
            FROM tm_tasks t
            LEFT JOIN tm_users tm ON t.assigned_to_tm = tm.user_id
            LEFT JOIN tm_users tl ON t.assigned_to_tl = tl.user_id
            WHERE t.due_date < SYSDATE
            AND t.status NOT IN ('APPROVED', 'CANCELLED')
            AND NOT EXISTS (
                SELECT 1 FROM tm_notifications n
                WHERE n.task_id = t.task_id
                AND n.notification_type = c_task_overdue
                AND n.created_date > SYSDATE - 1 -- Don't send duplicate overdue notifications within 24 hours
            );
    BEGIN
        FOR rec IN c_overdue_tasks LOOP
            -- Notify team member
            IF rec.assigned_to_tm IS NOT NULL THEN
                send_notification(
                    p_user_id => rec.assigned_to_tm,
                    p_task_id => rec.task_id,
                    p_notification_type => c_task_overdue,
                    p_message => 'Task "' || rec.title || '" is overdue (due: ' || TO_CHAR(rec.due_date, 'DD-MON-YYYY') || ')',
                    p_send_email => TRUE
                );
            END IF;
            
            -- Notify team leader
            IF rec.assigned_to_tl IS NOT NULL THEN
                send_notification(
                    p_user_id => rec.assigned_to_tl,
                    p_task_id => rec.task_id,
                    p_notification_type => c_task_overdue,
                    p_message => 'Team task "' || rec.title || '" assigned to ' || rec.tm_name || ' is overdue',
                    p_send_email => TRUE
                );
            END IF;
        END LOOP;
    END send_overdue_notifications;

END pkg_notification_system;
/

-- =====================================================
-- 3. ENHANCED TRIGGERS WITH NOTIFICATIONS
-- =====================================================

-- Replace the existing trigger with enhanced version
CREATE OR REPLACE TRIGGER trg_task_status_notification_enhanced
    AFTER UPDATE OF status ON tm_tasks
    FOR EACH ROW
DECLARE
    v_message VARCHAR2(1000);
    v_notification_type VARCHAR2(50);
    v_notify_user_id NUMBER;
    v_send_email BOOLEAN := FALSE;
BEGIN
    -- Only proceed if status actually changed
    IF :OLD.status != :NEW.status THEN
        
        CASE :NEW.status
            WHEN 'IN_PROGRESS' THEN
                v_message := 'Task "' || :NEW.title || '" has been assigned to you.';
                v_notification_type := pkg_notification_system.c_task_assigned;
                v_notify_user_id := :NEW.assigned_to_tm;
                v_send_email := TRUE;
                
            WHEN 'PENDING_TL_APPROVAL' THEN
                v_message := 'Task "' || :NEW.title || '" has been submitted for your approval.';
                v_notification_type := pkg_notification_system.c_approval_required;
                v_notify_user_id := :NEW.assigned_to_tl;
                v_send_email := TRUE;
                
            WHEN 'PENDING_SENIOR_APPROVAL' THEN
                v_message := 'Task "' || :NEW.title || '" requires senior approval.';
                v_notification_type := pkg_notification_system.c_approval_required;
                SELECT user_id INTO v_notify_user_id FROM tm_users WHERE role_code = 'SENIOR' AND ROWNUM = 1;
                v_send_email := TRUE;
                
            WHEN 'APPROVED' THEN
                v_message := 'Congratulations! Task "' || :NEW.title || '" has been approved.';
                v_notification_type := pkg_notification_system.c_task_approved;
                v_notify_user_id := :NEW.assigned_to_tm;
                v_send_email := TRUE;
                
            WHEN 'REJECTED' THEN
                v_message := 'Task "' || :NEW.title || '" has been rejected and requires rework. Please check the comments.';
                v_notification_type := pkg_notification_system.c_task_rejected;
                v_notify_user_id := :NEW.assigned_to_tm;
                v_send_email := TRUE;
                
            WHEN 'CANCELLED' THEN
                v_message := 'Task "' || :NEW.title || '" has been cancelled.';
                v_notification_type := pkg_notification_system.c_task_cancelled;
                -- Notify both TL and TM if assigned
                IF :NEW.assigned_to_tl IS NOT NULL THEN
                    pkg_notification_system.send_notification(
                        p_user_id => :NEW.assigned_to_tl,
                        p_task_id => :NEW.task_id,
                        p_notification_type => v_notification_type,
                        p_message => v_message,
                        p_send_email => TRUE
                    );
                END IF;
                v_notify_user_id := :NEW.assigned_to_tm;
                
            ELSE
                v_notify_user_id := NULL;
        END CASE;
        
        -- Send notification if we have a user to notify
        IF v_notify_user_id IS NOT NULL THEN
            pkg_notification_system.send_notification(
                p_user_id => v_notify_user_id,
                p_task_id => :NEW.task_id,
                p_notification_type => v_notification_type,
                p_message => v_message,
                p_send_email => v_send_email
            );
        END IF;
    END IF;
END;
/

-- =====================================================
-- 4. SCHEDULED JOBS FOR MAINTENANCE
-- =====================================================

-- Job to send overdue notifications (runs daily at 9 AM)
BEGIN
    DBMS_SCHEDULER.CREATE_JOB(
        job_name => 'TASK_OVERDUE_NOTIFICATIONS',
        job_type => 'PLSQL_BLOCK',
        job_action => 'BEGIN pkg_notification_system.send_overdue_notifications; END;',
        start_date => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=9; BYMINUTE=0; BYSECOND=0',
        enabled => TRUE,
        comments => 'Send daily overdue task notifications'
    );
END;
/

-- Job to cleanup old notifications (runs weekly)
BEGIN
    DBMS_SCHEDULER.CREATE_JOB(
        job_name => 'CLEANUP_OLD_NOTIFICATIONS',
        job_type => 'PLSQL_BLOCK',
        job_action => 'BEGIN pkg_notification_system.cleanup_old_notifications(30); END;',
        start_date => SYSTIMESTAMP,
        repeat_interval => 'FREQ=WEEKLY; BYDAY=SUN; BYHOUR=2; BYMINUTE=0; BYSECOND=0',
        enabled => TRUE,
        comments => 'Weekly cleanup of old notifications'
    );
END;
/

-- =====================================================
-- 5. APEX INTEGRATION FUNCTIONS
-- =====================================================

-- Function to get workflow actions for APEX page
CREATE OR REPLACE FUNCTION get_workflow_actions_json(
    p_task_id IN NUMBER,
    p_user_id IN NUMBER
) RETURN CLOB IS
    v_json CLOB;
BEGIN
    SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
            'action' VALUE action_name,
            'label' VALUE CASE action_name
                WHEN 'ASSIGN_TO_TL' THEN 'Assign to Team Leader'
                WHEN 'ASSIGN_TO_TM' THEN 'Assign to Team Member'
                WHEN 'SUBMIT_FOR_REVIEW' THEN 'Submit for Review'
                WHEN 'APPROVE' THEN 'Approve'
                WHEN 'REJECT' THEN 'Reject'
                WHEN 'FINAL_APPROVE' THEN 'Final Approve'
                WHEN 'FINAL_REJECT' THEN 'Final Reject'
                WHEN 'REWORK' THEN 'Start Rework'
                WHEN 'CANCEL' THEN 'Cancel Task'
                ELSE action_name
            END,
            'button_class' VALUE CASE action_name
                WHEN 'APPROVE' THEN 't-Button--success'
                WHEN 'FINAL_APPROVE' THEN 't-Button--success'
                WHEN 'REJECT' THEN 't-Button--danger'
                WHEN 'FINAL_REJECT' THEN 't-Button--danger'
                WHEN 'CANCEL' THEN 't-Button--warning'
                ELSE 't-Button--hot'
            END,
            'requires_comments' VALUE CASE 
                WHEN action_name IN ('REJECT', 'FINAL_REJECT', 'CANCEL') THEN 'Y'
                ELSE 'N'
            END
        )
    )
    INTO v_json
    FROM TABLE(pkg_workflow_engine.get_allowed_transitions(p_task_id, p_user_id));
    
    RETURN NVL(v_json, '[]');
END;
/

-- Function to get notification summary for user
CREATE OR REPLACE FUNCTION get_notification_summary_json(p_user_id IN NUMBER)
RETURN CLOB IS
    v_json CLOB;
BEGIN
    SELECT JSON_OBJECT(
        'unread_count' VALUE COUNT(CASE WHEN is_read = 'N' THEN 1 END),
        'total_count' VALUE COUNT(*),
        'recent_notifications' VALUE JSON_ARRAYAGG(
            JSON_OBJECT(
                'id' VALUE notification_id,
                'message' VALUE message,
                'type' VALUE notification_type,
                'is_read' VALUE is_read,
                'created_date' VALUE TO_CHAR(created_date, 'DD-MON-YYYY HH24:MI'),
                'task_id' VALUE task_id
            ) ORDER BY created_date DESC
        )
    )
    INTO v_json
    FROM (
        SELECT * FROM tm_notifications 
        WHERE user_id = p_user_id 
        AND created_date > SYSDATE - 7  -- Last 7 days
        ORDER BY created_date DESC
        FETCH FIRST 10 ROWS ONLY
    );
    
    RETURN NVL(v_json, '{"unread_count":0,"total_count":0,"recent_notifications":[]}');
END;
/

-- =====================================================
-- 6. REAL-TIME UPDATES (WEBSOCKET SIMULATION)
-- =====================================================

-- Table to track real-time updates
CREATE TABLE tm_realtime_updates (
    update_id NUMBER PRIMARY KEY,
    user_id NUMBER NOT NULL,
    update_type VARCHAR2(50) NOT NULL,
    update_data CLOB,
    created_date DATE DEFAULT SYSDATE,
    processed VARCHAR2(1) DEFAULT 'N',
    
    CONSTRAINT fk_realtime_user FOREIGN KEY (user_id) REFERENCES tm_users(user_id)
);

CREATE SEQUENCE tm_realtime_updates_seq START WITH 1 INCREMENT BY 1;

-- Procedure to queue real-time updates
CREATE OR REPLACE PROCEDURE queue_realtime_update(
    p_user_id IN NUMBER,
    p_update_type IN VARCHAR2,
    p_update_data IN CLOB
) IS
BEGIN
    INSERT INTO tm_realtime_updates (
        update_id, user_id, update_type, update_data
    ) VALUES (
        tm_realtime_updates_seq.NEXTVAL, p_user_id, p_update_type, p_update_data
    );
    
    COMMIT;
END;
/

-- Function to get pending updates for user (for AJAX polling)
CREATE OR REPLACE FUNCTION get_pending_updates_json(p_user_id IN NUMBER)
RETURN CLOB IS
    v_json CLOB;
BEGIN
    SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
            'id' VALUE update_id,
            'type' VALUE update_type,
            'data' VALUE JSON_QUERY(update_data, '$'),
            'timestamp' VALUE TO_CHAR(created_date, 'YYYY-MM-DD"T"HH24:MI:SS')
        ) ORDER BY created_date
    )
    INTO v_json
    FROM tm_realtime_updates
    WHERE user_id = p_user_id
    AND processed = 'N';
    
    -- Mark as processed
    UPDATE tm_realtime_updates
    SET processed = 'Y'
    WHERE user_id = p_user_id
    AND processed = 'N';
    
    COMMIT;
    
    RETURN NVL(v_json, '[]');
END;
/

-- =====================================================
-- 7. PERFORMANCE MONITORING
-- =====================================================

-- View for workflow performance metrics
CREATE OR REPLACE VIEW v_workflow_metrics AS
SELECT 
    'Total Tasks' as metric_name,
    COUNT(*) as metric_value,
    'tasks' as unit
FROM tm_tasks
UNION ALL
SELECT 
    'Average Completion Time (Days)' as metric_name,
    ROUND(AVG(completed_date - created_date), 2) as metric_value,
    'days' as unit
FROM tm_tasks 
WHERE status = 'APPROVED' AND completed_date IS NOT NULL
UNION ALL
SELECT 
    'Tasks Pending Approval' as metric_name,
    COUNT(*) as metric_value,
    'tasks' as unit
FROM tm_tasks 
WHERE status LIKE 'PENDING%'
UNION ALL
SELECT 
    'Overdue Tasks' as metric_name,
    COUNT(*) as metric_value,
    'tasks' as unit
FROM tm_tasks 
WHERE due_date < SYSDATE AND status NOT IN ('APPROVED', 'CANCELLED')
UNION ALL
SELECT 
    'Approval Success Rate (%)' as metric_name,
    ROUND((COUNT(CASE WHEN status = 'APPROVED' THEN 1 END) / COUNT(*)) * 100, 2) as metric_value,
    'percent' as unit
FROM tm_tasks 
WHERE status IN ('APPROVED', 'REJECTED');

-- =====================================================
-- COMMIT ALL CHANGES
-- =====================================================
COMMIT;

-- Display completion message
SELECT 'Advanced workflow engine and notification system created!' as status FROM dual;
SELECT 'Real-time updates and performance monitoring ready' as realtime_status FROM dual;
SELECT 'Email notifications and scheduled jobs configured' as email_status FROM dual;
SELECT 'Complete task management workflow implemented' as workflow_status FROM dual;