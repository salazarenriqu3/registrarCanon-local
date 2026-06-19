package com.iuims.registrar.finance;

import com.iuims.registrar.config.EnrollmentPortalProperties;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

/**
 * Read-only term fee readiness for Registrar deployment gates.
 * Program fee amounts are configured in Enrollment ({@code /admin/term-fees}).
 */
@Controller
@RequestMapping("/admin/term-fees")
public class TermFeeAdminController {

    private final TermFeeAdminService termFeeAdminService;
    private final EnrollmentPortalProperties enrollmentPortal;

    public TermFeeAdminController(TermFeeAdminService termFeeAdminService,
                                    EnrollmentPortalProperties enrollmentPortal) {
        this.termFeeAdminService = termFeeAdminService;
        this.enrollmentPortal = enrollmentPortal;
    }

    @GetMapping
    public String show(@RequestParam(required = false) Integer termId,
                       @RequestParam(required = false) String programCode,
                       @RequestParam(defaultValue = "1") int yearLevel,
                       @RequestParam(defaultValue = "1") int semester,
                       HttpSession session,
                       Model model) {
        if (session.getAttribute("currentUser") == null) {
            return "redirect:/login";
        }

        List<String> missingTables = termFeeAdminService.validateTablesExist();
        model.addAttribute("missingTables", missingTables);
        model.addAttribute("terms", termFeeAdminService.listTermsAscending());
        model.addAttribute("programs", termFeeAdminService.listPrograms());

        Integer activeTermId = termFeeAdminService.getActiveTermId();
        Integer effectiveTermId = termId != null ? termId : activeTermId;
        model.addAttribute("activeTermId", activeTermId);
        model.addAttribute("termId", effectiveTermId);
        model.addAttribute("yearLevel", yearLevel);
        model.addAttribute("semester", semester);
        model.addAttribute("termReadiness", termFeeAdminService.buildTermReadinessSummary(effectiveTermId));
        model.addAttribute("unresolvedScopes", termFeeAdminService.listFeeScopeReadiness(effectiveTermId, true, 40));

        Integer previousTermId = effectiveTermId != null
            ? termFeeAdminService.resolvePreviousTermId(effectiveTermId) : null;
        model.addAttribute("previousTermId", previousTermId);
        model.addAttribute("sourceTermReadiness",
            previousTermId != null ? termFeeAdminService.buildTermReadinessSummary(previousTermId) : Map.of());

        String effectiveProgram = (programCode != null && !programCode.isBlank())
            ? programCode.trim().toUpperCase()
            : (!termFeeAdminService.listPrograms().isEmpty()
                ? (String) termFeeAdminService.listPrograms().get(0).get("program_code") : null);
        model.addAttribute("programCode", effectiveProgram);

        Integer programId = effectiveProgram != null
            ? termFeeAdminService.resolveProgramId(effectiveProgram) : null;

        if (effectiveTermId != null && programId != null && missingTables.isEmpty()) {
            List<Map<String, Object>> feeTypes =
                termFeeAdminService.listFeeTypesForAdmin(programId, effectiveTermId, yearLevel, semester);
            Map<String, Double> currentRates =
                termFeeAdminService.getFeeRatesForScope(programId, effectiveTermId, yearLevel, semester);
            Map<String, String> rateSources =
                termFeeAdminService.getFeeRateSourcesForScope(programId, effectiveTermId, yearLevel, semester);
            model.addAttribute("feeTypes", feeTypes);
            model.addAttribute("currentRates", currentRates);
            model.addAttribute("rateSources", rateSources);
            model.addAttribute("missingFeeCodes", missingFeeCodes(feeTypes, currentRates));
            model.addAttribute("fallbackFeeCodes", fallbackFeeCodes(feeTypes, rateSources));
            model.addAttribute("enrollmentScopeUrl",
                enrollmentPortal.termFeesScopeUrl(effectiveTermId, effectiveProgram, yearLevel, semester));
        } else {
            model.addAttribute("feeTypes", List.of());
            model.addAttribute("currentRates", Map.of());
            model.addAttribute("rateSources", Map.of());
            model.addAttribute("missingFeeCodes", List.of());
            model.addAttribute("fallbackFeeCodes", List.of());
            model.addAttribute("enrollmentScopeUrl", enrollmentPortal.termFeesUrl());
        }

        return "admin_term_fees";
    }

    @PostMapping({"/save", "/import-global", "/import-scope", "/import-from-term", "/prepare",
        "/copy-templates", "/import-template"})
    public String blockWrites(HttpSession session, RedirectAttributes redirectAttributes) {
        return FeeConfigurationRedirectSupport.blockFeeWrite(session, redirectAttributes);
    }

    @GetMapping("/readiness-export")
    public void exportReadiness(@RequestParam Integer termId,
                                @RequestParam(defaultValue = "unresolved") String scope,
                                HttpSession session,
                                HttpServletResponse response) throws java.io.IOException {
        if (session.getAttribute("currentUser") == null) {
            response.sendRedirect("/login");
            return;
        }
        boolean unresolvedOnly = !"all".equalsIgnoreCase(scope);
        String csv = termFeeAdminService.exportFeeScopeReadinessCsv(termId, unresolvedOnly);
        writeCsvAttachment(response,
            "term-fee-gaps-term-" + termId + (unresolvedOnly ? "-unresolved" : "-all") + ".csv", csv);
    }

    @GetMapping("/import-template")
    public void exportImportTemplate(@RequestParam Integer termId,
                                     @RequestParam(defaultValue = "unresolved") String scope,
                                     HttpSession session,
                                     HttpServletResponse response) throws java.io.IOException {
        if (session.getAttribute("currentUser") == null) {
            response.sendRedirect("/login");
            return;
        }
        boolean unresolvedOnly = !"all".equalsIgnoreCase(scope);
        String csv = termFeeAdminService.exportFeeImportTemplateCsv(termId, unresolvedOnly);
        writeCsvAttachment(response,
            "term-fee-import-template-term-" + termId + (unresolvedOnly ? "-unresolved" : "-all") + ".csv", csv);
    }

    private static void writeCsvAttachment(HttpServletResponse response, String filename, String csv)
            throws java.io.IOException {
        response.setContentType("text/csv");
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
        response.getWriter().write(csv);
        response.getWriter().flush();
    }

    private List<String> missingFeeCodes(List<Map<String, Object>> feeTypes, Map<String, Double> currentRates) {
        java.util.ArrayList<String> missing = new java.util.ArrayList<>();
        for (Map<String, Object> feeType : feeTypes) {
            Object codeObj = feeType.get("fee_code");
            if (codeObj == null) {
                continue;
            }
            if (!currentRates.containsKey(codeObj.toString())) {
                missing.add(codeObj.toString());
            }
        }
        return missing;
    }

    private List<String> fallbackFeeCodes(List<Map<String, Object>> feeTypes, Map<String, String> rateSources) {
        java.util.ArrayList<String> fallback = new java.util.ArrayList<>();
        for (Map<String, Object> feeType : feeTypes) {
            Object codeObj = feeType.get("fee_code");
            if (codeObj == null) {
                continue;
            }
            if ("FALLBACK".equals(rateSources.get(codeObj.toString()))) {
                fallback.add(codeObj.toString());
            }
        }
        return fallback;
    }
}
