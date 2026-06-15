-- ============================================================
-- FIX: Credit units now include Lab units (Lec + Lab)
-- Source: SET BSIT.docx and SET COE.docx
-- Rev. 24 May 2026
-- ============================================================
USE eacdb;
SET SQL_SAFE_UPDATES = 0;

-- ── BSIT: courses where lab = 1 (stored as lec only, should be lec+1) ────
UPDATE courses SET credit_units = 3 WHERE course_code IN (
    'UPR1 11',   -- Fundamentals of Problem Solving & Programming (2+1)
    'UHC1 11',   -- Introduction to Human Computer Interaction (2+1)
    'UPR2 12',   -- Advanced Problem Solving & Programming (2+1)
    'UPR3 21',   -- Object Oriented Programming (2+1)
    'UIM0 12',   -- Introduction to Information Management (2+1)
    'UDB122',    -- Database Management System 1 (2+1)
    'UDS022',    -- Data Structures and Algorithms (2+1)
    'UNW122',    -- Networking 1 (2+1)
    'USI1 31',   -- System Integration and Architecture 1 (2+1)
    'UNW2 31',   -- Networking 2 (2+1)
    'UEL2 31',   -- Tangible Technologies (2+1)
    'UEL131',    -- Intangible Technologies (2+1)
    'UDB231',    -- Advanced Database Systems (2+1)
    'UADET 32',  -- Application Development and Emerging Technologies (2+1)
    'UEDP0 32',  -- Event Driven Programming (2+1)
    'UIAS1 32',  -- Information Assurance and Security 1 (2+1)
    'UIAS2 41',  -- Information Assurance and Security 2 (2+1)
    'USAM0 41',  -- Systems Administration and Maintenance (2+1)
    'USI1 41'    -- System Integration and Architecture 2 (2+1)
);

-- ── COE: courses with lab = 1 (lec+1) ─────────────────────────────────────
UPDATE courses SET credit_units = 3 WHERE course_code IN (
    'UNM0 22',   -- Numerical Method (2+1)
    'UDR2 31',   -- Computer Aided Drafting (0+1 → was 0, now 1)
    'UIH0 31',   -- Intro to Hardware Description Language (0+1 → was 0, now 1)
    'UFMS31',    -- Fundamental of Mixed Signals and Sensors (2+1)
    'UFCS31',    -- Feedback and Control Systems (2+1)
    'UDDC31',    -- Data and Digital Communications (2+1)
    'UML1 31',   -- Cognate/Elective 1 ML 1 (2+1)
    'UML2 32',   -- Cognate/Elective 2 ML 2 (2+1)
    'UML3 41',   -- Cognate/Elective 3 ML 3 (2+1)
    'UOS0 41'    -- Operating Systems (2+1)
);

-- COE: pure-lab courses (0 lec + 1 lab = 1 unit)
UPDATE courses SET credit_units = 1 WHERE course_code IN (
    'UDR2 31',   -- Computer Aided Drafting (0+1)
    'UIH0 31',   -- Intro to Hardware Description Language (0+1)
    'UDR3 32'    -- Computer Engineering Drafting and Design (0+1)
);

-- COE: courses with lab = 1 added to lec of 3 → 4 units
UPDATE courses SET credit_units = 4 WHERE course_code IN (
    'SCH411',    -- Chemistry for Engineers (3+1)
    'SPH1 12',   -- Physics for Engineers (3+1)
    'UPR4 21',   -- Object Oriented Programming COE (3+1)
    'UFEC21',    -- Fundamentals of Electrical Circuits (3+1)
    'UFEC22',    -- Fundamentals of Electronic Circuits (3+1)
    'UDS1 12',   -- Data Structures and Algorithm Analysis (3+1)
    'ULCD31',    -- Logic Circuits and Design (3+1)
    'UMC0 32',   -- Microprocessor (3+1)
    'UCNS32',    -- Computer Networks and Society (3+1)
    'USD31',     -- Software Design (3+1)
    'UES0 41',   -- Embedded Systems (3+1)
    'UDS0 41',   -- Digital Signal Processing (3+1)
    'UCAO41'     -- Computer Architecture and Organization (3+1)
);

-- COE: pure lab 2 units
UPDATE courses SET credit_units = 2 WHERE course_code = 'UPLD11'; -- Programming Logic and Design (0+2)

-- COE: UPD1 41 is 1+0 = 1 unit (already 1 in docx, check)
-- .docx says: 1 Lec + 0 Lab = 1 unit → already correct in DB

-- ── Verify final counts ─────────────────────────────────────────────────
SELECT
    c.course_code,
    c.course_title,
    c.credit_units AS units_in_db
FROM curriculum_courses cc
JOIN courses c ON cc.course_id = c.course_id
JOIN curriculum_templates ct ON cc.curriculum_id = ct.curriculum_id
WHERE ct.curriculum_name IN ('SET BSIT Curriculum','SET COE Curriculum')
ORDER BY ct.curriculum_name, cc.year_level, cc.semester_number, c.course_code;

SET SQL_SAFE_UPDATES = 1;
