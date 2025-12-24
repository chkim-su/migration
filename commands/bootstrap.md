---
description: Install strict-migration enforcement system into target project. MUST run before /migrate.
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# Bootstrap Command

Install the strict-migration enforcement system into the current project.

## ⚠️ CRITICAL: This MUST run first

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║   BEFORE using /migrate, you MUST run /bootstrap                          ║
║                                                                           ║
║   /bootstrap installs the enforcement scripts that make /migrate work.    ║
║   Without /bootstrap, there is NO enforcement - just instructions.        ║
║                                                                           ║
║   "scripts/ not found - I'll follow principles anyway" = NO ENFORCEMENT   ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## Step 1: Find the Plugin Directory

```bash
# Option 1: Check common locations
ls ~/.claude/plugins/strict-migration/scripts/ 2>/dev/null && echo "Found at ~/.claude/plugins/strict-migration"
ls ~/.config/claude/plugins/strict-migration/scripts/ 2>/dev/null && echo "Found at ~/.config/claude/plugins/strict-migration"

# Option 2: Search for it
find ~ -name "strict-migration" -type d 2>/dev/null | head -5
```

If you cannot find it automatically:
```yaml
AskUserQuestion:
  question: "Where is the strict-migration plugin installed?"
  header: "Plugin Location"
```

---

## Step 2: Verify Plugin Contains Scripts

```bash
# Check if plugin has the required scripts
PLUGIN_DIR="[path from step 1]"
ls -la "$PLUGIN_DIR/scripts/"
```

Required scripts:
- state-machine.sh
- gate-check.sh
- quality-gate.sh
- progress-tracker.sh
- enforce-workflow.sh
- bootstrap.sh

---

## Step 3: Run Bootstrap

```bash
# Set the plugin directory
export STRICT_MIGRATION_PLUGIN_DIR="[path from step 1]"

# Run bootstrap
bash "$STRICT_MIGRATION_PLUGIN_DIR/scripts/bootstrap.sh" .
```

---

## Step 4: Verify Installation

```bash
# Check scripts were installed
ls -la scripts/

# Check state machine was initialized
cat .claude/local/migration-state.json
```

Expected output:
```
✓ state-machine.sh (executable)
✓ gate-check.sh (executable)
✓ quality-gate.sh (executable)
✓ progress-tracker.sh (executable)
✓ enforce-workflow.sh (executable)
✓ State machine initialized
BOOTSTRAP COMPLETE - Enforcement system installed
```

---

## Step 5: Ready for /migrate

After successful bootstrap:
```
You can now run /migrate with ACTUAL enforcement.
The hooks will now block invalid actions because scripts/ exists.
```

---

## Troubleshooting

### "Plugin not found"
- Check Claude Code settings for plugin installation path
- Manually clone the plugin: `git clone https://github.com/chkim-su/migration ~/.claude/plugins/strict-migration`

### "Permission denied"
```bash
chmod +x scripts/*.sh
```

### "State machine not initialized"
```bash
bash scripts/state-machine.sh init
```

---

## What Gets Installed

| File | Purpose |
|------|---------|
| `scripts/state-machine.sh` | Tracks phases, gates, and progress |
| `scripts/gate-check.sh` | Verifies prerequisites before actions |
| `scripts/quality-gate.sh` | Enforces code quality thresholds |
| `scripts/progress-tracker.sh` | Visual dashboard of migration status |
| `scripts/enforce-workflow.sh` | Core enforcement functions |
| `.claude/local/migration-state.json` | State machine data file |

---

## Why Bootstrap is Required

Without bootstrap:
- Hooks try to run `scripts/enforce-workflow.sh` → File not found
- No actual blocking happens
- Claude can create manual workarounds like `.migration/`
- No enforcement, just "principles"

With bootstrap:
- All enforcement scripts are in target project
- Hooks successfully block invalid actions
- State machine tracks all progress
- Gates actually prevent skipping steps
