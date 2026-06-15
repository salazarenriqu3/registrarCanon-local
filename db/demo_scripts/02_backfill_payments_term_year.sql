-- ============================================================
-- OPTIONAL ONE-TIME: Backfill payments.term_year for legacy rows
-- that were inserted before term tagging was implemented.
--
-- SAFE TO RUN MORE THAN ONCE (only touches rows where term_year IS NULL).
-- HOW TO RUN:
--   1. Run the PREVIEW SELECT to inspect which rows will be updated.
--   2. Run the UPDATE block when satisfied.
-- ============================================================
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;
USE eacdb;

-- ── PREVIEW (no changes) ─────────────────────────────────────────────────
SELECT
  p.payment_id,
  p.student_id,
  p.amount,
  p.payment_date,
  p.year_level,
  p.semester,
  su.term_year AS student_term_year
FROM payments p
LEFT JOIN sys_users su ON su.username = p.student_id
WHERE p.term_year IS NULL
  AND su.term_year IS NOT NULL
  AND su.term_year LIKE 'SL_%'
LIMIT 200;

-- ── UPDATE: tag untagged rows with the student's active SL term ──────────
UPDATE payments p
JOIN sys_users su ON su.username = p.student_id
SET p.term_year = su.term_year
WHERE p.term_year IS NULL
  AND su.term_year IS NOT NULL
  AND su.term_year LIKE 'SL_%';

-- ── FALLBACK: tag any remaining rows with the global active term ─────────
-- Uncomment if student-level tagging is not available for some rows.
/*
UPDATE payments p
JOIN (
  SELECT setting_value AS current_term
  FROM system_settings
  WHERE setting_key = 'CURRENT_ACADEMIC_TERM'
  LIMIT 1
) cfg ON 1=1
SET p.term_year = cfg.current_term
WHERE p.term_year IS NULL;
*/

-- ── VERIFY ───────────────────────────────────────────────────────────────
SELECT
  COUNT(*)                   AS total_payments,
  SUM(term_year IS NULL)     AS still_null,
  SUM(term_year IS NOT NULL) AS tagged
FROM payments;
