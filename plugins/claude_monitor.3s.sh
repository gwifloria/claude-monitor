#!/bin/bash

# SwiftBar Plugin: ClaudeCode Status Monitor
# Shows ClaudeCode status in macOS menu bar with smart refresh rates

# SwiftBar metadata
# <swiftbar.title>ClaudeCode Monitor</swiftbar.title>
# <swiftbar.version>v1.0</swiftbar.version>
# <swiftbar.author>ClaudeCode Monitor</swiftbar.author>
# <swiftbar.author.github>your-github</swiftbar.author.github>
# <swiftbar.desc>Monitor ClaudeCode status across multiple projects</swiftbar.desc>
# <swiftbar.dependencies>jq</swiftbar.dependencies>

set -euo pipefail

# Configuration
readonly STATUS_MANAGER="$HOME/.claude-monitor/lib/status_manager.sh"
readonly REFRESH_CONFIG="$HOME/.claude-monitor/refresh_rate.txt"

# Check if status manager exists
if [[ ! -f "$STATUS_MANAGER" ]]; then
    get_attention_display ""
    echo "---"
    echo "ClaudeCode Monitor not installed"
    echo "Run installation script to set up monitoring"
    exit 0
fi


# Function to get static attention display
get_attention_display() {
    local count="$1"
    echo "⚠️ $count | color=#ea6161"    # Static warning icon
}

# Get animated loading icon for processing status
get_loading_animation() {
    # Get current timestamp in milliseconds using Perl (macOS compatible)
    # Animation is independent of SwiftBar refresh rate
    local milliseconds=$(perl -MTime::HiRes=time -e 'printf "%.0f", time()*1000')

    # Calculate which frame to show (5 frames, 200ms per frame = 1 second per rotation)
    # This ensures smooth animation even with 3s or 30s SwiftBar refresh intervals
    local frame=$(((milliseconds / 200) % 5))

    # Continuous clockwise rotation using 3-dot braille patterns
    # Each frame shows 3 dots forming a rotating arc
    # Braille grid: [0,0]=⠁ [1,0]=⠈ [0,1]=⠂ [1,1]=⠐ [0,2]=⠄ [1,2]=⠠
    case $frame in
        0) echo "⠇" ;;  # Left side: [0,0]+[0,1]+[0,2]
        1) echo "⠆" ;;  # Bottom: [0,1]+[0,2]+[1,2]
        2) echo "⠴" ;;  # Right side: [0,2]+[1,2]+[1,1]
        3) echo "⠸" ;;  # Right-top: [1,2]+[1,1]+[1,0]
        4) echo "⠉" ;;  # Top: [1,0]+[0,0]+[0,1]
    esac
}

# Function to get status icon and color
get_status_display() {
    local status="$1"
    local count="$2"

    case "$status" in
        "attention")
            get_attention_display "$count"
            ;;
        "processing")
            animation=$(get_loading_animation)
            echo "$animation $count | color=#333333 font=Menlo"
            ;;
        "completed")
            echo "✅ $count | color=green"
            ;;
        "idle")
            if [[ "$count" == "0" ]]; then
                echo "💤 | color=gray"
            else
                echo "💤 $count | color=gray"
            fi
            ;;
        *)
            echo "❓ | color=gray"
            ;;
    esac
}

# Function to update refresh rate based on status
update_refresh_rate() {
    local has_attention="$1"
    local has_processing="$2"

    if [[ "$has_attention" == "true" ]]; then
        # Attention state: refresh every 10 seconds
        echo "10s" > "$REFRESH_CONFIG"
    elif [[ "$has_processing" == "true" ]]; then
        # Processing state: refresh every 15 seconds
        echo "15s" > "$REFRESH_CONFIG"
    else
        # Idle state: refresh every 15 seconds
        echo "15s" > "$REFRESH_CONFIG"
    fi
}

# Get summary status
summary_output=$("$STATUS_MANAGER" summary)
IFS='|' read -r main_status attention_count processing_count completed_count idle_count <<< "$summary_output"

# Calculate total active sessions
total_sessions=$((attention_count + processing_count + completed_count + idle_count))

# Check if there are any sessions at all (not just active ones)
has_any_sessions=$("$STATUS_MANAGER" has-sessions 2>/dev/null || echo "false")

# Determine what to display in menu bar
if [[ "$has_any_sessions" == "false" ]] || [[ "$total_sessions" == "0" ]]; then
    # Only show the monitor icon if ClaudeCode sessions have been started
    # This prevents showing 💤 when no ClaudeCode session has ever been initiated
    echo "💤0 | color=gray dropdown=false"  # Show sleep icon with 0 count when no sessions
    echo "---"
    echo "ClaudeCode Monitor (Inactive)"
    echo "No ClaudeCode sessions detected"
    echo "---"
    echo "The monitor will activate when you start ClaudeCode"
    echo "🚀 Start ClaudeCode in any project to begin monitoring"
    echo "---"
    echo "ClaudeCode Monitor v1.0 | color=gray size=12"
    update_refresh_rate "false" "false"
    exit 0
fi

# Display main status
case "$main_status" in
    "attention")
        get_status_display "attention" "$attention_count"
        ;;
    "processing")
        total_active=$((attention_count + processing_count))
        if [[ "$attention_count" -gt 0 ]]; then
            get_status_display "attention" "$attention_count"
        else
            get_status_display "processing" "$processing_count"
        fi
        ;;
    "completed")
        if [[ "$attention_count" -gt 0 ]]; then
            get_status_display "attention" "$attention_count"
        elif [[ "$processing_count" -gt 0 ]]; then
            get_status_display "processing" "$processing_count"
        else
            get_status_display "completed" "$completed_count"
        fi
        ;;
    *)
        get_status_display "idle" "$idle_count"
        ;;
esac

# Update refresh rate
update_refresh_rate "$([[ $attention_count -gt 0 ]] && echo "true" || echo "false")" "$([[ $processing_count -gt 0 ]] && echo "true" || echo "false")"

# Dropdown menu
echo "---"

# Status summary
if [[ "$attention_count" -gt 0 ]]; then
    echo "⚠️ $attention_count need attention | color=#ea6161"
fi
if [[ "$processing_count" -gt 0 ]]; then
    animation=$(get_loading_animation)
    echo "$animation $processing_count processing | color=#333333 font=Menlo"
fi
if [[ "$completed_count" -gt 0 ]]; then
    echo "✅ $completed_count completed | color=green"
fi
if [[ "$idle_count" -gt 0 ]]; then
    echo "💤 $idle_count idle | color=gray"
fi

echo "---"

# Individual project statuses
echo "Projects:"
session_count=0
while IFS='|' read -r project_name status priority project_path; do
    [[ -z "$project_name" ]] && continue

    ((session_count++))

    case "$status" in
        "attention")
            echo "  ⚠️ $project_name | color=#ea6161 bash='cd \"$project_path\" && claude' terminal=true"
            ;;
        "processing")
            animation=$(get_loading_animation)
            echo "  $animation $project_name | color=#333333 font=Menlo bash='cd \"$project_path\" && claude' terminal=true"
            ;;
        "completed")
            echo "  ✅ $project_name | color=green bash='cd \"$project_path\" && claude' terminal=true"
            ;;
        "idle"|"connected")
            echo "  💤 $project_name | color=gray bash='cd \"$project_path\" && claude' terminal=true"
            ;;
    esac

    # Show project path as submenu
    echo "    📁 $project_path | color=gray size=12"

done < <("$STATUS_MANAGER" list)

if [[ "$session_count" == "0" ]]; then
    echo "  No active sessions"
fi

echo "---"
echo "🧹 Clean expired statuses | bash='$STATUS_MANAGER clean' terminal=false refresh=true"
echo "🔄 Refresh | refresh=true"
echo "---"
echo "ClaudeCode Monitor v1.0 | color=gray size=12"
echo "📊 Total sessions: $total_sessions | color=gray size=12"

# Show current refresh rate
current_refresh=$(cat "$REFRESH_CONFIG" 2>/dev/null || echo "5s")
echo "⏱️ Refresh rate: $current_refresh | color=gray size=12"