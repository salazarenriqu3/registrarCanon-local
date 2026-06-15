# Finance & demo data — unified setup (Jun 2026)

## Code fixes in this revision (rebuild **both** WARs)

| Area | Fix |
|------|-----|
| **Term close** | `forward = prior forward + assessment − SL-scoped payments only` (no legacy cross-term payment fallback at close) |
| **Term close** | Skip re-close when `\|prior forward\| > 0` and assessments already cleared |
| **Balance math** | Total due uses forward **net** (signed); enlist block = net forward debt ≥ PHP 100 |
| **Reconcile** | Registrar counts `PAYMENT + FORWARDED_BALANCE` credits before inserting sync rows |
| **Enlist block** | Block when **net forward debt ≥ PHP 100** — not current-term outstanding |
| **Student Manager Add** | Fixed form POST; flash redirect; ASCII error text (Tomcat strips `₱` in Location header) |

```powershell
cd "<path-to>\enrollment3"
.\mvnw.cmd clean package -DskipTests

.\mvnw.cmd -f "<path-to>\registrar\pom.xml" clean package -DskipTests
```

Copy `registrar-0.0.1-SNAPSHOT.war` → `webapps/registrar.war` and `enrollment.war` → Tomcat. Restart Tomcat.

---

## Fresh finance QA (recommended before demo)

See **`FRESH_FINANCE_DEMO.md`** for the full walkthrough.

| Order | Script |
|-------|--------|
| 1 | `00_finance_demo_reset.sql` |
| 2 | `10_seed_finance_demo_personas.sql` |
| 3 | `11_finance_scenario_checks.sql` |
| 4 | `04_smoke_test_checklist.sql` |

Test students: **2026-0028** (Add), **2026-0027** (forward pay), **2026-0026** (term transition).

---

## Fresh database demo (full BSIT lifecycle)

### One-time on new PC

| # | Script |
|---|--------|
| 1 | `db/fix` |
| 2 | `capss-demo-required/01_setup/01_fresh_demo_bootstrap.sql` |
| 3 | `capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql` |
| 4 | `capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql` |

### Pick a demo student

| Student | Script |
|---------|--------|
| Maria `2026-1001` | `demo_full_lifecycle.sql` |
| Elon `2026-0004` | `demo_elon_2026-0004_fresh.sql` |

### Retest flow (no manual SQL between terms)

1. Cashier → block enlist → pay downpayment via **walk-in** (not raw SQL).
2. Run matching `01_demo_grades_y1s1_*.sql`.
3. Registrar → **term transition**.
4. Repeat — verify cashier and registrar balances match.

### Reset one student only

| Student | Script |
|---------|--------|
| Maria | `00_demo_reset.sql` → `demo_full_lifecycle.sql` |
| Finance personas | `00_finance_demo_reset.sql` → `10_seed_finance_demo_personas.sql` |
| Elon | Delete `2026-0004` rows → `demo_elon_2026-0004_fresh.sql` |

---

## Legacy repair scripts (avoid on fresh DB)

- `fix_elon_2026-0004_finance_step_by_step.sql` / `fix_elon_2026-0002_forward.sql` — corrupted ledger only
- `audit_elon_2026-0004_finance_reconcile.sql` / `audit_elon_2026-0002_finance_reconcile.sql` — read-only audit

---

## Unified rules (after rebuild)

| Data | Source of truth |
|------|-----------------|
| Fee amounts | `program_general_fees` + `program_specific_fees` |
| Assessment debits | Cashier finalize / registrar sync → `TUITION/MISC/OTHER_ASSESSMENT` |
| Payment credits | `payments` + ledger `PAYMENT` (reconcile keeps them equal) |
| Term forward | `FORWARDED_BALANCE` (term-scoped close on transition) |
| Enlist block | Net `FORWARDED_BALANCE` ≥ PHP 100 |
| Student `term_year` | `SL_{sem}{yl}{AYstart}{AYend}` |
| Open term | `system_settings.CURRENT_ACADEMIC_TERM` (calendar `2120252026`, …) |

---

## Verify both apps match

```sql
SET @sn = '2026-0027';
SELECT 'net forward' AS label,
  (SELECT COALESCE(SUM(debit),0)-COALESCE(SUM(credit),0)
   FROM student_ledger WHERE student_id=@sn AND transaction_type='FORWARDED_BALANCE') AS amt
UNION ALL
SELECT 'payments table',
  (SELECT COALESCE(SUM(amount),0) FROM payments WHERE reference_number=@sn AND status='COMPLETED')
UNION ALL
SELECT 'ledger PAYMENT credits',
  (SELECT COALESCE(SUM(credit),0) FROM student_ledger WHERE student_id=@sn
   AND transaction_type IN ('PAYMENT','INITIAL_PAYMENT'));
```

Or run `audit_student_ledger_balance.sql` with `@sn` set.
