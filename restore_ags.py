import os
import shutil

src_path = r"C:\Users\sune\Downloads\temp_extract\projects\registrar\src\main\java\com\iuims\registrar\service\AcademicGradingService.java"
dst_path = r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\main\java\com\iuims\registrar\academic\AcademicGradingService.java"

with open(src_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Update package
content = content.replace("package com.iuims.registrar.service;", "package com.iuims.registrar.academic;")

# 2. Add required imports
imports = """
import com.iuims.registrar.core.PolicySettings;
import com.iuims.registrar.core.GradeOutcomeSql;
import com.iuims.registrar.scholarship.ScholarEnrollmentService;
import com.iuims.registrar.finance.TermFeeAdminService;
import com.iuims.registrar.core.GlobalTermService;
import com.iuims.registrar.academic.ClassInfoDto;
"""
if "com.iuims.registrar.core.PolicySettings" not in content:
    content = content.replace("package com.iuims.registrar.academic;", "package com.iuims.registrar.academic;\n" + imports)

# 3. Add repository and getClassInfoDto
if "AcademicGradingRepository" not in content:
    content = content.replace(
        "@Autowired\n    private JdbcTemplate db;",
        "@Autowired\n    private JdbcTemplate db;\n\n    @Autowired\n    private AcademicGradingRepository academicGradingRepository;\n\n    public ClassInfoDto getClassInfoDto(int scheduleId) {\n        return academicGradingRepository.findClassInfo(scheduleId);\n    }"
    )

# 4. Replace string getCurrentGlobalTermCode usage (if any in this file)
content = content.replace("AcademicGradingService.getCurrentGlobalTermCode", "GlobalTermService.getCurrentGlobalTermCode")

# 5. Remove getCurrentGlobalTermCode method definition
# We do this carefully with a manual string search to avoid regex truncation bugs.
method_start = "public String getCurrentGlobalTermCode() {"
if method_start in content:
    start_idx = content.find(method_start)
    end_idx = content.find("}", content.find("return null;", start_idx)) + 1
    # also remove any trailing newlines/spaces
    content = content[:start_idx] + content[end_idx:]

with open(dst_path, "w", encoding="utf-8") as f:
    f.write(content)

print(f"Restored and patched. New length: {len(content.splitlines())} lines.")
