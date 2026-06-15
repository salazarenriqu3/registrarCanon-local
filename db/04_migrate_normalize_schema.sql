-- =============================================================================
-- EACDB — SCHEMA NORMALIZATION MIGRATION (Run once against live eacdb)
-- Migrates jp_* legacy tables -> canonical programs/curriculum_templates/
-- curriculum_courses/course_prerequisites tables.
--
-- Compatible: MySQL 5.7+, MariaDB 10.4+
-- =============================================================================

USE eacdb;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_SAFE_UPDATES = 0;

-- ---------------------------------------------------------------------------
-- STEP 1 — Add departments.faculty_id (department head link)
-- MariaDB 10.4: ADD COLUMN supports IF NOT EXISTS, but ADD CONSTRAINT does NOT.
-- We use dynamic SQL to conditionally add the FK only if it doesn't exist yet.
-- ---------------------------------------------------------------------------
ALTER TABLE departments
    ADD COLUMN IF NOT EXISTS faculty_id INT DEFAULT NULL;

-- Conditionally add FK (safe on both fresh and already-migrated databases)
SET @fk_exists = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE()
      AND TABLE_NAME        = 'departments'
      AND CONSTRAINT_NAME   = 'fk_dept_head'
);
SET @sql = IF(
    @fk_exists = 0,
    'ALTER TABLE departments ADD CONSTRAINT fk_dept_head FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id) ON DELETE SET NULL',
    'SELECT 1 /* fk_dept_head already exists, skipping */'
);
PREPARE _stmt FROM @sql; EXECUTE _stmt; DEALLOCATE PREPARE _stmt;

-- ---------------------------------------------------------------------------
-- STEP 2 — Add canonical programs table (replaces jp_programs)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS programs (
    program_id    INT AUTO_INCREMENT PRIMARY KEY,
    program_code  VARCHAR(20)  NOT NULL UNIQUE,
    program_name  VARCHAR(150),
    department_id INT          DEFAULT NULL,
    school_name   VARCHAR(100),
    active_status TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT fk_prog_dept FOREIGN KEY (department_id)
        REFERENCES departments(department_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- STEP 3 — Add curriculum_templates (one curriculum version per program)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS curriculum_templates (
    curriculum_id   INT AUTO_INCREMENT PRIMARY KEY,
    program_id      INT NOT NULL,
    curriculum_name VARCHAR(100),
    academic_year   VARCHAR(20),
    version_number  INT          NOT NULL DEFAULT 1,
    approval_status VARCHAR(20)  NOT NULL DEFAULT 'Draft',
    is_active       TINYINT(1)   NOT NULL DEFAULT 0,
    CONSTRAINT fk_ct_program FOREIGN KEY (program_id)
        REFERENCES programs(program_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- STEP 4 — Add curriculum_courses (replaces jp_curriculum_mapping)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS curriculum_courses (
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

-- ---------------------------------------------------------------------------
-- STEP 5 — Add course_prerequisites (many-to-many, replaces prerequisite_id FK)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS course_prerequisites (
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

-- ---------------------------------------------------------------------------
-- STEP 6 — Extend courses table with scheduling schema columns
-- ---------------------------------------------------------------------------
ALTER TABLE courses
    ADD COLUMN IF NOT EXISTS lecture_units                INT        DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS lab_units                    INT        DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS is_coordinator_based         TINYINT(1) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS coordinator_equivalent_units INT        DEFAULT NULL;

-- Backfill lecture_units / lab_units from existing hours columns
UPDATE courses
SET    lecture_units = lecture_hours_per_week,
       lab_units     = lab_hours_per_week
WHERE  lecture_units IS NULL
  AND  lecture_hours_per_week IS NOT NULL;

-- ---------------------------------------------------------------------------
-- STEP 7 — Extend class_sections with semester_number
-- ---------------------------------------------------------------------------
ALTER TABLE class_sections
    ADD COLUMN IF NOT EXISTS semester_number INT DEFAULT NULL;

-- Backfill semester_number from courses.semester (if column still exists on live DB)
SET @has_sem_col = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'courses'
      AND COLUMN_NAME  = 'semester'
);
SET @sql = IF(
    @has_sem_col > 0,
    'UPDATE class_sections cs JOIN courses c ON c.course_id = cs.course_id SET cs.semester_number = c.semester WHERE cs.semester_number IS NULL',
    'SELECT 1 /* courses.semester column not present, skipping backfill */'
);
PREPARE _stmt FROM @sql; EXECUTE _stmt; DEALLOCATE PREPARE _stmt;

-- ---------------------------------------------------------------------------
-- STEP 8 — Migrate jp_programs -> programs
-- (Only runs if jp_programs still exists)
-- ---------------------------------------------------------------------------
SET @jp_programs_exists = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'jp_programs'
);
SET @sql = IF(
    @jp_programs_exists > 0,
    'INSERT IGNORE INTO programs (program_code, program_name, school_name) SELECT program_code, program_name, school_name FROM jp_programs',
    'SELECT 1 /* jp_programs does not exist, skipping */'
);
PREPARE _stmt FROM @sql; EXECUTE _stmt; DEALLOCATE PREPARE _stmt;

-- ---------------------------------------------------------------------------
-- STEP 9 — Migrate jp_curriculum_mapping -> curriculum_templates + curriculum_courses
-- One curriculum_template per program (active, Draft, AY 2024-2025)
-- ---------------------------------------------------------------------------
SET @jp_map_exists = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'jp_curriculum_mapping'
);

-- 9a: seed curriculum_templates for each program that has mapping rows
SET @sql = IF(
    @jp_map_exists > 0,
    'INSERT IGNORE INTO curriculum_templates (program_id, curriculum_name, academic_year, version_number, approval_status, is_active) SELECT p.program_id, CONCAT(p.program_name, '' Curriculum''), ''2024-2025'', 1, ''Draft'', 1 FROM programs p WHERE EXISTS (SELECT 1 FROM jp_curriculum_mapping jcm WHERE jcm.program_code = p.program_code)',
    'SELECT 1 /* jp_curriculum_mapping not present */'
);
PREPARE _stmt FROM @sql; EXECUTE _stmt; DEALLOCATE PREPARE _stmt;

-- 9b: map each jp_curriculum_mapping row into curriculum_courses
SET @sql = IF(
    @jp_map_exists > 0,
    'INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number, is_required) SELECT ct.curriculum_id, c.course_id, jcm.year_level, jcm.semester, 1 FROM jp_curriculum_mapping jcm JOIN programs p ON p.program_code = jcm.program_code JOIN curriculum_templates ct ON ct.program_id = p.program_id JOIN jp_courses jc ON jc.course_id = jcm.course_id JOIN courses c ON c.course_code = jc.course_code',
    'SELECT 1 /* jp_curriculum_mapping not present */'
);
PREPARE _stmt FROM @sql; EXECUTE _stmt; DEALLOCATE PREPARE _stmt;

-- ---------------------------------------------------------------------------
-- STEP 10 — Migrate courses.prerequisite_id -> course_prerequisites
-- Guard: only run if the prerequisite_id column still exists on courses
-- ---------------------------------------------------------------------------
SET @has_prereq_col = (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'courses'
      AND COLUMN_NAME  = 'prerequisite_id'
);
SET @sql = IF(
    @has_prereq_col > 0,
    'INSERT IGNORE INTO course_prerequisites (course_id, prerequisite_course_id) SELECT course_id, prerequisite_id FROM courses WHERE prerequisite_id IS NOT NULL',
    'SELECT 1 /* courses.prerequisite_id already removed, skipping */'
);
PREPARE _stmt FROM @sql; EXECUTE _stmt; DEALLOCATE PREPARE _stmt;

-- ---------------------------------------------------------------------------
-- STEP 11 — Drop jp_* legacy tables
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS jp_curriculum_mapping;
DROP TABLE IF EXISTS jp_grades;
DROP TABLE IF EXISTS jp_subject_logs;
DROP TABLE IF EXISTS jp_student_enlistments;
DROP TABLE IF EXISTS jp_class_schedules;
DROP TABLE IF EXISTS jp_class_sections;
DROP TABLE IF EXISTS jp_courses;
DROP TABLE IF EXISTS jp_students;
DROP TABLE IF EXISTS jp_programs;

-- ---------------------------------------------------------------------------
-- STEP 12 — (OPTIONAL) Clean up now-redundant columns on courses.
-- The columns semester, year_level, semester_id, prerequisite_id, program_code
-- are now carried by curriculum_courses and course_prerequisites.
-- Uncomment ONLY AFTER verifying curriculum_courses data is correct.
-- ---------------------------------------------------------------------------
-- ALTER TABLE courses
--     DROP FOREIGN KEY fk_course_prereq,
--     DROP COLUMN semester,
--     DROP COLUMN year_level,
--     DROP COLUMN semester_id,
--     DROP COLUMN prerequisite_id,
--     DROP COLUMN program_code;

SET SQL_SAFE_UPDATES = 1;
SET FOREIGN_KEY_CHECKS = 1;

SELECT 'Migration complete. jp_* tables removed. programs, curriculum_templates, curriculum_courses, course_prerequisites created.' AS status;
