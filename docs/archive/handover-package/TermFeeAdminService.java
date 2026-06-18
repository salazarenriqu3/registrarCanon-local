package com.iuims.registrar.finance;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
public class TermFeeAdminService {

    private static final String CODE_TUITION = "TUITION_PER_UNIT";
    private static final String CODE_RLE = "RLE_RATE_PER_HOUR";

    // Known static fee types in the new unified model
    private static final List<String> KNOWN_FEES = Arrays.asList(
        "TUITION_PER_UNIT", "LEC_FEE_PER_UNIT", "LAB_FEE_PER_UNIT", "COMP_FEE_PER_UNIT", "RLE_FEE_PER_UNIT",
        "MISC_REGISTRATION", "MISC_LIBRARY", "MISC_MEDICAL", "MISC_ID", "MISC_ATHLETIC", "MISC_GUIDANCE", "MISC_LMS", "MISC_INS", "MISC_CULT", "MISC_AV", "MISC_ENERGY",
        "OTHER_LATE_ENROLLMENT", "OTHER_ADD_DROP", "OTHER_INSTALLMENT", "OTHER_ID", "OTHER_INS", "OTHER_COMP", "OTHER_DEV"
    );

    @Autowired
    private JdbcTemplate db;

    @Autowired
    private ProgramFeeSettingRepository feeSettingRepository;

    public List<Map<String, Object>> listTermsAscending() {
        try {
            return db.queryForList(
                "SELECT term_id, term_code, term_name, academic_year, semester_number, status, is_active " +
                    "FROM academic_terms ORDER BY term_id ASC");
        } catch (Exception e) {
            return List.of();
        }
    }

    public Integer getActiveTermId() {
        try {
            return db.queryForObject(
                "SELECT term_id FROM academic_terms WHERE is_active = 1 OR UPPER(COALESCE(status,'')) = 'ACTIVE' " +
                    "ORDER BY term_id DESC LIMIT 1",
                Integer.class);
        } catch (Exception e) {
            return null;
        }
    }

    public List<Map<String, Object>> listPrograms() {
        try {
            return db.queryForList(
                "SELECT program_code, program_name FROM programs WHERE COALESCE(active_status, 1) = 1 ORDER BY program_code");
        } catch (Exception e) {
            return List.of();
        }
    }

    public List<String> validateTablesExist() {
        List<String> missing = new ArrayList<>();
        if (!tableExists("program_fee_settings")) missing.add("program_fee_settings");
        if (!tableExists("programs")) missing.add("programs");
        if (!tableExists("curriculum_templates")) missing.add("curriculum_templates");
        return missing;
    }

    public Integer resolveProgramId(String programCode) {
        if (programCode == null || programCode.isBlank()) return null;
        try {
            return db.queryForObject(
                "SELECT program_id FROM programs WHERE program_code = ? LIMIT 1",
                Integer.class, programCode.trim().toUpperCase());
        } catch (Exception e) {
            return null;
        }
    }

    public Integer resolveTermIdFromTermCode(String termCode) {
        if (termCode == null || termCode.isBlank()) return null;
        String dbTermCode = termCode.trim();
        if (dbTermCode.startsWith("SL_")) {
            dbTermCode = dbTermCode.substring(3);
        }
        try {
            return db.queryForObject(
                "SELECT term_id FROM academic_terms WHERE term_code = ? ORDER BY term_id DESC LIMIT 1",
                Integer.class, dbTermCode);
        } catch (Exception ignored) {
        }
        try {
            if (dbTermCode.length() >= 10) {
                int sem = Character.getNumericValue(dbTermCode.charAt(0));
                String ay = dbTermCode.substring(2, 6) + "-" + dbTermCode.substring(6, 10);
                return db.queryForObject(
                    "SELECT term_id FROM academic_terms WHERE academic_year = ? AND semester_number = ? ORDER BY term_id DESC LIMIT 1",
                    Integer.class, ay, sem);
            }
        } catch (Exception ignored) {
        }
        return null;
    }

    public List<Map<String, Object>> listFeeTypesForAdmin(int programId, Integer termId, int yearLevel, int semester) {
        List<Map<String, Object>> rows = new ArrayList<>();
        rows.add(feeRow(CODE_TUITION, "Tuition per unit", "RATE", "PER_UNIT"));
        rows.add(feeRow("LEC_FEE_PER_UNIT", "Lecture fee per unit", "RATE", "PER_UNIT"));
        rows.add(feeRow("LAB_FEE_PER_UNIT", "Lab fee per unit", "RATE", "PER_UNIT"));
        rows.add(feeRow("COMP_FEE_PER_UNIT", "Computer fee per unit", "RATE", "PER_UNIT"));
        rows.add(feeRow(CODE_RLE, "RLE rate per hour (BSN)", "RATE", "PER_HOUR"));
        
        rows.add(feeRow("MISC_REGISTRATION", "Registration Fee", "MISC", "FLAT"));
        rows.add(feeRow("MISC_LIBRARY", "Library Fee", "MISC", "FLAT"));
        rows.add(feeRow("MISC_MEDICAL", "Medical/Dental Fee", "MISC", "FLAT"));
        rows.add(feeRow("MISC_ID", "ID Fee", "MISC", "FLAT"));
        rows.add(feeRow("MISC_ATHLETIC", "Athletic Fee", "MISC", "FLAT"));
        rows.add(feeRow("MISC_GUIDANCE", "Guidance & Counselling", "MISC", "FLAT"));
        rows.add(feeRow("MISC_LMS", "Learning Management System", "MISC", "FLAT"));
        rows.add(feeRow("MISC_INS", "Student Accident Insurance", "MISC", "FLAT"));
        rows.add(feeRow("MISC_CULT", "Cultural Fee", "MISC", "FLAT"));
        rows.add(feeRow("MISC_AV", "Multi-media / Audio Visual", "MISC", "FLAT"));
        rows.add(feeRow("MISC_ENERGY", "Energy Fee", "MISC", "FLAT"));
        
        rows.add(feeRow("OTHER_LATE_ENROLLMENT", "Late Enrollment Fee", "OTHER", "FLAT"));
        rows.add(feeRow("OTHER_ADD_DROP", "Adding/Dropping Fee", "OTHER", "FLAT"));
        rows.add(feeRow("OTHER_INSTALLMENT", "Installment Charge", "OTHER", "FLAT"));
        rows.add(feeRow("OTHER_ID", "Identification Card", "OTHER", "FLAT"));
        rows.add(feeRow("OTHER_INS", "Insurance", "OTHER", "FLAT"));
        rows.add(feeRow("OTHER_COMP", "Computer Hands-On", "OTHER", "FLAT"));
        rows.add(feeRow("OTHER_DEV", "Developmental Fees", "OTHER", "FLAT"));
        return rows;
    }

    public Map<String, Double> getFeeRatesForScope(int programId, Integer termId, int yearLevel, int semester) {
        Map<String, Double> map = new LinkedHashMap<>();
        Optional<ProgramFeeSetting> settingOpt = feeSettingRepository.findBestMatch(programId, yearLevel, semester, termId);
        
        if (settingOpt.isPresent()) {
            ProgramFeeSetting setting = settingOpt.get();
            for (String code : KNOWN_FEES) {
                double val = setting.getFee(code);
                if (val > 0) {
                    map.put(code, val);
                }
            }
        }
        return map;
    }

    public Map<String, String> getFeeRateSourcesForScope(int programId, Integer termId, int yearLevel, int semester) {
        Map<String, String> map = new LinkedHashMap<>();
        Optional<ProgramFeeSetting> settingOpt = feeSettingRepository.findBestMatch(programId, yearLevel, semester, termId);
        
        if (settingOpt.isPresent()) {
            ProgramFeeSetting setting = settingOpt.get();
            String source = (setting.getTermId() != null && setting.getTermId().equals(termId)) ? "EXACT_TERM" : "FALLBACK";
            for (String code : KNOWN_FEES) {
                double val = setting.getFee(code);
                if (val > 0) {
                    map.put(code, source);
                }
            }
        }
        return map;
    }

    @Transactional
    public boolean saveFeeRate(int programId, Integer termId, int yearLevel, int semester,
                               String feeCode, double amount) {
        if (feeCode == null || feeCode.isBlank()) return false;
        String code = feeCode.trim().toUpperCase();

        ProgramFeeSetting setting;
        Optional<ProgramFeeSetting> existingOpt = feeSettingRepository.findActiveForScopeOrFallback(programId, yearLevel, semester, termId);
        
        if (existingOpt.isPresent() && Objects.equals(existingOpt.get().getTermId(), termId)) {
            // Found exact match
            setting = existingOpt.get();
        } else {
            // Need to create a new row for this specific term
            setting = new ProgramFeeSetting();
            setting.setProgramId(programId);
            setting.setTermId(termId);
            setting.setYearLevel(yearLevel);
            setting.setSemesterNumber(semester);
            
            // If fallback exists, copy its values
            if (existingOpt.isPresent()) {
                ProgramFeeSetting fallback = existingOpt.get();
                for (String k : KNOWN_FEES) {
                    setting.setFee(k, fallback.getFee(k));
                }
            }
        }
        
        // Ensure standard tuition carries over to lec if not explicitly handled
        if (CODE_TUITION.equals(code) && setting.getFee("LEC_FEE_PER_UNIT") == 0) {
            setting.setFee("LEC_FEE_PER_UNIT", amount);
        }

        setting.setFee(code, amount);
        feeSettingRepository.saveAndFlush(setting);
        return true;
    }

    @Transactional
    public boolean addMiscOrOtherFee(int programId, Integer termId, int yearLevel, int semester,
                                     String feeCode, String feeName) {
        // In the wide-table model, new dynamic columns require a schema update.
        // We only support saving to existing known columns.
        if (!KNOWN_FEES.contains(feeCode.trim().toUpperCase())) {
            return false;
        }
        return saveFeeRate(programId, termId, yearLevel, semester, feeCode, 0.0);
    }

    public boolean isSupportedChargeCode(String feeCode) {
        if (feeCode == null) return false;
        return KNOWN_FEES.contains(feeCode.trim().toUpperCase());
    }

    @Transactional
    public TermFeePreparationResult prepareTermFees(Integer termId) {
        if (termId == null || !validateTablesExist().isEmpty()) {
            return new TermFeePreparationResult(0, 0, 0, 0, 0, 0);
        }

        int programsChecked = 0;
        int scopesChecked = 0;
        int coreRowsCreated = 0;
        int coreRowsUpdated = 0;
        int specificRowsCopied = 0;
        int unableToInferTuition = 0;

        for (Map<String, Object> program : listPrograms()) {
            Object codeObj = program.get("program_code");
            if (codeObj == null) continue;
            Integer programId = resolveProgramId(codeObj.toString());
            if (programId == null) continue;
            programsChecked++;

            for (int yearLevel = 1; yearLevel <= 4; yearLevel++) {
                for (int semester = 1; semester <= 2; semester++) {
                    scopesChecked++;
                    
                    Optional<ProgramFeeSetting> exactOpt = feeSettingRepository.findBestMatch(programId, yearLevel, semester, termId);
                    if (exactOpt.isPresent() && Objects.equals(exactOpt.get().getTermId(), termId)) {
                        // Already exists
                        if (exactOpt.get().getFeeTuitionPerUnit().doubleValue() == 0 && exactOpt.get().getFeeRlePerUnit().doubleValue() == 0) {
                            unableToInferTuition++;
                        } else {
                            coreRowsUpdated++;
                        }
                    } else {
                        // Needs creation from fallback
                        ProgramFeeSetting setting = new ProgramFeeSetting();
                        setting.setProgramId(programId);
                        setting.setTermId(termId);
                        setting.setYearLevel(yearLevel);
                        setting.setSemesterNumber(semester);
                        
                        if (exactOpt.isPresent()) {
                            // Copy from fallback
                            ProgramFeeSetting fallback = exactOpt.get();
                            for (String k : KNOWN_FEES) {
                                setting.setFee(k, fallback.getFee(k));
                            }
                            coreRowsCreated++;
                            specificRowsCopied += 5; // Estimating equivalent specific rows copied
                        } else {
                            unableToInferTuition++;
                        }
                        feeSettingRepository.saveAndFlush(setting);
                    }
                }
            }
        }

        return new TermFeePreparationResult(
            programsChecked, scopesChecked, coreRowsCreated, coreRowsUpdated, specificRowsCopied, unableToInferTuition);
    }

    @Transactional
    public FeeTemplateCopyResult copyImportedProgramFeeTemplates(Integer termId) {
        if (termId == null || !validateTablesExist().isEmpty()) {
            return new FeeTemplateCopyResult(0, 0, 0, 0, 0, 0);
        }

        int programsChecked = 0;
        int programsSeeded = 0;
        int coreRowsCreated = 0;
        int coreRowsUpdated = 0;
        int specificRowsCopied = 0;
        int skippedNoSource = 0;

        Map<String, String> sources = feeTemplateSources();
        for (Map<String, Object> program : listPrograms()) {
            Object codeObj = program.get("program_code");
            if (codeObj == null) continue;
            String targetCode = codeObj.toString().trim().toUpperCase();
            String sourceCode = sources.get(targetCode);
            if (sourceCode == null) continue;
            programsChecked++;

            Integer targetProgramId = resolveProgramId(targetCode);
            Integer sourceProgramId = resolveProgramId(sourceCode);
            if (targetProgramId == null || sourceProgramId == null) {
                skippedNoSource++;
                continue;
            }

            boolean seededProgram = false;
            boolean missingSourceForProgram = false;
            for (int yearLevel = 1; yearLevel <= 4; yearLevel++) {
                for (int semester = 1; semester <= 2; semester++) {
                    Optional<ProgramFeeSetting> sourceOpt = feeSettingRepository.findBestMatch(sourceProgramId, yearLevel, semester, termId);
                    if (sourceOpt.isEmpty() || sourceOpt.get().getFeeTuitionPerUnit().doubleValue() == 0) {
                        missingSourceForProgram = true;
                        continue;
                    }
                    
                    ProgramFeeSetting sourceTemplate = sourceOpt.get();
                    Optional<ProgramFeeSetting> targetOpt = feeSettingRepository.findActiveForScopeOrFallback(targetProgramId, yearLevel, semester, termId);
                    
                    ProgramFeeSetting targetTemplate;
                    if (targetOpt.isPresent() && Objects.equals(targetOpt.get().getTermId(), termId)) {
                        targetTemplate = targetOpt.get();
                        coreRowsUpdated++;
                    } else {
                        targetTemplate = new ProgramFeeSetting();
                        targetTemplate.setProgramId(targetProgramId);
                        targetTemplate.setTermId(termId);
                        targetTemplate.setYearLevel(yearLevel);
                        targetTemplate.setSemesterNumber(semester);
                        coreRowsCreated++;
                    }
                    
                    // Copy values
                    for (String k : KNOWN_FEES) {
                        targetTemplate.setFee(k, sourceTemplate.getFee(k));
                    }
                    feeSettingRepository.saveAndFlush(targetTemplate);
                    seededProgram = true;
                    specificRowsCopied += 5;
                }
            }

            if (seededProgram) programsSeeded++;
            if (!seededProgram && missingSourceForProgram) skippedNoSource++;
        }

        return new FeeTemplateCopyResult(
            programsChecked, programsSeeded, coreRowsCreated, coreRowsUpdated, specificRowsCopied, skippedNoSource);
    }

    @Transactional
    public FeeTemplateCopyResult importFeesFromSpecificTerm(Integer sourceTermId, Integer targetTermId, Integer programId, Integer yearLevel, Integer semesterNumber) {
        if (Objects.equals(sourceTermId, targetTermId) || !validateTablesExist().isEmpty()) {
            return new FeeTemplateCopyResult(0, 0, 0, 0, 0, 0);
        }

        List<ProgramFeeSetting> sourceFees;
        if (programId != null && yearLevel != null && semesterNumber != null) {
            sourceFees = feeSettingRepository.findByTermIdAndProgramIdAndYearLevelAndSemesterNumberAndIsActiveTrue(sourceTermId, programId, yearLevel, semesterNumber);
        } else {
            sourceFees = feeSettingRepository.findByTermIdAndIsActiveTrue(sourceTermId);
        }
        
        int rowsChecked = sourceFees.size();
        int rowsSeeded = 0;
        int coreRowsCreated = 0;
        int coreRowsUpdated = 0;
        int specificRowsCopied = 0;
        int skippedNoSource = 0;

        for (ProgramFeeSetting sourceTemplate : sourceFees) {
            Optional<ProgramFeeSetting> targetOpt = feeSettingRepository.findFirstByProgramIdAndYearLevelAndSemesterNumberAndTermIdOrderByFeeSettingIdDesc(
                sourceTemplate.getProgramId(), sourceTemplate.getYearLevel(), sourceTemplate.getSemesterNumber(), targetTermId
            );

            ProgramFeeSetting targetTemplate;
            if (targetOpt.isPresent()) {
                targetTemplate = targetOpt.get();
                coreRowsUpdated++;
            } else {
                targetTemplate = new ProgramFeeSetting();
                targetTemplate.setProgramId(sourceTemplate.getProgramId());
                targetTemplate.setTermId(targetTermId);
                targetTemplate.setYearLevel(sourceTemplate.getYearLevel());
                targetTemplate.setSemesterNumber(sourceTemplate.getSemesterNumber());
                coreRowsCreated++;
            }

            // Copy values
            for (String k : KNOWN_FEES) {
                targetTemplate.setFee(k, sourceTemplate.getFee(k));
            }
            feeSettingRepository.saveAndFlush(targetTemplate);
            rowsSeeded++;
            specificRowsCopied += KNOWN_FEES.size();
        }

        return new FeeTemplateCopyResult(
            rowsChecked, rowsSeeded, coreRowsCreated, coreRowsUpdated, specificRowsCopied, skippedNoSource);
    }

    public Map<String, Object> buildTermReadinessSummary(Integer termId) {
        Map<String, Object> summary = new LinkedHashMap<>();
        List<String> missingTables = validateTablesExist();
        List<Map<String, Object>> programs = listPrograms();
        List<String> missingFeeExamples = new ArrayList<>();
        List<String> fallbackFeeExamples = new ArrayList<>();
        List<String> missingCurricula = new ArrayList<>();

        summary.put("termId", termId);
        summary.put("missingTables", missingTables);
        summary.put("programCount", programs.size());
        summary.put("missingFeeExamples", missingFeeExamples);
        summary.put("fallbackFeeExamples", fallbackFeeExamples);
        summary.put("missingCurricula", missingCurricula);
        summary.put("missingFeeScopeCount", 0);
        summary.put("fallbackFeeScopeCount", 0);
        summary.put("checkedScopeCount", 0);
        summary.put("ready", false);

        if (termId == null || !missingTables.isEmpty()) {
            summary.put("statusText", termId == null ? "No active term selected." : "Required tables are missing.");
            return summary;
        }

        Map<String, Object> term = termDetails(termId);
        Object termName = term.get("term_name");
        summary.put("termLabel", termName != null && !termName.toString().isBlank() ? termName : "Term #" + termId);
        summary.put("termActive", isTruthy(term.get("is_active")) || "ACTIVE".equalsIgnoreCase(String.valueOf(term.get("status"))));
        summary.put("termStatus", term.get("status"));

        int missingFeeScopeCount = 0;
        int fallbackFeeScopeCount = 0;
        int checkedScopeCount = 0;

        for (Map<String, Object> program : programs) {
            String programCode = program.get("program_code") != null ? program.get("program_code").toString() : "";
            Integer programId = resolveProgramId(programCode);
            if (programId == null) {
                missingCurricula.add(programCode + " (program id missing)");
                continue;
            }
            if (!hasActiveCurriculum(programId)) {
                missingCurricula.add(programCode);
            }

            for (int yearLevel = 1; yearLevel <= 4; yearLevel++) {
                for (int semester = 1; semester <= 2; semester++) {
                    checkedScopeCount++;
                    Optional<ProgramFeeSetting> settingOpt = feeSettingRepository.findBestMatch(programId, yearLevel, semester, termId);
                    
                    boolean scopeMissing = settingOpt.isEmpty();
                    boolean scopeFallback = settingOpt.isPresent() && !Objects.equals(settingOpt.get().getTermId(), termId);

                    if (scopeMissing) {
                        missingFeeScopeCount++;
                        addExample(missingFeeExamples, programCode + " Y" + yearLevel + " S" + semester + " TUITION");
                    } else if (scopeFallback) {
                        fallbackFeeScopeCount++;
                        addExample(fallbackFeeExamples, programCode + " Y" + yearLevel + " S" + semester + " TUITION");
                    }
                }
            }
        }

        boolean ready = !programs.isEmpty()
            && missingFeeScopeCount == 0
            && fallbackFeeScopeCount == 0
            && missingCurricula.isEmpty();
        summary.put("missingFeeScopeCount", missingFeeScopeCount);
        summary.put("fallbackFeeScopeCount", fallbackFeeScopeCount);
        summary.put("checkedScopeCount", checkedScopeCount);
        summary.put("ready", ready);
        summary.put("statusText", ready
            ? "Ready for operation."
            : "Review warnings before activating or operating this term.");
        return summary;
    }

    private Map<String, Object> termDetails(Integer termId) {
        try {
            return db.queryForMap(
                "SELECT term_id, term_code, term_name, academic_year, semester_number, status, is_active " +
                    "FROM academic_terms WHERE term_id = ? LIMIT 1",
                termId);
        } catch (Exception e) {
            Map<String, Object> fallback = new LinkedHashMap<>();
            fallback.put("term_id", termId);
            fallback.put("term_name", "Term #" + termId);
            fallback.put("status", "UNKNOWN");
            fallback.put("is_active", 0);
            return fallback;
        }
    }

    private boolean hasActiveCurriculum(int programId) {
        try {
            Integer count = db.queryForObject(
                "SELECT COUNT(*) FROM curriculum_templates WHERE program_id = ? AND is_active = 1",
                Integer.class, programId);
            return count != null && count > 0;
        } catch (Exception e) {
            return false;
        }
    }

    private static boolean isTruthy(Object value) {
        if (value instanceof Number) {
            return ((Number) value).intValue() != 0;
        }
        return value != null && Boolean.parseBoolean(value.toString());
    }

    private static void addExample(List<String> examples, String value) {
        if (examples.size() < 8) {
            examples.add(value);
        }
    }

    private Map<String, String> feeTemplateSources() {
        Map<String, String> sources = new LinkedHashMap<>();
        sources.put("BSBAFIN", "BSBA");
        sources.put("BSBAMKTG", "BSBA");
        sources.put("BSBAOPS", "BSBA");
        sources.put("BSCUSTOMAD", "BSBA");
        sources.put("BSPHARM", "BSMT");
        sources.put("BSPT", "BSMT");
        sources.put("BSOT", "BSMT");
        sources.put("BSRT", "BSMT");
        sources.put("BSRT-RESP", "BSMT");
        sources.put("BSND", "BSMT");
        sources.put("DMD", "BSMT");
        sources.put("BSCPE", "BSIT");
        sources.put("BEED", "BSED");
        return sources;
    }

    private static Map<String, Object> feeRow(String code, String name, String kind, String unitBasis) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("fee_code", code);
        m.put("fee_name", name);
        m.put("kind", kind);
        m.put("unit_basis", unitBasis);
        return m;
    }

    private boolean tableExists(String table) {
        try {
            Integer c = db.queryForObject(
                "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?",
                Integer.class, table);
            if (c != null && c > 0) {
                return true;
            }
        } catch (Exception ignored) {
        }
        try {
            db.queryForList("SELECT 1 FROM " + table + " WHERE 1 = 0");
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public record TermFeePreparationResult(
        int programsChecked,
        int scopesChecked,
        int coreRowsCreated,
        int coreRowsUpdated,
        int specificRowsCopied,
        int unableToInferTuition
    ) {}

    public record FeeTemplateCopyResult(
        int programsChecked,
        int programsSeeded,
        int coreRowsCreated,
        int coreRowsUpdated,
        int specificRowsCopied,
        int skippedNoSource
    ) {}
}
