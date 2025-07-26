DELIMITER $$
CREATE DEFINER=`data_architect`@`%` EVENT `calculate_doctors_nurses_expenses` ON SCHEDULE EVERY 1 DAY STARTS '2025-02-28 09:00:00' ON COMPLETION PRESERVE ENABLE DO BEGIN
-- =============================================================
-- Event Type: Scheduled (Daily Execution)
-- Name: calculate_doctors_nurses_expenses
-- Purpose:
--     - On the last day of each month:
--         • Record the current total salaries of doctors and nurses
--           into the `monthly_expenses` table
--         • Reset doctors' `current_monthly_salary` and nurses' `salary` to 0
--
-- Execution Time: Daily (checked that it runs only on the last day of the month)
-- it runs before income_statement_calculate event is executed
-- and after creating_nurses_salraies event is executed
-- =============================================================

    -- Only run on the last day of the month
    IF CURRENT_DATE = LAST_DAY(CURRENT_DATE) THEN

        -- Step 1: Store final salary totals in the `monthly_expenses` table
        UPDATE monthly_expenses
        SET cost = CASE 
            WHEN name = "doctors salaries" THEN (
                SELECT SUM(current_monthly_salary) FROM doctors
            )
            WHEN name = "nurses salaries" THEN (
                SELECT SUM(salary) FROM nurses
            )
            ELSE cost -- fallback for safety: leave other rows unchanged
        END
        WHERE name IN ("doctors salaries", "nurses salaries");

        -- Step 2: Reset doctors' current_monthly_salary to 0
        UPDATE doctors
        SET current_monthly_salary = 0;

        -- Step 3: Reset nurses' salary to 0
        UPDATE nurses
        SET salary = 0;

    END IF;

END $$
DELIMITER ;

DELIMITER $$

CREATE DEFINER=`data_architect`@`%` EVENT `creating_nurses_salraies` ON SCHEDULE EVERY 1 MONTH STARTS '2025-02-27 03:00:00' ON COMPLETION PRESERVE ENABLE DO BEGIN
-- =============================================================
-- Event Type: Scheduled (on the 27th of each month)
-- Name: creating_nurses_salaries
-- Purpose:
--     - Calculate nurses' net salary using a formula that:
--         • Adds base + incentive + partial allowance
--         • Subtracts deduction + partial loan
--         • Resets incentive and deduction to 0
--         • Updates allowance and loan by subtracting what was consumed this month
--
-- Execution Logic:
--     - Executed before the `calculate_doctors_nurses_expenses` event
--     - Designed to reflect actual earned and dedusubd amounts before end-of-month aggregation
--
-- Salary Calculation Details:
--     - Base salary: 3000 (fixed)
--     - Incentive: added fully to salary; then reset to 0
--     - Deduction: subtrasubd fully from salary; then reset to 0
--     - Allowance: 
--         • If > 500, subtract 10% from allowance and add it to salary
--         • If ≤ 500, subtract full amount from allowance and add it to salary
--     - Loan:
--         • If > 500, subtract 10% from loan and deduct it from salary
--         • If ≤ 500, subtract full amount from loan and deduct it from salary
--
-- =============================================================

    -- Update nurse salaries based on incentive, deduction, loan, and allowance policies
    UPDATE nurses
    JOIN (
        -- Inline subquery calculates how much of loan/allowance is to be used
        SELECT 
            id AS id_sub,

            -- If loan > 500, take 10% of it for deduction; else take full loan
            CASE 
                WHEN loan > 500 THEN loan * 0.10
                ELSE loan
            END AS loan_sub,

            -- If allowance > 500, take 10% of it for salary bonus; else take full allowance
            CASE 
                WHEN allowance > 500 THEN allowance * 0.10
                ELSE allowance
            END AS allowance_sub

        FROM nurses
    ) AS sub ON nurses.id = sub.id_sub

    -- Calculate salary using:
    -- Base (3000) + incentive + portion of allowance - deduction - portion of loan
    SET 
        salary = 3000 + incentive + sub.allowance_sub - deduction - sub.loan_sub,

        -- Remove used incentive and deduction entirely
        incentive = 0,
        deduction = 0,

        -- Subtract consumed portion of allowance and loan
        allowance = allowance - sub.allowance_sub,
        loan = loan - sub.loan_sub;

END $$
DELIMITER ;

DELIMITER $$

CREATE DEFINER=`data_architect`@`%` EVENT `income_statement_calculate` ON SCHEDULE EVERY 1 MONTH STARTS '2025-02-01 07:00:00' ON COMPLETION PRESERVE ENABLE DO BEGIN
-- =============================================================
-- Event Type: Scheduled (Monthly Execution)
-- Name: income_statement_calculate
-- Purpose:
--     - On the first day of each month, generate a complete income statement
--       for the previous month and archive it in `monthly_income_statement`.
--     - Summarizes all expenses and revenues in text format for reporting.
--     - Resets monthly financial counters in:
--         • `monthly_expenses` → cost = 0
--         • `services` → times_per_month = 0
--
-- Data Sources:
--     • Revenue: `past_cases.payment` for all discharges in the previous month
--     • Cost: total from `monthly_expenses`
--     • Revenue Details: based on (service cost × usage count)
--     • Cost Details: itemized cost per entry from `monthly_expenses`
--
-- Notes:
--     - Text fields `cost_details` and `revenue_details` provide a breakdown.
--     - If no expenses exist, fallback message is provided.
--     - All counters reset immediately after archiving.
--     - Executed on the 1st day of each month (ideally scheduled early morning).
-- =============================================================

    -- Insert the previous month’s financial summary into monthly_income_statement
    INSERT INTO monthly_income_statement (
        cost_details,
        revenue_details,
        revenue,
        cost,
        month
   -- income is a STORED GENERATED column, automatically calculated as (revenue - cost)
    )
    VALUES (
        -- Itemized cost entries > 0 or fallback message
        COALESCE((
            SELECT GROUP_CONCAT(name, ': ', cost SEPARATOR '\n')
            FROM monthly_expenses
            WHERE cost > 0
        ), 'no expenses for the last month!'),

        -- Itemized revenue from services > 0 (cost × usage count)
        (
            SELECT GROUP_CONCAT(name, ': ', cost * times_per_month SEPARATOR '\n')
            FROM services
            WHERE times_per_month > 0
        ),

        -- Total revenue from payments made by discharged patients
        -- Revenue should be equal to SUM(cost * times_per_month) from services
        (
            SELECT SUM(payment)
            FROM past_cases
            WHERE EXTRACT(YEAR_MONTH FROM CURRENT_DATE) = EXTRACT(YEAR_MONTH FROM leave_date)
        ),

        -- Total cost from monthly_expenses
        (
            SELECT SUM(cost)
            FROM monthly_expenses
        ),

        -- Use yesterday’s date to represent the "month" being reported
        DATE_SUB(CURRENT_DATE, INTERVAL 1 DAY)
    );

    -- Reset all expenses costs for next month
    UPDATE monthly_expenses
    SET cost = 0;

    -- Reset service usage counts for next month
    UPDATE services
    SET times_per_month = 0;

END$$
DELIMITER ;

DELIMITER $$

CREATE DEFINER=`data_architect`@`%` EVENT `nurses_shift_pro_call` ON SCHEDULE EVERY 1 MONTH STARTS '2025-03-01 00:00:00' ON COMPLETION PRESERVE ENABLE DO BEGIN
-- =============================================================
-- Event Type: Scheduled (Monthly Execution)
-- Name: nurses_shift_pro_call
-- Purpose:
--     - Automatically rotate nurses' shift-related data on the 1st day of each month
--     - Calls the procedure `nurses_shift()` to shift nurse-specific details
--       (name, phone, address, loan, allowance) down to the next row (circular swap)
--
-- Execution Flow:
--     - Executes once per month on the 1st day Calls `nurses_shift()`
-- Note:
--     -  The logic is not included as an Event because Events do not accept variables.
-- =============================================================

    -- Trigger the nurse shift rotation logic
    CALL `nurses_shift`();

END $$
DELIMITER ;


-- data_entry user creation and privileges
GRANT USAGE ON *.* TO `data_entry`@`%` IDENTIFIED BY PASSWORD '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257';
GRANT INSERT ON `hospital`.`patients_services` TO `data_entry`@`%`;
GRANT EXECUTE ON PROCEDURE `hospital`.`patient_removal` TO `data_entry`@`%`;
GRANT EXECUTE ON PROCEDURE `hospital`.`patient_insert` TO `data_entry`@`%`;

-- executive user creation and privileges
GRANT USAGE ON *.* TO `executive`@`%` IDENTIFIED BY PASSWORD '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257';
GRANT SELECT ON `hospital`.`active_doctors` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`past_cases` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`monthly_income_statement` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`cases_status_analysis` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`monthly_expenses` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`monthly_yearly_income_statement_report` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`services` TO `executive`@`%`;

-- financial_officer user creation and privileges
GRANT USAGE ON *.* TO `financial_officer`@`%` IDENTIFIED BY PASSWORD '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257';
GRANT SELECT ON `hospital`.`monthly_expenses` TO `financial_officer`@`%`;
GRANT SELECT ON `hospital`.`monthly_income_statement` TO `financial_officer`@`%`;
GRANT EXECUTE ON PROCEDURE `hospital`.`teams_incentives` TO `financial_officer`@`%`;
GRANT EXECUTE ON PROCEDURE `hospital`.`nurses_payroll_factors_set` TO `financial_officer`@`%`;
