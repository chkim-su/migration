---
description: Show current migration status, progress, and next required action
allowed-tools:
  - Bash
  - Read
---

# Migration Status Command

Shows the current state of the migration workflow.

## Usage

Run this command anytime to see:
- Overall progress percentage
- Current phase
- Gate status
- Quality metrics
- Next required action

## Execution

```bash
# Full dashboard
bash scripts/progress-tracker.sh dashboard

# Next required action
echo ""
echo "═══════════════════════════════════════════════════════"
echo "            NEXT REQUIRED ACTION                       "
echo "═══════════════════════════════════════════════════════"
bash scripts/progress-tracker.sh next
```

## Quick Status

For a compact one-line status:
```bash
bash scripts/progress-tracker.sh compact
```

## Gate Check

To verify if you can proceed:
```bash
bash scripts/gate-check.sh pre-test
bash scripts/gate-check.sh pre-completion
```
