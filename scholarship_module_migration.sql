-- ============================================================
-- SCHOLARSHIP MODULE SCHEMA MIGRATION
-- Adds the `student_scholarships` table for the expanded scholarship tracking.
-- ============================================================

USE registrar_db_v2;

CREATE TABLE IF NOT EXISTS student_scholarships (
    scholarship_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    classification VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    discount_percentage DECIMAL(5,2) DEFAULT 0.00,
    awarded_term_year VARCHAR(30),
    last_evaluated_semester INT,
    last_evaluated_year INT,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES sys_users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
