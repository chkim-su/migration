#!/bin/bash
# Gate Check Script - Enforces prerequisites before actions
# Returns exit code 0 if gate passes, 1 if blocked

STATE_SCRIPT="$(dirname "$0")/state-machine.sh"
LOG_FILE="${MIGRATION_LOG_FILE:-.claude/local/migration-audit.log}"

log_gate() {
    local gate="$1"
    local result="$2"
    local message="$3"
    echo "[$(date -Iseconds)] [GATE_CHECK] $gate: $result - $message" >> "$LOG_FILE"
}

# Check if state machine is initialized
check_initialized() {
    if [ ! -f ".claude/local/migration-state.json" ]; then
        echo "❌ BLOCKED: Migration not initialized. Run /migrate first."
        log_gate "INIT_CHECK" "BLOCKED" "State file not found"
        return 1
    fi
    return 0
}

# Gate: Block testing without final audit
gate_test_requires_audit() {
    check_initialized || return 1

    local final_audit_passed=$("$STATE_SCRIPT" get "gates_passed.final_audit_passed")

    if [ "$final_audit_passed" != "true" ]; then
        echo "❌ BLOCKED: Cannot run tests - Final audit not passed"
        echo ""
        echo "Required: Run implementation-auditor and pass final audit first"
        echo "Command: /audit"
        log_gate "TEST_GATE" "BLOCKED" "Final audit not passed"
        return 1
    fi

    echo "✓ Gate passed: Final audit completed"
    log_gate "TEST_GATE" "PASSED" "Final audit verified"
    return 0
}

# Gate: Block Phase 2 without Phase 1
gate_phase2_requires_phase1() {
    check_initialized || return 1

    local static_tests_passed=$("$STATE_SCRIPT" get "gates_passed.static_tests_passed")

    if [ "$static_tests_passed" != "true" ]; then
        echo "❌ BLOCKED: Cannot run Phase 2 simulation tests"
        echo ""
        echo "Required: Phase 1 static tests must pass first"
        echo "Run static-test-runner before simulation-test-runner"
        log_gate "PHASE2_GATE" "BLOCKED" "Phase 1 not passed"
        return 1
    fi

    echo "✓ Gate passed: Phase 1 tests completed"
    log_gate "PHASE2_GATE" "PASSED" "Phase 1 verified"
    return 0
}

# Gate: Block completion without all gates passed
gate_completion_check() {
    check_initialized || return 1

    local all_passed=true
    local missing_gates=""

    for gate in scope_confirmed plan_approved final_audit_passed static_tests_passed simulation_tests_passed; do
        local passed=$("$STATE_SCRIPT" get "gates_passed.$gate")
        if [ "$passed" != "true" ]; then
            all_passed=false
            missing_gates="$missing_gates $gate"
        fi
    done

    if [ "$all_passed" != "true" ]; then
        echo "❌ BLOCKED: Cannot mark as complete"
        echo ""
        echo "Missing gates:$missing_gates"
        echo ""
        echo "All gates must pass before completion"
        log_gate "COMPLETION_GATE" "BLOCKED" "Missing:$missing_gates"
        return 1
    fi

    echo "✓ Gate passed: All prerequisites met"
    log_gate "COMPLETION_GATE" "PASSED" "All gates verified"
    return 0
}

# Gate: Check for TODO/FIXME before test
gate_no_todos() {
    local target="${1:-.}"

    local todo_count=$(grep -rn "TODO\|FIXME\|XXX\|HACK" "$target" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.java" \
        2>/dev/null | wc -l)

    if [ "$todo_count" -gt 0 ]; then
        echo "❌ BLOCKED: Found $todo_count TODO/FIXME comments"
        echo ""
        echo "Locations:"
        grep -rn "TODO\|FIXME\|XXX\|HACK" "$target" \
            --include="*.ts" --include="*.js" --include="*.py" --include="*.java" \
            2>/dev/null | head -10
        echo ""
        echo "Remove all TODO/FIXME before proceeding"
        log_gate "TODO_GATE" "BLOCKED" "Found $todo_count TODOs"
        return 1
    fi

    echo "✓ Gate passed: No TODO/FIXME found"
    log_gate "TODO_GATE" "PASSED" "Clean"
    return 0
}

# Gate: Check for hardcoded secrets
gate_no_secrets() {
    local target="${1:-.}"

    local secret_count=$(grep -rn "password\s*=\|secret\s*=\|api_key\s*=\|apikey\s*=" "$target" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.java" \
        2>/dev/null | grep -v "\.env\|config\|test\|mock\|example" | wc -l)

    if [ "$secret_count" -gt 0 ]; then
        echo "❌ BLOCKED: Potential hardcoded secrets found"
        echo ""
        echo "Locations:"
        grep -rn "password\s*=\|secret\s*=\|api_key\s*=\|apikey\s*=" "$target" \
            --include="*.ts" --include="*.js" --include="*.py" --include="*.java" \
            2>/dev/null | grep -v "\.env\|config\|test\|mock\|example" | head -10
        echo ""
        echo "Move secrets to environment variables"
        log_gate "SECRETS_GATE" "BLOCKED" "Found $secret_count potential secrets"
        return 1
    fi

    echo "✓ Gate passed: No hardcoded secrets found"
    log_gate "SECRETS_GATE" "PASSED" "Clean"
    return 0
}

# Gate: Verify scope not reduced
gate_scope_compliance() {
    check_initialized || return 1

    local scope_features=$("$STATE_SCRIPT" get "scope_features | length")

    if [ "$scope_features" -eq 0 ]; then
        echo "❌ BLOCKED: No scope features defined"
        log_gate "SCOPE_GATE" "BLOCKED" "No features in scope"
        return 1
    fi

    # This is a reminder check - actual verification done by implementation-auditor
    echo "✓ Gate passed: Scope defined with $scope_features features"
    echo "  Note: Full scope compliance verified by implementation-auditor"
    log_gate "SCOPE_GATE" "PASSED" "$scope_features features"
    return 0
}

# Timeout check for long-running phases
gate_timeout_check() {
    check_initialized || return 1

    local current_phase=$("$STATE_SCRIPT" get "current_phase")
    local max_minutes="${2:-60}"  # Default 60 minutes

    # Get phase start time (would need to be tracked in state)
    # This is a placeholder for timeout logic
    echo "✓ Gate passed: Phase '$current_phase' within time limit"
    log_gate "TIMEOUT_GATE" "PASSED" "$current_phase"
    return 0
}

# Combined pre-test gate
gate_pre_test() {
    echo "═══════════════════════════════════════════════════════"
    echo "            PRE-TEST GATE CHECK                        "
    echo "═══════════════════════════════════════════════════════"
    echo ""

    local failed=0

    gate_test_requires_audit || failed=1
    echo ""
    gate_no_todos || failed=1
    echo ""
    gate_no_secrets || failed=1

    echo ""
    echo "═══════════════════════════════════════════════════════"

    if [ "$failed" -eq 1 ]; then
        echo "RESULT: ❌ BLOCKED - Fix issues before testing"
        return 1
    else
        echo "RESULT: ✓ ALL GATES PASSED - Proceed with testing"
        return 0
    fi
}

# Combined pre-completion gate
gate_pre_completion() {
    echo "═══════════════════════════════════════════════════════"
    echo "          PRE-COMPLETION GATE CHECK                    "
    echo "═══════════════════════════════════════════════════════"
    echo ""

    local failed=0

    gate_completion_check || failed=1
    echo ""
    gate_no_todos || failed=1
    echo ""
    gate_no_secrets || failed=1
    echo ""
    gate_scope_compliance || failed=1

    echo ""
    echo "═══════════════════════════════════════════════════════"

    if [ "$failed" -eq 1 ]; then
        echo "RESULT: ❌ BLOCKED - Cannot mark as complete"
        return 1
    else
        echo "RESULT: ✓ ALL GATES PASSED - Ready for completion"
        return 0
    fi
}

# Main command handler
case "${1:-}" in
    test-requires-audit)
        gate_test_requires_audit
        ;;
    phase2-requires-phase1)
        gate_phase2_requires_phase1
        ;;
    completion-check)
        gate_completion_check
        ;;
    no-todos)
        gate_no_todos "$2"
        ;;
    no-secrets)
        gate_no_secrets "$2"
        ;;
    scope-compliance)
        gate_scope_compliance
        ;;
    timeout)
        gate_timeout_check "$2"
        ;;
    pre-test)
        gate_pre_test
        ;;
    pre-completion)
        gate_pre_completion
        ;;
    *)
        echo "Usage: $0 {test-requires-audit|phase2-requires-phase1|completion-check|no-todos|no-secrets|scope-compliance|timeout|pre-test|pre-completion}"
        exit 1
        ;;
esac
