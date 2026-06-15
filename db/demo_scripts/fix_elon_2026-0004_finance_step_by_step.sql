-- =============================================================================
-- LEGACY REPAIR ONLY — prefer fresh demo + rebuilt WARs (see FINANCE_FIX_STEPS.md).
-- STEP-BY-STEP finance fix — Elon Musk 2026-0004 (run in order on eacdb)
--
-- BEFORE: run audit_elon_2026-0004_finance_reconcile.sql and save the output.
-- AFTER:  restart enrollment + registrar apps (or redeploy WARs) if you applied
--         the Java patch for registrar total_paid (see FINANCE_FIX_STEPS.md).
-- =============================================================================
USE eacdb;

SET @sn = '2026-0004';
SET @sl_y1s2 = 'SL_2120242025';

-- -----------------------------------------------------------------------------
-- STEP 1 — Snapshot (do not skip; proves starting state)
-- -----------------------------------------------------------------------------
SELECT 'STEP 1 — BEFORE' AS step;
SELECT transaction_type,
       ROUND(COALESCE(SUM(debit),0),2) AS debits,
       ROUND(COALESCE(SUM(credit),0),2) AS credits
FROM student_ledger WHERE student_id = @sn
GROUP BY transaction_type;

SELECT ROUND(COALESCE(SUM(amount),0),2) AS payments_table_total
FROM payments WHERE reference_number = @sn AND status = 'COMPLETED';

-- -----------------------------------------------------------------------------
-- STEP 2 — Clear FORWARDED_BALANCE net (debit − credit on FORWARDED rows only)
-- Example: 60,000 forward debit + 62,800 payment elsewhere → credit 60,000 here
-- so prior term no longer inflates enrollment/registrar totals.
-- -----------------------------------------------------------------------------
SET @fwd_net = (
    SELECT COALESCE(SUM(debit),0) - COALESCE(SUM(credit),0)
    FROM student_ledger
    WHERE student_id = @sn AND transaction_type = 'FORWARDED_BALANCE'
);

SELECT @fwd_net AS forwarded_net_before_step2;

INSERT INTO student_ledger (student_id, transaction_type, description, debit, credit)
SELECT @sn, 'FORWARDED_BALANCE',
       'Prior term balance cleared (demo fix)',
       0, @fwd_net
FROM DUAL
WHERE @fwd_net > 0.01;

-- -----------------------------------------------------------------------------
-- STEP 3 — Backfill student_ledger PAYMENT credits from payments table
-- Registrar Student Manager only counts ledger PAYMENT / INITIAL_PAYMENT.
-- -----------------------------------------------------------------------------
SET @ledger_paid = (
    SELECT COALESCE(SUM(credit),0)
    FROM student_ledger
    WHERE student_id = @sn
      AND transaction_type IN ('PAYMENT', 'INITIAL_PAYMENT')
);
SET @payments_paid = (
    SELECT COALESCE(SUM(amount),0)
    FROM payments
    WHERE reference_number = @sn AND status = 'COMPLETED'
);
SET @gap = @payments_paid - @ledger_paid;

SELECT @ledger_paid AS ledger_payments_before,
       @payments_paid AS payments_table_total,
       @gap AS credit_gap_to_backfill;

INSERT INTO student_ledger (student_id, transaction_type, description, debit, credit)
SELECT @sn, 'PAYMENT',
       'Backfill — synced from payments table (demo fix)',
       0, @gap
FROM DUAL
WHERE @gap > 0.01;

-- -----------------------------------------------------------------------------
-- STEP 4 — Re-align TUITION / MISC / OTHER debits to enlisted Y1 S2 + fee tables
-- (Matches enrollment TermAssessmentService logic at SQL level.)
-- -----------------------------------------------------------------------------
SET @term_id = (SELECT term_id FROM academic_terms WHERE term_code = '2120242025' LIMIT 1);

SET @units = (
    SELECT COALESCE(SUM(c.credit_units), 0)
    FROM student_enlistments se
    JOIN courses c ON c.course_id = se.course_id
    JOIN class_sections cs ON se.section_id = cs.section_id
    WHERE se.student_id = @sn
      AND (cs.term_id = @term_id OR cs.section_code LIKE 'BSIT-1-2-%')
);

SET @rate = COALESCE(
    (SELECT pgf.tuition_per_unit
     FROM program_general_fees pgf
     JOIN programs p ON p.program_id = pgf.program_id
     WHERE p.program_code = 'BSIT'
       AND pgf.year_level = 1 AND pgf.semester_number = 2
       AND (pgf.term_id = @term_id OR pgf.term_id IS NULL)
     ORDER BY pgf.term_id IS NULL ASC, pgf.term_id DESC
     LIMIT 1),
    1483.00
);

SET @tuition = ROUND(@units * @rate, 2);

SET @misc = COALESCE(
    (SELECT SUM(psf.amount)
     FROM program_specific_fees psf
     JOIN programs p ON p.program_id = psf.program_id
     WHERE p.program_code = 'BSIT'
       AND psf.year_level = 1 AND psf.semester_number = 2
       AND psf.fee_group = 'MISC' AND COALESCE(psf.is_active, 1) = 1
       AND (psf.term_id = @term_id OR psf.term_id IS NULL)),
    0
);

SET @other = COALESCE(
    (SELECT SUM(psf.amount)
     FROM program_specific_fees psf
     JOIN programs p ON p.program_id = psf.program_id
     WHERE p.program_code = 'BSIT'
       AND psf.year_level = 1 AND psf.semester_number = 2
       AND psf.fee_group = 'OTHER' AND COALESCE(psf.is_active, 1) = 1
       AND (psf.term_id = @term_id OR psf.term_id IS NULL)),
    0
);

SELECT @units AS billed_units, @rate AS tuition_rate, @tuition AS tuition,
       @misc AS misc, @other AS other,
       ROUND(@tuition + @misc + @other, 2) AS current_term_assessment;

DELETE FROM student_ledger
WHERE student_id = @sn
  AND transaction_type IN ('TUITION_ASSESSMENT', 'MISC_ASSESSMENT', 'OTHER_ASSESSMENT', 'RLE_ASSESSMENT', 'SUBJECT_ADD');

INSERT INTO student_ledger (student_id, transaction_type, description, debit, credit)
VALUES (
    @sn, 'TUITION_ASSESSMENT',
    CONCAT('Tuition Fee Assessment (', @units, ' Units @ ₱', FORMAT(@rate, 2), ')'),
    @tuition, 0
);

INSERT INTO student_ledger (student_id, transaction_type, description, debit, credit)
SELECT @sn, 'MISC_ASSESSMENT', 'Institutional Miscellaneous Fees', @misc, 0
FROM DUAL WHERE @misc > 0;

INSERT INTO student_ledger (student_id, transaction_type, description, debit, credit)
SELECT @sn, 'OTHER_ASSESSMENT', 'Institutional Other Fees', @other, 0
FROM DUAL WHERE @other > 0;

-- -----------------------------------------------------------------------------
-- STEP 5 — Ensure student standing matches open term (Y1 S2)
-- -----------------------------------------------------------------------------
UPDATE students
SET term_year = @sl_y1s2, year_level = 1, semester = 2
WHERE student_number = @sn;

UPDATE sys_users u
JOIN students s ON s.user_id = u.user_id
SET u.year_level = 1, u.semester = 2
WHERE s.student_number = @sn;

-- Optional: set open enrollment term (uncomment if needed)
-- UPDATE system_settings SET setting_value = @sl_y1s2 WHERE setting_key = 'CURRENT_ACADEMIC_TERM';

-- -----------------------------------------------------------------------------
-- STEP 6 — AFTER summary (expect registrar balance ≈ 0 if payments ≥ assessment)
-- -----------------------------------------------------------------------------
SELECT 'STEP 6 — AFTER' AS step;

SELECT transaction_type,
       ROUND(COALESCE(SUM(debit),0),2) AS debits,
       ROUND(COALESCE(SUM(credit),0),2) AS credits,
       ROUND(COALESCE(SUM(debit),0)-COALESCE(SUM(credit),0),2) AS net
FROM student_ledger WHERE student_id = @sn
GROUP BY transaction_type;

SELECT
    ROUND((SELECT COALESCE(SUM(debit),0) FROM student_ledger WHERE student_id=@sn
           AND transaction_type IN ('TUITION_ASSESSMENT','MISC_ASSESSMENT','OTHER_ASSESSMENT')),2) AS assessment_debits,
    ROUND((SELECT COALESCE(SUM(credit),0) FROM student_ledger WHERE student_id=@sn
           AND transaction_type IN ('PAYMENT','INITIAL_PAYMENT')),2) AS ledger_payments,
    ROUND((SELECT COALESCE(SUM(debit),0)-COALESCE(SUM(credit),0) FROM student_ledger WHERE student_id=@sn),2) AS net_all_ledger,
    ROUND(GREATEST(
        (SELECT COALESCE(SUM(debit),0) FROM student_ledger WHERE student_id=@sn
         AND transaction_type IN ('TUITION_ASSESSMENT','MISC_ASSESSMENT','OTHER_ASSESSMENT'))
        - (SELECT COALESCE(SUM(credit),0) FROM student_ledger WHERE student_id=@sn
           AND transaction_type IN ('PAYMENT','INITIAL_PAYMENT')),
        0),2) AS registrar_style_balance;
