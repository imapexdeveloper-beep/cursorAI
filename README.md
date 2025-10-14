# Task Management System - Oracle APEX Application

A comprehensive task management system with multi-level approval workflow built on Oracle APEX, designed to manage projects across multiple teams with role-based access control.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [System Architecture](#system-architecture)
- [User Roles](#user-roles)
- [Workflow](#workflow)
- [Installation](#installation)
- [Database Objects](#database-objects)
- [APEX Application Structure](#apex-application-structure)
- [Screenshots & Diagrams](#screenshots--diagrams)
- [Usage Guide](#usage-guide)
- [Technical Details](#technical-details)

---

## 🎯 Overview

This Task Management System enables organizations to efficiently manage tasks across multiple teams with a structured approval workflow. The system supports:

- **1 Project Manager** - Creates and oversees tasks
- **1 Senior Approver** - Final approval authority
- **6 Team Leaders** - Manages 6 teams and provides first-level approval
- **66 Team Members** - Executes tasks (11 members per team)

## ✨ Features

### Core Functionality
- ✅ **Task Creation & Assignment** - PM creates tasks and assigns to Team Leaders
- ✅ **Team Management** - TL assigns tasks to Team Members
- ✅ **Two-Level Approval Workflow**
  - Level 1: Team Leader Approval
  - Level 2: Senior Approval
- ✅ **Real-time Notifications** - Automatic notifications for all workflow events
- ✅ **Comment System** - Contextual comments for collaboration
- ✅ **Task Status Tracking** - Comprehensive status management
- ✅ **Priority Management** - LOW, MEDIUM, HIGH, URGENT priorities
- ✅ **Due Date Tracking** - Overdue indicators and reminders
- ✅ **Rejection Workflow** - Tasks can be rejected with mandatory comments for rework
- ✅ **Role-based Access Control** - Granular permissions based on user roles
- ✅ **Reporting Dashboard** - Analytics and insights
- ✅ **Audit Trail** - Complete history of task activities

### Task Statuses
1. **NEW** - Task created and assigned to Team Leader
2. **IN_PROGRESS** - Task assigned to Team Member and being worked on
3. **PENDING_TL_APPROVAL** - Submitted by TM, awaiting TL approval
4. **PENDING_SENIOR_APPROVAL** - TL approved, awaiting Senior approval
5. **APPROVED** - Fully approved by both TL and Senior
6. **REJECTED** - Rejected by TL or Senior, requires rework
7. **CANCELLED** - Task cancelled by PM

---

## 🏗 System Architecture

### Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         TASK WORKFLOW                                 │
└─────────────────────────────────────────────────────────────────────┘

  Project Manager (PM)
        │
        │ Creates Task & Assigns to TL
        ▼
  ┌──────────┐
  │   NEW    │
  └──────────┘
        │
        │ Team Leader assigns to Team Member
        ▼
  ┌──────────────┐
  │ IN_PROGRESS  │
  └──────────────┘
        │
        │ Team Member completes work & submits
        ▼
  ┌─────────────────────────┐
  │ PENDING_TL_APPROVAL     │
  └─────────────────────────┘
        │
        ├──► APPROVE (TL) ──────────────────────┐
        │                                        │
        └──► REJECT (TL) ──► REJECTED ──► Rework│
                                           │     │
                              ┌────────────┘     │
                              │                  ▼
                              │      ┌──────────────────────────────┐
                              │      │ PENDING_SENIOR_APPROVAL      │
                              │      └──────────────────────────────┘
                              │                  │
                              │      ├──► APPROVE (Senior) ──► APPROVED
                              │      │
                              └──────┴──► REJECT (Senior) ──► REJECTED ──► Rework
```

---

## 👥 User Roles

### 1. Project Manager (PM)
**Responsibilities:**
- Create new tasks
- Assign tasks to Team Leaders
- Monitor overall task progress
- Cancel tasks when needed
- View all tasks and reports

**Permissions:**
- Full visibility of all tasks they created
- Cannot approve tasks
- Can cancel tasks

### 2. Team Leader (TL)
**Responsibilities:**
- Receive tasks from PM
- Assign tasks to Team Members
- Review and approve/reject submitted tasks (Level 1 Approval)
- Provide feedback and comments
- Monitor team performance

**Permissions:**
- View tasks assigned to their team
- Assign tasks to team members
- Approve/reject tasks (with comments)
- View team reports

### 3. Team Member (TM)
**Responsibilities:**
- Work on assigned tasks
- Submit completed tasks for review
- Rework rejected tasks
- Add comments and updates

**Permissions:**
- View only tasks assigned to them
- Submit tasks for approval
- Add comments
- View own task history

### 4. Senior
**Responsibilities:**
- Provide final approval (Level 2)
- Review tasks approved by Team Leaders
- Reject tasks requiring higher standards
- Oversee quality across all teams

**Permissions:**
- View all tasks pending senior approval
- Approve/reject tasks after TL approval
- View reports across all teams

---

## 🔄 Workflow

### Complete Task Lifecycle

#### Step 1: Task Creation
```sql
PM creates task → Status: NEW → Notification sent to TL
```

#### Step 2: Task Assignment
```sql
TL assigns to TM → Status: IN_PROGRESS → Notification sent to TM
```

#### Step 3: Task Submission
```sql
TM completes work → Submits for review → Status: PENDING_TL_APPROVAL
→ Notification sent to TL
```

#### Step 4: Team Leader Approval
```sql
Option A: TL approves → Status: PENDING_SENIOR_APPROVAL → Notify Senior
Option B: TL rejects (with comments) → Status: REJECTED → Notify TM → Go to Step 3
```

#### Step 5: Senior Approval
```sql
Option A: Senior approves → Status: APPROVED → Notify TM & TL → Complete
Option B: Senior rejects (with comments) → Status: REJECTED → Notify TM → Go to Step 3
```

---

## 📦 Installation

### Prerequisites
- Oracle Database 11g or higher
- Oracle APEX 19.2 or higher
- SQL*Plus or SQL Developer
- Appropriate database privileges (CREATE TABLE, CREATE SEQUENCE, CREATE PACKAGE, etc.)

### Step-by-Step Installation

#### 1. Database Setup

Execute the SQL scripts in order:

```bash
# Connect to your Oracle database
sqlplus username/password@database

# Run installation scripts
@01_create_tables.sql
@02_create_sequences_triggers.sql
@03_create_views.sql
@04_create_package.sql
@05_sample_data.sql
```

#### 2. Verify Database Installation

```sql
-- Check tables
SELECT table_name FROM user_tables 
WHERE table_name IN ('APP_USERS', 'TASKS', 'TASK_APPROVALS', 'TASK_COMMENTS', 'TASK_NOTIFICATIONS');

-- Check sample data
SELECT role, COUNT(*) FROM app_users GROUP BY role;
SELECT status, COUNT(*) FROM tasks GROUP BY status;

-- Verify package
SELECT object_name, status FROM user_objects WHERE object_name = 'PKG_TASK_MANAGEMENT';
```

#### 3. APEX Application Setup

**Option A: Import Application (Recommended)**
1. Log into APEX workspace
2. Go to `App Builder` > `Import`
3. Import the application export file (if provided)
4. Run the application

**Option B: Manual Creation**
1. Create a new application in APEX
2. Set authentication to "Application Express Accounts"
3. Follow the detailed structure in `06_apex_application_setup.sql`
4. Create pages as specified in `07_apex_pages_structure.sql`
5. Configure shared components (LOVs, Authorization Schemes)
6. Test the application

#### 4. User Setup

Create APEX user accounts matching the database users:

```sql
-- Example: Create APEX users
-- This should be done through APEX Administration
-- Navigate to: Manage Workspace > Manage Users and Groups

-- Or use SQL:
BEGIN
    -- Create PM user
    APEX_UTIL.CREATE_USER(
        p_user_name => 'PM_JOHN',
        p_email_address => 'john.smith@company.com',
        p_web_password => 'Welcome123!',
        p_change_password_on_first_use => 'Y'
    );
    
    -- Repeat for other users (TL, TM, Senior)
END;
/
```

#### 5. Initial Configuration

1. Log in as PM_JOHN
2. Verify navigation menu appears correctly
3. Create a test task
4. Log in as TL to verify assignment works
5. Test the complete workflow

---

## 🗄 Database Objects

### Tables

#### 1. **APP_USERS**
Stores user information and role assignments.

| Column | Type | Description |
|--------|------|-------------|
| user_id | NUMBER | Primary key |
| username | VARCHAR2(100) | Unique username (matches APEX user) |
| full_name | VARCHAR2(200) | User's full name |
| email | VARCHAR2(200) | Email address |
| role | VARCHAR2(20) | PM, TL, TM, or SENIOR |
| team_id | NUMBER | Team assignment (for TL and TM) |
| is_active | VARCHAR2(1) | Active status flag |

#### 2. **TASKS**
Main task information and workflow status.

| Column | Type | Description |
|--------|------|-------------|
| task_id | NUMBER | Primary key |
| title | VARCHAR2(500) | Task title |
| description | CLOB | Detailed description |
| status | VARCHAR2(30) | Current status |
| priority | VARCHAR2(20) | Task priority |
| created_by | VARCHAR2(100) | Creator username |
| assigned_to_tl | NUMBER | Assigned Team Leader |
| assigned_to_tm | NUMBER | Assigned Team Member |
| due_date | DATE | Target completion date |
| submitted_date | DATE | Date submitted for review |
| tl_approval_date | DATE | TL approval timestamp |
| senior_approval_date | DATE | Senior approval timestamp |

#### 3. **TASK_APPROVALS**
Audit trail of all approvals and rejections.

| Column | Type | Description |
|--------|------|-------------|
| approval_id | NUMBER | Primary key |
| task_id | NUMBER | Related task |
| approval_level | VARCHAR2(20) | TL or SENIOR |
| approver_id | NUMBER | User who approved/rejected |
| approval_status | VARCHAR2(20) | APPROVED or REJECTED |
| comments | CLOB | Approval/rejection comments |
| approval_date | DATE | Timestamp |

#### 4. **TASK_COMMENTS**
All comments and task discussions.

| Column | Type | Description |
|--------|------|-------------|
| comment_id | NUMBER | Primary key |
| task_id | NUMBER | Related task |
| comment_text | CLOB | Comment content |
| comment_type | VARCHAR2(20) | GENERAL, REJECTION, APPROVAL, STATUS_CHANGE |
| commented_by | VARCHAR2(100) | Username |
| comment_date | DATE | Timestamp |

#### 5. **TASK_NOTIFICATIONS**
User notifications for workflow events.

| Column | Type | Description |
|--------|------|-------------|
| notification_id | NUMBER | Primary key |
| task_id | NUMBER | Related task |
| user_id | NUMBER | Recipient user |
| notification_type | VARCHAR2(50) | Type of notification |
| notification_text | VARCHAR2(1000) | Message |
| is_read | VARCHAR2(1) | Read status flag |

### Views

#### 1. **V_TASK_DASHBOARD**
Comprehensive task view with all related information.

#### 2. **V_MY_TASKS**
User-specific task view based on :APP_USER.

#### 3. **V_PENDING_APPROVALS**
Tasks awaiting approval by TL or Senior.

#### 4. **V_TASK_HISTORY**
Complete audit trail of task events.

### PL/SQL Package: PKG_TASK_MANAGEMENT

Key procedures:
- `create_task()` - Create new task
- `assign_task_to_tm()` - Assign to team member
- `submit_task_for_review()` - Submit for approval
- `approve_task_tl()` - TL approval
- `reject_task_tl()` - TL rejection
- `approve_task_senior()` - Senior approval
- `reject_task_senior()` - Senior rejection
- `send_notification()` - Send user notification
- `add_comment()` - Add task comment

---

## 🎨 APEX Application Structure

### Pages

| Page | Name | Role | Description |
|------|------|------|-------------|
| 1 | Home Dashboard | All | Landing page with user-specific overview |
| 10 | My Tasks | TM | Team member's active tasks |
| 11 | Task Detail | All | Detailed task view with comments and history |
| 20 | Create Task | PM | Task creation form |
| 30 | Manage Tasks | TL | Team Leader's task management |
| 31 | Assign Task to TM | TL | Assignment form |
| 40 | Pending Approvals | TL, Senior | Approval queue |
| 41 | Approve/Reject Task | TL, Senior | Approval decision form |
| 50 | All Tasks | PM, TL | Complete task list |
| 60 | Reports Dashboard | All | Charts and analytics |
| 70 | Notifications | All | User notification center |

### Authorization Schemes

- `IS_PM` - Project Manager only
- `IS_TL` - Team Leader only
- `IS_TM` - Team Member only
- `IS_SENIOR` - Senior only
- `IS_PM_OR_TL` - PM or TL
- `IS_TL_OR_SENIOR` - TL or Senior

### List of Values (LOVs)

- `TEAM_LEADERS_LOV` - Active team leaders
- `TEAM_MEMBERS_LOV` - Team members (filtered by TL's team)
- `ALL_TEAM_MEMBERS_LOV` - All team members
- `TASK_STATUS_LOV` - Status options
- `PRIORITY_LOV` - Priority levels
- `USER_ROLES_LOV` - System roles

---

## 📖 Usage Guide

### For Project Managers

#### Creating a Task
1. Navigate to **Create Task** (Page 20)
2. Fill in:
   - Task Title
   - Description
   - Assign to Team Leader (select from dropdown)
   - Priority (Low/Medium/High/Urgent)
   - Due Date (optional)
3. Click **Create Task**
4. Task is created with status NEW and TL is notified

#### Monitoring Tasks
1. Go to **All Tasks** (Page 50)
2. Use filters to find specific tasks
3. Click task to view details
4. Monitor approval progress
5. View reports in **Reports Dashboard** (Page 60)

### For Team Leaders

#### Assigning Tasks
1. Check **Manage Tasks** (Page 30)
2. Find tasks with status NEW
3. Click **Assign to Team Member**
4. Select team member from dropdown
5. Confirm assignment
6. Status changes to IN_PROGRESS

#### Reviewing Submissions
1. Go to **Pending Approvals** (Page 40)
2. Review task with status PENDING_TL_APPROVAL
3. Click to open approval form
4. Choose APPROVE or REJECT
5. For rejection: **Comments are mandatory**
6. Submit decision
7. If approved: Task goes to Senior
8. If rejected: TM is notified to rework

### For Team Members

#### Working on Tasks
1. Navigate to **My Tasks** (Page 10)
2. View tasks assigned to you
3. Work on tasks with status IN_PROGRESS
4. Add comments as needed
5. When complete, click **Submit for Review**
6. Status changes to PENDING_TL_APPROVAL

#### Handling Rejections
1. Check **My Tasks** for REJECTED tasks
2. Read rejection comments
3. Rework the task based on feedback
4. Re-submit for review
5. Process repeats until approved

### For Senior

#### Final Approval
1. Go to **Pending Approvals** (Page 40)
2. Review tasks with status PENDING_SENIOR_APPROVAL
3. These tasks are already TL-approved
4. Review work quality
5. Approve or reject with comments
6. If approved: Task is complete (status APPROVED)
7. If rejected: Returns to TM for rework

---

## 🔧 Technical Details

### Key Features Implementation

#### 1. Automatic Notifications
Notifications are sent automatically via the `send_notification()` procedure:
- Task assigned to TL
- Task assigned to TM
- Task submitted for review
- Task approved at each level
- Task rejected with reason

#### 2. Status Transitions
Valid status transitions enforced by package procedures:
```
NEW → IN_PROGRESS → PENDING_TL_APPROVAL → PENDING_SENIOR_APPROVAL → APPROVED
                ↓              ↓                      ↓
              REJECTED ←── REJECTED ←────────── REJECTED
                ↓
           IN_PROGRESS (rework)
```

#### 3. Role-Based Security
- Database level: Views filter data based on :APP_USER
- APEX level: Authorization schemes control page access
- Button level: Dynamic visibility based on role and task status

#### 4. Audit Trail
Complete history maintained through:
- task_approvals table (all approval decisions)
- task_comments table (all comments)
- v_task_history view (unified timeline)

### Performance Considerations

#### Indexes
All critical columns are indexed:
- Foreign keys
- Status columns
- Date columns
- User assignment columns

#### Views
Views use efficient joins and are optimized for common queries.

### Security Best Practices

1. **SQL Injection Prevention**: All inputs use bind variables
2. **Authorization**: Multi-layer security (DB + APEX)
3. **Audit Trail**: All actions logged with username and timestamp
4. **Data Validation**: Check constraints on critical columns
5. **Role Separation**: Clear role boundaries enforced

---

## 📊 Sample Data

The system comes with pre-populated sample data:

- **1 Project Manager**: PM_JOHN
- **1 Senior**: SENIOR_MARY
- **6 Team Leaders**: TL_JAMES, TL_PATRICIA, TL_ROBERT, TL_JENNIFER, TL_MICHAEL, TL_LINDA
- **66 Team Members**: 11 per team (TM_TEAM1_01 to TM_TEAM6_11)
- **6 Sample Tasks**: Demonstrating all workflow statuses

### Test Credentials
```
Username: PM_JOHN
Password: Welcome123!

Username: TL_JAMES
Password: Welcome123!

Username: TM_TEAM1_01
Password: Welcome123!

Username: SENIOR_MARY
Password: Welcome123!
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. "User not found" error
**Solution**: Ensure APEX username matches database username in APP_USERS table.

#### 2. Authorization scheme fails
**Solution**: Check that user has correct role in APP_USERS table.

#### 3. Notifications not appearing
**Solution**: Verify task_notifications table has records and user_id is correct.

#### 4. Cannot submit task for review
**Solution**: Ensure task status is IN_PROGRESS and user is the assigned TM.

#### 5. Package compilation errors
**Solution**: 
```sql
-- Check errors
SELECT * FROM user_errors WHERE name = 'PKG_TASK_MANAGEMENT';

-- Recompile
ALTER PACKAGE pkg_task_management COMPILE;
ALTER PACKAGE pkg_task_management COMPILE BODY;
```

---

## 📝 Customization Guide

### Adding More Teams

1. **Add Team Leader**:
```sql
INSERT INTO app_users (username, full_name, email, role, team_id, is_active, created_by)
VALUES ('TL_NEW', 'New Team Leader', 'new.tl@company.com', 'TL', 7, 'Y', 'ADMIN');
```

2. **Add Team Members**:
```sql
INSERT INTO app_users (username, full_name, email, role, team_id, is_active, created_by)
VALUES ('TM_TEAM7_01', 'Team Member 7.01', 'tm.team7.01@company.com', 'TM', 7, 'Y', 'ADMIN');
```

### Adding New Status

1. Modify TASKS table constraint
2. Update LOV
3. Add logic to package procedures
4. Update views if needed

### Custom Reports

Add new regions to Page 60 with custom SQL:
```sql
-- Example: Tasks completed this month
SELECT COUNT(*) as completed_tasks
FROM tasks
WHERE status = 'APPROVED'
  AND TRUNC(completed_date, 'MM') = TRUNC(SYSDATE, 'MM');
```

---

## 🤝 Support & Contribution

### Documentation
- Database schema: See table creation scripts
- API documentation: Comments in PKG_TASK_MANAGEMENT package
- APEX pages: Detailed in 07_apex_pages_structure.sql

### Best Practices
1. Always add comments when rejecting tasks
2. Set realistic due dates
3. Regular status reviews
4. Monitor pending approvals
5. Use priority flags appropriately

---

## 📄 License

This application is provided as-is for educational and business purposes.

---

## 🎓 Learning Resources

### Oracle APEX
- [APEX Documentation](https://docs.oracle.com/en/database/oracle/apex/)
- [APEX Community](https://apex.oracle.com/community)

### PL/SQL
- [PL/SQL Language Reference](https://docs.oracle.com/en/database/oracle/oracle-database/19/lnpls/)

---

## ✅ Checklist for Deployment

- [ ] Database scripts executed successfully
- [ ] All tables created
- [ ] Sequences and triggers working
- [ ] Views returning data
- [ ] Package compiled without errors
- [ ] Sample data loaded
- [ ] APEX application created
- [ ] Authorization schemes configured
- [ ] LOVs populated
- [ ] Pages created and tested
- [ ] User accounts created
- [ ] Navigation menu working
- [ ] Test complete workflow
- [ ] Notifications working
- [ ] Reports displaying correctly

---

## 📞 Contact

For questions or support, please contact your database administrator or APEX development team.

---

**Version**: 1.0  
**Last Updated**: 2025-10-14  
**Author**: Oracle APEX Development Team
