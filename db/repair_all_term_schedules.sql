-- =============================================================================
-- REPAIR ALL TERM SCHEDULES (full DB cleanup for LAB-301 stamp)
-- Rebuilds staggered slots for every term; rooms cleared to TBA.
-- =============================================================================
USE eacdb;
SET SQL_SAFE_UPDATES = 0;

DELETE FROM class_schedules;

-- Clear demo mass-faculty stamp (one professor on thousands of sections)
UPDATE class_sections cs
JOIN (
    SELECT cs2.faculty_id, cs2.term_id, COUNT(*) AS section_count, f.max_teaching_units
    FROM class_sections cs2
    JOIN faculty f ON f.faculty_id = cs2.faculty_id
    WHERE cs2.faculty_id IS NOT NULL
    GROUP BY cs2.faculty_id, cs2.term_id, f.max_teaching_units
    HAVING section_count > COALESCE(NULLIF(f.max_teaching_units, 0), 18)
) hot ON hot.faculty_id = cs.faculty_id AND hot.term_id = cs.term_id
SET cs.faculty_id = NULL;

INSERT INTO class_schedules (section_id, room_id, faculty_id, day_of_week, start_time, end_time, schedule_type, status)
SELECT
    slot.section_id,
    NULL AS room_id,
    slot.faculty_id,
    MOD(slot.slot_no - 1, 5) + 1 AS day_of_week,
    CASE FLOOR((slot.slot_no - 1) / 5) MOD 5
        WHEN 0 THEN '07:30:00'
        WHEN 1 THEN '09:00:00'
        WHEN 2 THEN '10:30:00'
        WHEN 3 THEN '13:00:00'
        ELSE '14:30:00'
    END AS start_time,
    CASE FLOOR((slot.slot_no - 1) / 5) MOD 5
        WHEN 0 THEN '09:00:00'
        WHEN 1 THEN '10:30:00'
        WHEN 2 THEN '12:00:00'
        WHEN 3 THEN '14:30:00'
        ELSE '16:00:00'
    END AS end_time,
    CASE WHEN COALESCE(slot.lab_units, 0) > 0 THEN 'Lab' ELSE 'Lecture' END AS schedule_type,
    'OPEN'
FROM (
    SELECT
        cs.section_id,
        cs.faculty_id,
        c.lab_units,
        ROW_NUMBER() OVER (
            PARTITION BY cs.term_id
            ORDER BY cs.section_code, c.course_code, cs.section_id
        ) AS slot_no
    FROM class_sections cs
    JOIN courses c ON c.course_id = cs.course_id
) slot;

SELECT cs.term_id,
       COUNT(*) AS schedule_rows,
       SUM(CASE WHEN sch.room_id IS NOT NULL THEN 1 ELSE 0 END) AS rows_with_room
FROM class_schedules sch
JOIN class_sections cs ON cs.section_id = sch.section_id
GROUP BY cs.term_id
ORDER BY cs.term_id;

SET SQL_SAFE_UPDATES = 1;
