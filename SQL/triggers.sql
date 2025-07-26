DELIMITER $$
CREATE TRIGGER `after_patient_insert` AFTER INSERT ON `patients`
 FOR EACH ROW BEGIN

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

END $$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER `after_patient_services_insert` AFTER INSERT ON `patients_services`
 FOR EACH ROW BEGIN
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

END $$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER `before_patient_delete` BEFORE DELETE ON `patients`
 FOR EACH ROW BEGIN
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

END $$

DELIMITER ;
