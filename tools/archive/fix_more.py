import os
import re

base_dir = r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\main\java"

# 1. Add import for ClassInfoDto in AcademicController
ac_path = os.path.join(base_dir, "com", "iuims", "registrar", "portal", "AcademicController.java")
with open(ac_path, "r", encoding="utf-8") as f:
    ac_content = f.read()
if "import com.iuims.registrar.academic.ClassInfoDto;" not in ac_content:
    ac_content = ac_content.replace("import com.iuims.registrar.academic.AcademicGradingService;", "import com.iuims.registrar.academic.AcademicGradingService;\nimport com.iuims.registrar.academic.ClassInfoDto;")
    with open(ac_path, "w", encoding="utf-8") as f:
        f.write(ac_content)

# 2. Fix ScholarEnrollmentService to use GlobalTermService instead of AcademicGradingService for getCurrentGlobalTermCode
ses_path = os.path.join(base_dir, "com", "iuims", "registrar", "scholarship", "ScholarEnrollmentService.java")
with open(ses_path, "r", encoding="utf-8") as f:
    ses_content = f.read()
if "globalTermService" not in ses_content:
    ses_content = ses_content.replace("import com.iuims.registrar.academic.AcademicGradingService;", "import com.iuims.registrar.academic.AcademicGradingService;\nimport com.iuims.registrar.core.GlobalTermService;")
    ses_content = ses_content.replace("@Autowired\n    private AcademicGradingService academicService;", "@Autowired\n    private AcademicGradingService academicService;\n\n    @Autowired\n    private GlobalTermService globalTermService;")
    ses_content = ses_content.replace("academicService.getCurrentGlobalTermCode()", "globalTermService.getCurrentGlobalTermCode()")
    with open(ses_path, "w", encoding="utf-8") as f:
        f.write(ses_content)

# 3. Fix ScholarController (now in portal) to use GlobalTermService
sc_path = os.path.join(base_dir, "com", "iuims", "registrar", "portal", "ScholarController.java")
with open(sc_path, "r", encoding="utf-8") as f:
    sc_content = f.read()
if "globalTermService" not in sc_content:
    sc_content = sc_content.replace("import com.iuims.registrar.academic.AcademicGradingService;", "import com.iuims.registrar.academic.AcademicGradingService;\nimport com.iuims.registrar.core.GlobalTermService;")
    sc_content = sc_content.replace("@Autowired private AcademicGradingService academicService;", "@Autowired private AcademicGradingService academicService;\n    @Autowired private GlobalTermService globalTermService;")
    sc_content = sc_content.replace("academicService.getCurrentGlobalTermCode()", "globalTermService.getCurrentGlobalTermCode()")
    with open(sc_path, "w", encoding="utf-8") as f:
        f.write(sc_content)

# 4. Remove getCurrentGlobalTermCode from AcademicGradingService
ags_path = os.path.join(base_dir, "com", "iuims", "registrar", "academic", "AcademicGradingService.java")
with open(ags_path, "r", encoding="utf-8") as f:
    ags_content = f.read()
if "public String getCurrentGlobalTermCode()" in ags_content:
    # Regex to remove the method
    ags_content = re.sub(r'public String getCurrentGlobalTermCode\(\) \{[\s\S]*?return null;\s*\}\s*\}', '', ags_content)
    with open(ags_path, "w", encoding="utf-8") as f:
        f.write(ags_content)

print("Done phase 2.")
