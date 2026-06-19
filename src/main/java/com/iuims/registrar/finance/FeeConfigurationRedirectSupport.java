package com.iuims.registrar.finance;

import jakarta.servlet.http.HttpSession;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

/**
 * Blocks legacy Registrar fee write paths; configuration lives in Enrollment (Cashier/Accounting).
 */
final class FeeConfigurationRedirectSupport {

    static final String MOVED_MESSAGE =
        "Fee amounts and finance policy are configured in Enrollment (Cashier/Accounting), not Registrar. "
            + "Use the Enrollment portal link on this page.";

    private FeeConfigurationRedirectSupport() {
    }

    static String blockFeeWrite(HttpSession session, RedirectAttributes redirectAttributes) {
        if (session.getAttribute("currentUser") == null) {
            return "redirect:/login";
        }
        redirectAttributes.addFlashAttribute("errorMessage", MOVED_MESSAGE);
        return "redirect:/admin/term-fees";
    }

    static String blockFinancePolicyWrite(HttpSession session,
                                          RedirectAttributes redirectAttributes,
                                          Integer installmentTermId) {
        if (session.getAttribute("currentUser") == null) {
            return "redirect:/login";
        }
        redirectAttributes.addFlashAttribute("errorMessage", MOVED_MESSAGE);
        return installmentTermId != null
            ? "redirect:/admin/finance-policy?installmentTermId=" + installmentTermId
            : "redirect:/admin/finance-policy";
    }
}
