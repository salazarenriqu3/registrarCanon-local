# Phase 4: Model Context Protocol (MCP) Integration Plan

## Context: Why MCP Came After the Refactoring

Phases 1–3 (architectural refactoring) were a prerequisite for MCP integration. The `@Tool` annotation exposes Java methods to AI agents. If those methods contained raw SQL (`db.update(...)`), an AI agent could indirectly trigger arbitrary database mutations with no domain validation. Only after fully migrating all mutations to JPA was it safe to expose any method as an MCP tool.

---

## Architectural Changes

### 1. Dependency Integration

We integrated **Spring AI's official MCP Server starter** via the Spring Milestones repository.

#### Dependency Resolution History

> [!IMPORTANT]
> The stable Spring AI `1.0.0-M5` release was attempted first. It failed dependency resolution due to incompatible transitive dependencies with Spring Boot 3.2.1. After investigation, we switched to the `1.1.0-M1-PLATFORM-2` milestone release, which resolved cleanly.

**Additions to `pom.xml`:**

```xml
<!-- Spring Milestones repository (required for pre-release Spring AI) -->
<repository>
    <id>spring-milestones</id>
    <url>https://repo.spring.io/milestone</url>
</repository>

<!-- Spring AI BOM for consistent dependency management -->
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.ai</groupId>
            <artifactId>spring-ai-bom</artifactId>
            <version>1.1.0-M1-PLATFORM-2</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<!-- MCP Server Starter (WebMVC/SSE transport) -->
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-starter-mcp-server-webmvc</artifactId>
</dependency>
```

**Why `webmvc` and not `webflux`?** The registrar application runs on an embedded Tomcat servlet container (Spring MVC). The `webflux` variant requires a reactive Netty runtime. Using `webmvc` allows SSE streaming without introducing a full reactive stack change.

---

### 2. Protocol Configuration

MCP servers can expose tools over two transports:
- **STDIO**: Used when the MCP server is a child process managed by a local client (e.g., Claude Desktop launching a jar as a subprocess).
- **HTTP/SSE**: Used when the MCP server is a running web service. Clients connect via HTTP and receive a Server-Sent Events stream.

Since this is a web application with an existing Tomcat runtime, **HTTP/SSE** was the correct choice.

**Addition to `application.properties`:**
```properties
spring.ai.mcp.server.webmvc.enabled=true
```

This single property activates:
1. The SSE endpoint (`/sse`) that MCP clients connect to for handshaking.
2. The message endpoint (`/mcp/message`) for JSON-RPC tool call payloads.
3. Automatic registration of all `@Tool`-annotated methods from Spring-managed beans.

---

### 3. Tool Annotation Strategy

The `@Tool` annotation (`org.springframework.ai.tool.annotation.Tool`) marks a method for automatic registration with the MCP server. Spring AI scans all Spring `@Service` beans for `@Tool` annotations at startup and registers them into the MCP tool registry.

#### Tool Selection Criteria

Not all methods are appropriate for MCP exposure. The criteria used:

1. **JPA-backed only**: The method must use JPA repositories for all mutations. Raw `db.update(...)` methods are explicitly excluded.
2. **Meaningful AI use case**: The method must represent a logical action an AI assistant would plausibly be asked to perform.
3. **Non-destructive preference**: Read operations are preferred. Write operations are included only when they are bounded (e.g., creating an academic term, opening a section) and carry low risk of irreversible damage.

#### Tools Exposed in `AcademicGradingService`

| Method | Annotation Description | Type |
|---|---|---|
| `getClassGrades(int scheduleId)` | `"Retrieve all grades for a specific class section"` | Read |
| `getPendingClassSubmissions()` | `"Get a list of class sections pending grade submission"` | Read |
| `getGradeChangeRequests()` | `"View pending grade change requests"` | Read |
| `addAcademicTerm(...)` | `"Create a new academic term"` | Write (bounded) |
| `openSection(...)` | `"Open a new class section for enrollment"` | Write (bounded) |

---

### 4. MCP Debug Endpoint

A lightweight HTTP endpoint was added to `AcademicController` for MCP-client diagnostic purposes:

```
GET /api/mcp/classes/{id}
```

This endpoint returns a `ClassInfoDto` (typed DTO) containing the class section's `classId`, `courseCode`, `sectionCode`, and `status`. It allows an AI agent to quickly verify class identity before invoking tools like `getClassGrades`.

---

## Security Assurance

The MCP layer has no direct database access. Every AI-invoked tool call flows through:

```
AI Agent → MCP Client → HTTP/SSE → Spring AI MCP Server
    → @Tool Method (AcademicGradingService)
        → JPA Repository (GradeRepository, ClassSectionRepository, etc.)
            → Hibernate ORM
                → MySQL Database
```

The JPA layer acts as a mandatory intermediary. Business constraints encoded in the Java domain model (entity field validation, `@NotNull`, `@Column` constraints) are automatically enforced for every AI-triggered write.
