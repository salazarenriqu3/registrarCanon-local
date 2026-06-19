package com.iuims.registrar.academic;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

import static org.assertj.core.api.Assertions.assertThat;

class ScheduleRepairServiceTest {

    private JdbcTemplate db;
    private ScheduleRepairService service;

    @BeforeEach
    void setUp() {
        DriverManagerDataSource dataSource = new DriverManagerDataSource(
            "jdbc:h2:mem:schedule-repair-" + System.nanoTime() + ";MODE=MySQL;DB_CLOSE_DELAY=-1", "sa", "");
        db = new JdbcTemplate(dataSource);
        seedSchema();
        service = new ScheduleRepairService(db);
    }

    @Test
    void repairClearsSingleRoomStampAndConflicts() {
        insertOverlappingLab301Rows();

        ScheduleRepairService.RepairResult result = service.repairTermSchedules(1);

        assertThat(result.message()).startsWith("SUCCESS");
        assertThat(result.roomConflictsAfter()).isZero();
        assertThat(result.facultyConflictsAfter()).isZero();
        Integer roomsAssigned = db.queryForObject(
            "SELECT COUNT(*) FROM class_schedules sch " +
                "JOIN class_sections cs ON cs.section_id = sch.section_id " +
                "WHERE cs.term_id = 1 AND sch.room_id IS NOT NULL",
            Integer.class);
        assertThat(roomsAssigned).isZero();
    }

    private void insertOverlappingLab301Rows() {
        db.update(
            "INSERT INTO class_sections (section_id, course_id, term_id, section_code, faculty_id) VALUES (1, 1, 1, 'BSCPE-1-1-A', 1)");
        db.update(
            "INSERT INTO class_sections (section_id, course_id, term_id, section_code, faculty_id) VALUES (2, 2, 1, 'BSCPE-1-1-A', 1)");
        db.update(
            "INSERT INTO class_schedules (section_id, room_id, faculty_id, day_of_week, start_time, end_time, schedule_type, status) " +
                "VALUES (1, 1, 1, 1, '09:00:00', '10:30:00', 'Lecture', 'OPEN')");
        db.update(
            "INSERT INTO class_schedules (section_id, room_id, faculty_id, day_of_week, start_time, end_time, schedule_type, status) " +
                "VALUES (2, 1, 1, 1, '09:00:00', '10:30:00', 'Lecture', 'OPEN')");
    }

    private void seedSchema() {
        db.execute("CREATE TABLE faculty (faculty_id INT PRIMARY KEY, max_teaching_units INT DEFAULT 18)");
        db.execute("CREATE TABLE courses (course_id INT PRIMARY KEY, course_code VARCHAR(32), lab_units INT DEFAULT 0)");
        db.execute("CREATE TABLE class_sections (section_id INT PRIMARY KEY, course_id INT, term_id INT, section_code VARCHAR(40), faculty_id INT)");
        db.execute("CREATE TABLE class_schedules (schedule_id INT AUTO_INCREMENT PRIMARY KEY, section_id INT, room_id INT, faculty_id INT, day_of_week INT, start_time TIME, end_time TIME, schedule_type VARCHAR(20), status VARCHAR(20))");
        db.update("INSERT INTO faculty VALUES (1, 18)");
        db.update("INSERT INTO courses VALUES (1, 'CPE101', 0)");
        db.update("INSERT INTO courses VALUES (2, 'CPE102', 0)");
    }
}
