-- =============================================================================
-- Registrar demo rescue: professor grading account
-- =============================================================================
-- Purpose:
--   Reconnect the old `prof` login to the canonical faculty/class_sections model.
--   Safe to rerun. It does not reset data.
--
-- Login after running:
--   username: prof
--   password: 1234

USE eacdb;

SET @active_term_id := (
    SELECT term_id
    FROM academic_terms
    WHERE status = 'ACTIVE' OR is_active = 1
    ORDER BY term_id DESC
    LIMIT 1
);

SET @default_department_id := COALESCE(
    (SELECT department_id FROM programs WHERE program_code = 'BSIT' LIMIT 1),
    (SELECT department_id FROM departments ORDER BY department_id LIMIT 1),
    1
);

UPDATE sys_users
SET role = 'Faculty',
    is_active = 1,
    status = 'ACTIVE'
WHERE username = 'prof';

INSERT INTO faculty (
    employee_number,
    first_name,
    last_name,
    email,
    department_id,
    employment_type,
    max_teaching_units,
    active_status
)
SELECT
    'prof',
    'Professor',
    'Demo',
    'prof@school.edu.ph',
    @default_department_id,
    'FULL_TIME',
    24,
    1
WHERE NOT EXISTS (
    SELECT 1
    FROM faculty
    WHERE employee_number = 'prof'
);

SET @prof_faculty_id := (
    SELECT faculty_id
    FROM faculty
    WHERE employee_number = 'prof'
    ORDER BY faculty_id
    LIMIT 1
);

-- Prefer an active-term BSIT section that already has enrolled students.
SET @section_id := COALESCE(
    (
        SELECT cs.section_id
        FROM class_sections cs
        WHERE cs.term_id = @active_term_id
          AND cs.section_code LIKE 'BSIT%'
          AND EXISTS (
              SELECT 1
              FROM student_enlistments se
              WHERE se.section_id = cs.section_id
          )
        ORDER BY cs.section_id DESC
        LIMIT 1
    ),
    (
        SELECT cs.section_id
        FROM class_sections cs
        WHERE cs.term_id = @active_term_id
          AND cs.section_code LIKE 'BSIT%'
        ORDER BY cs.section_id DESC
        LIMIT 1
    ),
    (
        SELECT cs.section_id
        FROM class_sections cs
        WHERE cs.term_id = @active_term_id
        ORDER BY cs.section_id DESC
        LIMIT 1
    )
);

UPDATE class_sections
SET faculty_id = @prof_faculty_id,
    section_status = CASE
        WHEN section_status IN ('SUBMITTED', 'PENDING_APPROVAL') THEN section_status
        ELSE 'Open'
    END
WHERE section_id = @section_id
  AND @prof_faculty_id IS NOT NULL;

UPDATE class_schedules
SET faculty_id = @prof_faculty_id
WHERE section_id = @section_id
  AND @prof_faculty_id IS NOT NULL;

-- If the chosen section has no enlistments, attach one existing BSIT student so
-- the grade sheet is not blank. This is demo-only and repeat-safe.
SET @demo_student_number := COALESCE(
    (
        SELECT se.student_id
        FROM student_enlistments se
        JOIN class_sections cs ON cs.section_id = se.section_id
        WHERE cs.term_id = @active_term_id
        ORDER BY se.enlistment_id DESC
        LIMIT 1
    ),
    (
        SELECT student_number
        FROM students
        WHERE program_code = 'BSIT'
        ORDER BY student_number DESC
        LIMIT 1
    )
);

INSERT INTO student_enlistments (student_id, course_id, section_id)
SELECT @demo_student_number, cs.course_id, cs.section_id
FROM class_sections cs
WHERE cs.section_id = @section_id
  AND @demo_student_number IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM student_enlistments se
      WHERE se.student_id = @demo_student_number
        AND se.section_id = cs.section_id
  );

INSERT INTO grades (student_id, course_id, section_id, student_name, status, date_recorded)
SELECT
    se.student_id,
    se.course_id,
    se.section_id,
    COALESCE(
        NULLIF(TRIM(CONCAT(COALESCE(st.last_name, ''), ', ', COALESCE(st.first_name, ''))), ','),
        se.student_id
    ) AS student_name,
    'DRAFT',
    NOW()
FROM student_enlistments se
LEFT JOIN students st ON st.student_number = se.student_id
WHERE se.section_id = @section_id
  AND NOT EXISTS (
      SELECT 1
      FROM grades g
      WHERE g.student_id = se.student_id
        AND g.course_id = se.course_id
        AND g.section_id = se.section_id
  );

SELECT
    CASE
        WHEN @prof_faculty_id IS NULL THEN 'FAIL: faculty row for prof was not created.'
        WHEN @section_id IS NULL THEN 'FAIL: no active-term class section exists to assign.'
        WHEN (
            SELECT COUNT(*)
            FROM grades
            WHERE section_id = @section_id
        ) = 0 THEN 'FAIL: section assigned but no grade rows were created.'
        ELSE 'PASS: prof can open at least one active-term grading class.'
    END AS professor_grading_salvage_status;

SELECT
    su.username,
    f.faculty_id,
    cs.section_id,
    c.course_code,
    c.course_title,
    cs.section_code,
    cs.term_id,
    cs.section_status,
    (SELECT COUNT(*) FROM grades g WHERE g.section_id = cs.section_id) AS grade_rows
FROM sys_users su
JOIN faculty f ON f.employee_number = su.username
JOIN class_sections cs ON cs.faculty_id = f.faculty_id
JOIN courses c ON c.course_id = cs.course_id
WHERE su.username = 'prof'
  AND cs.section_id = @section_id;
