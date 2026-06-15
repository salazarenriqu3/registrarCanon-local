-- ============================================================
-- P1-12: Address legacy student_id keys in Registrar tables
--
-- Background: Some older rows in student_enlistments / grades use
-- an integer user_id (or NULL) instead of the string student_number.
-- This script identifies and optionally migrates those rows.
--
-- SAFE TO RUN: All writes are guarded by WHERE clauses.
-- HOW TO RUN:
--   1. Run the PREVIEW SELECTs to understand the scope.
--   2. Uncomment the UPDATE/FIX blocks once reviewed.
-- ============================================================
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;
USE eacdb;

-- ── PREVIEW: grades rows where student_id looks numeric (old int key) ────
SELECT
  g.grade_id,
  g.student_id,
  su.username AS correct_student_number
FROM grades g
JOIN sys_users su ON su.user_id = g.student_id REGEXP '^[0-9]+$'
               AND CAST(su.user_id AS CHAR) = g.student_id
WHERE g.student_id REGEXP '^[0-9]+$'
LIMIT 100;

-- ── FIX: remap numeric grade.student_id → student_number string ──────────
-- Uncomment after reviewing preview.
/*
UPDATE grades g
JOIN sys_users su ON CAST(su.user_id AS CHAR) = g.student_id
SET g.student_id = su.username
WHERE g.student_id REGEXP '^[0-9]+$'
  AND su.username IS NOT NULL
  AND su.username <> '';
*/

-- ── PREVIEW: student_enlistments rows with numeric student_id ────────────
SELECT
  se.enlistment_id,
  se.student_id,
  su.username AS correct_student_number
FROM student_enlistments se
JOIN sys_users su ON CAST(su.user_id AS CHAR) = se.student_id
WHERE se.student_id REGEXP '^[0-9]+$'
LIMIT 100;

-- ── FIX: remap numeric enlistment.student_id → student_number string ─────
-- Uncomment after reviewing preview.
/*
UPDATE student_enlistments se
JOIN sys_users su ON CAST(su.user_id AS CHAR) = se.student_id
SET se.student_id = su.username
WHERE se.student_id REGEXP '^[0-9]+$'
  AND su.username IS NOT NULL
  AND su.username <> '';
*/

-- ── PREVIEW: student_ledger rows with numeric student_id ─────────────────
SELECT
  sl.ledger_id,
  sl.student_id,
  su.username AS correct_student_number
FROM student_ledger sl
JOIN sys_users su ON CAST(su.user_id AS CHAR) = sl.student_id
WHERE sl.student_id REGEXP '^[0-9]+$'
LIMIT 100;

-- ── FIX: remap numeric ledger.student_id → student_number string ─────────
-- Uncomment after reviewing preview.
/*
UPDATE student_ledger sl
JOIN sys_users su ON CAST(su.user_id AS CHAR) = sl.student_id
SET sl.student_id = su.username
WHERE sl.student_id REGEXP '^[0-9]+$'
  AND su.username IS NOT NULL
  AND su.username <> '';
*/

-- ── VERIFY ────────────────────────────────────────────────────────────────
SELECT
  'grades'               AS tbl,
  SUM(student_id REGEXP '^[0-9]+$') AS numeric_ids,
  COUNT(*)                           AS total
FROM grades
UNION ALL
SELECT
  'student_enlistments',
  SUM(student_id REGEXP '^[0-9]+$'),
  COUNT(*)
FROM student_enlistments
UNION ALL
SELECT
  'student_ledger',
  SUM(student_id REGEXP '^[0-9]+$'),
  COUNT(*)
FROM student_ledger;
