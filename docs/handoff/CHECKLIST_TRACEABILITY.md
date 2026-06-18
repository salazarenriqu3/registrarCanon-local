# Checklist Traceability (Items 1.1–7.10)

Sprint completion status for evaluator checklist items. **Sprint 1–2** were completed prior to this pass.

| Item | Requirement (summary) | Sprint | Status | Notes |
|------|----------------------|--------|--------|-------|
| **1. Admissions & Program Setup** |
| 1.1 | Pre-registration tagging in admissions | 1–2 | Done | Prior sprint |
| 1.2 | 4-step document process | 1–2 | Done | Prior sprint |
| 1.3 | Program create + ACTIVE/INACTIVE | 1–2 | Done | Prior sprint |
| 1.4 | Admissions integration | 1–2 | Partial | External Admission app |
| 1.5 | Program vs curriculum separation | 1–2 | Done | Prior sprint |
| 1.6 | Course LEC/LAB + code lock | 1–2 | Done | Prior sprint |
| 1.7 | Deletion constraints | 1–2 | Done | Prior sprint |
| 1.8 | Curriculum year assignment | 1–2 | Done | Prior sprint |
| 1.9 | Admissions open date config | 8 | Partial | `ENROLLMENT_OPEN_DATE` on Finance Policy; admissions-specific UI deferred |
| **2. Cashier, Financials & Enrollment** |
| 2.1 | Payment trigger / data lock | 1–2 | Partial | Enrollment finalize in Cashier app |
| 2.2 | Post-payment Dean approval | 4 | Done | Program shift + withdrawal workflows |
| 2.3 | Student number at OR | 1–2 | External | Cashier system |
| 2.4 | Admitted → Enrolled escalation | 1–2 | Done | Prior sprint |
| 2.5 | Finalize at Cashier only | 1–2 | External | Enrollment app |
| 2.6 | Installment overrides at Cashier | 8 | Done | Registrar override ADMIN-only; template note |
| 2.7 | Admission fee excluded | 1–2 | Done | Prior sprint |
| 2.8 | Enrollment open/close dates | 8 | Done | Finance Policy + enlistment block |
| 2.9 | Add/drop close window | 8 | Done | `ADD_DROP_CLOSE_DATE` enforced on enlistment changes and withdrawal requests |
| 2.10 | Late enrollment fee | 8 | Partial | Flag stored; fee posting deferred |
| 2.11 | Prorated withdrawal 25/50/100% | 4 | Done | `drop_penalty_first_week_percent` + tiers |
| **3. Registrar Module & Records** |
| 3.1 | Pre-Reg vs Registration Form title | 3 | Done | Dynamic `formTitle` |
| 3.2 | COR after payment + rooms | 3 | Done | Downpayment gate on print |
| 3.3 | Portal sync on payment | 1–2 | Partial | Payment sync exists; full auto-COR deferred |
| 3.4 | Old vs new curriculum | 1–2 | Done | Prior sprint |
| 3.5 | Grade file + COG | 3 | Done | print-cog + events |
| 3.6 | Editable TOR fields | 3 | Done | GET/POST print-tor form |
| 3.7 | Student Profile restrictions | 1–2 | Done | Prior sprint |
| 3.8 | Reg form lifecycle tracking | 3 | Done | `RegFormEventService` on print |
| **4. Pre-Registration & Scheduling** |
| 4.1 | Section terminology | 1–2 | Done | Prior sprint |
| 4.2 | Term context on scheduling | 1–2 | Done | Prior sprint |
| 4.3 | UI separation by term | 1–2 | Partial | |
| 4.4 | Block delete subject | 1–2 | Done | Prior sprint |
| 4.5 | Course types REG/TUTORIAL/PETITION | 9 | Partial | Catalog + column; petition pricing hint only |
| 4.6 | Pre-reg block rules | 1–2 | Partial | Dean/block paths exist |
| 4.7 | Section override for irregular | 1–2 | Partial | |
| 4.8 | Manual section CLOSE | 1–2 | Done | Prior sprint |
| 4.9 | Slot monitoring dashboard | 1–2 | Done | Prior sprint |
| 4.10 | Schedule lock matrix | 7 | Partial | Faculty assign DEAN/ADMIN only |
| **5. Withdrawal & Program Changes** |
| 5.1 | WITHDRAW terminology | 1–2 | Done | Prior sprint |
| 5.2 | Withdrawal workflow | 1–2 | Done | Prior sprint |
| 5.3 | Program shift workflow | 4 | Done | Dean → Registrar queues |
| 5.4 | Withdrawal reason reports | 1–2 | Done | Prior sprint |
| 5.5 | Midterm withdrawal deadline | 4 | Done | `midterm_exam_date` policy |
| **6. Grading** |
| 6.1 | Subject categorization by level | 5 | Deferred | Not in scope |
| 6.2 | Grade weighting config | 5 | Done | `grading_schemes` + Settings |
| 6.3 | Encoding periods | 1–2 | Done | Prior sprint |
| 6.4 | Registrar overrides | 1–2 | Partial | Window overrides exist |
| 6.5–6.10 | Faculty encoding / approvals | 1–2 | Partial | Prior sprint baseline |
| **7. Scholarships & Holds** |
| 7.1–7.5 | Scholarship workflow | 1–2, 6 | Partial | Candidates exclude withdrawn; holds table |
| 7.6–7.10 | Portal blocks / RBAC | 6–7 | Done | Holds block portal; Dean evaluation |

## Sprint summary

| Sprint | Theme | Status |
|--------|-------|--------|
| 3 | Registration forms & documents | Complete |
| 4 | Withdrawal & program shift governance | Complete |
| 5 | Grading configuration | Complete (default scheme) |
| 6 | Scholarships & holds | Complete |
| 7 | Dean evaluation & RBAC | Complete |
| 8 | Enrollment periods | Complete |
| 9 | Course types | Complete (petition pricing logic deferred) |
| 10 | Docs & CI | Complete |

## Deferred / follow-up

- Full petition course conditional pricing engine
- Late enrollment fee ledger posting when flag enabled
- Per-program grading scheme UI (DB supports nullable `program_code`)
- Admissions-module open date screen (registrar stores dates only)
