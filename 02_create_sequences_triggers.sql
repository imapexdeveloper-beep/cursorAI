-- =============================================
-- Task Management System - Sequences and Triggers
-- =============================================

-- Drop existing sequences
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_app_users';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_tasks';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_task_approvals';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_task_comments';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_task_notifications';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- =============================================
-- Create Sequences
-- =============================================
CREATE SEQUENCE seq_app_users START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_tasks START WITH 1000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_task_approvals START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_task_comments START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_task_notifications START WITH 1 INCREMENT BY 1 NOCACHE;

-- =============================================
-- Triggers for Auto-Increment
-- =============================================

-- Trigger for app_users
CREATE OR REPLACE TRIGGER trg_app_users_bi
BEFORE INSERT ON app_users
FOR EACH ROW
BEGIN
    IF :NEW.user_id IS NULL THEN
        :NEW.user_id := seq_app_users.NEXTVAL;
    END IF;
    IF :NEW.created_date IS NULL THEN
        :NEW.created_date := SYSDATE;
    END IF;
END;
/

-- Trigger for tasks
CREATE OR REPLACE TRIGGER trg_tasks_bi
BEFORE INSERT ON tasks
FOR EACH ROW
BEGIN
    IF :NEW.task_id IS NULL THEN
        :NEW.task_id := seq_tasks.NEXTVAL;
    END IF;
    IF :NEW.created_date IS NULL THEN
        :NEW.created_date := SYSDATE;
    END IF;
    IF :NEW.last_updated_date IS NULL THEN
        :NEW.last_updated_date := SYSDATE;
    END IF;
END;
/

-- Trigger for tasks update
CREATE OR REPLACE TRIGGER trg_tasks_bu
BEFORE UPDATE ON tasks
FOR EACH ROW
BEGIN
    :NEW.last_updated_date := SYSDATE;
END;
/

-- Trigger for task_approvals
CREATE OR REPLACE TRIGGER trg_task_approvals_bi
BEFORE INSERT ON task_approvals
FOR EACH ROW
BEGIN
    IF :NEW.approval_id IS NULL THEN
        :NEW.approval_id := seq_task_approvals.NEXTVAL;
    END IF;
    IF :NEW.approval_date IS NULL THEN
        :NEW.approval_date := SYSDATE;
    END IF;
END;
/

-- Trigger for task_comments
CREATE OR REPLACE TRIGGER trg_task_comments_bi
BEFORE INSERT ON task_comments
FOR EACH ROW
BEGIN
    IF :NEW.comment_id IS NULL THEN
        :NEW.comment_id := seq_task_comments.NEXTVAL;
    END IF;
    IF :NEW.comment_date IS NULL THEN
        :NEW.comment_date := SYSDATE;
    END IF;
END;
/

-- Trigger for task_notifications
CREATE OR REPLACE TRIGGER trg_task_notifications_bi
BEFORE INSERT ON task_notifications
FOR EACH ROW
BEGIN
    IF :NEW.notification_id IS NULL THEN
        :NEW.notification_id := seq_task_notifications.NEXTVAL;
    END IF;
    IF :NEW.created_date IS NULL THEN
        :NEW.created_date := SYSDATE;
    END IF;
END;
/

COMMIT;
