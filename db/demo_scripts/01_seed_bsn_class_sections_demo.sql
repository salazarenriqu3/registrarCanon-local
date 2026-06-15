-- =============================================================================
-- BSN class sections and schedules for full lifecycle testing
--
-- Run AFTER:
--   00_upsert_academic_terms_calendar.sql
--   00_seed_bsn_curriculum_marian_official.sql
--
-- Creates:
--   BSN-{Y}-{S}-A on every calendar term where semester matches.
--   BSN-1-{S}-B for Year 1 second-block testing.
--   One simple OPEN schedule row per course section.
--
-- Safe to re-run. Does not delete enlistments, grades, payments, or ledger rows.
-- =============================================================================
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;
USE eacdb;

-- Open primary A blocks across all lifecycle terms.
INSERT INTO class_sections (course_id, term_id, section_code, max_capacity, section_status, semester_number)
SELECT DISTINCT
    c.course_id,
    at.term_id,
    CONCAT('BSN-', cc.year_level, '-', cc.semester_number, '-A'),
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
WHERE p.program_code = 'BSN'
  AND ct.is_active = 1
  AND COALESCE(c.onlist, 1) = 1
  AND NOT EXISTS (
      SELECT 1
      FROM class_sections cs
      WHERE cs.course_id = c.course_id
        AND cs.term_id = at.term_id
        AND cs.section_code = CONCAT('BSN-', cc.year_level, '-', cc.semester_number, '-A')
  );

-- Optional second block for first-year intake testing.
INSERT INTO class_sections (course_id, term_id, section_code, max_capacity, section_status, semester_number)
SELECT DISTINCT
    c.course_id,
    at.term_id,
    CONCAT('BSN-', cc.year_level, '-', cc.semester_number, '-B'),
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
WHERE p.program_code = 'BSN'
  AND ct.is_active = 1
  AND cc.year_level = 1
  AND cc.semester_number IN (1, 2)
  AND COALESCE(c.onlist, 1) = 1
  AND NOT EXISTS (
      SELECT 1
      FROM class_sections cs
      WHERE cs.course_id = c.course_id
        AND cs.term_id = at.term_id
        AND cs.section_code = CONCAT('BSN-', cc.year_level, '-', cc.semester_number, '-B')
  );

-- Make all generated BSN sections explicitly open.
UPDATE class_sections cs
JOIN courses c ON c.course_id = cs.course_id
JOIN curriculum_courses cc ON cc.course_id = c.course_id
JOIN curriculum_templates ct ON ct.curriculum_id = cc.curriculum_id
JOIN programs p ON p.program_id = ct.program_id
SET cs.section_status = 'Open',
    cs.max_capacity = COALESCE(cs.max_capacity, 40),
    cs.semester_number = cc.semester_number
WHERE p.program_code = 'BSN'
  AND ct.is_active = 1
  AND cs.section_code LIKE 'BSN-%';

-- Insert one deterministic schedule row per BSN section. No duplicate on rerun.
INSERT INTO class_schedules (section_id, room_id, faculty_id, day_of_week, start_time, end_time, schedule_type, status)
SELECT
    x.section_id,
    NULL,
    NULL,
    ((x.rn - 1) % 5) + 1 AS day_of_week,
    CASE FLOOR((x.rn - 1) / 5) % 4
        WHEN 0 THEN '07:30:00'
        WHEN 1 THEN '09:30:00'
        WHEN 2 THEN '13:00:00'
        ELSE '15:00:00'
    END AS start_time,
    CASE FLOOR((x.rn - 1) / 5) % 4
        WHEN 0 THEN '09:00:00'
        WHEN 1 THEN '11:00:00'
        WHEN 2 THEN '14:30:00'
        ELSE '16:30:00'
    END AS end_time,
    CASE WHEN COALESCE(x.lab_units, 0) > 0 THEN 'Mixed' ELSE 'Lecture' END AS schedule_type,
    'OPEN'
FROM (
    SELECT
        cs.section_id,
        c.lab_units,
        ROW_NUMBER() OVER (
            PARTITION BY cs.term_id, cs.section_code
            ORDER BY c.course_code
        ) AS rn
    FROM class_sections cs
    JOIN courses c ON c.course_id = cs.course_id
    WHERE cs.section_code LIKE 'BSN-%'
) x
WHERE NOT EXISTS (
    SELECT 1
    FROM class_schedules sch
    WHERE sch.section_id = x.section_id
);

-- Summary: BSN sections and schedules per calendar term.
SELECT at.term_code, at.term_name,
       COUNT(DISTINCT cs.section_id) AS bsn_sections,
       COUNT(DISTINCT sch.schedule_id) AS bsn_schedules
FROM academic_terms at
LEFT JOIN class_sections cs
    ON cs.term_id = at.term_id
   AND cs.section_code LIKE 'BSN-%'
LEFT JOIN class_schedules sch
    ON sch.section_id = cs.section_id
WHERE at.term_code REGEXP '^[12]1[0-9]{8}$'
GROUP BY at.term_id, at.term_code, at.term_name
ORDER BY at.term_code;

-- Curriculum term slices expected during block enlistment.
SELECT cc.year_level, cc.semester_number, COUNT(*) AS subjects, SUM(c.credit_units) AS units
FROM curriculum_courses cc
JOIN curriculum_templates ct ON ct.curriculum_id = cc.curriculum_id
JOIN programs p ON p.program_id = ct.program_id
JOIN courses c ON c.course_id = cc.course_id
WHERE p.program_code = 'BSN'
  AND ct.is_active = 1
GROUP BY cc.year_level, cc.semester_number
ORDER BY cc.year_level, cc.semester_number;
