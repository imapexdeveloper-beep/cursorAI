# Task Management System - Workflow Diagrams

## Complete Workflow Visualization

### 1. Main Task Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         TASK MANAGEMENT WORKFLOW                            │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐
│ Project Manager │
│      (PM)       │
└────────┬────────┘
         │
         │ 1. Creates Task
         │    - Title
         │    - Description  
         │    - Priority
         │    - Due Date
         │
         ▼
    ┌─────────┐
    │   NEW   │ ← Task created and assigned to Team Leader
    └─────────┘
         │
         │ 2. TL receives notification
         │
┌────────┴────────┐
│  Team Leader    │
│      (TL)       │
└────────┬────────┘
         │
         │ 3. Assigns to Team Member
         │
         ▼
  ┌───────────────┐
  │  IN_PROGRESS  │ ← Team Member starts working
  └───────────────┘
         │
         │ 4. TM works on task
         │    - Adds comments
         │    - Updates progress
         │
┌────────┴────────┐
│  Team Member    │
│      (TM)       │
└────────┬────────┘
         │
         │ 5. Submits for review
         │
         ▼
  ┌──────────────────────┐
  │ PENDING_TL_APPROVAL  │ ← Awaiting Team Leader review
  └──────────────────────┘
         │
         ├─────────────────────────┬───────────────────────┐
         │                         │                       │
         │ 6a. TL APPROVES        │ 6b. TL REJECTS       │
         │     (with comments)     │     (with comments)   │
         │                         │                       │
         ▼                         ▼                       │
  ┌────────────────────────┐  ┌────────────┐            │
  │ PENDING_SENIOR_APPROVAL│  │  REJECTED  │─────┐      │
  └────────────────────────┘  └────────────┘     │      │
         │                         │              │      │
         │ 7. Senior reviews       │              │      │
         │                         │ 8. TM reworks│      │
         │                         │              │      │
         ├──────────┬─────────     └──────────────┘      │
         │          │                     │               │
         │ 8a. APPROVE │ 8b. REJECT      │               │
         │          │                     │               │
         ▼          ▼                     ▼               │
    ┌──────────┐ ┌────────────┐   Back to IN_PROGRESS  │
    │ APPROVED │ │  REJECTED  │          │               │
    └──────────┘ └────────────┘          │               │
         │              │                 │               │
         │              └─────────────────┴───────────────┘
         │
         ▼
    TASK COMPLETE
```

---

## 2. Role-Based Views

### Project Manager (PM) View

```
┌──────────────────────────────────────────────────────────┐
│                   PROJECT MANAGER                        │
└──────────────────────────────────────────────────────────┘

Actions Available:
┌─────────────────────┐
│  Create New Task    │ ─────► Assign to Team Leader
└─────────────────────┘
           │
           ▼
┌─────────────────────┐
│  Monitor Progress   │
│  - View all tasks   │
│  - Check statuses   │
│  - View reports     │
└─────────────────────┘
           │
           ▼
┌─────────────────────┐
│  Cancel Task        │ (if needed)
└─────────────────────┘

Visibility: All tasks created by PM
Permissions: Create, View, Cancel (not Approve)
```

### Team Leader (TL) View

```
┌──────────────────────────────────────────────────────────┐
│                     TEAM LEADER                          │
└──────────────────────────────────────────────────────────┘

Step 1: Receive Task
┌─────────────────────┐
│  NEW task arrives   │ ◄──── Notification
└─────────────────────┘
           │
           ▼
Step 2: Assign
┌─────────────────────┐
│ Assign to TM in     │
│ my team (Team 1-6)  │
└─────────────────────┘
           │
           ▼
Step 3: Monitor
┌─────────────────────┐
│ Track TM progress   │
└─────────────────────┘
           │
           ▼
Step 4: Review & Approve
┌─────────────────────┐
│ PENDING_TL_APPROVAL │
└─────────────────────┘
           │
           ├──► Approve ──► To Senior
           │
           └──► Reject ──► Back to TM with comments

Visibility: All tasks for their team
Permissions: Assign to TM, Approve/Reject (Level 1)
```

### Team Member (TM) View

```
┌──────────────────────────────────────────────────────────┐
│                    TEAM MEMBER                           │
└──────────────────────────────────────────────────────────┘

Step 1: Receive Assignment
┌─────────────────────┐
│  IN_PROGRESS task   │ ◄──── Notification
└─────────────────────┘
           │
           ▼
Step 2: Work on Task
┌─────────────────────┐
│  - Do the work      │
│  - Add comments     │
│  - Update status    │
└─────────────────────┘
           │
           ▼
Step 3: Submit
┌─────────────────────┐
│ Submit for Review   │
└─────────────────────┘
           │
           ▼
Step 4: Wait for Approval
┌─────────────────────┐
│  PENDING APPROVAL   │
└─────────────────────┘
           │
           ├──► APPROVED ──► Task Complete! ✓
           │
           └──► REJECTED ──► Read comments, rework, resubmit

Visibility: Only tasks assigned to them
Permissions: Work on tasks, Submit for review, Add comments
```

### Senior Approver View

```
┌──────────────────────────────────────────────────────────┐
│                   SENIOR APPROVER                        │
└──────────────────────────────────────────────────────────┘

Step 1: Receive for Final Approval
┌───────────────────────────┐
│ PENDING_SENIOR_APPROVAL   │ ◄──── Already TL-approved
└───────────────────────────┘
           │
           ▼
Step 2: Review Quality
┌─────────────────────┐
│ - Check work        │
│ - Review TL notes   │
│ - Verify standards  │
└─────────────────────┘
           │
           ▼
Step 3: Final Decision
┌─────────────────────┐
│  Make Decision      │
└─────────────────────┘
           │
           ├──► APPROVE ──► APPROVED (Final!) ✓
           │
           └──► REJECT ──► Back to TM with comments

Visibility: All tasks pending senior approval
Permissions: Final Approve/Reject (Level 2)
```

---

## 3. Notification Flow

```
┌──────────────────────────────────────────────────────────┐
│                  NOTIFICATION SYSTEM                     │
└──────────────────────────────────────────────────────────┘

Event: Task Created
  │
  ▼
┌─────────────────────┐
│ Notify Team Leader  │ "New task assigned to you"
└─────────────────────┘

Event: Task Assigned to TM
  │
  ▼
┌─────────────────────┐
│ Notify Team Member  │ "New task assigned to you"
└─────────────────────┘

Event: Task Submitted
  │
  ▼
┌─────────────────────┐
│ Notify Team Leader  │ "Task ready for your review"
└─────────────────────┘

Event: TL Approves
  │
  ▼
┌─────────────────────┐
│ Notify Senior       │ "Task ready for Senior approval"
└─────────────────────┘

Event: TL Rejects
  │
  ▼
┌─────────────────────┐
│ Notify Team Member  │ "Task rejected - please rework"
└─────────────────────┘

Event: Senior Approves
  │
  ├──► Notify Team Member: "Task approved!"
  │
  └──► Notify Team Leader: "Task approved by Senior"

Event: Senior Rejects
  │
  ├──► Notify Team Member: "Task rejected by Senior - please rework"
  │
  └──► Notify Team Leader: "Task rejected by Senior"
```

---

## 4. Status Transition Diagram

```
┌──────────────────────────────────────────────────────────┐
│               VALID STATUS TRANSITIONS                   │
└──────────────────────────────────────────────────────────┘

                    ┌─────────┐
                    │   NEW   │
                    └────┬────┘
                         │
                         │ assign_task_to_tm()
                         ▼
                  ┌─────────────┐
                  │ IN_PROGRESS │
                  └──────┬──────┘
                         │
                         │ submit_task_for_review()
                         ▼
             ┌──────────────────────┐
             │ PENDING_TL_APPROVAL  │
             └──────────┬───────────┘
                        │
          ┌─────────────┴─────────────┐
          │                           │
    approve_task_tl()          reject_task_tl()
          │                           │
          ▼                           ▼
┌───────────────────────┐      ┌────────────┐
│PENDING_SENIOR_APPROVAL│      │  REJECTED  │
└───────┬───────────────┘      └─────┬──────┘
        │                            │
        │                            │ Rework
  ┌─────┴──────┐                     │
  │            │                     │
approve  reject_task_senior()        │
  │            │                     │
  ▼            ▼                     │
┌──────┐  ┌────────────┐            │
│APPROVE│  │  REJECTED  │◄───────────┘
└──────┘  └────────────┘

Note: CANCELLED status can be set by PM from any state
```

---

## 5. Data Flow Diagram

```
┌──────────────────────────────────────────────────────────┐
│                    DATA FLOW                             │
└──────────────────────────────────────────────────────────┘

┌──────────────┐
│    TASKS     │ ◄──── Main task data
└──────┬───────┘
       │
       ├────► ┌─────────────────┐
       │      │ TASK_APPROVALS  │ ◄──── Approval history
       │      └─────────────────┘
       │
       ├────► ┌─────────────────┐
       │      │ TASK_COMMENTS   │ ◄──── Comments & notes
       │      └─────────────────┘
       │
       └────► ┌──────────────────────┐
              │ TASK_NOTIFICATIONS   │ ◄──── User notifications
              └──────────────────────┘

              ┌──────────────┐
              │  APP_USERS   │ ◄──── User information & roles
              └──────────────┘

Views combine this data:
┌────────────────────┐
│ V_TASK_DASHBOARD   │ ◄──── Complete task view
└────────────────────┘
┌────────────────────┐
│ V_PENDING_APPROVALS│ ◄──── Approval queue
└────────────────────┘
┌────────────────────┐
│ V_TASK_HISTORY     │ ◄──── Audit trail
└────────────────────┘
```

---

## 6. Approval Decision Tree

```
┌──────────────────────────────────────────────────────────┐
│              APPROVAL DECISION TREE                      │
└──────────────────────────────────────────────────────────┘

Task submitted for review
         │
         ▼
    Is TM happy with work?
         │
    ┌────┴────┐
    │  YES    │  NO → Continue working
    └────┬────┘
         │
         ▼
    Submit to TL
         │
         ▼
    TL reviews work
         │
    ┌────┴────┐
    │         │
   GOOD    NEEDS WORK
    │         │
    │    Reject with
    │    detailed comments
    │         │
    │         └──► TM reworks
    │                   │
    └───────────────────┘
         │
    Approve & send to Senior
         │
         ▼
    Senior reviews work
         │
    ┌────┴──────────┐
    │               │
  EXCELLENT    NEEDS IMPROVEMENT
    │               │
    │          Reject with
    │          feedback
    │               │
    │               └──► TM reworks
    │                        │
    └────────────────────────┘
         │
    Final Approval
         │
         ▼
    TASK COMPLETE ✓
```

---

## 7. Time-based Workflow

```
┌──────────────────────────────────────────────────────────┐
│              TYPICAL TASK TIMELINE                       │
└──────────────────────────────────────────────────────────┘

Day 1:  PM creates task ──────────► NEW
        └──► TL notified

Day 1:  TL assigns to TM ─────────► IN_PROGRESS
        └──► TM notified

Day 2-5: TM works on task
         - Regular updates
         - Comments added

Day 5:  TM submits ───────────────► PENDING_TL_APPROVAL
        └──► TL notified

Day 6:  TL reviews
        │
        ├─► Approves ─────────────► PENDING_SENIOR_APPROVAL
        │   └──► Senior notified
        │
        └─► OR Rejects ───────────► REJECTED
            └──► TM reworks (back to Day 2)

Day 7:  Senior reviews
        │
        ├─► Approves ─────────────► APPROVED ✓
        │   └──► TM & TL notified
        │
        └─► OR Rejects ───────────► REJECTED
            └──► TM reworks (back to Day 2)

Total time for successful task: 6-7 days
(varies based on complexity and rejection cycles)
```

---

## 8. Error Handling Flow

```
┌──────────────────────────────────────────────────────────┐
│              ERROR & REJECTION HANDLING                  │
└──────────────────────────────────────────────────────────┘

Rejection by TL
    │
    ├──► Status = REJECTED
    ├──► Mandatory comments added
    ├──► Notification sent to TM
    └──► TM sees:
         - Rejection reason
         - Specific feedback
         - What to improve
    │
    ▼
TM reads feedback
    │
    ▼
TM reworks task
    │
    ▼
TM resubmits ────────────► PENDING_TL_APPROVAL
    │
    └──► Cycle repeats until approved

Rejection by Senior
    │
    ├──► Status = REJECTED
    ├──► Mandatory comments added
    ├──► Notifications sent to TM & TL
    └──► TM sees:
         - Senior's feedback
         - Quality concerns
         - Standards not met
    │
    ▼
TM discusses with TL (if needed)
    │
    ▼
TM reworks with higher quality
    │
    ▼
TM resubmits ────────────► PENDING_TL_APPROVAL
    │
    └──► Full cycle repeats

Note: No limit on rejection cycles
      Task improves with each iteration
```

---

## 9. Team Structure

```
┌──────────────────────────────────────────────────────────┐
│                 ORGANIZATIONAL STRUCTURE                 │
└──────────────────────────────────────────────────────────┘

                    ┌─────────────┐
                    │   SENIOR    │ (1 person)
                    │   APPROVER  │
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │                         │
        ┌─────▼──────┐          ┌──────▼─────┐
        │  PROJECT   │          │   TEAM     │
        │  MANAGER   │◄────────►│  LEADERS   │ (6 people)
        └────────────┘          └──────┬─────┘
              │                        │
              │                        │
              │         ┌──────────────┴──────────────┐
              │         │              │              │
              │    ┌────▼───┐    ┌────▼───┐    ┌────▼───┐
              │    │ Team 1 │    │ Team 2 │... │ Team 6 │
              │    │ 11 TMs │    │ 11 TMs │    │ 11 TMs │
              │    └────────┘    └────────┘    └────────┘
              │         │              │              │
              └─────────┴──────────────┴──────────────┘
                        Total: 66 Team Members

Task Flow:
PM ──► TL ──► TM ──► TL ──► SENIOR
```

---

## Quick Reference

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Two-Level Approval** | TL approves first, then Senior |
| **Mandatory Comments** | Required when rejecting tasks |
| **Notifications** | Automatic at every workflow step |
| **Role-Based Access** | Each role sees only relevant tasks |
| **Audit Trail** | Complete history maintained |
| **Rework Cycle** | Rejected tasks can be resubmitted |

### Status Summary

| Status | Who Sees | Next Action |
|--------|----------|-------------|
| NEW | PM, TL | TL assigns to TM |
| IN_PROGRESS | TM, TL | TM works and submits |
| PENDING_TL_APPROVAL | TL, TM | TL approves/rejects |
| PENDING_SENIOR_APPROVAL | Senior, TL, TM | Senior approves/rejects |
| APPROVED | All | Complete - No action |
| REJECTED | TM, TL | TM reworks |
| CANCELLED | All | Cancelled - No action |

---

**End of Workflow Documentation**
