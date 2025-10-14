# APEX Task Management (2-step approval)

Run in order in SQL Workshop or SQL*Plus:

1. `@01_schema.sql`
2. `@02_seed.sql`
3. `@03_pkg_task_workflow.sql`

Then build pages per `04_apex_notes.sql`.

Note: There is no `projects` entity; all workflow is task-centric.

Role mapping expects users in `USERS` table matching `:APP_USER`. Adjust seed usernames to your environment.
