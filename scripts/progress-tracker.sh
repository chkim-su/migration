#!/bin/bash
# Progress Tracker - Visual progress display and milestone tracking

STATE_FILE="${MIGRATION_STATE_FILE:-.claude/local/migration-state.json}"

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

get_state() {
    if [ -f "$STATE_FILE" ]; then
        jq -r "$1 // empty" "$STATE_FILE" 2>/dev/null
    fi
}

# Calculate overall progress percentage
calculate_progress() {
    local completed=0
    local total=9

    local phases=("scope_selection" "scope_definition" "solid_analysis" "migration_planning" "implementation" "final_audit" "phase1_testing" "phase2_testing" "completion")

    for phase in "${phases[@]}"; do
        local status=$(get_state ".phases.$phase.status")
        if [ "$status" = "completed" ]; then
            ((completed++))
        fi
    done

    echo "$((completed * 100 / total))"
}

# Draw progress bar
draw_progress_bar() {
    local percent=$1
    local width=40
    local filled=$((percent * width / 100))
    local empty=$((width - filled))

    printf "["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %d%%\n" "$percent"
}

# Get phase icon based on status
get_phase_icon() {
    local status=$1
    case "$status" in
        "completed") echo -e "${GREEN}✓${NC}";;
        "in_progress") echo -e "${YELLOW}→${NC}";;
        "failed") echo -e "${RED}✗${NC}";;
        "pending") echo -e "○";;
        *) echo " ";;
    esac
}

# Get gate icon
get_gate_icon() {
    local passed=$1
    if [ "$passed" = "true" ]; then
        echo -e "${GREEN}●${NC}"
    else
        echo -e "○"
    fi
}

# Display full dashboard
show_dashboard() {
    if [ ! -f "$STATE_FILE" ]; then
        echo -e "${RED}No migration in progress${NC}"
        echo "Run /migrate to start a new migration"
        return 1
    fi

    local percent=$(calculate_progress)
    local current_phase=$(get_state ".current_phase")
    local scope_type=$(get_state ".scope_type")
    local workflow_id=$(get_state ".workflow_id")
    local started_at=$(get_state ".started_at")

    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║               STRICT MIGRATION PROGRESS DASHBOARD                ║${NC}"
    echo -e "${BOLD}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo ""

    # Progress bar
    echo -e "  ${BOLD}Overall Progress:${NC}"
    echo -n "  "
    draw_progress_bar "$percent"
    echo ""

    # Current status
    echo -e "  ${BOLD}Current Phase:${NC} ${CYAN}$current_phase${NC}"
    echo -e "  ${BOLD}Scope Type:${NC} $scope_type"
    [ -n "$started_at" ] && echo -e "  ${BOLD}Started:${NC} $started_at"
    echo ""

    # Phase status
    echo -e "${BOLD}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}║  WORKFLOW PHASES                                                 ║${NC}"
    echo -e "${BOLD}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo ""

    local phases=("scope_selection:Scope Selection" "scope_definition:Scope Definition" "solid_analysis:SOLID Analysis" "migration_planning:Migration Planning" "implementation:Implementation" "final_audit:Final Audit" "phase1_testing:Phase 1 (Static)" "phase2_testing:Phase 2 (Simulation)" "completion:Completion")

    for phase_info in "${phases[@]}"; do
        local phase_key="${phase_info%%:*}"
        local phase_name="${phase_info##*:}"
        local status=$(get_state ".phases.$phase_key.status")
        local icon=$(get_phase_icon "$status")
        local completed_at=$(get_state ".phases.$phase_key.completed_at")

        printf "  %s %-25s " "$icon" "$phase_name"

        case "$status" in
            "completed")
                echo -e "${GREEN}[DONE]${NC} $completed_at"
                ;;
            "in_progress")
                echo -e "${YELLOW}[IN PROGRESS]${NC}"
                ;;
            "failed")
                echo -e "${RED}[FAILED]${NC}"
                ;;
            *)
                echo "[pending]"
                ;;
        esac
    done

    echo ""

    # Gate status
    echo -e "${BOLD}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}║  QUALITY GATES                                                   ║${NC}"
    echo -e "${BOLD}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo ""

    local gates=("scope_confirmed:Scope Confirmed" "plan_approved:Plan Approved" "all_phases_audited:All Phases Audited" "final_audit_passed:Final Audit Passed" "static_tests_passed:Static Tests (Phase 1)" "simulation_tests_passed:Simulation Tests (Phase 2)")

    for gate_info in "${gates[@]}"; do
        local gate_key="${gate_info%%:*}"
        local gate_name="${gate_info##*:}"
        local passed=$(get_state ".gates_passed.$gate_key")
        local icon=$(get_gate_icon "$passed")

        printf "  %s %-30s " "$icon" "$gate_name"
        if [ "$passed" = "true" ]; then
            echo -e "${GREEN}PASSED${NC}"
        else
            echo -e "${RED}NOT PASSED${NC}"
        fi
    done

    echo ""

    # Quality metrics
    echo -e "${BOLD}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}║  QUALITY METRICS                                                 ║${NC}"
    echo -e "${BOLD}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo ""

    local todo_count=$(get_state ".quality_metrics.todo_count")
    local fixme_count=$(get_state ".quality_metrics.fixme_count")
    local hardcode=$(get_state ".quality_metrics.hardcode_violations")
    local incomplete=$(get_state ".quality_metrics.incomplete_implementations")

    printf "  TODO comments:      %s\n" "${todo_count:-0}"
    printf "  FIXME comments:     %s\n" "${fixme_count:-0}"
    printf "  Hardcode issues:    %s\n" "${hardcode:-0}"
    printf "  Incomplete impls:   %s\n" "${incomplete:-0}"

    echo ""
    echo -e "${BOLD}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Show compact one-line status
show_compact() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "No migration"
        return
    fi

    local percent=$(calculate_progress)
    local current=$(get_state ".current_phase")
    local scope=$(get_state ".scope_type")

    echo "[$percent%] $current ($scope)"
}

# Show next required action
show_next_action() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "Run /migrate to start"
        return
    fi

    local current=$(get_state ".current_phase")

    # Determine next action based on current phase and gates
    local final_audit=$(get_state ".gates_passed.final_audit_passed")
    local static_tests=$(get_state ".gates_passed.static_tests_passed")
    local sim_tests=$(get_state ".gates_passed.simulation_tests_passed")

    if [ "$sim_tests" = "true" ]; then
        echo -e "${GREEN}All complete! Ready to finalize.${NC}"
    elif [ "$static_tests" = "true" ]; then
        echo -e "${YELLOW}REQUIRED: Run Phase 2 simulation tests${NC}"
        echo "  → Launch simulation-test-runner"
    elif [ "$final_audit" = "true" ]; then
        echo -e "${YELLOW}REQUIRED: Run Phase 1 static tests${NC}"
        echo "  → Launch test-orchestrator or static-test-runner"
    else
        case "$current" in
            "implementation"|"final_audit")
                echo -e "${YELLOW}REQUIRED: Pass final audit${NC}"
                echo "  → Run /audit"
                ;;
            *)
                echo -e "${BLUE}Continue with: $current${NC}"
                ;;
        esac
    fi
}

# Command handler
case "${1:-dashboard}" in
    dashboard|status)
        show_dashboard
        ;;
    compact)
        show_compact
        ;;
    next)
        show_next_action
        ;;
    percent)
        calculate_progress
        ;;
    *)
        echo "Usage: $0 {dashboard|compact|next|percent}"
        ;;
esac
