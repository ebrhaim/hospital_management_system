-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jul 21, 2025 at 02:16 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `hospital`
--
-- data_security user creation
GRANT RELOAD, SHUTDOWN, PROCESS, REFERENCES, SHOW DATABASES, SUPER, LOCK TABLES, REPLICATION SLAVE, REPLICATION CLIENT, CREATE USER ON *.* TO `data_security`@`%` IDENTIFIED BY PASSWORD '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257' WITH GRANT OPTION;

CREATE DATABASE IF NOT EXISTS `hospital` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `hospital`;

-- data_architect user creation
GRANT USAGE ON *.* TO `data_architect`@`%` IDENTIFIED BY PASSWORD '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, EXECUTE, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EVENT, TRIGGER ON `hospital`.* TO `data_architect`@`%`;


DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`data_architect`@`%` PROCEDURE `doctor_treated_cases` (IN `doctor_id_param` TINYINT(2))  READS SQL DATA begin
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

CREATE DEFINER=`data_architect`@`%` PROCEDURE `month_inc_stat_word_count` (IN `word_param` VARCHAR(50), IN `year_param` SMALLINT(4))  DETERMINISTIC READS SQL DATA begin
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

CREATE DEFINER=`data_architect`@`%` PROCEDURE `nurses_payroll_factors_set` (IN `incentive_param` DECIMAL(5,2), IN `id_incentive_param` VARCHAR(250), IN `deduction_percentage_param` DECIMAL(5,2), IN `id_deduction_param` VARCHAR(250), IN `id_loan_param` VARCHAR(250), IN `loan_param` VARCHAR(5000), IN `id_allowance_param` VARCHAR(250), IN `allowance_param` VARCHAR(5000))  MODIFIES SQL DATA BEGIN

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

CREATE DEFINER=`data_architect`@`%` PROCEDURE `nurses_shift` ()  MODIFIES SQL DATA BEGIN

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

CREATE DEFINER=`data_architect`@`%` PROCEDURE `patient_insert` (IN `name_param` VARCHAR(50), IN `case_name_param` VARCHAR(50), IN `urgency_level_param` ENUM('low','moderate','high'), IN `leave_date_param` DATE, IN `phone_param` VARCHAR(30), IN `address_param` VARCHAR(50))  MODIFIES SQL DATA BEGIN
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

CREATE DEFINER=`data_architect`@`%` PROCEDURE `patient_removal` (IN `patient_id_param` TINYINT(3), IN `prescription_param` TEXT, IN `revision_date_param` DATE)  MODIFIES SQL DATA BEGIN
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

CREATE DEFINER=`data_architect`@`%` PROCEDURE `teams_incentives` (IN `Emergency_incentives_param` DECIMAL(6,2), IN `Environmental_incentives_param` DECIMAL(6,2), IN `security_incentives_param` DECIMAL(6,2))   BEGIN 
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

-- --------------------------------------------------------

--
-- Stand-in structure for view `active_doctors`
-- (See below for the actual view)
--
CREATE TABLE `active_doctors` (
`doctor_name` varchar(50)
,`specialization` varchar(50)
,`assigned_cases` tinyint(1)
,`patient_name` varchar(50)
,`patient_case` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `cases_status_analysis`
-- (See below for the actual view)
--
CREATE TABLE `cases_status_analysis` (
`type` longtext
,`total_urgency_level` varbinary(43)
);

-- --------------------------------------------------------

--
-- Table structure for table `doctors`
--

CREATE TABLE `doctors` (
  `id` tinyint(2) NOT NULL,
  `name` varchar(50) NOT NULL,
  `specialization` varchar(50) NOT NULL,
  `assigned_cases` tinyint(1) NOT NULL DEFAULT 0 COMMENT '2 at most',
  `address` varchar(50) NOT NULL,
  `phone` varchar(30) NOT NULL,
  `wage_per_case` decimal(8,2) NOT NULL,
  `current_monthly_salary` decimal(8,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `doctors`
--

INSERT INTO `doctors` (`id`, `name`, `specialization`, `assigned_cases`, `address`, `phone`, `wage_per_case`, `current_monthly_salary`) VALUES
(1, 'Sarah Johnson', 'Cardiologist', 0, '123 Heart St, Cityville', '0123456789', 820.25, 0.00),
(2, 'Michael Smith', 'Pediatrician', 0, '456 Elm St, Townland', '0987654321', 198.50, 0.00),
(3, 'Emily Davis', 'Neurologist', 0, '789 Maple Ave, Urbantown', '0111223344', 243.30, 0.00),
(4, 'Daniel Brown', 'Orthopedist', 0, '321 Oak St, Villagecity', '0334455667', 1250.36, 0.00),
(5, 'Jessica Martinez', 'General Practitioner', 0, '654 Pine St, Cityville', '0445566778', 289.99, 0.00),
(6, 'David Wilson', 'Dermatologist', 0, '987 Cedar St, Townland', '0667788990', 401.20, 0.00),
(7, 'Jennifer Lee', 'Psychiatrist', 0, '159 Spruce St, Urbantown', '0778899001', 378.65, 0.00),
(8, 'Matthew Miller', 'Oncologist', 0, '753 Birch Rd, Villagecity', '0889900112', 459.80, 0.00),
(9, 'Elizabeth Taylor', 'Endocrinologist', 0, '951 Walnut St, Cityville', '0990011223', 512.55, 0.00),
(10, 'Samy Noha', 'Urologist', 0, '159 Alder Ave, Townland', '0213344556', 487.40, 0.00),
(11, 'Patricia Harris', 'Ophthalmologist', 0, '753 Redwood, Urbantown', '0324455667', 623.15, 0.00),
(12, 'Anthony Clark', 'Pulmonologist', 0, '123 Willow Blvd, Villagecity', '0435566778', 256.75, 0.00),
(13, 'Susan Allen', 'Rheumatologist', 0, '456 Cypress St, Cityville', '0546677889', 678.90, 0.00),
(14, 'Brian Hernandez', 'General Practitioner', 0, '789 Aspen Rd, Townland', '0657788990', 745.25, 0.00),
(15, 'Amanda King', 'Allergist', 0, '321 Beech St, Urbantown', '0768899001', 710.60, 0.00),
(16, 'Kevin Martinez', 'Gastroenterologist', 0, '654 Chestnut Ave, Villagecity', '0879900112', 832.45, 0.00),
(17, 'Michelle Walker', 'Hematologist', 0, '987 Elmwood, Cityville', '0980011223', 799.30, 0.00),
(18, 'Joshua Hall', 'Nephrologist', 0, '159 Pinewood St, Townland', '0111122233', 910.85, 0.00),
(19, 'Angela Young', 'Obstetrician', 0, '753 Cedarwood Blvd, Urbantown', '0223344455', 975.50, 0.00),
(20, 'Robert Scott', 'Surgeon', 0, '951 Maplewood Ave, Villagecity', '0334455566', 940.15, 0.00),
(21, 'Sarah Blake', 'Cardiologist', 0, '101 Heart Way, Medville', '0123405678', 550.50, 0.00),
(22, 'Michael Turner', 'Pediatrician', 0, '202 Child St, Kidstown', '0987654345', 1018.35, 0.00),
(23, 'Emily Roberts', 'Neurologist', 0, '303 Brain Ave, Neurocity', '0111234567', 1134.90, 0.00),
(24, 'Daniel Edwards', 'Orthopedist', 0, '404 Bone Rd, Jointville', '0334456789', 3636.00, 0.00),
(25, 'Jessica Adams', 'General Practitioner', 0, '505 Health St, Caretown', '0445567890', 1164.20, 0.00),
(26, 'David Cooper', 'Dermatologist', 0, '606 Skin Blvd, Smoothland', '0667789012', 1287.75, 0.00),
(27, 'Jennifer Moore', 'Psychiatrist', 0, '707 Mind St, Tranquility', '0778890123', 1253.40, 0.00),
(28, 'Matthew Lopez', 'Oncologist', 0, '808 Cancer Ln, Oncologyville', '0889901234', 1378.95, 0.00),
(29, 'Elizabeth Foster', 'Endocrinologist', 0, '909 Hormone St, Glandland', '0990012345', 1443.60, 0.00),
(30, 'Christopher Jenkins', 'Urologist', 0, '1010 Urinary Rd, Flowtown', '0213345678', 120.36, 0.00),
(31, 'Patricia Carter', 'Ophthalmologist', 0, '1111 Vision Blvd, Eyetown', '0324456789', 1532.80, 0.00),
(32, 'Anthony Bell', 'Pulmonologist', 0, '1212 Lung St, Breatherland', '0435567890', 1500.50, 0.00),
(33, 'Susan Wright', 'Rheumatologist', 0, '1313 Joint Rd, Arthritisville', '0546678901', 1623.00, 0.00),
(34, 'Brian Powell', 'General Practitioner', 0, '1414 Clinic Blvd, Healthtown', '0657789012', 1687.65, 0.00),
(35, 'Amanda Murphy', 'Allergist', 0, '1515 Allergy St, Respireville', '0768890123', 875.36, 0.00),
(36, 'Kevin Rivera', 'Gastroenterologist', 0, '1616 Digestive Rd, Gutland', '0879901234', 1776.85, 0.00),
(37, 'Michelle Simmons', 'Hematologist', 0, '1717 Blood Rd, Redcelltown', '0980012345', 1742.50, 0.00),
(38, 'Joshua Ward', 'Nephrologist', 0, '1818 Kidney Blvd, Uretown', '0111123456', 1867.05, 0.00),
(39, 'Angela Morgan', 'Obstetrician', 0, '1919 Baby St, Mothercity', '0223345678', 1931.70, 0.00),
(40, 'Robert Kelly', 'Surgeon', 0, '2020 Operation Rd, Scalpelville', '0334456789', 1896.35, 0.00),
(41, 'Liam Parker', 'Orthodontist', 0, '2121 Smile Rd, Toothville', '0456678901', 2020.90, 0.00),
(42, 'Olivia Mitchell', 'Cardiologist', 0, '2222 Pulse Ave, Heartland', '0567789012', 1986.55, 0.00),
(43, 'Noah Bennett', 'Pediatric Surgeon', 0, '2323 Kid Care Rd, Playtown', '0678890123', 1250.80, 0.00),
(44, 'Emma Scott', 'Dermatologist', 0, '2424 Glow St, Skinhaven', '0789901234', 2175.75, 0.00),
(45, 'James Hill', 'Psychiatrist', 0, '2525 Peace Blvd, Calmcity', '0890012345', 2140.40, 0.00),
(46, 'Charlotte Lewis', 'Allergist', 0, '2626 Breathe Ave, Respireville', '0901123456', 536.36, 0.00),
(47, 'Benjamin Howard', 'Pulmonologist', 0, '2727 Airway Rd, Windtown', '0112234567', 2230.60, 0.00),
(48, 'Sophia Clark', 'Ophthalmologist', 0, '2828 Vision Blvd, Sightland', '0223345678', 2355.15, 0.00),
(49, 'Elijah Young', 'Gastroenterologist', 0, '2929 Digest St, Stomachville', '0334456789', 2419.80, 0.00),
(50, 'Isabella Hall', 'Surgeon', 0, '3030 Scalpel Rd, Incisiontown', '0445567890', 925.00, 0.00);

-- --------------------------------------------------------

--
-- Table structure for table `floors`
--

CREATE TABLE `floors` (
  `id` tinyint(2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `floors`
--

INSERT INTO `floors` (`id`) VALUES
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(8),
(9),
(10);

-- --------------------------------------------------------

--
-- Table structure for table `last_assigned_doctor`
--

CREATE TABLE `last_assigned_doctor` (
  `doctor_id` tinyint(2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `monthly_expenses`
--

CREATE TABLE `monthly_expenses` (
  `name` varchar(50) NOT NULL,
  `cost` decimal(12,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `monthly_expenses`
--

INSERT INTO `monthly_expenses` (`name`, `cost`) VALUES
('advertising', 0.00),
('doctors salaries', 0.00),
('electricity', 0.00),
('Emergency Medical Services team', 0.00),
('Environmental Services team', 0.00),
('equipment_rental', 0.00),
('food_supplies', 0.00),
('insurance', 0.00),
('internet_services', 0.00),
('maintenance', 0.00),
('medical_supplies', 0.00),
('nurses salaries', 0.00),
('oxygen_supply', 0.00),
('pharmaceuticals', 0.00),
('research', 0.00),
('sanitation', 0.00),
('security team', 0.00),
('software_licenses', 0.00),
('staff_training', 0.00),
('transportation', 0.00),
('waste_disposal', 0.00),
('water_supply', 0.00);

-- --------------------------------------------------------

--
-- Table structure for table `monthly_income_statement`
--

CREATE TABLE `monthly_income_statement` (
  `cost_details` text NOT NULL,
  `revenue_details` text NOT NULL,
  `revenue` decimal(20,2) NOT NULL,
  `cost` decimal(20,2) NOT NULL,
  `income` decimal(20,2) GENERATED ALWAYS AS (`revenue` - `cost`) STORED COMMENT 'automatically calculated',
  `month` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `monthly_yearly_income_statement_report`
-- (See below for the actual view)
--
CREATE TABLE `monthly_yearly_income_statement_report` (
`month` varchar(10)
,`cumulative_revenue` decimal(42,2)
,`cumulative_cost` decimal(42,2)
,`cumulative_income` decimal(42,2)
);

-- --------------------------------------------------------

--
-- Table structure for table `nurses`
--

CREATE TABLE `nurses` (
  `id` tinyint(2) NOT NULL,
  `name` varchar(50) NOT NULL,
  `floor_id` tinyint(2) NOT NULL,
  `half` enum('first','second') NOT NULL,
  `shift` enum('morning','night') NOT NULL,
  `phone` varchar(30) NOT NULL,
  `address` varchar(50) NOT NULL,
  `salary` decimal(8,2) NOT NULL,
  `incentive` decimal(5,2) NOT NULL,
  `allowance` decimal(8,2) NOT NULL,
  `loan` decimal(8,2) NOT NULL,
  `deduction` decimal(5,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `nurses`
--

INSERT INTO `nurses` (`id`, `name`, `floor_id`, `half`, `shift`, `phone`, `address`, `salary`, `incentive`, `allowance`, `loan`, `deduction`) VALUES
(1, 'Liam Carter', 1, 'first', 'morning', '0123405678', '123 Elm St, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(2, 'Olivia Mitchell', 1, 'first', 'morning', '0987654321', '456 Oak St, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(3, 'Noah Bennett', 1, 'first', 'night', '0111234567', '789 Maple Ave, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(4, 'Emma Scott', 1, 'first', 'night', '0334456789', '321 Pine Rd, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(5, 'James Hill', 1, 'second', 'morning', '0445567890', '654 Cedar Blvd, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(6, 'Charlotte Lewis', 1, 'second', 'morning', '0667789012', '987 Birch St, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(7, 'Benjamin Howard', 1, 'second', 'night', '0778890123', '159 Spruce Ave, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(8, 'Sophia Clark', 1, 'second', 'night', '0889901234', '753 Redwood Blvd, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(9, 'Elijah Young', 2, 'first', 'morning', '0990012345', '951 Alder Rd, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(10, 'Isabella Hall', 2, 'first', 'morning', '0213345678', '123 Beech St, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(11, 'William Turner', 2, 'first', 'night', '0324456789', '456 Cypress Ave, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(12, 'Mia Wright', 2, 'first', 'night', '0435567890', '789 Aspen Blvd, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(13, 'Lucas Morgan', 2, 'second', 'morning', '0546678901', '321 Chestnut St, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(14, 'Amelia Brooks', 2, 'second', 'morning', '0657789012', '654 Willow Rd, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(15, 'Henry Rivera', 2, 'second', 'night', '0768890123', '987 Elmwood Ave, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(16, 'Evelyn Kelly', 2, 'second', 'night', '0879901234', '159 Pinewood Blvd, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(17, 'Alexander Ward', 3, 'first', 'morning', '0980012345', '753 Cedarwood Rd, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(18, 'Harper Walker', 3, 'first', 'morning', '0111123456', '951 Maplewood Blvd, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(19, 'Daniel Foster', 3, 'first', 'night', '0223345678', '123 Walnut St, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(20, 'Avery Murphy', 3, 'first', 'night', '0334456789', '456 Redwood Ave, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(21, 'Matthew Simmons', 3, 'second', 'morning', '0445567890', '789 Alder Rd, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(22, 'Ella Carter', 3, 'second', 'morning', '0667789012', '321 Beech Blvd, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(23, 'Jackson King', 3, 'second', 'night', '0778890123', '654 Cypress Rd, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(24, 'Scarlett Lopez', 3, 'second', 'night', '0889901234', '987 Aspen Ave, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(25, 'Sebastian Hill', 4, 'first', 'morning', '0990012345', '159 Chestnut Blvd, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(26, 'Victoria Evans', 4, 'first', 'morning', '0213345678', '753 Willow St, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(27, 'Owen Moore', 4, 'first', 'night', '0324456789', '951 Elmwood Blvd, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(28, 'Ella Brooks', 4, 'first', 'night', '0435567890', '123 Pinewood St, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(29, 'Mason Lewis', 4, 'second', 'morning', '0546678901', '456 Cedarwood Ave, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(30, 'Sofia Rivera', 4, 'second', 'morning', '0657789012', '789 Maplewood Blvd, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(31, 'Ethan Powell', 4, 'second', 'night', '0768890123', '321 Walnut Rd, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(32, 'Grace Jenkins', 4, 'second', 'night', '0879901234', '654 Redwood Blvd, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(33, 'Henry Bell', 5, 'first', 'morning', '0980012345', '987 Alder Ave, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(34, 'Chloe Miller', 5, 'first', 'morning', '0111123456', '159 Beech Blvd, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(35, 'Liam Cooper', 5, 'first', 'night', '0223345678', '753 Cypress St, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(36, 'Emily Wright', 5, 'first', 'night', '0334456789', '951 Aspen Blvd, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(37, 'Samuel Turner', 5, 'second', 'morning', '0445567890', '123 Chestnut Ave, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(38, 'Ava Scott', 5, 'second', 'morning', '0667789012', '456 Willow Blvd, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(39, 'Jack Howard', 5, 'second', 'night', '0778890123', '789 Elmwood St, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(40, 'Isabella Young', 5, 'second', 'night', '0889901234', '321 Pinewood Rd, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(41, 'Michael Harris', 6, 'first', 'morning', '0990012345', '654 Cedarwood Blvd, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(42, 'Lily Foster', 6, 'first', 'morning', '0213345678', '987 Maplewood Rd, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(43, 'Logan Rivera', 6, 'first', 'night', '0324456789', '159 Walnut Blvd, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(44, 'Abigail Scott', 6, 'first', 'night', '0435567890', '753 Redwood St, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(45, 'Elijah Edwards', 6, 'second', 'morning', '0546678901', '951 Alder Rd, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(46, 'Madison Jenkins', 6, 'second', 'morning', '0657789012', '123 Beech Blvd, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(47, 'James Taylor', 6, 'second', 'night', '0768890123', '456 Cypress St, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(48, 'Sophia Lewis', 6, 'second', 'night', '0879901234', '789 Aspen Blvd, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(49, 'David Carter', 7, 'first', 'morning', '0980012345', '321 Chestnut Rd, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(50, 'Ella Moore', 7, 'first', 'morning', '0111123456', '654 Willow Blvd, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(51, 'Lucas Hill', 7, 'first', 'night', '0223345678', '987 Elmwood Rd, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(52, 'Amelia Murphy', 7, 'first', 'night', '0334456789', '159 Pinewood Blvd, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(53, 'Alexander Bell', 7, 'second', 'morning', '0445567890', '753 Cedarwood Rd, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(54, 'Harper Foster', 7, 'second', 'morning', '0667789012', '951 Maplewood Blvd, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(55, 'Nathan Bennett', 7, 'second', 'night', '0778890123', '123 Walnut St, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(56, 'Emily Simmons', 7, 'second', 'night', '0889901234', '456 Redwood Blvd, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(57, 'Jacob Carter', 8, 'first', 'morning', '0990012345', '789 Alder Ave, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(58, 'Mia Scott', 8, 'first', 'morning', '0213345678', '321 Beech St, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(59, 'Ethan Brooks', 8, 'first', 'night', '0324456789', '654 Cypress Rd, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(60, 'Lily Jenkins', 8, 'first', 'night', '0435567890', '987 Aspen Blvd, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(61, 'Mason Howard', 8, 'second', 'morning', '0546678901', '159 Chestnut Blvd, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(62, 'Isabella Rivera', 8, 'second', 'morning', '0657789012', '753 Willow Rd, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(63, 'Sebastian Lopez', 8, 'second', 'night', '0768890123', '951 Elmwood Blvd, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(64, 'Charlotte Powell', 8, 'second', 'night', '0879901234', '123 Pinewood Ave, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(65, 'Samuel Ward', 9, 'first', 'morning', '0980012345', '456 Cedarwood Blvd, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(66, 'Emma Miller', 9, 'first', 'morning', '0111123456', '789 Maplewood Rd, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(67, 'Benjamin King', 9, 'first', 'night', '0223345678', '321 Walnut Blvd, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(68, 'Sophia Edwards', 9, 'first', 'night', '0334456789', '654 Redwood St, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(69, 'Henry Evans', 9, 'second', 'morning', '0445567890', '987 Alder Rd, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(70, 'Olivia Hill', 9, 'second', 'morning', '0667789012', '159 Beech Blvd, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(71, 'Jack Murphy', 9, 'second', 'night', '0778890123', '753 Cypress St, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(72, 'Grace Walker', 9, 'second', 'night', '0889901234', '951 Aspen Blvd, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(73, 'Logan Bell', 10, 'first', 'morning', '0990012345', '123 Chestnut Rd, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(74, 'Abigail Wright', 10, 'first', 'morning', '0213345678', '456 Willow Blvd, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(75, 'Michael Taylor', 10, 'first', 'night', '0324456789', '789 Elmwood Rd, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(76, 'Chloe Lopez', 10, 'first', 'night', '0435567890', '321 Pinewood Blvd, Wellnessville', 0.00, 0.00, 0.00, 0.00, 0.00),
(77, 'Lucas Rivera', 10, 'second', 'morning', '0546678901', '654 Cedarwood Rd, Medcity', 0.00, 0.00, 0.00, 0.00, 0.00),
(78, 'Harper King', 10, 'second', 'morning', '0657789012', '987 Maplewood Blvd, Healthville', 0.00, 0.00, 0.00, 0.00, 0.00),
(79, 'David Moore', 10, 'second', 'night', '0768890123', '159 Walnut St, Caretown', 0.00, 0.00, 0.00, 0.00, 0.00),
(80, 'Jack Willson', 10, 'second', 'night', '0879901234', '256 Redwood Blvd, mrs.marry st', 0.00, 0.00, 0.00, 0.00, 0.00);

-- --------------------------------------------------------

--
-- Table structure for table `past_cases`
--

CREATE TABLE `past_cases` (
  `id` bigint(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `doctor_id` tinyint(2) NOT NULL,
  `entrance_date` date NOT NULL,
  `leave_date` date NOT NULL DEFAULT current_timestamp(),
  `revision_date` date DEFAULT NULL,
  `prescription` text DEFAULT NULL,
  `payment` decimal(12,2) NOT NULL,
  `payment_details` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `patients`
--

CREATE TABLE `patients` (
  `id` tinyint(3) NOT NULL DEFAULT 0,
  `name` varchar(50) NOT NULL,
  `case_name` varchar(50) NOT NULL,
  `doctor_id` tinyint(2) DEFAULT NULL,
  `room_id` tinyint(3) DEFAULT NULL,
  `urgency_level` enum('low','moderate','high') NOT NULL,
  `entrance_date` datetime NOT NULL DEFAULT current_timestamp(),
  `leave_date` date DEFAULT NULL,
  `phone` varchar(30) NOT NULL,
  `address` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `patients`
--
DELIMITER $$
CREATE TRIGGER `after_patient_insert` AFTER INSERT ON `patients` FOR EACH ROW BEGIN

-- =============================================================
-- Trigger: after_patient_insert
-- Purpose:
--     Upon inserting a new patient record, update related tables and auxiliary data:
--         1) Set room occupation status to 'yes'
--         2) Update last_assigned_doctor table to reflect the assigned doctor
--         3) Increment the assigned_cases count in doctors table
--         4) Insert a default entry into patients_services noting urgency level
-- 
-- Notes:
--     - The insert into patients_services causes after_patient_services_insert trigger to fire, but it makes no changes when the service is an urgency level service.
--     - We do not select from services table when inserting urgency level into patients_services because MySQL disallows selecting from and updating the same table simultaneously.
--     - Incrementing the times_per_month column in services table for urgency level services is handled separately in before_patient_delete trigger, which considers number of days.
-- ============================================================= 

    -- Mark room as occupied
    UPDATE rooms
    SET occupation = 'yes'
    WHERE id = NEW.room_id; 

    -- Update or insert into last_assigned_doctor to track latest assignment
    IF (SELECT COUNT(*) FROM last_assigned_doctor) = 0 THEN
        INSERT INTO last_assigned_doctor VALUES (1); -- Initialize if empty
    ELSE
        UPDATE last_assigned_doctor
        SET doctor_id = NEW.doctor_id;
    END IF;

    -- Increment the number of assigned cases for the doctor
    UPDATE doctors
    SET assigned_cases = assigned_cases + 1
    WHERE id = NEW.doctor_id;

    -- Insert urgency level note into patients_services table
    -- Note: We avoid selecting from services table here to prevent MySQL error about reading and updating the same table simultaneously.
    INSERT INTO patients_services
    VALUES (NEW.id, CONCAT('Urgency Level: ', NEW.urgency_level, ' (Per Day)'));

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_patient_delete` BEFORE DELETE ON `patients` FOR EACH ROW BEGIN
-- =============================================================
-- Trigger Type: BEFORE DELETE ON `patients`
-- Name: before_patient_delete
-- Purpose:
--     - Calculate patient’s total payment and detailed billing info
--     - Archive patient record into `past_cases` including cost summary
--     - Update related tables to maintain system integrity:
--         • Free the assigned room
--         • Decrease doctor’s active case count and adjust salary
--         • Update `times_per_month` in `services` for urgency level services
--
-- Triggered By:
--     - Any DELETE on `patients` table (typically from patient_removal procedure)
--
-- Notes:
--     - The urgency-level service cost is calculated by multiplying per-day rate
--       by the number of days the patient stayed
--     - For non-urgency services, total cost is summed directly
--     - The `AFTER INSERT` trigger on `patients_services` does not handle urgency-level
--       increments in services table (this trigger updates those counts instead with day-based increments)
-- =============================================================

    -- Declare local variables for computation
    DECLARE days_spent SMALLINT;
    DECLARE urgency_level_cost,services_cost, total_payment DECIMAL(10,2);
    DECLARE payment_info TEXT;

    -- Set number of days spent (include entrance day)
    SET days_spent = DATEDIFF(CURRENT_DATE(), (SELECT entrance_date FROM patients WHERE id = OLD.id)) + 1;

    -- Calculate urgency-level cost over the total days spent
    SELECT cost * days_spent INTO urgency_level_cost
    FROM services JOIN patients_services
        ON name = service_name
    WHERE patients_services.patient_id = OLD.id  
        AND service_name LIKE 'urgency%';

    -- Sum non-urgency services cost (use COALESCE in case of no services)
    SET services_cost = COALESCE((
        SELECT SUM(cost)
        FROM services JOIN patients_services
            ON name = service_name
        WHERE patients_services.patient_id = OLD.id  
            AND service_name NOT LIKE 'urgency%'
    ), 0);

    -- Calculate total payment
    SET total_payment = urgency_level_cost + services_cost;

    -- Build payment details text with all services and total
    SELECT CONCAT(
        GROUP_CONCAT(
            CASE  
                WHEN name LIKE 'urgency%' THEN
                    CONCAT(name, ': $', urgency_level_cost, ' for ', days_spent, ' days spent')
                ELSE
                    CONCAT(name, ': $', cost)
            END
            ORDER BY name like 'urgency%' DESC -- get the urgency service first to highlight it, also to extract it easily when using SUBSTRING_INDEX in cases_status_analysis view
            SEPARATOR '\n'
        ), 
        '\n total payment: ', total_payment
    )
    INTO payment_info
    FROM services JOIN patients_services
        ON name = service_name
    WHERE patients_services.patient_id = OLD.id;

    -- Insert archived patient record into `past_cases`
    INSERT INTO past_cases (
        name, doctor_id, entrance_date, leave_date, payment, payment_details
    )
    VALUES (
        CONCAT_WS('_', OLD.name, OLD.case_name),
        OLD.doctor_id,
        OLD.entrance_date,
        CURRENT_DATE(),
        total_payment,
        payment_info
    );

    -- Mark room as unoccupied
    UPDATE rooms
    SET occupation = 'no'
    WHERE id = OLD.room_id;

    -- Update doctor record: decrease active case count, increase salary
    UPDATE doctors
    SET 
        assigned_cases = assigned_cases - 1,
        current_monthly_salary = current_monthly_salary + wage_per_case
    WHERE id = OLD.doctor_id;

    -- Update services table: add days spent to times_per_month for urgency-level service
    UPDATE services
    SET times_per_month = times_per_month + days_spent
    WHERE name LIKE CONCAT('%', OLD.urgency_level, '%');

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `patients_services`
--

CREATE TABLE `patients_services` (
  `patient_id` tinyint(3) NOT NULL,
  `service_name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `patients_services`
--
DELIMITER $$
CREATE TRIGGER `after_patient_services_insert` AFTER INSERT ON `patients_services` FOR EACH ROW BEGIN
-- =============================================================
-- Trigger Type: AFTER INSERT ON `patients_services`
-- Name: after_patient_services_insert
-- Purpose:
--     - Increment `times_per_month` in `services` table by 1
--       whenever a new service is added to `patients_services`,
--       *except* for urgency_level services.
--
-- Notes:
--     - Urgency-level services are treated differently: their `times_per_month`
--       is updated in the `BEFORE DELETE` trigger on `patients` with the number
--       of days spent by the patient, not on insertion.
--     - This trigger handles both:
--         • Manual insertions into `patients_services` (expected to be non-urgency services)
--         • Automatic insertions from `after_patient_insert` trigger (which also inserts urgency-level services but leaves them unchanged here)
--
--     - Skips update if the `service_name` starts with 'urgency'
-- =============================================================

    -- Increment service usage count by 1 in `services` table
    -- (only for non-urgency services)
    UPDATE services
    SET times_per_month = times_per_month + 1
    WHERE name = NEW.service_name 
        AND name NOT LIKE 'urgency%';

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `rooms`
--

CREATE TABLE `rooms` (
  `id` tinyint(3) NOT NULL,
  `floor_id` tinyint(2) NOT NULL,
  `occupation` enum('yes','no') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `rooms`
--

INSERT INTO `rooms` (`id`, `floor_id`, `occupation`) VALUES
(1, 1, 'no'),
(2, 1, 'no'),
(3, 1, 'no'),
(4, 1, 'no'),
(5, 1, 'no'),
(6, 1, 'no'),
(7, 1, 'no'),
(8, 1, 'no'),
(9, 1, 'no'),
(10, 1, 'no'),
(11, 2, 'no'),
(12, 2, 'no'),
(13, 2, 'no'),
(14, 2, 'no'),
(15, 2, 'no'),
(16, 2, 'no'),
(17, 2, 'no'),
(18, 2, 'no'),
(19, 2, 'no'),
(20, 2, 'no'),
(21, 3, 'no'),
(22, 3, 'no'),
(23, 3, 'no'),
(24, 3, 'no'),
(25, 3, 'no'),
(26, 3, 'no'),
(27, 3, 'no'),
(28, 3, 'no'),
(29, 3, 'no'),
(30, 3, 'no'),
(31, 4, 'no'),
(32, 4, 'no'),
(33, 4, 'no'),
(34, 4, 'no'),
(35, 4, 'no'),
(36, 4, 'no'),
(37, 4, 'no'),
(38, 4, 'no'),
(39, 4, 'no'),
(40, 4, 'no'),
(41, 5, 'no'),
(42, 5, 'no'),
(43, 5, 'no'),
(44, 5, 'no'),
(45, 5, 'no'),
(46, 5, 'no'),
(47, 5, 'no'),
(48, 5, 'no'),
(49, 5, 'no'),
(50, 5, 'no'),
(51, 6, 'no'),
(52, 6, 'no'),
(53, 6, 'no'),
(54, 6, 'no'),
(55, 6, 'no'),
(56, 6, 'no'),
(57, 6, 'no'),
(58, 6, 'no'),
(59, 6, 'no'),
(60, 6, 'no'),
(61, 7, 'no'),
(62, 7, 'no'),
(63, 7, 'no'),
(64, 7, 'no'),
(65, 7, 'no'),
(66, 7, 'no'),
(67, 7, 'no'),
(68, 7, 'no'),
(69, 7, 'no'),
(70, 7, 'no'),
(71, 8, 'no'),
(72, 8, 'no'),
(73, 8, 'no'),
(74, 8, 'no'),
(75, 8, 'no'),
(76, 8, 'no'),
(77, 8, 'no'),
(78, 8, 'no'),
(79, 8, 'no'),
(80, 8, 'no'),
(81, 9, 'no'),
(82, 9, 'no'),
(83, 9, 'no'),
(84, 9, 'no'),
(85, 9, 'no'),
(86, 9, 'no'),
(87, 9, 'no'),
(88, 9, 'no'),
(89, 9, 'no'),
(90, 9, 'no'),
(91, 10, 'no'),
(92, 10, 'no'),
(93, 10, 'no'),
(94, 10, 'no'),
(95, 10, 'no'),
(96, 10, 'no'),
(97, 10, 'no'),
(98, 10, 'no'),
(99, 10, 'no'),
(100, 10, 'no');

-- --------------------------------------------------------

--
-- Table structure for table `services`
--

CREATE TABLE `services` (
  `name` varchar(50) NOT NULL,
  `cost` decimal(9,2) NOT NULL,
  `times_per_month` int(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `services`
--

INSERT INTO `services` (`name`, `cost`, `times_per_month`) VALUES
('Acne Treatment', 1000.75, 0),
('Allergy Test', 400.25, 0),
('Ambulance Service', 1000.85, 0),
('Blood Test - Complete', 300.45, 0),
('Bone Density Test', 700.65, 0),
('Braces Fitting', 3000.50, 0),
('Cardiac Surgery', 10000.55, 0),
('Cardiology Consultation', 1300.70, 0),
('Chemical Peel', 1200.45, 0),
('Cholesterol Test', 350.15, 0),
('Colonoscopy', 1500.60, 0),
('COVID-19 PCR Test', 250.10, 0),
('CT Scan', 1000.75, 0),
('Day Surgery Admission', 2000.35, 0),
('Dental Filling', 700.25, 0),
('Dentistry Consultation', 800.30, 0),
('Dermatology Consultation', 800.50, 0),
('DNA Testing', 10000.25, 0),
('Echocardiogram', 900.90, 0),
('Electrocardiogram (ECG)', 600.80, 0),
('Emergency Room Admission', 1500.25, 0),
('ENT Consultation', 750.35, 0),
('Eye Test', 200.60, 0),
('Fertility Test', 1000.25, 0),
('Gastroscopy', 1400.55, 0),
('General Practitioner Consultation', 500.25, 0),
('General Ward Daily Charge', 1500.60, 0),
('Gynecological Surgery', 5000.85, 0),
('Hair Removal Laser', 2000.90, 0),
('Health Screening - Basic', 2000.55, 0),
('Health Screening - Comprehensive', 5000.85, 0),
('Health Screening - Executive', 8000.75, 0),
('Hearing Test', 250.45, 0),
('Home Visit by Doctor', 1200.75, 0),
('Home Visit by Nurse', 800.25, 0),
('ICU Daily Charge', 3000.55, 0),
('Kidney Function Test', 400.50, 0),
('Laser Skin Treatment', 2500.85, 0),
('Liver Function Test', 450.70, 0),
('Mammography', 1100.35, 0),
('Meditation Session', 250.65, 0),
('MRI Scan', 1200.50, 0),
('Neurology Consultation', 1200.85, 0),
('Neurosurgery', 12000.35, 0),
('Nutrition Counseling', 800.75, 0),
('Obstetrics Consultation', 700.45, 0),
('Occupational Therapy Session', 400.20, 0),
('Orthopedic Consultation', 900.45, 0),
('Orthopedic Surgery', 6000.90, 0),
('Pap Smear', 300.40, 0),
('Paternity Testing', 7000.65, 0),
('Pediatric Consultation', 600.60, 0),
('Physical Therapy Session', 300.45, 0),
('Physiotherapy Session', 300.35, 0),
('Plastic Surgery - Breast Augmentation', 10000.85, 0),
('Plastic Surgery - Liposuction', 8000.65, 0),
('Plastic Surgery - Rhinoplasty', 7000.50, 0),
('Plastic Surgery - Tummy Tuck', 12000.70, 0),
('Postnatal Checkup', 800.55, 0),
('Prenatal Checkup', 900.60, 0),
('Private Room Daily Charge', 5000.40, 0),
('Prostate Exam', 800.45, 0),
('Psychological Counseling', 1000.90, 0),
('Rehabilitation Program', 5000.35, 0),
('Root Canal Treatment', 1500.55, 0),
('Scaling and Polishing', 500.20, 0),
('Skin Allergy Patch Test', 500.35, 0),
('Skin Biopsy', 800.60, 0),
('Smoking Cessation Program', 2500.50, 0),
('Speech Therapy Session', 350.60, 0),
('Stress Management Counseling', 1200.45, 0),
('Substance Abuse Counseling', 2000.85, 0),
('Teeth Whitening', 2000.85, 0),
('Thyroid Function Test', 400.85, 0),
('Ultrasound', 800.25, 0),
('Urgency Level: High (Per Day)', 1225.85, 0),
('Urgency Level: Low (Per Day)', 250.30, 0),
('Urgency Level: Moderate (Per Day)', 500.45, 0),
('Urine Test', 200.20, 0),
('Vaccination - Flu', 250.20, 0),
('Vaccination - Hepatitis', 400.55, 0),
('Vaccination - Tetanus', 350.40, 0),
('Weight Loss Program', 3000.75, 0),
('Wellness Check-Up', 1500.75, 0),
('Wisdom Tooth Removal', 2500.45, 0),
('X-Ray', 500.30, 0),
('Yoga Session', 200.25, 0);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `doctors`
--
ALTER TABLE `doctors`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `floors`
--
ALTER TABLE `floors`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `last_assigned_doctor`
--
ALTER TABLE `last_assigned_doctor`
  ADD KEY `doctor_id` (`doctor_id`);

--
-- Indexes for table `monthly_expenses`
--
ALTER TABLE `monthly_expenses`
  ADD PRIMARY KEY (`name`);

--
-- Indexes for table `nurses`
--
ALTER TABLE `nurses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `floor_id` (`floor_id`);

--
-- Indexes for table `past_cases`
--
ALTER TABLE `past_cases`
  ADD PRIMARY KEY (`id`),
  ADD KEY `doctor_id` (`doctor_id`);

--
-- Indexes for table `patients`
--
ALTER TABLE `patients`
  ADD PRIMARY KEY (`id`),
  ADD KEY `doctor_id` (`doctor_id`,`room_id`),
  ADD KEY `room_id` (`room_id`);

--
-- Indexes for table `patients_services`
--
ALTER TABLE `patients_services`
  ADD KEY `patient_id` (`patient_id`,`service_name`),
  ADD KEY `service_name` (`service_name`);

--
-- Indexes for table `rooms`
--
ALTER TABLE `rooms`
  ADD PRIMARY KEY (`id`),
  ADD KEY `floor_id` (`floor_id`);

--
-- Indexes for table `services`
--
ALTER TABLE `services`
  ADD PRIMARY KEY (`name`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `doctors`
--
ALTER TABLE `doctors`
  MODIFY `id` tinyint(2) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;

--
-- AUTO_INCREMENT for table `nurses`
--
ALTER TABLE `nurses`
  MODIFY `id` tinyint(2) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=81;

--
-- AUTO_INCREMENT for table `past_cases`
--
ALTER TABLE `past_cases`
  MODIFY `id` bigint(50) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `rooms`
--
ALTER TABLE `rooms`
  MODIFY `id` tinyint(3) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=101;

-- --------------------------------------------------------

--
-- Structure for view `active_doctors`
--
DROP TABLE IF EXISTS `active_doctors`;

CREATE ALGORITHM=UNDEFINED DEFINER=`data_architect`@`%` SQL SECURITY DEFINER VIEW `active_doctors`  AS SELECT `doctors`.`name` AS `doctor_name`, `doctors`.`specialization` AS `specialization`, `doctors`.`assigned_cases` AS `assigned_cases`, `patients`.`name` AS `patient_name`, `patients`.`case_name` AS `patient_case` FROM (`doctors` left join `patients` on(`doctors`.`id` = `patients`.`doctor_id`)) WHERE `doctors`.`assigned_cases` > 0 AND 'comment' <> 'Displays all doctors currently handling one or more active patient cases, Joins doctor information with their assigned patients' ;

-- --------------------------------------------------------

--
-- Structure for view `cases_status_analysis`
--
DROP TABLE IF EXISTS `cases_status_analysis`;

CREATE ALGORITHM=UNDEFINED DEFINER=`data_architect`@`%` SQL SECURITY DEFINER VIEW `cases_status_analysis`  AS WITH patients_summary AS (SELECT `patients`.`urgency_level` AS `col1`, count(0) AS `col2` FROM `patients` GROUP BY `patients`.`urgency_level`), past_cases_summary AS (SELECT substring_index(substring_index(`past_cases`.`payment_details`,' ',3),' ',-1) AS `col3`, count(0) AS `col2` FROM `past_cases` GROUP BY substring_index(substring_index(`past_cases`.`payment_details`,' ',3),' ',-1)) SELECT 'current' AS `type`, '---' AS `total_urgency_level` UNION SELECT `patients_summary`.`col1` AS `col1`, `patients_summary`.`col2` AS `col2` FROM `patients_summary` UNION SELECT 'past' AS `past`, '---' AS `---` UNION ALL SELECT `past_cases_summary`.`col3` AS `col3`, `past_cases_summary`.`col2` AS `col2` FROM `past_cases_summary` UNION ALL SELECT 'Combined Total' AS `Combined Total`, '---' AS `---` UNION ALL SELECT `all_data`.`col1` AS `col1`, sum(`all_data`.`col2`) AS `total` FROM (select `patients_summary`.`col1` AS `col1`,`patients_summary`.`col2` AS `col2` from `patients_summary` union all select `past_cases_summary`.`col3` AS `col3`,`past_cases_summary`.`col2` AS `col2` from `past_cases_summary` where 'comment' <> 'Provides a summarized count of ongoing and past cases (by extracting the third word from past_cases.payment_details) separately and total of both grouped by urgency level with visual separators\r\n') AS `all_data` GROUP BY `all_data`.`col1`;

-- --------------------------------------------------------

--
-- Structure for view `monthly_yearly_income_statement_report`
--
DROP TABLE IF EXISTS `monthly_yearly_income_statement_report`;

CREATE ALGORITHM=UNDEFINED DEFINER=`data_architect`@`%` SQL SECURITY DEFINER VIEW `monthly_yearly_income_statement_report`  AS WITH monthly_income_statement_cte AS (SELECT `monthly_income_statement`.`revenue` AS `revenue_cte`, `monthly_income_statement`.`cost` AS `cost_cte`, `monthly_income_statement`.`income` AS `income_cte`, `monthly_income_statement`.`month` AS `month_cte` FROM `monthly_income_statement` ORDER BY `monthly_income_statement`.`month` ASC) SELECT `monthly_income_statement_cte`.`month_cte` AS `month`, sum(`monthly_income_statement_cte`.`revenue_cte`) over ( partition by year(`monthly_income_statement_cte`.`month_cte`) order by `monthly_income_statement_cte`.`month_cte`) AS `cumulative_revenue`, sum(`monthly_income_statement_cte`.`cost_cte`) over ( partition by year(`monthly_income_statement_cte`.`month_cte`) order by `monthly_income_statement_cte`.`month_cte`) AS `cumulative_cost`, sum(`monthly_income_statement_cte`.`income_cte`) over ( partition by year(`monthly_income_statement_cte`.`month_cte`) order by `monthly_income_statement_cte`.`month_cte`) AS `cumulative_income` FROM `monthly_income_statement_cte` UNION ALL SELECT year(`monthly_income_statement_cte`.`month_cte`) AS `year`, sum(`monthly_income_statement_cte`.`revenue_cte`) AS `revenue`, sum(`monthly_income_statement_cte`.`cost_cte`) AS `cost`, sum(`monthly_income_statement_cte`.`income_cte`) AS `income` FROM `monthly_income_statement_cte` GROUP BY year(`monthly_income_statement_cte`.`month_cte`) UNION ALL SELECT 'total' AS `total`, sum(`monthly_income_statement_cte`.`revenue_cte`) AS `sum(revenue_cte)`, sum(`monthly_income_statement_cte`.`cost_cte`) AS `sum(cost_cte)`, sum(`monthly_income_statement_cte`.`income_cte`) AS `sum(income_cte)` FROM `monthly_income_statement_cte` WHERE 'comment' <> 'Summarizes financial performance data (revenue, cost, and income) across three levels: Monthly cumulative, Yearly total summaries, Overall total for all time''Summarizes financial performance data (revenue, cost, and income) across three levels: Monthly cumulative, Yearly total summaries, Overall total for all time'  ;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `last_assigned_doctor`
--
ALTER TABLE `last_assigned_doctor`
  ADD CONSTRAINT `last_assigned_doctor_ibfk_1` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`id`);

--
-- Constraints for table `nurses`
--
ALTER TABLE `nurses`
  ADD CONSTRAINT `nurses_ibfk_1` FOREIGN KEY (`floor_id`) REFERENCES `floors` (`id`);

--
-- Constraints for table `past_cases`
--
ALTER TABLE `past_cases`
  ADD CONSTRAINT `past_cases_ibfk_1` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`id`);

--
-- Constraints for table `patients`
--
ALTER TABLE `patients`
  ADD CONSTRAINT `patients_ibfk_1` FOREIGN KEY (`doctor_id`) REFERENCES `doctors` (`id`),
  ADD CONSTRAINT `patients_ibfk_2` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`);

--
-- Constraints for table `patients_services`
--
ALTER TABLE `patients_services`
  ADD CONSTRAINT `patients_services_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `patients_services_ibfk_2` FOREIGN KEY (`service_name`) REFERENCES `services` (`name`);

--
-- Constraints for table `rooms`
--
ALTER TABLE `rooms`
  ADD CONSTRAINT `rooms_ibfk_1` FOREIGN KEY (`floor_id`) REFERENCES `floors` (`id`);

DELIMITER $$
--
-- Events
--
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

END$$

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

END$$

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

END$$

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

-- data_entry user creation
GRANT USAGE ON *.* TO `data_entry`@`%` IDENTIFIED BY PASSWORD '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257';
GRANT INSERT ON `hospital`.`patients_services` TO `data_entry`@`%`;
GRANT EXECUTE ON PROCEDURE `hospital`.`patient_removal` TO `data_entry`@`%`;
GRANT EXECUTE ON PROCEDURE `hospital`.`patient_insert` TO `data_entry`@`%`;

-- executive user creation
GRANT USAGE ON *.* TO `executive`@`%` IDENTIFIED BY PASSWORD '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257';
GRANT SELECT ON `hospital`.`active_doctors` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`past_cases` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`monthly_income_statement` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`cases_status_analysis` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`monthly_expenses` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`monthly_yearly_income_statement_report` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`services` TO `executive`@`%`;

-- financial_officer user creation
GRANT USAGE ON *.* TO `financial_officer`@`%` IDENTIFIED BY PASSWORD '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257';
GRANT SELECT ON `hospital`.`monthly_expenses` TO `financial_officer`@`%`;
GRANT SELECT ON `hospital`.`monthly_income_statement` TO `financial_officer`@`%`;
GRANT EXECUTE ON PROCEDURE `hospital`.`teams_incentives` TO `financial_officer`@`%`;
GRANT EXECUTE ON PROCEDURE `hospital`.`nurses_payroll_factors_set` TO `financial_officer`@`%`;

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
