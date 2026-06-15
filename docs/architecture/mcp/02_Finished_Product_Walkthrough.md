# MCP Integration: Finished Product Walkthrough

## What Was Integrated

The `registrar` Spring Boot service is now a fully operational MCP Server. AI agents can connect to the running application, discover its tools via a JSON schema handshake, and invoke Java business methods directly — all through the standardized Model Context Protocol.

---

## Integration Summary

### 1. Framework: Spring AI MCP Server

- **Dependency**: `org.springframework.ai:spring-ai-starter-mcp-server-webmvc` version `1.1.0-M1-PLATFORM-2`
- **Repository**: Spring Milestones (`https://repo.spring.io/milestone`)
- **Transport**: HTTP with Server-Sent Events (SSE)
- **Activation property**: `spring.ai.mcp.server.webmvc.enabled=true`

### 2. Active MCP Endpoints (at Runtime)

| Endpoint | Method | Purpose |
|---|---|---|
| `/sse` | `GET` | SSE stream — MCP clients connect here to establish the session |
| `/mcp/message` | `POST` | JSON-RPC 2.0 endpoint — tool call payloads arrive here |
| `/api/mcp/classes/{id}` | `GET` | Custom debug endpoint returning a typed `ClassInfoDto` |

### 3. Registered MCP Tools

All of the following methods are live-registered in the MCP tool registry at application startup:

| Tool Name | Method | Service | Description |
|---|---|---|---|
| `getClassGrades` | `getClassGrades(int scheduleId)` | `AcademicGradingService` | Retrieve all grade rows for a class section |
| `getPendingClassSubmissions` | `getPendingClassSubmissions()` | `AcademicGradingService` | List sections pending grade approval |
| `getGradeChangeRequests` | `getGradeChangeRequests()` | `AcademicGradingService` | View pending grade change requests |
| `addAcademicTerm` | `addAcademicTerm(String, int, String, String)` | `AcademicGradingService` | Create a new academic term |
| `openSection` | `openSection(int, int, String, Integer, int)` | `AcademicGradingService` | Open a new class section for enrollment |

### 4. The `ClassInfoDto` Helper

To support AI agents that need to verify class section metadata before invoking tools, a typed DTO was introduced:

```java
public record ClassInfoDto(
    int classId,
    String courseCode,
    String sectionCode,
    String status
) {}
```

This is returned by both `getClassInfoDto(int classId)` (internal) and the `GET /api/mcp/classes/{id}` HTTP endpoint. It gives AI clients a structured, predictable object to reason about — compared to the raw `Map<String, Object>` returned by the general `getClassInfo()` method.

---

## How to Connect an AI Client

### Claude Desktop (Local Development)

Add the following to your Claude Desktop MCP configuration file:

```json
{
  "mcpServers": {
    "registrar": {
      "url": "http://localhost:8080/sse"
    }
  }
}
```

After restarting Claude Desktop with the app running, the Registrar tools will appear in the tool list under `registrar`.

### Custom AI Agent (Any MCP-Compatible Client)

1. Boot the application: `mvn spring-boot:run`
2. Connect your client to `http://localhost:8080/sse` (GET, with `Accept: text/event-stream`)
3. Perform the MCP handshake (the client sends `initialize`, server responds with `serverInfo` and tool list)
4. Call tools using JSON-RPC 2.0 over `POST /mcp/message`

---

## Security and Safety Assurance

### Why Write Tools Are Safe to Expose

Both `addAcademicTerm` and `openSection` are write operations exposed to AI. They are safe because:

1. **JPA validation layer**: All fields are typed. An AI cannot pass a string where an integer is expected without a Java `MethodArgumentTypeMismatchException`.
2. **Domain guard clauses**: `addAcademicTerm` validates the academic year format with a regex, checks for duplicate terms, and returns an `"ERROR: ..."` string if preconditions fail — never silently corrupting data.
3. **No raw SQL path**: Neither method contains `db.update(...)`. All mutations go through `classSectionRepository.saveAndFlush()` or `academicTermRepository.saveAndFlush()`.

### What Is NOT Exposed (and Why)

| Method | Reason Not Exposed |
|---|---|
| `triggerTermTransition(String)` | High-impact irreversible operation — requires human confirmation |
| `approveGradeChange(int)` | Financial consequence — must remain human-gated |
| `deleteUser(int)` | Destructive; no recovery path |
| `login(String, String)` | Security-sensitive; must never be AI-callable |
| `resetPassword(int)` | Security-sensitive |
