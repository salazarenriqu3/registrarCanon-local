-- =============================================================================
-- BSIT class sections for block enlistment (all calendar terms)
-- Run AFTER:
--   00_upsert_academic_terms_calendar.sql
--   00_seed_bsit_curriculum_set_official.sql
--
-- Creates BSIT-{Y}-{S}-A on every calendar term where curriculum semester matches.
-- Creates BSIT-1-{S}-B on 1st/2nd sem terms for Year 1 only.
--
-- Enrollment resolves term_id via student SL_* → DB term_code (TermParserUtil).
-- Example: Elon Y1 S2 + SL_2120242025 → term 2120242025 → sections for cc.semester_number = 2.
-- =============================================================================
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;
USE eacdb;

INSERT INTO class_sections (course_id, term_id, section_code, max_capacity, section_status, semester_number)
SELECT DISTINCT
    c.course_id,
    at.term_id,
    CONCAT('BSIT-', cc.year_level, '-', cc.semester_number, '-A'),
    40,
    'Open',
    cc.semester_number
FROM curriculum_courses cc
JOIN curriculum_templates ct ON cc.curriculum_id = ct.curriculum_id
JOIN programs p ON ct.program_id = p.program_id
JOIN courses c ON cc.course_id = c.course_id
JOIN academic_terms at
    ON at.term_code REGEXP '^[12]1[0-9]{8}$'
   AND at.semester_number = cc.semester_number
WHERE p.program_code = 'BSIT'
  AND ct.is_active = 1
  AND COALESCE(c.onlist, 1) = 1
  AND NOT EXISTS (
      SELECT 1
      FROM class_sections cs
      WHERE cs.course_id = c.course_id
        AND cs.term_id = at.term_id
        AND cs.section_code = CONCAT('BSIT-', cc.year_level, '-', cc.semester_number, '-A')
  );

INSERT INTO class_sections (course_id, term_id, section_code, max_capacity, section_status, semester_number)
SELECT DISTINCT
    c.course_id,
    at.term_id,
    CONCAT('BSIT-', cc.year_level, '-', cc.semester_number, '-B'),
    40,
    'Open',
    cc.semester_number
FROM curriculum_courses cc
JOIN curriculum_templates ct ON cc.curriculum_id = ct.curriculum_id
JOIN programs p ON ct.program_id = p.program_id
JOIN courses c ON cc.course_id = c.course_id
JOIN academic_terms at
    ON at.term_code REGEXP '^[12]1[0-9]{8}$'
   AND at.semester_number = cc.semester_number
WHERE p.program_code = 'BSIT'
  AND ct.is_active = 1
  AND cc.year_level = 1
  AND cc.semester_number IN (1, 2)
  AND COALESCE(c.onlist, 1) = 1
  AND NOT EXISTS (
      SELECT 1
      FROM class_sections cs
      WHERE cs.course_id = c.course_id
        AND cs.term_id = at.term_id
        AND cs.section_code = CONCAT('BSIT-', cc.year_level, '-', cc.semester_number, '-B')
  );

-- Summary: sections per calendar term (BSIT only)
SELECT at.term_code, at.term_name, COUNT(DISTINCT cs.section_id) AS bsit_sections
FROM academic_terms at
LEFT JOIN class_sections cs ON cs.term_id = at.term_id AND cs.section_code LIKE 'BSIT-%'
WHERE at.term_code REGEXP '^[12]1[0-9]{8}$'
GROUP BY at.term_id, at.term_code, at.term_name
ORDER BY at.term_code;

-- Open-term hint (does not change ACTIVE flag)
SET @open = (SELECT setting_value FROM system_settings WHERE setting_key = 'CURRENT_ACADEMIC_TERM' LIMIT 1);
SET @open_db = IF(
    @open LIKE 'SL\_%' AND LENGTH(@open) >= 13,
    CONCAT(SUBSTRING(@open, 4, 1), '1', SUBSTRING(@open, 6, 4), SUBSTRING(@open, 10, 4)),
    @open
);
SELECT @open AS current_academic_term_setting,
       @open_db AS resolved_db_term_code,
       (SELECT term_name FROM academic_terms WHERE term_code = @open_db LIMIT 1) AS resolved_term_name;
