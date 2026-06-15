package com.iuims.registrar.withdrawal;

import com.iuims.registrar.jaypee.JaypeeIntegrationService;
import com.iuims.registrar.forms.RegFormEventService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.Map;

@Controller
public class WithdrawalController {

    private final WithdrawalService withdrawalService;
    private final JaypeeIntegrationService jaypeeService;
    private final RegFormEventService regFormEventService;

    public WithdrawalController(WithdrawalService withdrawalService, JaypeeIntegrationService jaypeeService,
                                RegFormEventService regFormEventService) {
        this.withdrawalService = withdrawalService;
        this.jaypeeService = jaypeeService;
        this.regFormEventService = regFormEventService;
    }

    @GetMapping("/admin/withdrawals")
    public String registrarQueue(HttpSession session, Model model) {
        if (session.getAttribute("currentUser") == null) return "redirect:/login";
        model.addAttribute("queueMode", "REGISTRAR");
        model.addAttribute("pageTitle", "Withdrawal Approvals");
        model.addAttribute("pageSubtitle", "Final Registrar approval removes the subject and preserves the reasoned audit trail.");
        model.addAttribute("requests", withdrawalService.listRequests(WithdrawalService.STATUS_PENDING_REGISTRAR));
        model.addAttribute("statusCounts", withdrawalService.statusCounts());
        return "withdrawal_queue";
    }

    @GetMapping("/admin/withdrawals/report")
    public String registrarReport(HttpSession session, Model model) {
        if (session.getAttribute("currentUser") == null) return "redirect:/login";
        model.addAttribute("queueMode", "REPORT");
        model.addAttribute("pageTitle", "Withdrawal Report");
        model.addAttribute("pageSubtitle", "Reportable withdrawal history by reason, timing bucket, program, and approver.");
        model.addAttribute("requests", withdrawalService.listRequests(null));
        model.addAttribute("statusCounts", withdrawalService.statusCounts());
        model.addAttribute("reasonSummary", withdrawalService.reasonSummary());
        model.addAttribute("timingSummary", withdrawalService.timingSummary());
        return "withdrawal_queue";
    }

    @GetMapping("/faculty/withdrawals")
    public String deanQueue(HttpSession session, Model model) {
        if (session.getAttribute("currentUser") == null) return "redirect:/login";
        model.addAttribute("queueMode", "DEAN");
        model.addAttribute("pageTitle", "Dean Withdrawal Review");
        model.addAttribute("pageSubtitle", "Review subject withdrawal requests before Registrar final approval.");
        model.addAttribute("requests", withdrawalService.listRequests(WithdrawalService.STATUS_PENDING_DEAN));
        model.addAttribute("statusCounts", withdrawalService.statusCounts());
        return "withdrawal_queue";
    }

    @PostMapping("/admin/withdrawals/request")
    public String requestWithdrawal(@RequestParam String studentNumber,
                                    @RequestParam Integer scheduleId,
                                    @RequestParam String reasonCode,
                                    @RequestParam(required = false) String remarks,
                                    HttpSession session,
                                    RedirectAttributes ra) {
        if (session.getAttribute("currentUser") == null) return "redirect:/login";
        String username = studentNumber != null ? studentNumber.trim() : "";
        try {
            long requestId = withdrawalService.createRequest(
                username, scheduleId, reasonCode, remarks, currentUsername(session));
            ra.addFlashAttribute("successMessage",
                "Withdrawal request #" + requestId + " submitted for Dean review.");
        } catch (Exception e) {
            ra.addFlashAttribute("errorMessage", "Withdrawal request failed: " + e.getMessage());
        }
        ra.addAttribute("username", username);
        return "redirect:/admin/student-manager";
    }

    @PostMapping("/faculty/withdrawals/dean-approve")
    public String deanApprove(@RequestParam long requestId,
                              HttpSession session,
                              RedirectAttributes ra) {
        if (session.getAttribute("currentUser") == null) return "redirect:/login";
        ra.addFlashAttribute("successMessage",
            withdrawalService.deanApprove(requestId, currentUsername(session)));
        return "redirect:/faculty/withdrawals";
    }

    @PostMapping("/admin/withdrawals/approve")
    public String registrarApprove(@RequestParam long requestId,
                                   HttpSession session,
                                   RedirectAttributes ra) {
        if (session.getAttribute("currentUser") == null) return "redirect:/login";
        try {
            Map<String, Object> request = withdrawalService.prepareRegistrarApproval(requestId, currentUsername(session));
            String studentNumber = String.valueOf(request.get("student_number"));
            int sectionId = ((Number) request.get("section_id")).intValue();
            double charge = request.get("estimated_charge") instanceof Number n ? n.doubleValue() : 0.0;
            String policyNote = request.get("policy_note") != null ? request.get("policy_note").toString() : null;
            String courseCode = request.get("course_code") != null ? request.get("course_code").toString() : "subject";
            jaypeeService.dropSubjectCrossSystem(studentNumber, sectionId, charge, policyNote);
            withdrawalService.markCompleted(requestId);
            regFormEventService.recordEvent(
                studentNumber,
                "WITHDRAWAL_APPROVED",
                "Registration form updated after formal withdrawal",
                requestId,
                String.format("Removed %s. Applied charge: PHP %,.2f.", courseCode, charge),
                currentUsername(session));
            ra.addFlashAttribute("successMessage",
                String.format("Withdrawal request #%d approved and subject removed. Applied charge: PHP %,.2f.",
                    requestId, charge));
        } catch (Exception e) {
            ra.addFlashAttribute("errorMessage", "Withdrawal approval failed: " + e.getMessage());
        }
        return "redirect:/admin/withdrawals";
    }

    @PostMapping({"/admin/withdrawals/reject", "/faculty/withdrawals/reject"})
    public String reject(@RequestParam long requestId,
                         @RequestParam(required = false) String rejectionReason,
                         HttpServletRequest request,
                         HttpSession session,
                         RedirectAttributes ra) {
        if (session.getAttribute("currentUser") == null) return "redirect:/login";
        ra.addFlashAttribute("successMessage",
            withdrawalService.reject(requestId, currentUsername(session), rejectionReason));
        String path = request.getRequestURI();
        return path != null && path.contains("/faculty/")
            ? "redirect:/faculty/withdrawals"
            : "redirect:/admin/withdrawals";
    }

    private String currentUsername(HttpSession session) {
        Object raw = session.getAttribute("currentUser");
        if (raw instanceof Map<?, ?> user && user.get("username") != null) {
            return user.get("username").toString();
        }
        return "registrar";
    }
}
