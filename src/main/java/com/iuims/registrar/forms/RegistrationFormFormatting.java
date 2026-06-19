package com.iuims.registrar.forms;

/**
 * Shared label formatting aligned with Admission {@code PreRegFormFormatting}.
 */
public final class RegistrationFormFormatting {

    private RegistrationFormFormatting() {
    }

    public static String formatYearLabel(int yearLevel) {
        return switch (Math.max(1, yearLevel)) {
            case 1 -> "First Year";
            case 2 -> "Second Year";
            case 3 -> "Third Year";
            case 4 -> "Fourth Year";
            case 5 -> "Fifth Year";
            default -> "Year " + yearLevel;
        };
    }

    public static String formatCourseYearLine(String programCode, int yearLevel) {
        String code = programCode != null ? programCode.trim() : "";
        return code + " - " + formatYearLabel(yearLevel);
    }

    public static String formatSemesterSchoolYear(int semesterNumber, String schoolYearDisplay) {
        String semName = switch (semesterNumber) {
            case 2 -> "Second Semester";
            case 3 -> "Summer";
            default -> "First Semester";
        };
        if (schoolYearDisplay == null || schoolYearDisplay.isBlank()) {
            return semName;
        }
        return semName + ", A.Y. " + schoolYearDisplay.trim();
    }

    public static String formatMoney(double value) {
        return String.format("%,.2f", value);
    }

    public static String formatPayment(double value) {
        return String.format("%,.3f", value);
    }
}
