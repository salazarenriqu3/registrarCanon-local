package com.iuims.registrar.config;

import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

@ControllerAdvice
public class FeeOwnershipModelAdvice {

    private final EnrollmentPortalProperties enrollmentPortal;

    public FeeOwnershipModelAdvice(EnrollmentPortalProperties enrollmentPortal) {
        this.enrollmentPortal = enrollmentPortal;
    }

    @ModelAttribute("enrollmentPortalBaseUrl")
    public String enrollmentPortalBaseUrl() {
        return enrollmentPortal.getBaseUrl();
    }

    @ModelAttribute("enrollmentFinancePolicyUrl")
    public String enrollmentFinancePolicyUrl() {
        return enrollmentPortal.financePolicyUrl();
    }

    @ModelAttribute("enrollmentTermFeesUrl")
    public String enrollmentTermFeesUrl() {
        return enrollmentPortal.termFeesUrl();
    }

    @ModelAttribute("enrollmentCourseFeesUrl")
    public String enrollmentCourseFeesUrl() {
        return enrollmentPortal.courseFeesUrl();
    }
}
