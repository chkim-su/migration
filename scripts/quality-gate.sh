#!/bin/bash
# Quality Gate System - Enforces code quality thresholds

STATE_FILE="${MIGRATION_STATE_FILE:-.claude/local/migration-state.json}"
LOG_FILE="${MIGRATION_LOG_FILE:-.claude/local/migration-audit.log}"

# Default thresholds (can be overridden via environment)
MAX_TODO_COUNT="${MAX_TODO_COUNT:-0}"
MAX_FIXME_COUNT="${MAX_FIXME_COUNT:-0}"
MAX_HARDCODE_VIOLATIONS="${MAX_HARDCODE_VIOLATIONS:-0}"
MAX_INCOMPLETE_IMPLS="${MAX_INCOMPLETE_IMPLS:-0}"

log_quality() {
    echo "[$(date -Iseconds)] [QUALITY_GATE] $1" >> "$LOG_FILE"
}

update_metric() {
    local metric="$1"
    local value="$2"
    if [ -f "$STATE_FILE" ]; then
        local tmp=$(mktemp)
        jq ".quality_metrics.$metric = $value" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
    fi
}

# Scan for TODO/FIXME comments
scan_todos() {
    local target="${1:-.}"
    local extensions="*.ts *.js *.py *.java *.go *.rs *.tsx *.jsx"

    local todo_count=0
    local fixme_count=0

    for ext in $extensions; do
        todo_count=$((todo_count + $(find "$target" -name "$ext" -type f -exec grep -l "TODO" {} \; 2>/dev/null | wc -l)))
        fixme_count=$((fixme_count + $(find "$target" -name "$ext" -type f -exec grep -l "FIXME\|XXX\|HACK" {} \; 2>/dev/null | wc -l)))
    done

    update_metric "todo_count" "$todo_count"
    update_metric "fixme_count" "$fixme_count"

    echo "$todo_count $fixme_count"
}

# Scan for hardcoded values
scan_hardcode() {
    local target="${1:-.}"
    local violations=0

    # Check for hardcoded URLs (excluding tests and configs)
    local url_count=$(grep -rn "https\?://[^\"']*" "$target" \
        --include="*.ts" --include="*.js" --include="*.py" \
        2>/dev/null | grep -v "test\|spec\|config\|package.json\|node_modules" | wc -l)

    # Check for hardcoded secrets patterns
    local secret_count=$(grep -rn "password\s*[:=]\s*[\"'][^\"']\+[\"']\|api_key\s*[:=]\s*[\"'][^\"']\+[\"']" "$target" \
        --include="*.ts" --include="*.js" --include="*.py" \
        2>/dev/null | grep -v "test\|spec\|mock\|example\|\.env" | wc -l)

    violations=$((url_count + secret_count))
    update_metric "hardcode_violations" "$violations"

    echo "$violations"
}

# Scan for incomplete implementations
scan_incomplete() {
    local target="${1:-.}"
    local incomplete=0

    # Python: pass statements, NotImplementedError
    incomplete=$((incomplete + $(grep -rn "^\s*pass\s*$\|raise NotImplementedError" "$target" \
        --include="*.py" 2>/dev/null | wc -l)))

    # JavaScript/TypeScript: throw new Error("Not implemented")
    incomplete=$((incomplete + $(grep -rn "throw.*[Nn]ot [Ii]mplemented\|// not implemented\|/\* not implemented" "$target" \
        --include="*.ts" --include="*.js" 2>/dev/null | wc -l)))

    # Empty function bodies
    incomplete=$((incomplete + $(grep -rn "{\s*}\s*$" "$target" \
        --include="*.ts" --include="*.js" 2>/dev/null | wc -l)))

    update_metric "incomplete_implementations" "$incomplete"

    echo "$incomplete"
}

# Full quality scan
full_scan() {
    local target="${1:-.}"

    echo "═══════════════════════════════════════════════════════"
    echo "              QUALITY GATE SCAN                        "
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo "Scanning: $target"
    echo ""

    # Run all scans
    local todos=$(scan_todos "$target")
    local todo_count=$(echo "$todos" | cut -d' ' -f1)
    local fixme_count=$(echo "$todos" | cut -d' ' -f2)
    local hardcode=$(scan_hardcode "$target")
    local incomplete=$(scan_incomplete "$target")

    echo "───────────────────────────────────────────────────────"
    echo "RESULTS:"
    echo "───────────────────────────────────────────────────────"
    printf "  TODO comments:         %3d (max: %d)\n" "$todo_count" "$MAX_TODO_COUNT"
    printf "  FIXME/XXX/HACK:        %3d (max: %d)\n" "$fixme_count" "$MAX_FIXME_COUNT"
    printf "  Hardcode violations:   %3d (max: %d)\n" "$hardcode" "$MAX_HARDCODE_VIOLATIONS"
    printf "  Incomplete impls:      %3d (max: %d)\n" "$incomplete" "$MAX_INCOMPLETE_IMPLS"
    echo ""

    # Check against thresholds
    local failed=0

    if [ "$todo_count" -gt "$MAX_TODO_COUNT" ]; then
        echo "❌ TODO count exceeds threshold"
        failed=1
    fi

    if [ "$fixme_count" -gt "$MAX_FIXME_COUNT" ]; then
        echo "❌ FIXME count exceeds threshold"
        failed=1
    fi

    if [ "$hardcode" -gt "$MAX_HARDCODE_VIOLATIONS" ]; then
        echo "❌ Hardcode violations exceed threshold"
        failed=1
    fi

    if [ "$incomplete" -gt "$MAX_INCOMPLETE_IMPLS" ]; then
        echo "❌ Incomplete implementations exceed threshold"
        failed=1
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════"

    if [ "$failed" -eq 1 ]; then
        echo "QUALITY GATE: ❌ FAILED"
        log_quality "FAILED - TODO:$todo_count FIXME:$fixme_count HARDCODE:$hardcode INCOMPLETE:$incomplete"
        return 1
    else
        echo "QUALITY GATE: ✓ PASSED"
        log_quality "PASSED"
        return 0
    fi
}

# Show violations detail
show_violations() {
    local target="${1:-.}"

    echo "═══════════════════════════════════════════════════════"
    echo "            QUALITY VIOLATIONS DETAIL                  "
    echo "═══════════════════════════════════════════════════════"
    echo ""

    echo "──── TODO/FIXME Comments ────"
    grep -rn "TODO\|FIXME\|XXX\|HACK" "$target" \
        --include="*.ts" --include="*.js" --include="*.py" --include="*.java" \
        2>/dev/null | head -20
    echo ""

    echo "──── Potential Hardcoded Values ────"
    grep -rn "https\?://\|password\s*=\|api_key\s*=" "$target" \
        --include="*.ts" --include="*.js" --include="*.py" \
        2>/dev/null | grep -v "test\|spec\|config\|node_modules" | head -20
    echo ""

    echo "──── Incomplete Implementations ────"
    grep -rn "pass\s*$\|NotImplementedError\|not implemented\|{\s*}\s*$" "$target" \
        --include="*.ts" --include="*.js" --include="*.py" \
        2>/dev/null | head -20
    echo ""
}

# Set custom thresholds
set_thresholds() {
    echo "Current thresholds:"
    echo "  MAX_TODO_COUNT=$MAX_TODO_COUNT"
    echo "  MAX_FIXME_COUNT=$MAX_FIXME_COUNT"
    echo "  MAX_HARDCODE_VIOLATIONS=$MAX_HARDCODE_VIOLATIONS"
    echo "  MAX_INCOMPLETE_IMPLS=$MAX_INCOMPLETE_IMPLS"
    echo ""
    echo "Set via environment variables before running."
}

# Command handler
case "${1:-scan}" in
    scan)
        full_scan "${2:-.}"
        ;;
    todos)
        scan_todos "${2:-.}"
        ;;
    hardcode)
        scan_hardcode "${2:-.}"
        ;;
    incomplete)
        scan_incomplete "${2:-.}"
        ;;
    violations|detail)
        show_violations "${2:-.}"
        ;;
    thresholds)
        set_thresholds
        ;;
    *)
        echo "Usage: $0 {scan|todos|hardcode|incomplete|violations|thresholds} [target_dir]"
        ;;
esac
