-- ============================================================
-- hotfix_admission_status_and_names.sql
-- Run once to fix existing students that:
--   1. Show ADMITTED despite already having enlistments
--   2. Have blank first_name / last_name (only real_name was set)
-- ============================================================

USE eacdb;
SET SQL_SAFE_UPDATES = 0;

-- -------------------------------------------------------
-- FIX 1: Flip ADMITTED -> ENROLLED for students who
--         already have at least one student_enlistment
-- -------------------------------------------------------
UPDATE sys_users u
SET    u.admission_status = 'ENROLLED'
WHERE  u.role = 'Student'
  AND  (u.admission_status = 'ADMITTED' OR u.admission_status IS NULL)
  AND  EXISTS (
      SELECT 1 FROM student_enlistments se WHERE se.student_id = u.user_id
  );

-- -------------------------------------------------------
-- FIX 2: Back-fill first_name / last_name from real_name
--         for students where those columns are empty/null
--         but real_name has a value.
--
-- Strategy:  last word  -> last_name
--            everything before last word -> first_name
-- -------------------------------------------------------
UPDATE sys_users u
SET
    u.last_name  = TRIM(SUBSTRING_INDEX(u.real_name, ' ', -1)),
    u.first_name = TRIM(
                     CASE
                       WHEN LOCATE(' ', u.real_name) > 0
                       THEN SUBSTRING(u.real_name, 1, CHAR_LENGTH(u.real_name) - CHAR_LENGTH(SUBSTRING_INDEX(u.real_name, ' ', -1)) - 1)
                       ELSE u.real_name
                     END
                   )
WHERE  u.role = 'Student'
  AND  u.real_name IS NOT NULL
  AND  TRIM(u.real_name) <> ''
  AND  (u.first_name IS NULL OR TRIM(u.first_name) = '')
  AND  (u.last_name  IS NULL OR TRIM(u.last_name)  = '');

SET SQL_SAFE_UPDATES = 1;

SELECT
    username         AS student_no,
    real_name,
    first_name,
    last_name,
    admission_status AS status
FROM sys_users
WHERE role = 'Student'
ORDER BY user_id;
