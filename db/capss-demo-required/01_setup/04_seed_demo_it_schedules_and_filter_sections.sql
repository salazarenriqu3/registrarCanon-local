-- =============================================================================
-- DEMO IT SCHEDULES + CROSS-PROGRAM GEN ED FILTER SECTIONS
--
-- Run after 01_fresh_demo_bootstrap.sql, 02_bsit_full_align_term_and_curriculum.sql,
-- and 03_seed_program_fees_full_lifecycle.sql.
--
-- Safe to re-run. It upserts five demo sections and replaces schedules only for
-- those demo sections.
-- =============================================================================

USE eacdb;

SET @open_raw = (SELECT setting_value FROM system_settings WHERE setting_key = 'CURRENT_ACADEMIC_TERM' LIMIT 1);
SET @open_db = CASE
    WHEN @open_raw LIKE 'SL\_%' AND LENGTH(@open_raw) >= 13 THEN
        CONCAT(SUBSTRING(@open_raw, 4, 1), '1', SUBSTRING(@open_raw, 6, 4), SUBSTRING(@open_raw, 10, 4))
    ELSE @open_raw
END;
SET @term_id = COALESCE(
    (SELECT term_id FROM academic_terms WHERE term_code = @open_db LIMIT 1),
    (SELECT term_id FROM academic_terms WHERE status = 'ACTIVE' OR is_active = 1 ORDER BY term_id DESC LIMIT 1),
    (SELECT term_id FROM academic_terms WHERE term_code = '2120252026' LIMIT 1),
    (SELECT term_id FROM academic_terms ORDER BY term_id DESC LIMIT 1)
);
SET @dept_id = COALESCE((SELECT department_id FROM departments ORDER BY department_id LIMIT 1), 1);

INSERT INTO programs (program_code, program_name, department_id, school_name, active_status)
SELECT 'BSN', 'Bachelor of Science in Nursing', @dept_id, 'School of Nursing', 1
WHERE NOT EXISTS (SELECT 1 FROM programs WHERE program_code = 'BSN');

INSERT INTO programs (program_code, program_name, department_id, school_name, active_status)
SELECT 'BSBA', 'Bachelor of Science in Business Administration', @dept_id, 'School of Business', 1
WHERE NOT EXISTS (SELECT 1 FROM programs WHERE program_code = 'BSBA');

INSERT INTO programs (program_code, program_name, department_id, school_name, active_status)
SELECT 'BSHM', 'Bachelor of Science in Hospitality Management', @dept_id, 'School of Hospitality Management', 1
WHERE NOT EXISTS (SELECT 1 FROM programs WHERE program_code = 'BSHM');

INSERT INTO curriculum_templates (program_id, curriculum_name, academic_year, version_number, approval_status, is_active)
SELECT p.program_id, CONCAT(p.program_code, ' Demo Gen Ed Filter Curriculum'), '2025-2026', 1, 'Approved', 1
FROM programs p
WHERE p.program_code IN ('BSN', 'BSBA', 'BSHM')
  AND NOT EXISTS (
      SELECT 1 FROM curriculum_templates ct
      WHERE ct.program_id = p.program_id
        AND ct.curriculum_name = CONCAT(p.program_code, ' Demo Gen Ed Filter Curriculum')
  );

UPDATE curriculum_templates ct
JOIN programs p ON p.program_id = ct.program_id
SET ct.is_active = 1, ct.approval_status = 'Approved'
WHERE p.program_code IN ('BSN', 'BSBA', 'BSHM')
  AND ct.curriculum_name = CONCAT(p.program_code, ' Demo Gen Ed Filter Curriculum');

INSERT INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number, is_required)
SELECT ct.curriculum_id, c.course_id, 2, 2, 1
FROM curriculum_templates ct
JOIN programs p ON p.program_id = ct.program_id
JOIN courses c ON c.course_code = 'STS0 22'
WHERE p.program_code = 'BSN'
  AND ct.is_active = 1
  AND NOT EXISTS (
      SELECT 1 FROM curriculum_courses cc
      WHERE cc.curriculum_id = ct.curriculum_id AND cc.course_id = c.course_id
  );

INSERT INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number, is_required)
SELECT ct.curriculum_id, c.course_id, 2, 2, 1
FROM curriculum_templates ct
JOIN programs p ON p.program_id = ct.program_id
JOIN courses c ON c.course_code = 'AEN4 22'
WHERE p.program_code = 'BSBA'
  AND ct.is_active = 1
  AND NOT EXISTS (
      SELECT 1 FROM curriculum_courses cc
      WHERE cc.curriculum_id = ct.curriculum_id AND cc.course_id = c.course_id
  );

INSERT INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number, is_required)
SELECT ct.curriculum_id, c.course_id, 2, 2, 1
FROM curriculum_templates ct
JOIN programs p ON p.program_id = ct.program_id
JOIN courses c ON c.course_code = 'PE4 22'
WHERE p.program_code = 'BSHM'
  AND ct.is_active = 1
  AND NOT EXISTS (
      SELECT 1 FROM curriculum_courses cc
      WHERE cc.curriculum_id = ct.curriculum_id AND cc.course_id = c.course_id
  );

INSERT INTO class_sections (course_id, term_id, section_code, max_capacity, section_status, semester_number)
SELECT c.course_id, @term_id, v.section_code, v.max_capacity, 'Open', 2
FROM (
    SELECT 'UDS022' AS course_code, 'BSIT-DEMO-DSA-A' AS section_code, 35 AS max_capacity
    UNION ALL SELECT 'UDB122', 'BSIT-DEMO-DB-A', 35
    UNION ALL SELECT 'STS0 22', 'BSN-GE-STS-A', 45
    UNION ALL SELECT 'AEN4 22', 'BSBA-GE-BC-A', 45
    UNION ALL SELECT 'PE4 22', 'BSHM-GE-PE-A', 40
) v
JOIN courses c ON c.course_code = v.course_code
WHERE @term_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM class_sections cs
      WHERE cs.term_id = @term_id
        AND cs.course_id = c.course_id
        AND cs.section_code = v.section_code
  );

DELETE sch
FROM class_schedules sch
JOIN class_sections cs ON cs.section_id = sch.section_id
WHERE cs.term_id = @term_id
  AND cs.section_code IN ('BSIT-DEMO-DSA-A', 'BSIT-DEMO-DB-A', 'BSN-GE-STS-A', 'BSBA-GE-BC-A', 'BSHM-GE-PE-A');

INSERT INTO class_schedules (section_id, room_id, faculty_id, day_of_week, start_time, end_time, schedule_type, status)
SELECT cs.section_id, NULL, NULL, v.day_of_week, v.start_time, v.end_time, v.schedule_type, 'OPEN'
FROM (
    SELECT 'BSIT-DEMO-DSA-A' AS section_code, 1 AS day_of_week, '08:00:00' AS start_time, '09:30:00' AS end_time, 'Lecture' AS schedule_type
    UNION ALL SELECT 'BSIT-DEMO-DSA-A', 3, '08:00:00', '09:30:00', 'Lecture'
    UNION ALL SELECT 'BSIT-DEMO-DB-A', 2, '10:00:00', '11:30:00', 'Lecture'
    UNION ALL SELECT 'BSIT-DEMO-DB-A', 4, '10:00:00', '11:30:00', 'Lab'
    UNION ALL SELECT 'BSN-GE-STS-A', 1, '13:00:00', '14:30:00', 'Lecture'
    UNION ALL SELECT 'BSN-GE-STS-A', 3, '13:00:00', '14:30:00', 'Lecture'
    UNION ALL SELECT 'BSBA-GE-BC-A', 2, '14:00:00', '15:30:00', 'Lecture'
    UNION ALL SELECT 'BSBA-GE-BC-A', 4, '14:00:00', '15:30:00', 'Lecture'
    UNION ALL SELECT 'BSHM-GE-PE-A', 5, '09:00:00', '11:00:00', 'Activity'
) v
JOIN class_sections cs ON cs.section_code = v.section_code AND cs.term_id = @term_id;

-- Block enrollment uses the original BSIT-{year}-{sem}-A/B sections created by
-- 02_bsit_full_align_term_and_curriculum.sql, not the demo irregular sections.
-- Give every BSIT block section across the whole curriculum/term set a real
-- schedule so block enrollment and historical/current views do not display TBA.
DELETE sch
FROM class_schedules sch
JOIN class_sections cs ON cs.section_id = sch.section_id
WHERE cs.section_code REGEXP '^BSIT-[1-4]-[12]-[AB]$';

DROP TEMPORARY TABLE IF EXISTS bsit_block_schedule_slots;
CREATE TEMPORARY TABLE bsit_block_schedule_slots AS
SELECT
    ordered.section_id,
    ordered.course_id,
    ordered.section_code,
    ordered.term_id,
    ordered.lec_units,
    ordered.lab_units,
    ordered.credit_units,
    MOD(ordered.slot_no - 1, 12) AS slot_idx
FROM (
    SELECT
        cs.section_id,
        c.course_id,
        cs.section_code,
        cs.term_id,
        c.lec_units,
        c.lab_units,
        c.credit_units,
        ROW_NUMBER() OVER (
            PARTITION BY cs.term_id, cs.section_code
            ORDER BY cc.year_level, cc.semester_number, c.course_code, cs.section_id
        ) AS slot_no
    FROM class_sections cs
    JOIN courses c ON c.course_id = cs.course_id
    JOIN curriculum_courses cc ON cc.course_id = c.course_id
    JOIN curriculum_templates ct ON ct.curriculum_id = cc.curriculum_id AND ct.is_active = 1
    JOIN programs p ON p.program_id = ct.program_id AND p.program_code = 'BSIT'
    WHERE cs.section_code REGEXP '^BSIT-[1-4]-[12]-[AB]$'
) ordered;

INSERT INTO class_schedules (section_id, room_id, faculty_id, day_of_week, start_time, end_time, schedule_type, status)
SELECT
    slot.section_id,
    NULL,
    NULL,
    CASE slot.slot_idx
        WHEN 0 THEN 1
        WHEN 1 THEN 1
        WHEN 2 THEN 2
        WHEN 3 THEN 2
        WHEN 4 THEN 3
        WHEN 5 THEN 3
        WHEN 6 THEN 4
        WHEN 7 THEN 4
        WHEN 8 THEN 5
        WHEN 9 THEN 5
        WHEN 10 THEN 6
        ELSE 6
    END AS day_of_week,
    CASE slot.slot_idx
        WHEN 0 THEN '07:30:00'
        WHEN 1 THEN '09:00:00'
        WHEN 2 THEN '07:30:00'
        WHEN 3 THEN '09:00:00'
        WHEN 4 THEN '07:30:00'
        WHEN 5 THEN '09:00:00'
        WHEN 6 THEN '13:00:00'
        WHEN 7 THEN '14:30:00'
        WHEN 8 THEN '13:00:00'
        WHEN 9 THEN '14:30:00'
        WHEN 10 THEN '08:00:00'
        ELSE '10:00:00'
    END AS start_time,
    CASE slot.slot_idx
        WHEN 0 THEN '09:00:00'
        WHEN 1 THEN '10:30:00'
        WHEN 2 THEN '09:00:00'
        WHEN 3 THEN '10:30:00'
        WHEN 4 THEN '09:00:00'
        WHEN 5 THEN '10:30:00'
        WHEN 6 THEN '14:30:00'
        WHEN 7 THEN '16:00:00'
        WHEN 8 THEN '14:30:00'
        WHEN 9 THEN '16:00:00'
        WHEN 10 THEN '10:00:00'
        ELSE '12:00:00'
    END AS end_time,
    CASE WHEN COALESCE(slot.lab_units, 0) > 0 THEN 'Lab' ELSE 'Lecture' END AS schedule_type,
    'OPEN'
FROM bsit_block_schedule_slots slot;

-- Keep BSIT block sections to one generated meeting row per course. The block
-- package must be conflict-free for demo enrollment; contact-hour realism is
-- less important than a clean block-enroll flow here.

-- Irregular/manual enlistment can fetch any section connected to an active
-- curriculum, including cross-program Gen Ed and future demo programs. Fill any
-- remaining unscheduled curriculum-backed section so the UI does not show TBA.
INSERT INTO class_schedules (section_id, room_id, faculty_id, day_of_week, start_time, end_time, schedule_type, status)
SELECT
    cs.section_id,
    NULL,
    NULL,
    CASE MOD(cs.section_id + c.course_id + COALESCE(cs.term_id, 0), 6)
        WHEN 0 THEN 1
        WHEN 1 THEN 2
        WHEN 2 THEN 3
        WHEN 3 THEN 4
        WHEN 4 THEN 5
        ELSE 6
    END AS day_of_week,
    CASE MOD(cs.section_id + c.course_id + COALESCE(cs.term_id, 0), 10)
        WHEN 0 THEN '07:00:00'
        WHEN 1 THEN '08:00:00'
        WHEN 2 THEN '09:00:00'
        WHEN 3 THEN '10:00:00'
        WHEN 4 THEN '11:00:00'
        WHEN 5 THEN '13:00:00'
        WHEN 6 THEN '14:00:00'
        WHEN 7 THEN '15:00:00'
        WHEN 8 THEN '16:00:00'
        ELSE '17:00:00'
    END AS start_time,
    CASE MOD(cs.section_id + c.course_id + COALESCE(cs.term_id, 0), 10)
        WHEN 0 THEN '08:30:00'
        WHEN 1 THEN '09:30:00'
        WHEN 2 THEN '10:30:00'
        WHEN 3 THEN '11:30:00'
        WHEN 4 THEN '12:30:00'
        WHEN 5 THEN '14:30:00'
        WHEN 6 THEN '15:30:00'
        WHEN 7 THEN '16:30:00'
        WHEN 8 THEN '17:30:00'
        ELSE '18:30:00'
    END AS end_time,
    CASE WHEN COALESCE(c.lab_units, 0) > 0 THEN 'Lab' ELSE 'Lecture' END AS schedule_type,
    'OPEN'
FROM class_sections cs
JOIN courses c ON c.course_id = cs.course_id
WHERE EXISTS (
    SELECT 1
    FROM curriculum_courses cc
    JOIN curriculum_templates ct ON ct.curriculum_id = cc.curriculum_id
    WHERE cc.course_id = cs.course_id
      AND ct.is_active = 1
)
AND NOT EXISTS (
    SELECT 1 FROM class_schedules existing
    WHERE existing.section_id = cs.section_id
);

-- Give remaining unscheduled 3-unit lecture sections a second weekly meeting
-- as well. This catches Gen Ed service sections from any active curriculum.
INSERT INTO class_schedules (section_id, room_id, faculty_id, day_of_week, start_time, end_time, schedule_type, status)
SELECT
    cs.section_id,
    NULL,
    NULL,
    CASE MOD(cs.section_id + c.course_id + COALESCE(cs.term_id, 0), 6)
        WHEN 0 THEN 3
        WHEN 1 THEN 4
        WHEN 2 THEN 5
        WHEN 3 THEN 1
        WHEN 4 THEN 2
        ELSE 4
    END AS day_of_week,
    CASE MOD(cs.section_id + c.course_id + COALESCE(cs.term_id, 0), 10)
        WHEN 0 THEN '07:00:00'
        WHEN 1 THEN '08:00:00'
        WHEN 2 THEN '09:00:00'
        WHEN 3 THEN '10:00:00'
        WHEN 4 THEN '11:00:00'
        WHEN 5 THEN '13:00:00'
        WHEN 6 THEN '14:00:00'
        WHEN 7 THEN '15:00:00'
        WHEN 8 THEN '16:00:00'
        ELSE '17:00:00'
    END AS start_time,
    CASE MOD(cs.section_id + c.course_id + COALESCE(cs.term_id, 0), 10)
        WHEN 0 THEN '08:30:00'
        WHEN 1 THEN '09:30:00'
        WHEN 2 THEN '10:30:00'
        WHEN 3 THEN '11:30:00'
        WHEN 4 THEN '12:30:00'
        WHEN 5 THEN '14:30:00'
        WHEN 6 THEN '15:30:00'
        WHEN 7 THEN '16:30:00'
        WHEN 8 THEN '17:30:00'
        ELSE '18:30:00'
    END AS end_time,
    'Lecture',
    'OPEN'
FROM class_sections cs
JOIN courses c ON c.course_id = cs.course_id
WHERE COALESCE(c.lab_units, 0) = 0
  AND COALESCE(c.lec_units, c.credit_units, 0) >= 3
  AND EXISTS (
      SELECT 1
      FROM curriculum_courses cc
      JOIN curriculum_templates ct ON ct.curriculum_id = cc.curriculum_id
      WHERE cc.course_id = cs.course_id
        AND ct.is_active = 1
  )
  AND (
      SELECT COUNT(*) FROM class_schedules existing
      WHERE existing.section_id = cs.section_id
  ) = 1;

SELECT cs.section_code,
       c.course_code,
       c.course_title,
       GROUP_CONCAT(
           CONCAT(
               CASE sch.day_of_week
                   WHEN 1 THEN 'MON'
                   WHEN 2 THEN 'TUE'
                   WHEN 3 THEN 'WED'
                   WHEN 4 THEN 'THU'
                   WHEN 5 THEN 'FRI'
                   WHEN 6 THEN 'SAT'
                   ELSE 'SUN'
               END,
               ' ',
               TIME_FORMAT(sch.start_time, '%h:%i %p'),
               '-',
               TIME_FORMAT(sch.end_time, '%h:%i %p')
           )
           ORDER BY sch.day_of_week SEPARATOR ' | '
       ) AS demo_schedule
FROM class_sections cs
JOIN courses c ON c.course_id = cs.course_id
JOIN class_schedules sch ON sch.section_id = cs.section_id
WHERE cs.term_id = @term_id
  AND (
      cs.section_code IN ('BSIT-DEMO-DSA-A', 'BSIT-DEMO-DB-A', 'BSN-GE-STS-A', 'BSBA-GE-BC-A', 'BSHM-GE-PE-A')
      OR cs.section_code REGEXP '^BSIT-[1-4]-[12]-[AB]$'
  )
GROUP BY cs.section_code, c.course_code, c.course_title
ORDER BY cs.section_code;

SELECT 'Unscheduled curriculum-backed sections after demo schedule seed' AS check_name,
       COUNT(*) AS unscheduled_count
FROM class_sections cs
WHERE EXISTS (
    SELECT 1
    FROM curriculum_courses cc
    JOIN curriculum_templates ct ON ct.curriculum_id = cc.curriculum_id
    WHERE cc.course_id = cs.course_id
      AND ct.is_active = 1
)
AND NOT EXISTS (
    SELECT 1 FROM class_schedules sch WHERE sch.section_id = cs.section_id
);

SELECT 'BSIT same-block schedule overlaps after demo schedule seed' AS check_name,
       COUNT(*) AS overlap_count
FROM class_sections cs1
JOIN class_sections cs2
  ON cs2.term_id = cs1.term_id
 AND cs2.section_code = cs1.section_code
 AND cs2.section_id > cs1.section_id
JOIN class_schedules s1 ON s1.section_id = cs1.section_id
JOIN class_schedules s2 ON s2.section_id = cs2.section_id
 AND s2.day_of_week = s1.day_of_week
 AND s1.start_time < s2.end_time
 AND s2.start_time < s1.end_time
WHERE cs1.section_code REGEXP '^BSIT-[1-4]-[12]-[AB]$';
