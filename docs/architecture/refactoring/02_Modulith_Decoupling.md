# Modulith Decoupling: Event-Driven Architecture

## The Problem: Cyclic Dependencies

Before the refactoring, the Spring Boot application operated as a monolithic "Big Ball of Mud". The most prominent architectural violation was a cyclic dependency between the `academic` module and the `scholarship`/`enrollment` modules.

### The Dependency Chain
```
AcademicGradingService (academic)
    └── calls → ScholarEnrollmentService.forwardBalancesToNextTerm()
                    └── calls → AcademicGradingService (back to start — CYCLE!)
```

Specifically:
- `AcademicGradingService` (in `academic`) triggered term transitions and had to directly call `ScholarEnrollmentService` to forward student financial balances.
- `ScholarEnrollmentService` (in `scholarship`) needed to call back into academic methods for student state resolution.
- This resulted in Spring throwing `BeanCurrentlyInCreationException` during application startup. The cycle was temporarily masked with a `@Lazy` annotation but never resolved architecturally.

### Why `@Lazy` Is Not a Solution

The `@Lazy` annotation tells Spring to defer the creation of a bean until first use, avoiding the circular dependency at startup. However:
- It defers the problem, not eliminates it. The cycle still exists at runtime.
- It makes dependency graphs invisible and harder to audit.
- Spring Modulith's modularity enforcement would flag it as a boundary violation.
- Any future restructuring would risk reactivating the `BeanCurrentlyInCreationException`.

## The Solution: Asynchronous Domain Events

We resolved this by adopting an Event-Driven Architecture leveraging Spring's `ApplicationEventPublisher`.

### The TermTransitionEvent

We defined a plain Java record in the `academic` package to carry all the data that downstream modules need when a term transitions:

```java
// com.iuims.registrar.academic.TermTransitionEvent
public record TermTransitionEvent(
    String studentNumber,
    String newTermCode,
    java.util.concurrent.atomic.AtomicInteger debtCounter
) {}
```

### Publishing the Event

Inside `AcademicGradingService.triggerTermTransition()`, instead of holding a direct reference to `ScholarEnrollmentService`, we publish the event. The `academic` module only knows about `ApplicationEventPublisher` — a Spring core interface, not a domain dependency:

```java
@Autowired
private ApplicationEventPublisher eventPublisher;

// Inside triggerTermTransition():
for (SysUser student : eligibleStudents) {
    eventPublisher.publishEvent(
        new TermTransitionEvent(student.getUsername(), targetDbTermCode, debtCounter)
    );
}
```

### Consuming the Event

Inside `ScholarEnrollmentService`, an `@EventListener` method was added to independently handle the financial forwarding logic. This method is called synchronously by Spring's event multicaster after the publisher fires:

```java
@EventListener
public void onTermTransition(TermTransitionEvent event) {
    forwardBalancesToNextTerm(
        event.studentNumber(),
        event.newTermCode(),
        event.debtCounter()
    );
}
```

### Result: Unidirectional Dependency Graph

```
academic ──publishes──► TermTransitionEvent ◄──listens── scholarship
```

The `academic` module has **zero knowledge** of the `scholarship` module. The `scholarship` module listens passively. There is no import of any `scholarship` class from within `academic`.

## Term Transition Audit Trail

Every term transition attempt is recorded in the `term_transition_audit` table via the `recordTermTransitionAudit()` method in `AcademicGradingService`. This ensures that even if a term transition partially fails (e.g., the readiness check fails), there is a persisted record of:
- The requested term code
- The target database term code
- Whether the transition succeeded
- How many students were advanced
- How many debt records were forwarded
- Any error message if the transition was blocked

## Why This Matters for Extensibility

By relying on events rather than direct method invocations:

- **New modules can subscribe freely**: If a future `notifications` module needs to send an email to each student when a term transitions, it can simply add `@EventListener onTermTransition(TermTransitionEvent e)` — **zero changes required in the `academic` module**.
- **Modular testing is possible**: Each module's test suite can run independently, importing only its own service under `@DataJpaTest`, without needing the other module to be present in the Spring context.
- **Spring Modulith validation passes**: The inter-module communication now uses the approved `ApplicationEvent` channel, which is the sanctioned cross-module communication primitive in Spring Modulith.
