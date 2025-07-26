# Hospital Management SQL System
A fully relational MySQL database built to manage hospital operations, including patient admissions, staff salaries, service tracking, shift scheduling, financial reporting, and automated archival of medical cases.

## Entity-Relationship Overview

This database is designed around the lifecycle of patients, doctors, nurses, rooms, and services. It follows a normalized relational model with clear relationships and automated workflows through triggers, procedures, and events.

### Core Entities:
- **patients**: linked to doctors and rooms, with urgency level and case info
- **doctors**: track assigned cases and dynamic salaries
- **nurses**: have shift-related data and salary components (loan, allowance, etc.)
- **services**: medical services taken by patients, tracked monthly
- **past_cases**: archived patient cases after discharge
- **rooms**: track occupation status dynamically
- **monthly_income_statement**: logs monthly revenue, cost, and calculated income

### Relationships:
- One-to-many between **doctors → patients**
- One-to-one between **rooms → patients**
- Many-to-many between **patients ↔ services** via `patients_services`
- Archival of **patients → past_cases** handled by triggers

## Database Objectives

- Automate patient admission, room assignment, and doctor allocation
- Track nurse and doctor salaries, including incentives and deductions
- Manage and record patient services, both ongoing and archived
- Archive discharged patients into a separate past cases log
- Maintain live statistics and summaries through views
- Auto-generate financial reports using scheduled SQL events
- Support shift rotation and team salary calculation

## Core Tables and Relationships

### patients
- Tracks ongoing cases with doctor, room, urgency level, and personal info
- Linked to `doctors`, `rooms`, and `patients_services`
- Auto-archived into `past_cases` upon discharge

### doctors
- Stores doctor info, specialization, and assigned case count
- Salary updated per case via triggers and monthly event

### nurses
- Contains shift, salary, and incentive data
- Supports rotation logic and monthly salary recalculation

### rooms
- Each room can be occupied by one patient
- Auto-updated when patients are admitted or discharged

### services
- Lists available medical services with cost and usage tracking
- Linked to patients via `patients_services`

### patients_services
- Junction table for many-to-many between patients and services
- Auto-managed to update service usage counts

### past_cases
- Archives discharged patients with total payment and summary
- Populated partially via trigger, then completed by procedure

### monthly_income_statement
- Records total revenue, cost, and calculated income per month

### monthly_expenses
- Stores categorized cost data like salaries, team incentives, etc.

## Triggers

### AFTER INSERT ON patients
- Marks assigned room as occupied
- Updates doctor’s assigned case count
- Records initial urgency-level service
- Updates `last_assigned_doctor` to ensure fair case distribution

### BEFORE DELETE ON patients
- Archives patient data into `past_cases`
- Calculates total payment (urgency-based and service-based)
- Updates room occupation and doctor salary
- Updates service usage count based on days spent

### AFTER INSERT ON patients_services
- Increases monthly usage count in `services` table
- Excludes urgency-level services (handled separately)

## Stored Procedures

### doctor_treated_cases
- Returns current and archived cases for a doctor
- Combines multiple sources using `UNION`

### month_inc_stat_word_count
- Counts word occurrences in monthly cost descriptions
- Useful for keyword-based financial filtering

### nurses_payroll_factors_set
- Applies monthly updates to nurses’ salary-related fields
- Valid only until the 26th of each month

### nurses_shift
- Rotates nurses’ identities (name, contact, allowance, loan) for monthly shift cycling
- Triggered on the 1st of each month

### patient_insert
- Handles patient admission logic
- Selects next available room and doctor
- Inserts a new patient record with assigned resources

### patient_removal
- Deletes a patient and updates their archived record in `past_cases`
- Completes missing details like prescription and revision date

### teams_incentives
- Updates outsourced teams’ monthly costs based on provided incentives
- Locked until the 27th of each month

## Events

### nurses_shift_pro_call
- Runs on the 1st of each month
- calls nurse shift rotation using `nurses_shift` procedure

### creating_nurses_salaries
- Calculates each nurse’s salary at the end of the month
- Applies loan and allowance deductions (partial or full)
- Resets deduction and incentive fields after use

### calculate_doctors_nurses_expenses
- Executes on the last day of each month
- Aggregates total doctor and nurse salaries into `monthly_expenses`
- Resets salary fields in both tables

### income_statement_calculate
- runs on the first day of each month
- Inserts monthly income, cost, and revenue summaries into `monthly_income_statement`
- Resets `monthly_expenses` and `services` usage for the next cycle

## Views

### active_doctors
- Lists doctors currently assigned to at least one patient
- Joins doctor info with their patients and cases

### cases_status_analysis
- Combines current and past cases grouped by urgency level
- Useful for tracking patient distribution trends

### monthly_yearly_income_statement_report
- Shows monthly cumulative revenue, cost, and income
- Includes yearly and total financial summaries for comparison

## Column Conventions

- **income** (in `monthly_income_statement`) is a **STORED GENERATED** column  
  → Automatically calculated as `revenue - cost`

- **revision_date** and **prescription** (in `past_cases`)  
  → Accept `NULL` initially; filled later during patient removal

- **assigned_cases**, **current_monthly_salary**, **times_per_month**, **last_assigned_doctor**
  → System-managed fields updated via triggers and events — don’t modify directly

## User Roles & Permissions

### executive
- Has read access to some tables, views, statistics, and financial summaries

### data_entry
- Can execute patient records (admissions & discharges) via procedures
- Triggers will handle all related changes automatically

### financial_officer
- Can read `monthly_expenses`, `monthly_income_statement`, and execute nurses_payroll_factors_setroutines, teams_incentives procedures

### data_architect
- Full access to the database (except for administration)
- Responsible for maintaining logic and performance

### data_security
- Monitors user activity and role assignments
- Can grant/revoke roles and audit access logs

> All core logic (procedures, triggers, events, and views) is created by the data_architect.  
> Therefore, system processes execute under his privileges, requiring the data_architect to have full access to the entire database — not just the logic layer.
> Note on User Creation Order:  
> Users with full or global access to the data (like the data_architect) should be created **before** the database, espicially if he is the definer (which is the case) as his privileges may be embedded in logic definitions.
> Other users with local access should be created **after** the database is fully built, as they will be created with mentioning names of their specific logics and/or tables they will access

## License & Usage

This project is licensed for personal, academic, and educational use only.

-  Free to use for learning, research, and reference
-  Not permitted for commercial or production use without permission
-  Attribution is required when sharing or presenting any part of the project
-  For commercial licensing (e.g., hospitals, businesses, or commercial apps), please contact the author directly: ibrahimsherif.virtualnomadic@gmail.com

This project is provided as-is without warranty.  
If you're interested in using it in a real-world or business setting, the author offers review, customization, and support based on your needs.

For commercial licensing, contact me at: ibrahimsherif.virtualnomadic@gmail.com

## Final Notes

- The users.sql file is not standalone and should only be used in the following cases:
Do not use if importing the full database — users are already created inside.
If importing parts manually, insert users where appropriate (e.g., data_security at the top, data_architect after DB creation, others at the end).
Avoid using this file alone without importing the main database — it won’t work correctly, as most users are tied to the hospital database.
- All data logic is self-managed through SQL triggers, procedures, and events — no manual recalculation required
- Urgency_level services are treated differently to ensure billing accuracy per day
- Monthly financials are auto-archived, and usage counters are reset without external input
- Manual inserts or deletions are allowed but should respect existing logic chains
- This README gives a summarized guide — refer to the full documentation for detailed logic, edge cases, and reasoning
- Some mock data used in this system does not reflect real-world hospital operations. For instance, doctors have varying wages per case based on experience, not necessarily by operation type, These variations are designed intentionally to demonstrate a range of SQL processes and logic capabilities.
- The SQL files provided were exported via phpMyAdmin and can be imported directly into your MySQL environment.
- Data Integrity Notice
Most dynamic data is handled automatically via triggers, events, and procedures. Manual direct changes to tables may break key flows, result in missing data, overwrite automated logic, or prevent triggers from firing correctly. User roles and privileges have been narrowed deliberately to help preserve data consistency and flow.





