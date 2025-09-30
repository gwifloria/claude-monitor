#!/bin/bash

# SwiftBar Manager Script for ClaudeCode Monitor
# Manages SwiftBar lifecycle: start, stop, restart, and status checking

set -euo pipefail

# Colors for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if SwiftBar is installed
check_swiftbar() {
    if [[ -d "/Applications/SwiftBar.app" ]]; then
        echo "/Applications/SwiftBar.app"
        return 0
    elif [[ -d "$HOME/Applications/SwiftBar.app" ]]; then
        echo "$HOME/Applications/SwiftBar.app"
        return 0
    else
        return 1
    fi
}

# Kill any existing SwiftBar processes
kill_existing_swiftbar() {
    if pgrep -f "SwiftBar" > /dev/null; then
        log_info "Stopping existing SwiftBar processes..."
        pkill -f "SwiftBar" || true
        sleep 2

        # Verify SwiftBar is actually stopped
        local attempts=0
        local max_attempts=5
        while (( attempts < max_attempts )) && pgrep -f "SwiftBar" > /dev/null; do
            sleep 1
            ((attempts++))
        done

        if pgrep -f "SwiftBar" > /dev/null; then
            log_warning "SwiftBar processes still running after graceful shutdown attempt"
        else
            log_success "SwiftBar stopped successfully"
        fi
    fi
}

# Start SwiftBar
start_swiftbar() {
    local swiftbar_path="$1"

    log_info "Starting SwiftBar..."
    open "$swiftbar_path"

    # Wait for SwiftBar to start
    local attempts=0
    local max_attempts=10

    while (( attempts < max_attempts )); do
        if pgrep -f "SwiftBar" > /dev/null; then
            log_success "SwiftBar started successfully"
            return 0
        fi

        sleep 1
        ((attempts++))
    done

    log_error "SwiftBar failed to start within ${max_attempts} seconds"
    return 1
}

# Verify plugin is loaded
verify_plugin() {
    local plugin_path="$HOME/Library/Application Support/SwiftBar/claude_monitor.3s.sh"

    if [[ -f "$plugin_path" ]]; then
        log_success "ClaudeCode Monitor plugin found"

        # Test plugin execution
        if "$plugin_path" > /dev/null 2>&1; then
            log_success "Plugin is working correctly"
        else
            log_warning "Plugin execution test failed - check plugin permissions"
        fi
    else
        log_error "Plugin not found at: $plugin_path"
        return 1
    fi
}

# Show usage instructions
show_instructions() {
    echo
    log_success "SwiftBar with ClaudeCode Monitor is now running!"
    echo
    echo "🔍 Look for the ClaudeCode status icon in your menu bar"
    echo "💤 Currently showing: idle (no active sessions)"
    echo
    echo "📋 To test the monitor:"
    echo "  1. Start a ClaudeCode session in any project"
    echo "  2. Watch the menu bar icon change to show activity"
    echo "  3. Click the icon to see detailed project statuses"
    echo
    echo "🔧 Manual controls:"
    echo "  • Test status: ~/.claude/hooks/update_status.sh processing"
    echo "  • Check status: ~/.claude-monitor/lib/status_manager.sh summary"
    echo "  • Restart SwiftBar: $0 restart"
    echo "  • Stop SwiftBar: $0 stop"
    echo
    echo "🐛 Troubleshooting:"
    echo "  • Enable debug: export CLAUDE_MONITOR_DEBUG=1"
    echo "  • View logs: ~/.claude-monitor/debug.log"
}

# Main function for starting SwiftBar
start_swiftbar_main() {
    echo "🚀 SwiftBar ClaudeCode Monitor Launcher"
    echo "======================================="
    echo

    # Check if SwiftBar is installed
    local swiftbar_path
    if swiftbar_path=$(check_swiftbar); then
        log_success "SwiftBar found at: $swiftbar_path"
    else
        log_error "SwiftBar not found in /Applications or ~/Applications"
        echo
        echo "Install SwiftBar using:"
        echo "  brew install --cask swiftbar"
        echo "  or download from: https://github.com/swiftbar/SwiftBar/releases"
        exit 1
    fi

    # Kill existing SwiftBar
    kill_existing_swiftbar

    # Start SwiftBar
    if start_swiftbar "$swiftbar_path"; then
        sleep 3  # Give SwiftBar time to load plugins
        verify_plugin
        show_instructions
    else
        log_error "Failed to start SwiftBar"
        exit 1
    fi
}

# Stop SwiftBar function
stop_swiftbar_main() {
    echo "🛑 Stopping SwiftBar ClaudeCode Monitor"
    echo "======================================"
    echo

    kill_existing_swiftbar

    # Clear any remaining status to prevent stale display
    if [[ -f "$HOME/.claude-monitor/lib/status_manager.sh" ]]; then
        log_info "Clearing monitor status..."
        "$HOME/.claude-monitor/lib/status_manager.sh" clean || true
    fi

    log_success "SwiftBar monitor stopped"
}

# Handle script arguments
case "${1:-start}" in
    "start")
        start_swiftbar_main
        ;;
    "restart")
        echo "🔄 Restarting SwiftBar ClaudeCode Monitor"
        echo "========================================"
        echo
        stop_swiftbar_main
        echo
        start_swiftbar_main
        ;;
    "stop")
        stop_swiftbar_main
        ;;
    "status")
        echo "📊 SwiftBar ClaudeCode Monitor Status"
        echo "===================================="
        echo
        if pgrep -f "SwiftBar" > /dev/null; then
            log_success "SwiftBar is running"
            verify_plugin
        else
            log_warning "SwiftBar is not running"
            echo
            echo "Start with: $0 start"
        fi
        ;;
    *)
        echo "SwiftBar ClaudeCode Monitor Manager"
        echo "=================================="
        echo
        echo "Usage: $0 {start|restart|stop|status}"
        echo "  start    - Start SwiftBar with ClaudeCode Monitor (default)"
        echo "  restart  - Restart SwiftBar completely"
        echo "  stop     - Stop SwiftBar and clear status"
        echo "  status   - Check if SwiftBar is running and plugin is loaded"
        exit 1
        ;;
esac