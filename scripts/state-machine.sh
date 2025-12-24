#!/bin/bash
# Strict Migration State Machine
# Tracks workflow state and enforces phase transitions

STATE_FILE="${MIGRATION_STATE_FILE:-.claude/local/migration-state.json}"
LOG_FILE="${MIGRATION_LOG_FILE:-.claude/local/migration-audit.log}"

# Initialize state file if not exists
init_state() {
    mkdir -p "$(dirname "$STATE_FILE")"
    mkdir -p "$(dirname "$LOG_FILE")"

    if [ ! -f "$STATE_FILE" ]; then
        cat > "$STATE_FILE" << 'EOF'
{
    "workflow_id": "",
    "started_at": "",
    "scope_type": "",
    "scope_features": [],
    "current_phase": "not_started",
    "phases": {
        "scope_selection": {"status": "pending", "completed_at": null},
        "scope_definition": {"status": "pending", "completed_at": null},
        "solid_analysis": {"status": "pending", "completed_at": null},
        "migration_planning": {"status": "pending", "completed_at": null},
        "implementation": {"status": "pending", "sub_phases": [], "completed_at": null},
        "final_audit": {"status": "pending", "verdict": null, "completed_at": null},
        "phase1_testing": {"status": "pending", "verdict": null, "completed_at": null},
        "phase2_testing": {"status": "pending", "verdict": null, "completed_at": null},
        "completion": {"status": "pending", "completed_at": null}
    },
    "gates_passed": {
        "scope_confirmed": false,
        "plan_approved": false,
        "all_phases_audited": false,
        "final_audit_passed": false,
        "static_tests_passed": false,
        "simulation_tests_passed": false
    },
    "quality_metrics": {
        "todo_count": 0,
        "fixme_count": 0,
        "hardcode_violations": 0,
        "incomplete_implementations": 0
    },
    "audit_history": [],
    "rollback_points": []
}
EOF
        log_action "STATE_INIT" "State machine initialized"
    fi
}

# Log action to audit trail
log_action() {
    local action="$1"
    local message="$2"
    local timestamp=$(date -Iseconds)
    echo "[$timestamp] [$action] $message" >> "$LOG_FILE"
}

# Get current state
get_state() {
    local key="$1"
    if [ -f "$STATE_FILE" ]; then
        jq -r ".$key // empty" "$STATE_FILE"
    fi
}

# Set state value
set_state() {
    local key="$1"
    local value="$2"
    if [ -f "$STATE_FILE" ]; then
        local tmp=$(mktemp)
        jq ".$key = $value" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
        log_action "STATE_UPDATE" "$key = $value"
    fi
}

# Check if phase can be started
can_start_phase() {
    local phase="$1"

    case "$phase" in
        "scope_selection")
            echo "true"
            ;;
        "scope_definition")
            [ "$(get_state 'phases.scope_selection.status')" = "completed" ] && echo "true" || echo "false"
            ;;
        "solid_analysis")
            [ "$(get_state 'gates_passed.scope_confirmed')" = "true" ] && echo "true" || echo "false"
            ;;
        "migration_planning")
            [ "$(get_state 'phases.solid_analysis.status')" = "completed" ] && echo "true" || echo "false"
            ;;
        "implementation")
            [ "$(get_state 'gates_passed.plan_approved')" = "true" ] && echo "true" || echo "false"
            ;;
        "final_audit")
            [ "$(get_state 'phases.implementation.status')" = "completed" ] && echo "true" || echo "false"
            ;;
        "phase1_testing")
            [ "$(get_state 'gates_passed.final_audit_passed')" = "true" ] && echo "true" || echo "false"
            ;;
        "phase2_testing")
            [ "$(get_state 'gates_passed.static_tests_passed')" = "true" ] && echo "true" || echo "false"
            ;;
        "completion")
            [ "$(get_state 'gates_passed.simulation_tests_passed')" = "true" ] && echo "true" || echo "false"
            ;;
        *)
            echo "false"
            ;;
    esac
}

# Start a phase
start_phase() {
    local phase="$1"

    if [ "$(can_start_phase "$phase")" != "true" ]; then
        echo "ERROR: Cannot start phase '$phase' - prerequisites not met"
        log_action "PHASE_BLOCKED" "Attempted to start $phase without prerequisites"
        return 1
    fi

    set_state "current_phase" "\"$phase\""
    set_state "phases.$phase.status" "\"in_progress\""
    log_action "PHASE_START" "Started phase: $phase"
    echo "Phase '$phase' started"
}

# Complete a phase
complete_phase() {
    local phase="$1"
    local timestamp=$(date -Iseconds)

    set_state "phases.$phase.status" "\"completed\""
    set_state "phases.$phase.completed_at" "\"$timestamp\""
    log_action "PHASE_COMPLETE" "Completed phase: $phase"
    echo "Phase '$phase' completed"
}

# Pass a gate
pass_gate() {
    local gate="$1"
    set_state "gates_passed.$gate" "true"
    log_action "GATE_PASSED" "Gate passed: $gate"
    echo "Gate '$gate' passed"
}

# Fail a gate
fail_gate() {
    local gate="$1"
    local reason="$2"
    log_action "GATE_FAILED" "Gate failed: $gate - $reason"
    echo "ERROR: Gate '$gate' failed - $reason"
    return 1
}

# Create rollback point
create_rollback_point() {
    local name="$1"
    local timestamp=$(date -Iseconds)
    local git_commit=$(git rev-parse HEAD 2>/dev/null || echo "no-git")

    local rollback_point="{\"name\": \"$name\", \"timestamp\": \"$timestamp\", \"git_commit\": \"$git_commit\"}"

    # Append to rollback_points array
    local tmp=$(mktemp)
    jq ".rollback_points += [$rollback_point]" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
    log_action "ROLLBACK_POINT" "Created: $name at $git_commit"
    echo "Rollback point '$name' created"
}

# Get progress percentage
get_progress() {
    local completed=0
    local total=9  # Total number of phases

    for phase in scope_selection scope_definition solid_analysis migration_planning implementation final_audit phase1_testing phase2_testing completion; do
        if [ "$(get_state "phases.$phase.status")" = "completed" ]; then
            ((completed++))
        fi
    done

    echo "$((completed * 100 / total))"
}

# Print status summary
print_status() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "No migration in progress"
        return
    fi

    echo "═══════════════════════════════════════════════════════════════"
    echo "                    MIGRATION STATUS                           "
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "Progress: $(get_progress)%"
    echo "Current Phase: $(get_state 'current_phase')"
    echo "Scope Type: $(get_state 'scope_type')"
    echo ""
    echo "─────────────────────────────────────────────────────────────────"
    echo "PHASES:"
    echo "─────────────────────────────────────────────────────────────────"

    for phase in scope_selection scope_definition solid_analysis migration_planning implementation final_audit phase1_testing phase2_testing completion; do
        local status=$(get_state "phases.$phase.status")
        local icon=""
        case "$status" in
            "completed") icon="✓";;
            "in_progress") icon="→";;
            "pending") icon="○";;
            "failed") icon="✗";;
        esac
        printf "  %s %-20s [%s]\n" "$icon" "$phase" "$status"
    done

    echo ""
    echo "─────────────────────────────────────────────────────────────────"
    echo "GATES:"
    echo "─────────────────────────────────────────────────────────────────"

    for gate in scope_confirmed plan_approved all_phases_audited final_audit_passed static_tests_passed simulation_tests_passed; do
        local passed=$(get_state "gates_passed.$gate")
        local icon="○"
        [ "$passed" = "true" ] && icon="✓"
        printf "  %s %s\n" "$icon" "$gate"
    done

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
}

# Main command handler
case "${1:-}" in
    init)
        init_state
        ;;
    get)
        get_state "$2"
        ;;
    set)
        set_state "$2" "$3"
        ;;
    can-start)
        can_start_phase "$2"
        ;;
    start-phase)
        start_phase "$2"
        ;;
    complete-phase)
        complete_phase "$2"
        ;;
    pass-gate)
        pass_gate "$2"
        ;;
    fail-gate)
        fail_gate "$2" "$3"
        ;;
    rollback-point)
        create_rollback_point "$2"
        ;;
    progress)
        get_progress
        ;;
    status)
        print_status
        ;;
    *)
        echo "Usage: $0 {init|get|set|can-start|start-phase|complete-phase|pass-gate|fail-gate|rollback-point|progress|status}"
        exit 1
        ;;
esac
