-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: localhost    Database: eacdb_fresh
-- ------------------------------------------------------
-- Server version	5.5.5-10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `academic_term_policies`
--

DROP TABLE IF EXISTS `academic_term_policies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `academic_term_policies` (
  `term_id` int(11) NOT NULL,
  `inc_expiration_date` date DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`term_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `academic_terms`
--

DROP TABLE IF EXISTS `academic_terms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `academic_terms` (
  `term_id` int(11) NOT NULL AUTO_INCREMENT,
  `term_code` varchar(20) DEFAULT NULL,
  `term_name` varchar(100) NOT NULL,
  `academic_year` varchar(20) DEFAULT NULL,
  `semester_number` int(11) DEFAULT 1,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'INACTIVE',
  `is_active` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`term_id`),
  UNIQUE KEY `term_code` (`term_code`)
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `admin_saved_filters`
--

DROP TABLE IF EXISTS `admin_saved_filters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin_saved_filters` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `username` varchar(255) DEFAULT NULL,
  `filter_name` varchar(255) DEFAULT NULL,
  `keyword` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `track_filter` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_admin_saved_filters_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `admission_applications`
--

DROP TABLE IF EXISTS `admission_applications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admission_applications` (
  `applicant_id` varchar(50) NOT NULL,
  `full_name` varchar(100) DEFAULT NULL,
  `status` varchar(50) DEFAULT 'PENDING',
  PRIMARY KEY (`applicant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `applicant_payments`
--

DROP TABLE IF EXISTS `applicant_payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `applicant_payments` (
  `payment_id` int(11) NOT NULL AUTO_INCREMENT,
  `applicant_id` varchar(50) NOT NULL,
  `payment_amount` decimal(10,2) NOT NULL,
  `payment_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` varchar(20) DEFAULT 'UNPROCESSED',
  PRIMARY KEY (`payment_id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `applicants`
--

DROP TABLE IF EXISTS `applicants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `applicants` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `reference_number` varchar(50) DEFAULT NULL,
  `applicant_status` text DEFAULT NULL,
  `application_status` varchar(50) DEFAULT 'ADMISSION_PENDING',
  `term_year` text DEFAULT NULL,
  `first_name` text DEFAULT NULL,
  `last_name` text DEFAULT NULL,
  `middle_name` text DEFAULT NULL,
  `middle_initial` text DEFAULT NULL,
  `middle_name_na` tinyint(1) DEFAULT 0,
  `extension` text DEFAULT NULL,
  `sex` text DEFAULT NULL,
  `dob` text DEFAULT NULL,
  `place_of_birth` text DEFAULT NULL,
  `civil_status` text DEFAULT NULL,
  `religion` text DEFAULT NULL,
  `nationality` text DEFAULT NULL,
  `citizenship` text DEFAULT NULL,
  `age` int(11) DEFAULT NULL,
  `four_ps` tinyint(1) DEFAULT 0,
  `indigenous` tinyint(1) DEFAULT 0,
  `international_student` tinyint(1) DEFAULT 0,
  `email` text DEFAULT NULL,
  `email_verified` tinyint(1) DEFAULT 0,
  `mobile` text DEFAULT NULL,
  `landline` text DEFAULT NULL,
  `street` text DEFAULT NULL,
  `city` text DEFAULT NULL,
  `province` text DEFAULT NULL,
  `zip` text DEFAULT NULL,
  `emergency_contact_name` text DEFAULT NULL,
  `emergency_contact_mobile` text DEFAULT NULL,
  `emergency_contact_relationship` text DEFAULT NULL,
  `father_name` text DEFAULT NULL,
  `father_occupation` text DEFAULT NULL,
  `father_contact` text DEFAULT NULL,
  `father_address` text DEFAULT NULL,
  `mother_name` text DEFAULT NULL,
  `mother_occupation` text DEFAULT NULL,
  `mother_contact` text DEFAULT NULL,
  `mother_address` text DEFAULT NULL,
  `guardian_name` text DEFAULT NULL,
  `guardian_contact` text DEFAULT NULL,
  `guardian_relationship` text DEFAULT NULL,
  `sibling_count` int(11) DEFAULT NULL,
  `sibling_order` text DEFAULT NULL,
  `monthly_income` text DEFAULT NULL,
  `academic_level` text DEFAULT NULL,
  `elementary_school` text DEFAULT NULL,
  `elementary_address` text DEFAULT NULL,
  `elementary_year` text DEFAULT NULL,
  `jhs_school` text DEFAULT NULL,
  `jhs_address` text DEFAULT NULL,
  `jhs_year` text DEFAULT NULL,
  `shs_school` text DEFAULT NULL,
  `shs_address` text DEFAULT NULL,
  `shs_track` text DEFAULT NULL,
  `shs_year` text DEFAULT NULL,
  `last_school` text DEFAULT NULL,
  `last_school_year` text DEFAULT NULL,
  `course_taken` text DEFAULT NULL,
  `program1` text DEFAULT NULL,
  `program2` text DEFAULT NULL,
  `form138_path` text DEFAULT NULL,
  `form138_verified` tinyint(1) DEFAULT 0,
  `good_moral_path` text DEFAULT NULL,
  `good_moral_verified` tinyint(1) DEFAULT 0,
  `psa_birth_cert_path` text DEFAULT NULL,
  `psa_birth_cert_verified` tinyint(1) DEFAULT 0,
  `id_picture_path` text DEFAULT NULL,
  `id_picture_verified` tinyint(1) DEFAULT 0,
  `marriage_cert_path` text DEFAULT NULL,
  `marriage_cert_verified` tinyint(1) DEFAULT 0,
  `other_doc_path` text DEFAULT NULL,
  `other_doc_verified` tinyint(1) DEFAULT 0,
  `interview_date` text DEFAULT NULL,
  `interview_time` text DEFAULT NULL,
  `interview_link` text DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `revised` tinyint(1) DEFAULT 0,
  `reopen_until` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `enrollment_start_time` datetime DEFAULT NULL,
  `registration_date` datetime DEFAULT NULL,
  `semester` int(11) DEFAULT 1,
  `year_level` int(11) DEFAULT 1,
  `scholarship_type` varchar(50) DEFAULT 'NONE',
  `application_track` text DEFAULT NULL,
  `degree_certificate_program` text DEFAULT NULL,
  `enrollment_term` text DEFAULT NULL,
  `school_year_text` text DEFAULT NULL,
  `admission_classification` text DEFAULT NULL,
  `lrn` text DEFAULT NULL,
  `visa_status` text DEFAULT NULL,
  `period_of_authorized_stay` text DEFAULT NULL,
  `passport_no` text DEFAULT NULL,
  `passport_issue_date` text DEFAULT NULL,
  `passport_expiry_date` text DEFAULT NULL,
  `acr_no` text DEFAULT NULL,
  `acr_issue_date` text DEFAULT NULL,
  `acr_expiry_date` text DEFAULT NULL,
  `crt_no` text DEFAULT NULL,
  `crt_issue_date` text DEFAULT NULL,
  `crt_expiry_date` text DEFAULT NULL,
  `father_company_address` text DEFAULT NULL,
  `mother_company_address` text DEFAULT NULL,
  `guardian_age` int(11) DEFAULT NULL,
  `guardian_occupation` text DEFAULT NULL,
  `guardian_home_address` text DEFAULT NULL,
  `guardian_landline` text DEFAULT NULL,
  `guardian_mobile` text DEFAULT NULL,
  `guardian_email` text DEFAULT NULL,
  `undergrad_school_address` text DEFAULT NULL,
  `grad_program_school` text DEFAULT NULL,
  `grad_program_address` text DEFAULT NULL,
  `grad_program_year` text DEFAULT NULL,
  `privacy_consent_accepted` tinyint(1) NOT NULL DEFAULT 0,
  `privacy_consent_by_guardian` tinyint(1) NOT NULL DEFAULT 0,
  `declaration_learner_name` text DEFAULT NULL,
  `declaration_accomplished_date` text DEFAULT NULL,
  `foreign_city_address` text DEFAULT NULL,
  `foreign_city_tel` text DEFAULT NULL,
  `foreign_provincial_address` text DEFAULT NULL,
  `foreign_provincial_tel` text DEFAULT NULL,
  `foreign_home_house_name` text DEFAULT NULL,
  `foreign_home_street` text DEFAULT NULL,
  `foreign_home_province` text DEFAULT NULL,
  `foreign_home_city` text DEFAULT NULL,
  `foreign_home_country` text DEFAULT NULL,
  `foreign_home_zip` text DEFAULT NULL,
  `foreign_home_tel` text DEFAULT NULL,
  `foreign_current_house_name` text DEFAULT NULL,
  `foreign_current_street` text DEFAULT NULL,
  `foreign_current_province` text DEFAULT NULL,
  `foreign_current_city` text DEFAULT NULL,
  `foreign_current_country` text DEFAULT NULL,
  `foreign_current_zip` text DEFAULT NULL,
  `foreign_current_tel` text DEFAULT NULL,
  `foreign_emergency_house_name` text DEFAULT NULL,
  `foreign_emergency_street` text DEFAULT NULL,
  `foreign_emergency_province` text DEFAULT NULL,
  `foreign_emergency_city` text DEFAULT NULL,
  `foreign_emergency_country` text DEFAULT NULL,
  `foreign_emergency_zip` text DEFAULT NULL,
  `foreign_emergency_tel` text DEFAULT NULL,
  `father_age` int(11) DEFAULT NULL,
  `mother_age` int(11) DEFAULT NULL,
  `father_landline` text DEFAULT NULL,
  `father_email` text DEFAULT NULL,
  `father_office_tel` text DEFAULT NULL,
  `father_highest_education` text DEFAULT NULL,
  `father_schools_attended` text DEFAULT NULL,
  `mother_landline` text DEFAULT NULL,
  `mother_email` text DEFAULT NULL,
  `mother_office_tel` text DEFAULT NULL,
  `mother_highest_education` text DEFAULT NULL,
  `mother_schools_attended` text DEFAULT NULL,
  `foreign_siblings_json` text DEFAULT NULL,
  `foreign_references_json` text DEFAULT NULL,
  `foreign_edu_elementary` text DEFAULT NULL,
  `foreign_edu_high_school` text DEFAULT NULL,
  `foreign_edu_college` text DEFAULT NULL,
  `foreign_edu_post_graduate` text DEFAULT NULL,
  `foreign_edu_vocational` text DEFAULT NULL,
  `foreign_certification_accepted` tinyint(1) NOT NULL DEFAULT 0,
  `email_verification_token` text DEFAULT NULL,
  `interview_mode` text DEFAULT NULL,
  `interview_venue` text DEFAULT NULL,
  `reopen_reminder_sent_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `reference_number` (`reference_number`)
) ENGINE=InnoDB AUTO_INCREMENT=108 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `application_logs`
--

DROP TABLE IF EXISTS `application_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `application_logs` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `applicant_id` bigint(20) DEFAULT NULL,
  `action` varchar(255) DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `performed_by` varchar(255) DEFAULT NULL,
  `actor_role` varchar(255) DEFAULT NULL,
  `source_page` varchar(255) DEFAULT NULL,
  `old_value` text DEFAULT NULL,
  `new_value` text DEFAULT NULL,
  `timestamp` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_application_logs_applicant` (`applicant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `audit_logs`
--

DROP TABLE IF EXISTS `audit_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_logs` (
  `log_id` int(11) NOT NULL AUTO_INCREMENT,
  `admin_id` int(11) DEFAULT NULL,
  `action` varchar(255) DEFAULT NULL,
  `log_date` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`log_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `class_schedules`
--

DROP TABLE IF EXISTS `class_schedules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `class_schedules` (
  `schedule_id` int(11) NOT NULL AUTO_INCREMENT,
  `section_id` int(11) NOT NULL,
  `room_id` int(11) DEFAULT NULL,
  `faculty_id` int(11) DEFAULT NULL,
  `day_of_week` int(11) DEFAULT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `schedule_type` varchar(20) DEFAULT 'Lecture',
  `status` varchar(50) DEFAULT 'OPEN',
  PRIMARY KEY (`schedule_id`),
  KEY `fk_sch_section` (`section_id`),
  KEY `fk_sch_room` (`room_id`),
  KEY `fk_sch_faculty` (`faculty_id`),
  CONSTRAINT `fk_sch_faculty` FOREIGN KEY (`faculty_id`) REFERENCES `faculty` (`faculty_id`),
  CONSTRAINT `fk_sch_room` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`room_id`),
  CONSTRAINT `fk_sch_section` FOREIGN KEY (`section_id`) REFERENCES `class_sections` (`section_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1458 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `class_sections`
--

DROP TABLE IF EXISTS `class_sections`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `class_sections` (
  `section_id` int(11) NOT NULL AUTO_INCREMENT,
  `course_id` int(11) NOT NULL,
  `term_id` int(11) NOT NULL,
  `section_code` varchar(32) NOT NULL,
  `faculty_id` int(11) DEFAULT NULL,
  `max_capacity` int(11) DEFAULT 40,
  `section_status` varchar(20) DEFAULT 'Planning',
  `semester_number` int(11) DEFAULT NULL,
  PRIMARY KEY (`section_id`),
  UNIQUE KEY `uq_term_course_section` (`term_id`,`course_id`,`section_code`),
  KEY `idx_sections_term` (`term_id`),
  KEY `fk_cs_course` (`course_id`),
  KEY `fk_cs_faculty` (`faculty_id`),
  CONSTRAINT `fk_cs_course` FOREIGN KEY (`course_id`) REFERENCES `courses` (`course_id`),
  CONSTRAINT `fk_cs_faculty` FOREIGN KEY (`faculty_id`) REFERENCES `faculty` (`faculty_id`),
  CONSTRAINT `fk_cs_term` FOREIGN KEY (`term_id`) REFERENCES `academic_terms` (`term_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3928 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `course_prerequisites`
--

DROP TABLE IF EXISTS `course_prerequisites`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `course_prerequisites` (
  `prerequisite_id` int(11) NOT NULL AUTO_INCREMENT,
  `course_id` int(11) NOT NULL,
  `prerequisite_course_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`prerequisite_id`),
  UNIQUE KEY `unique_prereq` (`course_id`,`prerequisite_course_id`),
  KEY `idx_cp_prereq` (`prerequisite_course_id`),
  CONSTRAINT `fk_cp_course` FOREIGN KEY (`course_id`) REFERENCES `courses` (`course_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cp_prereq_course` FOREIGN KEY (`prerequisite_course_id`) REFERENCES `courses` (`course_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=692 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `courses`
--

DROP TABLE IF EXISTS `courses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `courses` (
  `course_id` int(11) NOT NULL AUTO_INCREMENT,
  `course_code` varchar(20) NOT NULL,
  `course_title` varchar(100) NOT NULL,
  `department_id` int(11) NOT NULL,
  `description` text DEFAULT NULL,
  `credit_units` int(11) NOT NULL DEFAULT 3,
  `lec_units` int(11) NOT NULL DEFAULT 0,
  `lecture_units` int(11) DEFAULT NULL,
  `lab_units` int(11) NOT NULL DEFAULT 0,
  `lecture_hours_per_week` int(11) DEFAULT 3,
  `lab_hours_per_week` int(11) DEFAULT 0,
  `max_students` int(11) DEFAULT 40,
  `course_type` varchar(20) DEFAULT NULL,
  `is_coordinator_based` tinyint(1) NOT NULL DEFAULT 0,
  `coordinator_equivalent_units` int(11) DEFAULT NULL,
  `active_status` tinyint(1) DEFAULT 1,
  `onlist` tinyint(1) GENERATED ALWAYS AS (`active_status`) STORED,
  PRIMARY KEY (`course_id`),
  UNIQUE KEY `course_code` (`course_code`),
  KEY `fk_course_dept` (`department_id`),
  CONSTRAINT `fk_course_dept` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`),
  CONSTRAINT `chk_coordinator` CHECK (`is_coordinator_based` = 0 and `coordinator_equivalent_units` is null or `is_coordinator_based` = 1 and `coordinator_equivalent_units` is not null and `coordinator_equivalent_units` > 0)
) ENGINE=InnoDB AUTO_INCREMENT=2312 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `curriculum_catalog`
--

DROP TABLE IF EXISTS `curriculum_catalog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `curriculum_catalog` (
  `course_code` varchar(20) NOT NULL,
  `description` varchar(150) DEFAULT NULL,
  `units` int(11) DEFAULT 3,
  PRIMARY KEY (`course_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `curriculum_courses`
--

DROP TABLE IF EXISTS `curriculum_courses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `curriculum_courses` (
  `curriculum_course_id` int(11) NOT NULL AUTO_INCREMENT,
  `curriculum_id` int(11) NOT NULL,
  `course_id` int(11) NOT NULL,
  `year_level` int(11) NOT NULL,
  `semester_number` int(11) NOT NULL,
  `is_required` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`curriculum_course_id`),
  UNIQUE KEY `uq_curr_course` (`curriculum_id`,`course_id`,`year_level`,`semester_number`),
  KEY `fk_cc_course` (`course_id`),
  CONSTRAINT `fk_cc_course` FOREIGN KEY (`course_id`) REFERENCES `courses` (`course_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cc_curriculum` FOREIGN KEY (`curriculum_id`) REFERENCES `curriculum_templates` (`curriculum_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1528 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `curriculum_templates`
--

DROP TABLE IF EXISTS `curriculum_templates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `curriculum_templates` (
  `curriculum_id` int(11) NOT NULL AUTO_INCREMENT,
  `program_id` int(11) NOT NULL,
  `curriculum_name` varchar(100) DEFAULT NULL,
  `academic_year` varchar(20) DEFAULT NULL,
  `version_number` int(11) NOT NULL DEFAULT 1,
  `approval_status` varchar(20) NOT NULL DEFAULT 'Draft',
  `is_active` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`curriculum_id`),
  KEY `fk_ct_program` (`program_id`),
  CONSTRAINT `fk_ct_program` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=102 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `data_privacy_policies`
--

DROP TABLE IF EXISTS `data_privacy_policies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_privacy_policies` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `policy_code` varchar(32) NOT NULL,
  `title` varchar(255) NOT NULL,
  `subtitle` varchar(255) DEFAULT NULL,
  `body_html` longtext NOT NULL,
  `updated_at` datetime DEFAULT NULL,
  `updated_by` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_data_privacy_policy_code` (`policy_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `departments`
--

DROP TABLE IF EXISTS `departments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `departments` (
  `department_id` int(11) NOT NULL AUTO_INCREMENT,
  `department_code` varchar(10) NOT NULL,
  `department_name` varchar(100) NOT NULL,
  `faculty_id` int(11) DEFAULT NULL,
  `building_location` varchar(200) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`department_id`),
  UNIQUE KEY `department_code` (`department_code`),
  KEY `fk_dept_head` (`faculty_id`),
  CONSTRAINT `fk_dept_head` FOREIGN KEY (`faculty_id`) REFERENCES `faculty` (`faculty_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `eac_application_logs`
--

DROP TABLE IF EXISTS `eac_application_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `eac_application_logs` (
  `log_id` int(11) NOT NULL AUTO_INCREMENT,
  `ref_no` varchar(30) DEFAULT NULL,
  `action` varchar(100) DEFAULT NULL,
  `performed_by` varchar(60) DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `log_timestamp` datetime DEFAULT NULL,
  PRIMARY KEY (`log_id`)
) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `enrollment_settings`
--

DROP TABLE IF EXISTS `enrollment_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `enrollment_settings` (
  `setting_key` varchar(80) NOT NULL,
  `setting_value` varchar(500) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `enrollment_track_settings`
--

DROP TABLE IF EXISTS `enrollment_track_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `enrollment_track_settings` (
  `track` varchar(32) NOT NULL,
  `enrollment_open` tinyint(1) NOT NULL DEFAULT 1,
  `closed_message` text DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`track`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `faculty`
--

DROP TABLE IF EXISTS `faculty`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `faculty` (
  `faculty_id` int(11) NOT NULL AUTO_INCREMENT,
  `employee_number` varchar(20) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `department_id` int(11) DEFAULT NULL,
  `employment_type` varchar(20) DEFAULT NULL,
  `max_teaching_units` int(11) DEFAULT 18,
  `active_status` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`faculty_id`),
  UNIQUE KEY `employee_number` (`employee_number`),
  UNIQUE KEY `email` (`email`),
  KEY `fk_faculty_dept` (`department_id`),
  CONSTRAINT `fk_faculty_dept` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `grade_change_requests`
--

DROP TABLE IF EXISTS `grade_change_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `grade_change_requests` (
  `request_id` int(11) NOT NULL AUTO_INCREMENT,
  `grade_id` bigint(20) DEFAULT NULL,
  `student_name` varchar(100) DEFAULT NULL,
  `course_code` varchar(20) DEFAULT NULL,
  `faculty_name` varchar(100) DEFAULT NULL,
  `requested_grade` varchar(20) DEFAULT NULL,
  `reason` text DEFAULT NULL,
  `status` varchar(30) DEFAULT 'PENDING',
  `request_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `request_type` varchar(40) NOT NULL DEFAULT 'FINAL_GRADE_CORRECTION',
  `requested_prelim` decimal(5,2) DEFAULT NULL,
  `requested_midterm` decimal(5,2) DEFAULT NULL,
  `requested_finals` decimal(5,2) DEFAULT NULL,
  `applied_action` varchar(80) DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`request_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `grades`
--

DROP TABLE IF EXISTS `grades`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `grades` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `student_id` varchar(100) NOT NULL,
  `course_id` int(11) NOT NULL,
  `section_id` int(11) DEFAULT NULL,
  `prelim` decimal(5,2) DEFAULT NULL,
  `midterm` decimal(5,2) DEFAULT NULL,
  `final_grade` decimal(5,2) DEFAULT NULL,
  `semestral_grade` decimal(5,2) DEFAULT NULL,
  `remarks` varchar(30) DEFAULT NULL,
  `previous_grade` varchar(20) DEFAULT NULL,
  `student_name` varchar(100) DEFAULT NULL,
  `curriculum_year` int(11) DEFAULT NULL,
  `grade` double DEFAULT NULL,
  `status` varchar(20) DEFAULT 'DRAFT',
  `date_recorded` datetime DEFAULT NULL,
  `registrar_final_grade` decimal(5,2) DEFAULT NULL,
  `registrar_final_remarks` varchar(30) DEFAULT NULL,
  `grade_lock_status` varchar(30) DEFAULT NULL,
  `grade_lock_reason` varchar(80) DEFAULT NULL,
  `registrar_finalized_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_grades_student` (`student_id`),
  KEY `fk_g_course` (`course_id`),
  CONSTRAINT `fk_g_course` FOREIGN KEY (`course_id`) REFERENCES `courses` (`course_id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `grading_term_windows`
--

DROP TABLE IF EXISTS `grading_term_windows`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `grading_term_windows` (
  `window_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `term_id` int(11) NOT NULL,
  `grading_period` varchar(20) NOT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `override_status` varchar(20) NOT NULL DEFAULT 'AUTO',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`window_id`),
  UNIQUE KEY `uq_gtw_term_period` (`term_id`,`grading_period`),
  KEY `idx_gtw_term` (`term_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `payments`
--

DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payments` (
  `payment_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `transaction_id` varchar(60) NOT NULL,
  `or_number` varchar(20) DEFAULT NULL,
  `reference_number` varchar(50) NOT NULL,
  `amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `change_amount` decimal(12,2) DEFAULT 0.00,
  `payment_method` varchar(60) DEFAULT 'Cash (OTC)',
  `semester` int(11) DEFAULT 1,
  `year_level` int(11) DEFAULT 1,
  `term_year` varchar(30) DEFAULT NULL,
  `remarks` varchar(150) DEFAULT NULL,
  `payment_date` datetime NOT NULL DEFAULT current_timestamp(),
  `status` varchar(20) NOT NULL DEFAULT 'COMPLETED',
  `bank_name` varchar(100) DEFAULT NULL,
  `check_number` varchar(60) DEFAULT NULL,
  `check_date` datetime DEFAULT NULL,
  `cashier_name` varchar(100) DEFAULT NULL,
  `date_created` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`payment_id`),
  UNIQUE KEY `uk_transaction` (`transaction_id`)
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `program_fee_settings`
--

DROP TABLE IF EXISTS `program_fee_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `program_fee_settings` (
  `fee_setting_id` int(11) NOT NULL AUTO_INCREMENT,
  `program_id` int(11) NOT NULL,
  `term_id` int(11) DEFAULT NULL,
  `year_level` int(11) DEFAULT NULL,
  `semester_number` int(11) DEFAULT NULL,
  `fee_tuition_per_unit` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_lec_per_unit` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_lab_per_unit` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_comp_per_unit` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_rle_per_unit` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_misc_registration` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_misc_library` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_misc_medical` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_misc_id` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_misc_athletic` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_misc_guidance` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_misc_lms` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_misc_insurance` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_misc_cultural` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_misc_av` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_misc_energy` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_other_id` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_other_insurance` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_other_comp` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_other_dev` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_other_late_enrollment` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_other_add_drop` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fee_other_installment` decimal(10,2) NOT NULL DEFAULT 0.00,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`fee_setting_id`),
  KEY `idx_pfs_scope` (`program_id`,`year_level`,`semester_number`,`term_id`),
  CONSTRAINT `fk_pfs_program` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2577 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `programs`
--

DROP TABLE IF EXISTS `programs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `programs` (
  `program_id` int(11) NOT NULL AUTO_INCREMENT,
  `program_code` varchar(20) NOT NULL,
  `program_name` varchar(150) DEFAULT NULL,
  `department_id` int(11) DEFAULT NULL,
  `school_name` varchar(100) DEFAULT NULL,
  `active_status` tinyint(1) NOT NULL DEFAULT 1,
  `level` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`program_id`),
  UNIQUE KEY `program_code` (`program_code`),
  KEY `fk_prog_dept` (`department_id`),
  CONSTRAINT `fk_prog_dept` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=102 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `requirement_upload_definitions`
--

DROP TABLE IF EXISTS `requirement_upload_definitions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `requirement_upload_definitions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `application_track` varchar(32) NOT NULL,
  `slot_key` varchar(64) NOT NULL,
  `display_label` text NOT NULL,
  `kind` varchar(16) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `required` tinyint(1) NOT NULL DEFAULT 1,
  `sort_order` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_req_upload_track_slot` (`application_track`,`slot_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rooms`
--

DROP TABLE IF EXISTS `rooms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rooms` (
  `room_id` int(11) NOT NULL AUTO_INCREMENT,
  `room_code` varchar(20) NOT NULL,
  `building_name` varchar(50) DEFAULT NULL,
  `capacity` int(11) DEFAULT NULL,
  `room_type` varchar(20) DEFAULT 'Lecture',
  `active_status` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`room_id`),
  UNIQUE KEY `room_code` (`room_code`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `scholarship_types`
--

DROP TABLE IF EXISTS `scholarship_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `scholarship_types` (
  `type_id` int(11) NOT NULL AUTO_INCREMENT,
  `classification` varchar(50) NOT NULL,
  `is_internal` tinyint(1) DEFAULT 0,
  `requires_id` tinyint(1) DEFAULT 1,
  `display_name` varchar(100) DEFAULT NULL,
  `discount_mode` varchar(20) NOT NULL DEFAULT 'PERCENT',
  `default_discount_percentage` decimal(5,2) NOT NULL DEFAULT 0.00,
  `default_scholarship_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`type_id`),
  UNIQUE KEY `classification` (`classification`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `school_terms`
--

DROP TABLE IF EXISTS `school_terms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `school_terms` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `school_year` varchar(255) NOT NULL,
  `semester` varchar(255) NOT NULL,
  `code` varchar(255) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `current_term` tinyint(1) NOT NULL DEFAULT 0,
  `scope` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_school_terms_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_curriculum_assignments`
--

DROP TABLE IF EXISTS `student_curriculum_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_curriculum_assignments` (
  `assignment_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `student_number` varchar(100) NOT NULL,
  `curriculum_id` int(11) NOT NULL,
  `program_code` varchar(100) NOT NULL,
  `assignment_type` varchar(40) NOT NULL DEFAULT 'DEFAULT',
  `reason` varchar(255) DEFAULT NULL,
  `is_current` tinyint(1) NOT NULL DEFAULT 1,
  `assigned_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`assignment_id`),
  KEY `idx_sca_student_current` (`student_number`,`is_current`),
  KEY `idx_sca_curriculum` (`curriculum_id`),
  KEY `idx_sca_program` (`program_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_enlistments`
--

DROP TABLE IF EXISTS `student_enlistments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_enlistments` (
  `enlistment_id` int(11) NOT NULL AUTO_INCREMENT,
  `student_id` varchar(100) NOT NULL,
  `course_id` int(11) NOT NULL,
  `section_id` int(11) NOT NULL,
  `enlisted_date` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`enlistment_id`),
  KEY `idx_se_student_course` (`student_id`,`course_id`),
  KEY `idx_se_student` (`student_id`),
  KEY `fk_se_course` (`course_id`),
  KEY `fk_se_section` (`section_id`),
  CONSTRAINT `fk_se_course` FOREIGN KEY (`course_id`) REFERENCES `courses` (`course_id`),
  CONSTRAINT `fk_se_section` FOREIGN KEY (`section_id`) REFERENCES `class_sections` (`section_id`)
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `student_grades`
--

DROP TABLE IF EXISTS `student_grades`;
/*!50001 DROP VIEW IF EXISTS `student_grades`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `student_grades` AS SELECT 
 1 AS `grade_id`,
 1 AS `schedule_id`,
 1 AS `student_name`,
 1 AS `student_id`,
 1 AS `prelim`,
 1 AS `midterm`,
 1 AS `final`,
 1 AS `semestral_grade`,
 1 AS `remarks`,
 1 AS `previous_grade`,
 1 AS `status`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `student_ledger`
--

DROP TABLE IF EXISTS `student_ledger`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_ledger` (
  `ledger_id` int(11) NOT NULL AUTO_INCREMENT,
  `student_id` varchar(100) NOT NULL,
  `transaction_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `transaction_type` varchar(40) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `debit` decimal(10,2) DEFAULT 0.00,
  `credit` decimal(10,2) DEFAULT 0.00,
  PRIMARY KEY (`ledger_id`),
  KEY `idx_ledger_student` (`student_id`)
) ENGINE=InnoDB AUTO_INCREMENT=951 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_requirement_files`
--

DROP TABLE IF EXISTS `student_requirement_files`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_requirement_files` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `applicant_id` bigint(20) NOT NULL,
  `definition_id` bigint(20) NOT NULL,
  `stored_path` text NOT NULL,
  `verified` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_student_req_file` (`applicant_id`,`definition_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_scholarships`
--

DROP TABLE IF EXISTS `student_scholarships`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_scholarships` (
  `scholarship_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `type_id` int(11) NOT NULL,
  `semester_id` int(11) NOT NULL DEFAULT 1,
  `status` varchar(20) DEFAULT 'ACTIVE',
  `granted_date` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`scholarship_id`),
  KEY `fk_ss_user` (`user_id`),
  KEY `fk_ss_type` (`type_id`),
  CONSTRAINT `fk_ss_type` FOREIGN KEY (`type_id`) REFERENCES `scholarship_types` (`type_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ss_user` FOREIGN KEY (`user_id`) REFERENCES `sys_users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_waitlist`
--

DROP TABLE IF EXISTS `student_waitlist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_waitlist` (
  `waitlist_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `student_id` varchar(100) NOT NULL,
  `course_id` int(11) NOT NULL,
  `status` varchar(30) DEFAULT 'WAITING',
  `priority_date` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`waitlist_id`),
  KEY `idx_wl_student` (`student_id`),
  KEY `fk_wl_course` (`course_id`),
  CONSTRAINT `fk_wl_course` FOREIGN KEY (`course_id`) REFERENCES `courses` (`course_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `students`
--

DROP TABLE IF EXISTS `students`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `students` (
  `student_number` varchar(100) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `reference_number` varchar(100) DEFAULT NULL,
  `first_name` varchar(100) DEFAULT NULL,
  `last_name` varchar(100) DEFAULT NULL,
  `middle_name` varchar(100) DEFAULT NULL,
  `real_name` varchar(200) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `mobile` varchar(50) DEFAULT NULL,
  `program_code` varchar(100) DEFAULT NULL,
  `year_level` int(11) NOT NULL DEFAULT 1,
  `semester` int(11) NOT NULL DEFAULT 1,
  `term_year` varchar(50) DEFAULT NULL,
  `student_type` varchar(50) DEFAULT NULL,
  `enrollment_status_type` varchar(50) DEFAULT NULL,
  `admission_status` varchar(50) DEFAULT NULL,
  `scholarship_type` varchar(50) DEFAULT 'NONE',
  `scholarship_approved` tinyint(1) NOT NULL DEFAULT 0,
  `scholarship_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `discount_percentage` decimal(5,2) NOT NULL DEFAULT 0.00,
  `section_group` varchar(10) DEFAULT NULL,
  `status` varchar(50) NOT NULL DEFAULT 'ACTIVE',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `enrollment_blocked` tinyint(1) NOT NULL DEFAULT 0,
  `password` varchar(255) DEFAULT NULL,
  `role` varchar(30) NOT NULL DEFAULT 'STUDENT',
  PRIMARY KEY (`student_number`),
  KEY `idx_students_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `subject_logs`
--

DROP TABLE IF EXISTS `subject_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subject_logs` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `student_number` varchar(50) DEFAULT NULL,
  `action` varchar(20) DEFAULT NULL,
  `course_code` varchar(20) DEFAULT NULL,
  `course_title` varchar(200) DEFAULT NULL,
  `timestamp` datetime DEFAULT NULL,
  `performed_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=90 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `subject_requests`
--

DROP TABLE IF EXISTS `subject_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subject_requests` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `student_id` varchar(100) NOT NULL,
  `course_id` int(11) NOT NULL,
  `section_id` int(11) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'PENDING',
  `request_date` datetime DEFAULT NULL,
  `reason` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sr_student` (`student_id`),
  KEY `fk_sr_course` (`course_id`),
  KEY `fk_sr_section` (`section_id`),
  CONSTRAINT `fk_sr_course` FOREIGN KEY (`course_id`) REFERENCES `courses` (`course_id`),
  CONSTRAINT `fk_sr_section` FOREIGN KEY (`section_id`) REFERENCES `class_sections` (`section_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sys_users`
--

DROP TABLE IF EXISTS `sys_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_users` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `real_name` varchar(100) DEFAULT NULL,
  `first_name` varchar(100) DEFAULT NULL,
  `last_name` varchar(100) DEFAULT NULL,
  `middle_name` varchar(100) DEFAULT NULL,
  `role` varchar(30) DEFAULT NULL,
  `program_code` varchar(100) DEFAULT NULL,
  `year_level` int(11) DEFAULT 1,
  `semester` int(11) DEFAULT 1,
  `term_year` varchar(30) DEFAULT 'SL_1120252026',
  `reference_number` varchar(50) DEFAULT NULL,
  `student_type` varchar(50) DEFAULT NULL,
  `enrollment_status_type` varchar(50) DEFAULT NULL,
  `scholarship_type` varchar(50) DEFAULT 'NONE',
  `discount_percentage` decimal(5,2) DEFAULT 0.00,
  `admission_status` varchar(50) DEFAULT NULL,
  `admission_date` datetime DEFAULT NULL,
  `enrollment_blocked` tinyint(1) DEFAULT 0,
  `enrollment_start_time` datetime DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `mobile` varchar(20) DEFAULT NULL,
  `street` text DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `province` varchar(100) DEFAULT NULL,
  `last_school` varchar(200) DEFAULT NULL,
  `course_taken` varchar(200) DEFAULT NULL,
  `form138_path` varchar(255) DEFAULT NULL,
  `good_moral_path` varchar(255) DEFAULT NULL,
  `psa_birth_cert_path` varchar(255) DEFAULT NULL,
  `id_picture_path` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `status` varchar(30) DEFAULT 'ACTIVE',
  `granted_permissions` text DEFAULT NULL,
  `scholarship_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `scholarship_approved` tinyint(1) NOT NULL DEFAULT 0,
  `section_group` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `system_settings`
--

DROP TABLE IF EXISTS `system_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `system_settings` (
  `setting_key` varchar(50) NOT NULL,
  `setting_value` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `term_installment_plan`
--

DROP TABLE IF EXISTS `term_installment_plan`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `term_installment_plan` (
  `plan_id` int(11) NOT NULL AUTO_INCREMENT,
  `term_id` int(11) DEFAULT NULL COMMENT 'NULL = default for all terms',
  `installment_number` tinyint(4) NOT NULL,
  `due_months_offset` int(11) NOT NULL DEFAULT 1,
  `installment_label` varchar(80) NOT NULL,
  PRIMARY KEY (`plan_id`),
  UNIQUE KEY `uk_term_inst` (`term_id`,`installment_number`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `term_transition_audit`
--

DROP TABLE IF EXISTS `term_transition_audit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `term_transition_audit` (
  `audit_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `requested_term_code` varchar(32) DEFAULT NULL,
  `target_db_term_code` varchar(32) DEFAULT NULL,
  `target_term_id` int(11) DEFAULT NULL,
  `success` tinyint(1) NOT NULL DEFAULT 0,
  `advanced_count` int(11) NOT NULL DEFAULT 0,
  `forwarded_debt_count` int(11) NOT NULL DEFAULT 0,
  `error_message` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`audit_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `username` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` varchar(30) NOT NULL,
  `email` varchar(255) NOT NULL DEFAULT '',
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vpaa_extensions`
--

DROP TABLE IF EXISTS `vpaa_extensions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vpaa_extensions` (
  `ext_id` int(11) NOT NULL AUTO_INCREMENT,
  `schedule_id` int(11) DEFAULT NULL,
  `faculty_id` int(11) DEFAULT NULL,
  `status` varchar(50) DEFAULT 'PENDING',
  `reason` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ext_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Final view structure for view `student_grades`
--

/*!50001 DROP VIEW IF EXISTS `student_grades`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `student_grades` AS select `g`.`id` AS `grade_id`,`g`.`section_id` AS `schedule_id`,`g`.`student_name` AS `student_name`,`g`.`student_id` AS `student_id`,`g`.`prelim` AS `prelim`,`g`.`midterm` AS `midterm`,`g`.`final_grade` AS `final`,`g`.`semestral_grade` AS `semestral_grade`,`g`.`remarks` AS `remarks`,`g`.`previous_grade` AS `previous_grade`,coalesce(`g`.`status`,'DRAFT') AS `status` from `grades` `g` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-06-05  9:29:19
-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: localhost    Database: eacdb
-- ------------------------------------------------------
-- Server version	5.5.5-10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Dumping data for table `programs`
--

LOCK TABLES `programs` WRITE;
/*!40000 ALTER TABLE `programs` DISABLE KEYS */;
INSERT INTO `programs` VALUES (1,'BSIT','Bachelor of Science in Information Technology',1,'School of Computer Studies',1,'COLLEGE'),(2,'BSCS','Bachelor of Science in Computer Science',1,'School of Computer Studies',1,'COLLEGE'),(3,'BSBio','Bachelor of Science in Biology',2,'School of Arts and Sciences',1,'COLLEGE'),(4,'BSMATH','Bachelor of Science in Mathematics',2,'School of Arts and Sciences',1,'COLLEGE'),(5,'ABCOMM','Bachelor of Arts in Communication',2,'School of Arts and Sciences',1,'COLLEGE'),(6,'BSBA','Bachelor of Science in Business Administration',1,'School of Business',1,'COLLEGE'),(7,'BSA','Bachelor of Science in Accountancy',1,'School of Business',1,'COLLEGE'),(8,'BSED','Bachelor of Secondary Education',2,'School of Education',1,'COLLEGE'),(9,'BEED','Bachelor of Elementary Education',2,'School of Education',1,'COLLEGE'),(10,'BSCrim','Bachelor of Science in Criminology',1,'School of Criminal Justice',1,'COLLEGE'),(11,'BSN','Bachelor of Science in Nursing',2,'School of Health Sciences',1,'COLLEGE'),(12,'BSMT','Bachelor of Science in Medical Technology',2,'School of Health Sciences',1,'COLLEGE'),(13,'BSECE','Bachelor of Science in Electronics Engineering',1,'School of Engineering',1,'COLLEGE'),(14,'BSCE','Bachelor of Science in Civil Engineering',1,'School of Engineering',1,'COLLEGE'),(16,'NNAD','NA Nutrition and Diabetics',NULL,'School of  Nutrition and Diabetics',1,'COLLEGE'),(17,'SAIC','SAS Arts In Com',NULL,'School of Arts and Sciences',1,'COLLEGE'),(19,'BSPSYCH','SAS PSYCHOLOGY',NULL,'School of Arts and Sciences',1,'COLLEGE'),(21,'BBAMIMM','BS Business Ad Major in Marketing Management',NULL,'School of Business Education',1,'COLLEGE'),(22,'BCA','BS Custom Ad',NULL,'School of Business Education',1,'COLLEGE'),(23,'BMIOM','BSBA Major in Operation Management',NULL,'School of Business Education',1,'COLLEGE'),(24,'BAMIFM','Business Ad Major in Financial Management',NULL,'School of Business Education',1,'COLLEGE'),(26,'DM','Dental Medicine',NULL,'School of Dentistry',1,'COLLEGE'),(28,'BSCPE','SET COE',NULL,'School of Engineering and Technology',1,'COLLEGE'),(29,'HM','Hospitality Management',NULL,'School of Hospitality and Tourism Management',1,'COLLEGE'),(30,'BSMedTech','Medtech',NULL,'School of Medical Technology',1,'COLLEGE'),(31,'BSPHARM','SP Science in Pharmacy',NULL,'School of Pharmacy',1,'COLLEGE'),(32,'BSOT','Occupational Therapy',NULL,'School of Physical, Occupational, And Respiratory Therapy_',1,'COLLEGE'),(33,'BSPT','Physical Therapy',NULL,'School of Physical, Occupational, And Respiratory Therapy_',1,'COLLEGE'),(34,'RT','Respi Therapy',NULL,'School of Physical, Occupational, And Respiratory Therapy_',1,'COLLEGE'),(35,'R','Radtech',NULL,'School of Radiologic Technology',1,'COLLEGE'),(36,'BEMIE','BS Educ major in English',NULL,'School of Teacher Education',1,'COLLEGE'),(37,'BEE','BS Elem Education',NULL,'School of Teacher Education',1,'COLLEGE'),(38,'BSEMISS','BS Secondary Educ major in Social Studies',NULL,'School of Teacher Education',1,'COLLEGE');
/*!40000 ALTER TABLE `programs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `academic_terms`
--

LOCK TABLES `academic_terms` WRITE;
/*!40000 ALTER TABLE `academic_terms` DISABLE KEYS */;
INSERT INTO `academic_terms` VALUES (1,'1120242025','A.Y. 2024-2025 - 1st Semester','2024-2025',1,'2024-08-01','2024-12-15','INACTIVE',0),(2,'2120242025','A.Y. 2024-2025 - 2nd Semester','2024-2025',2,'2025-01-15','2025-05-30','INACTIVE',0),(10,'1120252026','A.Y. 2025-2026 - 1st Semester','2025-2026',1,'2025-08-01','2025-12-15','INACTIVE',0),(11,'2120252026','A.Y. 2025-2026 - 2nd Semester','2025-2026',2,'2026-01-15','2026-05-30','ACTIVE',1),(12,'1120262027','A.Y. 2026-2027 - 1st Semester','2026-2027',1,'2026-08-01','2026-12-15','INACTIVE',0),(13,'2120262027','A.Y. 2026-2027 - 2nd Semester','2026-2027',2,'2027-01-15','2027-05-30','INACTIVE',0),(14,'1120272028','A.Y. 2027-2028 - 1st Semester','2027-2028',1,'2027-08-01','2027-12-15','INACTIVE',0),(15,'2120272028','A.Y. 2027-2028 - 2nd Semester','2027-2028',2,'2028-01-15','2028-05-30','INACTIVE',0);
/*!40000 ALTER TABLE `academic_terms` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-06-05  9:24:12
