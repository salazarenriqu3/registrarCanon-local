import os
import re

files_to_fix = [
    r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\main\java\com\iuims\registrar\academic\AcademicGradingService.java",
    r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\main\java\com\iuims\registrar\scholarship\ScholarEnrollmentService.java",
    r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\main\java\com\iuims\registrar\admission\FinanceAdmissionService.java",
    r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\main\java\com\iuims\registrar\portal\AcademicController.java",
    r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\main\java\com\iuims\registrar\portal\EnrollmentController.java",
    r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\main\java\com\iuims\registrar\portal\PortalController.java",
    r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\main\java\com\iuims\registrar\portal\ScholarController.java",
    r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\main\java\com\iuims\registrar\jaypee\JaypeeIntegrationService.java"
]

def process_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # If already has @RequiredArgsConstructor, we don't add it.
    if "@RequiredArgsConstructor" not in content:
        # Add @RequiredArgsConstructor to class level annotations
        content = re.sub(r"(public class \w+)", r"@lombok.RequiredArgsConstructor\n\1", content, count=1)
        
    # Replace @Autowired\n private Type field; with private final Type field;
    # (handling optional @Lazy)
    # The regex matches @Autowired (and optional @Lazy) followed by private <type> <name>;
    pattern = r"@Autowired\s+(?:@Lazy\s+)?private\s+([A-Za-z0-9<>_]+)\s+([A-Za-z0-9_]+)\s*;"
    
    # We replace it with private final Type name;
    content = re.sub(pattern, r"private final \1 \2;", content)

    # Some @Autowired may be on the same line: @Autowired private ...
    pattern_same_line = r"@Autowired\s+private\s+([A-Za-z0-9<>_]+)\s+([A-Za-z0-9_]+)\s*;"
    content = re.sub(pattern_same_line, r"private final \1 \2;", content)

    # We also have to handle any non-final fields that were converted if they don't have @Autowired.
    # But wait, Modulith only complained about @Autowired fields.

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

for f in files_to_fix:
    if os.path.exists(f):
        process_file(f)
        print(f"Processed {os.path.basename(f)}")
    else:
        print(f"File not found: {f}")
