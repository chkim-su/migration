# Strict Migration Plugin

A Claude Code plugin that enforces strict implementation standards during refactoring and migration work.

## Key Features

### 1. Scope Commitment Enforcement
- **MVP vs Full selection is binding** - Once chosen, no unauthorized scope reductions
- Explicit scope definition before work begins
- Every feature in scope MUST be completely implemented

### 2. Two-Phase Testing
- **Phase 1: Static Testing** - Import validation, type checking, linting, unit tests
- **Phase 2: Real User Simulation** - Actual builds, real service calls, user journey simulation
- For LLM services: Real prompts → Real LLM calls → Response validation

### 3. Implementation Auditing
- Detects TODO/FIXME comments
- Finds dummy code and placeholders
- Identifies hardcoded values
- Catches incomplete implementations
- **Must pass before testing allowed**

## Installation

### From GitHub Marketplace

```bash
claude plugins install chanhokim/strict-migration
```

### Manual Installation

Clone this repository to your Claude plugins directory:

```bash
git clone https://github.com/chanhokim/strict-migration ~/.claude/plugins/local/strict-migration
```

Then enable in settings:
```json
{
  "enabledPlugins": {
    "strict-migration@local": true
  }
}
```

## Commands

| Command | Description |
|---------|-------------|
| `/strict-migration:migrate` | Full migration workflow with all enforcement |
| `/strict-migration:analyze` | Quick SOLID violation analysis |
| `/strict-migration:audit` | Implementation quality audit |

## Workflow

```
1. /strict-migration:migrate src/

2. Select scope: MVP or Full (BINDING)

3. Define features in scope

4. SOLID analysis runs

5. Migration plan created

6. For each implementation phase:
   └→ Implement
   └→ Audit checkpoint (MUST PASS)
   └→ Continue

7. Final audit (MUST PASS)

8. Two-phase testing:
   └→ Phase 1: Static tests
   └→ Phase 2: Real simulation

9. Complete (only if all pass)
```

## Strict Rules

### FORBIDDEN

| Pattern | Reason |
|---------|--------|
| `// TODO` | Incomplete work |
| `// FIXME` | Known issues not fixed |
| `throw NotImplementedException` | Placeholder code |
| `return null` (without logic) | Dummy implementation |
| Hardcoded API URLs | Configuration violation |
| Scope reduction without approval | Contract violation |

### REQUIRED

- All features in scope must be complete
- Audit must pass before testing
- Both test phases must pass
- Real user simulation for integration tests
- Explicit user approval for any scope change

## Components

### Skills
- `solid-design-rules` - SOLID principles and TDD enforcement
- `strict-implementation-rules` - MVP/Full scope and anti-dummy rules

### Agents
- `solid-analyzer` - SOLID violation detection
- `migration-planner` - Safe migration planning
- `implementation-auditor` - Dummy/hardcode detection
- `test-executor` - Two-phase test execution

### Hooks
- `pre-test-audit` - Blocks testing until audit passes

## Philosophy

> "If you haven't tested it like a real user would use it, you haven't tested it at all."

This plugin ensures that:
1. Scope commitments are honored
2. No dummy code ships
3. Real-world testing happens
4. Quality gates are enforced

## License

MIT
