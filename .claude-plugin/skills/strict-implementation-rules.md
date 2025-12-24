---
description: Strict implementation enforcement rules. MVP/Full scope enforcement, anti-dummy rules, and real testing requirements. MUST be referenced during all migration and refactoring work.
---

# Strict Implementation Rules

## CRITICAL: These rules are NON-NEGOTIABLE

Violation of any rule below results in **immediate work rejection**.

---

## Rule 1: Scope Commitment Enforcement

### The Contract

When user selects scope (MVP or Full), that decision is **BINDING**.

```
┌─────────────────────────────────────────────────────────────┐
│  SCOPE SELECTION IS A CONTRACT, NOT A SUGGESTION           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  User selects "Full Migration"                              │
│       ↓                                                     │
│  Agent MUST implement ALL features completely               │
│       ↓                                                     │
│  NO shortcuts, NO "we can add this later"                   │
│       ↓                                                     │
│  If blocked, ASK USER - never self-decide to reduce scope   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### MVP Selection

When user selects MVP:
- Define exact MVP scope with user BEFORE starting
- Document what is IN and what is OUT
- Implement ONLY what's in MVP scope
- Everything in MVP must be COMPLETE (no half implementations)

### Full Selection

When user selects Full:
- Implement EVERYTHING specified
- No arbitrary scope reduction
- No "simplified versions"
- No "placeholder for future implementation"
- If something is technically impossible, STOP and discuss with user

### FORBIDDEN Behaviors

| Behavior | Why Forbidden |
|----------|---------------|
| "For MVP, I'll just..." (when Full selected) | Unauthorized scope change |
| "We can add this later" | Incomplete implementation |
| "This is a simplified version" | Not what user requested |
| "To save time, I'll..." | Prioritizing speed over correctness |
| Silently reducing features | Breach of contract |

---

## Rule 2: Testing Requirements

### Two-Phase Testing is MANDATORY

Every implementation must pass BOTH phases:

```
Phase 1: Static Testing
├── Import/syntax validation
├── Type checking
├── Linting
└── Unit tests with mocks

Phase 2: Real User Simulation Testing
├── Actual build execution
├── Real service calls (if LLM service: real prompt → real response)
├── End-to-end workflow verification
└── User journey simulation
```

### Static Testing (Phase 1)

- Import resolution
- Syntax validation
- Type checking (if typed language)
- Unit tests with appropriate mocking
- Linting rules

### Real User Simulation Testing (Phase 2)

**CRITICAL: This is NOT optional**

| If Project Type | Must Test |
|-----------------|-----------|
| Web Application | Real browser interaction, form submission, navigation |
| API Service | Real HTTP requests, actual responses |
| LLM Service | Real prompt input, actual LLM API call, response validation |
| CLI Tool | Real command execution, actual output |
| Library | Real import, actual function calls |

Example for LLM Service:
```
NOT ACCEPTABLE:
- Mock LLM response
- Hardcoded expected output
- "Assuming LLM returns X..."

REQUIRED:
- Send actual prompt to LLM API
- Receive actual response
- Validate response format and content
- Test error handling with real errors
```

---

## Rule 3: Implementation Quality Standards

### STRICTLY FORBIDDEN

| Pattern | Detection Method | Severity |
|---------|------------------|----------|
| `// TODO` | Grep scan | CRITICAL |
| `// FIXME` | Grep scan | CRITICAL |
| `throw new NotImplementedError()` | AST scan | CRITICAL |
| `pass` (Python placeholder) | AST scan | CRITICAL |
| `return null` (without logic) | AST scan | HIGH |
| `return {}` (empty object placeholder) | AST scan | HIGH |
| `return []` (empty array placeholder) | AST scan | HIGH |
| `console.log("TODO")` | Grep scan | CRITICAL |
| `print("not implemented")` | Grep scan | CRITICAL |
| Hardcoded values that should be configurable | Manual review | HIGH |
| Magic numbers without constants | Manual review | MEDIUM |
| Commented-out code blocks | Grep scan | MEDIUM |
| `any` type (TypeScript) without justification | AST scan | HIGH |
| Empty catch blocks | AST scan | CRITICAL |
| Functions with no implementation | AST scan | CRITICAL |

### Hardcoding Rules

**Forbidden Hardcoding:**
- API endpoints
- Credentials/secrets
- Environment-specific values
- User-facing strings (if i18n required)
- Configuration values

**Allowed Hardcoding:**
- Mathematical constants
- Protocol specifications
- Truly immutable values

---

## Rule 4: Audit Checkpoints

### When Audit MUST Run

1. **Before any test execution**
2. **After each implementation phase**
3. **Before marking task as complete**

### Audit Failure = Work Stoppage

If audit finds violations:
1. STOP all work
2. Report violations to user
3. Fix ALL violations
4. Re-run audit
5. Only proceed when audit passes

### Audit Report Format

```markdown
## Implementation Audit Report

### Scope Compliance
- Selected: [MVP/Full]
- Implemented: [X of Y features]
- Status: [PASS/FAIL]

### Forbidden Pattern Scan
| Pattern | Occurrences | Files |
|---------|-------------|-------|
| TODO comments | 0 | - |
| ...

### Hardcoding Scan
| Type | Occurrences | Files |
|------|-------------|-------|
| API endpoints | 0 | - |
| ...

### Test Readiness
- Static tests: [READY/NOT READY]
- Real simulation tests: [READY/NOT READY]

### Verdict: [PASS/FAIL]
```

---

## Rule 5: User Communication Protocol

### MUST Ask User When:

1. Scope needs ANY change
2. Blocked by technical limitation
3. Found ambiguity in requirements
4. Test failure that suggests design issue
5. Time estimate significantly changes

### NEVER Assume:

- "User probably meant..."
- "This is close enough..."
- "They won't notice if..."
- "I'll fix this later..."

---

## Enforcement Summary

> Every implementation must be complete, tested with real user simulation, and free of dummy code.
> Scope changes require explicit user approval.
> Audit must pass before any task is marked complete.
> When in doubt, ASK - never assume or simplify without permission.
