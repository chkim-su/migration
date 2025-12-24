---
description: Strict migration workflow with full enforcement system. State machine tracking, gate checkpoints, quality gates, and mandatory two-phase testing.
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

This command enforces strict implementation standards with automated enforcement.

## ⚠️ CRITICAL: ENFORCEMENT SYSTEM ACTIVE

This migration uses an automated enforcement system:
- **State Machine**: Tracks all phases, gates, and progress
- **Gate Checks**: Blocks actions that skip prerequisites
- **Quality Gates**: Enforces code quality thresholds
- **Hooks**: Automatically verify and block invalid transitions

**YOU CANNOT SKIP STEPS. THE SYSTEM WILL BLOCK YOU.**

---

## Workflow Overview

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                     ENFORCED MIGRATION WORKFLOW                            ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║  ┌─────────────────┐                                                      ║
║  │ 0. INITIALIZE   │ ← State machine setup + rollback point               ║
║  └────────┬────────┘                                                      ║
║           ▼                                                               ║
║  ┌─────────────────┐     ┌────────────────┐                              ║
║  │ 1. SCOPE SELECT │────▶│ 2. SCOPE DEFINE│                              ║
║  └────────┬────────┘     └────────┬───────┘                              ║
║           │                       │                                       ║
║           │    ┌──────────────────┘                                       ║
║           ▼    ▼                                                          ║
║  ╔═════════════════════════════════════════════════════════════════════╗  ║
║  ║  GATE: scope_confirmed (User must explicitly confirm)               ║  ║
║  ╚═══════════════════════════════╤═════════════════════════════════════╝  ║
║                                  ▼                                        ║
║  ┌─────────────────┐     ┌─────────────────┐                             ║
║  │ 3. SOLID ANALYZE│────▶│ 4. PLAN MIGRATE │                             ║
║  └────────┬────────┘     └────────┬────────┘                             ║
║           │                       │                                       ║
║  ╔═════════════════════════════════════════════════════════════════════╗  ║
║  ║  GATE: plan_approved (User must approve plan)                       ║  ║
║  ╚═══════════════════════════════╤═════════════════════════════════════╝  ║
║                                  ▼                                        ║
║  ┌─────────────────────────────────────────────────────────────────┐     ║
║  │ 5. IMPLEMENTATION PHASES                                         │     ║
║  │    ┌────────────────────────────────────────────────────────┐   │     ║
║  │    │ FOR each phase:                                         │   │     ║
║  │    │   5.1 Implement                                         │   │     ║
║  │    │   5.2 Audit checkpoint (implementation-auditor)         │   │     ║
║  │    │   5.3 Quality gate check                                │   │     ║
║  │    │   5.4 User confirmation → NEXT PHASE                    │   │     ║
║  │    │   [LOOP until all phases complete]                      │   │     ║
║  │    └────────────────────────────────────────────────────────┘   │     ║
║  └────────────────────────────────┬────────────────────────────────┘     ║
║                                   │                                       ║
║  ╔═════════════════════════════════════════════════════════════════════╗  ║
║  ║  GATE: all_phases_audited (Every phase must pass audit)             ║  ║
║  ╚═══════════════════════════════╤═════════════════════════════════════╝  ║
║                                  ▼                                        ║
║  ┌─────────────────┐                                                      ║
║  │ 6. FINAL AUDIT  │ ← implementation-auditor (MANDATORY)                 ║
║  └────────┬────────┘                                                      ║
║           │                                                               ║
║  ╔═════════════════════════════════════════════════════════════════════╗  ║
║  ║  GATE: final_audit_passed (BLOCKS ALL TESTING if not passed)        ║  ║
║  ╚═══════════════════════════════╤═════════════════════════════════════╝  ║
║                                  ▼                                        ║
║  ┌─────────────────────────────────────────────────────────────────┐     ║
║  │ 7. TWO-PHASE TESTING (BOTH REQUIRED - HOOKS ENFORCE THIS)       │     ║
║  │                                                                  │     ║
║  │   ┌─────────────────┐     ╔══════════════════╗                  │     ║
║  │   │ 7.1 STATIC TEST │────▶║GATE: static_tests║                  │     ║
║  │   │  (Phase 1)      │     ╚════════╤═════════╝                  │     ║
║  │   └─────────────────┘              │                            │     ║
║  │                                    ▼                            │     ║
║  │   ┌─────────────────┐     ╔══════════════════╗                  │     ║
║  │   │ 7.2 SIMULATION  │────▶║GATE: sim_tests   ║                  │     ║
║  │   │  (Phase 2)      │     ╚════════╤═════════╝                  │     ║
║  │   └─────────────────┘              │                            │     ║
║  │         ⚠️ CANNOT SKIP             │                            │     ║
║  │           Hook blocks completion   │                            │     ║
║  │           without Phase 2          │                            │     ║
║  └────────────────────────────────────┼────────────────────────────┘     ║
║                                       ▼                                   ║
║  ╔═════════════════════════════════════════════════════════════════════╗  ║
║  ║  GATE: all_tests_passed (BOTH phases required)                      ║  ║
║  ╚═══════════════════════════════╤═════════════════════════════════════╝  ║
║                                  ▼                                        ║
║  ┌─────────────────┐                                                      ║
║  │ 8. COMPLETION   │ ← Only if ALL gates passed                           ║
║  └─────────────────┘                                                      ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## Step 0: Initialize Workflow

**ALWAYS START HERE**

```bash
# Initialize state machine
bash scripts/state-machine.sh init

# Create rollback point
bash scripts/state-machine.sh rollback-point "migration-start"

# Show initial status
bash scripts/progress-tracker.sh dashboard
```

Record workflow metadata:
```bash
bash scripts/state-machine.sh set "workflow_id" "\"$(date +%Y%m%d-%H%M%S)\""
bash scripts/state-machine.sh set "started_at" "\"$(date -Iseconds)\""
```

---

## Step 1: Scope Selection

**THIS IS A BINDING CONTRACT**

```bash
bash scripts/state-machine.sh start-phase scope_selection
```

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

After selection:
```bash
bash scripts/state-machine.sh set "scope_type" "\"[MVP/Full]\""
bash scripts/state-machine.sh complete-phase scope_selection
```

---

## Step 2: Scope Definition

```bash
bash scripts/state-machine.sh start-phase scope_definition
```

### If MVP Selected:
```yaml
AskUserQuestion:
  question: "Define MVP scope. List the EXACT features to implement."
  header: "MVP Features"
```

### If Full Selected:
Analyze target and list ALL features.

**Document scope in state:**
```bash
# Set features array
bash scripts/state-machine.sh set "scope_features" '["Feature1", "Feature2", ...]'
```

**Get explicit confirmation:**
```yaml
AskUserQuestion:
  question: "Confirm this scope. Once confirmed, I will implement ALL listed features completely."
  header: "Confirm Scope"
  options:
    - label: "Confirmed - Proceed"
    - label: "Modify scope"
```

After confirmation:
```bash
bash scripts/state-machine.sh pass-gate scope_confirmed
bash scripts/state-machine.sh complete-phase scope_definition
bash scripts/progress-tracker.sh dashboard
```

---

## Step 3: SOLID Analysis

**Gate Check:** scope_confirmed must be true
```bash
bash scripts/gate-check.sh scope-compliance || exit 1
bash scripts/state-machine.sh start-phase solid_analysis
```

```
Task:
  agent: solid-analyzer
  prompt: "Analyze [target] for SOLID violations. Include file:line references."
```

After completion (auto-tracked by hook):
```bash
bash scripts/progress-tracker.sh dashboard
```

---

## Step 4: Migration Planning

```bash
bash scripts/state-machine.sh start-phase migration_planning
```

```
Task:
  agent: migration-planner
  prompt: |
    Create migration plan for [target].

    SCOPE CONTRACT:
    Type: [MVP/Full]
    Features: [list from state]

    CRITICAL: Plan must address ALL features in scope.
```

Get approval:
```yaml
AskUserQuestion:
  question: "Review migration plan. Does it cover all scope features?"
  header: "Plan Review"
  options:
    - label: "Approved - Proceed"
    - label: "Needs adjustment"
```

After approval:
```bash
bash scripts/state-machine.sh pass-gate plan_approved
bash scripts/state-machine.sh create-rollback-point "pre-implementation"
bash scripts/progress-tracker.sh dashboard
```

---

## Step 5: Implementation Phases

```bash
bash scripts/state-machine.sh start-phase implementation
```

### FOR EACH PHASE:

#### 5.1 Execute Phase
Implement changes for current phase.

#### 5.2 Audit Checkpoint (MANDATORY)
```
Task:
  agent: implementation-auditor
  prompt: |
    Audit Phase [N] implementation.

    SCOPE CONTRACT:
    Type: [scope_type]
    Features in this phase: [list]

    Check for: Scope compliance, TODO/FIXME, Dummy code, Hardcoding, Incomplete implementations
```

#### 5.3 Quality Gate Check
```bash
bash scripts/quality-gate.sh scan [target]
```

#### 5.4 Checkpoint Decision
```yaml
AskUserQuestion:
  question: "Phase [N] audit: [PASS/FAIL]. Quality gate: [PASS/FAIL]. How to proceed?"
  header: "Checkpoint"
  options:
    - label: "Continue to next phase"  # Only if PASS
    - label: "Fix violations first"     # If FAIL
```

**IF AUDIT FAILS**: You MUST fix all violations. The gate will block testing.

### After All Phases:
```bash
bash scripts/state-machine.sh pass-gate all_phases_audited
bash scripts/state-machine.sh complete-phase implementation
bash scripts/progress-tracker.sh dashboard
```

---

## Step 6: Final Audit

**⚠️ BLOCKING GATE: Testing is impossible without passing this.**

```bash
bash scripts/state-machine.sh start-phase final_audit
```

```
Task:
  agent: implementation-auditor
  prompt: |
    FINAL AUDIT before testing.

    SCOPE CONTRACT:
    Type: [scope_type]
    ALL Features: [complete list]

    STRICT CHECK:
    - Every feature implemented?
    - Zero TODO/FIXME?
    - Zero dummy code?
    - Zero hardcoding violations?
    - Zero incomplete implementations?

    VERDICT REQUIRED: PASS or FAIL
```

**Hook auto-updates:**
- If PASS: `gates_passed.final_audit_passed = true`
- If FAIL: Testing commands will be blocked

```bash
bash scripts/progress-tracker.sh next
```

---

## Step 7: Two-Phase Testing

**⚠️ HOOKS ENFORCE BOTH PHASES**

The hook system will:
1. Block Phase 2 until Phase 1 passes
2. Block completion until Phase 2 passes
3. Track test results in state machine

### 7.1 Phase 1: Static Tests

```bash
# Gate check happens automatically via hook
bash scripts/state-machine.sh start-phase phase1_testing
```

```
Task:
  agent: test-orchestrator
  prompt: |
    Execute two-phase testing on [target].

    The orchestrator will:
    1. Run static-test-runner (Phase 1)
    2. If Phase 1 passes, run simulation-test-runner (Phase 2)
```

Or manually:
```
Task:
  agent: static-test-runner
  prompt: "Execute Phase 1 static testing. Run all static checks."
```

### 7.2 Phase 2: Simulation Tests (MANDATORY)

**Hook blocks completion without Phase 2.**

```bash
# This command is blocked unless static_tests_passed = true
bash scripts/state-machine.sh start-phase phase2_testing
```

```
Task:
  agent: simulation-test-runner
  prompt: |
    Execute Phase 2 simulation testing.

    Run REAL user simulations:
    - User journey tests
    - Service integration tests
    - LLM integration tests (if applicable)

    Use REAL services, NO mocking.
```

After both phases:
```bash
bash scripts/progress-tracker.sh dashboard
```

---

## Step 8: Completion

**Gate Check (automatic via hook):**

```bash
# This will fail if any gate is not passed
bash scripts/gate-check.sh pre-completion
```

Only mark complete if ALL conditions met:
- [ ] scope_confirmed = true
- [ ] plan_approved = true
- [ ] all_phases_audited = true
- [ ] final_audit_passed = true
- [ ] static_tests_passed = true
- [ ] simulation_tests_passed = true

```bash
bash scripts/state-machine.sh start-phase completion
bash scripts/state-machine.sh complete-phase completion
bash scripts/progress-tracker.sh dashboard
```

### Final Report:
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

### All Gates Passed: ✓
```

---

## Helper Commands

### Check Progress Anytime
```bash
bash scripts/progress-tracker.sh dashboard
bash scripts/progress-tracker.sh next
```

### Check Quality
```bash
bash scripts/quality-gate.sh scan
bash scripts/quality-gate.sh violations
```

### Check Gate Status
```bash
bash scripts/gate-check.sh pre-test
bash scripts/gate-check.sh pre-completion
```

### State Machine Commands
```bash
bash scripts/state-machine.sh status
bash scripts/state-machine.sh progress
```

---

## ENFORCEMENT RULES SUMMARY

| Rule | Enforced By | Blocks |
|------|-------------|--------|
| Scope must be confirmed | Gate check | SOLID analysis |
| Plan must be approved | Gate check | Implementation |
| Final audit must pass | PreToolUse hook | All test commands |
| Phase 1 must pass | PreToolUse hook | simulation-test-runner |
| Phase 2 must pass | Stop hook | Task completion |
| All gates required | pre-completion | Marking as done |

**There are NO shortcuts. The system enforces the workflow.**
