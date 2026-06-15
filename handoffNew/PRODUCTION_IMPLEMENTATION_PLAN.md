# Production Implementation Plan (Proposal)

Last updated: 2026-06-10  
**Status:** Proposal / backlog — **not actively implementing** until UAT sign-off + user go-ahead.

**Context:** Demo/pilot stabilization is **complete**. Human UAT is **in progress** (user re-tested core flows positively). This plan covers work **after** UAT when moving toward production.

**Master status:** **`PROJECT_STATUS_AND_ROADMAP.md`**

---

## Guiding principle

| Phase | When | Goal |
|-------|------|------|
| **Now** | UAT in progress | **Testing / sign-off** — `HUMAN_UAT_CHECKLIST.md` (0/A/B largely done; C–F pending) |
| **Phase 1** | After UAT + go-ahead | **Security & access control** — **1A deferred** per user 2026-06-10 |
| **Phase 2** | Parallel or after Phase 1 | **Data & policy hardening** |
| **Phase 3** | Pre-go-live | **Ops, CI/CD, observability** |
| **Phase 4** | Post-go-live | **Deferred features** (TOR OCR, equivalency, etc.) |

Do **not** start Phase 1 until UAT has recorded pass/fail for Sessions 0–E (or explicit waiver).

---

## Phase summary

| Phase | Workstream | Priority | Detailed proposal |
|-------|------------|----------|-------------------|
| **1A** | Registrar Spring Security | High (prod) | **`PROPOSAL_REGISTRAR_SPRING_SECURITY.md`** — **DEFERRED** |
| **1B** | Align Enrollment ↔ Registrar role matrix | Medium | Section below |
| **1C** | Remove demo-only behaviors (password reset on boot) | High | In Spring Security proposal |
| **2A** | Official production fee rates | High (business) | Registrar UI import + sign-off |
| **2B** | Empty curricula (6 retired programs) | Low unless reactivated | Manual curriculum fill |
| **2C** | Session timeout / audit logging | Medium | After 1A |
| **3A** | CI/CD (build, test, deploy) | Medium | TBD |
| **3B** | Secrets management (.env, no empty root) | High | TBD |
| **3C** | Backup / restore runbook | High | TBD |
| **4** | TOR PDF/OCR, equivalency, scheduling automation | Low | Out of demo scope |

---

## Phase 1 — Security (recommended order)

### 1A. Registrar Spring Security — **DEFERRED** (proposal ready)

**Problem today:** Registrar uses manual `HttpSession` + `currentUser` map. ~80+ per-controller login checks. Several POST/API routes have **no auth at all**. Any logged-in role (including Student) can hit `/admin/*` URLs if they know the path.

**Proposal:** `PROPOSAL_REGISTRAR_SPRING_SECURITY.md` (full design).

**Success criteria:**
- All non-public routes require authentication
- `/admin/**` restricted to Admin / Registrar roles
- `/grades/**` restricted to Faculty (+ Admin read-only where already supported)
- Open APIs (`/api/faculty/auto-save`, `/api/mcp/**`) secured or disabled
- Demo UAT still passes with `admin` / `prof.cruz` / `1234`

### 1B. Role matrix alignment

Enrollment already uses Spring Security with roles from `sys_users.role`:

| Enrollment path pattern | Roles allowed |
|-------------------------|---------------|
| `/admin/**` | ADMIN, CASHIER, FACULTY |
| `/registrar/**` | REGISTRAR, ADMIN |
| `/faculty/**` | FACULTY, ADMIN |
| `/admission/**` | ADMISSION, ADMIN |

Registrar proposal mirrors this for equivalent surfaces:

| Registrar path | Intended roles |
|----------------|----------------|
| `/admin/**` | Admin, Registrar |
| `/grades/**` | Faculty, Admin (readonly) |
| `/` dashboard | Admin, Registrar, Faculty (redirect by role) |
| Student self-service (`/enrollment`, `/my-grades`, …) | Student |

**Impact:** Operators who use `cashier` in Enrollment should **not** get Registrar admin unless explicitly granted Registrar/Admin role in `sys_users`.

### 1C. Demo-only removal (gated by profile)

| Behavior | Location | Production change |
|----------|----------|-------------------|
| Reset `admin`/`prof` password to `1234` on every boot | `RegistrarApplication.java` | Disable unless `spring.profiles.active=demo` |
| Default password `1234` on user create | `AcademicGradingService`, `DatabaseSetupService` | Force password change on first login (Phase 1B+) |

---

## Phase 2 — Data & policy

| Item | Notes | System impact |
|------|-------|---------------|
| Official fee rates | CSV import via Program Fees UI | Billing amounts change; re-run readiness |
| Production finance gates | Finance Policy page | May block enlist/finalize in UAT scenarios |
| Six retired programs | Only if business reactivates | Re-run retire patch inverse + curriculum fill |
| `granted_permissions` JSON on `sys_users` | Exists but **not enforced** today | Optional Phase 1D — fine-grained permissions |

---

## Phase 3 — Operations

| Item | Notes |
|------|-------|
| CI/CD | `mvn test` + bootstrap smoke on PR |
| DB credentials | Non-empty root password; separate app DB user with least privilege |
| HTTPS / reverse proxy | Tomcat behind nginx or IIS |
| MCP server | `spring.ai.mcp.server.webmvc.enabled=true` — **disable or auth-wrap in prod** |
| Logging / audit | Who changed finance policy, term transition, grade approvals |

---

## Phase 4 — Deferred features (unchanged)

- TOR PDF upload / OCR
- Course equivalency table
- Scheduling automation / room conflict engine
- Curriculum CSV import (export only today)

---

## Decision log (fill during review)

| Question | Options | Decision |
|----------|---------|----------|
| Start Phase 1 before UAT complete? | Yes / **No** | **No** — UAT still in progress |
| Implement Registrar Spring Security now? | Yes / **No (defer)** | **Deferred** 2026-06-10 — too long for current sprint |
| CSRF on Registrar forms? | Enable / Match Enrollment (off initially) | TBD when 1A starts |
| MCP in production? | Disable / API key / VPN only | TBD |
| Single sign-on across apps? | No (separate sessions) / Future SSO | TBD |
| `granted_permissions` enforcement? | Phase 1 / Phase 2 / Never | TBD |

---

## Related documents

| Doc | Purpose |
|-----|---------|
| **`PROJECT_STATUS_AND_ROADMAP.md`** | Master status — done / pending / sidetracks |
| **`PROPOSAL_REGISTRAR_SPRING_SECURITY.md`** | Detailed security implementation (deferred) |
| `HANDOFF_UPDATES_20260609.md` | Changelog by date |
| `HUMAN_UAT_CHECKLIST.md` | Pre-production testing |
| `COMPLETE_FRESH_SETUP_AND_DEMO_GUIDE.md` | Demo setup |
