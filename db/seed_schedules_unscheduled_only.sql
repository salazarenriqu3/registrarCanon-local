-- =============================================================================
-- Schedules for sections that have NONE yet (append-only, no wipe)
-- Set @target_term_id to limit one calendar term, or NULL for all terms.
-- Requires rooms + faculty (seed_all_class_schedules.sql sections 1-2 once).
-- =============================================================================
USE eacdb;
SET SQL_SAFE_UPDATES = 0;

SET @target_term_id = NULL;

INSERT INTO class_schedules (section_id, room_id, faculty_id, day_of_week, start_time, end_time, schedule_type, status)
SELECT
    slot.section_id,
    (SELECT MIN(room_id) FROM rooms) AS room_id,
    NULL AS faculty_id,
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
        cs.course_id,
        cs.term_id,
        c.lab_units,
        ROW_NUMBER() OVER (
            PARTITION BY cs.term_id, cs.section_code
            ORDER BY c.course_code, cs.section_id
        ) AS slot_no
    FROM class_sections cs
    JOIN courses c ON c.course_id = cs.course_id
    WHERE NOT EXISTS (SELECT 1 FROM class_schedules sch WHERE sch.section_id = cs.section_id)
      AND (@target_term_id IS NULL OR cs.term_id = @target_term_id)
) slot;

UPDATE class_sections cs
SET cs.section_status = 'Open'
WHERE (cs.section_status IS NULL OR cs.section_status = 'Planning')
  AND (@target_term_id IS NULL OR cs.term_id = @target_term_id);

SELECT at.term_code,
       COUNT(DISTINCT cs.section_id) AS sections,
       SUM(CASE WHEN sch.schedule_id IS NULL THEN 1 ELSE 0 END) AS still_unscheduled
FROM academic_terms at
JOIN class_sections cs ON cs.term_id = at.term_id
LEFT JOIN class_schedules sch ON sch.section_id = cs.section_id
WHERE at.term_code REGEXP '^[12]1[0-9]{8}$'
  AND (@target_term_id IS NULL OR at.term_id = @target_term_id)
GROUP BY at.term_id, at.term_code
ORDER BY at.term_code;
