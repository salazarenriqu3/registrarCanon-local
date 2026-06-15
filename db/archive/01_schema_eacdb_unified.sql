-- =============================================================================
-- EACDB — UNIFIED SCHEMA ONLY (no seed data)
-- =============================================================================

CREATE DATABASE IF NOT EXISTS eacdb
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE eacdb;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- Drop existing tables to ensure a fresh schema with correct columns
DROP TABLE IF EXISTS subject_logs;
DROP TABLE IF EXISTS subject_requests;
DROP TABLE IF EXISTS student_waitlist;
DROP TABLE IF EXISTS grades;
DROP TABLE IF EXISTS student_enlistments;
DROP TABLE IF EXISTS class_schedules;
DROP TABLE IF EXISTS class_sections;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS faculty;
DROP TABLE IF EXISTS academic_terms;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS academic_terms;
DROP TABLE IF EXISTS eac_application_logs;
DROP TABLE IF EXISTS applicants;
DROP TABLE IF EXISTS student_scholarships;
DROP TABLE IF EXISTS scholarship_types;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS applicant_payments;
DROP TABLE IF EXISTS admission_applications;
DROP TABLE IF EXISTS student_ledger;
DROP TABLE IF EXISTS sys_users;
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS system_settings;
DROP TABLE IF EXISTS jp_curriculum_mapping;
DROP TABLE IF EXISTS jp_grades;
DROP TABLE IF EXISTS jp_subject_logs;
DROP TABLE IF EXISTS jp_student_enlistments;
DROP TABLE IF EXISTS jp_class_schedules;
DROP TABLE IF EXISTS jp_class_sections;
DROP TABLE IF EXISTS jp_courses;
DROP TABLE IF EXISTS jp_students;
DROP TABLE IF EXISTS jp_programs;
DROP TABLE IF EXISTS curriculum_courses;
DROP TABLE IF EXISTS curriculum_templates;
DROP TABLE IF EXISTS programs;
DROP TABLE IF EXISTS course_prerequisites;

-- ---------------------------------------------------------------------------
-- 1. Core System & Shared
-- ---------------------------------------------------------------------------

CREATE TABLE system_settings (
    setting_key   VARCHAR(50) PRIMARY KEY,
    setting_value VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE audit_logs (
    log_id   INT AUTO_INCREMENT PRIMARY KEY,
    admin_id INT,
    action   VARCHAR(255),
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE sys_users (
    user_id             INT AUTO_INCREMENT PRIMARY KEY,
    username            VARCHAR(50) UNIQUE,
    password            VARCHAR(255),
    real_name           VARCHAR(100),
    first_name          VARCHAR(100),
    last_name           VARCHAR(100),
    middle_name         VARCHAR(100),
    role                VARCHAR(30),
    program_code        VARCHAR(100),
    year_level          INT DEFAULT 1,
    semester            INT DEFAULT 1,
    term_year           VARCHAR(30) DEFAULT 'SL_1120252026',
    reference_number    VARCHAR(50),
    student_type        VARCHAR(50),
    enrollment_status_type VARCHAR(50),
    scholarship_type    VARCHAR(50) DEFAULT 'NONE',
    discount_percentage   DECIMAL(5,2) DEFAULT 0.00,
    admission_status      VARCHAR(50),
    admission_date        DATETIME,
    enrollment_blocked    TINYINT(1) DEFAULT 0,
    enrollment_start_time DATETIME,
    email               VARCHAR(100),
    mobile              VARCHAR(20),
    street              TEXT,
    city                VARCHAR(100),
    province            VARCHAR(100),
    last_school         VARCHAR(200),
    course_taken        VARCHAR(200),
    form138_path        VARCHAR(255),
    good_moral_path     VARCHAR(255),
    psa_birth_cert_path VARCHAR(255),
    id_picture_path     VARCHAR(255),
    is_active           TINYINT(1) DEFAULT 1,
    status              VARCHAR(30) DEFAULT 'ACTIVE',
    granted_permissions TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE student_ledger (
    ledger_id        INT AUTO_INCREMENT PRIMARY KEY,
    student_id       INT,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    transaction_type VARCHAR(40),
    description      VARCHAR(255),
    debit            DECIMAL(10,2) DEFAULT 0.00,
    credit           DECIMAL(10,2) DEFAULT 0.00,
    CONSTRAINT fk_ledger_student FOREIGN KEY (student_id) REFERENCES sys_users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE admission_applications (
    applicant_id VARCHAR(50) PRIMARY KEY,
    full_name    VARCHAR(100),
    status       VARCHAR(50) DEFAULT 'PENDING'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE applicant_payments (
    payment_id     INT AUTO_INCREMENT PRIMARY KEY,
    applicant_id   VARCHAR(50) NOT NULL,
    payment_amount DECIMAL(10,2) NOT NULL,
    payment_date   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status         VARCHAR(20) DEFAULT 'UNPROCESSED'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE payments (
    payment_id       BIGINT AUTO_INCREMENT PRIMARY KEY,
    transaction_id   VARCHAR(60) NOT NULL,
    or_number        VARCHAR(20),
    reference_number VARCHAR(50) NOT NULL,
    amount           DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    change_amount    DECIMAL(12,2) DEFAULT 0.00,
    payment_method   VARCHAR(60) DEFAULT 'Cash (OTC)',
    semester         INT DEFAULT 1,
    year_level       INT DEFAULT 1,
    term_year        VARCHAR(30),
    remarks          VARCHAR(150),
    payment_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status           VARCHAR(20) NOT NULL DEFAULT 'COMPLETED',
    UNIQUE KEY uk_transaction (transaction_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE scholarship_types (
    type_id         INT AUTO_INCREMENT PRIMARY KEY,
    classification  VARCHAR(50) NOT NULL UNIQUE,
    is_internal     TINYINT(1) DEFAULT 0,
    requires_id     TINYINT(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE student_scholarships (
    scholarship_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id        INT NOT NULL,
    type_id        INT NOT NULL,
    semester_id    INT NOT NULL DEFAULT 1,
    status         VARCHAR(20) DEFAULT 'ACTIVE',
    granted_date   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ss_user FOREIGN KEY (user_id) REFERENCES sys_users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_ss_type FOREIGN KEY (type_id) REFERENCES scholarship_types(type_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- 2. Registrar Portal (eac_applicants)
-- ---------------------------------------------------------------------------

CREATE TABLE applicants (
    id                          BIGINT AUTO_INCREMENT PRIMARY KEY,
    reference_number            VARCHAR(50) UNIQUE,
    applicant_status            VARCHAR(50) DEFAULT 'SUBMITTED',
    application_status          VARCHAR(50) DEFAULT 'ADMISSION_PENDING',
    term_year                   VARCHAR(30),
    first_name                  VARCHAR(100),
    last_name                   VARCHAR(100),
    middle_name                 VARCHAR(100),
    middle_initial              VARCHAR(10),
    middle_name_na              TINYINT(1) DEFAULT 0,
    extension                   VARCHAR(20),
    sex                         VARCHAR(10),
    dob                         VARCHAR(20),
    place_of_birth              TEXT,
    civil_status                VARCHAR(30),
    religion                    VARCHAR(60),
    nationality                 VARCHAR(60),
    citizenship                 VARCHAR(60),
    age                         INT,
    four_ps                     TINYINT(1) DEFAULT 0,
    indigenous                  TINYINT(1) DEFAULT 0,
    international_student       TINYINT(1) DEFAULT 0,
    email                       VARCHAR(150),
    email_verified              TINYINT(1) DEFAULT 0,
    mobile                      VARCHAR(30),
    landline                    VARCHAR(30),
    street                      TEXT,
    city                        VARCHAR(100),
    province                    VARCHAR(100),
    zip                         VARCHAR(10),
    emergency_contact_name      VARCHAR(150),
    emergency_contact_mobile    VARCHAR(30),
    emergency_contact_relationship VARCHAR(60),
    father_name                 VARCHAR(150),
    father_occupation           VARCHAR(100),
    father_contact              VARCHAR(30),
    father_address              TEXT,
    mother_name                 VARCHAR(150),
    mother_occupation           VARCHAR(100),
    mother_contact              VARCHAR(30),
    mother_address              TEXT,
    guardian_name               VARCHAR(150),
    guardian_contact            VARCHAR(30),
    guardian_relationship         VARCHAR(60),
    sibling_count               INT,
    sibling_order               VARCHAR(30),
    monthly_income              VARCHAR(30),
    academic_level              VARCHAR(30),
    elementary_school           TEXT,
    elementary_address          TEXT,
    elementary_year             VARCHAR(20),
    jhs_school                  TEXT,
    jhs_address                 TEXT,
    jhs_year                    VARCHAR(20),
    shs_school                  TEXT,
    shs_address                 TEXT,
    shs_track                   VARCHAR(60),
    shs_year                    VARCHAR(20),
    last_school                 TEXT,
    last_school_year            VARCHAR(20),
    course_taken                VARCHAR(100),
    program1                    VARCHAR(20),
    program2                    VARCHAR(20),
    form138_path                VARCHAR(255),
    form138_verified            TINYINT(1) DEFAULT 0,
    good_moral_path             VARCHAR(255),
    good_moral_verified         TINYINT(1) DEFAULT 0,
    psa_birth_cert_path         VARCHAR(255),
    psa_birth_cert_verified     TINYINT(1) DEFAULT 0,
    id_picture_path             VARCHAR(255),
    id_picture_verified         TINYINT(1) DEFAULT 0,
    marriage_cert_path          VARCHAR(255),
    marriage_cert_verified      TINYINT(1) DEFAULT 0,
    other_doc_path              VARCHAR(255),
    other_doc_verified          TINYINT(1) DEFAULT 0,
    interview_date              TEXT,
    interview_time              TEXT,
    interview_link              TEXT,
    remarks                     TEXT,
    revised                     TINYINT(1) DEFAULT 0,
    reopen_until                DATETIME,
    created_at                  DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at                  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- Enrollment3 entity fields
    enrollment_start_time       DATETIME        DEFAULT NULL,
    registration_date           DATETIME        DEFAULT NULL,
    semester                    INT             DEFAULT 1,
    year_level                  INT             DEFAULT 1,
    scholarship_type            VARCHAR(50)     DEFAULT 'NONE'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE eac_application_logs (
    log_id        INT AUTO_INCREMENT PRIMARY KEY,
    ref_no        VARCHAR(30),
    action        VARCHAR(100),
    performed_by  VARCHAR(60),
    remarks       TEXT,
    log_timestamp DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- 3. Enrollment Subsystem (canonical shared tables)
-- ---------------------------------------------------------------------------

CREATE TABLE users (
    id       BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role     VARCHAR(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE departments (
    department_id      INT AUTO_INCREMENT PRIMARY KEY,
    department_code    VARCHAR(10)  NOT NULL UNIQUE,
    department_name    VARCHAR(100) NOT NULL,
    faculty_id         INT          DEFAULT NULL,  -- department head (set after faculty is inserted)
    building_location  VARCHAR(200),
    created_at         DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE academic_terms (
    term_id    INT AUTO_INCREMENT PRIMARY KEY,
    term_code  VARCHAR(20) NOT NULL,
    term_name  VARCHAR(50),
    start_date DATE NOT NULL,
    end_date   DATE NOT NULL,
    status     VARCHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS academic_terms;

CREATE TABLE academic_terms (
    term_id         INT AUTO_INCREMENT PRIMARY KEY,
    term_code       VARCHAR(20) UNIQUE,
    term_name       VARCHAR(100) NOT NULL,
    academic_year   VARCHAR(20),
    semester_number INT          DEFAULT 1,
    start_date      DATE,
    end_date        DATE,
    status          VARCHAR(20)  NOT NULL DEFAULT 'INACTIVE',
    is_active       TINYINT(1)   NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE faculty (

    faculty_id         INT AUTO_INCREMENT PRIMARY KEY,
    employee_number    VARCHAR(20) NOT NULL UNIQUE,
    first_name         VARCHAR(50) NOT NULL,
    last_name          VARCHAR(50) NOT NULL,
    email              VARCHAR(100) UNIQUE,
    department_id      INT,
    employment_type    VARCHAR(20),
    max_teaching_units INT DEFAULT 18,
    active_status      TINYINT(1) DEFAULT 1,
    CONSTRAINT fk_faculty_dept FOREIGN KEY (department_id) REFERENCES departments(department_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE rooms (
    room_id       INT AUTO_INCREMENT PRIMARY KEY,
    room_code     VARCHAR(20) NOT NULL UNIQUE,
    building_name VARCHAR(50),
    capacity      INT,
    room_type     VARCHAR(20) DEFAULT 'Lecture',
    active_status TINYINT(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE courses (
    course_id                     INT AUTO_INCREMENT PRIMARY KEY,
    course_code                   VARCHAR(20)  NOT NULL UNIQUE,
    course_title                  VARCHAR(100) NOT NULL,
    department_id                 INT NOT NULL,
    description                   TEXT,
    credit_units                  INT NOT NULL DEFAULT 3,
    lecture_units                 INT          DEFAULT NULL,
    lab_units                     INT          DEFAULT NULL,
    lecture_hours_per_week        INT          DEFAULT 3,
    lab_hours_per_week            INT          DEFAULT 0,
    max_students                  INT          DEFAULT 40,
    course_type                   VARCHAR(20),         -- 'Lecture','Laboratory','Mixed'
    is_coordinator_based          TINYINT(1)   NOT NULL DEFAULT 0,
    coordinator_equivalent_units  INT          DEFAULT NULL,
    active_status                 TINYINT(1)   DEFAULT 1,
    CONSTRAINT fk_course_dept FOREIGN KEY (department_id) REFERENCES departments(department_id),
    CONSTRAINT chk_coordinator CHECK (
        is_coordinator_based = 0 AND coordinator_equivalent_units IS NULL
        OR is_coordinator_based = 1 AND coordinator_equivalent_units IS NOT NULL AND coordinator_equivalent_units > 0
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE class_sections (
    section_id      INT AUTO_INCREMENT PRIMARY KEY,
    course_id       INT NOT NULL,
    term_id         INT NOT NULL,
    section_code    VARCHAR(32) NOT NULL,
    faculty_id      INT,
    max_capacity    INT DEFAULT 40,
    section_status  VARCHAR(20) DEFAULT 'Planning',
    semester_number INT         DEFAULT NULL,
    UNIQUE KEY uq_term_course_section (term_id, course_id, section_code),
    KEY idx_sections_term (term_id),
    CONSTRAINT fk_cs_course FOREIGN KEY (course_id) REFERENCES courses(course_id),
    CONSTRAINT fk_cs_term FOREIGN KEY (term_id) REFERENCES academic_terms(term_id),
    CONSTRAINT fk_cs_faculty FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE class_schedules (
    schedule_id   INT AUTO_INCREMENT PRIMARY KEY,
    section_id    INT NOT NULL,
    room_id       INT,
    faculty_id    INT,
    day_of_week   INT,
    start_time    TIME,
    end_time      TIME,
    schedule_type VARCHAR(20) DEFAULT 'Lecture',
    CONSTRAINT fk_sch_section FOREIGN KEY (section_id) REFERENCES class_sections(section_id),
    CONSTRAINT fk_sch_room FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    CONSTRAINT fk_sch_faculty FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE student_enlistments (
    enlistment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id    INT NOT NULL,
    course_id     INT NOT NULL,
    section_id    INT NOT NULL,
    enlisted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY idx_se_student_course (student_id, course_id),
    CONSTRAINT fk_se_student FOREIGN KEY (student_id) REFERENCES sys_users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_se_course FOREIGN KEY (course_id) REFERENCES courses(course_id),
    CONSTRAINT fk_se_section FOREIGN KEY (section_id) REFERENCES class_sections(section_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE grades (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_id    INT NOT NULL,
    course_id     INT NOT NULL,
    grade         DOUBLE,
    status        VARCHAR(20),
    date_recorded DATETIME,
    CONSTRAINT fk_g_student FOREIGN KEY (student_id) REFERENCES sys_users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_g_course FOREIGN KEY (course_id) REFERENCES courses(course_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE student_waitlist (
    waitlist_id   BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_id    INT NOT NULL,
    course_id     INT NOT NULL,
    status        VARCHAR(30) DEFAULT 'WAITING',
    priority_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_wl_student FOREIGN KEY (student_id) REFERENCES sys_users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_wl_course FOREIGN KEY (course_id) REFERENCES courses(course_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE subject_requests (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_id   INT NOT NULL,
    course_id    INT NOT NULL,
    section_id   INT,
    status       VARCHAR(20) DEFAULT 'PENDING',
    request_date DATETIME,
    reason       VARCHAR(500),
    CONSTRAINT fk_sr_student FOREIGN KEY (student_id) REFERENCES sys_users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_sr_course FOREIGN KEY (course_id) REFERENCES courses(course_id),
    CONSTRAINT fk_sr_section FOREIGN KEY (section_id) REFERENCES class_sections(section_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE subject_logs (
    id             BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_number VARCHAR(50),
    action         VARCHAR(20),
    course_code    VARCHAR(20),
    course_title   VARCHAR(200),
    `timestamp`    DATETIME,
    performed_by   VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- 4. Canonical Curriculum & Program Tables
-- ---------------------------------------------------------------------------

CREATE TABLE programs (
    program_id    INT AUTO_INCREMENT PRIMARY KEY,
    program_code  VARCHAR(20)  NOT NULL UNIQUE,
    program_name  VARCHAR(150),
    department_id INT          DEFAULT NULL,
    school_name   VARCHAR(100),
    active_status TINYINT(1)   NOT NULL DEFAULT 1,
    level         VARCHAR(32)  NULL,
    CONSTRAINT fk_prog_dept FOREIGN KEY (department_id)
        REFERENCES departments(department_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE curriculum_templates (
    curriculum_id   INT AUTO_INCREMENT PRIMARY KEY,
    program_id      INT NOT NULL,
    curriculum_name VARCHAR(100),
    academic_year   VARCHAR(20),
    version_number  INT         NOT NULL DEFAULT 1,
    approval_status VARCHAR(20) NOT NULL DEFAULT 'Draft',
    is_active       TINYINT(1)  NOT NULL DEFAULT 0,
    CONSTRAINT fk_ct_program FOREIGN KEY (program_id)
        REFERENCES programs(program_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE curriculum_courses (
    curriculum_course_id INT AUTO_INCREMENT PRIMARY KEY,
    curriculum_id        INT NOT NULL,
    course_id            INT NOT NULL,
    year_level           INT NOT NULL,
    semester_number      INT NOT NULL,
    is_required          TINYINT(1) NOT NULL DEFAULT 1,
    UNIQUE KEY uq_curr_course (curriculum_id, course_id, year_level, semester_number),
    CONSTRAINT fk_cc_curriculum FOREIGN KEY (curriculum_id)
        REFERENCES curriculum_templates(curriculum_id) ON DELETE CASCADE,
    CONSTRAINT fk_cc_course FOREIGN KEY (course_id)
        REFERENCES courses(course_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE course_prerequisites (
    prerequisite_id        INT AUTO_INCREMENT PRIMARY KEY,
    course_id              INT NOT NULL,
    prerequisite_course_id INT NOT NULL,
    created_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_prereq (course_id, prerequisite_course_id),
    KEY idx_cp_prereq (prerequisite_course_id),
    CONSTRAINT fk_cp_course FOREIGN KEY (course_id)
        REFERENCES courses(course_id) ON DELETE CASCADE,
    CONSTRAINT fk_cp_prereq_course FOREIGN KEY (prerequisite_course_id)
        REFERENCES courses(course_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Dept-head FK (deferred to avoid forward-reference during CREATE)
ALTER TABLE departments
    ADD CONSTRAINT fk_dept_head FOREIGN KEY (faculty_id)
        REFERENCES faculty(faculty_id) ON DELETE SET NULL;

SET FOREIGN_KEY_CHECKS = 1;
