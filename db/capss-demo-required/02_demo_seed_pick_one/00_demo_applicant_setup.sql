-- ============================================================
-- 00_demo_applicant_setup.sql
-- Applicant-only seed for live admission demo (Maria Santos).
-- Does NOT create student number or ledger — use registrar Admission
-- Acceptance after payment to generate 2026-1001.
--
-- Run AFTER:
--   1) db/fix
--   2) capss-demo-required/01_setup/01_fresh_demo_bootstrap.sql
--   3) capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql
--   4) capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql
-- ============================================================
USE eacdb;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_SAFE_UPDATES   = 0;

INSERT IGNORE INTO applicants (
    reference_number, first_name, last_name, middle_name,
    email, mobile, sex, program1, applicant_status,
    application_status, term_year, created_at, updated_at,
    form138_verified, good_moral_verified, psa_birth_cert_verified, id_picture_verified
) VALUES (
    'DEMO-SANTOS-001', 'Maria', 'Santos', 'Reyes',
    'maria.santos@demo.eac.edu.ph', '09171234567', 'Female', 'BSIT',
    'QUALIFIED FOR ENROLLMENT', 'ADMISSION_PENDING',
    'SL_1120252026', NOW(), NOW(),
    1, 1, 1, 1
);

-- Optional: pre-record admission fee so Phase 2 can skip walk-in payment
INSERT IGNORE INTO payments (
    transaction_id, reference_number, amount, payment_method, status, payment_date
) VALUES (
    'PAY-DEMO-SANTOS-001', 'DEMO-SANTOS-001', 1000.00, 'Cash (OTC)', 'COMPLETED', NOW()
);

SET FOREIGN_KEY_CHECKS = 1;
SET SQL_SAFE_UPDATES   = 1;

SELECT reference_number, first_name, last_name, program1, applicant_status
FROM applicants WHERE reference_number = 'DEMO-SANTOS-001';
