#!/bin/bash

# ClaudeCode Monitor Uninstaller
# Safely removes all components and restores original configuration

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly CLAUDE_CONFIG_DIR="$HOME/.claude"
readonly CLAUDE_SETTINGS_FILE="$CLAUDE_CONFIG_DIR/settings.json"
readonly CLAUDE_MONITOR_DIR="$HOME/.claude-monitor"
readonly SWIFTBAR_PLUGINS_DIR="$HOME/Library/Application Support/SwiftBar"
readonly BACKUP_PATH_FILE="$CLAUDE_MONITOR_DIR/backup_path.txt"

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

# Show what will be removed
show_removal_plan() {
    echo "🗑️  ClaudeCode Monitor Uninstaller"
    echo "=================================="
    echo
    echo "The following will be removed:"
    echo

    # Check what exists
    if [[ -d "$CLAUDE_MONITOR_DIR" ]]; then
        echo "📁 Monitor directory: $CLAUDE_MONITOR_DIR"
    fi

    if [[ -f "$SWIFTBAR_PLUGINS_DIR/claude_monitor.5s.sh" ]]; then
        echo "🔌 SwiftBar plugin: $SWIFTBAR_PLUGINS_DIR/claude_monitor.5s.sh"
    fi

    if [[ -f "$CLAUDE_CONFIG_DIR/hooks/update_status.sh" ]]; then
        echo "🪝 Hook script: $CLAUDE_CONFIG_DIR/hooks/update_status.sh"
    fi

    echo "⚙️  ClaudeCode hooks configuration (from settings.json)"
    echo

    # Check for backup
    if [[ -f "$BACKUP_PATH_FILE" ]]; then
        local backup_file
        backup_file=$(cat "$BACKUP_PATH_FILE")
        if [[ -f "$backup_file" ]]; then
            echo "🔄 Configuration will be restored from backup: $backup_file"
        fi
    else
        echo "⚠️  No backup found - hooks will be removed from settings.json"
    fi

    echo
}

# Remove ClaudeCode hooks from configuration
remove_claude_hooks() {
    log_info "Removing ClaudeCode hooks configuration..."

    if [[ ! -f "$CLAUDE_SETTINGS_FILE" ]]; then
        log_warning "No settings.json file found"
        return 0
    fi

    # Check if we have a backup to restore
    if [[ -f "$BACKUP_PATH_FILE" ]]; then
        local backup_file
        backup_file=$(cat "$BACKUP_PATH_FILE")

        if [[ -f "$backup_file" ]]; then
            log_info "Restoring configuration from backup: $backup_file"
            cp "$backup_file" "$CLAUDE_SETTINGS_FILE"
            log_success "Configuration restored from backup"
            return 0
        else
            log_warning "Backup file not found: $backup_file"
        fi
    fi

    # No backup available, remove our hooks manually
    log_info "Removing monitor hooks from settings.json..."

    local temp_settings="/tmp/claude_settings_$$.json"
    local hooks_to_remove=("UserPromptSubmit" "Notification" "SubagentStop" "Stop" "SessionStart" "SessionEnd")

    cp "$CLAUDE_SETTINGS_FILE" "$temp_settings"

    for hook_name in "${hooks_to_remove[@]}"; do
        # Check if this hook contains our command
        if jq -r ".hooks.\"$hook_name\"[]?.hooks[]?.command // empty" "$temp_settings" | grep -q "update_status.sh" 2>/dev/null; then
            log_info "Removing hook: $hook_name"

            # Precisely remove only hooks containing update_status.sh, with layer-by-layer cleanup
            jq "
                if .hooks.\"$hook_name\" then
                    .hooks.\"$hook_name\" = [
                        .hooks.\"$hook_name\"[] |
                        # Clean hooks array: remove only hooks with update_status.sh
                        .hooks = [.hooks[] | select(.command | contains(\"update_status.sh\") | not)] |
                        # Keep matcher only if hooks array is not empty
                        select(.hooks | length > 0)
                    ] |
                    # Remove lifecycle hook if no matchers remain
                    if .hooks.\"$hook_name\" | length == 0 then
                        del(.hooks.\"$hook_name\")
                    else
                        .
                    end
                else
                    .
                end
            " "$temp_settings" > "${temp_settings}.new" && mv "${temp_settings}.new" "$temp_settings"
        fi
    done

    # Validate and update settings
    if jq . "$temp_settings" > /dev/null 2>&1; then
        mv "$temp_settings" "$CLAUDE_SETTINGS_FILE"
        log_success "Hooks removed from configuration"
    else
        log_error "Failed to update settings.json"
        rm -f "$temp_settings"
        return 1
    fi
}

# Remove SwiftBar plugin
remove_swiftbar_plugin() {
    log_info "Removing SwiftBar plugin..."

    if [[ -f "$SWIFTBAR_PLUGINS_DIR/claude_monitor.5s.sh" ]]; then
        rm -f "$SWIFTBAR_PLUGINS_DIR/claude_monitor.5s.sh"
        log_success "SwiftBar plugin removed"
    else
        log_info "SwiftBar plugin not found"
    fi
}

# Remove hook script
remove_hook_script() {
    log_info "Removing hook script..."

    if [[ -f "$CLAUDE_CONFIG_DIR/hooks/update_status.sh" ]]; then
        rm -f "$CLAUDE_CONFIG_DIR/hooks/update_status.sh"
        log_success "Hook script removed"

        # Remove hooks directory if empty
        if [[ -d "$CLAUDE_CONFIG_DIR/hooks" ]] && [[ -z "$(ls -A "$CLAUDE_CONFIG_DIR/hooks")" ]]; then
            rmdir "$CLAUDE_CONFIG_DIR/hooks"
            log_info "Removed empty hooks directory"
        fi
    else
        log_info "Hook script not found"
    fi
}

# Remove monitor directory
remove_monitor_directory() {
    log_info "Removing monitor directory..."

    if [[ -d "$CLAUDE_MONITOR_DIR" ]]; then
        rm -rf "$CLAUDE_MONITOR_DIR"
        log_success "Monitor directory removed"
    else
        log_info "Monitor directory not found"
    fi
}

# Clean up any remaining processes
cleanup_processes() {
    log_info "Cleaning up any running processes..."

    # Kill any background status manager processes (unlikely but safe)
    pkill -f "status_manager.sh" 2>/dev/null || true

    log_success "Process cleanup complete"
}

# Show uninstall summary
show_summary() {
    echo
    log_success "ClaudeCode Monitor uninstallation completed!"
    echo
    echo "📋 Removal Summary:"
    echo "  • All monitor files removed"
    echo "  • SwiftBar plugin removed"
    echo "  • ClaudeCode hooks configuration cleaned"
    echo "  • Configuration restored from backup (if available)"
    echo
    echo "🔧 Next steps:"
    echo "  1. Restart SwiftBar to remove the plugin from menu bar"
    echo "  2. Restart ClaudeCode sessions to apply configuration changes"
    echo
    echo "📝 Note:"
    echo "  • Your original ClaudeCode settings have been preserved"
    echo "  • No user data or projects were affected"
}

# Confirmation prompt
confirm_uninstall() {
    echo
    read -p "Proceed with uninstallation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstallation cancelled"
        exit 0
    fi
}

# Main uninstallation process
main() {
    show_removal_plan
    confirm_uninstall

    echo "Starting uninstallation..."
    echo

    cleanup_processes
    remove_claude_hooks
    remove_swiftbar_plugin
    remove_hook_script
    remove_monitor_directory

    show_summary
}

# Error handling
trap 'log_error "Uninstallation failed at line $LINENO"' ERR

# Run main uninstallation
main "$@"