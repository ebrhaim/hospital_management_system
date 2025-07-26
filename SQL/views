-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jul 24, 2025 at 12:09 PM
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
-- Structure for view `active_doctors`
--

CREATE ALGORITHM=UNDEFINED DEFINER=`data_architect`@`%` SQL SECURITY DEFINER VIEW `active_doctors`  AS SELECT `doctors`.`name` AS `doctor_name`, `doctors`.`specialization` AS `specialization`, `doctors`.`assigned_cases` AS `assigned_cases`, `patients`.`name` AS `patient_name`, `patients`.`case_name` AS `patient_case` FROM (`doctors` left join `patients` on(`doctors`.`id` = `patients`.`doctor_id`)) WHERE `doctors`.`assigned_cases` > 0 AND 'comment' <> 'Displays all doctors currently handling one or more active patient cases, Joins doctor information with their assigned patients' ;

-- --------------------------------------------------------

--
-- Structure for view `cases_status_analysis`
--

CREATE ALGORITHM=UNDEFINED DEFINER=`data_architect`@`%` SQL SECURITY DEFINER VIEW `cases_status_analysis`  AS WITH patients_summary AS (SELECT `patients`.`urgency_level` AS `col1`, count(0) AS `col2` FROM `patients` GROUP BY `patients`.`urgency_level`), past_cases_summary AS (SELECT substring_index(substring_index(`past_cases`.`payment_details`,' ',3),' ',-1) AS `col3`, count(0) AS `col2` FROM `past_cases` GROUP BY substring_index(substring_index(`past_cases`.`payment_details`,' ',3),' ',-1)) SELECT 'current' AS `type`, '---' AS `total_urgency_level` UNION SELECT `patients_summary`.`col1` AS `col1`, `patients_summary`.`col2` AS `col2` FROM `patients_summary` UNION SELECT 'past' AS `past`, '---' AS `---` UNION ALL SELECT `past_cases_summary`.`col3` AS `col3`, `past_cases_summary`.`col2` AS `col2` FROM `past_cases_summary` UNION ALL SELECT 'Combined Total' AS `Combined Total`, '---' AS `---` UNION ALL SELECT `all_data`.`col1` AS `col1`, sum(`all_data`.`col2`) AS `total` FROM (select `patients_summary`.`col1` AS `col1`,`patients_summary`.`col2` AS `col2` from `patients_summary` union all select `past_cases_summary`.`col3` AS `col3`,`past_cases_summary`.`col2` AS `col2` from `past_cases_summary` where 'comment' <> 'Provides a summarized count of ongoing and past cases (by extracting the third word from past_cases.payment_details) separately and total of both grouped by urgency level with visual separators\r\n') AS `all_data` GROUP BY `all_data`.`col1`;

-- --------------------------------------------------------

--
-- Structure for view `monthly_yearly_income_statement_report`
--

CREATE ALGORITHM=UNDEFINED DEFINER=`data_architect`@`%` SQL SECURITY DEFINER VIEW `monthly_yearly_income_statement_report`  AS WITH monthly_income_statement_cte AS (SELECT `monthly_income_statement`.`revenue` AS `revenue_cte`, `monthly_income_statement`.`cost` AS `cost_cte`, `monthly_income_statement`.`income` AS `income_cte`, `monthly_income_statement`.`month` AS `month_cte` FROM `monthly_income_statement` ORDER BY `monthly_income_statement`.`month` ASC) SELECT `monthly_income_statement_cte`.`month_cte` AS `month`, sum(`monthly_income_statement_cte`.`revenue_cte`) over ( partition by year(`monthly_income_statement_cte`.`month_cte`) order by `monthly_income_statement_cte`.`month_cte`) AS `cumulative_revenue`, sum(`monthly_income_statement_cte`.`cost_cte`) over ( partition by year(`monthly_income_statement_cte`.`month_cte`) order by `monthly_income_statement_cte`.`month_cte`) AS `cumulative_cost`, sum(`monthly_income_statement_cte`.`income_cte`) over ( partition by year(`monthly_income_statement_cte`.`month_cte`) order by `monthly_income_statement_cte`.`month_cte`) AS `cumulative_income` FROM `monthly_income_statement_cte` UNION ALL SELECT year(`monthly_income_statement_cte`.`month_cte`) AS `year`, sum(`monthly_income_statement_cte`.`revenue_cte`) AS `revenue`, sum(`monthly_income_statement_cte`.`cost_cte`) AS `cost`, sum(`monthly_income_statement_cte`.`income_cte`) AS `income` FROM `monthly_income_statement_cte` GROUP BY year(`monthly_income_statement_cte`.`month_cte`) UNION ALL SELECT 'total' AS `total`, sum(`monthly_income_statement_cte`.`revenue_cte`) AS `sum(revenue_cte)`, sum(`monthly_income_statement_cte`.`cost_cte`) AS `sum(cost_cte)`, sum(`monthly_income_statement_cte`.`income_cte`) AS `sum(income_cte)` FROM `monthly_income_statement_cte` WHERE 'comment' <> 'Summarizes financial performance data (revenue, cost, and income) across three levels: Monthly cumulative, Yearly total summaries, Overall total for all time''Summarizes financial performance data (revenue, cost, and income) across three levels: Monthly cumulative, Yearly total summaries, Overall total for all time'  ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
