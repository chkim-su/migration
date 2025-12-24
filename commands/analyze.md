---
description: Quick SOLID and implementation quality analysis. Returns violation report without making changes. Use before planning migration.
allowed-tools:
  - Task
  - Read
  - Glob
  - Grep
---

# Analyze Command

Quick analysis of code quality and SOLID compliance.

## Usage

```
/strict-migration:analyze [target]
```

## Workflow

### Step 1: Target Selection

If no target provided:
```yaml
AskUserQuestion:
  question: "What should I analyze?"
  header: "Target"
  options:
    - label: "Current directory"
    - label: "Specific path"
```

### Step 2: Run Analysis

```
Task:
  agent: solid-analyzer
  prompt: "Analyze [target] for SOLID violations. Provide summary with top issues."
```

### Step 3: Output

```markdown
## Analysis Report: [target]

### Quick Summary
| Principle | Status | Violations |
|-----------|--------|------------|
| SRP | OK/WARN/FAIL | X |
| OCP | OK/WARN/FAIL | X |
| LSP | OK/WARN/FAIL | X |
| ISP | OK/WARN/FAIL | X |
| DIP | OK/WARN/FAIL | X |

### Top Issues
1. **[CRITICAL]** [file:line] - [issue]
2. ...

### Recommendations
Use `/strict-migration:migrate` to fix these issues with full audit enforcement.
```
