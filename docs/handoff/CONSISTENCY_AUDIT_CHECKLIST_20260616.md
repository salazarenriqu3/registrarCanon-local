# Cross-App Consistency Audit Checklist (2026-06-16)

Use this when verifying **registrar-canon** (8083), **admission** (8081), and **enrollment3** (8082) against shared DB `eacdb`.

**Regression student:** `24-1-00001` (Lyncer Contang, ref `26A00002`, BSCPE)

---

## A. Deployment & canon

| # | Check | Expected | How to verify |
|---|--------|----------|---------------|
| A1 | Active registrar is **registrar-canon** | Not legacy `C:\2\newer\new\registrar` | Process cwd / port 8083 |
| A2 | `CURRENT_ACADEMIC_TERM` in `system_settings` | 10-digit code e.g. `1120242025` | `SELECT setting_value FROM system_settings WHERE setting_key='CURRENT_ACADEMIC_TERM'` |
| A3 | All three apps point to **same** `eacdb` | Single source of truth | JDBC URLs in each `application.properties` |

---

## B. Section & course gates (registrar → admission/enrollment)

| # | Check | Expected | Status |
|---|--------|----------|--------|
| B1 | Section status filter | Only `OPEN` / `ACTIVE` (DB stores `Open` → OK) | **Fixed** registrar-canon `JaypeeIntegrationService`; admission `PreRegCurriculumService`; enrollment `RegistrarOfferingGate` |
| B2 | Course on-list | `c.onlist = 1` (or `COALESCE(c.onlist,0)=1`) | **Fixed** registrar grouped offerings + analyzed offerings |
| B3 | Pre-reg snapshot sections match program | BSCPE snapshot → `BSCPE-*-*-*` only | **Fixed** admission `PreRegCurriculumService` program prefix on groups + section query |
| B4 | Capacity counts | COMMITTED enlistments only | **Fixed** admission pre-reg capacity subquery |
| B5 | Re-save pre-reg snapshot for old applicants | Lines use correct block sections | **Manual:** re-download pre-reg PDF for `26A00002` after admission restart |

**SQL — committed load vs snapshot:**

```sql
SELECT cs.section_code, COUNT(*) 
FROM student_enlistments se 
JOIN class_sections cs ON se.section_id = cs.section_id 
WHERE se.student_id = '24-1-00001' AND se.enlistment_status = 'COMMITTED'
GROUP BY cs.section_code;

SELECT c.course_code, cs.section_code 
FROM applicant_pre_reg_subject_lines l
JOIN applicant_pre_reg_snapshots s ON l.snapshot_id = s.id
JOIN class_sections cs ON l.section_id = cs.section_id
JOIN courses c ON l.course_id = c.course_id
WHERE s.reference_number = '26A00002';
```

---

## C. Registration / pre-registration forms

| # | Check | Expected | Status |
|---|--------|----------|--------|
| C1 | Layout matches Admission PDF | EAC header, student box, subject table, fee/payment columns, 2-page rules | **Done** — `fragments/eac_registration_document.html` |
| C2 | Title before payment | **Pre-Registration Form** | registrar `resolveRegistrationFormTitle()`; admission PDF `resolvedDocumentTitle()` |
| C3 | Title after commit | **Registration Form** | Same as C2 when ENROLLED / has student number |
| C4 | Fee line items | Misc/other broken out under headers | **Improved** registrar print via `TermFeeAdminService` |
| C5 | Term on print | Student SL `term_year`, not only global active term | **Fixed** `RegistrationFormPrintService.resolveTermLabel()` |
| C6 | Applicant docs on profile | View + Print; trail events | **Done** — view + print routes; `DOCUMENT_VIEWED` / `DOCUMENT_PRINTED` |

**Manual test:**

1. Registrar → Student Manager → `24-1-00001` → **Print Registration Form**
2. Admission → applicant `26A00002` → **Download pre-reg PDF** (after re-save should show BSCPE sections)
3. Compare titles, subject sections, fee blocks

---

## D. Add Subjects panel (registrar student profile)

| # | Check | Expected | Status |
|---|--------|----------|--------|
| D1 | Panel shows curriculum courses | Not empty when curriculum assigned | **Fixed** — removed invalid `cs.section_status` from course query without join |
| D2 | Closed sections hidden in picker | Per-section subquery uses OPEN/ACTIVE filter | **Fixed** |
| D3 | Already enrolled courses | Shown disabled with "Currently Enrolled" | By design |

---

## E. Auto-enrollment pipeline

| # | Check | Expected | Status |
|---|--------|----------|--------|
| E1 | Pre-reg walk-in SQL | No invalid column `sort_order` | **Fixed** enrollment `AdmissionPreRegWalkinService` |
| E2 | Finalize with 0 subjects | Must not mark ENROLLED | **Fixed** `PreRegEnrollmentFinalizeService` |
| E3 | Regular block sections | `BlockSectionResolver` program prefix | **Fixed** enrollment |
| E4 | Terminal block table when FINALIZED | Shows actual committed enlistments | **Fixed** `EnlistmentTerminalService` |
| E5 | Schedule registrar vs enrollment | Same section codes | **Fixed** for `24-1-00001` (DB repair + resolver) |

---

## F. Document trail

| # | Check | Expected | Status |
|---|--------|----------|--------|
| F1 | Admission upload/verify events | In `application_logs` | Admission owns |
| F2 | Registrar reads trail | `StudentDocumentTrailService` includes `application_logs` | **Done** |
| F3 | Registrar doc view/print | Events in trail | **Done** |
| F4 | Pre-reg PDF download audit | Logged in Admission | **Open** — not yet audited on download |

---

## G. Known open items (lower priority)

| Item | Notes |
|------|--------|
| Dual pre-reg snapshot schema | Admission PK `id` vs registrar `snapshot_id`; bridged by compat SQL |
| `enrollment_type` on ADMISSION snapshot | May default IRREGULAR; cosmetic for regular flow |
| Admission document **release** workflow | Not in registrar/enrollment |
| Legacy `registrar/` tree | Do not deploy; missing several canon fixes |
| Irregular finalize | Still trusts registrar snapshot `section_id`s — must be correct at source |

---

## H. Restart & smoke test order

```powershell
cd "C:\2\newer\new\registrar-canon"; mvn spring-boot:run
cd "C:\New folder\admission"; mvn spring-boot:run
cd "C:\New folder\enrollment3"; mvn spring-boot:run
```

1. Registrar: search `24-1-00001` — load visible, Add Subjects populated, print reg form, print applicant doc
2. Enrollment: cashier terminal — block subjects match registrar schedules
3. Admission: pre-reg PDF for `26A00002` — BSCPE sections only; title **Registration Form** if enrolled

---

## Fixes applied in this pass (2026-06-16)

- registrar-canon: section gate whitelist OPEN/ACTIVE; strict `onlist`; reg form term from SL; fee line items
- admission: pre-reg section queries require `{program}-*` prefix; committed-only capacity; dynamic PDF title
- Checklist document (this file)
