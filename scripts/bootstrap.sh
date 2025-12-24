#!/bin/bash
# Bootstrap Script - Installs strict-migration enforcement system into target project
# This MUST run before any migration work begins

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PLUGIN_DIR="${STRICT_MIGRATION_PLUGIN_DIR:-$(dirname "$(dirname "$(readlink -f "$0")")")}"
TARGET_DIR="${1:-.}"

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}        STRICT-MIGRATION BOOTSTRAP INSTALLER                   ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Plugin source: ${YELLOW}$PLUGIN_DIR${NC}"
echo -e "Target project: ${YELLOW}$TARGET_DIR${NC}"
echo ""

# Verify plugin source exists
if [ ! -d "$PLUGIN_DIR/scripts" ]; then
    echo -e "${RED}ERROR: Plugin scripts directory not found at $PLUGIN_DIR/scripts${NC}"
    echo "Please set STRICT_MIGRATION_PLUGIN_DIR environment variable"
    exit 1
fi

# Create target directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p "$TARGET_DIR/.claude/local"
mkdir -p "$TARGET_DIR/scripts"

# Copy enforcement scripts
echo -e "${YELLOW}Installing enforcement scripts...${NC}"

SCRIPTS=(
    "state-machine.sh"
    "gate-check.sh"
    "quality-gate.sh"
    "progress-tracker.sh"
    "enforce-workflow.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$PLUGIN_DIR/scripts/$script" ]; then
        cp "$PLUGIN_DIR/scripts/$script" "$TARGET_DIR/scripts/"
        chmod +x "$TARGET_DIR/scripts/$script"
        echo -e "  ${GREEN}✓${NC} $script"
    else
        echo -e "  ${RED}✗${NC} $script (not found in plugin)"
    fi
done

# Copy bootstrap itself for reference
cp "$PLUGIN_DIR/scripts/bootstrap.sh" "$TARGET_DIR/scripts/" 2>/dev/null || true
chmod +x "$TARGET_DIR/scripts/bootstrap.sh" 2>/dev/null || true

# Initialize state machine
echo ""
echo -e "${YELLOW}Initializing state machine...${NC}"
cd "$TARGET_DIR"
bash scripts/state-machine.sh init

# Create initial rollback point if git is available
if [ -d ".git" ]; then
    echo -e "${YELLOW}Creating rollback point...${NC}"
    bash scripts/state-machine.sh rollback-point "pre-migration"
    echo -e "  ${GREEN}✓${NC} Rollback point created"
fi

# Verify installation
echo ""
echo -e "${YELLOW}Verifying installation...${NC}"

VERIFICATION_PASSED=true

for script in "${SCRIPTS[@]}"; do
    if [ -x "$TARGET_DIR/scripts/$script" ]; then
        echo -e "  ${GREEN}✓${NC} $script (executable)"
    else
        echo -e "  ${RED}✗${NC} $script (missing or not executable)"
        VERIFICATION_PASSED=false
    fi
done

if [ -f "$TARGET_DIR/.claude/local/migration-state.json" ]; then
    echo -e "  ${GREEN}✓${NC} State machine initialized"
else
    echo -e "  ${RED}✗${NC} State machine not initialized"
    VERIFICATION_PASSED=false
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"

if [ "$VERIFICATION_PASSED" = true ]; then
    echo -e "${GREEN}BOOTSTRAP COMPLETE - Enforcement system installed${NC}"
    echo ""
    echo "The following enforcement is now active:"
    echo "  - State machine tracking all phases"
    echo "  - Gate checks blocking unauthorized progression"
    echo "  - Quality gates enforcing code standards"
    echo "  - Progress tracker for visibility"
    echo ""
    echo -e "${YELLOW}IMPORTANT: All migration work must now use these scripts.${NC}"
    echo -e "${YELLOW}Skipping phases or tests will be BLOCKED.${NC}"
else
    echo -e "${RED}BOOTSTRAP FAILED - Some components missing${NC}"
    echo "Please check the errors above and retry."
    exit 1
fi

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
