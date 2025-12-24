---
description: Run implementation audit to detect dummy code, hardcoding, TODOs, and incomplete implementations. Returns PASS/FAIL verdict. Use before testing or task completion.
allowed-tools:
  - Task
  - Read
  - Glob
  - Grep
---

# Audit Command

Strict implementation audit for quality enforcement.

## Usage

```
/strict-migration:audit [target]
```

## Workflow

### Step 1: Target Selection

If no target provided:
```yaml
AskUserQuestion:
  question: "What should I audit?"
  header: "Target"
  options:
    - label: "Recent changes (git diff)"
    - label: "Specific path"
    - label: "Entire project"
```

### Step 2: Scope Context (Optional)

```yaml
AskUserQuestion:
  question: "Is this part of an MVP or Full scope project?"
  header: "Scope"
  options:
    - label: "MVP - Check against MVP features"
    - label: "Full - Check for complete implementation"
    - label: "Standalone audit - No scope context"
```

### Step 3: Run Audit

```
Task:
  agent: implementation-auditor
  prompt: |
    Audit [target] for implementation quality.

    Scope context: [MVP/Full/Standalone]

    CHECK FOR:
    1. TODO/FIXME comments
    2. Dummy code / placeholders
    3. Hardcoded values
    4. Incomplete implementations
    5. Empty catch blocks
    6. NotImplementedException

    RETURN: PASS or FAIL verdict
```

### Step 4: Output

```markdown
## Audit Report: [target]

### Verdict: [PASS/FAIL]

### Violations Found
| Type | Count | Severity | Locations |
|------|-------|----------|-----------|
| TODO comments | X | CRITICAL | file:line, ... |
| Dummy code | X | CRITICAL | file:line, ... |
| Hardcoding | X | HIGH | file:line, ... |

### Required Actions
If FAIL:
1. [Fix needed]
2. [Fix needed]
...

Re-run audit after fixes.
```

## When to Use

- Before running tests
- Before marking task complete
- After each implementation phase
- When reviewing code quality
