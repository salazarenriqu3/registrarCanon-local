import os
import re

files = [
    r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\test\java\com\iuims\registrar\academic\AcademicGradingServiceTermTransitionTest.java",
    r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\test\java\com\iuims\registrar\academic\AcademicGradingServiceGradingWindowTest.java",
    r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\test\java\com\iuims\registrar\academic\GradeOutcomeSemanticsTest.java"
]

for filepath in files:
    if os.path.exists(filepath):
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
        
        # Add Test import to GradeOutcomeSemanticsTest if missing
        if "GradeOutcomeSemanticsTest.java" in filepath:
            if "import org.junit.jupiter.api.Test;" not in content:
                content = "import org.junit.jupiter.api.Test;\n" + content
                
        content = content.replace("new AcademicGradingService()", "new AcademicGradingService(null, null, null, null)")
        content = content.replace("new ScholarEnrollmentService()", "new ScholarEnrollmentService(null, null, null, null, null)")
        content = content.replace("new JaypeeIntegrationService()", "new JaypeeIntegrationService(null, null, null, null, null)")
        
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
        print("Fixed", os.path.basename(filepath))

# StudentCurriculumServiceTest.java
scst_path = r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\test\java\com\iuims\registrar\curriculum\StudentCurriculumServiceTest.java"
if os.path.exists(scst_path):
    with open(scst_path, "r", encoding="utf-8") as f:
        content = f.read()
    if "import org.springframework.test.util.ReflectionTestUtils;" not in content:
        content = "import org.springframework.test.util.ReflectionTestUtils;\n" + content
    if "import static org.assertj.core.api.Assertions.assertThat;" not in content:
        content = "import static org.assertj.core.api.Assertions.assertThat;\n" + content
    with open(scst_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Fixed StudentCurriculumServiceTest.java")

# AcademicGradingServiceTermTransitionTest.java also missing imports
agstt_path = r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\test\java\com\iuims\registrar\academic\AcademicGradingServiceTermTransitionTest.java"
if os.path.exists(agstt_path):
    with open(agstt_path, "r", encoding="utf-8") as f:
        content = f.read()
    if "import org.springframework.test.util.ReflectionTestUtils;" not in content:
        content = "import org.springframework.test.util.ReflectionTestUtils;\n" + content
    if "import static org.assertj.core.api.Assertions.assertThat;" not in content:
        content = "import static org.assertj.core.api.Assertions.assertThat;\n" + content
    with open(agstt_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Fixed AcademicGradingServiceTermTransitionTest.java imports")
