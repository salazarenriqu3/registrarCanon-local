# Production Go-Live Checklist

Date: 2026-06-19  
Repository: `salazarenriqu3/registrar`  
Branch: `main` / `canon-main`

This checklist turns the sprint work into an actionable production path. Complete every **Gate** section in order. Do not skip gates based on a green Maven build alone.

---

## Release position (read first)

| Environment | Status | Notes |
|-------------|--------|-------|
| Local demo / UAT | **GO with conditions** | Fresh bootstrap + demo manual |
| Staging pilot | **Ready to start** after Gate 1–3 | Shared DB with Enrollment |
| Production | **NO-GO until all gates signed** | See blockers below |

Sprint 1–10 closed most **registrar-owned** checklist gaps. Cross-app flows (Cashier finalize, Admission intake), official fee rates, and human UAT sign-off remain business/ops responsibilities.

---

## Gate 0 — Code baseline (developer)

- [ ] Pull latest `main` (commit includes sprints 2–10 + production hooks)
- [ ] `mvn test -Dtest=!ModulithTests` passes
- [ ] `mvn -q -DskipTests package` produces WAR
- [ ] Review `docs/handoff/CHECKLIST_TRACEABILITY.md` for Partial/Deferred items your pilot accepts

**Evidence:** CI workflow `.github/workflows/maven-test.yml` (excludes ModulithTests until cycles resolved)

---

## Gate 1 — Database & migration

- [ ] **Never** run `setup/RUN_FRESH_SETUP.cmd` against staging/prod (destructive)
- [ ] Apply schema changes from `db/MIGRATION_SIGNOFF.md` on a staging clone first
- [ ] Verify new objects exist:
  - `student_program_shift_requests`
  - `grading_schemes`
  - `student_holds`
  - `academic_term_policies.midterm_exam_date`
  - `courses.course_type`
  - Enrollment period keys in `system_settings`
- [ ] DBA signs `db/MIGRATION_SIGNOFF.md`
- [ ] Backup taken **before** promote; restore drill documented

**Owner:** DBA + developer  
**Rollback:** Nullable columns can remain; new tables need data review before DROP

---

## Gate 2 — Cross-app coordination

Registrar shares `eacdb` with Enrollment (8082) and Admission. Schema or term-id mismatches fail silently at runtime.

- [ ] Enrollment WAR deployed to compatible version
- [ ] Admission app version documented (if used in pilot)
- [ ] Active term matches in all apps: `system_settings.CURRENT_ACADEMIC_TERM`
- [ ] `student_number` identity consistent across apps
- [ ] Investigate/fix Enrollment `Unknown column 'RESERVED'` if finance UAT is in scope
- [ ] Coordinate deploy order: DB migration → Enrollment → Registrar

**Smoke URLs after deploy:**

| App | URL |
|-----|-----|
| Registrar | `https://<host>/registrar/admin/settings` |
| Enrollment | `https://<host>:8082/` (or your reverse-proxy path) |

---

## Gate 3 — Business data sign-off

- [ ] Official fee CSV imported per program/year/semester (not demo seeds)
- [ ] Finance Policy values confirmed by finance office:
  - Downpayment threshold / percent
  - Accounting block threshold
  - Enrollment open/close dates
  - Add/drop close date
  - Late enrollment fee flag (posting still manual if enabled)
- [ ] Grading scheme weights confirmed (Settings → Grading Scheme)
- [ ] Withdrawal penalty tiers confirmed (25/50/100%, midterm exam date per term)
- [ ] Scholarship policy thresholds confirmed

**Document:** attach signed CSV export or screenshot bundle to release ticket

---

## Gate 4 — Human UAT (Sessions C–E)

Run `docs/handoff/FINAL_DEMO_AND_TEST_MANUAL_20260618.md` on **staging** with disposable test students (`DREG-*`, `HTEST-*`, etc.).

### Session C — Finance & enrollment cross-app

- [ ] Payment at Cashier triggers enrollment state correctly
- [ ] COR/Registration Form prints only after downpayment gate
- [ ] Forwarded balance blocks enlistment at threshold
- [ ] Enrollment close date blocks new enlistments
- [ ] Add/drop close date blocks enlistment changes and new withdrawal requests

### Session D — Academic operations

- [ ] Program Builder create/edit (ADMIN); REGISTRAR view-only
- [ ] Slot monitoring: close, dissolve, capacity update
- [ ] Program shift: Dean queue → Registrar queue → approved shift
- [ ] Withdrawal: Dean → Registrar → subject removed + charge applied
- [ ] Dean student evaluation checklist renders correctly

### Session E — Records & portal

- [ ] Student holds block my-grades / my-load
- [ ] TOR form fields appear on print
- [ ] Reg form event trail records prints
- [ ] Scholarship workflow through POSTED (if in pilot scope)

**Sign-off table:**

| Role | Name | Date | Pass/Fail |
|------|------|------|-----------|
| Registrar lead | | | |
| Finance | | | |
| IT operations | | | |

---

## Gate 5 — Security & secrets

### Production profile

Start with:

```bash
export SPRING_PROFILES_ACTIVE=prod
export SPRING_DATASOURCE_URL=jdbc:mysql://<host>:3306/eacdb?...
export SPRING_DATASOURCE_USERNAME=registrar_app
export SPRING_DATASOURCE_PASSWORD=<secret>
```

`application-prod.properties` enforces:

- Non-empty DB password
- `registrar.demo.reset-passwords-on-boot=false`
- MCP server disabled
- Secure session cookies (HTTPS required at proxy)

### Security checklist

- [ ] Remove or rotate demo accounts (`admin`/`1234`, `cashier`, etc.)
- [ ] Dedicated DB user with least privilege (not `root`/empty password)
- [ ] HTTPS terminated at reverse proxy; HTTP redirects to HTTPS
- [ ] Secrets in vault/env — not in `application.properties` committed to git
- [ ] Role matrix reviewed: ADMIN, REGISTRAR, DEAN, FACULTY, STUDENT
- [ ] Faculty assignment restricted to DEAN/ADMIN (verified)
- [ ] Installment override restricted to ADMIN (verified)

**Known gap:** Full SSO/LDAP integration is not implemented; form login remains. Plan identity provider before wide production rollout.

---

## Gate 6 — Operations

- [ ] HTTPS certificate valid
- [ ] Log aggregation (stdout → collector or file rotation)
- [ ] Health check endpoint monitored (Tomcat `/registrar/login` or custom actuator if added)
- [ ] Backup schedule: nightly DB + weekly full
- [ ] Restore test completed on non-prod clone (document RTO/RPO)
- [ ] Rollback plan: previous WAR + DB snapshot ID documented
- [ ] On-call contact and escalation path defined

---

## Gate 7 — Architecture debt disposition

| Item | Required action |
|------|-----------------|
| `ModulithTests` cycle failure | Resolve package cycles **or** formally accept exclusion with architect sign-off |
| Shared-table integration | Document schema change process across apps |
| Partial features (see traceability) | Accept, defer, or implement before prod |

---

## Gate 8 — Production deploy

### Pre-deploy

- [ ] Maintenance window announced
- [ ] DB backup ID recorded
- [ ] Previous WAR artifact archived

### Deploy steps

1. Apply pending SQL / allow app auto-migrate on first boot (verify in staging first)
2. Deploy Enrollment WAR (if changed)
3. Deploy Registrar WAR: `target/registrar-0.0.1-SNAPSHOT.war`
4. Set `SPRING_PROFILES_ACTIVE=prod` and datasource env vars
5. Restart Tomcat / container
6. Run post-deploy smoke (below)

### Post-deploy smoke (15 min)

- [ ] Login with production admin account (not demo)
- [ ] `/admin/settings` → readiness **Ready** for active term
- [ ] `/admin/finance-policy` → dates saved and load correctly
- [ ] `/admin/slot-monitoring` → sections list loads
- [ ] Student portal login → my-load loads (test student)
- [ ] No stack traces in logs for smoke paths

---

## Accepted deferrals (document in release ticket)

These are **known partial** items — acceptable for pilot only if explicitly signed off:

| Item | Risk if deferred |
|------|------------------|
| Petition course conditional pricing | Manual fee adjustment at Cashier |
| Late enrollment fee auto-posting | Manual late fee at Cashier |
| Per-program grading scheme UI | Use default scheme only |
| Admissions open-date screen | Configure dates in Registrar Finance Policy |
| Full portal auto-COR on payment | Manual COR print at Registrar |
| Modulith cycle debt | CI excludes test; no runtime impact today |

---

## Quick reference

| Resource | Path |
|----------|------|
| Checklist traceability | `docs/handoff/CHECKLIST_TRACEABILITY.md` |
| Demo / UAT manual | `docs/handoff/FINAL_DEMO_AND_TEST_MANUAL_20260618.md` |
| System documentation | `docs/handoff/FINAL_SYSTEM_DOCUMENTATION_20260618.md` |
| Migration sign-off | `db/MIGRATION_SIGNOFF.md` |
| Production profile | `src/main/resources/application-prod.properties` |
| Fresh setup (dev only) | `setup/RUN_FRESH_SETUP.cmd` |

---

## Final production decision

```
Production GO / NO-GO: _______________
Decision date: _______________
Release version / commit: _______________
DB backup ID: _______________
Signed by (Registrar): _______________
Signed by (IT): _______________
Signed by (Management): _______________
Known exceptions accepted: _______________
```

**Default recommendation:** **NO-GO** until Gates 1–6 are signed and Gate 4 UAT passes on staging.
