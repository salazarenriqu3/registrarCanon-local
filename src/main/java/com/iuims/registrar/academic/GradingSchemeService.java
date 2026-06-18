package com.iuims.registrar.academic;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class GradingSchemeService {

    private final JdbcTemplate db;

    public GradingSchemeService(JdbcTemplate db) {
        this.db = db;
    }

    public void ensureSchema() {
        db.execute("""
            CREATE TABLE IF NOT EXISTS grading_schemes (
                scheme_id INT AUTO_INCREMENT PRIMARY KEY,
                program_code VARCHAR(20) NULL,
                class_standing_percent DECIMAL(5,2) NOT NULL DEFAULT 50.00,
                exam_percent DECIMAL(5,2) NOT NULL DEFAULT 50.00,
                base_scale VARCHAR(20) NOT NULL DEFAULT 'POINT',
                updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                UNIQUE KEY uq_grading_scheme_program (program_code)
            )
            """);
        Integer count = db.queryForObject("SELECT COUNT(*) FROM grading_schemes WHERE program_code IS NULL", Integer.class);
        if (count == null || count == 0) {
            db.update(
                "INSERT INTO grading_schemes (program_code, class_standing_percent, exam_percent, base_scale) " +
                    "VALUES (NULL, 50.00, 50.00, 'POINT')");
        }
    }

    public Map<String, Object> getDefaultScheme() {
        ensureSchema();
        try {
            return db.queryForMap(
                "SELECT scheme_id, program_code, class_standing_percent, exam_percent, base_scale " +
                    "FROM grading_schemes WHERE program_code IS NULL LIMIT 1");
        } catch (Exception e) {
            Map<String, Object> fallback = new LinkedHashMap<>();
            fallback.put("scheme_id", 0);
            fallback.put("program_code", null);
            fallback.put("class_standing_percent", 50.0);
            fallback.put("exam_percent", 50.0);
            fallback.put("base_scale", "POINT");
            return fallback;
        }
    }

    public Map<String, Object> resolveForProgram(String programCode) {
        ensureSchema();
        if (programCode != null && !programCode.isBlank()) {
            try {
                return db.queryForMap(
                    "SELECT scheme_id, program_code, class_standing_percent, exam_percent, base_scale " +
                        "FROM grading_schemes WHERE BINARY program_code = BINARY ? LIMIT 1",
                    programCode.trim().toUpperCase());
            } catch (Exception ignored) {
            }
        }
        return getDefaultScheme();
    }

    public List<Map<String, Object>> listAll() {
        ensureSchema();
        return db.queryForList(
            "SELECT scheme_id, program_code, class_standing_percent, exam_percent, base_scale " +
                "FROM grading_schemes ORDER BY program_code IS NULL DESC, program_code ASC");
    }

    @Transactional
    public void saveDefaultScheme(double classStandingPercent, double examPercent, String baseScale) {
        ensureSchema();
        validateWeights(classStandingPercent, examPercent);
        db.update(
            "UPDATE grading_schemes SET class_standing_percent = ?, exam_percent = ?, base_scale = ? " +
                "WHERE program_code IS NULL",
            classStandingPercent, examPercent, cleanScale(baseScale));
        Integer updated = db.queryForObject(
            "SELECT COUNT(*) FROM grading_schemes WHERE program_code IS NULL", Integer.class);
        if (updated == null || updated == 0) {
            db.update(
                "INSERT INTO grading_schemes (program_code, class_standing_percent, exam_percent, base_scale) " +
                    "VALUES (NULL, ?, ?, ?)",
                classStandingPercent, examPercent, cleanScale(baseScale));
        }
    }

    private void validateWeights(double classStandingPercent, double examPercent) {
        if (classStandingPercent < 0 || examPercent < 0) {
            throw new IllegalArgumentException("Grading weights cannot be negative.");
        }
        if (Math.abs(classStandingPercent + examPercent - 100.0) > 0.01) {
            throw new IllegalArgumentException("Class standing and exam weights must total 100%.");
        }
    }

    private String cleanScale(String baseScale) {
        if (baseScale == null || baseScale.isBlank()) return "POINT";
        return baseScale.trim().toUpperCase();
    }
}
