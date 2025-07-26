-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jul 25, 2025 at 10:59 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

-- data_security user creation and privileges
GRANT RELOAD, SHUTDOWN, PROCESS, REFERENCES, SHOW DATABASES, SUPER, LOCK TABLES, REPLICATION SLAVE, REPLICATION CLIENT, CREATE USER ON *.* TO `data_security`@`%` IDENTIFIED BY PASSWORD '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257' WITH GRANT OPTION;


--
-- Database: `hospital`
--
CREATE DATABASE IF NOT EXISTS `hospital` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `hospital`;

-- data_architect user creation and privileges
GRANT USAGE ON *.* TO `data_architect`@`%` IDENTIFIED BY PASSWORD '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, EXECUTE, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EVENT, TRIGGER ON `hospital`.* TO `data_architect`@`%`;

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
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
