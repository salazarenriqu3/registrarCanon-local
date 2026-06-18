# Proposal — Registrar Spring Security

Last updated: 2026-06-10  
**Status:** Proposal / implementation plan — **not implemented** — **DEFERRED** per user 2026-06-10 (too long for current sprint; accept pilot risk)  
**Parent:** `PRODUCTION_IMPLEMENTATION_PLAN.md` Phase 1A  
**Master status:** `PROJECT_STATUS_AND_ROADMAP.md`

---

## 1. Executive summary

Registrar today has **no Spring Security**. Authentication is a custom `POST /login` that stores a `Map` in `HttpSession` as `currentUser`. Authorization is **inconsistent**: most controllers only check “someone logged in,” not role. Several write APIs are **fully open**.

**Recommendation:** Add `spring-boot-starter-security` and mirror Enrollment’s proven pattern (`CustomUserDetailsService` + `SecurityFilterChain`), adapted for Registrar’s context path (`/registrar`) and route layout. Roll out in **four sub-phases** with a session bridge so we do not rewrite every controller at once.

**Estimated effort:** 3–5 dev days implementation + 1–2 days UAT regression.

---

## 2. Current state (code audit)

### 2.1 What exists today

| Piece | Registrar | Enrollment (reference) |
|-------|-----------|------------------------|
| Dependency | **None** | `spring-boot-starter-security` |
| Login | `PortalController` → `AcademicGradingService.login()` | Spring form login |
| Password hash | jBCrypt (`org.mindrot.jbcrypt`) | `BCryptPasswordEncoder` |
| User store | `sys_users` via JPA `SysUser` | `sys_users` via JPA `User` |
| Session | `currentUser` map in `HttpSession` | `SecurityContext` + session |
| URL protection | Manual per method | `SecurityFilterChain` |
| Role enforcement | **Mostly absent at URL level** | Role-based `requestMatchers` |

### 2.2 Controllers using manual session checks

11 controllers, **~84** `redirect:/login` or `currentUser == null` checks, including:

- `PortalController` — login/logout/dashboard/student pages
- `AcademicController` — grades, admin settings, class scheduling, users
- `EnrollmentController` — student manager, COR/TOR, installments
- `TermFeeAdminController`, `FinancePolicyController`
- `CurriculumController`, `CourseCatalogController`
- `AdmissionController`, `ScholarshipController`, `FacultyLoadController`, `ScholarController`

### 2.3 Known gaps (security holes)

These endpoints have **no login check** today:

| Endpoint | Risk |
|----------|------|
| `POST /api/faculty/auto-save` | Anyone can modify grade rows by `gradeId` |
| `POST /faculty/submit-class` | Anyone can submit a class for approval |
| `POST /faculty/unsubmit-class` | Anyone can unsubmit |
| `GET /api/mcp/classes/{id}` | Unauthenticated read of class info (MCP/AI integration) |
| Spring AI MCP server (`spring.ai.mcp.server.webmvc.enabled=true`) | Additional attack surface if exposed |

### 2.4 Role checks that exist (but are weak)

| Location | Check | Gap |
|----------|-------|-----|
| `PortalController` student routes | `role == "Student"` | Good for those pages only |
| `AcademicController` grade sheet | `isFacultyUser()` for readonly flag | Page loads for any logged-in user |
| `EnrollmentController` | `isAdmin` for some UI flags | **No URL block** for non-admin |
| Most `/admin/**` | Logged in only | **Student could open `/admin/settings` if logged in on Registrar** |

### 2.5 Demo-only behaviors (must change for production)

```java
// RegistrarApplication.java — runs every startup
db.update("UPDATE sys_users SET password = ? WHERE username IN ('prof', 'admin')", validHash);
```

This resets production passwords on every deploy. Must be **profile-gated** (`demo` only).

### 2.6 Faculty identity bridge (must preserve)

| `sys_users.username` | Maps to `faculty.employee_number` | Notes |
|----------------------|-----------------------------------|-------|
| `prof` | `prof.cruz` | Alias in `AcademicGradingService.facultyLoginAlias()` |
| `prof.cruz` | `prof.cruz` | Bootstrap seed creates both |
| `faculty` | `prof.garcia` | Legacy alias |

Spring Security login must accept **both** `prof` and `prof.cruz` without breaking grading class resolution.

### 2.7 Shared database impact

Both apps authenticate against **`sys_users`**. Enrollment excludes `role = 'Student'` from its `User` entity; Registrar allows all roles including Student (student self-service pages exist on Registrar).

**No schema migration required** for Phase 1 if we reuse `sys_users.username`, `password`, `role`, `is_active`.

---

## 3. Goals and non-goals

### Goals

1. **Authenticate** all non-public routes via Spring Security.
2. **Authorize** by role at URL level (match Enrollment semantics where paths overlap).
3. **Close open APIs** (grading auto-save, MCP) or require auth + role.
4. **Preserve demo UAT** behind a `demo` Spring profile.
5. **Minimize controller churn** in first merge via a `currentUser` session bridge.

### Non-goals (this proposal)

- Single sign-on / shared session cookie across Registrar and Enrollment
- OAuth2 / LDAP / Active Directory
- Enforcing `granted_permissions` JSON (future Phase 1D)
- Re-enabling CSRF on day one (match Enrollment: disabled initially; enable in follow-up)
- Changing password hashing algorithm in DB (BCrypt stays)

---

## 4. Target architecture

```text
Browser
   │
   ▼
SecurityFilterChain  (/registrar context)
   ├── permitAll: /login, /css/**, /js/**, /images/**, /error
   ├── hasRole ADMIN|REGISTRAR: /admin/**
   ├── hasRole FACULTY|ADMIN: /grades/**, /faculty/**
   ├── hasRole STUDENT: /enrollment, /my-grades, /my-load, /student/**
   ├── authenticated: /
   └── deny /api/mcp/** in prod (or ADMIN + API key)
   │
   ▼
AuthenticationSuccessHandler  → role-based redirect (/, /grades, /enrollment)
   │
   ▼
SessionBridgeFilter (custom, Phase 1B)
   └── copies SecurityContext principal → session attribute "currentUser" (Map)
   │
   ▼
Existing @Controller methods (unchanged initially)
```

### 4.1 New classes (planned)

| Class | Package | Purpose |
|-------|---------|---------|
| `SecurityConfig` | `com.iuims.registrar.config` | `SecurityFilterChain`, password encoder, handlers |
| `RegistrarUserDetailsService` | `com.iuims.registrar.security` | `UserDetailsService` loading `SysUser` |
| `RegistrarUserPrincipal` | `com.iuims.registrar.security` | Optional — exposes `user_id`, `role`, faculty alias |
| `SessionCurrentUserBridgeFilter` | `com.iuims.registrar.security` | Populates `currentUser` map for legacy controllers |
| `DemoPasswordResetRunner` | `com.iuims.registrar.config` | Moves startup password reset; `@Profile("demo")` only |

### 4.2 Dependency (`pom.xml`)

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-security</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework.security</groupId>
  <artifactId>spring-security-test</artifactId>
  <scope>test</scope>
</dependency>
```

---

## 5. Role matrix (proposed)

DB stores mixed case (`Admin`, `Faculty`, …). Normalizer converts to `ROLE_ADMIN`, `ROLE_FACULTY`, etc. (same as Enrollment `CustomUserDetailsService`).

| `sys_users.role` | Spring authority | Registrar access |
|------------------|------------------|------------------|
| `Admin` | `ROLE_ADMIN` | Full — all `/admin/**`, `/grades/**`, settings, approvals |
| `Registrar` | `ROLE_REGISTRAR` | Full admin except user password reset (optional split) |
| `Faculty` | `ROLE_FACULTY` | `/grades/**`, `/faculty/**`, dashboard → redirect grades |
| `Student` | `ROLE_STUDENT` | `/enrollment`, `/my-grades`, `/my-load`, `/student/finance` |
| `Admission` | `ROLE_ADMISSION` | `/admin/admission-*` only (if used on Registrar) |
| inactive `is_active=0` | — | Login denied |

### 5.1 URL rules (draft `SecurityFilterChain`)

Context path is `/registrar` — Spring Security 6 matches **without** context path prefix.

```java
http.authorizeHttpRequests(auth -> auth
    .requestMatchers("/login", "/css/**", "/js/**", "/images/**", "/error").permitAll()
    .requestMatchers("/admin/**").hasAnyRole("ADMIN", "REGISTRAR")
    .requestMatchers("/grades/**", "/faculty/**").hasAnyRole("FACULTY", "ADMIN", "REGISTRAR")
    .requestMatchers("/enrollment", "/my-grades", "/my-load", "/student/**").hasRole("STUDENT")
    .requestMatchers("/api/faculty/**").hasAnyRole("FACULTY", "ADMIN", "REGISTRAR")
    .requestMatchers("/api/mcp/**").hasRole("ADMIN")  // or denyAll() in prod profile
    .anyRequest().authenticated()
);
```

**Login/logout:**

```java
.formLogin(form -> form
    .loginPage("/login")
    .loginProcessingUrl("/login")
    .successHandler(registrarSuccessHandler())
    .permitAll()
)
.logout(logout -> logout
    .logoutUrl("/logout")
    .logoutSuccessUrl("/login?logout")
);
```

**Success redirect** (mirror `PortalController` dashboard logic):

| Role | Redirect |
|------|----------|
| ADMIN / REGISTRAR | `/` (dashboard) |
| FACULTY | `/grades` |
| STUDENT | `/enrollment` |

### 5.2 Disable custom `PortalController` login POST

After Phase 1A:

- Keep `GET /login` → `login.html` (or let Spring Security serve it)
- **Remove** `POST /login` handler from `PortalController` — Spring Security owns `loginProcessingUrl`
- Update `login.html` form: `th:action="@{/login}"`, fields `username` / `password` (default Spring names)

---

## 6. Implementation phases

### Phase 1A — Foundation (day 1)

| Task | Detail |
|------|--------|
| Add dependency + `SecurityConfig` | Basic chain: everything except `/login` + static assets requires auth |
| `RegistrarUserDetailsService` | Load `SysUser` by username; map role → `ROLE_*`; reject `is_active=false` |
| `BCryptPasswordEncoder` bean | Spring encoder (compatible with existing jBCrypt hashes in DB) |
| Wire form login | Replace custom POST login |
| Smoke test | `admin/1234`, `prof.cruz/1234` still work |

**Exit criteria:** Unauthenticated visit to `/admin/settings` → redirect login. No regression on login page render.

### Phase 1B — Role rules + API lockdown (day 2)

| Task | Detail |
|------|--------|
| Apply role `requestMatchers` | Table in §5.1 |
| Secure open endpoints | `/api/faculty/auto-save`, submit/unsubmit require FACULTY+ |
| MCP policy | `demo` profile: ADMIN only; `prod` profile: `denyAll()` or disable `spring.ai.mcp.server` |
| `SessionCurrentUserBridgeFilter` | After auth, set `session.setAttribute("currentUser", mapFromPrincipal)` |

**Exit criteria:** Student session cannot open `/admin/term-fees`. Auto-save returns 401/403 without faculty login.

### Phase 1C — Cleanup + demo profile (day 3)

| Task | Detail |
|------|--------|
| Move password reset | `RegistrarApplication` → `DemoPasswordResetRunner` `@Profile("demo")` |
| `application-demo.properties` | `spring.profiles.active=demo` for local UAT |
| `application-prod.properties` | MCP off, demo runner off, stricter headers (optional) |
| Begin removing redundant `if (currentUser == null)` | Optional in 1C or defer to 1D — bridge keeps them harmless |

### Phase 1D — Hardening (optional, day 4–5)

| Task | Detail |
|------|--------|
| `@PreAuthorize` on sensitive service methods | Grade save, term transition, finance policy save |
| `granted_permissions` | Parse JSON; custom `PermissionEvaluator` if business needs fine-grained |
| CSRF | Enable for POST forms; add Thymeleaf `_csrf` tokens |
| Method-level tests | `@WithMockUser(roles="FACULTY")` on controller tests |
| Remove `currentUser` bridge | Controllers inject `@AuthenticationPrincipal` |

---

## 7. `RegistrarUserDetailsService` (sketch)

```java
@Service
public class RegistrarUserDetailsService implements UserDetailsService {

    private final SysUserRepository repo;

    @Override
    public UserDetails loadUserByUsername(String username) {
        SysUser u = repo.findByUsername(username)
            .orElseThrow(() -> new UsernameNotFoundException(username));
        if (Boolean.FALSE.equals(u.getIsActive())) {
            throw new DisabledException("Account disabled");
        }
        String role = u.getRole() == null ? "STUDENT" : u.getRole().toUpperCase();
        if (!role.startsWith("ROLE_")) role = "ROLE_" + role;

        return User.builder()
            .username(u.getUsername())
            .password(u.getPassword())   // BCrypt hash from DB
            .authorities(role)
            .build();
    }
}
```

**Password verification:** Spring `DaoAuthenticationProvider` + `BCryptPasswordEncoder` works with hashes created by jBCrypt (same `$2a$` format). Validate with integration test using seeded `admin` row.

---

## 8. Session bridge (why and how)

**Why:** 80+ controller lines read `session.getAttribute("currentUser")` as a `Map` with `user_id`, `username`, `role`, etc. Rewriting all at once is high-risk before demo.

**How:** After successful authentication, a filter builds the same map shape as `AcademicGradingService.sysUserToMap()` and stores it in the session.

```java
// Pseudocode — SessionCurrentUserBridgeFilter
if (authentication != null && authentication.isAuthenticated()) {
    SysUser u = load fresh from DB or from principal;
    session.setAttribute("currentUser", sysUserToMap(u));
}
```

**Later:** Controllers migrate to `@AuthenticationPrincipal RegistrarUserPrincipal` and bridge is removed.

---

## 9. System impact analysis

### 9.1 Applications

| Area | Impact | Mitigation |
|------|--------|------------|
| **Registrar UI** | Login form may need `th:action` fix; logout URL unchanged | Test all roles |
| **Enrollment app** | **None** — separate WAR/JAR, separate security filter chain | No code change |
| **Shared `sys_users`** | Same passwords work in both apps | Document that roles are per-app URL rules |
| **Bootstrap / seeds** | No change if BCrypt hashes remain | Keep `seed_faculty_professors_and_grading.sql` |
| **Python UAT scripts** | HTTP clients must send session cookie or use form login | Update preflight auth helpers |
| **MCP / AI tools** | Break if MCP was open; needs token | Disable in prod or ADMIN-only |

### 9.2 User journeys

| Journey | Before | After |
|---------|--------|-------|
| Admin opens Settings | Works if logged in | Works; **Student blocked** |
| `prof.cruz` grades | Works | Works; APIs require FACULTY |
| `prof` login alias | Works via custom login | Must still resolve faculty classes (bridge map + existing alias logic) |
| Student self-service on Registrar | Works | Works; student blocked from `/admin/**` |
| Demo password reset | Every restart → `1234` | Only with `demo` profile |

### 9.3 Performance

Negligible — one extra filter + BCrypt verify on login only.

### 9.4 Deployment

| Environment | Profile | Notes |
|-------------|---------|-------|
| Local demo / UAT | `demo` | Password reset runner ON |
| Staging | `staging` | Real passwords; MCP optional |
| Production | `prod` | MCP off; CSRF on (if Phase 1D); no demo reset |

### 9.5 Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| BCrypt hash incompatibility | Low | Integration test on boot |
| Broken Thymeleaf forms (CSRF) | Medium if CSRF on early | Keep CSRF off until 1D |
| Faculty alias `prof` vs `prof.cruz` | Medium | UAT both logins in Session D |
| Hidden admin URLs bookmarked by wrong role | High today | Role rules fix this |
| Regression in 11 controllers | Medium | Bridge + phased rollout |

---

## 10. Testing plan

### 10.1 Automated

| Test | Type |
|------|------|
| `loadUserByUsername("admin")` | Unit |
| Login with seeded BCrypt hash | Integration (`@SpringBootTest` + `MockMvc`) |
| `/admin/settings` without auth → 302 login | `MockMvc` |
| `/admin/settings` as STUDENT → 403 | `MockMvc` |
| `POST /api/faculty/auto-save` without auth → 401/403 | `MockMvc` |
| `prof` and `prof.cruz` faculty class list not empty | Integration (existing grading tests) |

### 10.2 Manual UAT regression

Re-run from `HUMAN_UAT_CHECKLIST.md`:

| Session | Focus after security |
|---------|---------------------|
| 0 | Login both apps |
| A | Admin pages |
| D | `prof.cruz` grading + approvals |
| B | Enrollment cashier (unchanged) |

### 10.3 Negative tests

| Attempt | Expected |
|---------|----------|
| Student logs into Registrar, browse to `/admin/finance-policy` | 403 or redirect |
| curl auto-save without cookie | 401/403 |
| Wrong password 5× | (Future) lockout — not in Phase 1 |

---

## 11. Rollback strategy

1. Feature branch `feature/registrar-spring-security`.
2. If regression blocks demo: revert merge; custom login still in `PortalController` on main.
3. Bridge filter can stay behind property `registrar.security.legacy-session-bridge=true` for one release.

---

## 12. Open questions for stakeholder review

| # | Question | Recommendation |
|---|----------|----------------|
| 1 | Implement before or after panel demo? | **After** — UAT first on current build |
| 2 | Should `Registrar` role differ from `Admin`? | Same `/admin/**` for now; split later |
| 3 | CSRF in Phase 1? | **No** — match Enrollment; enable in 1D |
| 4 | MCP in production? | **Disable** unless explicitly needed |
| 5 | Keep `currentUser` bridge how long? | 1–2 releases, then remove |
| 6 | Cashier role on Registrar? | **Deny** unless business needs cashier on Registrar |

---

## 13. File change checklist (when approved)

| File | Action |
|------|--------|
| `registrar/pom.xml` | Add security dependencies |
| `registrar/.../config/SecurityConfig.java` | **Create** |
| `registrar/.../security/RegistrarUserDetailsService.java` | **Create** |
| `registrar/.../security/SessionCurrentUserBridgeFilter.java` | **Create** |
| `registrar/.../config/DemoPasswordResetRunner.java` | **Create** (move from `RegistrarApplication`) |
| `registrar/.../RegistrarApplication.java` | Remove password reset from default runner |
| `registrar/.../portal/PortalController.java` | Remove `POST /login`; keep or delegate `GET /login` |
| `registrar/.../templates/login.html` | Spring Security form fields |
| `registrar/src/main/resources/application-demo.properties` | **Create** |
| `registrar/src/main/resources/application-prod.properties` | **Create** — MCP off |
| `registrar/src/test/java/.../SecurityConfigTest.java` | **Create** |
| Controllers (11 files) | Phase 1D — remove manual checks |

---

## 14. Recommendation

| Timing | Action |
|--------|--------|
| **Now** | Approve this proposal; complete human UAT on current build |
| **After UAT sign-off** | Implement Phase 1A → 1B → 1C on a branch |
| **Before production** | Phase 1D + ops items in `PRODUCTION_IMPLEMENTATION_PLAN.md` |

Registrar Spring Security is the **highest-value production gap** and should be the first implementation stream after demo UAT — not a blocker for panel testing today.
