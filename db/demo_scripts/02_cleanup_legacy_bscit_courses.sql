-- Remove legacy BSCS-clone rows from curriculum views and block enlist lists.
-- Run after 00_seed_bsit_curriculum_set_official.sql on eacdb.

USE eacdb;

-- Typo from old seeds: AFCO 11 → official AECO 11 (Emilian Culture)
UPDATE courses SET course_code = 'AECO 11', course_title = 'Emilian Culture', active_status = 1
WHERE course_code IN ('AFCO 11', 'AFC0 11')
  AND NOT EXISTS (SELECT 1 FROM courses c2 WHERE c2.course_code = 'AECO 11' AND c2.course_id <> courses.course_id);

-- Drop curriculum links with missing year/sem (shows as "null / null" in UI)
DELETE cc FROM curriculum_courses cc
WHERE cc.year_level IS NULL OR cc.semester_number IS NULL;

-- Deactivate old IT/CC/GE codes not in SET BSIT (keep rows for grade history)
UPDATE courses
SET active_status = 0
WHERE course_code IN (
    'CC101', 'CC102', 'CC103', 'IT104',
    'GE101', 'GE102', 'GE103',
    'IT111', 'IT112', 'IT121', 'IT122',
    'IT211', 'IT212', 'IT221', 'IT222',
    'IT311', 'IT312', 'IT322', 'IT411', 'IT412', 'IT421', 'IT422',
    'NSTP101', 'PE101'
);

SELECT 'active legacy IT/CC still onlist' AS check_label, COUNT(*) AS cnt
FROM courses
WHERE course_code LIKE 'IT%' AND onlist = 1 AND active_status = 1;

SELECT p.program_code, cc.year_level, cc.semester_number, COUNT(*) AS subjects
FROM curriculum_courses cc
JOIN curriculum_templates ct ON cc.curriculum_id = ct.curriculum_id
JOIN programs p ON ct.program_id = p.program_id
WHERE ct.is_active = 1 AND p.program_code = 'BSIT'
GROUP BY p.program_code, cc.year_level, cc.semester_number
ORDER BY cc.year_level, cc.semester_number;
