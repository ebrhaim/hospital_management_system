DELIMITER $$
CREATE DEFINER=`data_architect`@`%` PROCEDURE `doctor_treated_cases`(IN `doctor_id_param` TINYINT(2))
    READS SQL DATA
begin
-- =============================================================
-- Logic Type: Procedure
-- Name: doctor_treated_cases
-- Purpose: Retrieve a combined list of ongoing cases, archived cases, 
--          and a total count of archived cases for a given doctor.
-- Input: doctor_id_param (INT) – the ID of the doctor in question.
-- Output: A UNIONed result set with labeled rows:
--         - ongoing cases with patient + case names,
--         - archived cases with patient names,
--         - total count of archived cases.
-- =============================================================

SELECT 'ongoing cases' AS Type, 
       CONCAT(name, "_", case_name) AS "patient & case name"
    FROM patients 
    WHERE doctor_id = doctor_id_param -- fetches active cases linked to the doctor

UNION

SELECT 'archieved cases', name
    FROM past_cases
    WHERE doctor_id = doctor_id_param -- archived case names for the same doctor

UNION

SELECT 'total archieved cases', COUNT(doctor_id)
    FROM past_cases
    WHERE doctor_id = doctor_id_param; -- total number of archived cases for summary
end$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`data_architect`@`%` PROCEDURE `month_inc_stat_word_count`(IN `word_param` VARCHAR(50), IN `year_param` SMALLINT(4))
    READS SQL DATA
    DETERMINISTIC
begin
-- =============================================================
-- Logic Type: Procedure
-- Name: month_inc_stat_word_count
-- Purpose: Count how many times a specific word appears in the 'cost_details'
--          field for each month in a given year, and then calculate the total.
-- Input:
--     - word_param (VARCHAR): the word to search for.
--     - year_param (INT): the year to filter records by.
-- Output:
--     - Monthly rows with counts of word occurrences per row (if > 0).
--     - A final row labeled "SUM" that totals all occurrences.
-- Notes:
--     - Uses CTE for cleaner structuring.
--     - Uses regex with word boundaries to ensure accurate word matches.
-- =============================================================

with word_cte as (
    SELECT
        month,
        -- Count word occurrences by checking length difference after replacement
        (LENGTH(cost_details) - LENGTH(REGEXP_REPLACE(cost_details, CONCAT('\\b', word_param, '\\b'), ''))) / LENGTH(word_param) AS word_count_per_row 
    FROM 
        monthly_income_statement
        WHERE EXTRACT(YEAR FROM month) = year_param 
)

-- Select rows where the word appears at least once
(SELECT * FROM word_cte
 WHERE word_count_per_row > 0
    ORDER BY month)
UNION ALL

-- Append a summary row with the total count of word occurrences
SELECT
	"SUM",
    SUM(word_count_per_row)
FROM 
    word_cte;
end$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`data_architect`@`%` PROCEDURE `nurses_payroll_factors_set`(IN `incentive_param` DECIMAL(5,2), IN `id_incentive_param` VARCHAR(250), IN `deduction_percentage_param` DECIMAL(5,2), IN `id_deduction_param` VARCHAR(250), IN `id_loan_param` VARCHAR(250), IN `loan_param` VARCHAR(5000), IN `id_allowance_param` VARCHAR(250), IN `allowance_param` VARCHAR(5000))
    MODIFIES SQL DATA
BEGIN

-- =============================================================
-- Logic Type: Procedure
-- Name: nurses_payroll_factors_set
-- Purpose:
--     Conditionally update multiple financial fields (incentive, deduction, 
--     loan, allowance) in the nurses table — with enforcement of a monthly cutoff.
-- 
-- Input Parameters:
--     - id_incentive_param (CSV or "all"): nurse IDs to receive incentives
--     - incentive_param (DECIMAL): incentive amount to assign (bulk value for all matching IDs through id_incentive_param)
--     - id_deduction_param (CSV or "all"): nurse IDs to apply deductions to
--     - deduction_percentage_param (DECIMAL): percentage to calculate deduction from 3000 (bulk value for all matching IDs through id_deduction_param)
--     - id_loan_param (CSV): nurse IDs receiving loan values
--     - loan_param (CSV of loan values): must be in the same order as id_loan_param
--     - id_allowance_param (CSV): nurse IDs receiving allowance values
--     - allowance_param (CSV of allowance values): must match order of id_allowance_param
--
-- Output: None (UPDATE only)
--
-- Side Effects:
--     - Fails with an error if executed after the 26th day of the month
--
-- Notes:
--     - Uses FIND_IN_SET to match nurse IDs from CSV strings.
--     - Uses SUBSTRING_INDEX for mapping values by position.
--     - Very sensitive to order and formatting of CSV inputs.
--     - Incentives and deductions are applied as a single value to all matching IDs.
--     - Loans and allowances are applied as individual values per ID based on position.
--     - To leave any field unchanged for a given ID, leave its corresponding value blank.
-- =============================================================

    -- Prevent updates after the 26th of the month
    IF DAY(CURRENT_DATE) > 26 THEN 
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Update on nurses table cannot be executed after the 26th of the month';
    END IF;

    -- Update nurses financials based on provided CSV parameters
    UPDATE nurses 
    SET 
        -- Set incentive if nurse(s) is in the list or if 'all' is specified
        incentive = CASE 
            WHEN FIND_IN_SET(id, id_incentive_param) OR id_incentive_param = "all" 
                THEN incentive_param
            ELSE incentive
        END,

        -- Set deduction if nurse(s) is in the list or if 'all' is specified as 3000 * given percentage
        deduction = CASE 
            WHEN FIND_IN_SET(id, id_deduction_param) OR id_deduction_param = "all" 
                THEN 3000 * (deduction_percentage_param / 100)
            ELSE deduction
        END,
     
        -- Set loan based on position-matched value from CSV
        loan = CASE 
            WHEN FIND_IN_SET(id, id_loan_param) 
                THEN SUBSTRING_INDEX(SUBSTRING_INDEX(loan_param, ',', FIND_IN_SET(id, id_loan_param)), ',', -1)
            ELSE loan
        END,

        -- Set allowance using same method as loan (position-matched from CSV)
        allowance = CASE 
            WHEN FIND_IN_SET(id, id_allowance_param) 
                THEN SUBSTRING_INDEX(SUBSTRING_INDEX(allowance_param, ',', FIND_IN_SET(id, id_allowance_param)), ',', -1)
            ELSE allowance
        END

    -- Update only nurses affected by at least one of the parameters 
    -- this ensures updating relevant records without causing "CASE" to search the entire rows
    -- also to avoid making the unmentioned rows = NULL or blank
    WHERE
        FIND_IN_SET(id, id_incentive_param) 
        OR id_incentive_param = "all"  
        OR FIND_IN_SET(id, id_deduction_param)
        OR id_deduction_param = "all"
        OR FIND_IN_SET(id, id_loan_param)
        OR FIND_IN_SET(id, id_allowance_param);
END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`data_architect`@`%` PROCEDURE `nurses_shift`()
    MODIFIES SQL DATA
BEGIN

-- =============================================================
-- Logic Type: Procedure
-- Name: nurses_shift 
-- Purpose:
--     Rotate key nurse-specific fields (name, phone, address, allowance, loan)
--     across shift rows, creating a "monthly rotation" effect while leaving.
--     fixed shift assignments (id, floor, half, shift) untouched
--     so that the each nurse-specific field moves to the next fixed shift assignment.
--
-- Trigger Point:
--     Automatically executes on the 1st of each month using nurses_shift_pro_call Event (not included as an Event because Events don't accept variables)
--
-- Fields updated:
--     name, phone, address, allowance, loan
--
-- Fixed fields (not rotated):
--     id, floor, half, shift (these remain unchanged) salary, incentive, deduction
--     (intentionally excluded since reset monthly so no need to rotate as they are set to 0).
--
-- Logic:
--     - Save the last row’s data temporarily.
--     - Shift all other rows “down” by 1 using self-join.
--     - Assign saved last-row data to the first row to complete the rotation loop
--       as rotation is circular, means last nurse loops to first nurse

--
-- Assumptions:
--     - Nurse IDs are sequential and ordered (e.g., 1, 2, 3, ...)
--     - before the start of the month, financial fields like salary, incentive, and deduction are reset to 0.
-- =============================================================

-- Declare variables to hold the data of the last nurse
DECLARE name_var VARCHAR(50);
DECLARE phone_var VARCHAR(30);
DECLARE address_var VARCHAR(50);
DECLARE allowance_var DECIMAL(8,2);
DECLARE loan_var DECIMAL(8,2);

-- Step 1: Capture last nurse's personal data (to wrap it around to the top row)
SELECT 
    name, phone, address, allowance, loan  
INTO 
    name_var, phone_var, address_var, allowance_var, loan_var
FROM nurses 
ORDER BY id DESC 
LIMIT 1;

-- Step 2: Shift each nurse’s data to the next row by joining on id-1
UPDATE nurses t1 
JOIN nurses t2 ON t2.id = t1.id - 1
SET 
    t1.name = t2.name,
    t1.phone = t2.phone,
    t1.address = t2.address,
    t1.allowance = t2.allowance,  
    t1.loan = t2.loan
WHERE t1.id > 1;

-- Step 3: Assign the original last nurse's data to the first row (id = 1)
UPDATE nurses 
SET 
    name = name_var,
    phone = phone_var,
    address = address_var, 
    allowance = allowance_var,
    loan = loan_var
WHERE id = 1;

END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`data_architect`@`%` PROCEDURE `patient_insert`(IN `name_param` VARCHAR(50), IN `case_name_param` VARCHAR(50), IN `urgency_level_param` ENUM('low','moderate','high'), IN `leave_date_param` DATE, IN `phone_param` VARCHAR(30), IN `address_param` VARCHAR(50))
    MODIFIES SQL DATA
BEGIN
-- =============================================================
-- Logic Type: Procedure
-- Name: patient_insert 
-- Purpose:
--     Automatically admit a new patient by:
--     - Finding an available room
--     - Assigning a doctor (max 2 cases allowed)
--     - Generating a unique patient ID
--     - Inserting the patient record into the system
--
-- Input Parameters:
--     - name_param (VARCHAR)
--     - case_name_param (VARCHAR)
--     - urgency_level_param (ENUM) ('low', 'medium', 'high')
--     - leave_date_param (DATE) could be left blank
--     - phone_param (VARCHAR)
--     - address_param (VARCHAR)
--
-- Output: None (INSERT operation in patients table), fires AFTER INSERT trigger
--
-- Preconditions:
--     - At least one room must be unoccupied
--     - At least one doctor must have fewer than 2 active cases
--
-- Logic Highlights:
--     - If no room is available → raise error
--     - If all doctors are maxed out → raise error
--     - Patient ID is auto-calculated by finding the next available ID (handles gaps)
--     - Doctor assignment rotates based on a helper table (last_assigned_doctor)
--
-- Side Effects:
--     - Updates the patients table
--     - Fires AFTER INSERT after_patient_insert trigger on patients
--         → Updates room occupation
--         → Logs patient services
--         → Increments doctor assigned cases
--         → Updates last_assigned_doctor singletone table
-- Notes:
--     - Efficiently handles edge cases using COALESCE + fallbacks
--     - Assumes `last_assigned_doctor` contains only one row at most as a singleton table
-- =============================================================

-- Declare local variables for generated values
DECLARE patient_id_var, doctor_id_var, room_id_var tinyint;

    -- Step 1: Check if all rooms are occupied
IF (SELECT COUNT(*) FROM rooms WHERE occupation = 'no') = 0 THEN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'All rooms are occupied';

-- Step 2: Check if all doctors are fully booked (2 cases each)
ELSEIF (SELECT COUNT(*) FROM doctors WHERE assigned_cases < 2) = 0 THEN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'All doctors are handling 2 cases';
END IF;

-- Step 3: Determine next available patient ID
SET patient_id_var = COALESCE(
    (SELECT 1 WHERE 1 NOT IN (SELECT id FROM patients)), -- start at 1 if not taken
    (SELECT id + 1 
     FROM patients 
     WHERE id + 1 NOT IN (SELECT id FROM patients) 
     ORDER BY id 
     LIMIT 1) -- else find first missing ID (handles gaps)
);

-- Step 4: Assign doctor
SET doctor_id_var = COALESCE(
    (SELECT 1 FROM last_assigned_doctor HAVING COUNT(*) = 0), -- fallback if singleton table is empty
    (SELECT id 
     FROM doctors 
     WHERE assigned_cases < 2 
     AND id > (SELECT doctor_id FROM last_assigned_doctor)
     ORDER BY id 
     LIMIT 1), -- find next doctor after last assigned one in singleton table 
    (SELECT id 
     FROM doctors 
     WHERE assigned_cases < 2 
     ORDER BY id 
     LIMIT 1) -- fallback to first available doctor
);

-- Step 5: Assign first available room
SET room_id_var = (
    SELECT id 
    FROM rooms
    WHERE occupation = 'no'
    LIMIT 1
);

-- Step 6: Insert new patient with auto-calculated IDs and input parameters
INSERT INTO patients (
    id, name, case_name, doctor_id, room_id, 
    urgency_level, leave_date, phone, address
) 
VALUES (
    patient_id_var, name_param, case_name_param, doctor_id_var, 
    room_id_var, urgency_level_param, leave_date_param, phone_param, address_param
);

END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`data_architect`@`%` PROCEDURE `patient_removal`(IN `patient_id_param` TINYINT(3), IN `prescription_param` TEXT, IN `revision_date_param` DATE)
    MODIFIES SQL DATA
BEGIN
-- =============================================================
-- Logic Type: Procedure
-- Name: patient_removal
-- Purpose:
--     Handles safe removal of a patient from the active system:
--     - Deletes the patient from patients table.
--     - Relies on a BEFORE DELETE before_patient_delete trigger to archive patient details to past_cases.
--     - Completes archival by updating final fields using input parameters.
-- 
-- Input Parameters:
--     - patient_id_param (INT): ID of the patient to remove
--     - revision_date_param (DATE): Date of post-discharge revision or check-up
--     - prescription_param (TEXT): Final prescribed treatment plan
-- 
-- Notes:
--     - This procedure assumes that past_cases receives initial patient data 
--       from the trigger, and that this procedure provides the remaining fields
--       so it Uses UPDATE on the latest row in past_cases,
--     - revision_date and prescription are allowed to be NULL initially
--       This is intentional, as the BEFORE DELETE trigger inserts the row
--       with partial data, and this procedure completes it.
--       which is supposed to be the latsed added row from the trigger (based on `MAX(id)`).
--     - the trigger further audit/logging actions (see trigger definition)
--       based on patient removal for payment records, doctor, and room vacancy.
--     - deleting a patient will delete all it's corresponding data from `patients_services` table as an on-delete cascade action
-- =============================================================

    -- Step 1: Delete the patient
    DELETE FROM patients
    WHERE id = patient_id_param;

    -- Step 2: Finalize the past_cases record with extra details 
    -- after a BEFORE DELETE trigger inserts a new row with the initial fields in past_cases
    UPDATE past_cases
    SET 
        revision_date = revision_date_param,
        prescription = prescription_param
    WHERE id = (SELECT MAX(id) FROM past_cases); -- update the most recent inserted archive row

END$$
DELIMITER ;

DELIMITER $$
CREATE DEFINER=`data_architect`@`%` PROCEDURE `teams_incentives`(IN `Emergency_incentives_param` DECIMAL(6,2), IN `Environmental_incentives_param` DECIMAL(6,2), IN `security_incentives_param` DECIMAL(6,2))
BEGIN 
-- =============================================================
-- Logic Type: Procedure
-- Name: teams_incentives
-- Purpose:
--     Updates the calculated salary cost for outsourced teams in the `monthly_expenses` table.
--     This procedure factors in base salaries plus monthly incentive inputs for each team.
--     Execution is restricted to the last few days of the month (27th and onward).
-- 
-- Input Parameters:
--     - Emergency_incentives_param (DECIMAL): incentive amount per EMS employee
--     - Environmental_incentives_param (DECIMAL): incentive amount per environmental staff
--     - security_incentives_param (DECIMAL): incentive amount per security guard
-- 
-- Output: None (UPDATE operation)
-- 
-- Execution Constraint:
--     - Can only be executed on or after the 27th day of the month
--     - Will throw an error if run before the 27th
-- 
-- Notes:
--     - Base salaries are:
--           Emergency Medical Services team → 2500 × 10 employees
--           Environmental Services team → 2000 × 22 employees
--           Security team → 1200 × 8 employees
--     - If no incentives are available for a team, pass 0 as the corresponding parameter
-- =============================================================

    -- Block early execution: teams salaries can only be set from the 27th onward
    IF DAY(CURRENT_DATE) < 27 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'setting salaries of teams is not allowed before the 27th of the month';
    END IF;

    -- Update team costs based on their base salaries and incentive parameters
    UPDATE monthly_expenses
    SET cost = CASE 
        WHEN name = "Emergency Medical Services team" 
            THEN (2500 + Emergency_incentives_param) * 10 -- 10 EMS workers
        WHEN name = "Environmental Services team" 
            THEN (2000 + Environmental_incentives_param) * 22 -- 22 environmental staff
        WHEN name = "security team" 
            THEN (1200 + security_incentives_param) * 8 -- 8 security personnel
    END
    WHERE name IN (
        "Emergency Medical Services team", 
        "Environmental Services team", 
        "security team"
    );

END$$
DELIMITER ;
