-- ============================================================
-- ADMIN HELPER SCRIPTS & PROCEDURES (UPDATED FOR LEGACY SCHEMA)
-- Project: EIR Registrar System - Scholarship Module
-- ============================================================
USE registrar_db_v2;

-- ------------------------------------------------------------
-- 1. VIEW: Student Grade Status Viewer
-- Instantly summarizes if a student has failed any subjects
-- based on the Jaypee Grading Engine (jp_grades).
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW view_scholarship_evaluator AS
SELECT 
    u.user_id,
    u.username,
    u.real_name,
    SUM(CASE WHEN g.status = 'FAILED' THEN 1 ELSE 0 END) AS failed_subjects_count
FROM sys_users u
JOIN jp_students js ON u.username = js.student_number
JOIN jp_grades g ON js.id = g.student_id
GROUP BY u.user_id, u.username, u.real_name;

-- ------------------------------------------------------------
-- 2. STORED PROCEDURE: Auto-Evaluate Internal Scholarships
-- Grants/Revokes Academic (Type 2) and Deans Lister (Type 3) 
-- based on whether they have ANY failed subjects.
-- ------------------------------------------------------------
DELIMITER 
DROP PROCEDURE IF EXISTS evaluate_internal_scholarships
CREATE PROCEDURE evaluate_internal_scholarships()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_user_id INT;
    DECLARE v_failed_count INT;
    
    DECLARE cur CURSOR FOR 
        SELECT user_id, failed_subjects_count 
        FROM view_scholarship_evaluator;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO v_user_id, v_failed_count;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Step A: Revoke active internal scholarships if they failed
        UPDATE student_scholarships ss
        JOIN scholarship_types st ON ss.type_id = st.type_id
        SET ss.status = 'REVOKED'
        WHERE ss.user_id = v_user_id 
          AND st.is_internal = 1
          AND ss.status = 'ACTIVE'
          AND v_failed_count > 0;

        -- Step B: Grant if they have zero failed grades
        IF v_failed_count = 0 THEN
            -- Randomly assign them to either Deans (3) or Academic (2) for demo tracking
            IF (RAND() < 0.5) THEN
                IF NOT EXISTS (SELECT 1 FROM student_scholarships WHERE user_id = v_user_id AND type_id = 3 AND status = 'ACTIVE') THEN
                    INSERT INTO student_scholarships (user_id, type_id, semester_id, status) VALUES (v_user_id, 3, 1, 'ACTIVE');
                END IF;
            ELSE
                IF NOT EXISTS (SELECT 1 FROM student_scholarships WHERE user_id = v_user_id AND type_id = 2 AND status = 'ACTIVE') THEN
                    INSERT INTO student_scholarships (user_id, type_id, semester_id, status) VALUES (v_user_id, 2, 1, 'ACTIVE');
                END IF;
            END IF;
        END IF;
        
    END LOOP;
    
    CLOSE cur;
END 
DELIMITER ;
