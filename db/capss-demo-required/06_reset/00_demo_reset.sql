-- ============================================================
-- 00_demo_reset.sql
-- Clears Maria Santos (2026-1001) between demo runs.
-- Keeps all course, curriculum, section, and faculty seed data.
-- Run this to restart the demo from scratch.
--
-- After running this, re-seed the student with:
--   source 00_demo_applicant_setup.sql   (applicant-only — live admission demo)
--   (or demo_full_lifecycle.sql for pre-created student 2026-1001)
--
-- For finance QA personas (2026-0026..0028), use 00_finance_demo_reset.sql instead.
-- ============================================================
USE eacdb;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_SAFE_UPDATES   = 0;

DELETE FROM grades              WHERE student_id   = '2026-1001';
DELETE FROM student_enlistments WHERE student_id   = '2026-1001';
DELETE FROM student_ledger      WHERE student_id   = '2026-1001';
DELETE FROM subject_requests    WHERE student_id   = '2026-1001';
DELETE FROM students            WHERE student_number = '2026-1001';
DELETE FROM sys_users           WHERE username      = '2026-1001';
DELETE FROM applicants          WHERE reference_number = 'DEMO-SANTOS-001';
DELETE FROM payments            WHERE reference_number = 'DEMO-SANTOS-001';
DELETE FROM applicant_payments  WHERE applicant_id    = 'DEMO-SANTOS-001';

SET FOREIGN_KEY_CHECKS = 1;
SET SQL_SAFE_UPDATES   = 1;

SELECT 'RESET COMPLETE. Maria Santos (2026-1001) removed. Ready to re-seed.' AS status;
