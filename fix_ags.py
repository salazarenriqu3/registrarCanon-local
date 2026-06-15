import os
import re

ags_path = r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\main\java\com\iuims\registrar\academic\AcademicGradingService.java"

with open(ags_path, "r", encoding="utf-8") as f:
    content = f.read()

imports_to_add = """
import com.iuims.registrar.core.PolicySettings;
import com.iuims.registrar.core.GradeOutcomeSql;
import com.iuims.registrar.scholarship.ScholarEnrollmentService;
import com.iuims.registrar.finance.TermFeeAdminService;
import com.iuims.registrar.core.GlobalTermService;
"""

# Add imports
if "com.iuims.registrar.core.PolicySettings" not in content:
    content = content.replace("package com.iuims.registrar.academic;", "package com.iuims.registrar.academic;\n" + imports_to_add)

# Add AcademicGradingRepository injection & getClassInfoDto
if "AcademicGradingRepository" not in content:
    content = content.replace(
        "@Autowired\n    private JdbcTemplate db;",
        "@Autowired\n    private JdbcTemplate db;\n\n    @Autowired\n    private AcademicGradingRepository academicGradingRepository;\n\n    public ClassInfoDto getClassInfoDto(int scheduleId) {\n        return academicGradingRepository.findClassInfo(scheduleId);\n    }"
    )

# Remove getCurrentGlobalTermCode safely
method_pattern = r"public String getCurrentGlobalTermCode\(\) \{\s*try \{\s*return db\.queryForObject\(\s*\"SELECT param_value FROM sys_parameters WHERE param_name = 'CURRENT_TERM' LIMIT 1\",\s*String\.class\s*\);\s*\} catch \(Exception e\) \{\s*return null;\s*\}\s*\}"
content = re.sub(method_pattern, "", content)

with open(ags_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Fixed AcademicGradingService.")
