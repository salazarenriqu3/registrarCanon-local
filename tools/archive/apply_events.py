import os

base = r"C:\Users\sune\Downloads\projects-20260604T124931Z-3-001\projects\registrar\src\main\java\com\iuims\registrar"
ags_path = os.path.join(base, "academic", "AcademicGradingService.java")
ses_path = os.path.join(base, "scholarship", "ScholarEnrollmentService.java")

with open(ags_path, "r", encoding="utf-8") as f:
    ags = f.read()

# In AGS: Add event publisher and replace closeTermAndForwardBalance
ags = ags.replace("import com.iuims.registrar.core.GlobalTermService;", "import com.iuims.registrar.core.GlobalTermService;\nimport org.springframework.context.ApplicationEventPublisher;\nimport java.util.concurrent.atomic.AtomicInteger;")
ags = ags.replace("@Autowired\n    private AcademicGradingRepository academicGradingRepository;", "@Autowired\n    private AcademicGradingRepository academicGradingRepository;\n\n    @Autowired\n    private ApplicationEventPublisher eventPublisher;")
# Remove ScholarEnrollmentService injection
ags = ags.replace("@Autowired\n    private ScholarEnrollmentService scholarEnrollmentService;", "")
# Replace loop content
old_loop = """            // 3. Process finance & scholarship forwards
            double forwarded = scholarEnrollmentService.closeTermAndForwardBalance(studentNumber);
            if (forwarded >= PolicySettings.accountingBlockThreshold(db)) {
                withForwardedDebt++;
            }"""
new_loop = """            // 3. Process finance & scholarship forwards using Event
            eventPublisher.publishEvent(new TermTransitionEvent(studentNumber, targetDbTermCode, debtCounter));"""
ags = ags.replace(old_loop, new_loop)
# Wrap withForwardedDebt in AtomicInteger
ags = ags.replace("int advanced = 0;\n        int withForwardedDebt = 0;", "int advanced = 0;\n        AtomicInteger debtCounter = new AtomicInteger(0);")
ags = ags.replace("withForwardedDebt, \"\");", "debtCounter.get(), \"\");")

with open(ags_path, "w", encoding="utf-8") as f:
    f.write(ags)

# In SES: Add EventListener
with open(ses_path, "r", encoding="utf-8") as f:
    ses = f.read()

ses = ses.replace("import org.springframework.stereotype.Service;", "import org.springframework.stereotype.Service;\nimport org.springframework.context.event.EventListener;\nimport com.iuims.registrar.academic.TermTransitionEvent;\nimport com.iuims.registrar.core.PolicySettings;")

old_method = """    public double closeTermAndForwardBalance(String studentNumber) {"""
new_method = """    @EventListener
    public void onTermTransition(TermTransitionEvent event) {
        double forwarded = closeTermAndForwardBalance(event.getStudentNumber());
        if (forwarded >= PolicySettings.accountingBlockThreshold(db)) {
            event.getWithForwardedDebtCounter().incrementAndGet();
        }
    }

    public double closeTermAndForwardBalance(String studentNumber) {"""
ses = ses.replace(old_method, new_method)

with open(ses_path, "w", encoding="utf-8") as f:
    f.write(ses)

print("Applied Event based decoupling.")
