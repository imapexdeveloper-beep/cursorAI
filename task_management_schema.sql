-- =====================================================
-- ORACLE APEX TASK MANAGEMENT SYSTEM - DATABASE SCHEMA
-- =====================================================
-- Author: Oracle APEX Expert
-- Purpose: Complete task management system with approval workflow
-- Roles: PM, TL, TM, Senior
-- =====================================================

-- Drop existing objects (for clean installation)
BEGIN
    FOR c IN (SELECT table_name FROM user_tables WHERE table_name IN ('TM_TASKS', 'TM_USERS', 'TM_APPROVALS', 'TM_NOTIFICATIONS', 'TM_COMMENTS')) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || c.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;
    
    FOR s IN (SELECT sequence_name FROM user_sequences WHERE sequence_name LIKE 'TM_%_SEQ') LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/

-- =====================================================
-- 1. USERS TABLE
-- =====================================================
CREATE TABLE tm_users (
    user_id         NUMBER PRIMARY KEY,
    username        VARCHAR2(100) UNIQUE NOT NULL,
    full_name       VARCHAR2(200) NOT NULL,
    email           VARCHAR2(200) NOT NULL,
    role_code       VARCHAR2(10) NOT NULL CHECK (role_code IN ('PM', 'TL', 'TM', 'SENIOR')),
    team_id         NUMBER,
    manager_id      NUMBER,
    is_active       VARCHAR2(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    created_date    DATE DEFAULT SYSDATE,
    created_by      VARCHAR2(100) DEFAULT USER
);

CREATE SEQUENCE tm_users_seq START WITH 1 INCREMENT BY 1;

-- =====================================================
-- 2. TASKS TABLE
-- =====================================================
CREATE TABLE tm_tasks (
    task_id         NUMBER PRIMARY KEY,
    title           VARCHAR2(500) NOT NULL,
    description     CLOB,
    status          VARCHAR2(20) DEFAULT 'NEW' 
                    CHECK (status IN ('NEW', 'IN_PROGRESS', 'READY_FOR_REVIEW', 'PENDING_TL_APPROVAL', 
                                     'PENDING_SENIOR_APPROVAL', 'APPROVED', 'REJECTED', 'CANCELLED')),
    priority        VARCHAR2(10) DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    created_by      NUMBER NOT NULL,
    assigned_to_tl  NUMBER,
    assigned_to_tm  NUMBER,
    due_date        DATE,
    created_date    DATE DEFAULT SYSDATE,
    updated_date    DATE DEFAULT SYSDATE,
    completed_date  DATE,
    
    -- Foreign Keys
    CONSTRAINT fk_task_created_by FOREIGN KEY (created_by) REFERENCES tm_users(user_id),
    CONSTRAINT fk_task_assigned_tl FOREIGN KEY (assigned_to_tl) REFERENCES tm_users(user_id),
    CONSTRAINT fk_task_assigned_tm FOREIGN KEY (assigned_to_tm) REFERENCES tm_users(user_id)
);

CREATE SEQUENCE tm_tasks_seq START WITH 1 INCREMENT BY 1;

-- =====================================================
-- 3. APPROVALS TABLE
-- =====================================================
CREATE TABLE tm_approvals (
    approval_id     NUMBER PRIMARY KEY,
    task_id         NUMBER NOT NULL,
    approver_id     NUMBER NOT NULL,
    approval_level  NUMBER NOT NULL CHECK (approval_level IN (1, 2)), -- 1=TL, 2=Senior
    status          VARCHAR2(20) DEFAULT 'PENDING' 
                    CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    comments        CLOB,
    action_date     DATE,
    created_date    DATE DEFAULT SYSDATE,
    
    -- Foreign Keys
    CONSTRAINT fk_approval_task FOREIGN KEY (task_id) REFERENCES tm_tasks(task_id),
    CONSTRAINT fk_approval_user FOREIGN KEY (approver_id) REFERENCES tm_users(user_id),
    
    -- Unique constraint to prevent duplicate approvals
    CONSTRAINT uk_approval_task_level UNIQUE (task_id, approval_level)
);

CREATE SEQUENCE tm_approvals_seq START WITH 1 INCREMENT BY 1;

-- =====================================================
-- 4. NOTIFICATIONS TABLE
-- =====================================================
CREATE TABLE tm_notifications (
    notification_id NUMBER PRIMARY KEY,
    user_id         NUMBER NOT NULL,
    task_id         NUMBER NOT NULL,
    message         VARCHAR2(1000) NOT NULL,
    notification_type VARCHAR2(50) NOT NULL,
    is_read         VARCHAR2(1) DEFAULT 'N' CHECK (is_read IN ('Y', 'N')),
    created_date    DATE DEFAULT SYSDATE,
    read_date       DATE,
    
    -- Foreign Keys
    CONSTRAINT fk_notif_user FOREIGN KEY (user_id) REFERENCES tm_users(user_id),
    CONSTRAINT fk_notif_task FOREIGN KEY (task_id) REFERENCES tm_tasks(task_id)
);

CREATE SEQUENCE tm_notifications_seq START WITH 1 INCREMENT BY 1;

-- =====================================================
-- 5. COMMENTS TABLE
-- =====================================================
CREATE TABLE tm_comments (
    comment_id      NUMBER PRIMARY KEY,
    task_id         NUMBER NOT NULL,
    user_id         NUMBER NOT NULL,
    comment_text    CLOB NOT NULL,
    comment_type    VARCHAR2(20) DEFAULT 'GENERAL' 
                    CHECK (comment_type IN ('GENERAL', 'APPROVAL', 'REJECTION', 'STATUS_CHANGE')),
    created_date    DATE DEFAULT SYSDATE,
    
    -- Foreign Keys
    CONSTRAINT fk_comment_task FOREIGN KEY (task_id) REFERENCES tm_tasks(task_id),
    CONSTRAINT fk_comment_user FOREIGN KEY (user_id) REFERENCES tm_users(user_id)
);

CREATE SEQUENCE tm_comments_seq START WITH 1 INCREMENT BY 1;

-- =====================================================
-- 6. INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX idx_tasks_status ON tm_tasks(status);
CREATE INDEX idx_tasks_assigned_tl ON tm_tasks(assigned_to_tl);
CREATE INDEX idx_tasks_assigned_tm ON tm_tasks(assigned_to_tm);
CREATE INDEX idx_tasks_created_by ON tm_tasks(created_by);
CREATE INDEX idx_approvals_task ON tm_approvals(task_id);
CREATE INDEX idx_approvals_user ON tm_approvals(approver_id);
CREATE INDEX idx_notifications_user ON tm_notifications(user_id);
CREATE INDEX idx_notifications_unread ON tm_notifications(user_id, is_read);
CREATE INDEX idx_comments_task ON tm_comments(task_id);

-- =====================================================
-- 7. SAMPLE DATA INSERTION
-- =====================================================

-- Insert Senior User
INSERT INTO tm_users (user_id, username, full_name, email, role_code, team_id, manager_id)
VALUES (tm_users_seq.NEXTVAL, 'SENIOR1', 'John Senior', 'senior@company.com', 'SENIOR', NULL, NULL);

-- Insert Team Leaders (6 teams)
INSERT INTO tm_users (user_id, username, full_name, email, role_code, team_id, manager_id)
VALUES (tm_users_seq.NEXTVAL, 'TL1', 'Alice Team Leader 1', 'tl1@company.com', 'TL', 1, 1);

INSERT INTO tm_users (user_id, username, full_name, email, role_code, team_id, manager_id)
VALUES (tm_users_seq.NEXTVAL, 'TL2', 'Bob Team Leader 2', 'tl2@company.com', 'TL', 2, 1);

INSERT INTO tm_users (user_id, username, full_name, email, role_code, team_id, manager_id)
VALUES (tm_users_seq.NEXTVAL, 'TL3', 'Carol Team Leader 3', 'tl3@company.com', 'TL', 3, 1);

INSERT INTO tm_users (user_id, username, full_name, email, role_code, team_id, manager_id)
VALUES (tm_users_seq.NEXTVAL, 'TL4', 'David Team Leader 4', 'tl4@company.com', 'TL', 4, 1);

INSERT INTO tm_users (user_id, username, full_name, email, role_code, team_id, manager_id)
VALUES (tm_users_seq.NEXTVAL, 'TL5', 'Eva Team Leader 5', 'tl5@company.com', 'TL', 5, 1);

INSERT INTO tm_users (user_id, username, full_name, email, role_code, team_id, manager_id)
VALUES (tm_users_seq.NEXTVAL, 'TL6', 'Frank Team Leader 6', 'tl6@company.com', 'TL', 6, 1);

-- Insert Project Managers
INSERT INTO tm_users (user_id, username, full_name, email, role_code, team_id, manager_id)
VALUES (tm_users_seq.NEXTVAL, 'PM1', 'Grace Project Manager 1', 'pm1@company.com', 'PM', NULL, 1);

INSERT INTO tm_users (user_id, username, full_name, email, role_code, team_id, manager_id)
VALUES (tm_users_seq.NEXTVAL, 'PM2', 'Henry Project Manager 2', 'pm2@company.com', 'PM', NULL, 1);

-- Insert Team Members (11 per team = 66 total)
DECLARE
    v_team_id NUMBER;
    v_tl_id NUMBER;
    v_counter NUMBER;
BEGIN
    FOR team_num IN 1..6 LOOP
        -- Get TL ID for this team
        SELECT user_id INTO v_tl_id FROM tm_users WHERE role_code = 'TL' AND team_id = team_num;
        
        FOR member_num IN 1..11 LOOP
            v_counter := (team_num - 1) * 11 + member_num;
            INSERT INTO tm_users (user_id, username, full_name, email, role_code, team_id, manager_id)
            VALUES (tm_users_seq.NEXTVAL, 
                   'TM' || LPAD(v_counter, 2, '0'), 
                   'Team Member ' || v_counter, 
                   'tm' || v_counter || '@company.com', 
                   'TM', 
                   team_num, 
                   v_tl_id);
        END LOOP;
    END LOOP;
END;
/

-- =====================================================
-- 8. TRIGGERS
-- =====================================================

-- Trigger to update task updated_date
CREATE OR REPLACE TRIGGER trg_tasks_updated_date
    BEFORE UPDATE ON tm_tasks
    FOR EACH ROW
BEGIN
    :NEW.updated_date := SYSDATE;
END;
/

-- Trigger to create notifications when task status changes
CREATE OR REPLACE TRIGGER trg_task_status_notification
    AFTER UPDATE OF status ON tm_tasks
    FOR EACH ROW
DECLARE
    v_message VARCHAR2(1000);
    v_notification_type VARCHAR2(50);
    v_notify_user_id NUMBER;
BEGIN
    -- Only proceed if status actually changed
    IF :OLD.status != :NEW.status THEN
        
        CASE :NEW.status
            WHEN 'IN_PROGRESS' THEN
                v_message := 'Task "' || :NEW.title || '" has been assigned to you.';
                v_notification_type := 'TASK_ASSIGNED';
                v_notify_user_id := :NEW.assigned_to_tm;
                
            WHEN 'READY_FOR_REVIEW' THEN
                v_message := 'Task "' || :NEW.title || '" is ready for your review.';
                v_notification_type := 'READY_FOR_REVIEW';
                v_notify_user_id := :NEW.assigned_to_tl;
                
            WHEN 'PENDING_TL_APPROVAL' THEN
                v_message := 'Task "' || :NEW.title || '" requires your approval.';
                v_notification_type := 'APPROVAL_REQUIRED';
                v_notify_user_id := :NEW.assigned_to_tl;
                
            WHEN 'PENDING_SENIOR_APPROVAL' THEN
                v_message := 'Task "' || :NEW.title || '" requires senior approval.';
                v_notification_type := 'SENIOR_APPROVAL_REQUIRED';
                SELECT user_id INTO v_notify_user_id FROM tm_users WHERE role_code = 'SENIOR' AND ROWNUM = 1;
                
            WHEN 'APPROVED' THEN
                v_message := 'Task "' || :NEW.title || '" has been approved.';
                v_notification_type := 'TASK_APPROVED';
                v_notify_user_id := :NEW.assigned_to_tm;
                
            WHEN 'REJECTED' THEN
                v_message := 'Task "' || :NEW.title || '" has been rejected and requires rework.';
                v_notification_type := 'TASK_REJECTED';
                v_notify_user_id := :NEW.assigned_to_tm;
                
            ELSE
                v_notify_user_id := NULL;
        END CASE;
        
        -- Insert notification if we have a user to notify
        IF v_notify_user_id IS NOT NULL THEN
            INSERT INTO tm_notifications (notification_id, user_id, task_id, message, notification_type)
            VALUES (tm_notifications_seq.NEXTVAL, v_notify_user_id, :NEW.task_id, v_message, v_notification_type);
        END IF;
    END IF;
END;
/

-- =====================================================
-- 9. VIEWS FOR APEX APPLICATION
-- =====================================================

-- View for Task Dashboard
CREATE OR REPLACE VIEW v_task_dashboard AS
SELECT 
    t.task_id,
    t.title,
    t.description,
    t.status,
    t.priority,
    t.due_date,
    t.created_date,
    t.updated_date,
    creator.full_name as created_by_name,
    tl.full_name as team_leader_name,
    tm.full_name as team_member_name,
    t.created_by,
    t.assigned_to_tl,
    t.assigned_to_tm,
    CASE 
        WHEN t.due_date < SYSDATE AND t.status NOT IN ('APPROVED', 'CANCELLED') THEN 'OVERDUE'
        WHEN t.due_date <= SYSDATE + 2 AND t.status NOT IN ('APPROVED', 'CANCELLED') THEN 'DUE_SOON'
        ELSE 'ON_TIME'
    END as due_status
FROM tm_tasks t
LEFT JOIN tm_users creator ON t.created_by = creator.user_id
LEFT JOIN tm_users tl ON t.assigned_to_tl = tl.user_id
LEFT JOIN tm_users tm ON t.assigned_to_tm = tm.user_id;

-- View for Approval Queue
CREATE OR REPLACE VIEW v_approval_queue AS
SELECT 
    a.approval_id,
    a.task_id,
    a.approval_level,
    a.status as approval_status,
    a.comments,
    a.action_date,
    a.created_date,
    t.title as task_title,
    t.status as task_status,
    t.priority,
    approver.full_name as approver_name,
    creator.full_name as task_creator_name,
    tm.full_name as team_member_name
FROM tm_approvals a
JOIN tm_tasks t ON a.task_id = t.task_id
JOIN tm_users approver ON a.approver_id = approver.user_id
LEFT JOIN tm_users creator ON t.created_by = creator.user_id
LEFT JOIN tm_users tm ON t.assigned_to_tm = tm.user_id;

-- View for User Notifications
CREATE OR REPLACE VIEW v_user_notifications AS
SELECT 
    n.notification_id,
    n.user_id,
    n.task_id,
    n.message,
    n.notification_type,
    n.is_read,
    n.created_date,
    n.read_date,
    t.title as task_title,
    t.status as task_status
FROM tm_notifications n
JOIN tm_tasks t ON n.task_id = t.task_id
ORDER BY n.created_date DESC;

-- =====================================================
-- 10. PACKAGES FOR BUSINESS LOGIC
-- =====================================================

-- Package for Task Management
CREATE OR REPLACE PACKAGE pkg_task_management AS
    
    -- Create new task
    FUNCTION create_task(
        p_title IN VARCHAR2,
        p_description IN CLOB,
        p_created_by IN NUMBER,
        p_assigned_to_tl IN NUMBER DEFAULT NULL,
        p_priority IN VARCHAR2 DEFAULT 'MEDIUM',
        p_due_date IN DATE DEFAULT NULL
    ) RETURN NUMBER;
    
    -- Assign task to team member
    PROCEDURE assign_to_team_member(
        p_task_id IN NUMBER,
        p_assigned_to_tm IN NUMBER,
        p_assigned_by IN NUMBER
    );
    
    -- Submit task for review
    PROCEDURE submit_for_review(
        p_task_id IN NUMBER,
        p_submitted_by IN NUMBER
    );
    
    -- Approve/Reject task
    PROCEDURE process_approval(
        p_task_id IN NUMBER,
        p_approver_id IN NUMBER,
        p_approval_level IN NUMBER,
        p_action IN VARCHAR2, -- 'APPROVE' or 'REJECT'
        p_comments IN CLOB DEFAULT NULL
    );
    
    -- Cancel task
    PROCEDURE cancel_task(
        p_task_id IN NUMBER,
        p_cancelled_by IN NUMBER,
        p_reason IN VARCHAR2
    );
    
    -- Get user role
    FUNCTION get_user_role(p_user_id IN NUMBER) RETURN VARCHAR2;
    
    -- Check if user can access task
    FUNCTION can_access_task(p_task_id IN NUMBER, p_user_id IN NUMBER) RETURN BOOLEAN;
    
END pkg_task_management;
/

CREATE OR REPLACE PACKAGE BODY pkg_task_management AS

    FUNCTION create_task(
        p_title IN VARCHAR2,
        p_description IN CLOB,
        p_created_by IN NUMBER,
        p_assigned_to_tl IN NUMBER DEFAULT NULL,
        p_priority IN VARCHAR2 DEFAULT 'MEDIUM',
        p_due_date IN DATE DEFAULT NULL
    ) RETURN NUMBER IS
        v_task_id NUMBER;
    BEGIN
        INSERT INTO tm_tasks (
            task_id, title, description, created_by, assigned_to_tl, 
            priority, due_date, status
        ) VALUES (
            tm_tasks_seq.NEXTVAL, p_title, p_description, p_created_by, 
            p_assigned_to_tl, p_priority, p_due_date, 
            CASE WHEN p_assigned_to_tl IS NOT NULL THEN 'NEW' ELSE 'NEW' END
        ) RETURNING task_id INTO v_task_id;
        
        COMMIT;
        RETURN v_task_id;
    END create_task;

    PROCEDURE assign_to_team_member(
        p_task_id IN NUMBER,
        p_assigned_to_tm IN NUMBER,
        p_assigned_by IN NUMBER
    ) IS
    BEGIN
        UPDATE tm_tasks 
        SET assigned_to_tm = p_assigned_to_tm,
            status = 'IN_PROGRESS'
        WHERE task_id = p_task_id;
        
        -- Add comment
        INSERT INTO tm_comments (comment_id, task_id, user_id, comment_text, comment_type)
        VALUES (tm_comments_seq.NEXTVAL, p_task_id, p_assigned_by, 
                'Task assigned to team member', 'STATUS_CHANGE');
        
        COMMIT;
    END assign_to_team_member;

    PROCEDURE submit_for_review(
        p_task_id IN NUMBER,
        p_submitted_by IN NUMBER
    ) IS
    BEGIN
        UPDATE tm_tasks 
        SET status = 'PENDING_TL_APPROVAL',
            completed_date = SYSDATE
        WHERE task_id = p_task_id;
        
        -- Create approval record for TL
        INSERT INTO tm_approvals (approval_id, task_id, approver_id, approval_level, status)
        SELECT tm_approvals_seq.NEXTVAL, p_task_id, assigned_to_tl, 1, 'PENDING'
        FROM tm_tasks WHERE task_id = p_task_id;
        
        -- Add comment
        INSERT INTO tm_comments (comment_id, task_id, user_id, comment_text, comment_type)
        VALUES (tm_comments_seq.NEXTVAL, p_task_id, p_submitted_by, 
                'Task submitted for review', 'STATUS_CHANGE');
        
        COMMIT;
    END submit_for_review;

    PROCEDURE process_approval(
        p_task_id IN NUMBER,
        p_approver_id IN NUMBER,
        p_approval_level IN NUMBER,
        p_action IN VARCHAR2,
        p_comments IN CLOB DEFAULT NULL
    ) IS
        v_new_status VARCHAR2(30);
    BEGIN
        -- Update approval record
        UPDATE tm_approvals 
        SET status = p_action,
            comments = p_comments,
            action_date = SYSDATE
        WHERE task_id = p_task_id 
        AND approver_id = p_approver_id 
        AND approval_level = p_approval_level;
        
        -- Determine new task status
        IF p_action = 'APPROVED' THEN
            IF p_approval_level = 1 THEN
                -- TL approved, now needs senior approval
                v_new_status := 'PENDING_SENIOR_APPROVAL';
                
                -- Create approval record for Senior
                INSERT INTO tm_approvals (approval_id, task_id, approver_id, approval_level, status)
                SELECT tm_approvals_seq.NEXTVAL, p_task_id, user_id, 2, 'PENDING'
                FROM tm_users WHERE role_code = 'SENIOR' AND ROWNUM = 1;
                
            ELSIF p_approval_level = 2 THEN
                -- Senior approved, task is complete
                v_new_status := 'APPROVED';
            END IF;
        ELSE
            -- Rejected
            v_new_status := 'REJECTED';
        END IF;
        
        -- Update task status
        UPDATE tm_tasks SET status = v_new_status WHERE task_id = p_task_id;
        
        -- Add comment
        INSERT INTO tm_comments (comment_id, task_id, user_id, comment_text, comment_type)
        VALUES (tm_comments_seq.NEXTVAL, p_task_id, p_approver_id, 
                NVL(p_comments, p_action || ' by ' || (SELECT full_name FROM tm_users WHERE user_id = p_approver_id)), 
                CASE WHEN p_action = 'APPROVED' THEN 'APPROVAL' ELSE 'REJECTION' END);
        
        COMMIT;
    END process_approval;

    PROCEDURE cancel_task(
        p_task_id IN NUMBER,
        p_cancelled_by IN NUMBER,
        p_reason IN VARCHAR2
    ) IS
    BEGIN
        UPDATE tm_tasks SET status = 'CANCELLED' WHERE task_id = p_task_id;
        
        -- Add comment
        INSERT INTO tm_comments (comment_id, task_id, user_id, comment_text, comment_type)
        VALUES (tm_comments_seq.NEXTVAL, p_task_id, p_cancelled_by, 
                'Task cancelled: ' || p_reason, 'STATUS_CHANGE');
        
        COMMIT;
    END cancel_task;

    FUNCTION get_user_role(p_user_id IN NUMBER) RETURN VARCHAR2 IS
        v_role VARCHAR2(10);
    BEGIN
        SELECT role_code INTO v_role FROM tm_users WHERE user_id = p_user_id;
        RETURN v_role;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_user_role;

    FUNCTION can_access_task(p_task_id IN NUMBER, p_user_id IN NUMBER) RETURN BOOLEAN IS
        v_count NUMBER;
        v_role VARCHAR2(10);
    BEGIN
        SELECT role_code INTO v_role FROM tm_users WHERE user_id = p_user_id;
        
        -- Senior and PM can access all tasks
        IF v_role IN ('SENIOR', 'PM') THEN
            RETURN TRUE;
        END IF;
        
        -- Check if user is involved in the task
        SELECT COUNT(*)
        INTO v_count
        FROM tm_tasks
        WHERE task_id = p_task_id
        AND (created_by = p_user_id 
             OR assigned_to_tl = p_user_id 
             OR assigned_to_tm = p_user_id);
        
        RETURN v_count > 0;
    END can_access_task;

END pkg_task_management;
/

-- =====================================================
-- COMMIT ALL CHANGES
-- =====================================================
COMMIT;

-- Display summary
SELECT 'Database schema created successfully!' as status FROM dual;
SELECT 'Total users created: ' || COUNT(*) as user_count FROM tm_users;
SELECT 'Senior users: ' || COUNT(*) as senior_count FROM tm_users WHERE role_code = 'SENIOR';
SELECT 'Team Leaders: ' || COUNT(*) as tl_count FROM tm_users WHERE role_code = 'TL';
SELECT 'Team Members: ' || COUNT(*) as tm_count FROM tm_users WHERE role_code = 'TM';
SELECT 'Project Managers: ' || COUNT(*) as pm_count FROM tm_users WHERE role_code = 'PM';