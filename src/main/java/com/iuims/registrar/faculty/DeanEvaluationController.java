package com.iuims.registrar.faculty;

import com.iuims.registrar.academic.AcademicGradingService;
import com.iuims.registrar.curriculum.StudentCurriculumService;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;
import java.util.Map;

@Controller
public class DeanEvaluationController {

    private final StudentCurriculumService studentCurriculumService;
    private final AcademicGradingService academicGradingService;

    public DeanEvaluationController(StudentCurriculumService studentCurriculumService,
                                    AcademicGradingService academicGradingService) {
        this.studentCurriculumService = studentCurriculumService;
        this.academicGradingService = academicGradingService;
    }

    @GetMapping("/dean/student-evaluation")
    public String studentEvaluation(@RequestParam(required = false) String studentNumber,
                                    HttpSession session,
                                    Model model) {
        if (session.getAttribute("currentUser") == null) return "redirect:/login";
        model.addAttribute("studentNumber", studentNumber);
        if (studentNumber != null && !studentNumber.isBlank()) {
            String sn = studentNumber.trim();
            Map<String, Object> student = academicGradingService.findStudentByIdOrName(sn);
            model.addAttribute("student", student);
            model.addAttribute("assignment", studentCurriculumService.getCurrentAssignment(sn));
            List<Map<String, Object>> checklist = studentCurriculumService.buildCurriculumEvaluationChecklist(sn);
            model.addAttribute("checklist", checklist);
            long passed = checklist.stream().filter(r -> "passed".equals(r.get("status"))).count();
            long failed = checklist.stream().filter(r -> "failed".equals(r.get("status"))).count();
            model.addAttribute("passedCount", passed);
            model.addAttribute("failedCount", failed);
        }
        return "dean_student_evaluation";
    }
}
