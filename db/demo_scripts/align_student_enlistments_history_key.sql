-- ============================================================
-- Align student_enlistments key with historical ledger logic
--
-- Why:
--   student_enlistments is now preserved across terms for read/print
--   history. A global UNIQUE(student_id, course_id) blocks legitimate
--   later-term retakes/re-enlistments. Application services enforce
--   duplicate-course prevention within the active term.
--
-- Safe to run more than once.
-- ============================================================
USE eacdb;

SET @has_old_unique := (
  SELECT COUNT(*)
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'student_enlistments'
    AND index_name = 'uq_student_course'
);

SET @sql := IF(
  @has_old_unique > 0,
  'ALTER TABLE student_enlistments DROP INDEX uq_student_course',
  'SELECT ''uq_student_course already absent'' AS note'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_new_index := (
  SELECT COUNT(*)
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'student_enlistments'
    AND index_name = 'idx_se_student_course'
);

SET @sql := IF(
  @has_new_index = 0,
  'ALTER TABLE student_enlistments ADD INDEX idx_se_student_course (student_id, course_id)',
  'SELECT ''idx_se_student_course already present'' AS note'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SHOW INDEX FROM student_enlistments
WHERE Key_name IN ('uq_student_course', 'idx_se_student_course', 'idx_se_student');
