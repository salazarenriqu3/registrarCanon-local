$base = "src\main\java\com\iuims\registrar"
mkdir $base\academic, $base\admission, $base\curriculum, $base\enrollment, $base\faculty, $base\portal, $base\scholarship, $base\finance, $base\core -Force

function Move-AndUpdate {
    param($fileName, $fromDir, $toModule)
    $src = "$base\$fromDir\$fileName"
    $dest = "$base\$toModule\$fileName"
    if (Test-Path $src) {
        Move-Item -Path $src -Destination $dest -Force
        $content = Get-Content $dest -Raw
        $content = $content -replace "package com.iuims.registrar.$fromDir;", "package com.iuims.registrar.$toModule;"
        Set-Content -Path $dest -Value $content
    }
}

Move-AndUpdate "AcademicController.java" "controller" "academic"
Move-AndUpdate "AcademicGradingService.java" "service" "academic"
Move-AndUpdate "GradeOutcomeSql.java" "service" "academic"

Move-AndUpdate "AdmissionController.java" "controller" "admission"
Move-AndUpdate "ApplicantStatusSyncService.java" "service" "admission"
Move-AndUpdate "FinanceAdmissionService.java" "service" "admission"

Move-AndUpdate "CurriculumController.java" "controller" "curriculum"
Move-AndUpdate "CurriculumSeederService.java" "service" "curriculum"
Move-AndUpdate "StudentCurriculumService.java" "service" "curriculum"

Move-AndUpdate "EnrollmentController.java" "controller" "enrollment"
Move-AndUpdate "EnlistmentSchemaService.java" "service" "enrollment"

Move-AndUpdate "FacultyLoadController.java" "controller" "faculty"
Move-AndUpdate "FacultyLoadService.java" "service" "faculty"

Move-AndUpdate "PortalController.java" "controller" "portal"

Move-AndUpdate "ScholarController.java" "controller" "scholarship"
Move-AndUpdate "ScholarshipController.java" "controller" "scholarship"
Move-AndUpdate "ScholarEnrollmentService.java" "service" "scholarship"

Move-AndUpdate "TermFeeAdminController.java" "controller" "finance"
Move-AndUpdate "TermFeeAdminService.java" "service" "finance"

Move-AndUpdate "DatabaseSetupService.java" "service" "core"
Move-AndUpdate "JaypeeIntegrationService.java" "service" "core"
Move-AndUpdate "PolicySettings.java" "service" "core"

$sqlGen = "$base\SqlGenerator.java"
if (Test-Path $sqlGen) {
    Move-Item -Path $sqlGen -Destination "$base\core\SqlGenerator.java" -Force
    $content = Get-Content "$base\core\SqlGenerator.java" -Raw
    $content = $content -replace "package com.iuims.registrar;", "package com.iuims.registrar.core;"
    Set-Content -Path "$base\core\SqlGenerator.java" -Value $content
}

$replacements = @{
    "com.iuims.registrar.controller.AcademicController" = "com.iuims.registrar.academic.AcademicController"
    "com.iuims.registrar.service.AcademicGradingService" = "com.iuims.registrar.academic.AcademicGradingService"
    "com.iuims.registrar.service.GradeOutcomeSql" = "com.iuims.registrar.academic.GradeOutcomeSql"
    "com.iuims.registrar.controller.AdmissionController" = "com.iuims.registrar.admission.AdmissionController"
    "com.iuims.registrar.service.ApplicantStatusSyncService" = "com.iuims.registrar.admission.ApplicantStatusSyncService"
    "com.iuims.registrar.service.FinanceAdmissionService" = "com.iuims.registrar.admission.FinanceAdmissionService"
    "com.iuims.registrar.controller.CurriculumController" = "com.iuims.registrar.curriculum.CurriculumController"
    "com.iuims.registrar.service.CurriculumSeederService" = "com.iuims.registrar.curriculum.CurriculumSeederService"
    "com.iuims.registrar.service.StudentCurriculumService" = "com.iuims.registrar.curriculum.StudentCurriculumService"
    "com.iuims.registrar.controller.EnrollmentController" = "com.iuims.registrar.enrollment.EnrollmentController"
    "com.iuims.registrar.service.EnlistmentSchemaService" = "com.iuims.registrar.enrollment.EnlistmentSchemaService"
    "com.iuims.registrar.controller.FacultyLoadController" = "com.iuims.registrar.faculty.FacultyLoadController"
    "com.iuims.registrar.service.FacultyLoadService" = "com.iuims.registrar.faculty.FacultyLoadService"
    "com.iuims.registrar.controller.PortalController" = "com.iuims.registrar.portal.PortalController"
    "com.iuims.registrar.controller.ScholarController" = "com.iuims.registrar.scholarship.ScholarController"
    "com.iuims.registrar.controller.ScholarshipController" = "com.iuims.registrar.scholarship.ScholarshipController"
    "com.iuims.registrar.service.ScholarEnrollmentService" = "com.iuims.registrar.scholarship.ScholarEnrollmentService"
    "com.iuims.registrar.controller.TermFeeAdminController" = "com.iuims.registrar.finance.TermFeeAdminController"
    "com.iuims.registrar.service.TermFeeAdminService" = "com.iuims.registrar.finance.TermFeeAdminService"
    "com.iuims.registrar.service.DatabaseSetupService" = "com.iuims.registrar.core.DatabaseSetupService"
    "com.iuims.registrar.service.JaypeeIntegrationService" = "com.iuims.registrar.core.JaypeeIntegrationService"
    "com.iuims.registrar.service.PolicySettings" = "com.iuims.registrar.core.PolicySettings"
    "com.iuims.registrar.SqlGenerator" = "com.iuims.registrar.core.SqlGenerator"
}

Get-ChildItem -Path "src\main\java" -Filter "*.java" -Recurse | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content $file -Raw
    $modified = $false
    foreach ($key in $replacements.Keys) {
        $escapedKey = [regex]::Escape($key)
        if ($content -match $escapedKey) {
            $content = $content -replace $escapedKey, $replacements[$key]
            $modified = $true
        }
    }
    if ($modified) {
        Set-Content -Path $file -Value $content
    }
}

Remove-Item "$base\controller" -Force -Recurse
Remove-Item "$base\service" -Force -Recurse
