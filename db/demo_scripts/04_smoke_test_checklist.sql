-- ============================================================
-- SYSTEM SMOKE-TEST CHECKLIST — EAC Enrollment System (Jun 2026)
-- Run each SELECT to verify the system is ready for live use.
-- Expected results are noted in comments after each query.
-- ============================================================
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;
USE eacdb;

-- ────────────────────────────────────────────────────────────
-- 1. SINGLE ACTIVE GLOBAL TERM
--    Expected: exactly 1 row with a valid SL_* value
-- ────────────────────────────────────────────────────────────
SELECT setting_key, setting_value
FROM system_settings
WHERE setting_key = 'CURRENT_ACADEMIC_TERM';
-- Expect: calendar code e.g. 2120252026 (not SL_* — that is on student rows)

-- ────────────────────────────────────────────────────────────
-- 2. ONE ACTIVE ACADEMIC TERM ROW
--    Expected: exactly 1 row where is_active = 1
-- ────────────────────────────────────────────────────────────
SELECT term_id, term_code, term_name, is_active, status
FROM academic_terms
WHERE is_active = 1;
-- Expect: 1 row matching the CURRENT_ACADEMIC_TERM above

-- ────────────────────────────────────────────────────────────
-- 3. ACTIVE CURRICULA PER PROGRAM (one per program)
--    Expected: no program has more than 1 active curriculum
-- ────────────────────────────────────────────────────────────
SELECT p.program_code, COUNT(*) AS active_curriculum_count
FROM curriculum_templates ct
JOIN programs p ON p.program_id = ct.program_id
WHERE ct.is_active = 1
GROUP BY p.program_code
HAVING COUNT(*) > 1;
-- Expect: 0 rows (no duplicates)

-- ────────────────────────────────────────────────────────────
-- 4. CLASS SECTIONS FOR THE OPEN TERM
--    Expected: sections exist for the current is_active term
-- ────────────────────────────────────────────────────────────
SELECT at.term_code, at.term_name, COUNT(cs.section_id) AS sections
FROM academic_terms at
LEFT JOIN class_sections cs ON cs.term_id = at.term_id
WHERE at.is_active = 1
GROUP BY at.term_id, at.term_code, at.term_name;
-- Expect: ≥1 section for the active term

-- ────────────────────────────────────────────────────────────
-- 5. NO UNTAGGED PAYMENTS (term_year IS NULL)
--    Expected: 0 rows after backfill
-- ────────────────────────────────────────────────────────────
SELECT COUNT(*) AS untagged_payments
FROM payments
WHERE term_year IS NULL;
-- Expect: 0 (run 02_backfill_payments_term_year.sql if > 0)

-- ────────────────────────────────────────────────────────────
-- 6. ENROLLMENT_BLOCKED SYNC CHECK
--    Expected: sys_users and students agree on blocked status
-- ────────────────────────────────────────────────────────────
SELECT su.username, su.enrollment_blocked AS sysuser_blocked, st.enrollment_blocked AS student_blocked
FROM sys_users su
JOIN students st ON st.student_number = su.username
WHERE su.enrollment_blocked <> st.enrollment_blocked;
-- Expect: 0 rows (both tables in sync)

-- ────────────────────────────────────────────────────────────
-- 7. FORWARDED BALANCE CONSISTENCY
--    Students with FORWARDED_BALANCE debit should have blocked_flag or not
--    (informational — lists students with outstanding prior-term debt)
-- ────────────────────────────────────────────────────────────
SELECT sl.student_id, sl.debit AS forwarded_balance, su.enrollment_blocked
FROM student_ledger sl
JOIN sys_users su ON su.username = sl.student_id
WHERE sl.transaction_type = 'FORWARDED_BALANCE'
  AND sl.debit > 100
ORDER BY sl.debit DESC
LIMIT 20;
-- Informational: students with forwarded debt > PHP 100 (enlist block candidates)

-- ────────────────────────────────────────────────────────────
-- 8. CURRENT TERM LABEL (should be human-readable for COR header)
-- ────────────────────────────────────────────────────────────
SELECT
  COALESCE(
    (SELECT COALESCE(NULLIF(term_name,''),
            CONCAT('A.Y. ', academic_year, ' - ', IF(semester_number=2,'2nd','1st'), ' Semester'))
     FROM academic_terms WHERE is_active = 1 LIMIT 1),
    (SELECT setting_value FROM system_settings WHERE setting_key = 'CURRENT_ACADEMIC_TERM' LIMIT 1)
  ) AS cor_header_term_label;
-- Expect: "A.Y. 2025-2026 - 1st Semester" (or equivalent)

-- ────────────────────────────────────────────────────────────
-- 9. ENROLLMENT RULES / SESSION TIMEOUT SETTING
-- ────────────────────────────────────────────────────────────
SELECT setting_key, setting_value
FROM system_settings
WHERE setting_key IN ('ENROLLMENT_SESSION_MINUTES', 'ENROLLMENT_TIMEOUT_HOURS',
                      'DOWNPAYMENT_AMOUNT', 'INSTALLMENT_AMOUNT');
-- Expect: known values; adjust as needed before going live

-- ────────────────────────────────────────────────────────────
-- 11. APPLICANT / STUDENT STATUS SYNC
--    Expected: 0 rows (applicants.applicant_status matches students.admission_status)
-- ────────────────────────────────────────────────────────────
SELECT a.reference_number,
       a.applicant_status,
       s.student_number,
       s.admission_status
FROM applicants a
INNER JOIN students s ON s.reference_number = a.reference_number
WHERE (s.admission_status = 'ENROLLED' AND a.applicant_status <> 'ENROLLED')
   OR (s.admission_status = 'ADMITTED' AND a.applicant_status NOT IN ('ADMITTED', 'ENROLLED'))
LIMIT 20;
-- Expect: 0 rows (run 02_sync_applicant_enrolled_status.sql if mismatches found)

-- ────────────────────────────────────────────────────────────
-- 10. ENROLLED STUDENTS COUNT PER TERM
-- ────────────────────────────────────────────────────────────
SELECT
  su.term_year,
  su.admission_status,
  COUNT(*) AS student_count
FROM sys_users su
WHERE su.role = 'STUDENT'
GROUP BY su.term_year, su.admission_status
ORDER BY su.term_year DESC, su.admission_status;
-- Informational: enrollment progress snapshot

-- ────────────────────────────────────────────────────────────
-- 12. FINANCE DEMO PERSONAS (after 10_seed_finance_demo_personas.sql)
-- ────────────────────────────────────────────────────────────
SELECT student_number, term_year, year_level, semester, admission_status
FROM students
WHERE student_number IN ('2026-0026','2026-0027','2026-0028')
ORDER BY student_number;
-- Expect: 3 rows; 0026 on SL_2120242025; 0027/0028 on SL_2220252026

SELECT student_id,
       COALESCE(SUM(debit),0) - COALESCE(SUM(credit),0) AS net_forward
FROM student_ledger
WHERE student_id IN ('2026-0027','2026-0028')
  AND transaction_type = 'FORWARDED_BALANCE'
GROUP BY student_id;
-- Expect: 0027 net = 100; 0028 no row or net = 0

SELECT COUNT(*) AS dup_sync_rows FROM student_ledger
WHERE student_id IN ('2026-0026','2026-0027','2026-0028')
  AND description = 'Synced from enrollment payments';
-- Expect: 0 before loading Student Manager

