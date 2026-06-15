# Registrar Subsystem — Agent Handover
## Fee Architecture Overhaul + Full UI Standardization Sprint
### Completed: 2026-06-05 | Authored by: Antigravity (AI Coding Agent) + User (sune)

---

## 0. Prerequisites — Read This First

This document covers **only the Registrar WAR** (`registrar/` — runs on port 8083 at context path `/registrar`).  
The system is part of a three-WAR deployment: `admission.war`, `enrollment.war`, and `registrar.war`, all sharing database `eacdb` on MySQL `localhost:3306`.

The companion finance/enrollment sprint (term-close, ledger forward-net, drop/refund) is documented separately in  
`handoff/03-agent-dev/AGENT_HANDOVER_JUN2026.md`.

**Do not conflate the two.** That document covers `enrollment3/`. This document covers `registrar/`.

---

## 1. System Topology

| Property | Value |
|---|---|
| Artifact ID | `RegistrarSubsystem` |
| Server port | `8083` |
| Context path | `/registrar` |
| Database | `eacdb` on `localhost:3306` |
| DB user | `root` (no password on dev) |
| Thymeleaf cache | `false` (disabled for development; **do not enable in dev**) |
| JPA DDL auto | `none` — Hibernate **never** auto-modifies schema |
| Spring AI MCP | Enabled (`spring.ai.mcp.server.webmvc.enabled=true`) |

Run locally with:
```powershell
$env:SPRING_DATASOURCE_URL="jdbc:mysql://127.0.0.1:3306/eacdb?serverTimezone=Asia/Manila"
mvn clean spring-boot:run
```

Or use the sandbox database `registrar_sandbox` for isolated testing:
```powershell
$env:SPRING_DATASOURCE_URL="jdbc:mysql://127.0.0.1:3306/registrar_sandbox?serverTimezone=Asia/Manila"
mvn clean spring-boot:run
```

---

## 2. Package Structure

```
com.iuims.registrar
├── RegistrarApplication.java       — @SpringBootApplication, @EnableCaching; seeds demo passwords on startup
├── academic/                        — ClassSchedule, ClassScheduleRepository, AcademicGradingService, ...
├── admission/                       — Admission acceptance controllers + service
├── config/                          — Spring Security config, MVC config
├── core/                            — SysUser entity, SysUserRepository
├── curriculum/                      — Course, CurriculumTemplate, CurriculumController
├── enrollment/                      — EnrollmentController (Student Manager), EnlistmentSchemaService
├── faculty/                         — FacultyLoad entities + service
├── finance/                         — [PRIMARY SPRINT TARGET] — ProgramFeeSetting, TermFeeAdminService, ...
├── jaypee/                          — JaypeeIntegrationService (cross-system delegate for drops)
├── portal/                          — StudentPortalController (student-facing views)
└── scholarship/                     — ScholarEnrollmentService (fee calc + term close), ScholarshipController
```

---

## 3. This Sprint — What Was Done

### 3.1 Fee Architecture Overhaul (Phase 6, Improvements 1–4)

#### The Problem Before This Sprint

Two legacy tables stored fee configuration in a split-brain pattern:
- `program_general_fees` — wide table for tuition/RLE, required complex fallback SQL with nested subqueries.
- `program_specific_fees` — EAV pattern (Entity-Attribute-Value) storing misc/other charges as rows with `fee_code` + `amount` columns. Required correlated `NOT EXISTS` anti-join to deduplicate.

Every service that calculated fees (`ScholarEnrollmentService`, readiness checks, seeding) replicated the same 50+ line JDBC query blocks. The logic was untestable, fragile, and different services had subtly divergent fallback behaviors.

#### The Fix — `program_fee_settings` Unified Wide Table

A single table replaced both:

```sql
CREATE TABLE program_fee_settings (
    fee_setting_id        INT AUTO_INCREMENT PRIMARY KEY,
    program_id            INT NOT NULL,
    term_id               INT NULL,          -- NULL = global fallback template; INT = term-specific override
    year_level            INT NULL,          -- 1..4
    semester_number       INT NULL,          -- 1 or 2
    -- Core per-unit rates
    fee_tuition_per_unit  DECIMAL(10,2) DEFAULT 0.00,
    fee_lec_per_unit      DECIMAL(10,2) DEFAULT 0.00,
    fee_lab_per_unit      DECIMAL(10,2) DEFAULT 0.00,
    fee_comp_per_unit     DECIMAL(10,2) DEFAULT 0.00,
    fee_rle_per_unit      DECIMAL(10,2) DEFAULT 0.00,
    -- Misc flat charges
    fee_misc_registration DECIMAL(10,2) DEFAULT 0.00,
    fee_misc_library      DECIMAL(10,2) DEFAULT 0.00,
    fee_misc_medical      DECIMAL(10,2) DEFAULT 0.00,
    fee_misc_id           DECIMAL(10,2) DEFAULT 0.00,
    fee_misc_athletic     DECIMAL(10,2) DEFAULT 0.00,
    fee_misc_guidance     DECIMAL(10,2) DEFAULT 0.00,
    fee_misc_lms          DECIMAL(10,2) DEFAULT 0.00,
    fee_misc_insurance    DECIMAL(10,2) DEFAULT 0.00,
    fee_misc_cultural     DECIMAL(10,2) DEFAULT 0.00,
    fee_misc_av           DECIMAL(10,2) DEFAULT 0.00,
    fee_misc_energy       DECIMAL(10,2) DEFAULT 0.00,
    -- Other flat charges
    fee_other_late_enrollment DECIMAL(10,2) DEFAULT 0.00,
    fee_other_add_drop        DECIMAL(10,2) DEFAULT 0.00,
    fee_other_installment     DECIMAL(10,2) DEFAULT 0.00,
    fee_other_id              DECIMAL(10,2) DEFAULT 0.00,
    fee_other_insurance       DECIMAL(10,2) DEFAULT 0.00,
    fee_other_comp            DECIMAL(10,2) DEFAULT 0.00,
    fee_other_dev             DECIMAL(10,2) DEFAULT 0.00,
    is_active             TINYINT NOT NULL DEFAULT 1
);
```

**Semantics:**
- `0.00` = fee does not apply; not computed, not displayed.
- `> 0.00` = fee applies; shown in UI, computed against enrolled units (for per-unit types) or applied flat (for misc/other).
- `term_id = NULL` = **global fallback template** — applies to any term that does not have an explicit override row.
- `term_id = <id>` = **term-specific override** — takes absolute precedence over fallback.

#### Fallback Resolution — The One True Query

Every read path in the system resolves fees with exactly this SQL:
```sql
SELECT * FROM program_fee_settings
WHERE program_id = ?
  AND year_level = ?
  AND semester_number = ?
  AND is_active = 1
  AND (term_id = ? OR term_id IS NULL)
ORDER BY
  CASE WHEN term_id = ? THEN 0 ELSE 1 END,  -- exact term = priority 0
  fee_setting_id DESC                         -- most recent row wins ties
LIMIT 1
```
This is implemented in `ProgramFeeSettingRepository.findBestMatch(int programId, int yearLevel, int semester, Integer termId)`.  
**Do not reimplement this query anywhere else.** Direct all fee reads through `TermFeeAdminService.getFeeRatesForScope(...)`.

#### Key Files — Finance Package

| File | Responsibility |
|---|---|
| `finance/ProgramFeeSetting.java` | JPA `@Entity` for `program_fee_settings`. Contains `getFee(String code)` and `setFee(String code, double amount)` — a generic dispatch switch on `KNOWN_FEES` codes. Both methods use `BigDecimal` internally and return `double`. |
| `finance/ProgramFeeSettingRepository.java` | Spring Data repository. `findBestMatch` (read path), `findActiveForScopeOrFallback` (write path / upsert check), `findByTermIdAndIsActiveTrue` (bulk import), `findByTermId...AndIsActiveTrue` (scoped import), `findFirstByProgramId...AndTermId...` (target row lookup on import). |
| `finance/TermFeeAdminService.java` | **All fee business logic lives here.** See methods below. |
| `finance/TermFeeAdminController.java` | HTTP endpoints for the `/admin/term-fees` UI. Not modified in this sprint. Receives `Map<String, Double>` and `Map<String, String>` from the service layer. |

#### `TermFeeAdminService` — Public API Reference

| Method | Signature | Behaviour |
|---|---|---|
| `getFeeRatesForScope` | `(int programId, Integer termId, int yearLevel, int semester) → Map<String, Double>` | Resolves best-match row via `findBestMatch`, iterates `KNOWN_FEES`, returns only non-zero values. |
| `getFeeRateSourcesForScope` | `(int programId, Integer termId, int yearLevel, int semester) → Map<String, String>` | Same resolution; value is `"EXACT_TERM"` or `"FALLBACK"`. Used by admin UI to display fallback badges. |
| `saveFeeRate` | `(int programId, Integer termId, int yearLevel, int semester, String feeCode, double amount) → boolean` | Upserts. If no exact-term row exists, creates one (copying all values from fallback first). Side effect: if `TUITION_PER_UNIT` is saved and `LEC_FEE_PER_UNIT` is currently `0`, it auto-mirrors the tuition value to `LEC_FEE_PER_UNIT`. |
| `prepareTermFees` | `(Integer termId) → TermFeePreparationResult` | Admin-triggered. For every program × year × semester scope, seeds an exact-term row from fallback if none exists. |
| `importFeesFromSpecificTerm` | `(Integer sourceTermId, Integer targetTermId, Integer programId, Integer yearLevel, Integer semesterNumber) → FeeTemplateCopyResult` | Copies rows from one term to another. If `programId`, `yearLevel`, `semesterNumber` are all non-null, performs a scoped (single-scope) import. If any are null, performs a bulk import of all source rows. |
| `copyImportedProgramFeeTemplates` | `(Integer termId) → FeeTemplateCopyResult` | Seeds fees for "derived" programs (e.g. BSBAFIN copies from BSBA, BSCPE copies from BSIT). The source map is hardcoded in `feeTemplateSources()`. |
| `buildTermReadinessSummary` | `(Integer termId) → Map<String, Object>` | Diagnostic. Checks every scope for missing rows, fallback-only rows, and missing curricula. Returns `ready: true` only if zero missing, zero fallback, zero missing curricula. |

#### `KNOWN_FEES` — The Registry

`TermFeeAdminService.KNOWN_FEES` is the **canonical list** of all fee codes. It is a `static final List<String>`:
```
"TUITION_PER_UNIT", "LEC_FEE_PER_UNIT", "LAB_FEE_PER_UNIT", "COMP_FEE_PER_UNIT", "RLE_FEE_PER_UNIT",
"MISC_REGISTRATION", "MISC_LIBRARY", "MISC_MEDICAL", "MISC_ID", "MISC_ATHLETIC",
"MISC_GUIDANCE", "MISC_LMS", "MISC_INS", "MISC_CULT", "MISC_AV", "MISC_ENERGY",
"OTHER_LATE_ENROLLMENT", "OTHER_ADD_DROP", "OTHER_INSTALLMENT",
"OTHER_ID", "OTHER_INS", "OTHER_COMP", "OTHER_DEV"
```

> **CRITICAL RULE:** If you ever add a new fee type, you MUST update ALL of the following in lockstep:
> 1. Add the `DECIMAL(10,2)` column to `program_fee_settings` DDL.
> 2. Add the `@Column`-mapped field + getter/setter to `ProgramFeeSetting.java`.
> 3. Add a `case` arm to both `getFee()` and `setFee()` in `ProgramFeeSetting.java`.
> 4. Add the string to `KNOWN_FEES` in `TermFeeAdminService.java`.
> 5. Add a `feeRow(...)` entry in `listFeeTypesForAdmin()`.
> Failure to update all five will cause silent data loss where the new fee is iterated but returns 0.

#### `ScholarEnrollmentService` Integration

Before this sprint, `ScholarEnrollmentService` contained two private methods (`coreTuitionRate` and `coreFeeSum`) that independently executed raw JDBC queries against the deprecated legacy tables, duplicating 50+ lines of fallback logic.

After this sprint, both methods delegate entirely to `TermFeeAdminService.getFeeRatesForScope(...)`:
```java
// CURRENT implementation (correct)
private double coreTuitionRate(Integer programId, Integer termId, int yearLevel, int semester) {
    Map<String, Double> rates = termFeeAdminService.getFeeRatesForScope(programId, termId, yearLevel, semester);
    return rates.getOrDefault("TUITION_PER_UNIT", 0.0);
}
```
`TermFeeAdminService` is injected into `ScholarEnrollmentService` via **constructor injection** (not field injection). This is required by Spring Modulith's architectural boundary check (`@ModulithTests`).

#### Deprecated Legacy Tables

`program_general_fees` and `program_specific_fees` still physically exist in the database but **no Java code reads or writes them anymore.** They are dead weight retained only as a rollback buffer. A DBA may drop them once the current sprint is verified stable. Do not reference them in any new code.

#### UI — Term Fees Admin Page (`/admin/term-fees` → `admin_term_fees.html`)

Two UX improvements were made to the term-fees admin UI:

1. **Dynamic Semester Lock**: Each `<option>` in the Academic Term `<select>` carries a `data-semester` attribute. A vanilla-JS listener on the `change` event snaps the Semester dropdown to match the selected term's actual semester and disables it. The special option `-- Global Fallback Templates --` (value = `-1`) unlocks the semester dropdown because fallbacks are calendar-agnostic.

2. **Scoped vs. Bulk Import**: The "Import from Source" submit button always uses the currently-active filter (program/year/semester) as a scoped import by default. A checkbox `<input type="checkbox" name="importScope" value="all">` overrides this — when checked, the controller receives `importScope=all`, passes `null` for `programId`/`yearLevel`/`semesterNumber`, triggering the bulk path in `importFeesFromSpecificTerm`.

---

### 3.2 Subsystem Scope Reduction (Phase 6, Improvement 5)

**Basic Education Removal**

The system handles **College students only**. Basic Education programs (`HS`, `JHS`, `SHS`) were previously appearing in rosters, section listings, and course offerings.

Removal was applied at the database query level inside `AcademicGradingService` and `JaypeeIntegrationService`. All native queries that previously selected from `programs`, `class_sections`, or related joins now include:
```sql
WHERE p.program_code NOT IN ('HS', 'JHS', 'SHS')
```
If you add a new query that reads programs or sections, you **must** apply this filter. Basic Ed programs remain in the database but must never surface in the Registrar UI.

**Payment Capture Deprecation**

The Registrar's role is limited to **setting fees**. It does not collect payments. Internal payment-capture views and any associated form posts to a payment controller were removed.

The Student Manager (`/admin/student-manager` → `admin_student_manager.html`) now delegates financial transactions to an external cashier gateway via a prominently placed `Open Enrollment System (External)` button. The button is a simple `<a href="...">` anchor pointing to the external gateway URL. This URL must be configured by the deploying team — it is not currently backed by a Spring property.

---

### 3.3 Premium UI Standardization — The Full Layout Migration (Phase 7)

#### The Layout Standard

Every admin page in the Registrar portal now uses a strict, consistent Thymeleaf wrapper structure. **This is the canonical, non-negotiable pattern:**

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<head th:replace="~{fragments/layout :: head}"></head>
<body>
<div class="app">
    <div th:replace="~{fragments/layout :: topbar}"></div>

    <div class="body-wrapper">
        <nav th:replace="~{fragments/layout :: sidebar(activeLink='<KEY>')}"></nav>

        <main class="main" role="main" id="main-content">
            <!-- page content here -->
        </main>
    </div>
</div>
</body>
</html>
```

Replace `<KEY>` with the `activeLink` value that matches the page in `fragments/layout.html`. Valid keys:

| activeLink value | Nav item highlighted |
|---|---|
| `dashboard` | Dashboard |
| `admissions` | Admissions |
| `students` | Student Directory |
| `curriculum` | Curriculum |
| `classes` | Subjects |
| `scheduling` | Class Scheduling |
| `faculty` | Faculty Load |
| `grades` | Grade Records |
| `term-fees` | Term Fees |
| `scholarships` | Scholarships |
| `users` | Users & Access |
| `settings` | Settings |

#### The Layout Fragment — `fragments/layout.html`

Located at `src/main/resources/templates/fragments/layout.html`. This file defines three Thymeleaf fragments:

1. **`head`** — Injects `<meta charset>`, `<meta viewport>`, Tabler Icons CDN link, and `theme-eac.css`.
2. **`topbar`** — The top navigation bar with EAC shield SVG logo, school name, icon buttons (search, notifications, help), and avatar.
3. **`sidebar(activeLink)`** — The left navigation sidebar. Accepts `activeLink` as a Thymeleaf parameter. Sets `class="nav-item active"` on the matching link using `th:classappend`.

> **CRITICAL:** Never define CSS in a `<head>` tag on a page that uses `<head th:replace="...">`. The `th:replace` directive **replaces the entire `<head>` element** with the fragment. Any `<style>` or `<link>` tags you put inside the local `<head>` will be discarded. Put page-specific CSS inside `<style>` tags within the `<body>`, **after** the `<head th:replace>` line.

#### The CSS System — `theme-eac.css`

Located at `src/main/resources/static/css/theme-eac.css`.

The CSS design system uses CSS custom properties (variables) defined on `:root`. Key variables:

| Variable | Purpose |
|---|---|
| `--primary-color` | EAC crimson red — used for sidebar active states, buttons, badges |
| `--bg-primary` | Main background |
| `--bg-secondary` | Sidebar background |
| `--bg-tertiary` | Table header, card header |
| `--text-color` | Primary text |
| `--text-muted` | Secondary/dimmed text |
| `--border-color` | Borders, dividers |

Key layout classes:

| Class | Description |
|---|---|
| `.app` | Root flex container: `display: flex; flex-direction: column; height: 100vh` |
| `.body-wrapper` | Flex row: `display: flex; flex: 1; overflow: hidden` |
| `.sidebar` | Fixed-width nav panel, scrollable |
| `.main` | `flex: 1; overflow-y: auto; padding: 1.5rem` — the scrolling content area |
| `.topbar` | Fixed-height top bar |
| `.card` | Content card with shadow + border-radius |
| `.table-eac` | Styled table with `border-collapse: collapse`, zebra rows |
| `.status-badge` | Pill badge; modified by appending `.enrolled`, `.inactive`, `.waitlist` |
| `.btn` | Base button; variants: `.btn-primary`, `.btn-ghost` |
| `.page-header` | Flex row with page title + action buttons |
| `.stat-grid` | CSS Grid for KPI stat cards on dashboard |

#### Pages Migrated in This Sprint

All of the following were migrated from a legacy Bootstrap-based or ad-hoc layout to the unified pattern above:

| Template File | Route | activeLink | Notes |
|---|---|---|---|
| `dashboard.html` | `GET /` | `dashboard` | Stat grid, pending approvals table, quick-action buttons |
| `admin_term_fees.html` | `GET /admin/term-fees` | `term-fees` | Fee admin form, import controls, readiness summary |
| `admin_users.html` | `GET /admin/users` | `users` | User table, `<dialog>`-based edit modals |
| `admin_settings.html` | `GET /admin/settings` | `settings` | System settings form |
| `admin_scholarships.html` | `GET /admin/scholarships` | `scholarships` | Scholar list + grade-unlock controls |
| `admin_approvals.html` | `GET /admin/approvals` | `grades` | Grade change requests queue |
| `admin_admission_acceptance.html` | `GET /admin/admission-acceptance` | `admissions` | Applicant review + acceptance workflow |
| `admin_classes.html` | `GET /admin/classes` | `classes` | Curriculum Offerings view with filter pills |

The remaining templates (`admin_class_scheduling.html`, `admin_curriculum.html`, `admin_student_manager.html`, `admin_enrollment.html`, `admin_faculty_load.html`, `grades_sheet.html`, etc.) were migrated in prior sessions or are not yet migrated — verify individually.

#### The `<head>` Bug — What It Was & How To Identify Recurrence

During the migration sprint, several pages had broken layouts where the sidebar would not appear and no styling was visible. The root cause was that these pages had originally been using this pattern (which was **wrong**):

```html
<!-- WRONG — double-head pattern (causes layout failure) -->
<head>
    <title>Page Title</title>
    <th:block th:replace="~{fragments/layout :: head}"></th:block>
    <style>/* local CSS */</style>
</head>
<body>
<div class="app">
    <th:block th:replace="~{fragments/layout :: topbar}"></th:block>
```

The `<th:block th:replace>` inside an existing `<head>` injects the fragment content but does NOT replace the outer `<head>`. This means the stylesheet reference from the fragment gets injected correctly, but the **surrounding structure** means the browser has already processed a `<head>` block and the `theme-eac.css` class-based layout chain never fires correctly in some browser rendering paths.

The correct fix is the pattern shown in section 3.3 above — `<head th:replace="...">` as the actual `<head>` element itself, with no wrapping outer `<head>`.

If you add a new page and the sidebar/topbar is missing despite using the fragment, immediately check:
1. Is the `<head>` tag `<head th:replace="~{fragments/layout :: head}">` (correct) or `<head><th:block th:replace="...">(wrong)?
2. Is `<div class="app">` the first element inside `<body>` (correct) or inside some other wrapper (wrong)?

---

## 4. Backend Bug Fixes Made During This Sprint

### 4.1 `ClassSchedule.java` — `course_code` Column Mapping Removal

**File:** `academic/ClassSchedule.java`  
**Symptom:** `GET /admin/approvals` threw HTTP 500 with Hibernate exception: `Unknown column 'course_code' in 'class_schedules'`. The Approvals page could not load at all.  
**Root Cause:** `ClassSchedule` had a `@Column(name = "course_code")` field mapped, but the physical `class_schedules` table in the database does NOT have a `course_code` column. Hibernate attempted to SELECT this column on entity load.  
**Fix:** Changed `@Column(name = "course_code")` to `@Transient`. The field remains in the entity (used programmatically in service code) but is no longer mapped to a database column.  
**Also removed:** `findByCourseCode(String courseCode)` from `ClassScheduleRepository` — it was unused and was the only consumer of the phantom column.

**Current state of `ClassSchedule.java` fields:**
```java
@Transient
private String courseCode;  // populated by service layer, NOT from DB
```

### 4.2 `admin_users.html` — SpEL Boolean Type Error on `is_active`

**File:** `templates/admin_users.html`  
**Symptom:** `GET /admin/users` threw HTTP 500 (Thymeleaf rendering exception on iteration) when displaying the user table.  
**Root Cause:** The `sys_users.is_active` column is a `TINYINT` in MySQL. When retrieved via raw JDBC into a `Map<String, Object>`, the value is a Java `Integer` (0 or 1), not a Java `Boolean`. Thymeleaf's Spring Expression Language evaluates `${u.is_active}` as falsy when it's the Integer `0`, but when evaluated as a boolean expression, it can throw a type conversion error in stricter Thymeleaf versions.  
**Fix:** Changed both SpEL expressions to use explicit integer equality comparison:
```html
<!-- BEFORE (broken): -->
th:classappend="${u.is_active ? 'enrolled' : 'inactive'}"
th:text="${u.is_active ? 'Active' : 'Inactive'}"

<!-- AFTER (correct): -->
th:classappend="${u.is_active == 1 ? 'enrolled' : 'inactive'}"
th:text="${u.is_active == 1 ? 'Active' : 'Inactive'}"
```
**General rule:** When referencing `TINYINT` columns from JDBC `queryForList` / `queryForMap`, always compare with `== 1` or `== 0`. Never use the bare value as a boolean in Thymeleaf SpEL.

---

## 5. Scope Boundaries — What This System Is and Is Not

The following are explicitly **out of scope** for the Registrar WAR and must not be reintroduced:

| Feature | Why Out of Scope |
|---|---|
| Basic Education programs (HS, JHS, SHS) | System handles college students only; Basic Ed filtered at query level |
| Payment collection/capture | Handled externally by the Cashier/Enrollment gateway; Registrar only **sets** fees |
| Direct student ledger write operations | Ledger writes belong to `enrollment3/`; Registrar reads ledger for display only |
| Generating tuition receipts | Enrollment/Cashier domain |

---

## 6. Known Issues and Open Work

### 6.1 Historical Ledger Mismatch (Inherited — Not Introduced This Sprint)

Documented in full in `AGENT_HANDOVER_JUN2026.md` §8. Summary:  
When `getStudentLedgerHistoryForViewTerm()` is called for a past term after term-advance, it recomputes fees from current enlistments instead of reading from a frozen snapshot. This can produce a historical balance of `₱0` even when the student owed money at the time of close.

Planned fix: `student_term_closes` snapshot table + modify historical ledger read path to use the snapshot when available.

### 6.2 Dashboard Stats Are Hardcoded Placeholder Values

`dashboard.html` stat cards (students enrolled, pending approvals, etc.) are currently hardcoded placeholder numbers in the Thymeleaf template. They need to be connected to real controller model attributes. The controller that serves `GET /` is `enrollment/EnrollmentController.java` (check the `@GetMapping("/")` method for what model attributes it puts in).

### 6.3 Thymeleaf `spring.thymeleaf.cache`

`application.properties` does **not** currently contain `spring.thymeleaf.cache=false`. Thymeleaf defaults to `true` in production-mode builds. If template changes are not reflecting after restart, add:
```properties
spring.thymeleaf.cache=false
```
for local development. Remove or set to `true` before production deployment.

### 6.4 External Gateway URL is Hardcoded

The `Open Enrollment System (External)` button in `admin_student_manager.html` points to a hardcoded URL. This should be externalized to a Spring `@Value`-injected property or an `application.properties` entry like `registrar.external.enrollment-url`.

### 6.5 `admin_term_fees.html` — `BUSINESS_LOGIC_MASTER.md` Documents Fewer Fee Columns Than Actual

The BUSINESS_LOGIC_MASTER.md §3 DDL example shows 5 misc columns and 3 other columns. The actual `ProgramFeeSetting.java` entity has **16 misc columns and 7 other columns** (see Section 3.1 above for the complete list). The master doc's DDL snippet is illustrative only — treat `ProgramFeeSetting.java` as the ground truth for what columns exist.

---

## 7. Safe Testing Procedure

1. Ensure MySQL is running and `eacdb` (or `registrar_sandbox`) exists.
2. Run `mvn clean spring-boot:run` with the appropriate `SPRING_DATASOURCE_URL` env var.
3. Watch startup logs — a successful boot prints `>>> SYSTEM READY: Passwords for 'admin' and 'prof' synced to 1234.`
4. Log in at `http://localhost:8083/registrar` with username `admin`, password `1234`.
5. Navigate to each migrated page and verify:
   - Sidebar is visible and the correct nav item is highlighted.
   - Page content renders without error.
   - Check browser DevTools console for 404s on CSS/JS assets.
6. Navigate to `/admin/approvals` — should load without 500 (the `ClassSchedule` bug is fixed).
7. Navigate to `/admin/users` — user table should render correctly; `is_active` badges should show "Active"/"Inactive" correctly.
8. Navigate to `/admin/term-fees` — verify semester dropdown locks when a real academic term is selected; verify it unlocks when `-- Global Fallback Templates --` is selected.

---

## 8. File Reference Index

| File | Package/Path | What It Does |
|---|---|---|
| `ProgramFeeSetting.java` | `finance/` | JPA entity for `program_fee_settings`; `getFee()`/`setFee()` dispatch |
| `ProgramFeeSettingRepository.java` | `finance/` | Spring Data JPA queries; `findBestMatch` is the core read path |
| `TermFeeAdminService.java` | `finance/` | All fee business logic; `KNOWN_FEES` registry; `saveFeeRate`, `importFeesFromSpecificTerm`, `buildTermReadinessSummary` |
| `TermFeeAdminController.java` | `finance/` | HTTP endpoints for `/admin/term-fees` |
| `ScholarEnrollmentService.java` | `scholarship/` | Fee calculation delegation to `TermFeeAdminService`; term close; outstanding balance |
| `AcademicGradingService.java` | `academic/` | `triggerTermTransition()`; Basic Ed filter applied here |
| `JaypeeIntegrationService.java` | `jaypee/` | Cross-system drop delegate; Basic Ed filter applied here |
| `ClassSchedule.java` | `academic/` | `@Transient courseCode` — field exists but is NOT mapped to DB column |
| `ClassScheduleRepository.java` | `academic/` | `findByCourseCode` removed; `findBySectionId`, `findByFacultyId`, `updateIsUnlockedByScheduleId` remain |
| `layout.html` | `templates/fragments/` | Defines `head`, `topbar`, `sidebar(activeLink)` fragments |
| `theme-eac.css` | `static/css/` | Complete EAC design system — CSS variables, layout, components |
| `dashboard.html` | `templates/` | activeLink: `dashboard` |
| `admin_term_fees.html` | `templates/` | activeLink: `term-fees` |
| `admin_users.html` | `templates/` | activeLink: `users`; `<dialog>` modals; `is_active == 1` SpEL fix |
| `admin_settings.html` | `templates/` | activeLink: `settings` |
| `admin_scholarships.html` | `templates/` | activeLink: `scholarships` |
| `admin_approvals.html` | `templates/` | activeLink: `grades` |
| `admin_admission_acceptance.html` | `templates/` | activeLink: `admissions` |
| `admin_classes.html` | `templates/` | activeLink: `classes` |
| `application.properties` | `src/main/resources/` | Port 8083, context `/registrar`, DB `eacdb`, JPA DDL none |

---

*Last updated: 2026-06-05 — Fee Architecture Overhaul + Full UI Standardization Sprint.*
