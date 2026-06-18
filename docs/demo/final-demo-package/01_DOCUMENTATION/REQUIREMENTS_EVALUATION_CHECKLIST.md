# Requirements Evaluation Checklist (40 Items)

Evaluator sheet mapped to implementation evidence.  
Source: *Registrar System Implementation & Evaluation Checklist* (stakeholder interviews).

**Legend:** Pass | Partial | External | Fail | Deferred

**How to use:** Run demo preload SQL, then follow [`DEMO_SCRIPT_SPRINT_FEATURES.md`](DEMO_SCRIPT_SPRINT_FEATURES.md). Mark Status column during evaluation.

---

## 1. Admissions & Program Setup

| Item | Requirement | Status | Evidence / demo path |
|------|-------------|--------|----------------------|
| 1.1 | Pre-registration tagging in admissions | Partial | Admission app; Registrar reads STAGED enlistments |
| 1.2 | 4-step document process | Partial | Admission module; Registrar document trail on records |
| 1.3 | Program create + ACTIVE/INACTIVE | **Pass** | `/admin/programs` — `ProgramService`, `ProgramController` |
| 1.4 | Admissions integration — programs sync | Partial | Shared `programs` table; Admission app consumes |
| 1.5 | Program vs curriculum separation | **Pass** | Separate builders; curriculum staff cannot edit program core file |
| 1.6 | Course LEC/LAB + code lock after save | **Pass** | `/admin/course-catalog` — readonly code on edit |
| 1.7 | Deletion constraints | **Pass** | `ProgramService`, `CourseCatalogService` usage guards |
| 1.8 | Curriculum year assignment per program | **Pass** | Student Profile curriculum assignment |
| 1.9 | Admissions open date config screen | Partial | `ENROLLMENT_OPEN_DATE` on Finance Policy; Admission UI external |

## 2. Cashier, Financials & Enrollment Control

| Item | Requirement | Status | Evidence / demo path |
|------|-------------|--------|----------------------|
| 2.1 | Payment trigger & data lock | Partial | Enrollment/Cashier finalize; Registrar respects COMMITTED enlistments |
| 2.2 | Post-payment changes need Dean approval | **Pass** | Withdrawal + program shift workflows |
| 2.3 | Student number at OR only | External | Cashier / Enrollment app |
| 2.4 | Admitted → Enrolled on student number | **Pass** | `JaypeeIntegrationService` status promotion |
| 2.5 | Finalize enrollment at Cashier only | External | Enrollment app |
| 2.6 | Installment overrides at Cashier | **Pass** | Registrar override ADMIN-only; note on Student Manager |
| 2.7 | Admission fee excluded from assessment | **Pass** | Finance assessment logic |
| 2.8 | Enrollment open/close dates | **Pass** | `/admin/finance-policy` + enlistment block |
| 2.9 | Add/drop/change lock after window | **Pass** | `EnrollmentPeriodPolicy` — enlistment + withdrawal |
| 2.10 | Late enrollment fee automation | Partial | `LATE_ENROLLMENT_FEE_ENABLED` flag; manual Cashier posting |
| 2.11 | Prorated withdrawal 25/50/100% | **Pass** | `WithdrawalService` + `drop_penalty_first_week_percent` |

## 3. Registrar Module & Record Management

| Item | Requirement | Status | Evidence / demo path |
|------|-------------|--------|----------------------|
| 3.1 | Pre-Reg vs Registration Form naming | **Pass** | Dynamic `formTitle` in `print_cor.html` |
| 3.2 | Registration Form after payment + rooms | **Pass** | Downpayment gate on print; schedule shows rooms |
| 3.3 | Portal sync on payment | Partial | Payment sync exists; full auto-COR deferred |
| 3.4 | Old vs new curriculum tracking | **Pass** | Curriculum assignment + historical grades |
| 3.5 | Grade file + COG PDF | **Pass** | Student Profile history; `/admin/print-cog` |
| 3.6 | Editable TOR fields | **Pass** | `/admin/print-tor` form → `print_tor.html` |
| 3.7 | Student Profile restrictions | **Pass** | Terminology + field-level access |
| 3.8 | Registration form lifecycle audit | **Pass** | `RegFormEventService` on COR/COG/TOR print |

## 4. Pre-Registration, Scheduling & Slot Monitoring

| Item | Requirement | Status | Evidence / demo path |
|------|-------------|--------|----------------------|
| 4.1 | Section terminology (not Group) | **Pass** | Templates use Section |
| 4.2 | Term context on scheduling | **Pass** | Term filter on class scheduling |
| 4.3 | UI separation by term | Partial | Term-scoped views; concurrent term encoding possible |
| 4.4 | Delete subject from block | **Pass** | Block panel remove button + `remove-block-course` |
| 4.5 | Course types REG/TUTORIAL/PETITION + fees | Partial | Catalog dropdown + column; petition pricing deferred |
| 4.6 | Pre-reg block rules for new students | Partial | Block sections + Dean paths; Admission-owned flow |
| 4.7 | Section override for irregular | Partial | IRREG-A sections; manual open section |
| 4.8 | Manual section CLOSE | **Pass** | Slot monitoring + scheduling close |
| 4.9 | Slot monitoring dashboard | **Pass** | `/admin/slot-monitoring` — counts, capacity, dissolve, bulk |
| 4.10 | Schedule lock / approval matrix | Partial | Faculty assign DEAN/ADMIN only; full matrix partial |

## 5. Course Modifications (Withdrawal & Program Changes)

| Item | Requirement | Status | Evidence / demo path |
|------|-------------|--------|----------------------|
| 5.1 | WITHDRAW terminology | **Pass** | UI uses Withdraw |
| 5.2 | Withdrawal workflow | **Pass** | Student → Dean → Registrar → reprint |
| 5.3 | Program shift same workflow | **Pass** | `/faculty/program-shifts`, `/admin/program-shifts` |
| 5.4 | Withdrawal reason reports | **Pass** | `/admin/withdrawals/report` |
| 5.5 | Block withdrawal after midterm | **Pass** | `midterm_exam_date` on `academic_term_policies` |

## 6. Grading System

| Item | Requirement | Status | Evidence / demo path |
|------|-------------|--------|----------------------|
| 6.1 | Subject categorization by level | Deferred | Out of scope |
| 6.2 | Grade weighting configuration | **Pass** | `grading_schemes` + Settings UI |
| 6.3 | Encoding periods by term | **Pass** | Grading windows in Settings |
| 6.4 | Registrar super-admin overrides | Partial | Window overrides; per-subject drill-down partial |
| 6.5 | Faculty grading sheet UI | Partial | Faculty `/grades` baseline |
| 6.6 | Automatic computation | Partial | Weighted save in `AcademicGradingService` |
| 6.7 | Change of grade workflow | Partial | Grade change requests exist |

## 7. Scholarships, Deficiencies & Access Control

| Item | Requirement | Status | Evidence / demo path |
|------|-------------|--------|----------------------|
| 7.1 | Dashboard isolation | Partial | Role-based routes; cross-app separation partial |
| 7.2 | Exclude withdrawn from scholarships | **Pass** | `ScholarEnrollmentService` filter |
| 7.3 | Scholarship metrics (low/high grade, units) | Partial | Policy settings; GWA labels updated in config |
| 7.4 | Scholarship roster generation | Partial | Scholarship review workflow |
| 7.5 | Deficiency tagging OSA/Library/Registrar | **Pass** | `student_holds` + Student Manager UI |
| 7.6 | Portal blocks for deficiencies | **Pass** | `PortalController` hold checks |
| 7.7 | RBAC — Registrar grade file vs Dean eval | Partial | Dean evaluation separate; full isolation partial |
| 7.8 | Dean evaluation color checklist | **Pass** | `/dean/student-evaluation` |
| 7.9 | Faculty loading — Dean/Admin only | **Pass** | `SecurityConfig` on assign-faculty |
| 7.10 | Data migration compatibility | Partial | `db/migrations/` + `MIGRATION_SIGNOFF.md`; formal migration project TBD |

---

## Summary scorecard (registrar scope)

| Status | Count (approx.) |
|--------|-----------------|
| **Pass** | 28 |
| **Partial** | 16 |
| **External** | 3 |
| **Deferred** | 1 |

*Some items span multiple modules; External items require Enrollment/Admission/Cashier for full Pass.*

---

## SQL & document index

| Asset | Path |
|-------|------|
| **Storyboard presentation** | `docs/handoff/PRESENTATION_STORYBOARD.md` |
| **Storyboard SQL (one file)** | `db/demo_scripts/STORYBOARD_SQL_ALL_IN_ONE.sql` |
| Storyboard prep runner | `db/demo_scripts/RUN_STORYBOARD_DEMO_PREP.cmd` |
| Fresh bootstrap | `setup/RUN_FRESH_SETUP.cmd` |
| Sprint schema upgrade | `db/migrations/20260619_sprint_1_10_upgrade.sql` |
| Sprint demo seed | `db/demo_scripts/19_sprint_features_demo_seed.sql` |
| Sprint verify SQL | `db/sql_manual/12_verify_sprint_features.sql` |
| Withdrawal UAT seed | `db/demo_scripts/16_withdrawal_uat_seed.sql` |
| Deployment runbook | `docs/handoff/DEPLOYMENT_RUNBOOK.md` |
| Production gates | `docs/handoff/PRODUCTION_GO_LIVE_CHECKLIST.md` |
| Sprint demo script | `docs/handoff/DEMO_SCRIPT_SPRINT_FEATURES.md` |
| Code traceability | `docs/handoff/CHECKLIST_TRACEABILITY.md` |

---

## Evaluator sign-off

```
Evaluator name: _______________________
Date: _______________________
Overall: PASS / PASS WITH CONDITIONS / FAIL

Conditions / follow-up items:


Signature: _______________________
```
