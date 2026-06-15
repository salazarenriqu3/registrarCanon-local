-- =============================================================================
-- Finance reconcile: Elon Musk 2026-0004 (enrollment cashier vs registrar ledger)
-- Run on eacdb after reproducing the issue. Compare sections side-by-side.
-- =============================================================================
USE eacdb;

SET @sn = '2026-0004';
SET @sl_y1s2 = 'SL_2120242025';
SET @db_term = '2120242025';

-- Student standing
SELECT 'Student standing' AS section;
SELECT student_number, program_code, year_level, semester, term_year, section_group,
       scholarship_approved, scholarship_type, scholarship_amount, discount_percentage
FROM students WHERE student_number = @sn;

-- Calendar term
SELECT 'Academic term' AS section;
SELECT term_id, term_code, term_name, academic_year, semester_number
FROM academic_terms WHERE term_code = @db_term;

-- Enlistment (Y1 S2)
SELECT 'Enlistments Y1 S2' AS section;
SELECT c.course_code, c.course_title, c.credit_units, c.lec_units, c.lab_units,
       cs.section_code, at.term_code
FROM student_enlistments se
JOIN courses c ON c.course_id = se.course_id
LEFT JOIN class_sections cs ON se.section_id = cs.section_id
LEFT JOIN academic_terms at ON cs.term_id = at.term_id
WHERE se.student_id = @sn
  AND cs.section_code LIKE 'BSIT-1-2-%'
ORDER BY c.course_code;

SELECT 'Unit totals (enlisted Y1 S2)' AS section;
SELECT COUNT(*) AS subjects,
       SUM(c.credit_units) AS sum_credit_units,
       SUM(c.lec_units) AS sum_lec_units,
       SUM(c.lab_units) AS sum_lab_units,
       SUM(c.lec_units + c.lab_units) AS sum_lec_plus_lab
FROM student_enlistments se
JOIN courses c ON c.course_id = se.course_id
JOIN class_sections cs ON se.section_id = cs.section_id
WHERE se.student_id = @sn AND cs.section_code LIKE 'BSIT-1-2-%';

-- Ledger (registrar Student Manager uses this)
SELECT 'Ledger by transaction_type' AS section;
SELECT transaction_type,
       COALESCE(SUM(debit), 0) AS debits,
       COALESCE(SUM(credit), 0) AS credits,
       COALESCE(SUM(debit), 0) - COALESCE(SUM(credit), 0) AS net
FROM student_ledger WHERE student_id = @sn
GROUP BY transaction_type ORDER BY transaction_type;

SELECT 'Registrar-style assessment (ledger debits)' AS section;
SELECT
    (SELECT COALESCE(SUM(debit),0) FROM student_ledger WHERE student_id=@sn AND transaction_type='TUITION_ASSESSMENT') AS tuition_ledger,
    (SELECT COALESCE(SUM(debit),0) FROM student_ledger WHERE student_id=@sn AND transaction_type='MISC_ASSESSMENT') AS misc_ledger,
    (SELECT COALESCE(SUM(debit),0) FROM student_ledger WHERE student_id=@sn AND transaction_type='OTHER_ASSESSMENT') AS other_ledger,
    (SELECT COALESCE(SUM(debit),0) FROM student_ledger WHERE student_id=@sn AND transaction_type IN ('TUITION_ASSESSMENT','MISC_ASSESSMENT','OTHER_ASSESSMENT')) AS total_assessment_ledger,
    (SELECT COALESCE(SUM(credit),0) FROM student_ledger WHERE student_id=@sn AND transaction_type IN ('PAYMENT','INITIAL_PAYMENT')) AS ledger_payments_only,
    (SELECT COALESCE(SUM(debit),0)-COALESCE(SUM(credit),0) FROM student_ledger WHERE student_id=@sn) AS net_all_ledger;

SELECT 'FORWARDED_BALANCE net (enrollment balanceForwarded)' AS section;
SELECT COALESCE(SUM(debit),0) AS fwd_debit,
       COALESCE(SUM(credit),0) AS fwd_credit,
       GREATEST(COALESCE(SUM(debit),0)-COALESCE(SUM(credit),0),0) AS enrollment_getBalanceForwarded
FROM student_ledger WHERE student_id=@sn AND transaction_type='FORWARDED_BALANCE';

-- Payments table (enrollment cashier uses this for credits / PAID flags)
SELECT 'Payments by term_year / year / sem' AS section;
SELECT term_year, year_level, semester, status,
       COUNT(*) AS cnt, SUM(amount) AS total_amount, GROUP_CONCAT(remarks SEPARATOR ' | ') AS remarks_sample
FROM payments WHERE reference_number = @sn
GROUP BY term_year, year_level, semester, status
ORDER BY year_level, semester, term_year;

SELECT 'Payments for Y1 S2 SL (cashier term filter)' AS section;
SELECT COALESCE(SUM(amount),0) AS term_payments_y1s2
FROM payments
WHERE reference_number = @sn AND status = 'COMPLETED'
  AND (term_year = @sl_y1s2
       OR ((term_year IS NULL OR term_year = '') AND year_level = 1 AND semester = 2));

SELECT 'All COMPLETED payments (lifetime)' AS section;
SELECT COALESCE(SUM(amount),0) AS all_completed_payments FROM payments
WHERE reference_number = @sn AND status = 'COMPLETED';

-- Fee schedule hint (BSIT Y1 S2)
SELECT 'program_general_fees (BSIT Y1 S2)' AS section;
SELECT pgf.*
FROM program_general_fees pgf
JOIN programs p ON p.program_id = pgf.program_id
WHERE p.program_code = 'BSIT' AND pgf.year_level = 1 AND pgf.semester_number = 2
ORDER BY pgf.term_id IS NULL DESC, pgf.term_id DESC LIMIT 5;

SELECT 'program_specific_fees MISC+OTHER (BSIT Y1 S2, term_id NULL)' AS section;
SELECT psf.fee_code, psf.fee_group, psf.amount
FROM program_specific_fees psf
JOIN programs p ON p.program_id = psf.program_id
WHERE p.program_code = 'BSIT' AND psf.year_level = 1 AND psf.semester_number = 2
  AND psf.term_id IS NULL AND psf.is_active = 1
ORDER BY psf.fee_group, psf.fee_code;

-- Expected math (manual check)
SELECT 'Expected checks' AS section,
       '2800 overpay = prior 62800 credit - 60000 forward (if those rows exist)' AS check_1,
       'Cashier assessment ~ tuition(units*rate)+misc+other; ledger may use different rate' AS check_2,
       'Registrar balance ignores payments table unless synced to ledger PAYMENT' AS check_3;
