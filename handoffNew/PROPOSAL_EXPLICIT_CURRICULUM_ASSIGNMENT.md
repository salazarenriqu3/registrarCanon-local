# Proposal — Explicit Student Curriculum Assignment

Last updated: 2026-06-10  
**Bundle:** `61026.2/curriculum/`  
**Status:** Approved direction — **not implemented**  
**Build plan:** `IMPLEMENTATION_PLAN_CURRICULUM_ASSIGNMENT.md`

---

## 1. Problem

A student may have started under an **older catalog** (e.g. A.Y. 2024–25), stopped, and return while a **new active** catalog exists for the same program. They must **not** be treated as a new entrant on the latest catalog unless staff choose that.

Today:

| Behavior | Issue |
|----------|--------|
| Assignment at **admission** only (automated) | OK for new students |
| **Re-enroll** does not re-assign | OK if assignment row still exists |
| **No row** → `LEGACY_BACKFILL` (Registrar) or **active fallback** (Enrollment) | Wrong catalog silently |
| **Program Shift** only way to set catalog explicitly | Also changes program / Irregular / clears enlist |
| **Block enrollment** (Y1) ignores assignment | Uses `is_active = 1` only |

---

## 2. Agreed direction

1. **Explicit assign curriculum** in Registrar Student Manager (catalog only — not program shift).  
2. **Stop silent auto-assign** when no row exists; block irregular enlist until assigned.  
3. **Enrollment read paths** align with Registrar (no active-catalog fallback when unassigned).  
4. **Block enrollment** respects assigned `curriculum_id` when row exists.  
5. **Admission** keeps auto-assign to active catalog for **new** entrants only.

---

## 3. Data model (unchanged)

Table: `student_curriculum_assignments`

| Column | Role |
|--------|------|
| `student_number` | Student |
| `curriculum_id` | Assigned template |
| `program_code` | Denormalized from template |
| `assignment_type` | Audit: `NEW_ENTRANT`, `TRANSFEREE`, `PROGRAM_SHIFT`, **`MANUAL`**, **`RETURNING`** |
| `reason` | Free text |
| `is_current` | One current row per student |

No schema migration required for v1.

---

## 4. Lifecycle (target)

```text
New admission          → auto-assign active catalog (NEW_ENTRANT / TRANSFEREE) — unchanged
Returning, has row     → preserve — unchanged
Returning, no row      → block enlist + staff explicit assign (RETURNING / MANUAL)
Program change         → Program Shift (PROGRAM_SHIFT) — unchanged
Irregular / offerings  → filter by assigned curriculum_id only
Block sections         → filter by assigned curriculum_id when row exists
```

---

## 5. UX surfaces

| Surface | Action |
|---------|--------|
| **Registrar Student Manager** | Assign / change curriculum (primary) |
| **Registrar enrollment hub** | Warning + link if unassigned (optional) |
| **Enrollment cashier** | Banner if unassigned; block irregular finalize |
| **Enrollment block UI** | Sections from assigned catalog |

Staff **assign on Registrar**; Enrollment does not write assignments in v1.

---

## 6. Out of scope (v1)

- Auto-infer catalog from grades/TOR  
- Student self-service catalog choice  
- New admission track for all returnees  
- Curriculum assignment on bulk term transition  
- Multiple concurrent curricula per student  

---

## 7. UAT references

| ID | Scenario |
|----|----------|
| RET-CURR-01 | Two catalogs; student assigned old; irregular offerings match old |
| RET-CURR-02 | No assignment → enlist blocked; after assign → offerings appear |
| RET-CURR-03 | Active catalog changes; assigned student unchanged |
| RET-CURR-04 | Block path uses assigned catalog (if row exists) |
| TRANS-T04 | Regression — irregular scope (existing) |

---

## 8. Related docs

| Doc | Section |
|-----|---------|
| `IMPLEMENTATION_PLAN_CURRICULUM_ASSIGNMENT.md` | Phased build |
| `CURRICULUM_SEEDING_RULES.md` | Catalog seeding |
| `MASTER_DEMO_UAT_MANUAL.md` | TRANS-T04, SHIFT-T01 |
| `StudentCurriculumServiceTest.java` | Existing unit proof |
