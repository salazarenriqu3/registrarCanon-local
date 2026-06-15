# Production Readiness Architecture Checklist

This document provides architectural recommendations to secure, scale, and fortify your Java web application (Spring Boot 3.x, JDBC, MySQL) for a high-concurrency production deployment on an Apache Tomcat Servlet container.

---

## 1. Concurrency & Thread Management
> **Goal:** Safely handle simultaneous requests without starving out resources, blocking the JVM footprint, or creating race conditions within logic.

### 🍅 Tomcat Tuning
By default, Tomcat provides 200 maximum worker threads. Under heavy load, this can quickly deplete. Alternatively, unbounded queues can cause OutOfMemory errors.
- **Customize Thread Pools:** Add these to `application.properties` to scale Tomcat for production:
  ```properties
  server.tomcat.threads.max=400
  server.tomcat.threads.min-spare=50
  server.tomcat.accept-count=200 # Max queued requests before rejecting
  server.tomcat.connection-timeout=20000 
  ```

### ☕ Immutable & Stateless Services
- **Stateless Beans:** Verify that every `@Service` and `@RestController` class has **no instance-level state variables** (e.g., `private int counter`). These Spring components are singletons; mutating instance variables across simultaneous HTTP requests causes severe race conditions and data bleeding between users.
- **Local Scope:** Always pass context as method arguments or inside local variables.

### ⏱️ Asynchronous Processing
- Use `@Async` for long-running, non-blocking tasks like bulk-processing curriculums or sending emails. Do not tie up Tomcat HttpWorker threads on slow I/O.
- Configure a custom `TaskExecutor` ThreadPool to restrict the number of background threads running at once.

---

## 2. Database & Transaction Management
> **Goal:** Handle concurrency effectively without database deadlocks and ensure ACID compliance.

### 🗃️ Connection Pooling
Spring Boot 3 natively utilizes **HikariCP**, an extremely fast connection pool library. However, default settings should be tuned:
- **Optimal Pool Size:** Database connections are expensive. A very large pool slows down the DB. Use: `Connections = ((core_count * 2) + effective_spindle_count)`. A common start for MySQL is typically `10` or `20`, not `100`.
- **Property Settings:**
  ```properties
  spring.datasource.hikari.maximum-pool-size=25
  spring.datasource.hikari.minimum-idle=5
  spring.datasource.hikari.connection-timeout=30000
  spring.datasource.hikari.max-lifetime=1800000
  ```

### 🔁 ACID Compliance & Transactions
- **`@Transactional` Application:** Ensure all complex services modifying database state (e.g., `enrollStudent`, `submitGrades`) are annotated with `@Transactional`. If an exception is thrown midway, this guarantees all partial DB writes rollback automatically.
- **Race Condition Prevention:** For highly competitive access (e.g., enrolling in a class with 3 slots left and 10 students trying simultaneously):
  - **Optimistic Locking:** Introduce a `version` column in the database schema. If the version modified by Thread B is older than Thread A, throw a retryable error.
  - **Pessimistic Locking:** Use `SELECT ... FOR UPDATE` directly in your Spring JDBC Queries to lock the database row physically until the transaction completes.

### 🚀 JDBC Batch Operations
- Never insert records inside a simple loop constraint for tasks like batch ledger generation. Use Spring's `JdbcTemplate.batchUpdate()` to reduce heavy network chatter and load records synchronously in database-level batches.

---

## 3. Performance & Resource Optimization
> **Goal:** Memory management, low latency, and scaling for heavy student load limits.

### 🧮 JVM Heap & Garbage Collection
- **Heap Size Allocation:** When running the packaged application or `.war` on the server JVM, explicitly set minimum and maximum heap sizes to avoid dynamic allocation overhead.
  ```bash
  export JAVA_OPTS="-Xms2048m -Xmx4096m -XX:+UseG1GC"
  ```
  *(Java 17 uses G1 Garbage Collection by default, providing superior latency for heavily concurrent web servers).*

### 📁 Memory Safe Excel/Data Parsing
- **Apache POI Warnings:** Your project uses `poi-ooxml`. Using standard `XSSFWorkbook` instances parses the sheer XML of large spreadsheets directly into RAM, which is the #1 cause of `OutOfMemoryErrors`.
  - **Fix:** Refactor any excel parsers in `CurriculumSeederService` to use **`SXSSFWorkbook`** (Streaming API for XML that flushes data dynamically to local disks instead of retaining it in Heap memory).

### ⚡ Caching Strategies
- Enable Spring `@EnableCaching`.
- Add `@Cacheable` over methods that fetch heavy, immutable data—like Curriculum lists, standard Semesters, and Program parameters. This prevents querying the MySQL system entirely for heavily repeated requests.

### 🔍 Database Indexing
- Perform `EXPLAIN` analysis on your queries. Add MySQL `INDEX` attributes for heavily repeated `WHERE` and `JOIN` filters, specifically keys like `student_id`, `schedule_id`, and `semester_id`.

---

## 4. Security Best Practices
> **Goal:** Secure the deployment, prevent manipulation of transactions, and ensure payload integrity.

### 📦 WAR Packaging configuration
To safely deploy to a shared Tomcat environment:
1. In your `pom.xml`, set packaging to war: `<packaging>war</packaging>`
2. Exclude embedded tomcat from colliding:
    ```xml
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-tomcat</artifactId>
        <scope>provided</scope>
    </dependency>
    ```
3. Update your Application runtime root class to extend `SpringBootServletInitializer`.

### 🔏 Defeating Transaction Tampering (XSS / ID spoofing)
- **Zero Trust Hidden Elements:** Never trust database Primary IDs submitted via hidden HTML form inputs (`<input type="hidden">`). A student can use DevTools to change a `target_student_id` to tamper with another's grades.
  - **Fix:** Rely exclusively on Secure Session/JWT payload IDs for actions related to the logged-in user. Re-validate authorizations server-side.
- **SQL Injection Safety:** Ensure `JdbcTemplate` usages exclusively rely on `?` bind variables or `NamedParameterJdbcTemplate`. Absolutely no string concatenation (`+ name +`) inside of SQL strings.
- **Passwords:** Your `jbcrypt` implementation is good. Consider using a BCRYPT work factor of `12` or `14` if maximum latency tolerance permits.

### 🛡️ Spring Security integration
- If not already added, install `spring-boot-starter-security`.
- Enable **CSRF (Cross-Site Request Forgery)** protection for all state-changing endpoints (POST/PUT).
- Introduce Security Headers: `Content-Security-Policy (CSP)`, `X-Frame-Options: DENY` (To prevent Clickjacking of sensitive actions like fee payments), and strict `HTTPS/SSL` enforcement.
