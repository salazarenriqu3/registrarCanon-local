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

    # Remove @lombok.RequiredArgsConstructor if we added it
    content = content.replace("@lombok.RequiredArgsConstructor\n", "")

    # We need to find all `private final Type field;` inside the class
    # to generate the constructor.
    class_match = re.search(r"public class (\w+)", content)
    if not class_match:
        return
    class_name = class_match.group(1)

    fields = re.findall(r"private final ([A-Za-z0-9<>_]+)\s+([A-Za-z0-9_]+)\s*;", content)
    if not fields:
        # Check if there are still @Autowired fields we missed
        return

    # If there's already a constructor matching the fields, skip
    # (Simplified check)
    if f"public {class_name}(" in content:
        # maybe we already have one
        pass
    
    # Generate the constructor
    constructor_args = ", ".join([f"{t} {n}" for t, n in fields])
    constructor_body = "\n".join([f"        this.{n} = {n};" for t, n in fields])
    
    constructor_code = f"""
    public {class_name}({constructor_args}) {{
{constructor_body}
    }}
"""
    
    # Inject it after the last field or just before the first method.
    # Let's inject right before the first `public ` method or just after the fields.
    # The safest way: find the last `private final Type field;` and insert after.
    last_field_idx = -1
    for match in re.finditer(r"private final [A-Za-z0-9<>_]+\s+[A-Za-z0-9_]+\s*;", content):
        last_field_idx = match.end()
    
    if last_field_idx != -1:
        content = content[:last_field_idx] + "\n" + constructor_code + content[last_field_idx:]

    # For @Lazy dependencies, we might need to add @Lazy to the constructor args, but Spring handles parameter injection if we annotate the constructor with @Autowired if needed (optional since Spring 4.3).

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

for f in files_to_fix:
    if os.path.exists(f):
        process_file(f)
        print(f"Processed {os.path.basename(f)}")
