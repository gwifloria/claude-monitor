#!/bin/bash

# ClaudeCode Hook: Status Update Script
# Called by ClaudeCode hooks to update project status

set -euo pipefail

# Use absolute path to status manager
STATUS_MANAGER="$HOME/.claude-monitor/lib/status_manager.sh"

# Check if status manager exists
if [[ ! -f "$STATUS_MANAGER" ]]; then
    echo "Error: Status manager not found at $STATUS_MANAGER" >&2
    exit 1
fi

# Validate input
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <status>" >&2
    echo "Valid statuses: processing, attention, completed, idle, connected, disconnected" >&2
    exit 1
fi

STATUS="$1"

# Validate status value
case "$STATUS" in
    "processing"|"attention"|"completed"|"idle"|"connected"|"disconnected")
        ;;
    *)
        echo "Error: Invalid status '$STATUS'" >&2
        echo "Valid statuses: processing, attention, completed, idle, connected, disconnected" >&2
        exit 1
        ;;
esac

# Special handling for session management
case "$STATUS" in
    "connected")
        # Session start: register new session
        "$STATUS_MANAGER" update "connected"
        ;;
    "disconnected")
        # Session end: remove session
        "$STATUS_MANAGER" remove
        ;;
    *)
        # Regular status update - only proceed if session exists or we're initializing
        # This prevents premature status updates before session starts
        if [[ "$STATUS" == "processing" ]] || [[ "$STATUS" == "attention" ]]; then
            # For processing/attention, always create session if it doesn't exist
            "$STATUS_MANAGER" update "$STATUS"
        else
            # For other statuses, only update if session already exists
            has_sessions=$("$STATUS_MANAGER" has-sessions 2>/dev/null || echo "false")
            if [[ "$has_sessions" == "true" ]]; then
                "$STATUS_MANAGER" update "$STATUS"
            elif [[ "${CLAUDE_MONITOR_DEBUG:-}" == "1" ]]; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Ignoring $STATUS update - no active sessions" >> "$HOME/.claude-monitor/debug.log"
            fi
        fi
        ;;
esac

# Log the update (optional, for debugging)
if [[ "${CLAUDE_MONITOR_DEBUG:-}" == "1" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Updated status to: $STATUS (PID: $$, PWD: $(pwd))" >> "$HOME/.claude-monitor/debug.log"
fi