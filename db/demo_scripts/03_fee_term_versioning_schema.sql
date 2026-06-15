-- =============================================================================
-- OPTIONAL — NOT part of core CAPSS fee logic (default installs skip this file).
--
-- Core fees: program_general_fees + program_specific_fees (+ capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql)
-- Enrollment reads those unless enrollment.fees.use-program-fee-rates=true.
--
-- OPTIONAL legacy schema (program_fee_rates). Standard /admin/term-fees uses program_general_fees instead.
-- Only run if you explicitly adopt that model for every program/term.
-- =============================================================================
USE eacdb;

-- Fee catalog
CREATE TABLE IF NOT EXISTS fee_types (
  fee_type_id INT AUTO_INCREMENT PRIMARY KEY,
  fee_code    VARCHAR(50) NOT NULL UNIQUE,
  fee_name    VARCHAR(120) NOT NULL,
  kind        VARCHAR(20) NOT NULL,     -- 'RATE' or 'CHARGE'
  unit_basis  VARCHAR(20) NULL,         -- 'PER_UNIT','PER_HOUR','FLAT'
  is_active   TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Program fee rates by academic term
CREATE TABLE IF NOT EXISTS program_fee_rates (
  program_fee_rate_id INT AUTO_INCREMENT PRIMARY KEY,
  term_id      INT NOT NULL,
  program_code VARCHAR(20) NOT NULL,
  fee_type_id  INT NOT NULL,
  year_level   INT NULL,
  student_type VARCHAR(50) NULL,
  amount       DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  is_active    TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_prog_fee (term_id, program_code, fee_type_id, year_level, student_type),
  KEY idx_pfr_program_term (program_code, term_id),
  CONSTRAINT fk_pfr_term FOREIGN KEY (term_id) REFERENCES academic_terms(term_id),
  CONSTRAINT fk_pfr_fee  FOREIGN KEY (fee_type_id) REFERENCES fee_types(fee_type_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Optional course fee add-ons by academic term
CREATE TABLE IF NOT EXISTS course_fee_rates (
  course_fee_rate_id INT AUTO_INCREMENT PRIMARY KEY,
  term_id     INT NOT NULL,
  course_id   INT NOT NULL,
  fee_type_id INT NOT NULL,
  amount      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_course_fee (term_id, course_id, fee_type_id),
  KEY idx_cfr_term (term_id),
  CONSTRAINT fk_cfr_term FOREIGN KEY (term_id) REFERENCES academic_terms(term_id),
  CONSTRAINT fk_cfr_course FOREIGN KEY (course_id) REFERENCES courses(course_id),
  CONSTRAINT fk_cfr_fee FOREIGN KEY (fee_type_id) REFERENCES fee_types(fee_type_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Assessment snapshot (per student, per term)
CREATE TABLE IF NOT EXISTS student_term_assessments (
  assessment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  term_id    INT NOT NULL,
  assessed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  total_units DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  UNIQUE KEY uq_student_term (student_id, term_id),
  CONSTRAINT fk_sta_student FOREIGN KEY (student_id) REFERENCES sys_users(user_id) ON DELETE CASCADE,
  CONSTRAINT fk_sta_term FOREIGN KEY (term_id) REFERENCES academic_terms(term_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS student_term_assessment_items (
  assessment_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  assessment_id BIGINT NOT NULL,
  fee_type_id INT NOT NULL,
  label VARCHAR(150) NOT NULL,
  source VARCHAR(20) NOT NULL,            -- PROGRAM/COURSE/COMPUTED
  ref_course_id INT NULL,
  qty  DECIMAL(12,2) NOT NULL DEFAULT 1.00,
  rate DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  CONSTRAINT fk_stai_assessment FOREIGN KEY (assessment_id) REFERENCES student_term_assessments(assessment_id) ON DELETE CASCADE,
  CONSTRAINT fk_stai_fee FOREIGN KEY (fee_type_id) REFERENCES fee_types(fee_type_id),
  CONSTRAINT fk_stai_course FOREIGN KEY (ref_course_id) REFERENCES courses(course_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Baseline fee_type rows used by the apps
INSERT IGNORE INTO fee_types (fee_code, fee_name, kind, unit_basis) VALUES
('TUITION_PER_UNIT', 'Tuition Rate (per unit)', 'RATE', 'PER_UNIT'),
('RLE_RATE_PER_HOUR', 'RLE Rate (per hour)', 'RATE', 'PER_HOUR'),
('TUITION_CHARGE', 'Tuition', 'CHARGE', 'PER_UNIT'),
('MISC_CHARGE', 'Miscellaneous Fees', 'CHARGE', 'FLAT'),
('OTHER_CHARGE', 'Other Fees', 'CHARGE', 'FLAT'),
('RLE_CHARGE', 'RLE / Clinical Fees', 'CHARGE', 'PER_HOUR'),
('COURSE_LAB_FEE', 'Laboratory Fee', 'CHARGE', 'FLAT'),
('COURSE_COMPUTER_FEE', 'Computer Fee', 'CHARGE', 'FLAT');

