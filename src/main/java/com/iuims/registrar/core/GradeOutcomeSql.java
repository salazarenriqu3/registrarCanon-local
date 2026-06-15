package com.iuims.registrar.core;
import com.iuims.registrar.academic.AcademicGradingService;
import com.iuims.registrar.core.GradeOutcomeSql;
import com.iuims.registrar.admission.ApplicantStatusSyncService;
import com.iuims.registrar.admission.FinanceAdmissionService;
import com.iuims.registrar.curriculum.CurriculumSeederService;
import com.iuims.registrar.curriculum.StudentCurriculumService;
import com.iuims.registrar.core.EnlistmentSchemaService;
import com.iuims.registrar.faculty.FacultyLoadService;
import com.iuims.registrar.scholarship.ScholarEnrollmentService;
import com.iuims.registrar.finance.TermFeeAdminService;
import com.iuims.registrar.core.DatabaseSetupService;
import com.iuims.registrar.jaypee.JaypeeIntegrationService;
import com.iuims.registrar.core.PolicySettings;
import com.iuims.registrar.core.SqlGenerator;

public final class GradeOutcomeSql {

    private GradeOutcomeSql() {}

    public static String passed(String alias) {
        return outcome(alias) + " = 'PASSED'";
    }

    public static String failedOrInc(String alias) {
        return outcome(alias) + " IN ('FAILED', 'INC')";
    }

    public static String failed(String alias) {
        return outcome(alias) + " = 'FAILED'";
    }

    public static String outcome(String alias) {
        return "UPPER(COALESCE(" + alias + ".registrar_final_remarks, " + alias + ".remarks, ''))";
    }
}





