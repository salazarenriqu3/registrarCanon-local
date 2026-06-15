# Fresh Finance Demo — Jun 2026

Step-by-step guide for a **clean billing QA run** after the forward-balance, Student Manager, and term-close fixes.

**Database:** `eacdb` · **Apps:** Tomcat 8080 — `/enrollment`, `/registrar`, `/admission`

---

## 0. Prerequisites (once per machine)

| Step | Action |
|------|--------|
| 1 | Run `db/fix` (full schema) |
| 2 | `capss-demo-required/01_setup/01_fresh_demo_bootstrap.sql` |
| 3 | `capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql` |
| 4 | `capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql` |
| 5 | Rebuild & deploy **both** WARs (see `FINANCE_FIX_STEPS.md`) |
| 6 | Restart Tomcat |

Staff logins: `admin / 1234` (registrar & enrollment)

---

## 1. Reset & seed finance personas

Run in MySQL Workbench (**Execute All**):

```
00_finance_demo_reset.sql
10_seed_finance_demo_personas.sql
11_finance_scenario_checks.sql    -- baseline (before UI steps)
04_smoke_test_checklist.sql       -- system-wide sanity
```

### Seeded students (password `1234`)

| ID | Name | Purpose | Starting state |
|----|------|---------|----------------|
| **2026-0028** | Juan Dela Cruz | Student Manager **Add** button | Y2 S2, ENROLLED, 1 subject, **no forward** |
| **2026-0027** | John Doe | Forward **pay PHP 1 → net PHP 99** | Y2 S2, ENROLLED, **forward debt PHP 100** |
| **2026-0026** | Jane TermTest | **Term transition** forward debt | Y1 S2, fees **56074**, paid **3000** |

Open registrar term after seed: **A.Y. 2025-2026 2nd Sem** (`2120252026` / `SL_2220252026`).

---

## 2. Billing rules (what “correct” looks like)

| Rule | Expected behavior |
|------|-------------------|
| Before finalize | Ledger = payment credits only; no staging assessment debits block enlist |
| After finalize | Official debits posted; current-term balance alone does **not** block enlist |
| Enlist block | **Prior-term forwarded debt ≥ PHP 100** only |
| Term close | `forward = prior forward + term assessment − term payments (SL only)` |
| Balance display | Total uses forward **net** (signed); FORWARDED column shows **net** |
| Student Manager Add | Redirects back with message — **never** blank page |

---

## 3. Test scenarios

### A — Student Manager Add (2026-0028)

1. Registrar → **Student Manager** → search `2026-0028`
2. **Add Subjects** → choose section → **Add**
3. **Pass:** returns to Student Manager (success or red error alert)
4. **Fail:** blank page at `/registrar/admin/enroll` → stale WAR; redeploy registrar

Re-run `11_finance_scenario_checks.sql` block **A**.

---

### B — Forward payment (2026-0027)

1. Enrollment → **Cashier** → load `2026-0027`
2. Confirm **Balance Forwarded** shows **PHP 100.00**
3. Post **PHP 1.00** payment (walk-in or terminal)
4. **Pass:** net forward **PHP 99.00** (not 98)
5. Registrar Student Manager load → **no** new `Synced from enrollment payments` row

Re-run `11_finance_scenario_checks.sql` block **B**.

---

### C — Term transition (2026-0026)

1. In Workbench, set open term to Y1 S2 for this test only:

```sql
UPDATE system_settings SET setting_value = '2120242025' WHERE setting_key = 'CURRENT_ACADEMIC_TERM';
UPDATE academic_terms SET is_active = 0;
UPDATE academic_terms SET is_active = 1 WHERE term_code = '2120242025';
```

2. Registrar → **System Settings** → term transition to **Y2 S1** (`1120252026`)
3. **Pass:** Jane’s net FORWARDED ≈ **PHP 53,074** (debt), **not** a spurious credit (~23k)
4. **Fail:** large negative FORWARDED → re-run `00_finance_demo_reset.sql` + seed; confirm latest WARs

Re-run `11_finance_scenario_checks.sql` block **C**, then restore open term:

```sql
UPDATE system_settings SET setting_value = '2120252026' WHERE setting_key = 'CURRENT_ACADEMIC_TERM';
UPDATE academic_terms SET is_active = 0;
UPDATE academic_terms SET is_active = 1 WHERE term_code = '2120252026';
```

---

## 4. Full lifecycle demo (optional)

For the 4-year BSIT walkthrough (Maria / Elon), use the existing scripts in `README_DEMO_SQL.md`.  
Finance personas are **independent** — reset with `00_finance_demo_reset.sql` without touching `2026-0004` or `2026-1001`.

---

## 5. Troubleshooting

| Symptom | Fix |
|---------|-----|
| Blank page after Add | Redeploy registrar WAR (flash redirect + ASCII errors); check Tomcat log for `Location ... ₱ ... removed` |
| PHP 23,074 credit forward | Corrupted data from old WAR — run `00_finance_demo_reset.sql` + `10_seed_finance_demo_personas.sql` |
| Cashier vs Registrar balance mismatch | Run `audit_student_ledger_balance.sql`; rebuild both WARs |
| Add blocked at PHP 30,523 | Stale block logic — redeploy registrar (block = forward ≥ 100 only) |

---

## 6. Script index

| Script | When |
|--------|------|
| `00_finance_demo_reset.sql` | Before each finance QA session |
| `10_seed_finance_demo_personas.sql` | After reset |
| `11_finance_scenario_checks.sql` | After each UI scenario |
| `04_smoke_test_checklist.sql` | After seed / before demo |
| `audit_student_ledger_balance.sql` | Ad-hoc ledger debug |
| Per-student forward fix | Use `00_finance_demo_reset.sql` + `10_seed_finance_demo_personas.sql` instead |
