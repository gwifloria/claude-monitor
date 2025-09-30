#!/bin/bash

# ClaudeCode Monitor Installation Script
# Installs SwiftBar integration and configures ClaudeCode hooks

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration - will be updated based on installation choice
CLAUDE_CONFIG_DIR="$HOME/.claude"
CLAUDE_SETTINGS_FILE="$CLAUDE_CONFIG_DIR/settings.json"
readonly CLAUDE_MONITOR_DIR="$HOME/.claude-monitor"
readonly SWIFTBAR_PLUGINS_DIR="$HOME/Library/Application Support/SwiftBar"
INSTALL_SCOPE="global"  # global or project

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Progress bar function
show_progress() {
    local current=$1
    local total=$2
    local message=$3
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))

    printf "\r${BLUE}  [${NC}"
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '·'
    printf "${BLUE}] %d%% - %s${NC}" "$percentage" "$message"

    if [[ $current -eq $total ]]; then
        echo
    fi
}

# Check if Homebrew is available
check_homebrew() {
    command -v brew &> /dev/null
}

# Install SwiftBar via Homebrew
install_swiftbar_homebrew() {
    log_info "Installing SwiftBar via Homebrew..."

    show_progress 1 4 "Updating Homebrew..."
    if ! brew update &> /dev/null; then
        log_error "Failed to update Homebrew"
        return 1
    fi

    show_progress 2 4 "Installing SwiftBar..."
    if ! brew install --cask swiftbar &> /dev/null; then
        log_error "Failed to install SwiftBar via Homebrew"
        return 1
    fi

    show_progress 3 4 "Verifying installation..."
    sleep 1

    show_progress 4 4 "Installation complete"
    log_success "SwiftBar installed successfully via Homebrew"
    return 0
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."

    # Check for jq
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed"
        if check_homebrew; then
            read -p "Install jq via Homebrew? (Y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Nn]$ ]]; then
                echo "Install jq manually using: brew install jq"
                exit 1
            fi
            log_info "Installing jq..."
            if brew install jq; then
                log_success "jq installed successfully"
            else
                log_error "Failed to install jq"
                exit 1
            fi
        else
            echo "Install jq using: brew install jq"
            exit 1
        fi
    fi

    # Check for SwiftBar
    if [[ ! -d "/Applications/SwiftBar.app" ]] && [[ ! -d "$HOME/Applications/SwiftBar.app" ]]; then
        log_warning "SwiftBar not found in Applications folder"
        echo
        echo "SwiftBar is required for menu bar monitoring."

        if check_homebrew; then
            echo "Options:"
            echo "1) Auto-install SwiftBar via Homebrew (recommended)"
            echo "2) Manual installation"
            echo "3) Continue without SwiftBar (monitoring disabled)"
            echo
            read -p "Choose option (1-3) [1]: " -n 1 -r
            echo

            case "${REPLY:-1}" in
                1)
                    if install_swiftbar_homebrew; then
                        log_success "SwiftBar installation completed"
                    else
                        log_error "SwiftBar auto-installation failed"
                        echo "Please install manually: brew install --cask swiftbar"
                        exit 1
                    fi
                    ;;
                2)
                    echo "Manual installation options:"
                    echo "• Homebrew: brew install --cask swiftbar"
                    echo "• Direct download: https://github.com/swiftbar/SwiftBar/releases"
                    echo ""
                    read -p "Continue after installing SwiftBar manually? (Y/n): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Nn]$ ]]; then
                        exit 1
                    fi
                    ;;
                3)
                    log_warning "Continuing without SwiftBar - menu bar monitoring will be disabled"
                    ;;
                *)
                    log_warning "Invalid choice, attempting auto-installation"
                    install_swiftbar_homebrew || {
                        echo "Please install manually: brew install --cask swiftbar"
                        exit 1
                    }
                    ;;
            esac
        else
            echo "Options:"
            echo "1) Install Homebrew and SwiftBar automatically"
            echo "2) Manual installation (you handle it)"
            echo "3) Continue without SwiftBar (monitoring disabled)"
            echo
            read -p "Choose option (1-3) [1]: " -n 1 -r
            echo

            case "${REPLY:-1}" in
                1)
                    log_info "Installing Homebrew first..."
                    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
                        install_swiftbar_homebrew || {
                            echo "Please install manually: brew install --cask swiftbar"
                            exit 1
                        }
                    else
                        log_error "Failed to install Homebrew"
                        exit 1
                    fi
                    ;;
                2)
                    echo "Please install SwiftBar manually:"
                    echo "• Download from: https://github.com/swiftbar/SwiftBar/releases"
                    echo "• Or install Homebrew first, then: brew install --cask swiftbar"
                    exit 1
                    ;;
                3)
                    log_warning "Continuing without SwiftBar - menu bar monitoring will be disabled"
                    ;;
                *)
                    log_warning "Invalid choice, please install SwiftBar manually"
                    exit 1
                    ;;
            esac
        fi
    else
        log_success "SwiftBar found"
    fi

    # Check for ClaudeCode
    if [[ "$INSTALL_SCOPE" == "global" ]]; then
        if [[ ! -d "$CLAUDE_CONFIG_DIR" ]]; then
            log_warning "ClaudeCode global configuration directory not found"
            echo "Make sure ClaudeCode is installed and has been run at least once"
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        else
            log_success "ClaudeCode global configuration directory found"
        fi
    else
        log_info "Project-specific installation: will create .claude directory as needed"
    fi
}

# Backup existing configuration
backup_config() {
    if [[ -f "$CLAUDE_SETTINGS_FILE" ]]; then
        local backup_file="${CLAUDE_SETTINGS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backing up existing settings to: $backup_file"
        cp "$CLAUDE_SETTINGS_FILE" "$backup_file"

        # Ensure monitor directory exists before writing backup path
        mkdir -p "$CLAUDE_MONITOR_DIR"
        echo "$backup_file" > "$CLAUDE_MONITOR_DIR/backup_path.txt"
        log_success "Configuration backed up"
    else
        log_info "No existing settings.json found, will create new one"
    fi
}

# Install core files
install_core_files() {
    log_info "Installing core files..."

    # Create directories
    mkdir -p "$CLAUDE_MONITOR_DIR"
    mkdir -p "$CLAUDE_MONITOR_DIR/lib"
    mkdir -p "$CLAUDE_CONFIG_DIR"

    # Copy status manager
    cp "$SCRIPT_DIR/lib/status_manager.sh" "$CLAUDE_MONITOR_DIR/lib/"
    chmod +x "$CLAUDE_MONITOR_DIR/lib/status_manager.sh"

    # Create hooks directory in ClaudeCode config
    mkdir -p "$CLAUDE_CONFIG_DIR/hooks"
    cp "$SCRIPT_DIR/hooks/update_status.sh" "$CLAUDE_CONFIG_DIR/hooks/"
    chmod +x "$CLAUDE_CONFIG_DIR/hooks/update_status.sh"

    # Copy SwiftBar manager script
    mkdir -p "$CLAUDE_MONITOR_DIR/scripts"
    cp "$SCRIPT_DIR/scripts/swiftbar_manager.sh" "$CLAUDE_MONITOR_DIR/scripts/"
    chmod +x "$CLAUDE_MONITOR_DIR/scripts/swiftbar_manager.sh"

    log_success "Core files installed"
}

# Configure ClaudeCode hooks
configure_claude_hooks() {
    log_info "Configuring ClaudeCode hooks..."

    local temp_settings="/tmp/claude_settings_$$.json"
    local merge_mode="replace"

    if [[ -f "$CLAUDE_SETTINGS_FILE" ]]; then
        # Check if existing hooks would conflict
        local has_conflicting_hooks=false
        local hook_types=("UserPromptSubmit" "Notification" "SubagentStop" "Stop" "SessionStart" "SessionEnd")

        for hook_type in "${hook_types[@]}"; do
            if jq -e ".hooks.\"$hook_type\"" "$CLAUDE_SETTINGS_FILE" > /dev/null 2>&1; then
                has_conflicting_hooks=true
                break
            fi
        done

        if [[ "$has_conflicting_hooks" == "true" ]]; then
            echo
            log_warning "Existing ClaudeCode hooks detected!"
            echo "How should we handle existing hooks?"
            echo "1) Replace - Override existing hooks with monitor hooks (recommended)"
            echo "2) Append  - Add monitor hooks alongside existing ones"
            echo "3) Preserve - Keep existing hooks (monitor won't work)"
            echo
            read -p "Choose option (1-3) [1]: " -n 1 -r
            echo

            case "${REPLY:-1}" in
                1) merge_mode="replace" ;;
                2) merge_mode="append" ;;
                3) merge_mode="preserve" ;;
                *)
                    log_warning "Invalid choice, using replace mode"
                    merge_mode="replace"
                    ;;
            esac
        fi

        log_info "Merging with existing configuration (mode: $merge_mode)..."
        "$SCRIPT_DIR/scripts/generate_settings.sh" merge "$CLAUDE_SETTINGS_FILE" "$merge_mode" > "$temp_settings"
    else
        # Create new configuration
        log_info "Creating new configuration..."
        "$SCRIPT_DIR/scripts/generate_settings.sh" generate > "$temp_settings"
    fi

    # Validate JSON
    if jq . "$temp_settings" > /dev/null 2>&1; then
        mv "$temp_settings" "$CLAUDE_SETTINGS_FILE"
        log_success "ClaudeCode hooks configured"
    else
        log_error "Generated configuration is invalid JSON"
        rm -f "$temp_settings"
        exit 1
    fi
}

# Install SwiftBar plugin
install_swiftbar_plugin() {
    log_info "Installing SwiftBar plugin..."

    # Create SwiftBar plugins directory
    mkdir -p "$SWIFTBAR_PLUGINS_DIR"

    # Copy plugin file (3s refresh rate for balanced performance)
    cp "$SCRIPT_DIR/plugins/claude_monitor.3s.sh" "$SWIFTBAR_PLUGINS_DIR/"
    chmod +x "$SWIFTBAR_PLUGINS_DIR/claude_monitor.3s.sh"

    # Update plugin to use correct status manager path
    sed -i '' "s|readonly STATUS_MANAGER=\".*\"|readonly STATUS_MANAGER=\"$CLAUDE_MONITOR_DIR/lib/status_manager.sh\"|" \
        "$SWIFTBAR_PLUGINS_DIR/claude_monitor.3s.sh"

    log_success "SwiftBar plugin installed"
}

# Show SwiftBar startup instructions
show_swiftbar_instructions() {
    echo
    echo "🚀 SwiftBar Monitor Ready"
    echo "========================="
    log_success "Installation complete! SwiftBar plugin is ready to use."
    echo
    echo "To start monitoring:"
    echo "  $CLAUDE_MONITOR_DIR/scripts/swiftbar_manager.sh"
    echo
    echo "Manual controls:"
    echo "  • Start:   $CLAUDE_MONITOR_DIR/scripts/swiftbar_manager.sh start"
    echo "  • Stop:    $CLAUDE_MONITOR_DIR/scripts/swiftbar_manager.sh stop"
    echo "  • Restart: $CLAUDE_MONITOR_DIR/scripts/swiftbar_manager.sh restart"
    echo "  • Status:  $CLAUDE_MONITOR_DIR/scripts/swiftbar_manager.sh status"
    echo
    echo "🚀 Launch SwiftBar Monitor"
    echo "========================="
    read -p "Start SwiftBar with ClaudeCode monitoring now? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        log_info "Starting SwiftBar..."
        if "$CLAUDE_MONITOR_DIR/scripts/swiftbar_manager.sh" start; then
            echo
            log_success "SwiftBar monitor is now running!"
            echo "Look for the ClaudeCode status icon in your menu bar"
        else
            log_warning "Failed to start SwiftBar automatically"
            echo "You can start it manually later using:"
            echo "$CLAUDE_MONITOR_DIR/scripts/swiftbar_manager.sh start"
        fi
    else
        echo
        log_info "SwiftBar not started automatically"
        echo "Start it when ready using:"
        echo "$CLAUDE_MONITOR_DIR/scripts/swiftbar_manager.sh start"
    fi
}

# Show installation summary
show_summary() {
    echo
    log_success "ClaudeCode Monitor installation completed!"
    echo
    echo "📋 Installation Summary:"
    echo "  • Installation scope: $INSTALL_SCOPE"
    echo "  • Status manager: $CLAUDE_MONITOR_DIR/lib/status_manager.sh"
    echo "  • Hooks script: $CLAUDE_CONFIG_DIR/hooks/update_status.sh"
    echo "  • SwiftBar plugin: $SWIFTBAR_PLUGINS_DIR/claude_monitor.3s.sh"
    echo "  • SwiftBar manager: $CLAUDE_MONITOR_DIR/scripts/swiftbar_manager.sh"
    echo "  • Configuration: $CLAUDE_SETTINGS_FILE"
    echo
    echo "🔧 Manual controls:"
    echo "  • Start SwiftBar: $CLAUDE_MONITOR_DIR/scripts/swiftbar_manager.sh start"
    echo "  • Test status: $CLAUDE_CONFIG_DIR/hooks/update_status.sh processing"
    echo "  • Check status: $CLAUDE_MONITOR_DIR/lib/status_manager.sh summary"
    echo
    echo "🐛 Troubleshooting:"
    echo "  • Debug mode: export CLAUDE_MONITOR_DEBUG=1"
    echo "  • Log file: $CLAUDE_MONITOR_DIR/debug.log"
    echo
    echo "🗑️  To uninstall: ./uninstall.sh"
}

# Test installation
test_installation() {
    log_info "Testing installation..."

    # Test status manager
    if "$CLAUDE_MONITOR_DIR/lib/status_manager.sh" summary > /dev/null; then
        log_success "Status manager working"
    else
        log_error "Status manager test failed"
        exit 1
    fi

    # Test SwiftBar plugin
    if [[ -f "$SWIFTBAR_PLUGINS_DIR/claude_monitor.3s.sh" ]]; then
        log_success "SwiftBar plugin installed"
    else
        log_warning "SwiftBar plugin not found - check SwiftBar installation"
    fi
}

# Choose installation scope
choose_installation_scope() {
    echo "📍 Installation Scope"
    echo "===================="
    echo
    echo "Choose installation type:"
    echo
    echo "1) Global Installation (recommended)"
    echo "   • Monitors all ClaudeCode sessions across projects"
    echo "   • Uses ~/.claude/settings.json"
    echo "   • Works system-wide"
    echo
    echo "2) Project-Specific Installation"
    echo "   • Only monitors ClaudeCode in current directory"
    echo "   • Uses ./.claude/settings.json"
    echo "   • Requires setup in each project"
    echo
    read -p "Choose installation type (1-2) [1]: " -n 1 -r
    echo

    case "${REPLY:-1}" in
        1)
            INSTALL_SCOPE="global"
            CLAUDE_CONFIG_DIR="$HOME/.claude"
            CLAUDE_SETTINGS_FILE="$CLAUDE_CONFIG_DIR/settings.json"
            log_success "Global installation selected"
            ;;
        2)
            INSTALL_SCOPE="project"
            CLAUDE_CONFIG_DIR="$(pwd)/.claude"
            CLAUDE_SETTINGS_FILE="$CLAUDE_CONFIG_DIR/settings.json"
            log_success "Project-specific installation selected"
            log_info "Installation directory: $CLAUDE_CONFIG_DIR"
            ;;
        *)
            log_warning "Invalid choice, defaulting to global installation"
            INSTALL_SCOPE="global"
            CLAUDE_CONFIG_DIR="$HOME/.claude"
            CLAUDE_SETTINGS_FILE="$CLAUDE_CONFIG_DIR/settings.json"
            ;;
    esac
}

# Main installation process
main() {
    echo "🚀 ClaudeCode Monitor Installer"
    echo "================================"
    echo

    # Confirmation
    read -p "Install ClaudeCode Monitor? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi

    choose_installation_scope
    check_dependencies
    backup_config
    install_core_files
    configure_claude_hooks
    install_swiftbar_plugin
    test_installation
    show_summary
    show_swiftbar_instructions
}

# Error handling
trap 'log_error "Installation failed at line $LINENO"' ERR

# Run main installation
main "$@"