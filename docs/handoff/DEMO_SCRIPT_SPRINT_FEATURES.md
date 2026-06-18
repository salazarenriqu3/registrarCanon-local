# Sprint Features Demo Script

Date: 2026-06-19  
Audience: Evaluators, UAT presenters, successor agents  
Login: `admin` / `1234` at `http://localhost:8083/registrar`

**Preload data:**

```cmd
mysql -u root eacdb < registrar/db/demo_scripts/19_sprint_features_demo_seed.sql
```

Optional full lifecycle seeds:

```cmd
mysql -u root eacdb < registrar/db/demo_scripts/16_withdrawal_uat_seed.sql
```

---

## Demo flow (45–60 minutes)

### 1. Program Builder (Sprint 1) — 5 min

1. Open **Programs** → `/admin/programs`
2. Show existing programs; note REGISTRAR is view-only, ADMIN can create
3. Create test program `DEMO-PRG` (4 years) — save
4. Edit: show **program code is locked** after first save
5. Try delete on a program in use → blocked

### 2. Course catalog & types (Sprint 1 + 9) — 5 min

1. Open **Course Catalog** → `/admin/course-catalog`
2. Edit a course: show **course code readonly** on edit
3. Set **Course type**: REGULAR / TUTORIAL / PETITION
4. Note petition min headcount hint on catalog

### 3. Slot monitoring (Sprint 2) — 8 min

1. Open **Slot Monitoring** → `/admin/slot-monitoring`
2. Show enrolled vs pre-reg counts, capacity, status
3. Update max capacity on one section
4. **Close** a section (soft close — no new enlistments)
5. **Bulk close** with select-all checkbox
6. Class Scheduling → expand block → **Remove course from block** (if no enlistments)

### 4. Registration forms & documents (Sprint 3) — 8 min

1. Student Manager → student with payment (`2026-1001` if seeded, or any enrolled student)
2. Print Registration Form — note **Pre-Registration Form** vs **Registration Form** title
3. Attempt print before downpayment on unpaid student → blocked
4. **Print TOR** → `/admin/print-tor` — enter remarks, special order, purpose → print
5. Print COG — confirm audit event recorded (Student Profile document trail)

### 5. Withdrawal & program shift (Sprint 4) — 10 min

**Withdrawal** (use `WDRW-UAT-2026-001` if seed loaded):

1. Student Manager → submit withdrawal with reason
2. Dean queue → `/faculty/withdrawals` → approve
3. Registrar queue → `/admin/withdrawals` → approve → subject removed
4. Report → `/admin/withdrawals/report`

**Program shift:**

1. Student Manager → request program shift (creates request, not direct change)
2. Dean → `/faculty/program-shifts` → approve
3. Registrar → `/admin/program-shifts` → approve

### 6. Grading configuration (Sprint 5) — 3 min

1. **Settings** → `/admin/settings` — Grading Scheme section
2. Show class standing / exam weights (default 50/50)
3. Note: faculty encoding uses weights when saving grades

### 7. Holds & portal blocks (Sprint 6) — 5 min

1. Student Manager → `SPRINT-DEMO-2026-001`
2. Show active **OSA hold**; add/clear Library hold
3. Login as that student (if portal account exists) or explain portal block on my-grades/my-load

### 8. Dean evaluation (Sprint 7) — 5 min

1. `/dean/student-evaluation?studentNumber=SPRINT-DEMO-2026-001`
2. Show curriculum checklist — black passed, red failed
3. Class Scheduling → note faculty assign requires **DEAN or ADMIN**

### 9. Enrollment periods (Sprint 8) — 5 min

1. **Finance Policy** → `/admin/finance-policy`
2. Show enrollment open/close, add/drop close dates
3. Explain: enlistment blocked after close; add/drop close blocks changes
4. Installment override visible to **ADMIN only** on Student Manager

### 10. Traceability & CI (Sprint 10) — 2 min

1. Show `docs/handoff/CHECKLIST_TRACEABILITY.md` in repo
2. GitHub Actions → `maven-test.yml` runs on push

---

## Evaluator quick-reference URLs

| Feature | URL |
|---------|-----|
| Programs | `/admin/programs` |
| Slot monitoring | `/admin/slot-monitoring` |
| Class scheduling | `/admin/class-scheduling?view=blocks` |
| Finance policy | `/admin/finance-policy` |
| Print TOR form | `/admin/print-tor` |
| Withdrawals | `/admin/withdrawals` |
| Program shifts | `/admin/program-shifts` |
| Dean withdrawals | `/faculty/withdrawals` |
| Dean program shifts | `/faculty/program-shifts` |
| Dean evaluation | `/dean/student-evaluation?studentNumber=SPRINT-DEMO-2026-001` |
| Settings / grading | `/admin/settings` |

---

## Known demo limitations (state explicitly)

- Petition conditional pricing: column + hints only; no auto fee engine
- Late enrollment fee: flag stored; Cashier posts manually
- Payment finalize / student number issuance: Enrollment/Cashier apps
- Admissions open-date screen: external Admission module
- Demo fee rates are not official production values

---

## Sign-off

| Presenter | Date | Demo GO / NO-GO |
|-----------|------|-----------------|
| | | |
