import os
import re

ags_path = r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\main\java\com\iuims\registrar\academic\AcademicGradingService.java"

with open(ags_path, "r", encoding="utf-8") as f:
    content = f.read()

# Replace the loop correctly using regex to handle spaces and \r\n
old_loop_pattern = r"double\s+forwarded\s*=\s*scholarEnrollmentService\.closeTermAndForwardBalance\(studentNumber\);\s*if\s*\(forwarded\s*>=\s*PolicySettings\.accountingBlockThreshold\(db\)\)\s*\{\s*withForwardedDebt\+\+;\s*\}"
new_loop = "eventPublisher.publishEvent(new TermTransitionEvent(studentNumber, targetDbTermCode, debtCounter));"
content = re.sub(old_loop_pattern, new_loop, content)

# Fix the final return statement
content = content.replace("return TermTransitionResult.success(advanced, withForwardedDebt);", "return TermTransitionResult.success(advanced, debtCounter.get());")

# Ensure ScholarEnrollmentService injection is completely removed
content = re.sub(r"@Autowired\s+private\s+ScholarEnrollmentService\s+scholarEnrollmentService;", "", content)

# Fix TermTransitionResult constructor/fields if they were broken? No, just success method
# Wait, was TermTransitionResult modified?
# Let's fix line 1362 error "cannot find symbol debtCounter" in TermTransitionResult
# It's probably because I replaced "withForwardedDebt, " -> "debtCounter.get(), " everywhere indiscriminately!
# Let's revert the accidental replacements in TermTransitionResult
content = content.replace("public static TermTransitionResult success(int advanced, int debtCounter.get()", "public static TermTransitionResult success(int advanced, int withForwardedDebt")
content = content.replace("this.debtCounter.get() = debtCounter.get();", "this.withForwardedDebt = withForwardedDebt;")
content = content.replace("public int getDebtCounter.get()()", "public int getWithForwardedDebt()")
# The actual fields:
content = content.replace("private int debtCounter.get();", "private int withForwardedDebt;")

with open(ags_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Fixed AcademicGradingService loop and usages.")
