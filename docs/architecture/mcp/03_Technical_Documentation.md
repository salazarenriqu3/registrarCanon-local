# MCP Integration: Technical Agent Guide

This document is specifically authored to provide technical context for **future AI agents** operating within this repository. It covers how the MCP server works, how tools are registered, how to extend the tool set, and what hard constraints must be respected.

---

## 1. Framework and Version

The application uses **Spring AI MCP Server (WebMVC transport)**:

- **Artifact**: `org.springframework.ai:spring-ai-starter-mcp-server-webmvc`
- **Version**: `1.1.0-M1-PLATFORM-2` (via Spring Milestones BOM)
- **Transport**: HTTP with Server-Sent Events (SSE)

> [!IMPORTANT]
> Do NOT attempt to upgrade to a newer Spring AI version without verifying compatibility with Spring Boot 3.2.1 and the current `pom.xml`. The `1.0.0-M5` version failed dependency resolution during the integration attempt. The current version was specifically chosen because it resolved cleanly. Always check the Spring Milestones repo before changing the version.

---

## 2. How Tool Registration Works

Spring AI scans the Spring Application Context at startup for beans containing methods annotated with `@Tool`. These methods are registered into a `ToolCallbackProvider` and exposed via the MCP server's tool discovery endpoint.

**The registration flow:**

```
@SpringBootApplication startup
    → Spring AI auto-configuration activates
    → Scans all @Service/@Component beans for @Tool annotations
    → Builds JSON schema for each tool from method signature + @Tool description
    → Exposes schema at /sse on first MCP client handshake
```

**No explicit registration code is needed.** Simply annotating a method on a Spring-managed bean is sufficient for automatic registration.

---

## 3. How to Add a New MCP Tool (Step-by-Step)

To expose a new Java method to AI agents:

### Step 1: Verify the method is JPA-backed
```java
// ✅ SAFE to annotate — uses JPA repository
public List<SomeDto> getScholarshipHolders() {
    return scholarRepository.findByActiveScholarship(true).stream()
        .map(this::toDto).collect(Collectors.toList());
}

// ❌ DO NOT annotate — uses raw JDBC
public List<Map<String,Object>> getScholarshipHolders() {
    return db.queryForList("SELECT * FROM scholarships WHERE ...");
}
```

### Step 2: Add the `@Tool` annotation with a precise description
```java
import org.springframework.ai.tool.annotation.Tool;

@Tool(description = "Retrieve all currently active scholarship holders with their scholarship type and discount percentage")
public List<ScholarSummaryDto> getActiveScholarshipHolders() {
    // implementation
}
```

**Description writing guide:**
- Be specific about what is returned (e.g., not just "get scholars" but "retrieve all currently active scholarship holders")
- Mention key parameters if present (e.g., `"for a given student ID"`, `"for the currently active term"`)
- The LLM uses this description verbatim to decide when to call the tool — precision matters

### Step 3: Ensure the service bean is in the Spring context
The class must be a `@Service` or `@Component`. Spring AI only scans managed beans.

### Step 4: Restart the application
Tools are registered at startup. A running instance must be restarted to pick up new `@Tool` annotations.

---

## 4. Tool Naming Convention

Spring AI derives the tool name from the Java method name (camelCase converted to the JSON schema tool name). The tool name an AI client sees is the **exact Java method name**. Keep method names descriptive:

| Method Name | AI Sees |
|---|---|
| `getClassGrades` | `getClassGrades` |
| `getPendingClassSubmissions` | `getPendingClassSubmissions` |
| `addAcademicTerm` | `addAcademicTerm` |

Avoid changing `@Tool`-annotated method names without coordinating with any AI client configurations that reference the tool by name.

---

## 5. Runtime MCP Endpoints

| Endpoint | Protocol | Purpose |
|---|---|---|
| `GET /sse` | HTTP SSE | Client connection and handshake. AI client opens a persistent SSE stream here |
| `POST /mcp/message` | HTTP JSON-RPC 2.0 | Tool call payloads arrive here. Client sends `{"method":"tools/call","params":{"name":"getClassGrades","arguments":{"scheduleId":42}}}` |
| `GET /api/mcp/classes/{id}` | HTTP REST | Custom diagnostic endpoint returning `ClassInfoDto`. Not part of MCP spec, but useful for AI agents to verify class identity |

---

## 6. Absolute Constraints: What Must NEVER Be Annotated

> [!CAUTION]
> The following categories of methods are **permanently off-limits** for `@Tool` annotation, regardless of any future request:

| Category | Example Methods | Reason |
|---|---|---|
| Authentication | `login(String, String)` | AI must never be able to authenticate as a user |
| Password management | `resetPassword(int)`, `createUser(...)` | Security-sensitive; requires human authorization |
| Irreversible high-impact | `triggerTermTransition(String)` | Transitions thousands of student records; no rollback |
| Grade approvals | `approveGradeChange(int)`, `rejectGradeChange(int)` | Financial and academic consequence; human-gated |
| Raw JDBC mutations | Any method containing `db.update(...)` | AI must only operate through the JPA domain model |
| Destructive deletes | `deleteUser(int)`, `closeSection(int)` | No recovery path; must remain human-controlled |

---

## 7. Troubleshooting

### Tool not appearing in AI client
- Verify the class is a Spring `@Service` or `@Component`.
- Verify the method is `public` (Spring AI does not register private/package-private methods).
- Verify `spring.ai.mcp.server.webmvc.enabled=true` is in `application.properties`.
- Restart the application after adding the annotation.

### AI calling tool with wrong argument type
- Check the Java method parameter types. Spring AI generates the JSON schema from the parameter types.
- Use primitive types (`int`, `String`, `boolean`) or simple value types. Avoid complex nested objects for tool parameters.

### Dependency resolution errors when updating Spring AI version
- Always use the Spring AI BOM. Do not specify versions on individual Spring AI artifacts.
- Verify the new version is available at `https://repo.spring.io/milestone`.
- Check Spring Boot version compatibility in the Spring AI release notes before upgrading.
