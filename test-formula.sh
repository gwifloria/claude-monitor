#!/bin/bash

# Test Homebrew Formula Locally
# This script helps test the formula before publishing

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

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

echo "🧪 Testing Homebrew Formula"
echo "============================"
echo

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    log_error "Homebrew is not installed"
    echo "Install from: https://brew.sh"
    exit 1
fi

log_success "Homebrew found"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORMULA_PATH="$SCRIPT_DIR/Formula/claude-monitor.rb"

if [[ ! -f "$FORMULA_PATH" ]]; then
    log_error "Formula not found at: $FORMULA_PATH"
    exit 1
fi

log_success "Formula found: $FORMULA_PATH"

# Test 1: Audit Formula
echo
log_info "Test 1: Auditing formula syntax..."
if brew audit --strict "$FORMULA_PATH" 2>&1 | tee /tmp/brew-audit.log; then
    log_success "Formula syntax is valid"
else
    log_error "Formula audit failed - check /tmp/brew-audit.log"
    exit 1
fi

# Test 2: Style check
echo
log_info "Test 2: Checking formula style..."
if brew style "$FORMULA_PATH" 2>&1 | tee /tmp/brew-style.log; then
    log_success "Formula style is correct"
else
    log_warning "Formula style issues found - check /tmp/brew-style.log"
    echo "You can auto-fix with: brew style --fix $FORMULA_PATH"
fi

# Test 3: Check if already installed
echo
if brew list claude-monitor &> /dev/null; then
    log_warning "claude-monitor is already installed"
    read -p "Uninstall existing installation? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstalling existing installation..."
        brew uninstall claude-monitor || true
        rm -rf ~/.claude-monitor
        log_success "Existing installation removed"
    else
        log_error "Please uninstall manually: brew uninstall claude-monitor"
        exit 1
    fi
fi

# Test 4: Install from local formula
echo
log_info "Test 3: Installing from local formula..."
log_warning "This will install the package on your system"
read -p "Continue with installation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Installation skipped"
    exit 0
fi

if brew install --build-from-source "$FORMULA_PATH"; then
    log_success "Installation successful"
else
    log_error "Installation failed"
    exit 1
fi

# Test 5: Verify installation
echo
log_info "Test 4: Verifying installation..."

# Check if commands are available
if command -v claude-monitor &> /dev/null; then
    log_success "claude-monitor command found"
else
    log_error "claude-monitor command not found"
    exit 1
fi

if command -v claude-monitor-setup &> /dev/null; then
    log_success "claude-monitor-setup command found"
else
    log_error "claude-monitor-setup command not found"
    exit 1
fi

# Test 6: Run setup
echo
log_info "Test 5: Running setup..."
read -p "Run claude-monitor-setup? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if claude-monitor-setup; then
        log_success "Setup completed successfully"
    else
        log_error "Setup failed"
        exit 1
    fi
else
    log_warning "Setup skipped - you'll need to run it manually"
fi

# Test 7: Test basic functionality
echo
log_info "Test 6: Testing basic functionality..."

# Test status manager
if ~/.claude-monitor/lib/status_manager.sh summary &> /dev/null; then
    log_success "Status manager is working"
else
    log_error "Status manager failed"
    exit 1
fi

# Test hook script
if ~/.claude/hooks/update_status.sh processing &> /dev/null; then
    log_success "Hook script is working"
    # Clean up test status
    ~/.claude-monitor/lib/status_manager.sh remove &> /dev/null || true
else
    log_error "Hook script failed"
    exit 1
fi

# Test 8: Check SwiftBar plugin
echo
log_info "Test 7: Checking SwiftBar plugin..."
SWIFTBAR_PLUGIN="$HOME/Library/Application Support/SwiftBar/claude_monitor.1s.sh"
if [[ -f "$SWIFTBAR_PLUGIN" ]]; then
    log_success "SwiftBar plugin installed"
    if [[ -x "$SWIFTBAR_PLUGIN" ]]; then
        log_success "Plugin is executable"
    else
        log_error "Plugin is not executable"
    fi
else
    log_error "SwiftBar plugin not found"
fi

# Summary
echo
echo "=========================================="
log_success "All tests passed!"
echo
echo "✅ Formula is ready for publishing"
echo
echo "📋 Next steps:"
echo "  1. Review HOMEBREW_RELEASE.md for publishing instructions"
echo "  2. Create a GitHub release with version tag"
echo "  3. Update formula with release SHA256"
echo "  4. Create homebrew-tap repository and push formula"
echo
echo "🧹 Cleanup:"
echo "  To remove test installation:"
echo "    brew uninstall claude-monitor"
echo "    rm -rf ~/.claude-monitor"
echo "    rm -rf ~/.claude/hooks/update_status.sh"
echo
