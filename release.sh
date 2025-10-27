#!/bin/bash

# ClaudeCode Monitor Release Automation Script
# Usage: ./release.sh [patch|minor|major|VERSION]
# Example: ./release.sh patch
#          ./release.sh 0.3.0

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/gwifloria/claude-monitor"
VERSION_FILE="VERSION"
FORMULA_FILE="Formula/claude-monitor.rb"
CHANGELOG_FILE="CHANGELOG.md"

# Helper functions
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

log_step() {
    echo -e "\n${PURPLE}▶ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not a git repository"
        exit 1
    fi

    # Check if on main branch
    current_branch=$(git branch --show-current)
    if [[ "$current_branch" != "main" ]]; then
        log_error "Not on main branch (current: $current_branch)"
        echo "Please switch to main branch: git checkout main"
        exit 1
    fi

    # Check if working directory is clean
    if [[ -n $(git status --porcelain) ]]; then
        log_error "Working directory is not clean"
        echo "Please commit or stash your changes first"
        git status --short
        exit 1
    fi

    # Check if required files exist
    if [[ ! -f "$VERSION_FILE" ]]; then
        log_error "$VERSION_FILE not found"
        exit 1
    fi

    if [[ ! -f "$FORMULA_FILE" ]]; then
        log_error "$FORMULA_FILE not found"
        exit 1
    fi

    if [[ ! -f "$CHANGELOG_FILE" ]]; then
        log_error "$CHANGELOG_FILE not found"
        exit 1
    fi

    log_success "All prerequisites met"
}

# Get current version from VERSION file
get_current_version() {
    cat "$VERSION_FILE" | tr -d '\n'
}

# Calculate next version based on bump type
calculate_next_version() {
    local current_version=$1
    local bump_type=$2

    # Parse version components
    if [[ ! $current_version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        log_error "Invalid version format: $current_version"
        exit 1
    fi

    local major="${BASH_REMATCH[1]}"
    local minor="${BASH_REMATCH[2]}"
    local patch="${BASH_REMATCH[3]}"

    case "$bump_type" in
        patch)
            echo "$major.$minor.$((patch + 1))"
            ;;
        minor)
            echo "$major.$((minor + 1)).0"
            ;;
        major)
            echo "$((major + 1)).0.0"
            ;;
        *)
            log_error "Invalid bump type: $bump_type"
            exit 1
            ;;
    esac
}

# Validate version format
validate_version() {
    local version=$1
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Invalid version format: $version (expected: X.Y.Z)"
        exit 1
    fi
}

# Check if version tag already exists
check_version_exists() {
    local version=$1
    if git rev-parse "v$version" >/dev/null 2>&1; then
        log_error "Version v$version already exists"
        exit 1
    fi
}

# Update VERSION file
update_version_file() {
    local version=$1
    log_info "Updating $VERSION_FILE to $version"
    echo "$version" > "$VERSION_FILE"
    log_success "$VERSION_FILE updated"
}

# Update Formula file
update_formula() {
    local version=$1
    log_info "Updating $FORMULA_FILE"

    # Update version line
    sed -i '' "s/version \".*\"/version \"$version\"/" "$FORMULA_FILE"

    # Update url line
    sed -i '' "s|url \".*\"|url \"$REPO_URL/archive/refs/tags/v$version.tar.gz\"|" "$FORMULA_FILE"

    # Clear sha256 (will be calculated by GitHub Actions)
    sed -i '' 's/sha256 \".*\"/sha256 ""/' "$FORMULA_FILE"

    log_success "$FORMULA_FILE updated"
}

# Insert CHANGELOG entry
update_changelog() {
    local version=$1
    local date=$(date +%Y-%m-%d)

    log_info "Updating $CHANGELOG_FILE"

    # Create temporary file with new entry
    local temp_file=$(mktemp)

    # Read existing changelog
    if [[ -f "$CHANGELOG_FILE" ]]; then
        cat "$CHANGELOG_FILE" > "$temp_file"
    else
        echo "# Changelog" > "$temp_file"
        echo "" >> "$temp_file"
        echo "All notable changes to ClaudeCode Monitor will be documented in this file." >> "$temp_file"
        echo "" >> "$temp_file"
        echo "The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)," >> "$temp_file"
        echo "and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)." >> "$temp_file"
        echo "" >> "$temp_file"
    fi

    # Find the insertion point (after "## [Unreleased]" or after header)
    local insert_line=$(grep -n "^## \[Unreleased\]" "$temp_file" | cut -d: -f1 | head -1)
    if [[ -z "$insert_line" ]]; then
        # Find first "##" after header
        insert_line=$(grep -n "^## " "$temp_file" | cut -d: -f1 | head -1)
        if [[ -z "$insert_line" ]]; then
            # No existing versions, append to end
            insert_line=$(wc -l < "$temp_file")
            insert_line=$((insert_line + 1))
        fi
    else
        insert_line=$((insert_line + 2))
    fi

    # Create new changelog with inserted entry
    head -n $((insert_line - 1)) "$temp_file" > "$CHANGELOG_FILE"
    cat >> "$CHANGELOG_FILE" << EOF

## [$version] - $date

### Added

-

### Changed

-

### Fixed

-

EOF
    tail -n +$insert_line "$temp_file" >> "$CHANGELOG_FILE"

    rm "$temp_file"

    log_success "$CHANGELOG_FILE template inserted"
    log_warning "Please edit $CHANGELOG_FILE to add release notes"
}

# Show diff preview
show_diff_preview() {
    log_step "Changes preview:"
    echo ""
    git diff --color=always "$VERSION_FILE" "$FORMULA_FILE" "$CHANGELOG_FILE" | head -50
    echo ""
}

# Prompt for confirmation
confirm_release() {
    local current_version=$1
    local new_version=$2

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Release Summary${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  Current version: ${YELLOW}$current_version${NC}"
    echo -e "  New version:     ${GREEN}$new_version${NC}"
    echo -e "  Branch:          ${BLUE}$(git branch --show-current)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    read -p "Do you want to proceed with the release? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Release cancelled"
        exit 0
    fi
}

# Open editor for CHANGELOG
edit_changelog() {
    log_step "Opening $CHANGELOG_FILE for editing..."

    # Detect editor
    local editor="${EDITOR:-vi}"
    if command -v code >/dev/null 2>&1; then
        editor="code --wait"
    elif command -v nano >/dev/null 2>&1; then
        editor="nano"
    fi

    log_info "Press Enter to open editor ($editor)..."
    read -r

    $editor "$CHANGELOG_FILE"

    # Check if changes were made
    if git diff --quiet "$CHANGELOG_FILE"; then
        log_warning "No changes made to $CHANGELOG_FILE"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Release cancelled - please update CHANGELOG"
            exit 1
        fi
    fi

    log_success "CHANGELOG updated"
}

# Git operations
perform_git_operations() {
    local version=$1

    log_step "Performing git operations..."

    # Stage changes
    log_info "Staging changes..."
    git add "$VERSION_FILE" "$FORMULA_FILE" "$CHANGELOG_FILE"

    # Commit
    log_info "Creating commit..."
    git commit -m "Release v$version"

    # Create tag
    log_info "Creating tag v$version..."
    git tag -a "v$version" -m "Release version $version"

    log_success "Git commit and tag created"
}

# Push changes
push_changes() {
    local version=$1

    log_step "Pushing changes to remote..."

    # Push commits
    log_info "Pushing commits to origin/main..."
    git push origin main

    # Push tags
    log_info "Pushing tag v$version..."
    git push origin "v$version"

    log_success "Changes pushed to remote"
}

# Open GitHub Release page
open_github_release() {
    local version=$1
    local url="$REPO_URL/releases/new?tag=v$version"

    log_step "Opening GitHub Release page..."
    log_info "URL: $url"

    if command -v open >/dev/null 2>&1; then
        open "$url"
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url"
    else
        log_warning "Could not open browser automatically"
        echo "Please open: $url"
    fi
}

# Main function
main() {
    echo -e "${PURPLE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║         ClaudeCode Monitor Release Automation            ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Check arguments
    if [[ $# -ne 1 ]]; then
        log_error "Usage: $0 [patch|minor|major|VERSION]"
        echo "Examples:"
        echo "  $0 patch    # 0.2.2 → 0.2.3"
        echo "  $0 minor    # 0.2.2 → 0.3.0"
        echo "  $0 major    # 0.2.2 → 1.0.0"
        echo "  $0 0.3.0    # Explicit version"
        exit 1
    fi

    local version_input=$1

    # Check prerequisites
    check_prerequisites

    # Get current version
    local current_version=$(get_current_version)
    log_info "Current version: $current_version"

    # Determine new version
    local new_version
    if [[ "$version_input" =~ ^(patch|minor|major)$ ]]; then
        new_version=$(calculate_next_version "$current_version" "$version_input")
        log_info "Calculated new version: $new_version (bump: $version_input)"
    else
        new_version=$version_input
        validate_version "$new_version"
        log_info "Using explicit version: $new_version"
    fi

    # Check if version already exists
    check_version_exists "$new_version"

    # Update files
    log_step "Updating files..."
    update_version_file "$new_version"
    update_formula "$new_version"
    update_changelog "$new_version"

    # Show preview
    show_diff_preview

    # Edit CHANGELOG
    edit_changelog

    # Confirm release
    confirm_release "$current_version" "$new_version"

    # Git operations
    perform_git_operations "$new_version"

    # Push changes
    push_changes "$new_version"

    # Success message
    echo ""
    log_success "Release v$new_version completed successfully! 🎉"
    echo ""
    log_info "Next steps:"
    echo "  1. GitHub Actions will automatically update homebrew-tap"
    echo "  2. Create GitHub Release with release notes"
    echo ""

    # Open GitHub Release page
    open_github_release "$new_version"

    echo ""
    log_info "Monitor GitHub Actions: $REPO_URL/actions"
    log_info "Verify homebrew-tap: https://github.com/gwifloria/homebrew-tap/commits/main"
    echo ""
}

# Run main function
main "$@"
