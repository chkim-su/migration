#!/bin/bash
# Workflow Enforcement Script
# Detects and blocks unauthorized manual work without proper workflow initialization

STATE_FILE="${MIGRATION_STATE_FILE:-.claude/local/migration-state.json}"
LOG_FILE="${MIGRATION_LOG_FILE:-.claude/local/migration-audit.log}"
LOCK_FILE="${MIGRATION_LOCK_FILE:-.claude/local/migration.lock}"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

log_enforcement() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$(date -Iseconds)] [ENFORCEMENT] $1" >> "$LOG_FILE"
}

# Check if workflow is properly initialized
is_workflow_initialized() {
    if [ ! -f "$STATE_FILE" ]; then
        return 1
    fi

    local workflow_id=$(jq -r '.workflow_id // empty' "$STATE_FILE" 2>/dev/null)
    if [ -z "$workflow_id" ] || [ "$workflow_id" = "null" ]; then
        return 1
    fi

    return 0
}

# Check if currently in an active workflow
is_workflow_active() {
    if ! is_workflow_initialized; then
        return 1
    fi

    local current_phase=$(jq -r '.current_phase // "not_started"' "$STATE_FILE" 2>/dev/null)
    local completion_status=$(jq -r '.phases.completion.status // "pending"' "$STATE_FILE" 2>/dev/null)

    if [ "$completion_status" = "completed" ]; then
        return 1  # Workflow finished
    fi

    if [ "$current_phase" = "not_started" ]; then
        return 1  # Not started yet
    fi

    return 0
}

# BLOCK: Require workflow initialization
require_workflow() {
    if ! is_workflow_initialized; then
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}   ❌ BLOCKED: NO ACTIVE WORKFLOW                              ${NC}"
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}Manual work without workflow initialization is NOT ALLOWED.${NC}"
        echo ""
        echo "To start a migration workflow:"
        echo "  1. Run: /migrate"
        echo "  2. Or manually: bash scripts/state-machine.sh init"
        echo ""
        echo -e "${RED}This action has been BLOCKED and logged.${NC}"
        log_enforcement "BLOCKED: Attempted work without workflow - $1"
        return 1
    fi
    return 0
}

# BLOCK: Require specific gate to be passed
require_gate() {
    local gate_name="$1"
    local action_description="$2"

    if ! is_workflow_initialized; then
        require_workflow "$action_description"
        return 1
    fi

    local gate_passed=$(jq -r ".gates_passed.$gate_name // false" "$STATE_FILE" 2>/dev/null)

    if [ "$gate_passed" != "true" ]; then
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}   ❌ BLOCKED: GATE NOT PASSED                                 ${NC}"
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "Required gate: ${YELLOW}$gate_name${NC}"
        echo -e "Attempted action: ${YELLOW}$action_description${NC}"
        echo ""
        echo "You must pass this gate before proceeding."
        log_enforcement "BLOCKED: Gate $gate_name not passed for: $action_description"
        return 1
    fi

    return 0
}

# BLOCK: Require Phase 2 simulation tests before completion
require_simulation_tests() {
    if ! is_workflow_initialized; then
        require_workflow "completion check"
        return 1
    fi

    local sim_tests=$(jq -r '.gates_passed.simulation_tests_passed // false' "$STATE_FILE" 2>/dev/null)

    if [ "$sim_tests" != "true" ]; then
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}   ❌ BLOCKED: PHASE 2 SIMULATION TESTS NOT COMPLETED          ${NC}"
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}You CANNOT mark work as complete without real user simulation tests.${NC}"
        echo ""
        echo "Phase 2 tests are MANDATORY and include:"
        echo "  - Real service calls (NOT mocks)"
        echo "  - Actual user journey simulation"
        echo "  - Real LLM API calls (if applicable)"
        echo ""
        echo "Run simulation-test-runner before attempting completion."
        log_enforcement "BLOCKED: Completion attempted without Phase 2 simulation tests"
        return 1
    fi

    return 0
}

# BLOCK: Prevent skipping to later phases
require_sequential_phases() {
    local target_phase="$1"

    if ! is_workflow_initialized; then
        require_workflow "phase transition to $target_phase"
        return 1
    fi

    local current=$(jq -r '.current_phase // "not_started"' "$STATE_FILE" 2>/dev/null)

    # Phase order
    local -a phase_order=("not_started" "scope_selection" "scope_definition" "solid_analysis" "migration_planning" "implementation" "final_audit" "phase1_testing" "phase2_testing" "completion")

    local current_idx=-1
    local target_idx=-1

    for i in "${!phase_order[@]}"; do
        if [ "${phase_order[$i]}" = "$current" ]; then
            current_idx=$i
        fi
        if [ "${phase_order[$i]}" = "$target_phase" ]; then
            target_idx=$i
        fi
    done

    # Allow moving to next phase or same phase only
    if [ $target_idx -gt $((current_idx + 1)) ]; then
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}   ❌ BLOCKED: PHASE SKIP DETECTED                             ${NC}"
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "Current phase: ${YELLOW}$current${NC}"
        echo -e "Attempted phase: ${YELLOW}$target_phase${NC}"
        echo ""
        echo "You cannot skip phases. Complete the current phase first."
        log_enforcement "BLOCKED: Attempted to skip from $current to $target_phase"
        return 1
    fi

    return 0
}

# BLOCK: Require real service tests (not just import tests)
require_real_tests() {
    local test_type="$1"  # "static" or "simulation"

    if ! is_workflow_initialized; then
        require_workflow "test verification"
        return 1
    fi

    # Check test evidence file
    local evidence_file=".claude/local/test-evidence-${test_type}.json"

    if [ ! -f "$evidence_file" ]; then
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}   ❌ BLOCKED: NO TEST EVIDENCE FOUND                          ${NC}"
        echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "Test type: ${YELLOW}$test_type${NC}"
        echo ""
        echo "Tests must produce evidence file at: $evidence_file"
        echo ""
        echo "Evidence must include:"
        if [ "$test_type" = "simulation" ]; then
            echo "  - Real service call logs"
            echo "  - Actual response data"
            echo "  - User journey execution proof"
        else
            echo "  - Import test results"
            echo "  - Type check results"
            echo "  - Lint results"
        fi
        log_enforcement "BLOCKED: No test evidence for $test_type tests"
        return 1
    fi

    echo -e "${GREEN}✓ Test evidence found for: $test_type${NC}"
    return 0
}

# Create test evidence file
record_test_evidence() {
    local test_type="$1"
    local result="$2"  # "PASS" or "FAIL"
    local details="$3"

    mkdir -p ".claude/local"
    local evidence_file=".claude/local/test-evidence-${test_type}.json"

    cat > "$evidence_file" << EOF
{
    "test_type": "$test_type",
    "result": "$result",
    "timestamp": "$(date -Iseconds)",
    "details": "$details",
    "workflow_id": "$(jq -r '.workflow_id // "unknown"' "$STATE_FILE" 2>/dev/null)"
}
EOF

    log_enforcement "Test evidence recorded: $test_type = $result"
    echo -e "${GREEN}✓ Test evidence recorded: $test_type = $result${NC}"
}

# Verify completion is legitimate
verify_completion_legitimate() {
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}           COMPLETION VERIFICATION CHECK                       ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    local all_passed=true
    local failures=""

    # 1. Workflow initialized
    echo -n "1. Workflow initialized: "
    if is_workflow_initialized; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        all_passed=false
        failures="$failures workflow_not_initialized"
    fi

    # 2. Scope confirmed
    echo -n "2. Scope confirmed: "
    local scope=$(jq -r '.gates_passed.scope_confirmed // false' "$STATE_FILE" 2>/dev/null)
    if [ "$scope" = "true" ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        all_passed=false
        failures="$failures scope_not_confirmed"
    fi

    # 3. Plan approved
    echo -n "3. Plan approved: "
    local plan=$(jq -r '.gates_passed.plan_approved // false' "$STATE_FILE" 2>/dev/null)
    if [ "$plan" = "true" ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        all_passed=false
        failures="$failures plan_not_approved"
    fi

    # 4. Final audit passed
    echo -n "4. Final audit passed: "
    local audit=$(jq -r '.gates_passed.final_audit_passed // false' "$STATE_FILE" 2>/dev/null)
    if [ "$audit" = "true" ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        all_passed=false
        failures="$failures audit_not_passed"
    fi

    # 5. Static tests passed (with evidence)
    echo -n "5. Static tests passed (with evidence): "
    local static=$(jq -r '.gates_passed.static_tests_passed // false' "$STATE_FILE" 2>/dev/null)
    local static_evidence=".claude/local/test-evidence-static.json"
    if [ "$static" = "true" ] && [ -f "$static_evidence" ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        all_passed=false
        failures="$failures static_tests_incomplete"
    fi

    # 6. SIMULATION tests passed (with evidence) - CRITICAL
    echo -n "6. Simulation tests passed (with evidence): "
    local sim=$(jq -r '.gates_passed.simulation_tests_passed // false' "$STATE_FILE" 2>/dev/null)
    local sim_evidence=".claude/local/test-evidence-simulation.json"
    if [ "$sim" = "true" ] && [ -f "$sim_evidence" ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗ [CRITICAL - REAL USER TESTS REQUIRED]${NC}"
        all_passed=false
        failures="$failures SIMULATION_TESTS_MISSING"
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════════"

    if [ "$all_passed" = "true" ]; then
        echo -e "${GREEN}RESULT: ✓ ALL CHECKS PASSED - Completion is legitimate${NC}"
        log_enforcement "Completion verification PASSED"
        return 0
    else
        echo -e "${RED}RESULT: ✗ CHECKS FAILED - Completion is NOT legitimate${NC}"
        echo ""
        echo -e "${RED}Missing:$failures${NC}"
        echo ""
        echo -e "${YELLOW}You CANNOT mark this work as complete.${NC}"
        log_enforcement "Completion verification FAILED: $failures"
        return 1
    fi
}

# Create workflow lock
create_lock() {
    mkdir -p "$(dirname "$LOCK_FILE")"
    echo "$(date -Iseconds)" > "$LOCK_FILE"
    log_enforcement "Workflow lock created"
}

# Release workflow lock
release_lock() {
    rm -f "$LOCK_FILE"
    log_enforcement "Workflow lock released"
}

# Check lock
is_locked() {
    [ -f "$LOCK_FILE" ]
}

# Command handler
case "${1:-}" in
    require-workflow)
        require_workflow "$2"
        ;;
    require-gate)
        require_gate "$2" "$3"
        ;;
    require-simulation)
        require_simulation_tests
        ;;
    require-sequential)
        require_sequential_phases "$2"
        ;;
    require-real-tests)
        require_real_tests "$2"
        ;;
    record-evidence)
        record_test_evidence "$2" "$3" "$4"
        ;;
    verify-completion)
        verify_completion_legitimate
        ;;
    is-initialized)
        is_workflow_initialized && echo "true" || echo "false"
        ;;
    is-active)
        is_workflow_active && echo "true" || echo "false"
        ;;
    lock)
        create_lock
        ;;
    unlock)
        release_lock
        ;;
    is-locked)
        is_locked && echo "true" || echo "false"
        ;;
    *)
        echo "Usage: $0 {require-workflow|require-gate|require-simulation|require-sequential|require-real-tests|record-evidence|verify-completion|is-initialized|is-active|lock|unlock|is-locked}"
        exit 1
        ;;
esac
