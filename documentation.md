# 1. Introduction & Purpose

This database powers an automated hospital management system. It centralizes patient admissions, staff financials, medical services, and monthly operations. using native SQL logic such as triggers, procedures, events, and views.

The system is designed to:

- Reduce manual workload through event-driven automation
- Ensure consistency and safety using triggers and role-based procedures
- Provide real-time visibility into operations via views and summary tables
- Maintain financial accuracy by linking every patient action to cost and revenue outcomes

All logic is implemented within the database itself, eliminating the need for external schedulers or business logic layers. This approach ensures high reliability, integrity, and clarity in how processes are executed.

> This documentation explains each component of the system in depth, including why certain structures were chosen and how the system should be maintained and extended in production environments.

# 2. Database Schema Breakdown

The database is composed of several core entities, each handling a specific domain of hospital operations.

##  Core Tables

### `patients`
- Represents current inpatients
- Linked to `doctors`, `rooms`, and `patients_services`
- patient insert and removal happens via procedures
- Triggers handle billing, room status, and archiving on insert/delete

### `doctors`
- Each doctor has a max of 2 concurrent cases
- Tracks assigned case count and current salary (per case)
- Updated automatically via triggers

### `nurses`
- Salaries are calculated monthly using allowance, loan, deductions, and incentives
- Shift details are updated cyclically via an event
- Nurses are distributed across the hospital building, with equal coverage assigned per half-story. This is aligned with the shift-swapping mechanism to ensure fair workload distribution.

### `rooms`
- Each room has an `occupation` status
- Status toggled automatically upon patient insert/delete

### `services`
- Tracks all medical services (including urgency levels)
- `times_per_month` column reflects monthly usage — updated via triggers and events

### `patients_services`
- Junction table between `patients` and `services`
- Populated during patient insert and manually
- Triggers update `services.times_per_month` accordingly

### `past_cases`
- Connected with doctors table
- Archival of discharged patients
- Includes full billing data and treatment summaries

### `monthly_expenses`
- Holds fixed and dynamic monthly costs (teams, staff salaries, etc.)

### `monthly_income_statement`
- Summarizes revenue, cost, and net income monthly
- `income` is a generated column: `revenue - cost`

## `last_assigned_doctor`
- typically one cell acts as a dynamic variable to hold the last assgined doctor for the later next doctor

## `floors`
- a one column for hodling floors' numbers to connect them with nurses and rooms tables

## Special Design Notes
- `patients.id` is manually calculated to avoid gaps (auto-increment disabled)
- Urgency-level services are *not* treated like regular services in usage count
- Temporary summary tables (e.g., `last_assigned_doctor`) exist to manage rotation logic
- NULLs are accepted in fields that are filled post-trigger (e.g., `revision_date`)
- The schema includes both static reference tables (with preset initial data) and dynamic operational tables that are regularly updated, inserted into, or purged as part of normal workflows.

# 3. Triggers 

This system uses multiple triggers to enforce real-time automation and consistency.

## AFTER INSERT ON `patients`

- Updates:
  - Sets `rooms.occupation = 'yes'`
  - Updates `last_assigned_doctor` table with the most recently used doctor
  - Increases `doctors.assigned_cases` by 1
- Adds urgency-level service to `patients_services`
- **Note:** Adding urgency service directly (via string) avoids SELECT-from-table error in MySQL when that table is being updated

---

## AFTER INSERT ON `patients_services`

- Increases `services.times_per_month` by 1
- Ignores urgency-level services (`name LIKE 'urgency%'`) — those are handled elsewhere
- Fires on both manual and automatic insertions, but urgency-level logic won’t be affected due to name filter

## BEFORE DELETE ON `patients`

- Calculates:
  - Days spent based on `entrance_date`
  - Urgency-level cost: per-day * days spent
  - Additional services cost
  - Total payment = urgency + services
  - Detailed payment breakdown
- Inserts a new row into `past_cases` (archiving patient with cost info)
- Updates:
  - `rooms.occupation = 'no'`
  - `doctors.assigned_cases -= 1` and updates their salary
  - `services.times_per_month += days_spent` for urgency-level service
- This is the **main billing trigger** of the system

## Design Insights

- Urgency-level services are treated specially to calculate cost by duration, not frequency
- Decomposition of payment_details into formatted strings supports human readability in reporting
- Trigger logic assumes `services.name` strings are unique and correctly categorized

# 4. Stored Procedures

Stored procedures handle the main dynamic tasks across the system — from patient flow to staff financials. All logic runs with the data_architect’s privileges, enabling automation with safety controls.

## `patient_insert`

- Checks:
  - All rooms occupied?
  - All doctors maxed out (2 cases)?
- Finds next available:
  - `patient_id` (no gaps)
  - `doctor_id` (rotational, via `last_assigned_doctor`)
  - `room_id` (first available)
- Inserts new patient row → automatically fires triggers for room + doctor updates and urgency service

## `patient_removal`

- Deletes patient by ID
- Triggers archival (`BEFORE DELETE`)
- Updates final fields in `past_cases`: `revision_date`, `prescription`
- The update is necessary because the trigger inserts the row *without* these fields (nullable by design)

## `nurse_shifts`

- Rotates nurses’ personal details down one row (last loops to top)
- Affects: `name`, `phone`, `address`, `loan`, `allowance`
- Shift, salary, and incentive columns are not changed (reset at month start)
- Called via `nurses_shift_pro_call` event on the 1st of each month

## `teams_incentives`

- Runs only after 27th of the month
- Calculates salaries for outsourced teams (security, EMS, environmental)
  - Base + incentive × count
- Incentives passed as parameters; if none, pass 0

## `doctor_treated_cases`

- Combines results from:
  - `patients` (ongoing cases)
  - `past_cases` (archived)
- Output includes:
  - Case type (ongoing, archived, total archived)
  - Names of patients and cases
- Used for tracking doctor workloads and historical treatment

## `month_inc_stat_word_count`

- Counts how many times a given word appears in `cost_details` (monthly_income_statement)
- Filters by year (passed as param)
- Uses:
  - `REGEXP_REPLACE` to strip word occurrences
  - CTE for per-row counts
- Returns:
  - List of months where the word appears
  - Final SUM total across all months

## `nurses_payroll_factors_set`

- Runs before salary generation
- Updates nurses with:
  - Incentives (either by ID or “all”)
  - Deductions (with 3000 * percentage logic)
  - Allowances / loans (based on param arrays and position)
- Runs only before 27th (as salary setting is blocked after that)
- Used to prepare all financial factors for each nurse

## Design Notes

- Procedures use `FIND_IN_SET()` to support bulk updates via comma-separated IDs
- Some logic uses `SUBSTRING_INDEX()` for targeted value extraction (e.g., partial loan values)
- Manual error signaling is used to enforce business rules (e.g., date restrictions)

# 5. Scheduled Events

Events automate monthly and daily tasks, removing the need for manual intervention. Most run on specific days, and many depend on prior logic like triggers or procedures.

## `nurses_shift_pro_call`

- Executes on the 1st of every month
- Calls the `nurse_shifts` procedure to rotate nurse assignments
- Only personal data (name, phone, etc.) is rotated — shift and salary info remains untouched

## `creating_nurses_salaries`

- Executes near end of month (before financial closure)
- Calculates final nurse salaries:
  - Incentive + partial (10%) or full allowance (if less than 500)
  - Deduction + partial (10%) or full loan (if less than 500)
- Salary = fixed base + incentive + (allowance portion) - (deduction + loan portion)
- Sets financial columns to 0 after applying them

## `calculate_doctors_nurses_expenses`

- Executes every day, but actual logic execution **on the last day of the month**
- Updates `monthly_expenses` with:
  - Total of doctors' current salaries
  - Total of nurses' salaries
- Then resets:
  - `doctors.current_monthly_salary`
  - `nurses.salary`

## `income_statement_calculate`

- Executes **on the first day of the month**
- Inserts a row into `monthly_income_statement`:
  - `cost_details`: from non-zero expenses
  - `revenue_details`: from `services` usage
  - `revenue`: from sum of `past_cases.payment`
  - `cost`: sum of monthly expenses
- Resets:
  - `monthly_expenses.cost = 0`
  - `services.times_per_month = 0`
-  `income` is auto-generated from `revenue - cost`

## Event Strategy Notes

- Events are minimal and intentionally sequential
- Event order matters: salary → expense → income reporting

# 6. Views

Views are used to simplify reporting, summarize data. They reflect processed or grouped information, often combining live and historical records.

## `active_doctors`

- Lists doctors with active (ongoing) patients
- Joins `doctors` with `patients`
- Includes:
  - Doctor name, specialization, assigned case count
  - Patient name and case name
- Filters for `assigned_cases > 0`

## `urgency_level_summary`

- Combines:
  - Current patient urgency levels (`patients`)
  - Archived cases (parsed from `payment_details`)
- Uses CTEs and unions to create:
  - Header rows ("current", "past", "total")
  - Counts grouped by urgency level
- Useful for tracking patient case trends over time

## `monthly_income_statement_cumulative`

- Uses window functions to calculate:
  - Cumulative revenue, cost, income **per year**
- Includes:
  - Monthly breakdowns
  - Yearly summaries
  - Grand total across all years
- Ideal for trend charts, dashboards, or end-of-year reporting

## View Design Notes

- Views simplify frontend integration and reporting layers
- CTEs are used heavily to support complex unions and aggregation
- `SUBSTRING_INDEX()` is used to extract urgency info from text logs when data normalization isn't direct
- Views intentionally avoid referencing live calculations (like triggers) to keep them read-only

# 7. Data Flow & Automation Chains

This section maps the system's reactive behavior — how one action causes a chain of logic across the database. Most of the design runs without external app logic, fully contained in SQL.

## Patient Admission Flow

1. `patient_insert` procedure:
   - Checks doctor + room availability
   - Inserts into `patients`

2. `AFTER INSERT ON patients` trigger:
   - Marks room as occupied
   - Updates `last_assigned_doctor`
   - Increments doctor’s case count
   - Inserts urgency-level service into `patients_services`

3. `AFTER INSERT ON patients_services` trigger:
   - Adds 1 to `times_per_month` in `services` (except urgency-level services)

## Patient Discharge Flow

1. `patient_removal` procedure:
   - Deletes patient by ID

2. `BEFORE DELETE ON patients` trigger:
   - Calculates cost for urgency-level services based on days stayed
   - Calculates total cost and breakdown string
   - Inserts record into `past_cases`
   - Frees room + updates doctor case count + salary
   - Increments `services.times_per_month` for urgency-level by days


## Month-End Financial Chain

1. `creating_nurses_salaries` event:
   - Prepares nurses' final salaries
   - Resets incentive/deduction/loan/allowance values

2. `calculate_doctors_nurses_expenses` event:
   - Sums total staff salary payouts
   - Updates `monthly_expenses`
   - Resets salary columns

3. `income_statement_calculate` event:
   - Sums revenue (from `past_cases`)
   - Gathers cost and revenue details
   - Inserts into `monthly_income_statement`
   - Resets `services` and `monthly_expenses` counters

## Nurse Shift Rotation

- On the 1st of each month:
  - `nurses_shift_pro_call` event calls `nurse_shifts`
  - Personal details (name, phone, loan, etc.) rotate to the next nurse


## Automation Design Highlights

- Core logic is trigger-driven and chained through procedures
- Events simulate a real-world monthly cycle without needing cron jobs
- Business rules (like limits, cutoffs) are enforced through IF conditions or SIGNALs

## Data Flow Integrity & Manual Modification Risk

The system is designed to handle the majority of dynamic data using internal SQL mechanisms — such as triggers, scheduled events, and semi-automated procedures. These ensure that critical operations (like salary calculations, case assignments, service tracking, and archiving) are consistent, synchronized, and follow a structured logic.

Direct manual manipulation of core tables (especially `patients`, `nurses`, `doctors`, `patients_services`, `past_cases`, etc.) **bypasses this automation** and may result in:

- Missing or unlinked data
- Trigger chains not firing properly
- Incorrect totals or reports
- Overwritten auto-managed fields
- SQL warnings or critical constraint errors

To maintain the system’s stability and trustworthiness, **user roles are limited** to ensure only authorized roles (e.g. data_architecte, data_entry, financial_officer) can access relevant operations through proper procedures or views.

Manual entry outside of these workflows is strongly discouraged unless pre-cleared by the system maintainer (data_architecte user).

# 8. Edge Cases & Design Decisions

Some parts of the system were built with non-obvious decisions to protect performance, avoid MySQL limitations, or simplify future maintenance.

## Avoiding SELECT-from-UPDATE errors

- Inserting urgency-level services (e.g. `'Urgency Level: High'`) into `patients_services` avoids a `SELECT FROM services` call during the `AFTER INSERT` trigger on `patients`.
- Reason: MySQL doesn’t allow selecting from a table you’re updating within a trigger.

## Manually Controlled Patient IDs

- `patients.id` is not auto-incremented.
- IDs are generated by checking existing values to avoid gaps.
- Prevents accidental collisions when records are removed and reused.

## Urgency-Level Services Treated Separately

- Not counted by the general `AFTER INSERT ON patients_services` trigger.
- Instead, they're processed in `BEFORE DELETE ON patients`, using:
  - Days stayed × cost
- This avoids skewing the monthly service usage stats.

## Nullable Fields in `past_cases`

- Fields like `revision_date` and `prescription` are filled **after** the patient is archived (via procedure).
- They're left NULL during the trigger insert intentionally.
- The `patient_removal` procedure then completes the data.

## Monthly Constraints

- Some procedures and events check:
  - If today is before the 27th → prevent salary/expense actions
  - If it's the last day → allow month-end processing
  - This enforces a real-world payroll and financial cycle

## View Design Choices

- Views like `urgency_level_summary` and `monthly_income_statement_cumulative` are heavily unioned/aggregated to support dashboards
- Use of `WITH` CTEs simplifies logic and makes reuse clearer

# 9. User Roles & Privilege Design

Access is tightly scoped by role to minimize errors, enforce accountability, and protect the database's integrity. Below are the defined user types and their responsibilities.

## data_entry

- Tasks:
  - Add new patients
  - Remove patients after discharge
- Access:
  - Execution on related procedures of `patients`
  - Inserting into patient_services table

## financial_officer

- Tasks:
  - Set incentives, deductions, allowances
  - View revenue and cost reports
- Access:
  - UPDATE on `nurses`, `monthly_expenses`
  - SELECT on financial views and income statements

## executive

- Tasks:
  - Monitor operations
  - Review analytics and views
- Access:
  - SELECT-only access across all major tables and views

## data_architect (Developer Role)

- Tasks:
  - Design, edit, and deploy all logic (procedures, triggers, views, events)
  - Create/alter tables and logic structures
- Access:
  - Full privileges: CREATE, ALTER, DROP, EXECUTE, and all data privileges
- Note:
  - All system logic is created and executed under this role’s privileges
  - Changes are logged and reviewed before deployment in production

## data_security

- Tasks:
  - Monitor user activity and roles
  - Oversee usage logs or access reports 
- Access:
  - Has full global administration privileges to create users, grant/revoke their privileges, lock them, etc.

## Design Rationale

- Procedures, triggers, views, and events are protected from unauthorized changes
- Logic execution is sandboxed under the definer data_architect (not the invoker) to ensure traceability and security, so no need to grant unnecessary proccess (like selection, update, insert or delete) to users like data_entry as he just needs to execute the procedures (which includes insertion, deletion or update) under the privileges of the definer data_architect
- For data_architect, he is the definer of all logics, so he shouldn't be locked because as a consequence; locking him will cause the logics to halt, that will also prevent other users to do their tasks

## Password Handling

- All user passwords are encrypted (hashed) for security, even during testing
- Default password for all roles is set to `'123'` (encrypted) to simplify testing and role verification
- This allows the client to quickly log in as each user to validate access boundaries and privileges
- In production, it's advised to reset each password and enforce stricter password policies

# 10. Performance & Integrity Considerations

The database was designed to balance automation and performance. Triggers, procedures, and indexing choices aim to avoid common bottlenecks in transactional systems like hospitals.

## Trigger Efficiency

- Triggers avoid deep SELECTs or nested loops
- Most triggers:
  - Operate on single-row context (e.g. `AFTER INSERT`)
  - Chain to procedures when logic is complex (e.g. patient deletion)

## Smart Use of CTEs and Views

- Views like `monthly_yearly_income_statement_report` use CTEs + window functions to reduce complexity
- CTEs reused instead of repeating logic
- Views are SELECT-only for safety and clarity

## Preventing Logic Conflicts

- Urgency-level services are updated *only* during patient deletion to avoid conflict with concurrent triggers
- Manual patient service insertions are handled separately
- `patients_services` logic separates trigger and procedural impact

## Data Reset for Metrics

- `services.times_per_month` and `monthly_expenses.cost` reset monthly via events
- Ensures reports always show clean, rolling metrics
- `income` is a STORED GENERATED column for instant recalculation

## Indexed Time Columns

- Time-based fields like `month` in `monthly_income_statement` are indexed
- Used in ORDER BY, GROUP BY, and filtering in views/events
- Boosts performance in financial aggregations

## Safe Defaults & Constraints

- Nullable fields (`revision_date`, `prescription`) are used intentionally, and filled later
- Foreign key constraints + data consistency logic (e.g. `room_id`, `doctor_id`) enforced by flow
- Signal-based errors (e.g. "cannot update after 26th") protect business rules in real-time

## Minimal Locking, No Deadlocks

- No bulk updates across unrelated tables in one transaction
- Conditional updates use indexed (primary) IDs
- Procedures target specific rows using `FIND_IN_SET()` or primary keys to avoid full-table locks

## License & Usage Terms
This project and all accompanying documentation are provided for personal, academic, and educational use only.
This material is not licensed for use in commercial, clinical, or business systems without prior written permission.
Attribution to the original author Ibrahim Sherif Mohamed is required when used for public sharing, education, or presentation.
Redistribution or modification for business purposes (including hospitals or paid systems) is not allowed without a commercial license.
For commercial licensing or business use inquiries, please contact:
ibrahimsherif.virtualnomadic@gmail.com

## Final Note

- Important Note Regarding users.sql:
This file contains user creation logic, but it is not intended to be executed independently under the following conditions:
When importing the full database using hospitalPHPMyAdmin.sql file or separate files individually (here you should follow the individual files order when importing):
All necessary users are created within that file, aligned with their required order and context — there is no need to run users.sql separately.

When importing components of the database selectively (using your own preferences):
You must ensure user creation is placed appropriately:
data_security: Global privileges; should be added before any other operations.
data_architect: Database-level privileges; should appear immediately after the CREATE DATABASE statement.
Other users (e.g., data entry, financial_officer, etc.): These are local and should be placed after all structural and data insertions.

If users.sql is used standalone without the hospital database present:
It becomes non-functional or misleading, since all user definitions (except data_security) are either tied to the hospital database or meant to work alongside specific objects (views, procedures, etc.).
- All SQL dump files included in this project were exported using phpMyAdmin, which ensures compatibility with standard MySQL/MariaDB environments. This includes table structures, stored routines, views, triggers, and events. If you're using a different client, ensure it supports executing full SQL scripts with definers, foreign keys, and events enabled.
- While the database is designed with practical hospital workflows in mind, certain mock data and structural assumptions are intentionally simplified or abstracted to showcase specific SQL functionalities. For example, the system assigns wages per case to doctors based on individual experience levels rather than medical operation complexity. This abstraction enables the use of a diverse set of SQL operations for learning and demonstration purposes.


