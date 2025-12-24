---
description: Strict migration workflow with MVP/Full scope enforcement. Includes mandatory audit checkpoints and two-phase testing. Scope selection is binding - no unauthorized reductions allowed.
allowed-tools:
  - Task
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Strict Migration Command

This command enforces strict implementation standards throughout the migration process.

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    STRICT MIGRATION WORKFLOW                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. SCOPE SELECTION (MVP/Full) ← BINDING CONTRACT               │
│           ↓                                                     │
│  2. SCOPE DEFINITION ← Document ALL features                    │
│           ↓                                                     │
│  3. SOLID ANALYSIS ← Identify violations                        │
│           ↓                                                     │
│  4. MIGRATION PLANNING ← Respect scope contract                 │
│           ↓                                                     │
│  5. IMPLEMENTATION PHASES                                       │
│       ├→ Phase N Implementation                                 │
│       ├→ AUDIT CHECKPOINT ← Must pass                           │
│       └→ Repeat until all phases done                           │
│           ↓                                                     │
│  6. FINAL AUDIT ← No TODO, no dummy, no hardcode                │
│           ↓                                                     │
│  7. TWO-PHASE TESTING                                           │
│       ├→ Phase 1: Static tests                                  │
│       └→ Phase 2: Real user simulation                          │
│           ↓                                                     │
│  8. COMPLETION ← Only if all checks pass                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Step 1: Scope Selection

**THIS IS A BINDING CONTRACT**

```yaml
AskUserQuestion:
  question: "Select implementation scope. THIS CHOICE IS BINDING - no unauthorized changes allowed."
  header: "Scope"
  options:
    - label: "MVP"
      description: "Minimum viable - we will define exact features together"
    - label: "Full"
      description: "Complete implementation - ALL features, NO shortcuts"
```

## Step 2: Scope Definition

### If MVP Selected:
```yaml
AskUserQuestion:
  question: "Define MVP scope. List the EXACT features to implement. Everything listed MUST be complete."
  header: "MVP Features"
  # Free text input for feature list
```

Document the scope:
```markdown
## SCOPE CONTRACT

Type: MVP
Date: [timestamp]

### Features IN SCOPE (MUST implement completely):
1. [Feature]
2. [Feature]
...

### Features OUT OF SCOPE (explicitly excluded):
1. [Feature]
2. [Feature]
...

### User Confirmation: REQUIRED
```

### If Full Selected:
Analyze target and list ALL features:
```markdown
## SCOPE CONTRACT

Type: FULL
Date: [timestamp]

### ALL Features (MUST implement completely):
1. [Feature]
2. [Feature]
...

### Shortcuts/Simplifications: NONE ALLOWED

### User Confirmation: REQUIRED
```

Get explicit confirmation:
```yaml
AskUserQuestion:
  question: "Confirm this scope. Once confirmed, I will implement ALL listed features completely."
  header: "Confirm"
  options:
    - label: "Confirmed - Proceed"
      description: "I understand and agree to this scope"
    - label: "Modify scope"
      description: "I want to change the feature list"
```

## Step 3: SOLID Analysis

Launch analyzer:
```
Task:
  agent: solid-analyzer
  prompt: "Analyze [target] for SOLID violations. Include file:line references."
```

## Step 4: Migration Planning

Launch planner with scope contract:
```
Task:
  agent: migration-planner
  prompt: |
    Create migration plan for [target].

    SCOPE CONTRACT:
    Type: [MVP/Full]
    Features: [list]

    CRITICAL: Plan must address ALL features in scope.
    No scope reductions without explicit user approval.
```

Get plan approval:
```yaml
AskUserQuestion:
  question: "Review migration plan. Does it cover all scope features?"
  header: "Plan Review"
  options:
    - label: "Approved - Proceed"
    - label: "Needs adjustment"
```

## Step 5: Implementation Phases

For each phase:

### 5.1 Execute Phase
Implement changes for current phase.

### 5.2 Audit Checkpoint (MANDATORY)
```
Task:
  agent: implementation-auditor
  prompt: |
    Audit Phase [N] implementation.

    SCOPE CONTRACT:
    Type: [MVP/Full]
    Features in this phase: [list]

    Check for:
    - Scope compliance
    - TODO/FIXME comments
    - Dummy code
    - Hardcoding
    - Incomplete implementations
```

### 5.3 Checkpoint Decision
```yaml
AskUserQuestion:
  question: "Phase [N] audit complete. Result: [PASS/FAIL]. How to proceed?"
  header: "Checkpoint"
  options:
    - label: "Continue to next phase" # Only if PASS
    - label: "Fix violations first" # If FAIL
    - label: "Review changes"
```

**IF AUDIT FAILS**: Must fix all violations before proceeding.

## Step 6: Final Audit

Before any testing:
```
Task:
  agent: implementation-auditor
  prompt: |
    FINAL AUDIT before testing.

    SCOPE CONTRACT:
    Type: [MVP/Full]
    ALL Features: [complete list]

    STRICT CHECK:
    - Every feature implemented?
    - Zero TODO/FIXME?
    - Zero dummy code?
    - Zero hardcoding violations?
    - Zero incomplete implementations?

    VERDICT REQUIRED: PASS or FAIL
```

**IF FINAL AUDIT FAILS**: No testing allowed until all issues fixed.

## Step 7: Two-Phase Testing

Only after audit PASSES:

```
Task:
  agent: test-executor
  prompt: |
    Execute two-phase testing.

    Phase 1: Static Testing
    - Import validation
    - Type checking
    - Linting
    - Unit tests

    Phase 2: Real User Simulation
    - Actual build
    - Real service calls
    - User journey simulation
    [If LLM service: Real prompt → Real LLM call → Validate response]

    BOTH PHASES MUST PASS
```

## Step 8: Completion

Only mark complete if:
- [ ] Scope contract fulfilled (all features implemented)
- [ ] Final audit PASSED
- [ ] Phase 1 testing PASSED
- [ ] Phase 2 testing PASSED

```markdown
## Migration Complete

### Scope Compliance
- Type: [MVP/Full]
- Features implemented: [X/X] (100%)

### Audit Status
- Final audit: PASS

### Test Status
- Phase 1 (Static): PASS
- Phase 2 (Simulation): PASS

### Verification
All requirements met. Migration complete.
```

## CRITICAL RULES

1. **Scope is binding** - No changes without user approval
2. **Audit before test** - Always
3. **Both test phases required** - Static AND simulation
4. **FAIL = STOP** - Fix before proceeding
5. **Document everything** - Full traceability
