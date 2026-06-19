package com.iuims.registrar.academic;

import com.iuims.registrar.faculty.FacultyLoadService;
import com.iuims.registrar.faculty.FacultyProvisioningService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

import static org.assertj.core.api.Assertions.assertThat;

class SectionSchedulingServiceTest {

    private JdbcTemplate db;
    private SectionSchedulingService service;

    @BeforeEach
    void setUp() {
        DriverManagerDataSource dataSource = new DriverManagerDataSource(
            "jdbc:h2:mem:section-sched-" + System.nanoTime() + ";MODE=MySQL;DB_CLOSE_DELAY=-1", "sa", "");
        db = new JdbcTemplate(dataSource);
        seedSchema();
        FacultyLoadService loadService = new FacultyLoadService();
        injectJdbc(loadService, db);
        FacultyProvisioningService provisioningService = new FacultyProvisioningService(db);
        service = new SectionSchedulingService(db, loadService, provisioningService);
    }

    @Test
    void assignFacultyRejectsOverload() {
        int sectionId = insertSection(1, 1, 3);
        int overloadedSection = insertSection(2, 1, 16);
        db.update("UPDATE class_sections SET faculty_id = 1 WHERE section_id = ?", overloadedSection);

        String result = service.assignFaculty(sectionId, 1);

        assertThat(result).contains("unit cap");
    }

    @Test
    void distributeBlockFacultyProvisionsWhenCapacityMissing() {
        db.update(
            "INSERT INTO block_offerings (block_id, term_id, program_code, year_level, semester_number, section_group, max_capacity, curriculum_id) " +
                "VALUES (1, 1, 'BSCPE', 1, 1, 'A', 40, 1)");
        int sectionA = insertSection(1, 1, 12);
        db.update("UPDATE class_sections SET block_id = 1, section_code = 'BSCPE-1-1-A' WHERE section_id = ?", sectionA);
        int sectionB = insertSection(2, 1, 10);
        db.update("UPDATE class_sections SET block_id = 1, section_code = 'BSCPE-1-1-A' WHERE section_id = ?", sectionB);

        SectionSchedulingService.FacultyDistributionResult result = service.distributeBlockFaculty(1, 1);

        assertThat(result.sectionsAssigned()).isEqualTo(2);
        assertThat(result.facultyProvisioned()).isGreaterThanOrEqualTo(1);
    }

    private void seedSchema() {
        db.execute("CREATE TABLE departments (department_id INT PRIMARY KEY, department_code VARCHAR(20), department_name VARCHAR(120))");
        db.execute("CREATE TABLE programs (program_id INT PRIMARY KEY, program_code VARCHAR(32), department_id INT)");
        db.execute("CREATE TABLE faculty (faculty_id INT AUTO_INCREMENT PRIMARY KEY, employee_number VARCHAR(40), first_name VARCHAR(80), last_name VARCHAR(80), department_id INT, employment_type VARCHAR(40), max_teaching_units INT, active_status INT DEFAULT 1)");
        db.execute("CREATE TABLE courses (course_id INT PRIMARY KEY, course_code VARCHAR(32), course_title VARCHAR(120), credit_units INT, is_coordinator_based INT DEFAULT 0, coordinator_equivalent_units INT)");
        db.execute("CREATE TABLE academic_terms (term_id INT PRIMARY KEY, term_code VARCHAR(32), term_name VARCHAR(120), status VARCHAR(20))");
        db.execute("CREATE TABLE class_sections (section_id INT AUTO_INCREMENT PRIMARY KEY, course_id INT, term_id INT, section_code VARCHAR(40), max_capacity INT, section_status VARCHAR(20), semester_number INT, faculty_id INT, block_id INT)");
        db.execute("CREATE TABLE class_schedules (schedule_id INT AUTO_INCREMENT PRIMARY KEY, section_id INT, faculty_id INT, day_of_week INT, start_time TIME, end_time TIME, room_id INT, schedule_type VARCHAR(20), status VARCHAR(20))");
        db.execute("CREATE TABLE block_offerings (block_id INT PRIMARY KEY, term_id INT, program_code VARCHAR(32), year_level INT, semester_number INT, section_group VARCHAR(10), max_capacity INT, faculty_id INT, curriculum_id INT)");

        db.update("INSERT INTO departments VALUES (1, 'CPE', 'Computer Engineering')");
        db.update("INSERT INTO programs VALUES (1, 'BSCPE', 1)");
        db.update("INSERT INTO faculty VALUES (NULL, 'FAC-001', 'Main', 'Professor', 1, 'Full-Time', 18, 1)");
        db.update("INSERT INTO courses VALUES (1, 'CPE101', 'Intro', 3, 0, NULL)");
        db.update("INSERT INTO courses VALUES (2, 'CPE102', 'Logic', 3, 0, NULL)");
        db.update("INSERT INTO academic_terms VALUES (1, '2025-1', '2025 First', 'Active')");
    }

    private int insertSection(int courseId, int termId, int units) {
        db.update("UPDATE courses SET credit_units = ? WHERE course_id = ?", units, courseId);
        db.update(
            "INSERT INTO class_sections (course_id, term_id, section_code, max_capacity, section_status, semester_number) " +
                "VALUES (?, ?, 'SEC-A', 40, 'Open', 1)",
            courseId, termId);
        return db.queryForObject("SELECT MAX(section_id) FROM class_sections", Integer.class);
    }

    private static void injectJdbc(FacultyLoadService service, JdbcTemplate db) {
        try {
            var field = FacultyLoadService.class.getDeclaredField("db");
            field.setAccessible(true);
            field.set(service, db);
        } catch (ReflectiveOperationException e) {
            throw new IllegalStateException(e);
        }
    }
}
