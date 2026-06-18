package com.iuims.registrar.core;

import org.springframework.jdbc.core.JdbcTemplate;

import java.time.LocalDate;

/**
 * Shared enrollment calendar rules stored in {@code system_settings}.
 * Empty dates mean the gate is not enforced.
 */
public final class EnrollmentPeriodPolicy {

    private EnrollmentPeriodPolicy() {}

    public static boolean isBeforeEnrollmentOpen(LocalDate today, String openDate) {
        LocalDate parsed = parseDate(openDate);
        return parsed != null && today.isBefore(parsed);
    }

    public static boolean isEnrollmentClosed(LocalDate today, String closeDate) {
        LocalDate parsed = parseDate(closeDate);
        return parsed != null && today.isAfter(parsed);
    }

    public static boolean isAddDropClosed(LocalDate today, String addDropCloseDate) {
        LocalDate parsed = parseDate(addDropCloseDate);
        return parsed != null && today.isAfter(parsed);
    }

    public static boolean blocksNewEnlistment(JdbcTemplate db) {
        LocalDate today = LocalDate.now();
        return isBeforeEnrollmentOpen(today, readSetting(db, PolicySettings.ENROLLMENT_OPEN_DATE))
            || isEnrollmentClosed(today, readSetting(db, PolicySettings.ENROLLMENT_CLOSE_DATE));
    }

    public static boolean blocksSubjectChanges(JdbcTemplate db) {
        return blocksNewEnlistment(db)
            || isAddDropClosed(LocalDate.now(), readSetting(db, PolicySettings.ADD_DROP_CLOSE_DATE));
    }

    public static String enlistmentBlockMessage(JdbcTemplate db) {
        LocalDate today = LocalDate.now();
        String open = readSetting(db, PolicySettings.ENROLLMENT_OPEN_DATE);
        if (isBeforeEnrollmentOpen(today, open)) {
            return "ERROR: Enrollment has not opened yet (opens " + open.trim() + ").";
        }
        String close = readSetting(db, PolicySettings.ENROLLMENT_CLOSE_DATE);
        if (isEnrollmentClosed(today, close)) {
            return "ERROR: Enrollment period has closed. Contact the Registrar for assistance.";
        }
        String addDrop = readSetting(db, PolicySettings.ADD_DROP_CLOSE_DATE);
        if (isAddDropClosed(today, addDrop)) {
            return "ERROR: Add/drop period has closed (closed " + addDrop.trim() + "). Contact the Registrar.";
        }
        return null;
    }

    public static String withdrawalBlockMessage(JdbcTemplate db) {
        if (isAddDropClosed(LocalDate.now(), readSetting(db, PolicySettings.ADD_DROP_CLOSE_DATE))) {
            return "Add/drop period has closed. New withdrawal requests are not accepted.";
        }
        return null;
    }

    private static String readSetting(JdbcTemplate db, String key) {
        try {
            return db.queryForObject(
                "SELECT setting_value FROM system_settings WHERE setting_key = ? LIMIT 1",
                String.class, key);
        } catch (Exception e) {
            return null;
        }
    }

    static LocalDate parseDate(String raw) {
        if (raw == null || raw.isBlank()) return null;
        try {
            return LocalDate.parse(raw.trim());
        } catch (Exception e) {
            return null;
        }
    }
}
