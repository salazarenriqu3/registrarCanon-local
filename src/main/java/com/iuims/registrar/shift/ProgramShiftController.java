package com.iuims.registrar.shift;

import com.iuims.registrar.jaypee.JaypeeIntegrationService;
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
public class ProgramShiftController {

    private final ProgramShiftRequestService shiftService;
    private final JaypeeIntegrationService jaypeeService;

    public ProgramShiftController(ProgramShiftRequestService shiftService,
                                  JaypeeIntegrationService jaypeeService) {
        this.shiftService = shiftService;
        this.jaypeeService = jaypeeService;
    }

    @GetMapping("/admin/program-shifts")
    public String registrarQueue(HttpSession session, Model model) {
        if (session.getAttribute("currentUser") == null) return "redirect:/login";
        model.addAttribute("queueMode", "REGISTRAR");
        model.addAttribute("pageTitle", "Program Shift Approvals");
        model.addAttribute("pageSubtitle", "Final Registrar approval executes the program shift.");
        model.addAttribute("requests", shiftService.listRequests(ProgramShiftRequestService.STATUS_PENDING_REGISTRAR));
        model.addAttribute("statusCounts", shiftService.statusCounts());
        return "program_shift_queue";
    }

    @GetMapping("/faculty/program-shifts")
    public String deanQueue(HttpSession session, Model model) {
        if (session.getAttribute("currentUser") == null) return "redirect:/login";
        model.addAttribute("queueMode", "DEAN");
        model.addAttribute("pageTitle", "Dean Program Shift Review");
        model.addAttribute("pageSubtitle", "Review program shift requests before Registrar final approval.");
        model.addAttribute("requests", shiftService.listRequests(ProgramShiftRequestService.STATUS_PENDING_DEAN));
        model.addAttribute("statusCounts", shiftService.statusCounts());
        return "program_shift_queue";
    }

    @PostMapping("/faculty/program-shifts/dean-approve")
    public String deanApprove(@RequestParam long requestId,
                              HttpSession session,
                              RedirectAttributes ra) {
        if (session.getAttribute("currentUser") == null) return "redirect:/login";
        ra.addFlashAttribute("successMessage",
            shiftService.deanApprove(requestId, currentUsername(session)));
        return "redirect:/faculty/program-shifts";
    }

    @PostMapping("/admin/program-shifts/approve")
    public String registrarApprove(@RequestParam long requestId,
                                   HttpSession session,
                                   RedirectAttributes ra) {
        if (session.getAttribute("currentUser") == null) return "redirect:/login";
        try {
            Map<String, Object> request = shiftService.prepareRegistrarApproval(requestId, currentUsername(session));
            String studentNumber = String.valueOf(request.get("student_number"));
            String targetProgram = String.valueOf(request.get("to_program_code"));
            Integer yearLevel = request.get("target_year_level") instanceof Number n ? n.intValue() : null;
            Integer semester = request.get("target_semester") instanceof Number n ? n.intValue() : null;
            Integer curriculumId = request.get("target_curriculum_id") instanceof Number n ? n.intValue() : null;
            String reason = request.get("reason") != null ? request.get("reason").toString() : null;
            String result = jaypeeService.shiftStudentProgram(
                studentNumber, targetProgram, yearLevel, semester, curriculumId, reason);
            if (!result.startsWith("SUCCESS:")) {
                throw new IllegalStateException(result);
            }
            shiftService.markCompleted(requestId);
            ra.addFlashAttribute("successMessage",
                "Program shift request #" + requestId + " approved. " + result);
        } catch (Exception e) {
            ra.addFlashAttribute("errorMessage", "Program shift approval failed: " + e.getMessage());
        }
        return "redirect:/admin/program-shifts";
    }

    @PostMapping({"/admin/program-shifts/reject", "/faculty/program-shifts/reject"})
    public String reject(@RequestParam long requestId,
                         @RequestParam(required = false) String rejectionReason,
                         HttpServletRequest request,
                         HttpSession session,
                         RedirectAttributes ra) {
        if (session.getAttribute("currentUser") == null) return "redirect:/login";
        ra.addFlashAttribute("successMessage",
            shiftService.reject(requestId, currentUsername(session), rejectionReason));
        String path = request.getRequestURI();
        return path != null && path.contains("/faculty/")
            ? "redirect:/faculty/program-shifts"
            : "redirect:/admin/program-shifts";
    }

    private String currentUsername(HttpSession session) {
        Object raw = session.getAttribute("currentUser");
        if (raw instanceof Map<?, ?> user && user.get("username") != null) {
            return user.get("username").toString();
        }
        return "registrar";
    }
}
