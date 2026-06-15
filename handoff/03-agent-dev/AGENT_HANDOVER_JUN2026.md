# CAPSS Agent Handover — Finance, Forward Balance & Enrollment (Jun 2026)

**Purpose:** Onboard a new agent on the **current state** of the EAC CAPSS stack after multiple finance/enrollment sprints (through **1 Jun 2026**).  
**Audience:** Cursor agent or developer continuing billing, term-close, staging, and demo work.

**Canonical ops guide:** `../02-panel-demo/CAPSS_Deployment_and_Demo_Manual.md`  
**Demo SQL order:** `../05-demo-guides/README_DEMO_SQL.md`  
**Prior chat transcript:** agent transcript `7c0f4169-39f5-4957-9fb1-ca998d5ea165` (finance forward / drop / staging thread)

---

## 1. Workspace layout

| Path | Role |
|------|------|
| `c:\Users\admin\Downloads\registrar1\registrar` | Registrar WAR — term transition, Student Manager, grading, `ScholarEnrollmentService` |
| `c:\Users\admin\Desktop\May 26, 2026 Systems\enrollment3` | Enrollment/cashier WAR — enlist, pay, ledger UI, `FinancialService` |
| `c:\Users\admin\Desktop\Admission System Deployment\AdmissionEAC` | Admission portal (often same codebase family as enrollment) |

All three apps share **`eacdb`** on MySQL `localhost:3306`. Deploy to Tomcat **8080** as `admission.war`, `enrollment.war`, `registrar.war`.

---

## 2. Executive summary — where we are

### Done (structural, in source — requires **rebuilt WARs** on Tomcat)

- **Term close** rolls **net** forward using **SL-tagged payments only** (`closeTermAndForwardBalance` in enrollment + registrar).
- **Total due / outstanding / drop refund** use **forward net** (`debit − credit` on `FORWARDED_BALANCE`), **not** gross debits.
- **Drop/refund** unified: real overpayment only; penalty from `enrollment_settings`; no hardcoded ₱1,500 / 7-day rules in admin bulk drop.
- **Staging vs committed:** irreg/cashier staging must **not** show as enrolled on registrar until **Finalize**; both apps filter `student_enlistments.enlistment_status`.
- **Enlist block:** prior-term forwarded **debt** ≥ ₱100 (net), not current-term tuition.

### Working on fresh demo path (no hotfix SQL)

Fresh CAPSS flow: `db/fix` → bootstrap → align → fees → demo seed → **rebuild both WARs** → UI enroll/pay/finalize/term advance.  
Hotfix SQL scripts are **legacy data repair only** — **not** required for new students.

### Still broken / next sprint

**Historical ledger vs term-close mismatch** (confirmed on fresh student **John Doe `2026-0006`**):

- At term close, ledger `fwd_net` can be **credit** (e.g. **−₱4,449**) while historical term view recomputes **higher** fees and shows balance **₱0** instead of owed/credit.
- **Root cause:** close freezes one assessment; `getStudentLedgerHistoryForViewTerm()` **recomputes** fees from current enlistments/grades after advance.
- **Planned fix:** `student_term_closes` snapshot table + historical ledger reads snapshot; unify payment sum for list vs balance; INFO logging at close. See **§8**.

---

## 3. Agreed billing rules (source of truth)

| Rule | Behavior |
|------|----------|
| Before finalize | Ledger = **payments only**; staging assess must not block enlist |
| After finalize | `commitTermAssessment()` / `finalizeTermAssessment()` posts official debits |
| FORWARDED | **Prior terms only**; never same-term drop adjustments as forward |
| Term close | Single place: `priorForward + assess + orphan − scholar − **strict SL payments**` → one `FORWARDED_BALANCE` row; delete term assess rows |
| Total due | `currentTermFees + forwardNet` (signed; negative forward = credit) |
| Drop REFUND | Only when payments exceed post-drop amount still owed |
| Enlist block | `forwardNet ≥ ₱100` **debt** (positive), not gross forward |
| Payments | Cashier sets `payments.term_year = SL_*`; term close uses **strict SL** only |

---

## 4. Work completed — earlier sprints (structural)

### 4.1 Term transition & ledger (≈ Rev 28 May 2026)

- Registrar `triggerTermTransition()` **no longer deletes** `PAYMENT` rows or all `student_enlistments`.
- Per-student close via `ScholarEnrollmentService.closeTermAndForwardBalance()` before advancing `term_year`.
- Orphan prior-term assess handled at close with `computeOrphanAssessNet()` (SL-scoped prior payments).
- `student_id` on ledger/enlistments = **VARCHAR student_number** (not `user_id` INT).

### 4.2 Drop / refund unification (enrollment + registrar)

| Area | Change |
|------|--------|
| Enrollment | `EnrollmentIntegrationService.dropSubjectByEnlistmentId()` → `FinancialService.processSubjectDrop()` |
| Registrar | `ScholarEnrollmentService.processSubjectDrop()`; `JaypeeIntegrationService` delegates here |
| Admin bulk drop | `AdminController` wired to unified path; removed hardcoded penalty/refund |
| Sync assess | `syncCoreLedgerAssessment` DELETE limited to assessment debit types — preserves `REFUND`, `DROP_PENALTY` |
| Removed | `absorbUnclearedPriorAssessBeforeReplace` from drop/resync paths |

### 4.3 Staging vs committed (irreg regression fix)

- **Registrar:** new `EnlistmentSchemaService` — `STAGED` / `COMMITTED_ONLY` filters on `student_enlistments.enlistment_status`.
- Student Manager load, fee assessment, add/drop visibility = **COMMITTED only**.
- **Enrollment:** staged irreg table = **STAGED only**; only **Finalize** commits.

### 4.4 Fee model

- Single model: `program_general_fees` + `program_specific_fees` (not legacy `program_fee_rates` unless `use-program-fee-rates=true`).
- Admin `/admin/term-fees` edits same tables in both apps.

---

## 5. Work completed — 1 Jun 2026 session (forward net totals)

### Problem

UI **TOTAL FEES** used **forward gross debits** while FORWARDED column showed **net**. After paying toward forward, `fwd_gross = fwd_credits`, `fwd_net = 0`, but totals still inflated (e.g. Zuckerberg **₱80k** total, **₱52k** balance).

### Fix — use signed forward net everywhere in total-due math

**Enrollment** `FinancialService.java`:

- Added `forwardComponentForTotalDue()` → `getBalanceForwarded()` (net).
- Updated: `getStudentLedgerHistoryForViewTerm`, `populateLedgerFinancialData`, `populateStudentFinancialData`, `getOutstandingBalance`, `computeDropRefundCredit`.
- `getBalanceForwardedGrossDebit()` retained for **audit/debug only** (do not use in totals).

**Registrar:**

- `ScholarEnrollmentService.getOutstandingBalanceNet()` — forward net.
- `ScholarEnrollmentService.computeDropRefundCredit()` — forward net.
- `FinanceAdmissionService.calculateAssessment()` — `totalAssessment = termFees + balanceForwarded` (net).

### SQL added (optional — legacy repair / audit only)

| Script | Purpose |
|--------|---------|
| `audit_zuckerberg_2026-0005_finance_reconcile.sql` | Read-only audit |
| `fix_zuckerberg_2026-0005_forward.sql` | Repair corrupted forward (skip on fresh DB) |
| `audit_student_ledger_balance.sql` | Updated with `fwd_gross / fwd_credits / fwd_net` query |

**User decision:** Skip hotfix SQL when running fresh CAPSS demo; redeploy WARs instead.

### Docs status

- `FRESH_FINANCE_DEMO.md` now says total uses signed forward **net**.

---

## 6. Key files reference

### Enrollment (`enrollment3`)

| File | Responsibility |
|------|----------------|
| `service/FinancialService.java` | Cashier totals, ledger history, close, pay, drop refund |
| `service/TermAssessmentService.java` | Fee computation per term / view term |
| `service/EnlistmentSchemaService.java` | STAGED vs COMMITTED filters |
| `service/EnlistmentTerminalService.java` | Finalize → commit assess |
| `service/EnrollmentIntegrationService.java` | Drop orchestration |
| `controller/EnrollmentController.java` | Term advance → `closeTermAndForwardBalance` before apply |
| `controller/AdminController.java` | Cashier, ledger view, bulk drop |
| `templates/admin_ledger.html` | Official ledger breakdown UI |

### Registrar

| File | Responsibility |
|------|----------------|
| `service/ScholarEnrollmentService.java` | Term close, forward, drop, outstanding |
| `service/FinanceAdmissionService.java` | Admission pay, assessment map |
| `service/AcademicGradingService.java` | `triggerTermTransition()` → close per student |
| `service/EnlistmentSchemaService.java` | COMMITTED filter for Student Manager |
| `service/JaypeeIntegrationService.java` | Cross-system drop delegate |
| `controller/EnrollmentController.java` | Student Manager |

### Demo / DB

| File | Notes |
|------|-------|
| `db/fix` | Full schema once per machine |
| `db/capss-demo-required/01_setup/01_fresh_demo_bootstrap.sql` | Calendar terms |
| `db/capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql` | BSIT sections |
| `db/capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql` | **Required** fees |
| `db/capss-demo-required/02_demo_seed_pick_one/demo_full_lifecycle.sql` | Maria `2026-1001` |
| `db/capss-demo-required/02_demo_seed_pick_one/demo_elon_2026-0004_fresh.sql` | Clean Elon seed |
| `db/demo_scripts/00_finance_demo_reset.sql` + `10_seed_finance_demo_personas.sql` | Finance QA personas 0026–0028 |
| `fix_elon_*`, `fix_zuckerberg_*`, `fix_spurious_*` | **Legacy repair only** |

---

## 7. Term close formula (both apps)

```text
priorForward     = getBalanceForwarded()           // net
assessCharges    = computeForViewTerm / computeCurrentTermFees (committed load)
orphanNet        = uncleared prior-term assess − prior SL payments (if any)
termPayments     = sumPaymentsForTermCloseStrict(sl)  // SL_* only, no legacy fallback
discount         = scholar discount on assess
forwardResult    = priorForward + orphanNet + assessCharges − discount − termPayments

if forwardResult > 0  → FORWARDED_BALANCE debit
if forwardResult < 0  → FORWARDED_BALANCE credit (overpayment carried)
DELETE assess rows + prior FORWARDED rows; insert single new FORWARDED row
```

Walk-in pay (`applyWalkInPayment`): credit **FORWARDED first**, remainder → `PAYMENT`.

---

## 8. Next sprint — planned work (not implemented yet)

### Phase 1 — `student_term_closes` snapshot

Create table (shared `eacdb`):

```sql
student_id, closing_sl, term_id,
assess_total, term_payments, scholar_discount,
prior_forward, forward_net, term_balance,  -- signed
closed_at
```

Write on:

- `FinancialService.closeTermAndForwardBalance()`
- `ScholarEnrollmentService.closeTermAndForwardBalance()`

Add **INFO** log line per close with all inputs/outputs.

### Phase 2 — Historical ledger

In `getStudentLedgerHistoryForViewTerm()`:

- If snapshot exists for `viewTermSl` → use frozen assess + signed term balance.
- Do **not** clamp historical balance to 0 when underpaid/overpaid.
- Show **Other fees** column so tuition+lec+misc+other = total.

### Phase 3 — Payment attribution

Single helper for payment list **and** balance sum:

- Strict SL sum when any SL-tagged payments exist.
- Legacy untagged match only when no SL tags.

### Phase 4 — QA

Fresh student: partial pay Y2 S1 → finalize → registrar term transition → verify snapshot row matches `fwd_net` and historical view.

---

## 9. Case studies (for debugging)

### Zuckerberg `2026-0005` (legacy corrupted data)

- Symptom: `fwd_gross = fwd_credits ≈ 27246.67`, `fwd_net = 0`, but UI total still huge on **old WAR**.
- Expected forward ~**₱7,294.67** debt (Y1 overpay −5932 + Y1 S2 debt +13226.67).
- Fix: redeploy + optional `fix_zuckerberg_2026-0005_forward.sql` **or** fresh reset.

### John Doe `2026-0006` (fresh student — **active bug**)

- Y2 S1: fees **₱32,006**, payments **₱26,455** visible → should owe **₱5,551**; UI showed **₱0**.
- After term advance: SQL `fwd_net = **−4449**` (credit forward) — close used **lower** assess than historical recompute.
- Y2 S2 current term: forward **−4449** in total, balance **₱38,070** = **₱40,070 − ₱2,000** (current-term math OK).
- Tomcat logs (1 Jun 2026): clean deploy, payments insert with `term_year`; **no close audit logs** (not implemented).

### Finance personas (optional QA)

| ID | Test |
|----|------|
| `2026-0027` | Forward ₱100 → pay ₱1 → net ₱99 |
| `2026-0026` | Term transition → forward debt ~₱53,074 |
| `2026-0028` | Student Manager Add (no blank page) |

---

## 10. Deploy & verify checklist

```text
[ ] db/fix (once) + demo bootstrap scripts per CAPSS manual
[ ] mvn package enrollment3 → enrollment.war
[ ] mvn package registrar → registrar.war
[ ] Deploy to Tomcat webapps; restart
[ ] Fresh student OR finance personas — NOT legacy 0002/0005 without reset
[ ] Skip all fix_*.sql on fresh path
[ ] Optional: audit_student_ledger_balance.sql (read-only)
```

**Enrollment compile:** `enrollment3/mvnw.cmd -DskipTests compile` (verified Jun 2026).  
**Registrar:** use local Maven if `mvnw` absent.

**Runtime notes from logs:**

- JDK 25 on Tomcat 10.1.54 works; Hibernate warns MySQL dialect 5.5.5 (MariaDB compat).
- No finance errors in startup; need explicit close logging (next sprint).

---

## 11. Known UI / display gaps (non-blockers)

- Historical term balance uses `Math.max(0, …)` — hides mid-term **overpayment credit** until term close.
- Ledger breakdown omits **Other fees** column; `totalAssessment` includes other → column sum ≠ total.
- Misc itemized list can drift ~₱10–84 from misc total (fee tier rounding).
- `getStudentLedgerHistory()` (non-view-term) still puts `getOutstandingBalance(student)` in BALANCE for some rows — view-term path is correct for ledger page dropdown.

---

## 12. What NOT to do

- Do **not** run `fix_elon_*` / `fix_zuckerberg_*` on a **fresh** CAPSS demo DB.
- Do **not** use `getBalanceForwardedGrossDebit()` / `getForwardedBalanceGrossDebit()` in total-due math.
- Do **not** reintroduce `absorbUnclearedPriorAssessBeforeReplace` on drop/sync.
- Do **not** count lifetime ledger credits at term close — **SL-scoped payments only**.
- Do **not** treat staged irreg enlistments as enrolled on registrar.

---

## 13. Glossary

| Term | Meaning |
|------|---------|
| `SL_1220252026` | Student term_year (Y2 S1 A.Y. 2025–2026) |
| `1120252026` | Calendar `academic_terms.term_code` |
| `forwardNet` | `SUM(FORWARDED debits) − SUM(FORWARDED credits)`; negative = credit |
| `forwardGross` | Debits only — audit; was wrongly used in totals before 1 Jun fix |
| STAGED / COMMITTED | `student_enlistments.enlistment_status` — preview vs official |
| Strict SL payments | `payments.term_year = closing SL_*` only |

---

## 14. Handoff questions for next agent

1. Implement **`student_term_closes`** + historical ledger read path (§8).
2. Update **`FRESH_FINANCE_DEMO.md`** gross → net wording.
3. Retest **John Doe pattern** on fresh student after redeploy.
4. Confirm registrar WAR on Tomcat includes **`ScholarEnrollmentService` forwardNet** changes (same commit as enrollment).
5. Optional: expose signed balance / overpay on historical ledger UI.

---

*Last updated: 1 Jun 2026 — finance forward-net sprint + John Doe historical-ledger investigation.*
