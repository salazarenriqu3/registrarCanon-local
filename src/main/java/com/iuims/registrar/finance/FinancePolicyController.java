package com.iuims.registrar.finance;

import com.iuims.registrar.core.YearLevelLoadPolicyService;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.Map;

@Controller
@RequestMapping("/admin/finance-policy")
public class FinancePolicyController {

    private final FinancePolicyService financePolicyService;
    private final YearLevelLoadPolicyService yearLevelLoadPolicyService;

    public FinancePolicyController(FinancePolicyService financePolicyService,
                                   YearLevelLoadPolicyService yearLevelLoadPolicyService) {
        this.financePolicyService = financePolicyService;
        this.yearLevelLoadPolicyService = yearLevelLoadPolicyService;
    }

    @GetMapping
    public String show(@RequestParam(required = false) Integer installmentTermId,
                       HttpSession session,
                       Model model) {
        if (session.getAttribute("currentUser") == null) return "redirect:/login";
        Map<String, Object> view = financePolicyService.buildPolicyView(installmentTermId);
        model.addAllAttributes(view);
        model.addAttribute("yearLevelLoadPolicies", yearLevelLoadPolicyService.listPolicies());
        return "admin_finance_policy";
    }

    @PostMapping("/save-year-level-loads")
    public String saveYearLevelLoads(@RequestParam Map<String, String> params,
                                     @RequestParam(required = false) Integer installmentTermId,
                                     HttpSession session,
                                     RedirectAttributes ra) {
        if (session.getAttribute("currentUser") == null) return "redirect:/login";
        try {
            yearLevelLoadPolicyService.savePolicies(params);
            ra.addFlashAttribute("successMessage", "Year-level unit load policy saved.");
        } catch (IllegalArgumentException e) {
            ra.addFlashAttribute("errorMessage", e.getMessage());
        }
        return redirect(installmentTermId);
    }

    @PostMapping("/save-gates")
    public String saveGates(@RequestParam(required = false) Integer installmentTermId,
                            HttpSession session,
                            RedirectAttributes ra) {
        return FeeConfigurationRedirectSupport.blockFinancePolicyWrite(session, ra, installmentTermId);
    }

    @PostMapping("/save-rules")
    public String saveRules(@RequestParam(required = false) Integer installmentTermId,
                           HttpSession session,
                           RedirectAttributes ra) {
        return FeeConfigurationRedirectSupport.blockFinancePolicyWrite(session, ra, installmentTermId);
    }

    @PostMapping("/save-installments")
    public String saveInstallments(@RequestParam(required = false) Integer installmentTermId,
                                   HttpSession session,
                                   RedirectAttributes ra) {
        return FeeConfigurationRedirectSupport.blockFinancePolicyWrite(session, ra, installmentTermId);
    }

    @PostMapping("/copy-installments")
    public String copyInstallments(@RequestParam(required = false) Integer targetTermId,
                                   HttpSession session,
                                   RedirectAttributes ra) {
        return FeeConfigurationRedirectSupport.blockFinancePolicyWrite(session, ra, targetTermId);
    }

    @PostMapping("/save-enrollment-periods")
    public String saveEnrollmentPeriods(@RequestParam Map<String, String> params,
                                        @RequestParam(required = false) Integer installmentTermId,
                                        HttpSession session,
                                        RedirectAttributes ra) {
        if (session.getAttribute("currentUser") == null) return "redirect:/login";
        financePolicyService.saveEnrollmentPeriods(params);
        ra.addFlashAttribute("successMessage", "Enrollment period settings saved.");
        return redirect(installmentTermId);
    }

    private String redirect(Integer installmentTermId) {
        return installmentTermId != null
            ? "redirect:/admin/finance-policy?installmentTermId=" + installmentTermId
            : "redirect:/admin/finance-policy";
    }
}
