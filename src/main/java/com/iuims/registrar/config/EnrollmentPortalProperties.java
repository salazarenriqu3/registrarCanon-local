package com.iuims.registrar.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Links to the Enrollment (Cashier/Accounting) app where program fees and finance policy are configured.
 */
@Component
@ConfigurationProperties(prefix = "enrollment.portal")
public class EnrollmentPortalProperties {

    /** Base URL without trailing slash, e.g. http://localhost:8082 */
    private String baseUrl = "http://localhost:8082";

    public String getBaseUrl() {
        return baseUrl != null ? baseUrl.trim().replaceAll("/+$", "") : "http://localhost:8082";
    }

    public void setBaseUrl(String baseUrl) {
        this.baseUrl = baseUrl;
    }

    public String financePolicyUrl() {
        return getBaseUrl() + "/admin/finance-policy";
    }

    public String termFeesUrl() {
        return getBaseUrl() + "/admin/term-fees";
    }

    public String courseFeesUrl() {
        return getBaseUrl() + "/admin/course-fees";
    }

    public String termFeesScopeUrl(Integer termId, String programCode, Integer yearLevel, Integer semester) {
        StringBuilder url = new StringBuilder(getBaseUrl()).append("/admin/term-fees");
        if (termId == null) {
            return url.toString();
        }
        url.append("?termId=").append(termId);
        if (programCode != null && !programCode.isBlank()) {
            url.append("&programCode=").append(programCode.trim().toUpperCase());
        }
        if (yearLevel != null) {
            url.append("&yearLevel=").append(yearLevel);
        }
        if (semester != null) {
            url.append("&semester=").append(semester);
        }
        return url.toString();
    }
}
