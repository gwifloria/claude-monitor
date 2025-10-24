#!/bin/bash

# ClaudeCode Status Manager
# Handles multi-session status management with concurrent safety

set -euo pipefail

# Configuration
readonly STATUS_DIR="$HOME/.claude-monitor"
readonly STATUS_FILE="$STATUS_DIR/sessions.json"
readonly LOCK_FILE="$STATUS_DIR/sessions.lock"
readonly LOCK_TIMEOUT=5

# Create status directory if it doesn't exist
mkdir -p "$STATUS_DIR"

# Initialize empty status file if it doesn't exist
if [[ ! -f "$STATUS_FILE" ]]; then
    echo '{}' > "$STATUS_FILE"
fi

# File locking utilities
acquire_lock() {
    local timeout=$LOCK_TIMEOUT
    while (( timeout > 0 )); do
        if mkdir "$LOCK_FILE" 2>/dev/null; then
            trap 'rmdir "$LOCK_FILE" 2>/dev/null || true' EXIT
            return 0
        fi
        sleep 0.1
        (( timeout-- )) || true
    done
    echo "Error: Could not acquire lock after ${LOCK_TIMEOUT}s" >&2
    return 1
}

release_lock() {
    rmdir "$LOCK_FILE" 2>/dev/null || true
    trap - EXIT
}

# Get current project information
get_project_info() {
    local pwd_path
    local project_name
    local session_id
    local git_root

    # Try to get git root directory first (handles monorepo case)
    git_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

    if [[ -n "$git_root" ]]; then
        # Use git root for session ID (all subdirs share same session)
        pwd_path="$git_root"
    else
        # Fallback to current directory if not in git repo
        pwd_path=$(pwd)
    fi

    project_name=$(basename "$pwd_path")
    # Use MD5 hash of full path for consistent session ID
    session_id=$(echo -n "$pwd_path" | md5 | cut -c1-8)

    echo "$session_id" "$project_name" "$pwd_path"
}

# Status priority mapping
get_status_priority() {
    case "$1" in
        "attention") echo "4" ;;
        "processing") echo "3" ;;
        "completed") echo "2" ;;
        "idle") echo "1" ;;
        "connected") echo "1" ;;
        *) echo "0" ;;
    esac
}

# Update session status
update_status() {
    local status="$1"
    local session_info project_name pwd_path session_id
    local timestamp priority

    read -r session_id project_name pwd_path <<< "$(get_project_info)"
    timestamp=$(date +%s)
    priority=$(get_status_priority "$status")

    acquire_lock || return 1

    # Update status using jq
    jq \
        --arg sid "$session_id" \
        --arg name "$project_name" \
        --arg path "$pwd_path" \
        --arg status "$status" \
        --arg timestamp "$timestamp" \
        --arg priority "$priority" \
        '.[$sid] = {
            "project_name": $name,
            "project_path": $path,
            "status": $status,
            "priority": ($priority | tonumber),
            "timestamp": ($timestamp | tonumber),
            "last_updated": now
        }' \
        "$STATUS_FILE" > "$STATUS_FILE.tmp" && mv "$STATUS_FILE.tmp" "$STATUS_FILE"

    release_lock
}

# Remove session
remove_session() {
    local session_info session_id

    read -r session_id _ _ <<< "$(get_project_info)"

    acquire_lock || return 1

    jq "del(.\"$session_id\")" "$STATUS_FILE" > "$STATUS_FILE.tmp" && mv "$STATUS_FILE.tmp" "$STATUS_FILE"

    release_lock
}

# Clean stale statuses (auto-expire to idle)
# - completed: after 60 seconds
# - attention: after 10 minutes (600 seconds)
# - processing: after 30 minutes without updates (handles time limit scenarios)
clean_expired_completed() {
    local current_time
    current_time=$(date +%s)

    acquire_lock || return 1

    jq \
        --arg current_time "$current_time" \
        'to_entries | map(
            if (.value.status == "completed" and (($current_time | tonumber) - .value.timestamp) > 60) or
               (.value.status == "attention" and (($current_time | tonumber) - .value.timestamp) > 600) or
               (.value.status == "processing" and (($current_time | tonumber) - (.value.last_updated // .value.timestamp)) > 1800) then
                .value.status = "idle" | .value.priority = 1
            else
                .
            end
        ) | from_entries' \
        "$STATUS_FILE" > "$STATUS_FILE.tmp" && mv "$STATUS_FILE.tmp" "$STATUS_FILE"

    release_lock
}

# Clean sessions for dead ClaudeCode processes
# Removes sessions where the corresponding claude process no longer exists
clean_dead_sessions() {
    local current_time
    current_time=$(date +%s)
    local stale_threshold=300  # 5 minutes in seconds

    # Get all active claude CLI process working directories
    local active_dirs=()
    while IFS= read -r pid; do
        [[ -z "$pid" ]] && continue
        # Get working directory for this claude process
        local cwd
        cwd=$(lsof -p "$pid" -a -d cwd -Fn 2>/dev/null | grep '^n' | sed 's/^n//')
        if [[ -n "$cwd" ]]; then
            active_dirs+=("$cwd")
        fi
    done < <(ps aux | grep -E '^\S+\s+\S+.*\sclaude\s*$' | awk '{print $2}')

    acquire_lock || return 1

    # Build a jq filter to check if project_path is in active_dirs
    local active_dirs_json
    active_dirs_json=$(printf '%s\n' "${active_dirs[@]}" | jq -R . | jq -s .)

    jq \
        --argjson active_dirs "$active_dirs_json" \
        --arg current_time "$current_time" \
        --arg threshold "$stale_threshold" \
        'to_entries | map(
            select(
                # Keep session if:
                # 1. Project path is in active directories, OR
                # 2. Session was updated recently (within threshold)
                ([.value.project_path] | inside($active_dirs)) or
                (($current_time | tonumber) - (.value.last_updated // .value.timestamp)) < ($threshold | tonumber)
            )
        ) | from_entries' \
        "$STATUS_FILE" > "$STATUS_FILE.tmp" && mv "$STATUS_FILE.tmp" "$STATUS_FILE"

    release_lock
}

# Check if any sessions exist (for preventing premature display)
has_sessions() {
    if [[ -f "$STATUS_FILE" ]]; then
        local session_count
        session_count=$(jq 'keys | length' "$STATUS_FILE" 2>/dev/null || echo "0")
        if [[ "$session_count" -gt 0 ]]; then
            echo "true"
        else
            echo "false"
        fi
    else
        echo "false"
    fi
}

# Get all sessions with their statuses
get_all_sessions() {
    clean_expired_completed

    if [[ -f "$STATUS_FILE" ]]; then
        jq -r 'to_entries[] | "\(.value.project_name)|\(.value.status)|\(.value.priority)|\(.value.project_path)"' "$STATUS_FILE" 2>/dev/null || true
    fi
}

# Get highest priority status for menu bar
get_summary_status() {
    local max_priority=0
    local summary_status="idle"
    local attention_count=0
    local processing_count=0
    local completed_count=0
    local idle_count=0

    clean_expired_completed

    while IFS='|' read -r project_name status priority project_path; do
        [[ -z "$project_name" ]] && continue

        case "$status" in
            "attention") ((attention_count++)) ;;
            "processing") ((processing_count++)) ;;
            "completed") ((completed_count++)) ;;
            "idle"|"connected") ((idle_count++)) ;;
        esac

        if (( priority > max_priority )); then
            max_priority=$priority
            summary_status="$status"
        fi
    done < <(get_all_sessions)

    # Output: status|attention_count|processing_count|completed_count|idle_count
    echo "${summary_status}|${attention_count}|${processing_count}|${completed_count}|${idle_count}"
}

# Main command dispatcher
case "${1:-}" in
    "update")
        if [[ $# -lt 2 ]]; then
            echo "Usage: $0 update <status>" >&2
            exit 1
        fi
        update_status "$2"
        ;;
    "remove")
        remove_session
        ;;
    "list")
        get_all_sessions
        ;;
    "summary")
        get_summary_status
        ;;
    "clean")
        clean_expired_completed
        ;;
    "clean-dead")
        clean_dead_sessions
        ;;
    "has-sessions")
        has_sessions
        ;;
    *)
        echo "Usage: $0 {update|remove|list|summary|clean|clean-dead|has-sessions} [args...]" >&2
        echo "  update <status>      - Update current project status" >&2
        echo "  remove               - Remove current project session" >&2
        echo "  list                 - List all active sessions" >&2
        echo "  summary              - Get summary for menu bar display" >&2
        echo "  clean                - Clean expired completed statuses" >&2
        echo "  clean-dead           - Clean sessions for dead processes" >&2
        echo "  has-sessions         - Check if any sessions exist" >&2
        exit 1
        ;;
esac