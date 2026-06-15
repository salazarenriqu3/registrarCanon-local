-- =============================================================================
-- Fix spurious credit forward on Elon Musk 2026-0002 after Y1 S2 → Y2 S1 transition
--
-- Symptom: FORWARDED credit ~65115 on Y2 S1 (should be ~11616 debt or ~51499 credit max
--          if Y1 S1 was never closed — not both combined wrong).
--
-- BEFORE: run audit_elon_2026-0002_finance_reconcile.sql
-- AFTER:  rebuild + redeploy enrollment.war AND registrar.war (term-close fixes)
-- =============================================================================
USE eacdb;

SET @sn = '2026-0002';
SET @sl_y1s2 = 'SL_2120242025';
SET @sl_y1s1 = 'SL_1120242025';

-- Correct forward when Y1 S1 debt (63115) was rolled and Y1 S2 paid 111682 vs ~60183 fees:
SET @y1s1_debt = GREATEST(
  66115.00 - (SELECT COALESCE(SUM(amount),0) FROM payments WHERE reference_number=@sn AND status='COMPLETED' AND term_year=@sl_y1s1),
  0);
SET @y1s2_fees = 60183.00;
SET @y1s2_paid = (SELECT COALESCE(SUM(amount),0) FROM payments WHERE reference_number=@sn AND status='COMPLETED' AND term_year=@sl_y1s2);
SET @correct_forward = @y1s1_debt + @y1s2_fees - @y1s2_paid;

SELECT 'Computed correction' AS step, @y1s1_debt AS y1s1_debt, @y1s2_fees AS y1s2_fees,
       @y1s2_paid AS y1s2_paid, @correct_forward AS correct_forward_net;

DELETE FROM student_ledger
WHERE student_id = @sn
  AND transaction_type IN (
    'FORWARDED_BALANCE', 'TUITION_ASSESSMENT', 'MISC_ASSESSMENT', 'OTHER_ASSESSMENT',
    'RLE_ASSESSMENT', 'SUBJECT_ADD');

INSERT INTO student_ledger (student_id, transaction_type, description, debit, credit)
SELECT @sn, 'FORWARDED_BALANCE', 'Balance forwarded from previous term (corrected)', @correct_forward, 0
WHERE @correct_forward > 0.01;

INSERT INTO student_ledger (student_id, transaction_type, description, debit, credit)
SELECT @sn, 'FORWARDED_BALANCE', 'Credit forwarded from previous term (corrected)', 0, ABS(@correct_forward)
WHERE @correct_forward < -0.01;

SELECT 'AFTER forward row' AS step,
       COALESCE(SUM(debit),0) - COALESCE(SUM(credit),0) AS fwd_net
FROM student_ledger WHERE student_id = @sn AND transaction_type = 'FORWARDED_BALANCE';
