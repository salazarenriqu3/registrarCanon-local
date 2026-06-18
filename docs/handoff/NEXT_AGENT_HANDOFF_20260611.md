# Next Agent Handoff — 2026-06-11 (Bundle 61126)

**Canonical project root:** `C:\Users\sune\Downloads\new-20260606T044759Z-3-001\new` (zip workspace) · live mirror `C:\Users\sune\Downloads\new`  
**Bundle:** `61126/` — portable docs + setup reference (snapshot after curriculum + Registrar overpayment work)

---

## Executive summary

| Feature | Registrar (8083) | Enrollment (8082) | Human UAT |
|---------|------------------|-------------------|-----------|
| **Explicit curriculum assignment** (C1–C4) | **Done** | **Done** | **Pending** — RET-CURR-01–04 |
| **Overpayment pending → disposition** | **Done** (phase 1) | **Not started** | **Pending** — OPAY + BAL-T04 on Enrollment |
| Core demo / stabilization | Done | Done | Sessions 0–B largely positive; C–F open |

User is **pausing for now**; next session = **more testing** (RET-CURR browser UAT, remaining Sessions C–F).

---

## What was implemented this session

### Curriculum assignment (both apps)

- Registrar **Assign Curriculum** card + `POST /admin/student-manager/assign-curriculum`
- Removed silent **`LEGACY_BACKFILL`** auto-insert; read assignment only unless staff/admission assigns
- Enrollment: no active-catalog fallback; cashier/enlist **block** when unassigned; block path uses assigned `curriculum_id`
- Demo SQL: `registrar/db/demo_scripts/demo_returning_student_old_curriculum.sql`
- Tests: `StudentCurriculumServiceTest`, `EnrollmentIntegrationServiceCurriculumTest`, live smoke `RetCurrLiveSmokeTest`
- UAT seed (optional): `mvn test -Dtest=RetCurrUatSeedTest` in `enrollment3/` → students `2026-RET-UNASS`, `2026-RET-LEGACY`

**Docs:** `curriculum/PROPOSAL_*.md`, `curriculum/IMPLEMENTATION_PLAN_*.md` (status updated to **implemented**)

### Registrar overpayment (phase 1 — prior session, included in bundle)

- Term close overpay → `PENDING_TERM_CREDIT` (not auto credit forward)
- Student Manager disposition UI + enrollment hub gate
- SQL: `registrar/db/demo_scripts/13_student_overpay_dispositions.sql`

**Enrollment overpayment** still per `overpayment/IMPLEMENTATION_PLAN_OVERPAYMENT_ENROLLMENT.md`.

### Build / runtime notes

- Fixed `EnrollmentSettingsService` gap (`accountingBlockThreshold`, `admissionMinPayment`, `getInstallmentPlan(termId, studentNumber)`) so Enrollment compiles
- **Port conflicts:** if Eclipse fails with “8083 already in use”, run `netstat -ano | findstr ":8083"` then `taskkill /PID <pid> /F` (same for `:8082`)
- Prefer **one** Registrar + **one** Enrollment instance (Eclipse *or* `mvn spring-boot:run`, not both)

---

## RET-CURR quick UAT (when user returns)

| ID | Steps | Pass when |
|----|-------|-----------|
| **RET-CURR-01** | Student Manager → assign legacy/old catalog to returning student (`2026-RET-LEGACY` or manual) | Irregular offerings follow **assigned** catalog |
| **RET-CURR-02** | Cashier `?keyword=2026-RET-UNASS` (no assignment) | Warning banner; finalize blocked → assign in Registrar → unblock |
| **RET-CURR-03** | Change program active default; student with old assignment | Assignment row **unchanged** |
| **RET-CURR-04** | Regular block on student with old assigned catalog | Section groups from **assigned** template, not `is_active=1` only |

**URLs**

- Registrar Student Manager: http://localhost:8083/registrar/admin/student-manager?username=2026-RET-UNASS
- Cashier: http://localhost:8082/admin/cashier?keyword=2026-RET-UNASS
- Login: `admin` / `1234`

---

## Read order for next agent

1. **`docs/handoff/PROJECT_STATUS_AND_ROADMAP.md`**
2. **`docs/handoff/HANDOFF_UPDATES_20260609.md`** — §16–§21
3. **`docs/handoff/HUMAN_UAT_CHECKLIST.md`** — RET-CURR + Sessions C–F
4. **`curriculum/IMPLEMENTATION_PLAN_CURRICULUM_ASSIGNMENT.md`** — implementation record
5. **`overpayment/IMPLEMENTATION_PLAN_OVERPAYMENT_ENROLLMENT.md`** — if user asks for Enrollment overpay

---

## Pending (do not start without user ask)

| Item | Doc |
|------|-----|
| Enrollment overpayment phase | `overpayment/IMPLEMENTATION_PLAN_OVERPAYMENT_ENROLLMENT.md` |
| Registrar Spring Security | `docs/handoff/PROPOSAL_REGISTRAR_SPRING_SECURITY.md` |
| Full Sessions C–F sign-off | `HUMAN_UAT_CHECKLIST.md` |
| Handoff doc sync to `C:\Users\sune\Downloads\new\registrar\docs\handoff` | Manual if roots diverge |

---

## Key files changed (code)

### Registrar

- `curriculum/StudentCurriculumService.java`
- `portal/EnrollmentController.java`
- `jaypee/JaypeeIntegrationService.java`
- `curriculum/CreditGradeService.java`
- `scholarship/ScholarEnrollmentService.java`
- `resources/templates/admin_student_manager.html`
- `finance/OverpayDispositionService.java`, `scholarship/ScholarEnrollmentService.java` (overpay)
- `db/demo_scripts/demo_returning_student_old_curriculum.sql`

### Enrollment

- `service/EnrollmentIntegrationService.java`
- `service/EnlistmentTerminalService.java`
- `service/EnrollmentSettingsService.java`
- `controller/AdminController.java`
- `resources/templates/admin_payment.html`, `admin-enlistment.html`

---

*End of handoff 61126.*
