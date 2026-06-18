# Start Here - Registrar Handover

Last updated: 2026-06-19

**Canonical packaged handover:** `docs/demo/final-demo-package\00_START_HERE.md`

The dated package contains sorted documentation, a self-contained fresh database chain, current test SQL, runners, checksums, and execution evidence. Use it for a new terminal/demo setup.

Use this documentation order:

1. `FINAL_SYSTEM_DOCUMENTATION_20260618.md` - authoritative scope, architecture, capabilities, and readiness.
2. `FINAL_DEMO_AND_TEST_MANUAL_20260618.md` - fresh setup, build gate, presentation flow, complete UAT, and sign-off form.
3. `FINAL_HANDOVER_20260618.md` - build evidence, open risks, production blockers, and successor instructions.
4. `PRODUCTION_GO_LIVE_CHECKLIST.md` - staged gates for staging pilot and production sign-off (post sprint 1–10).

## Current verdict

- Controlled Registrar demo: ready after the documented preflight.
- Staging pilot: start after `PRODUCTION_GO_LIVE_CHECKLIST.md` Gates 1–3.
- Production deployment: not approved until Gates 1–8 signed.
- Active demo term: `1120242025` (`term_id = 1`).
- Retired Registrar irregular new-enrollee advising/pre-registration: out of scope.

## Quick start

From `C:\newer\new` on a disposable demo database:

```powershell
registrar\setup\CHECK_PREREQUISITES.cmd
registrar\setup\RUN_FRESH_SETUP.cmd
```

Warning: fresh setup drops and recreates `eacdb`.

Start Registrar from `C:\newer\new\registrar` with `mvn spring-boot:run` and Enrollment from `C:\newer\new\enrollment3` with `.\mvnw.cmd spring-boot:run`.

Older files in this folder are detailed supporting history. The three final documents above take precedence whenever wording or status conflicts.
