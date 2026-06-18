import os
import re

src_dir = r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\main\java"

replacements = {
    "import com.iuims.registrar.academic.GradeOutcomeSql;": "import com.iuims.registrar.core.GradeOutcomeSql;",
    "import com.iuims.registrar.core.JaypeeIntegrationService;": "import com.iuims.registrar.jaypee.JaypeeIntegrationService;",
    "import com.iuims.registrar.scholarship.ScholarController;": "import com.iuims.registrar.portal.ScholarController;",
    "import com.iuims.registrar.academic.AcademicController;": "import com.iuims.registrar.portal.AcademicController;",
    "import com.iuims.registrar.enrollment.EnrollmentController;": "import com.iuims.registrar.portal.EnrollmentController;"
}

for root, _, files in os.walk(src_dir):
    for f in files:
        if f.endswith(".java"):
            path = os.path.join(root, f)
            with open(path, "r", encoding="utf-8") as file:
                content = file.read()
            
            modified = False
            for old, new in replacements.items():
                if old in content:
                    content = content.replace(old, new)
                    modified = True
            
            if "AcademicGradingService.getCurrentGlobalTermCode" in content:
                content = content.replace("AcademicGradingService.getCurrentGlobalTermCode", "GlobalTermService.getCurrentGlobalTermCode")
                modified = True
                
            if modified:
                with open(path, "w", encoding="utf-8") as file:
                    file.write(content)
                print(f"Fixed imports in {f}")

print("Done.")
