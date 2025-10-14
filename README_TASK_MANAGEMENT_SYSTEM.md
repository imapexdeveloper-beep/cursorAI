# Oracle APEX Task Management System

## Overview

This is a comprehensive Oracle APEX task management application with a sophisticated approval workflow system. The application supports multiple user roles and implements a two-step approval process as specified in your requirements.

## Features

### 🚀 Core Features
- **Multi-Role Support**: Project Manager (PM), Team Leader (TL), Team Member (TM), Senior
- **Two-Step Approval Workflow**: TL approval followed by Senior approval
- **Real-time Notifications**: Email and in-app notifications
- **Task Assignment Chain**: PM → TL → TM
- **Comprehensive Reporting**: Role-specific dashboards and analytics
- **Workflow State Machine**: Robust state transitions with validation

### 📊 User Roles & Capabilities

#### Project Manager (PM)
- Create new tasks
- Assign tasks to Team Leaders
- Monitor all tasks across teams
- Cancel tasks when needed
- View comprehensive reports and analytics

#### Team Leader (TL)
- Receive tasks from Project Managers
- Assign tasks to Team Members
- Review and approve/reject completed work
- Monitor team performance
- First-level approval in the workflow

#### Team Member (TM)
- Receive assigned tasks
- Work on tasks and submit for review
- Rework rejected tasks
- View personal task history and performance

#### Senior
- Final approval authority
- System-wide oversight
- Approve/reject tasks after TL approval
- Access to all system analytics

### 🔄 Workflow Process

```
NEW → IN_PROGRESS → PENDING_TL_APPROVAL → PENDING_SENIOR_APPROVAL → APPROVED
                           ↓                        ↓
                       REJECTED ←──────────────── REJECTED
                           ↓
                    (Rework & Resubmit)
```

## Database Schema

### Core Tables
- **tm_users**: User management with roles and team assignments
- **tm_tasks**: Task information with status tracking
- **tm_approvals**: Two-level approval system
- **tm_notifications**: Real-time notification system
- **tm_comments**: Task comments and communication history

### Key Views
- **v_task_dashboard**: Comprehensive task overview
- **v_approval_queue**: Pending approvals by level
- **v_user_notifications**: User-specific notifications
- **v_workflow_metrics**: Performance analytics

## Installation Instructions

### 1. Database Setup

```sql
-- Run in order:
@task_management_schema.sql
@task_management_apex_app.sql
@apex_pages_detailed.sql
@apex_workflow_notifications.sql
```

### 2. APEX Application Creation

1. **Create New Application**
   - Application Name: "Task Management System"
   - Application Alias: "TASK_MGMT"
   - Authentication: Custom
   - Theme: Universal Theme 42

2. **Set Application Items**
   ```
   G_USER_ID (NUMBER)
   G_USER_ROLE (VARCHAR2)
   G_USER_FULL_NAME (VARCHAR2)
   G_USER_TEAM_ID (NUMBER)
   ```

3. **Create Authentication Scheme**
   - Name: "Custom Task Management Auth"
   - Function: `custom_auth_function`

4. **Create Authorization Schemes**
   - PM_ONLY: `auth_is_pm`
   - TL_ONLY: `auth_is_tl`
   - TM_ONLY: `auth_is_tm`
   - SENIOR_ONLY: `auth_is_senior`
   - ADMIN_ONLY: `auth_is_admin`

### 3. Page Creation

#### Page 1: Login
- Template: Login Page
- Authentication: Not Required
- Process: Custom authentication using `process_login`

#### Page 100: PM Dashboard
- Authorization: PM_ONLY
- Regions: Task Creation, All Tasks Report, Analytics
- Processes: Create Task, Assign to TL

#### Page 200: TL Dashboard
- Authorization: TL_ONLY
- Regions: Team Tasks, Assignment Form, Approval Queue
- Processes: Assign to TM, Process Approval

#### Page 300: TM Dashboard
- Authorization: TM_ONLY
- Regions: My Tasks, Work Form, Performance Summary
- Processes: Submit for Review, Update Progress

#### Page 400: Senior Dashboard
- Authorization: SENIOR_ONLY
- Regions: Pending Approvals, System Analytics
- Processes: Final Approval/Rejection

#### Page 500: Task Details (Modal)
- Authorization: Role-based access check
- Regions: Task Info, Comments, Approval History, Timeline

### 4. Shared Components

#### Lists of Values (LOVs)
- Team Leaders: `lov_team_leaders`
- Team Members: `lov_team_members`
- Priorities: `lov_priorities`
- Task Status: `lov_task_status`

#### Dynamic Actions
- Cascade LOVs for team member selection
- Real-time notification updates
- Form validations
- Status-based button visibility

## Testing

Run the comprehensive test suite:

```sql
@test_complete_workflow.sql
```

This will test:
- Complete successful workflow
- Rejection and rework scenarios
- Task cancellation
- Workflow engine validation
- Notification system
- Performance benchmarks
- Data integrity checks

## Configuration

### Email Notifications

Configure APEX email settings:
```sql
-- Set APEX email configuration
BEGIN
    APEX_INSTANCE_ADMIN.SET_PARAMETER('SMTP_HOST_ADDRESS', 'your-smtp-server.com');
    APEX_INSTANCE_ADMIN.SET_PARAMETER('SMTP_HOST_PORT', '587');
    APEX_INSTANCE_ADMIN.SET_PARAMETER('SMTP_USERNAME', 'your-email@company.com');
    APEX_INSTANCE_ADMIN.SET_PARAMETER('SMTP_PASSWORD', 'your-password');
END;
/
```

### Scheduled Jobs

The system includes automated jobs:
- **Daily Overdue Notifications**: Runs at 9 AM daily
- **Weekly Cleanup**: Removes old notifications on Sundays at 2 AM

### Performance Tuning

Key indexes are automatically created for:
- Task status queries
- User-based task filtering
- Notification lookups
- Approval processing

## User Management

### Default Users Created

The system creates sample users:
- 1 Senior user
- 6 Team Leaders (one per team)
- 66 Team Members (11 per team)
- 2 Project Managers

### Adding New Users

```sql
INSERT INTO tm_users (
    user_id, username, full_name, email, role_code, team_id, manager_id
) VALUES (
    tm_users_seq.NEXTVAL, 'new_user', 'Full Name', 'email@company.com', 
    'TM', 1, (SELECT user_id FROM tm_users WHERE role_code = 'TL' AND team_id = 1)
);
```

## API Reference

### Core Packages

#### pkg_task_management
- `create_task()`: Create new task
- `assign_to_team_member()`: Assign task to TM
- `submit_for_review()`: Submit completed work
- `process_approval()`: Handle approvals/rejections
- `cancel_task()`: Cancel task
- `get_user_role()`: Get user role
- `can_access_task()`: Check task access permissions

#### pkg_workflow_engine
- `get_allowed_transitions()`: Get valid state transitions
- `execute_transition()`: Execute workflow transition
- `is_transition_allowed()`: Validate transition
- `get_next_approver()`: Find next approver

#### pkg_notification_system
- `send_notification()`: Send notification
- `send_email_notification()`: Send email
- `mark_as_read()`: Mark notification read
- `get_unread_count()`: Get unread count
- `send_overdue_notifications()`: Send overdue alerts

### APEX Integration Functions

- `get_workflow_actions_json()`: Get available actions for task
- `get_notification_summary_json()`: Get user notifications
- `get_dashboard_stats()`: Get role-specific statistics
- `get_task_details_json()`: Get complete task information

## Security Features

- **Role-based Access Control**: Strict authorization schemes
- **Data Access Validation**: Users can only access relevant tasks
- **Audit Trail**: Complete history of all actions
- **Session Management**: Secure user session handling
- **SQL Injection Prevention**: Parameterized queries throughout

## Monitoring & Analytics

### Built-in Reports
- Task completion rates by team
- Average approval times
- Overdue task analysis
- User productivity metrics
- System performance indicators

### Real-time Dashboards
- Executive summary for Senior users
- Team performance for TL users
- Personal productivity for TM users
- Project overview for PM users

## Troubleshooting

### Common Issues

1. **Login Problems**
   - Check user exists in tm_users table
   - Verify is_active = 'Y'
   - Check authentication function

2. **Notification Issues**
   - Verify APEX email configuration
   - Check tm_notifications table
   - Review trigger execution

3. **Workflow Problems**
   - Check task status consistency
   - Verify user roles and permissions
   - Review approval records

### Debug Queries

```sql
-- Check user roles
SELECT username, role_code, is_active FROM tm_users WHERE username = 'USER_NAME';

-- Check task workflow state
SELECT task_id, status, created_by, assigned_to_tl, assigned_to_tm FROM tm_tasks WHERE task_id = 123;

-- Check pending approvals
SELECT * FROM tm_approvals WHERE task_id = 123 AND status = 'PENDING';

-- Check notifications
SELECT * FROM tm_notifications WHERE user_id = 123 ORDER BY created_date DESC;
```

## Support

For technical support or questions:
1. Review the test results from `test_complete_workflow.sql`
2. Check the system health metrics in `v_workflow_metrics`
3. Review audit logs in `tm_comments` table
4. Verify data integrity using the built-in checks

## License

This Oracle APEX Task Management System is designed for enterprise use with Oracle Database and APEX environments.

---

**Version**: 1.0  
**Last Updated**: October 2024  
**Compatibility**: Oracle APEX 20.1+ / Oracle Database 19c+