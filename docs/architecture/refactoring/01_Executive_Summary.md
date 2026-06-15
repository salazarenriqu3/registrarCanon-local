# Executive Summary: Spring Modulith Architecture Overhaul

## The Imperative for Change

The Registrar system previously suffered from deep architectural coupling, primarily driven by cyclic dependencies and cross-module database manipulation using raw `JdbcTemplate` queries. Classes in the `academic`, `scholarship`, and `enrollment` modules were tightly intertwined, making the system brittle, difficult to test, and risky to upgrade.

The most severe manifestation of this was a `BeanCurrentlyInCreationException` thrown by Spring at startup. The dependency graph `academic → scholarship → academic` created a circular reference that the Spring IoC container could not resolve, and was only temporarily masked by a `@Lazy` annotation workaround — which deferred the problem rather than solving it.

## The Objective

To prepare the system for the integration of the Model Context Protocol (MCP) and AI capabilities, we needed a rigorously structured backend. We chose the **Spring Modulith** architectural pattern. Spring Modulith enforces logical boundaries between Java packages, treating them as independent, encapsulated modules that can only communicate through well-defined APIs or asynchronous events.

## Module Structure (Post-Refactoring)

The codebase was reorganized into the following bounded context modules, each as a distinct Java sub-package under `com.iuims.registrar`:

| Module | Package | Responsibility |
|---|---|---|
| `core` | `com.iuims.registrar.core` | Shared entities, repositories, and utilities (`SysUser`, `Student`, `Grade`, `DatabaseSetupService`, etc.) |
| `academic` | `com.iuims.registrar.academic` | Grading, term management, class scheduling, academic policies |
| `scholarship` | `com.iuims.registrar.scholarship` | Scholar enrollment, financial ledgers, scholarship types |
| `enrollment` | `com.iuims.registrar.enrollment` | Student enlistment, block enrollment, COR/COG |
| `curriculum` | `com.iuims.registrar.curriculum` | Programs, curriculum templates, course catalog |
| `finance` | `com.iuims.registrar.finance` | Term fees, charge types, fee templates |
| `faculty` | `com.iuims.registrar.faculty` | Faculty load and scheduling |
| `admission` | `com.iuims.registrar.admission` | Applicant status sync, admission finance |
| `jaypee` | `com.iuims.registrar.jaypee` | JRU-specific integration service |
| `portal` | `com.iuims.registrar.portal` | HTTP controllers (Spring MVC layer, no business logic) |
| `config` | `com.iuims.registrar.config` | Spring Security, web configuration |

## Key Accomplishments

Our architectural overhaul successfully modernized the system through three major strategic shifts:

1. **Eradication of Cyclic Dependencies via Events**: We replaced direct method calls between domain services (which caused `academic` to depend on `scholarship` and vice versa) with Spring Application Events (`TermTransitionEvent`). The `@Lazy` workaround was removed entirely.

2. **JPA Migration for Data Integrity**: We systematically eliminated all raw SQL mutation queries in favor of Spring Data JPA. This provides type safety, prevents SQL injection, and ensures that modules only modify data they strictly own through managed entities.

3. **Strict Bounded Contexts**: Modules now respect their bounded contexts. The `AcademicGradingService`, for instance, no longer mutates the `sys_users` table directly via SQL. Instead, it relies on the `core` module's `SysUserRepository` and `StudentRepository` to manage user states appropriately.

## Deliberate Design Decision: CQRS-Lite for Read Operations

> [!NOTE]
> Read-only aggregate queries (`db.queryForList(...)`) were **deliberately left as raw JDBC** in `AcademicGradingService`. This is an intentional CQRS-lite (Command Query Responsibility Segregation) pattern: complex multi-table read projections (e.g., `getCoursesWithSections`, `getStudentAcademicHistory`) are not efficiently expressible as JPA entity graphs without introducing N+1 query problems or heavy `@EntityGraph` configurations. Raw JDBC reads are fast, read-only, and do not mutate state — they carry none of the architectural risks of raw JDBC writes.

## The Result

The system is now structurally decoupled. The Spring context initializes without errors, tests compile and run independently per domain, domain logic is strongly typed, and we have a resilient foundation that is perfectly primed for exposing `@Tool` annotations to AI assistants securely.
