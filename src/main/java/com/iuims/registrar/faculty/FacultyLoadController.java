package com.iuims.registrar.faculty;
import com.iuims.registrar.academic.AcademicGradingService;
import com.iuims.registrar.core.GradeOutcomeSql;
import com.iuims.registrar.admission.ApplicantStatusSyncService;
import com.iuims.registrar.admission.FinanceAdmissionService;
import com.iuims.registrar.curriculum.CurriculumSeederService;
import com.iuims.registrar.curriculum.StudentCurriculumService;
import com.iuims.registrar.core.EnlistmentSchemaService;
import com.iuims.registrar.academic.SectionSchedulingService;
import com.iuims.registrar.faculty.FacultyLoadService;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Controller
public class FacultyLoadController {

    @Autowired
    private FacultyLoadService loadService;

    @Autowired
    private SectionSchedulingService sectionSchedulingService;

    // ------------------------------------------------------------------
    // Dashboard page
    // ------------------------------------------------------------------

    @GetMapping("/admin/faculty-load")
    public String facultyLoadDashboard(
            @RequestParam(required = false) Integer termId,
            @RequestParam(required = false) Integer departmentId,
            HttpSession session, Model model) {

        if (session.getAttribute("currentUser") == null) return "redirect:/login";

        Map<String, Object> activeTerm = loadService.getActiveTerm();
        if (termId == null) termId = ((Number) activeTerm.get("term_id")).intValue();

        List<Map<String, Object>> loads;
        if (departmentId != null) {
            loads = loadService.getDepartmentLoadSummary(departmentId, termId);
        } else {
            loads = loadService.getAllFacultyLoadSummary(termId);
        }

        model.addAttribute("loads",       loads);
        model.addAttribute("terms",       loadService.getAllTerms());
        model.addAttribute("departments", loadService.getAllDepartments());
        model.addAttribute("selectedTermId",  termId);
        model.addAttribute("selectedDeptId",  departmentId);
        model.addAttribute("activeTerm",  activeTerm);
        return "admin_faculty_load";
    }

    // ------------------------------------------------------------------
    // JSON detail for one faculty
    // ------------------------------------------------------------------

    @GetMapping("/api/faculty/{facultyId}/load")
    @ResponseBody
    public Map<String, Object> getFacultyLoadDetail(
            @PathVariable int facultyId,
            @RequestParam(defaultValue = "1") int termId) {

        Map<String, Object> summary = loadService.getFacultyLoadSummary(facultyId, termId);
        List<Map<String, Object>> sections = loadService.getFacultyLoad(facultyId, termId);
        return Map.of("summary", summary, "sections", sections);
    }

    // ------------------------------------------------------------------
    // Assign faculty to a section (with cap check)
    // ------------------------------------------------------------------

    @PostMapping("/api/schedule/assign-faculty")
    @ResponseBody
    public Map<String, Object> assignFaculty(
            @RequestParam int sectionId,
            @RequestParam int facultyId,
            @RequestParam int termId,
            HttpSession session) {

        if (session.getAttribute("currentUser") == null)
            return Map.of("success", false, "error", "Unauthorized");

        String result = sectionSchedulingService.assignFaculty(sectionId, facultyId);
        if ("SUCCESS".equals(result)) {
            return Map.of("success", true, "message", "Faculty assigned successfully.");
        }
        boolean overload = result.contains("unit cap");
        return Map.of(
            "success", false,
            "overload", overload,
            "message", result.startsWith("ERROR: ") ? result.substring(7) : result
        );
    }
}




