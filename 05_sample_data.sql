-- =============================================
-- Task Management System - Sample Data
-- =============================================

-- Clear existing data
DELETE FROM task_notifications;
DELETE FROM task_comments;
DELETE FROM task_approvals;
DELETE FROM tasks;
DELETE FROM app_users;

COMMIT;

-- =============================================
-- Insert Users
-- =============================================

-- Insert Project Manager
INSERT INTO app_users (user_id, username, full_name, email, role, team_id, is_active, created_by)
VALUES (1, 'PM_JOHN', 'John Smith', 'john.smith@company.com', 'PM', NULL, 'Y', 'ADMIN');

-- Insert Senior
INSERT INTO app_users (user_id, username, full_name, email, role, team_id, is_active, created_by)
VALUES (2, 'SENIOR_MARY', 'Mary Johnson', 'mary.johnson@company.com', 'SENIOR', NULL, 'Y', 'ADMIN');

-- Insert Team Leaders (6 Teams)
INSERT INTO app_users (user_id, username, full_name, email, role, team_id, is_active, created_by)
VALUES (10, 'TL_JAMES', 'James Williams', 'james.williams@company.com', 'TL', 1, 'Y', 'ADMIN');

INSERT INTO app_users (user_id, username, full_name, email, role, team_id, is_active, created_by)
VALUES (11, 'TL_PATRICIA', 'Patricia Brown', 'patricia.brown@company.com', 'TL', 2, 'Y', 'ADMIN');

INSERT INTO app_users (user_id, username, full_name, email, role, team_id, is_active, created_by)
VALUES (12, 'TL_ROBERT', 'Robert Davis', 'robert.davis@company.com', 'TL', 3, 'Y', 'ADMIN');

INSERT INTO app_users (user_id, username, full_name, email, role, team_id, is_active, created_by)
VALUES (13, 'TL_JENNIFER', 'Jennifer Miller', 'jennifer.miller@company.com', 'TL', 4, 'Y', 'ADMIN');

INSERT INTO app_users (user_id, username, full_name, email, role, team_id, is_active, created_by)
VALUES (14, 'TL_MICHAEL', 'Michael Wilson', 'michael.wilson@company.com', 'TL', 5, 'Y', 'ADMIN');

INSERT INTO app_users (user_id, username, full_name, email, role, team_id, is_active, created_by)
VALUES (15, 'TL_LINDA', 'Linda Moore', 'linda.moore@company.com', 'TL', 6, 'Y', 'ADMIN');

-- Insert Team Members (66 total - 11 per team)
-- Team 1 Members
INSERT INTO app_users (user_id, username, full_name, email, role, team_id, is_active, created_by)
SELECT 100 + LEVEL, 'TM_TEAM1_' || LPAD(LEVEL, 2, '0'), 
       'Team Member 1.' || LPAD(LEVEL, 2, '0'),
       'tm.team1.' || LPAD(LEVEL, 2, '0') || '@company.com',
       'TM', 1, 'Y', 'ADMIN'
FROM DUAL CONNECT BY LEVEL <= 11;

-- Team 2 Members
INSERT INTO app_users (user_id, username, full_name, email, role, team_id, is_active, created_by)
SELECT 120 + LEVEL, 'TM_TEAM2_' || LPAD(LEVEL, 2, '0'), 
       'Team Member 2.' || LPAD(LEVEL, 2, '0'),
       'tm.team2.' || LPAD(LEVEL, 2, '0') || '@company.com',
       'TM', 2, 'Y', 'ADMIN'
FROM DUAL CONNECT BY LEVEL <= 11;

-- Team 3 Members
INSERT INTO app_users (user_id, username, full_name, email, role, team_id, is_active, created_by)
SELECT 140 + LEVEL, 'TM_TEAM3_' || LPAD(LEVEL, 2, '0'), 
       'Team Member 3.' || LPAD(LEVEL, 2, '0'),
       'tm.team3.' || LPAD(LEVEL, 2, '0') || '@company.com',
       'TM', 3, 'Y', 'ADMIN'
FROM DUAL CONNECT BY LEVEL <= 11;

-- Team 4 Members
INSERT INTO app_users (user_id, username, full_name, email, role, team_id, is_active, created_by)
SELECT 160 + LEVEL, 'TM_TEAM4_' || LPAD(LEVEL, 2, '0'), 
       'Team Member 4.' || LPAD(LEVEL, 2, '0'),
       'tm.team4.' || LPAD(LEVEL, 2, '0') || '@company.com',
       'TM', 4, 'Y', 'ADMIN'
FROM DUAL CONNECT BY LEVEL <= 11;

-- Team 5 Members
INSERT INTO app_users (user_id, username, full_name, email, role, team_id, is_active, created_by)
SELECT 180 + LEVEL, 'TM_TEAM5_' || LPAD(LEVEL, 2, '0'), 
       'Team Member 5.' || LPAD(LEVEL, 2, '0'),
       'tm.team5.' || LPAD(LEVEL, 2, '0') || '@company.com',
       'TM', 5, 'Y', 'ADMIN'
FROM DUAL CONNECT BY LEVEL <= 11;

-- Team 6 Members
INSERT INTO app_users (user_id, username, full_name, email, role, team_id, is_active, created_by)
SELECT 200 + LEVEL, 'TM_TEAM6_' || LPAD(LEVEL, 2, '0'), 
       'Team Member 6.' || LPAD(LEVEL, 2, '0'),
       'tm.team6.' || LPAD(LEVEL, 2, '0') || '@company.com',
       'TM', 6, 'Y', 'ADMIN'
FROM DUAL CONNECT BY LEVEL <= 11;

-- =============================================
-- Create Sample Tasks
-- =============================================

DECLARE
    v_task_id NUMBER;
BEGIN
    -- Task 1: NEW status (assigned to TL, not yet assigned to TM)
    pkg_task_management.create_task(
        p_title => 'Develop Customer Portal Login Module',
        p_description => 'Create a secure login module for the customer portal with OAuth integration',
        p_assigned_to_tl => 10,
        p_priority => 'HIGH',
        p_due_date => SYSDATE + 7,
        p_created_by => 'PM_JOHN',
        p_task_id => v_task_id
    );
    
    -- Task 2: IN_PROGRESS (assigned to TM, work in progress)
    pkg_task_management.create_task(
        p_title => 'Create Database Migration Scripts',
        p_description => 'Develop scripts to migrate data from legacy system to new database',
        p_assigned_to_tl => 11,
        p_priority => 'MEDIUM',
        p_due_date => SYSDATE + 10,
        p_created_by => 'PM_JOHN',
        p_task_id => v_task_id
    );
    pkg_task_management.assign_task_to_tm(
        p_task_id => v_task_id,
        p_assigned_to_tm => 121,
        p_assigned_by => 'TL_PATRICIA'
    );
    
    -- Task 3: PENDING_TL_APPROVAL (submitted by TM, waiting for TL approval)
    pkg_task_management.create_task(
        p_title => 'Design API Documentation',
        p_description => 'Create comprehensive API documentation using OpenAPI/Swagger',
        p_assigned_to_tl => 12,
        p_priority => 'MEDIUM',
        p_due_date => SYSDATE + 5,
        p_created_by => 'PM_JOHN',
        p_task_id => v_task_id
    );
    pkg_task_management.assign_task_to_tm(
        p_task_id => v_task_id,
        p_assigned_to_tm => 141,
        p_assigned_by => 'TL_ROBERT'
    );
    pkg_task_management.submit_task_for_review(
        p_task_id => v_task_id,
        p_submitted_by => 'TM_TEAM3_01'
    );
    
    -- Task 4: PENDING_SENIOR_APPROVAL (TL approved, waiting for Senior)
    pkg_task_management.create_task(
        p_title => 'Implement Payment Gateway Integration',
        p_description => 'Integrate Stripe payment gateway with proper error handling and logging',
        p_assigned_to_tl => 13,
        p_priority => 'HIGH',
        p_due_date => SYSDATE + 3,
        p_created_by => 'PM_JOHN',
        p_task_id => v_task_id
    );
    pkg_task_management.assign_task_to_tm(
        p_task_id => v_task_id,
        p_assigned_to_tm => 161,
        p_assigned_by => 'TL_JENNIFER'
    );
    pkg_task_management.submit_task_for_review(
        p_task_id => v_task_id,
        p_submitted_by => 'TM_TEAM4_01'
    );
    pkg_task_management.approve_task_tl(
        p_task_id => v_task_id,
        p_approver_id => 13,
        p_comments => 'Excellent work! Code quality is great.'
    );
    
    -- Task 5: APPROVED (fully approved by both TL and Senior)
    pkg_task_management.create_task(
        p_title => 'Setup CI/CD Pipeline',
        p_description => 'Configure Jenkins pipeline for automated testing and deployment',
        p_assigned_to_tl => 14,
        p_priority => 'HIGH',
        p_due_date => SYSDATE + 15,
        p_created_by => 'PM_JOHN',
        p_task_id => v_task_id
    );
    pkg_task_management.assign_task_to_tm(
        p_task_id => v_task_id,
        p_assigned_to_tm => 181,
        p_assigned_by => 'TL_MICHAEL'
    );
    pkg_task_management.submit_task_for_review(
        p_task_id => v_task_id,
        p_submitted_by => 'TM_TEAM5_01'
    );
    pkg_task_management.approve_task_tl(
        p_task_id => v_task_id,
        p_approver_id => 14,
        p_comments => 'Pipeline works perfectly!'
    );
    pkg_task_management.approve_task_senior(
        p_task_id => v_task_id,
        p_approver_id => 2,
        p_comments => 'Great job! Deployment is smooth.'
    );
    
    -- Task 6: REJECTED (rejected by TL, needs rework)
    pkg_task_management.create_task(
        p_title => 'Create User Management Module',
        p_description => 'Develop CRUD operations for user management with role-based access',
        p_assigned_to_tl => 15,
        p_priority => 'MEDIUM',
        p_due_date => SYSDATE + 8,
        p_created_by => 'PM_JOHN',
        p_task_id => v_task_id
    );
    pkg_task_management.assign_task_to_tm(
        p_task_id => v_task_id,
        p_assigned_to_tm => 201,
        p_assigned_by => 'TL_LINDA'
    );
    pkg_task_management.submit_task_for_review(
        p_task_id => v_task_id,
        p_submitted_by => 'TM_TEAM6_01'
    );
    pkg_task_management.reject_task_tl(
        p_task_id => v_task_id,
        p_approver_id => 15,
        p_comments => 'Please add input validation and improve error handling before resubmission.'
    );
    
    COMMIT;
END;
/

-- Verify data
SELECT 'Total Users: ' || COUNT(*) as info FROM app_users;
SELECT 'PM: ' || COUNT(*) as info FROM app_users WHERE role = 'PM';
SELECT 'Senior: ' || COUNT(*) as info FROM app_users WHERE role = 'SENIOR';
SELECT 'Team Leaders: ' || COUNT(*) as info FROM app_users WHERE role = 'TL';
SELECT 'Team Members: ' || COUNT(*) as info FROM app_users WHERE role = 'TM';
SELECT 'Total Tasks: ' || COUNT(*) as info FROM tasks;
SELECT status, COUNT(*) as count FROM tasks GROUP BY status ORDER BY status;

COMMIT;
