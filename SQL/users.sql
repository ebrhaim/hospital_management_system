-- Do NOT run this file if:
-- 1) You’ve already imported the full DB (users already included),
-- 2) you are importing using the individual files (users also included),
-- 3) You’re importing the DB in parts — insert users in correct order/places,
-- 4) You’re using this file alone — users depend on the 'hospital' DB context.

-- data_architect
GRANT USAGE ON *.* TO `data_architect`@`%` IDENTIFIED BY PASSWORD '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, EXECUTE, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EVENT, TRIGGER ON `hospital`.* TO `data_architect`@`%`;

-- data_entry
GRANT USAGE ON *.* TO `data_entry`@`%` IDENTIFIED BY PASSWORD '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257';
GRANT INSERT ON `hospital`.`patients_services` TO `data_entry`@`%`;
GRANT EXECUTE ON PROCEDURE `hospital`.`patient_removal` TO `data_entry`@`%`;
GRANT EXECUTE ON PROCEDURE `hospital`.`patient_insert` TO `data_entry`@`%`;

-- data_security
GRANT RELOAD, SHUTDOWN, PROCESS, REFERENCES, SHOW DATABASES, SUPER, LOCK TABLES, REPLICATION SLAVE, REPLICATION CLIENT, CREATE USER ON *.* TO `data_security`@`%` IDENTIFIED BY PASSWORD '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257' WITH GRANT OPTION;

-- executive
GRANT USAGE ON *.* TO `executive`@`%` IDENTIFIED BY PASSWORD '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257';
GRANT SELECT ON `hospital`.`active_doctors` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`past_cases` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`monthly_income_statement` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`cases_status_analysis` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`monthly_expenses` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`monthly_yearly_income_statement_report` TO `executive`@`%`;
GRANT SELECT ON `hospital`.`services` TO `executive`@`%`;

-- financial_officer
GRANT USAGE ON *.* TO `financial_officer`@`%` IDENTIFIED BY PASSWORD '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257';
GRANT SELECT ON `hospital`.`monthly_expenses` TO `financial_officer`@`%`;
GRANT SELECT ON `hospital`.`monthly_income_statement` TO `financial_officer`@`%`;
GRANT EXECUTE ON PROCEDURE `hospital`.`teams_incentives` TO `financial_officer`@`%`;
GRANT EXECUTE ON PROCEDURE `hospital`.`nurses_payroll_factors_set` TO `financial_officer`@`%`;

