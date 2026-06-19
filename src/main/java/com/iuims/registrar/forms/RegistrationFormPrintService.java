package com.iuims.registrar.forms;

import com.iuims.registrar.academic.AcademicGradingService;
import com.iuims.registrar.admission.FinanceAdmissionService;
import com.iuims.registrar.core.PolicySettings;
import com.iuims.registrar.finance.FinancePolicyService;
import com.iuims.registrar.finance.TermFeeAdminService;
import com.iuims.registrar.jaypee.JaypeeIntegrationService;
import com.iuims.registrar.scholarship.ScholarEnrollmentService;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.ui.Model;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class RegistrationFormPrintService {

    private static final DateTimeFormatter PRINTED_AT =
        DateTimeFormatter.ofPattern("MMMM d, yyyy hh:mm a", Locale.ENGLISH);

    private final JdbcTemplate db;
    private final AcademicGradingService academicService;
    private final JaypeeIntegrationService jaypeeService;
    private final FinanceAdmissionService financeService;
    private final FinancePolicyService financePolicyService;
    private final TermFeeAdminService termFeeAdminService;
    private final ScholarEnrollmentService scholarEnrollmentService;

    public RegistrationFormPrintService(JdbcTemplate db,
                                        AcademicGradingService academicService,
                                        JaypeeIntegrationService jaypeeService,
                                        FinanceAdmissionService financeService,
                                        FinancePolicyService financePolicyService,
                                        TermFeeAdminService termFeeAdminService,
                                        ScholarEnrollmentService scholarEnrollmentService) {
        this.db = db;
        this.academicService = academicService;
        this.jaypeeService = jaypeeService;
        this.financeService = financeService;
        this.financePolicyService = financePolicyService;
        this.termFeeAdminService = termFeeAdminService;
        this.scholarEnrollmentService = scholarEnrollmentService;
    }

    public void populateRegistrationFormModel(Model model,
                                              Map<String, Object> student,
                                              String printedBy) {
        if (student == null) {
            return;
        }
        String studentNumber = stringValue(student.get("username"));
        if (studentNumber.isBlank()) {
            return;
        }

        enrichStudentIdentity(student, studentNumber);

        List<Map<String, Object>> studentLoad = jaypeeService.getStudentLoad(studentNumber);
        int totalUnits = 0;
        for (Map<String, Object> row : studentLoad) {
            if (row.get("units") instanceof Number n) {
                totalUnits += n.intValue();
            }
        }

        Map<String, Object> finance = financeService.calculateAssessment(studentNumber);
        int yearLevel = student.get("year_level") instanceof Number n ? n.intValue() : 1;
        int semester = student.get("semester") instanceof Number n ? n.intValue() : 1;
        String programCode = stringValue(student.get("program_code"));

        String termLabel = resolveTermLabel(student, studentNumber);
        String schoolYear = extractSchoolYear(termLabel);
        String semesterSchoolYear =
            RegistrationFormFormatting.formatSemesterSchoolYear(semester, schoolYear);
        String courseYearLine =
            RegistrationFormFormatting.formatCourseYearLine(programCode, yearLevel);

        double totalAssessment = numeric(finance.get("total_assessment"));
        double tuition = numeric(finance.get("tuition_fee"));
        double misc = numeric(finance.get("misc_fee"));
        double other = numeric(finance.get("other_fee"));
        double laboratoryAmount = resolveLaboratoryFee(programCode, studentNumber);
        double downpayment = resolveDownpayment(totalAssessment);

        int termId = resolveStudentTermId(studentNumber);
        if (termId <= 0) {
            termId = academicService.getActiveTermId();
        }

        FeeBreakdown breakdown = loadFeeBreakdown(programCode, termId, yearLevel, semester, tuition, misc, other, laboratoryAmount);
        List<Map<String, Object>> installmentPlan =
            financePolicyService.resolveInstallmentPlanForStudent(studentNumber, termId);
        List<Map<String, Object>> paymentRows = buildPaymentRows(installmentPlan, totalAssessment, downpayment);

        String formTitle = jaypeeService.resolveRegistrationFormTitle(studentNumber);
        String statusLabel = stringValue(finance.get("enrollment_status"));
        if (statusLabel.isBlank()) {
            statusLabel = stringValue(student.get("admission_status"));
        }

        model.addAttribute("student", student);
        model.addAttribute("studentLoad", studentLoad);
        model.addAttribute("totalUnits", totalUnits);
        model.addAttribute("finance", finance);
        model.addAttribute("formTitle", formTitle);
        model.addAttribute("corTermLabel", termLabel);
        model.addAttribute("courseYearLine", courseYearLine);
        model.addAttribute("semesterSchoolYearLine", semesterSchoolYear);
        model.addAttribute("statusLabel", statusLabel);
        model.addAttribute("tuitionAmount", breakdown.tuition());
        model.addAttribute("miscAmount", breakdown.miscTotal());
        model.addAttribute("otherAmount", breakdown.otherTotal());
        model.addAttribute("laboratoryAmount", breakdown.laboratory());
        model.addAttribute("miscFeeLines", breakdown.miscLines());
        model.addAttribute("otherFeeLines", breakdown.otherLines());
        model.addAttribute("downpaymentRequired", downpayment);
        model.addAttribute("paymentRows", paymentRows);
        model.addAttribute("printedBy", printedBy != null && !printedBy.isBlank() ? printedBy : "Registrar");
        model.addAttribute("printedAt", LocalDateTime.now().format(PRINTED_AT));
    }

    private String resolveTermLabel(Map<String, Object> student, String studentNumber) {
        String sl = stringValue(student.get("term_year"));
        if (sl.isBlank()) {
            try {
                sl = db.queryForObject(
                    "SELECT term_year FROM students WHERE student_number = ? LIMIT 1",
                    String.class, studentNumber);
            } catch (Exception ignored) {
            }
        }
        if (sl != null && sl.startsWith("SL") && sl.length() >= 12) {
            try {
                char sem = sl.charAt(11);
                String dbCode = sem + "1" + sl.substring(2, 10);
                String name = db.queryForObject(
                    "SELECT COALESCE(NULLIF(term_name,''), CONCAT('A.Y. ', academic_year, ' - ', "
                        + "IF(semester_number=2,'2nd','1st'), ' Semester')) "
                        + "FROM academic_terms WHERE term_code = ? LIMIT 1",
                    String.class, dbCode);
                if (name != null && !name.isBlank()) {
                    return name;
                }
            } catch (Exception ignored) {
            }
        }
        return academicService.getCurrentTermLabel();
    }

    private int resolveStudentTermId(String studentNumber) {
        try {
            String sl = db.queryForObject(
                "SELECT term_year FROM students WHERE student_number = ? LIMIT 1",
                String.class, studentNumber);
            if (sl != null && sl.startsWith("SL") && !sl.startsWith("SL_") && sl.length() >= 12) {
                char sem = sl.charAt(11);
                String dbCode = sem + "1" + sl.substring(2, 10);
                Integer termId = db.queryForObject(
                    "SELECT term_id FROM academic_terms WHERE term_code = ? LIMIT 1",
                    Integer.class, dbCode);
                if (termId != null) {
                    return termId;
                }
            }
        } catch (Exception ignored) {
        }
        return academicService.getActiveTermId();
    }

    private double resolveLaboratoryFee(String programCode, String studentNumber) {
        String code = programCode != null ? programCode.trim().toUpperCase(Locale.ROOT) : "";
        if (!code.equals("BSN") && !code.contains("NURS")) {
            return 0.0;
        }
        try {
            ScholarEnrollmentService.TermFeeBreakdown fees =
                scholarEnrollmentService.computeCurrentTermFees(studentNumber);
            return Math.max(0, fees.other);
        } catch (Exception ignored) {
            return 0.0;
        }
    }

    private FeeBreakdown loadFeeBreakdown(String programCode,
                                          int termId,
                                          int yearLevel,
                                          int semester,
                                          double tuition,
                                          double miscTotal,
                                          double otherTotal,
                                          double laboratory) {
        List<Map<String, String>> miscLines = new ArrayList<>();
        List<Map<String, String>> otherLines = new ArrayList<>();
        try {
            Integer programId = db.queryForObject(
                "SELECT program_id FROM programs WHERE program_code = ? LIMIT 1",
                Integer.class, programCode);
            if (programId != null) {
                Map<String, Double> rates = termFeeAdminService.getFeeRatesForScope(
                    programId, termId, yearLevel, semester);
                for (Map.Entry<String, Double> entry : rates.entrySet()) {
                    if (entry.getValue() == null || entry.getValue() <= 0) {
                        continue;
                    }
                    String key = entry.getKey();
                    String label = humanizeFeeCode(key);
                    String amount = RegistrationFormFormatting.formatMoney(entry.getValue());
                    if (key.startsWith("MISC_")) {
                        miscLines.add(Map.of("label", label, "amount", amount));
                    } else if (key.startsWith("OTHER_")) {
                        otherLines.add(Map.of("label", label, "amount", amount));
                    }
                }
            }
        } catch (Exception ignored) {
        }
        return new FeeBreakdown(tuition, miscTotal, otherTotal, laboratory, miscLines, otherLines);
    }

    private static String humanizeFeeCode(String code) {
        if (code == null || code.isBlank()) {
            return "";
        }
        return code.replace('_', ' ').trim();
    }

    private void enrichStudentIdentity(Map<String, Object> student, String studentNumber) {
        try {
            Map<String, Object> row = db.queryForMap(
                "SELECT s.first_name, s.last_name, s.middle_name, s.admission_status, s.term_year, a.sex, a.age " +
                    "FROM students s " +
                    "LEFT JOIN applicants a ON a.reference_number = s.reference_number " +
                    "WHERE s.student_number = ? LIMIT 1",
                studentNumber);
            putIfPresent(student, "first_name", row.get("first_name"));
            putIfPresent(student, "last_name", row.get("last_name"));
            putIfPresent(student, "middle_name", row.get("middle_name"));
            putIfPresent(student, "gender", row.get("sex"));
            putIfPresent(student, "age", row.get("age"));
            putIfPresent(student, "admission_status", row.get("admission_status"));
            putIfPresent(student, "term_year", row.get("term_year"));
        } catch (Exception ignored) {
        }
    }

    private List<Map<String, Object>> buildPaymentRows(List<Map<String, Object>> plan,
                                                       double totalAssessment,
                                                       double downpayment) {
        List<Map<String, Object>> rows = new ArrayList<>();
        rows.add(Map.of(
            "label", "Downpayment",
            "amount", RegistrationFormFormatting.formatPayment(downpayment)));

        if (plan == null || plan.isEmpty()) {
            return rows;
        }

        double remaining = Math.max(0, round2(totalAssessment - downpayment));
        int count = plan.size();
        double perInstallment = count > 0 ? round2(remaining / count) : 0;
        for (int i = 0; i < count; i++) {
            double amount = i == count - 1
                ? round2(remaining - perInstallment * (count - 1))
                : perInstallment;
            Map<String, Object> row = plan.get(i);
            String label = row.get("installment_label") != null
                ? row.get("installment_label").toString()
                : "Installment " + (i + 1);
            rows.add(Map.of(
                "label", label,
                "amount", RegistrationFormFormatting.formatPayment(amount)));
        }
        return rows;
    }

    private double resolveDownpayment(double totalAssessment) {
        double fixed = PolicySettings.downpaymentThreshold(db);
        double percent = PolicySettings.downpaymentPercent(db);
        if (percent > 0) {
            return round2(totalAssessment * percent / 100.0);
        }
        return fixed;
    }

    private static String extractSchoolYear(String termLabel) {
        if (termLabel == null || termLabel.isBlank()) {
            return "";
        }
        String trimmed = termLabel.trim();
        if (trimmed.startsWith("A.Y.")) {
            int dash = trimmed.indexOf('-');
            int end = trimmed.indexOf(' ', dash > 0 ? dash : 0);
            if (end > 4) {
                return trimmed.substring(4, end).trim();
            }
            return trimmed.substring(4).trim();
        }
        return trimmed;
    }

    private static void putIfPresent(Map<String, Object> target, String key, Object value) {
        if (value != null && !value.toString().isBlank()) {
            target.put(key, value);
        }
    }

    private static double numeric(Object value) {
        return value instanceof Number n ? n.doubleValue() : 0.0;
    }

    private static String stringValue(Object value) {
        return value != null ? value.toString().trim() : "";
    }

    private static double round2(double value) {
        return Math.round(value * 100.0) / 100.0;
    }

    private record FeeBreakdown(
        double tuition,
        double miscTotal,
        double otherTotal,
        double laboratory,
        List<Map<String, String>> miscLines,
        List<Map<String, String>> otherLines
    ) {}
}
