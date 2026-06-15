DROP DATABASE IF EXISTS registrar_db_v2;
CREATE DATABASE registrar_db_v2;
USE registrar_db_v2;

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- EAC REGISTRAR SYSTEM — COMPLETE DATABASE SETUP SCRIPT
-- Database: registrar_db_v2
-- ============================================================
-- INSTRUCTIONS: Run this entire file ONCE on your school PC
-- using MySQL Workbench (Database > Run SQL Script).
-- It creates the database, all tables, all seed data,
-- and demo student accounts. Nothing else is needed.
-- ============================================================

-- Step 0: Create and select the database
CREATE DATABASE IF NOT EXISTS registrar_db_v2
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;



-- ============================================================
-- SECTION 1: CORE SYSTEM TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS system_settings (
    setting_key   VARCHAR(50) PRIMARY KEY,
    setting_value VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO system_settings VALUES
    ('PRELIM_START',      '2025-01-01'),
    ('PRELIM_END',        '2026-12-31'),
    ('MIDTERM_START',     '2025-01-01'),
    ('MIDTERM_END',       '2026-12-31'),
    ('FINAL_START',       '2025-01-01'),
    ('FINAL_END',         '2026-12-31'),
    ('PRELIM_OVERRIDE',   'FORCE_OPEN'),
    ('MIDTERM_OVERRIDE',  'FORCE_OPEN'),
    ('FINAL_OVERRIDE',    'FORCE_OPEN');

CREATE TABLE IF NOT EXISTS audit_logs (
    log_id   INT AUTO_INCREMENT PRIMARY KEY,
    admin_id INT,
    action   VARCHAR(255),
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- SECTION 2: MASTER USER TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS sys_users (
    user_id             INT AUTO_INCREMENT PRIMARY KEY,
    username            VARCHAR(50) UNIQUE,
    password            VARCHAR(255),
    real_name           VARCHAR(100),
    role                VARCHAR(30),
    program_code        VARCHAR(20),
    year_level          INT DEFAULT 1,
    semester            INT DEFAULT 1,
    term_year           VARCHAR(30) DEFAULT 'SL_1120252026',
    is_active           TINYINT(1) DEFAULT 1,
    status              VARCHAR(30) DEFAULT 'ACTIVE',
    granted_permissions TEXT,
    admission_status    VARCHAR(50),
    admission_date      DATETIME,
    -- Financial/Scholarship columns (from scholar_integration_setup.sql)
    scholarship_type    VARCHAR(20)    NOT NULL DEFAULT 'NONE',
    discount_percentage DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
    enrollment_blocked  TINYINT(1)   NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- SECTION 3: LEGACY GRADING TABLES (Registrar engine)
-- ============================================================

CREATE TABLE IF NOT EXISTS curriculum_catalog (
    course_code VARCHAR(20) PRIMARY KEY,
    description VARCHAR(150),
    units       INT DEFAULT 3
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS class_schedules (
    schedule_id  INT AUTO_INCREMENT PRIMARY KEY,
    course_code  VARCHAR(20),
    section      VARCHAR(20),
    faculty_id   INT,
    day_of_week  VARCHAR(20),
    start_time   TIME,
    end_time     TIME,
    status       VARCHAR(50) DEFAULT 'OPEN'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS student_grades (
    grade_id     INT AUTO_INCREMENT PRIMARY KEY,
    schedule_id  INT,
    student_name VARCHAR(100),
    student_id   INT,
    prelim       VARCHAR(10),
    midterm      VARCHAR(10),
    final_grade  VARCHAR(10),
    status       VARCHAR(50) DEFAULT 'DRAFT'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS vpaa_extensions (
    ext_id      INT AUTO_INCREMENT PRIMARY KEY,
    schedule_id INT,
    faculty_id  INT,
    status      VARCHAR(50) DEFAULT 'PENDING',
    reason      VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- SECTION 4: FINANCE & ADMISSIONS TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS student_ledger (
    ledger_id        INT AUTO_INCREMENT PRIMARY KEY,
    student_id       INT,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    transaction_type VARCHAR(20),
    description      VARCHAR(255),
    debit            DECIMAL(10,2) DEFAULT 0.00,
    credit           DECIMAL(10,2) DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS admissions (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    first_name       VARCHAR(100),
    last_name        VARCHAR(100),
    email            VARCHAR(150),
    phone            VARCHAR(30),
    program_applied  VARCHAR(30),
    admission_status VARCHAR(50) DEFAULT 'PENDING',
    application_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    term_year        VARCHAR(30) DEFAULT 'SL_1120252026'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS admission_applications (
    applicant_id VARCHAR(50) PRIMARY KEY,
    full_name    VARCHAR(100),
    status       VARCHAR(50) DEFAULT 'PENDING'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS applicant_payments (
    payment_id     INT AUTO_INCREMENT PRIMARY KEY,
    applicant_id   VARCHAR(50) NOT NULL,
    payment_amount DECIMAL(10,2) NOT NULL,
    payment_date   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status         VARCHAR(20) DEFAULT 'UNPROCESSED'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- SECTION 5: EAC APPLICANT PORTAL TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS eac_applicants (
    ref_no                      VARCHAR(30) PRIMARY KEY,
    applicant_status            VARCHAR(50) DEFAULT 'SUBMITTED',
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
    guardian_relationship       VARCHAR(60),
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
    updated_at                  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS eac_application_logs (
    log_id       INT AUTO_INCREMENT PRIMARY KEY,
    ref_no       VARCHAR(30),
    action       VARCHAR(100),
    performed_by VARCHAR(60),
    remarks      TEXT,
    log_timestamp DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- SECTION 6: JAYPEE ENGINE TABLES (Prefixed jp_)
-- ============================================================

CREATE TABLE IF NOT EXISTS jp_programs (
    program_code VARCHAR(20) PRIMARY KEY,
    program_name VARCHAR(150),
    school_name  VARCHAR(100),
    category     VARCHAR(60)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS jp_students (
    id             BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_number VARCHAR(50) UNIQUE,
    first_name     VARCHAR(50),
    last_name      VARCHAR(50),
    email          VARCHAR(100),
    program_code   VARCHAR(20),
    current_year   INT DEFAULT 1,
    status         VARCHAR(30) DEFAULT 'ADMITTED'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS jp_courses (
    course_id             INT AUTO_INCREMENT PRIMARY KEY,
    course_code           VARCHAR(20),
    course_title          VARCHAR(100),
    units                 INT,
    program_code          VARCHAR(20),
    prerequisite_course_id INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS jp_class_sections (
    section_id   INT AUTO_INCREMENT PRIMARY KEY,
    course_id    INT,
    section_name VARCHAR(20),
    max_capacity INT DEFAULT 40
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS jp_class_schedules (
    schedule_id  INT AUTO_INCREMENT PRIMARY KEY,
    section_id   INT,
    course_id    INT,
    day_of_week  VARCHAR(20),
    start_time   TIME,
    end_time     TIME,
    room         VARCHAR(30),
    faculty_id   INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS jp_student_enlistments (
    enlistment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id    BIGINT,
    course_id     INT,
    section_id    INT,
    status        VARCHAR(20) DEFAULT 'ENROLLED',
    enlisted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS jp_subject_logs (
    log_id     INT AUTO_INCREMENT PRIMARY KEY,
    student_id BIGINT,
    course_id  INT,
    action     VARCHAR(20),
    log_date   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS jp_grades (
    grade_id   INT AUTO_INCREMENT PRIMARY KEY,
    student_id BIGINT,
    course_id  INT,
    status     VARCHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS jp_curriculum_mapping (
    mapping_id   INT AUTO_INCREMENT PRIMARY KEY,
    program_code VARCHAR(20),
    course_id    INT,
    year_level   INT,
    semester     INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- SECTION 7: PAYMENTS TABLE (from scholar_integration_setup.sql)
-- ============================================================

CREATE TABLE IF NOT EXISTS payments (
    payment_id       BIGINT         AUTO_INCREMENT PRIMARY KEY,
    transaction_id   VARCHAR(60)    NOT NULL,
    or_number        VARCHAR(20)    DEFAULT NULL,
    reference_number VARCHAR(50)    NOT NULL,
    amount           DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    payment_method   VARCHAR(60)    DEFAULT 'Cash (OTC)',
    semester         INT            DEFAULT 1,
    year_level       INT            DEFAULT 1,
    term_year        VARCHAR(30)    DEFAULT NULL,
    remarks          VARCHAR(150)   DEFAULT NULL,
    payment_date     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status           VARCHAR(20)    NOT NULL DEFAULT 'COMPLETED',
    UNIQUE KEY uk_transaction (transaction_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- SECTION 8: SYSTEM ACCOUNTS
-- ============================================================
-- Note: The Spring Boot app (DatabaseSetupService) will auto-reset
-- the passwords for 'admin' and 'prof' to BCrypt('1234') on first startup.
-- All other accounts below use the same password: 1234 (plain stored as
-- marker — the app will bcrypt it on login via PasswordEncoder).
-- For immediate login, set real BCrypt hashes below if needed,
-- or use 'admin'/'1234' and 'prof'/'1234' which are auto-managed.

INSERT IGNORE INTO sys_users (username, password, real_name, role, is_active) VALUES
    -- Auto-managed by the app (use password: 1234)
    ('admin', '$2a$10$PLACEHOLDER', 'System Administrator', 'Admin', 1),
    ('prof',  '$2a$10$PLACEHOLDER', 'Dr. Maria Santos',     'Faculty', 1),
    ('prof2', '$2a$10$PLACEHOLDER', 'Prof. Jose Dela Cruz', 'Faculty', 1),
    ('prof3', '$2a$10$PLACEHOLDER', 'Prof. Lena Aquino',    'Faculty', 1);

-- IMPORTANT: Real BCrypt hash for password '1234'
-- The app auto-generates this for 'admin' and 'prof' on startup.
-- For prof2, prof3, and all demo accounts run this after first startup:
-- UPDATE sys_users SET password = (SELECT password FROM sys_users WHERE username = 'admin') WHERE username IN ('prof2','prof3');

-- ============================================================
-- SECTION 9: COURSE CATALOG (Legacy Grading Engine)
-- ============================================================

INSERT IGNORE INTO curriculum_catalog (course_code, description, units) VALUES
    ('CC101',   'Introduction to Computing',          3),
    ('CC102',   'Computer Programming 1',             3),
    ('CC103',   'Computer Programming 2',             3),
    ('MATH101', 'Mathematics in the Modern World',    3),
    ('NSTP101', 'National Service Training Program',  3),
    ('PE101',   'Physical Education 1',               2),
    ('ENGL101', 'Purposive Communication',            3),
    ('SCI101',  'Natural Science',                    3);

-- ============================================================
-- SECTION 10: JP PROGRAMS & COURSES
-- ============================================================

INSERT IGNORE INTO jp_programs (program_code, program_name, school_name, category) VALUES
    ('BSCS', 'Bachelor of Science in Computer Science', 'EAC', 'College'),
    ('BSIT', 'Bachelor of Science in Information Technology', 'EAC', 'College'),
    ('BSN',  'Bachelor of Science in Nursing', 'EAC', 'College');

INSERT IGNORE INTO jp_courses (course_code, course_title, units, program_code, prerequisite_course_id) VALUES
    ('CS101',   'Introduction to Computing',          3, 'BSCS', NULL),
    ('CS102',   'Computer Programming 1',             3, 'BSCS', NULL),
    ('CS103',   'Computer Programming 2',             3, 'BSCS', NULL),
    ('CS104',   'Data Structures and Algorithms',     3, 'BSCS', NULL),
    ('CS105',   'Web Development 1',                  3, 'BSCS', NULL),
    ('MATH101', 'Mathematics in the Modern World',    3, 'BSCS', NULL),
    ('ENGL101', 'Purposive Communication',            3, 'BSCS', NULL),
    ('PE101',   'Physical Education 1',               2, 'BSCS', NULL),
    ('NSTP101', 'National Service Training Program',  3, 'BSCS', NULL);

-- Curriculum Mapping: BSCS Year 1, Sem 1
INSERT IGNORE INTO jp_curriculum_mapping (program_code, course_id, year_level, semester)
SELECT 'BSCS', course_id, 1, 1 FROM jp_courses WHERE course_code IN ('CS101','CS102','MATH101','ENGL101','PE101');
-- BSCS Year 1, Sem 2
INSERT IGNORE INTO jp_curriculum_mapping (program_code, course_id, year_level, semester)
SELECT 'BSCS', course_id, 1, 2 FROM jp_courses WHERE course_code IN ('CS103','CS104','CS105','NSTP101');

-- Class sections
INSERT IGNORE INTO jp_class_sections (course_id, section_name, max_capacity)
SELECT course_id, 'CS-1A', 40 FROM jp_courses;

-- Class schedules (linked to sections)
INSERT INTO jp_class_schedules (section_id, course_id, day_of_week, start_time, end_time, room, faculty_id)
SELECT s.section_id, s.course_id, 'Monday', '08:00:00', '11:00:00', 'Room 301',
       (SELECT user_id FROM sys_users WHERE username = 'prof' LIMIT 1)
FROM jp_class_sections s
JOIN jp_courses c ON s.course_id = c.course_id WHERE c.course_code = 'CS101';

INSERT INTO jp_class_schedules (section_id, course_id, day_of_week, start_time, end_time, room, faculty_id)
SELECT s.section_id, s.course_id, 'Tuesday', '09:00:00', '12:00:00', 'Room 302',
       (SELECT user_id FROM sys_users WHERE username = 'prof' LIMIT 1)
FROM jp_class_sections s
JOIN jp_courses c ON s.course_id = c.course_id WHERE c.course_code = 'CS102';

-- Legacy grading class schedules
INSERT IGNORE INTO class_schedules (course_code, section, faculty_id, day_of_week, start_time, end_time, status) VALUES
    ('CC101',  'BSCS-1A', (SELECT user_id FROM sys_users WHERE username = 'prof'  LIMIT 1), 'Monday-Wednesday',  '07:00:00', '09:00:00', 'OPEN'),
    ('CC102',  'BSCS-1A', (SELECT user_id FROM sys_users WHERE username = 'prof'  LIMIT 1), 'Tuesday-Thursday',  '09:00:00', '12:00:00', 'OPEN'),
    ('CC103',  'BSIT-1A', (SELECT user_id FROM sys_users WHERE username = 'prof'  LIMIT 1), 'Friday',            '13:00:00', '16:00:00', 'OPEN'),
    ('MATH101','BSCS-1A', (SELECT user_id FROM sys_users WHERE username = 'prof2' LIMIT 1), 'Monday-Wednesday',  '13:00:00', '15:00:00', 'OPEN'),
    ('ENGL101','BSCS-1A', (SELECT user_id FROM sys_users WHERE username = 'prof2' LIMIT 1), 'Tuesday-Thursday',  '07:00:00', '09:00:00', 'OPEN'),
    ('SCI101', 'BSIT-1A', (SELECT user_id FROM sys_users WHERE username = 'prof3' LIMIT 1), 'Monday',            '09:00:00', '12:00:00', 'OPEN'),
    ('PE101',  'BSCS-1A', (SELECT user_id FROM sys_users WHERE username = 'prof3' LIMIT 1), 'Friday',            '07:00:00', '09:00:00', 'OPEN');

-- ============================================================
-- SECTION 11: EAC APPLICANTS (Seeded from DatabaseSetupService)
-- ============================================================

INSERT IGNORE INTO eac_applicants (ref_no,applicant_status,term_year,first_name,last_name,middle_name,middle_initial,middle_name_na,extension,sex,dob,place_of_birth,civil_status,religion,nationality,citizenship,age,four_ps,indigenous,international_student,email,email_verified,mobile,landline,street,city,province,zip,emergency_contact_name,emergency_contact_mobile,emergency_contact_relationship,father_name,father_occupation,father_contact,father_address,mother_name,mother_occupation,mother_contact,mother_address,guardian_name,guardian_contact,guardian_relationship,sibling_count,sibling_order,monthly_income,academic_level,elementary_school,elementary_address,elementary_year,jhs_school,jhs_address,jhs_year,shs_school,shs_address,shs_track,shs_year,last_school,last_school_year,course_taken,program1,program2,form138_path,form138_verified,good_moral_path,good_moral_verified,psa_birth_cert_path,psa_birth_cert_verified,id_picture_path,id_picture_verified,marriage_cert_path,marriage_cert_verified,other_doc_path,other_doc_verified,remarks,created_at) VALUES
    ('EAC-12E89F39','ENROLLED','2024-2025_1st','Maron','Javier','Soriano','S.',0,'','M','2004-02-13','Manila','single','catholic','Filipino','Filipino',22,0,0,0,'maronthegreatt@gmail.com',1,'09664170568','','1665 Int 13 J Zamora St. Paco Manila','Manila','Manila','1007','Maron Mikhail Javier','09123456789','Me','Marlon Javier','Chef','09987654321','1665 Int 13 J Zamora, Manila','Maricel Javier','House Wife','09123456789','1665 Int 13 J Zamora, Manila','','','',2,'eldest','below_10k','college','Justo Lukban Elem School','','2015-2016','Manuel A. Roxas HS','','2019-2020','Universidad De Manila','','GAS','2021-2022','','','','BSCS','BSIT','simulated/form138_EAC-12E89F39.pdf',1,'simulated/goodmoral_EAC-12E89F39.pdf',1,'simulated/psa_EAC-12E89F39.pdf',1,'simulated/idpic_EAC-12E89F39.jpg',1,NULL,0,NULL,0,NULL,'2026-02-13 12:23:40'),
    ('EAC-4A09644A','QUALIFIED FOR ENROLLMENT','2025-2026_2nd','Clarissa','Reyes','Marie','M.',0,'','F','2004-03-19','Quezon City','single','Catholic','Filipino','By Birth',21,0,0,0,'clarissa.reyes@gmail.com',1,'09175553241','','45 Sampaguita St. Brgy. Holy Spirit','Quezon City','Metro Manila','1127','Elena Reyes','09175551234','Mother','Roberto Reyes','Engineer','09175559876','45 Sampaguita St., Quezon City','Elena Reyes','Teacher','09175551234','45 Sampaguita St., Quezon City','','','',2,'eldest','10k_to_20k','College','Commonwealth Elem School','','2016','Batasan Hills NHS','','2020','San Bartolome HS','','HUMSS','2022','','','','BSN','BSCS','simulated/form138_EAC-4A09644A.pdf',1,'simulated/goodmoral_EAC-4A09644A.pdf',1,'simulated/psa_EAC-4A09644A.pdf',1,'simulated/idpic_EAC-4A09644A.jpg',1,'simulated/marrcert_EAC-4A09644A.pdf',1,'simulated/otherdoc_EAC-4A09644A.pdf',1,NULL,'2026-03-05 10:59:56'),
    ('EAC-F4F9B68D','QUALIFIED FOR ENROLLMENT','2025-2026_1st','Franklin','Moris','','',1,'','M','2003-02-18','Manila','single','Christian','Filipino','Filipino',23,0,0,0,'maronthegreatt@gmail.com',1,'09664170568','','1665 Int. 13 J. Zamora St.','Manila','Manila','1007','Maron Mikhail Javier','09123456789','Mother','Bush Moris','Cloud Engineer','09987654321','1665 Int. 13 J. Zamora, Manila','Analiza Moris','House Wife','09123456789','1665 Int. 13 J. Zamora, Manila','','','',1,'youngest','below_10k','College','Justo Lukban Elem School','1234 INT 14 I Test St.','2016','Manuel A. Roxas HS','1234 INT 14 I Test St.','2020','Universidad De Manila','1234 INT 14 I Test St.','GAS','2022','','','','BSCS','BSIT','simulated/form138_EAC-F4F9B68D.pdf',1,'simulated/goodmoral_EAC-F4F9B68D.pdf',1,'simulated/psa_EAC-F4F9B68D.pdf',1,'simulated/idpic_EAC-F4F9B68D.jpg',1,'simulated/marrcert_EAC-F4F9B68D.pdf',1,NULL,0,NULL,'2026-03-24 17:12:05'),
    ('EAC-1950DF37','QUALIFIED FOR ENROLLMENT','2025-2026_1st','Jessa Mae','Santos','Cruz','C.',0,'','F','2004-10-11','Pasig City','single','Christian','Filipino','Filipino',21,0,0,0,'jessamae.santos@gmail.com',0,'09281234567','','78 Rosario St. Brgy. Kapitolyo','Pasig City','Metro Manila','1603','Maria Santos','09281239876','Mother','Carlos Santos','OFW Seaman','09281235678','78 Rosario St., Pasig City','Maria Santos','Dressmaker','09281239876','78 Rosario St., Pasig City','Lita Cruz','09281237654','Aunt',1,'only','below_10k','College','Rizal Elem School','Rosario Ave, Pasig','2016','Pasig City Science HS','Rosario Ave, Pasig','2020','Sta. Lucia HS','Rosario Ave, Pasig','ABM','2022','','','','BSN','BSIT','simulated/form138_EAC-1950DF37.pdf',1,'simulated/goodmoral_EAC-1950DF37.pdf',1,'simulated/psa_EAC-1950DF37.pdf',1,'simulated/idpic_EAC-1950DF37.jpg',1,'simulated/marrcert_EAC-1950DF37.pdf',1,'simulated/otherdoc_EAC-1950DF37.pdf',1,NULL,'2026-03-24 17:29:14'),
    ('EAC-32987A96','REJECTED','2025-2026_1st','Denise','Torres','','',1,'','F','2004-03-18','Caloocan City','single','Christian','Filipino','Filipino',22,0,0,0,'denise.torres@gmail.com',1,'09359876543','','12 Libis St. Brgy. 171','Caloocan City','Metro Manila','1400','Rosa Torres','09359876000','Mother','Andres Torres','Driver','09359871111','12 Libis St., Caloocan City','Rosa Torres','Vendor','09359876000','12 Libis St., Caloocan City','','','',1,'only','below_10k','College','Caloocan North Elem School','Libis St, Caloocan','2016','Caloocan NHS','Libis St, Caloocan','2020','Caloocan City Senior HS','Libis St, Caloocan','ABM','2022','','','','BSN','BSCS','simulated/form138_EAC-32987A96.pdf',1,'simulated/goodmoral_EAC-32987A96.pdf',1,'simulated/psa_EAC-32987A96.pdf',1,'simulated/idpic_EAC-32987A96.jpg',0,NULL,0,NULL,0,'Did not meet admission policy criteria','2026-03-24 17:36:34');

-- Application logs
INSERT IGNORE INTO eac_application_logs (log_id,ref_no,action,performed_by,remarks,log_timestamp) VALUES
    (1,'EAC-12E89F39','SUBMITTED','anonymousUser','Initial application submission.','2026-02-13 12:20:03'),
    (2,'EAC-12E89F39','EMAIL VERIFIED','anonymousUser','Student verified their email address.','2026-02-13 12:20:27'),
    (3,'EAC-12E89F39','DEFICIENCY NOTIFIED','admin','','2026-02-13 12:23:15'),
    (4,'EAC-12E89F39','DOC VERIFIED','admin','Verified form138','2026-02-13 12:23:27'),
    (5,'EAC-12E89F39','DOC VERIFIED','admin','Verified goodMoral','2026-02-13 12:23:28'),
    (6,'EAC-12E89F39','DOC VERIFIED','admin','Verified psaBirthCert','2026-02-13 12:23:30'),
    (7,'EAC-12E89F39','DOC VERIFIED','admin','Verified idPicture','2026-02-13 12:23:31'),
    (8,'EAC-12E89F39','ENROLLED','admin',NULL,'2026-02-13 12:23:40'),
    (9,'EAC-4A09644A','SUBMITTED','encoder','Initial application submission.','2026-03-05 10:59:56'),
    (10,'EAC-4A09644A','DOC VERIFIED','admin','Verified form138','2026-03-05 11:20:55'),
    (11,'EAC-4A09644A','DOC VERIFIED','admin','Verified goodMoral','2026-03-05 11:20:59'),
    (12,'EAC-4A09644A','EMAIL VERIFIED','anonymousUser','Student verified their email address.','2026-03-24 16:37:50'),
    (38,'EAC-4A09644A','QUALIFIED FOR ENROLLMENT','admin',NULL,'2026-03-24 17:38:09'),
    (17,'EAC-F4F9B68D','SUBMITTED','anonymousUser','Initial application submission.','2026-03-24 17:12:05'),
    (28,'EAC-F4F9B68D','QUALIFIED FOR ENROLLMENT','encoder',NULL,'2026-03-24 17:13:27'),
    (29,'EAC-1950DF37','SUBMITTED','anonymousUser','Initial application submission.','2026-03-24 17:29:14'),
    (43,'EAC-1950DF37','QUALIFIED FOR ENROLLMENT','admin',NULL,'2026-03-24 17:38:43'),
    (30,'EAC-32987A96','SUBMITTED','anonymousUser','Initial application submission.','2026-03-24 17:36:35'),
    (42,'EAC-32987A96','REJECTED','admin','Did not meet admission policy criteria','2026-03-24 17:38:38');

-- ============================================================
-- SECTION 12: DEMO STUDENT ACCOUNTS (Financial & Enrollment Demo)
-- ============================================================
-- Cleanup first to ensure idempotency
SET SQL_SAFE_UPDATES = 0;
DELETE FROM payments          WHERE reference_number IN ('2026-0001','2026-0002','2026-0003');
DELETE FROM student_ledger    WHERE student_id IN (SELECT user_id FROM sys_users WHERE username IN ('2026-0001','2026-0002','2026-0003'));
DELETE FROM jp_student_enlistments WHERE student_id IN (SELECT id FROM jp_students WHERE student_number IN ('2026-0001','2026-0002','2026-0003'));
DELETE FROM jp_students       WHERE student_number IN ('2026-0001','2026-0002','2026-0003');
DELETE FROM sys_users         WHERE username IN ('2026-0001','2026-0002','2026-0003');
SET SQL_SAFE_UPDATES = 1;

-- STUDENT A: Fully enrolled, no scholarship — for walk-in payment demo
INSERT INTO sys_users (username, password, real_name, role, is_active, status, admission_status, program_code, year_level, semester, term_year, scholarship_type, discount_percentage, enrollment_blocked)
VALUES ('2026-0001', '$2a$10$PLACEHOLDER', 'Maron Javier Soriano', 'Student', 1, 'ACTIVE', 'ENROLLED', 'BSCS', 1, 1, 'SL_1120252026', 'NONE', 0.00, 0);

INSERT INTO jp_students (student_number, first_name, last_name, email, program_code, current_year, status)
VALUES ('2026-0001', 'Maron', 'Javier', 'maron@eac.edu.ph', 'BSCS', 1, 'ENROLLED');

-- Enlist Maron in 5 subjects (CS101-CS105, 3 units each = 15 units total)
INSERT INTO jp_student_enlistments (student_id, course_id, section_id, status)
SELECT s.id, c.course_id,
       (SELECT section_id FROM jp_class_sections WHERE course_id = c.course_id LIMIT 1),
       'ENROLLED'
FROM jp_students s, jp_courses c
WHERE s.student_number = '2026-0001'
  AND c.course_code IN ('CS101','CS102','CS103','CS104','MATH101');

-- Grade entries for Maron in legacy grading system
INSERT INTO student_grades (schedule_id, student_name, student_id, prelim, midterm, status)
SELECT s.schedule_id, '2026-0001 Maron Javier', (SELECT user_id FROM sys_users WHERE username = '2026-0001'), '88', '75', 'DRAFT'
FROM class_schedules s WHERE s.course_code IN ('CC101','CC102') AND s.section = 'BSCS-1A';


-- STUDENT B: Scholar (DISCOUNT type), already paid DP — for ledger & scholarship demo
INSERT INTO sys_users (username, password, real_name, role, is_active, status, admission_status, program_code, year_level, semester, term_year, scholarship_type, discount_percentage, enrollment_blocked)
VALUES ('2026-0002', '$2a$10$PLACEHOLDER', 'Clarissa Marie Reyes', 'Student', 1, 'ACTIVE', 'ENROLLED', 'BSCS', 1, 1, 'SL_1120252026', 'DISCOUNT', 0.00, 0);

INSERT INTO jp_students (student_number, first_name, last_name, email, program_code, current_year, status)
VALUES ('2026-0002', 'Clarissa', 'Reyes', 'clarissa@eac.edu.ph', 'BSCS', 1, 'ENROLLED');

INSERT INTO jp_student_enlistments (student_id, course_id, section_id, status)
SELECT s.id, c.course_id,
       (SELECT section_id FROM jp_class_sections WHERE course_id = c.course_id LIMIT 1),
       'ENROLLED'
FROM jp_students s, jp_courses c
WHERE s.student_number = '2026-0002'
  AND c.course_code IN ('CS101','CS102','MATH101','ENGL101','PE101');

-- Clarissa's downpayment (already paid ₱3,000)
INSERT INTO payments (transaction_id, or_number, reference_number, amount, payment_method, semester, year_level, term_year, remarks, payment_date, status)
VALUES ('WLK-CLARISSA01', '200100', '2026-0002', 3000.00, 'CASH (Over the Counter)', 1, 1, 'SL_1120252026', 'Downpayment', '2026-03-15 09:00:00', 'COMPLETED');

INSERT INTO student_ledger (student_id, transaction_type, description, credit)
SELECT user_id, 'PAYMENT', 'Walk-in: Downpayment', 3000.00 FROM sys_users WHERE username = '2026-0002';

-- Grade entries for Clarissa
INSERT INTO student_grades (schedule_id, student_name, student_id, prelim, midterm, status)
SELECT s.schedule_id, '2026-0002 Clarissa Reyes', (SELECT user_id FROM sys_users WHERE username = '2026-0002'), '92', '88', 'DRAFT'
FROM class_schedules s WHERE s.course_code IN ('CC101','CC102') AND s.section = 'BSCS-1A';


-- STUDENT C: Has a heavy historical debt — for Accounting Block demo
INSERT INTO sys_users (username, password, real_name, role, is_active, status, admission_status, program_code, year_level, semester, term_year, scholarship_type, discount_percentage, enrollment_blocked)
VALUES ('2026-0003', '$2a$10$PLACEHOLDER', 'David Franklin Santos', 'Student', 1, 'ACTIVE', 'ENROLLED', 'BSCS', 2, 1, 'SL_1120252026', 'NONE', 0.00, 0);

INSERT INTO jp_students (student_number, first_name, last_name, email, program_code, current_year, status)
VALUES ('2026-0003', 'David', 'Santos', 'david@eac.edu.ph', 'BSCS', 2, 'ENROLLED');

-- Artifical unpaid historical semester debt
INSERT INTO student_ledger (student_id, transaction_type, description, debit, credit)
SELECT user_id, 'ASSESSMENT', '1st Year 1st Semester - Unpaid Balance', 45500.00, 0.00
FROM sys_users WHERE username = '2026-0003';

-- ============================================================
-- SECTION 13: GRADING WINDOWS — Force OPEN for demo
-- ============================================================
UPDATE system_settings SET setting_value = 'FORCE_OPEN' WHERE setting_key IN ('PRELIM_OVERRIDE','MIDTERM_OVERRIDE','FINAL_OVERRIDE');

-- ============================================================
-- SECTION 14: GRADE DATA for legacy grading view
-- ============================================================
-- Fill all students into CC101 BSCS-1A grade sheet
INSERT INTO student_grades (schedule_id, student_name, student_id, prelim, midterm, final_grade, status)
SELECT s.schedule_id, u.real_name, u.user_id, NULL, NULL, NULL, 'DRAFT'
FROM class_schedules s
CROSS JOIN sys_users u
WHERE s.course_code = 'CC101' AND s.section = 'BSCS-1A'
  AND u.role = 'Student'
ON DUPLICATE KEY UPDATE student_name = u.real_name;

-- ============================================================
-- DONE.
-- ============================================================
-- Login Credentials (after first Spring Boot startup resets BCrypt):
--   admin / 1234      → System Admin / Registrar
--   prof  / 1234      → Faculty (Dr. Maria Santos)
--   prof2 / 1234      → Faculty (Prof. Jose Dela Cruz)
--   prof3 / 1234      → Faculty (Prof. Lena Aquino)
-- Student accounts (lookup these in Cashier/Ledger by student number):
--   2026-0001  → Maron Javier   (No scholarship, unpaid)
--   2026-0002  → Clarissa Reyes (DISCOUNT scholar, DP paid)
--   2026-0003  → David Santos   (₱45,500 accounting block)
-- ============================================================



-- ============================================================
-- SECTION 6: SCHOLARSHIP MODULE
-- ============================================================
CREATE TABLE IF NOT EXISTS scholarship_types (
    type_id INT AUTO_INCREMENT PRIMARY KEY,
    classification VARCHAR(50) NOT NULL UNIQUE,
    is_internal TINYINT(1) DEFAULT 0,
    requires_id TINYINT(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS student_scholarships (
    scholarship_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL, 
    type_id INT NOT NULL,
    semester_id INT NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    granted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES sys_users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (type_id) REFERENCES scholarship_types(type_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO scholarship_types (classification, is_internal, requires_id) VALUES
('Barangay Scholarship', 0, 1),
('Academic Scholarship', 1, 0),
('Deans / Presidents Lister', 1, 0),
('Other External', 0, 1);



-- ============================================================
-- SECTION 7: REAL CURRICULUM DATA SEED (BSIT)
-- ============================================================
INSERT IGNORE INTO jp_courses (course_code, course_title, units) VALUES
('AUS0 11', 'Understanding the Self', 3),
('ARPH 11', 'Readings in Philippine History', 3),
('SMMW 11', 'Mathematics in the Modern World', 3),
('AHU1 11', 'Art Appreciation', 3),
('ASS1011', 'Social Sciences and Philosophy', 3),
('PE1 11', 'PE 1: Movement Competency Training', 2),
('ANS1 11', 'CWTS 1/LTS 1/ROTC 1', 3),
('AECO 11', 'Emilian Culture', 1),
('UCO1 11', 'Introduction to Information Technology', 3),
('UPR1 11', 'Fundamentals of Problem Solving & Programming', 3),
('ACW0 12', 'The Contemporary World', 3),
('APC0 12', 'Purposive Communication', 3),
('AET0 12', 'Ethics', 3),
('UDB122', 'Database Management System 1', 3);

INSERT IGNORE INTO jp_class_sections (section_id, course_id, section_name, max_capacity) 
SELECT course_id + 500, course_id, CONCAT('SEC-', course_code), 40 FROM jp_courses;



-- ============================================================
-- SECTION 8: EXTENDED MASSIVE TEST DATA GENERATOR
-- ============================================================
DROP PROCEDURE IF EXISTS seed_massive_integrated_data;
DELIMITER 
CREATE PROCEDURE seed_massive_integrated_data()
BEGIN
    DECLARE v_sys_user_id INT;
    DECLARE v_jp_student_id BIGINT;
    DECLARE v_course_id INT;
    DECLARE v_section_id INT;
    DECLARE v_username VARCHAR(50);
    DECLARE v_first_name VARCHAR(100);
    DECLARE v_last_name VARCHAR(100);
    DECLARE v_status VARCHAR(20);
    DECLARE v_grade_status VARCHAR(20);
    DECLARE i INT DEFAULT 1;
    DECLARE s_idx INT;
    
    WHILE i <= 1000 DO
        SET v_first_name = CONCAT('TestStudent_', i);
        SET v_last_name = CONCAT('BatchX_', FLOOR(RAND() * 100));

        IF (RAND() < 0.8) THEN
            SET v_username = CONCAT('2026-T', LPAD(i, 4, '0'));
            
            INSERT INTO sys_users (username, real_name, role, program_code, year_level, semester, admission_status, is_active, password) 
            VALUES (v_username, CONCAT(v_first_name, ' ', v_last_name), 'Student', 'BSIT', 1, 1, 'ENROLLED', 1, '');
            SET v_sys_user_id = LAST_INSERT_ID();
            
            INSERT INTO jp_students (student_number, first_name, last_name) VALUES (v_username, v_first_name, v_last_name);
            SET v_jp_student_id = LAST_INSERT_ID();

            SET s_idx = 1;
            WHILE s_idx <= 4 DO
                SELECT course_id INTO v_course_id FROM jp_courses ORDER BY RAND() LIMIT 1;
                SELECT section_id INTO v_section_id FROM jp_class_sections WHERE course_id = v_course_id LIMIT 1;
                
                IF v_course_id IS NOT NULL AND v_section_id IS NOT NULL THEN
                    IF NOT EXISTS (SELECT 1 FROM jp_student_enlistments WHERE student_id = v_jp_student_id AND course_id = v_course_id) THEN
                        INSERT INTO jp_student_enlistments (student_id, course_id, section_id, status) VALUES (v_jp_student_id, v_course_id, v_section_id, 'ENROLLED');
                        
                        IF (RAND() < 0.1) THEN SET v_grade_status = 'FAILED';
                        ELSE SET v_grade_status = 'PASSED'; END IF;
                        
                        INSERT INTO jp_grades (student_id, course_id, status) VALUES (v_jp_student_id, v_course_id, v_grade_status);
                    END IF;
                END IF;
                SET s_idx = s_idx + 1;
            END WHILE;

            IF (RAND() < 0.1) THEN
                IF (RAND() < 0.5) THEN
                    INSERT INTO student_scholarships (user_id, type_id, semester_id, status) VALUES (v_sys_user_id, 1, 1, 'ACTIVE');
                ELSE
                    INSERT INTO student_scholarships (user_id, type_id, semester_id, status) VALUES (v_sys_user_id, 4, 1, 'ACTIVE');
                END IF;
            END IF;

        ELSE
            SET v_username = CONCAT('REF-', LPAD(i, 6, '0'));
            INSERT INTO eac_applicants (ref_no, first_name, last_name, applicant_status) 
            VALUES (v_username, v_first_name, v_last_name, 'QUALIFIED FOR ENROLLMENT');
            
            INSERT INTO admission_applications (applicant_id, full_name, status)
            VALUES (v_username, CONCAT(v_first_name, ' ', v_last_name), 'PENDING');
        END IF;

        SET i = i + 1;
    END WHILE;
END 
DELIMITER ;


SET FOREIGN_KEY_CHECKS = 1;
