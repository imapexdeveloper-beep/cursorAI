-- =============================================
-- Task Management System - Database Tables
-- =============================================

-- Drop existing tables (in reverse order of dependencies)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE task_comments CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE task_approvals CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE task_notifications CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE tasks CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE app_users CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- =============================================
-- Users Table
-- =============================================
CREATE TABLE app_users (
    user_id         NUMBER PRIMARY KEY,
    username        VARCHAR2(100) UNIQUE NOT NULL,
    full_name       VARCHAR2(200) NOT NULL,
    email           VARCHAR2(200) NOT NULL,
    role            VARCHAR2(20) NOT NULL CHECK (role IN ('PM', 'TL', 'TM', 'SENIOR')),
    team_id         NUMBER,
    is_active       VARCHAR2(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N')),
    created_date    DATE DEFAULT SYSDATE,
    created_by      VARCHAR2(100)
);

-- =============================================
-- Tasks Table
-- =============================================
CREATE TABLE tasks (
    task_id             NUMBER PRIMARY KEY,
    title               VARCHAR2(500) NOT NULL,
    description         CLOB,
    status              VARCHAR2(30) DEFAULT 'NEW' NOT NULL 
                        CHECK (status IN ('NEW', 'IN_PROGRESS', 'READY_FOR_REVIEW', 
                                        'PENDING_TL_APPROVAL', 'PENDING_SENIOR_APPROVAL', 
                                        'APPROVED', 'REJECTED', 'CANCELLED')),
    priority            VARCHAR2(20) DEFAULT 'MEDIUM' 
                        CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    created_by          VARCHAR2(100) NOT NULL,
    created_by_user_id  NUMBER,
    created_date        DATE DEFAULT SYSDATE NOT NULL,
    assigned_to_tl      NUMBER,
    assigned_to_tl_date DATE,
    assigned_to_tm      NUMBER,
    assigned_to_tm_date DATE,
    submitted_date      DATE,
    tl_approval_date    DATE,
    tl_approved_by      NUMBER,
    senior_approval_date DATE,
    senior_approved_by  NUMBER,
    due_date            DATE,
    completed_date      DATE,
    last_updated_date   DATE DEFAULT SYSDATE,
    last_updated_by     VARCHAR2(100),
    CONSTRAINT fk_task_created_by FOREIGN KEY (created_by_user_id) 
        REFERENCES app_users(user_id),
    CONSTRAINT fk_task_assigned_tl FOREIGN KEY (assigned_to_tl) 
        REFERENCES app_users(user_id),
    CONSTRAINT fk_task_assigned_tm FOREIGN KEY (assigned_to_tm) 
        REFERENCES app_users(user_id),
    CONSTRAINT fk_task_tl_approved_by FOREIGN KEY (tl_approved_by) 
        REFERENCES app_users(user_id),
    CONSTRAINT fk_task_senior_approved_by FOREIGN KEY (senior_approved_by) 
        REFERENCES app_users(user_id)
);

-- =============================================
-- Task Approvals Table (Audit Trail)
-- =============================================
CREATE TABLE task_approvals (
    approval_id         NUMBER PRIMARY KEY,
    task_id             NUMBER NOT NULL,
    approval_level      VARCHAR2(20) NOT NULL CHECK (approval_level IN ('TL', 'SENIOR')),
    approver_id         NUMBER NOT NULL,
    approval_status     VARCHAR2(20) NOT NULL CHECK (approval_status IN ('APPROVED', 'REJECTED')),
    comments            CLOB,
    approval_date       DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_approval_task FOREIGN KEY (task_id) REFERENCES tasks(task_id) ON DELETE CASCADE,
    CONSTRAINT fk_approval_user FOREIGN KEY (approver_id) REFERENCES app_users(user_id)
);

-- =============================================
-- Task Comments Table
-- =============================================
CREATE TABLE task_comments (
    comment_id          NUMBER PRIMARY KEY,
    task_id             NUMBER NOT NULL,
    comment_text        CLOB NOT NULL,
    comment_type        VARCHAR2(20) DEFAULT 'GENERAL' 
                        CHECK (comment_type IN ('GENERAL', 'REJECTION', 'APPROVAL', 'STATUS_CHANGE')),
    commented_by        VARCHAR2(100) NOT NULL,
    commented_by_user_id NUMBER,
    comment_date        DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_comment_task FOREIGN KEY (task_id) REFERENCES tasks(task_id) ON DELETE CASCADE,
    CONSTRAINT fk_comment_user FOREIGN KEY (commented_by_user_id) REFERENCES app_users(user_id)
);

-- =============================================
-- Task Notifications Table
-- =============================================
CREATE TABLE task_notifications (
    notification_id     NUMBER PRIMARY KEY,
    task_id             NUMBER NOT NULL,
    user_id             NUMBER NOT NULL,
    notification_type   VARCHAR2(50) NOT NULL,
    notification_text   VARCHAR2(1000) NOT NULL,
    is_read             VARCHAR2(1) DEFAULT 'N' CHECK (is_read IN ('Y', 'N')),
    created_date        DATE DEFAULT SYSDATE NOT NULL,
    read_date           DATE,
    CONSTRAINT fk_notif_task FOREIGN KEY (task_id) REFERENCES tasks(task_id) ON DELETE CASCADE,
    CONSTRAINT fk_notif_user FOREIGN KEY (user_id) REFERENCES app_users(user_id)
);

-- =============================================
-- Indexes for Performance
-- =============================================
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_assigned_tl ON tasks(assigned_to_tl);
CREATE INDEX idx_tasks_assigned_tm ON tasks(assigned_to_tm);
CREATE INDEX idx_tasks_created_by ON tasks(created_by_user_id);
CREATE INDEX idx_approvals_task ON task_approvals(task_id);
CREATE INDEX idx_comments_task ON task_comments(task_id);
CREATE INDEX idx_notif_user ON task_notifications(user_id, is_read);
CREATE INDEX idx_users_role ON app_users(role);

COMMIT;
