-- =============================================================================
-- Fix inflated forward on Mark Zuckerberg 2026-0005 after bad Y1 S2 → Y2 S1 close
--
-- Symptom: fwd_gross = fwd_credits ≈ 27246.67, fwd_net = 0 — payment zeroed net
--          but old UI still added gross to TOTAL FEES (~80k / ~52k balance).
-- Target: forward net ≈ 7294.67 (Y1 S1 overpay −5932 + Y1 S2 debt +13226.67).
--
-- BEFORE: run audit_zuckerberg_2026-0005_finance_reconcile.sql
-- AFTER:  rebuild + redeploy enrollment.war AND registrar.war (forward-net totals)
-- =============================================================================
USE eacdb;

SET @sn = '2026-0005';
SET @sl_y1s1 = 'SL_1120242025';
SET @sl_y1s2 = 'SL_2120242025';
SET @y1s1_fees = 60183.00;
SET @y1s2_fees = 32786.00;

SET @y1s1_net = @y1s1_fees - (
  SELECT COALESCE(SUM(amount), 0) FROM payments
  WHERE reference_number = @sn AND status = 'COMPLETED' AND term_year = @sl_y1s1);
SET @y1s2_net = @y1s2_fees - (
  SELECT COALESCE(SUM(amount), 0) FROM payments
  WHERE reference_number = @sn AND status = 'COMPLETED' AND term_year = @sl_y1s2);
SET @correct_forward = @y1s1_net + @y1s2_net;

SELECT 'Computed correction' AS step,
       @y1s1_net AS y1s1_net,
       @y1s2_net AS y1s2_net,
       @correct_forward AS correct_forward_net;

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
       COALESCE(SUM(debit), 0) AS fwd_gross,
       COALESCE(SUM(credit), 0) AS fwd_credits,
       COALESCE(SUM(debit), 0) - COALESCE(SUM(credit), 0) AS fwd_net
FROM student_ledger WHERE student_id = @sn AND transaction_type = 'FORWARDED_BALANCE';
