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

# Extract commit message and generate CHANGELOG entry
extract_commit_changelog() {
    local version=$1
    local date=$2

    # Get commit message
    local commit_subject=$(git log -1 --format='%s' 2>/dev/null || echo "")
    local commit_body=$(git log -1 --format='%b' 2>/dev/null || echo "")

    # Detect commit type and map to CHANGELOG section
    local section="Changed"  # default
    if [[ $commit_subject =~ ^feat:.*$ ]] || [[ $commit_subject =~ ^feature:.*$ ]]; then
        section="Added"
    elif [[ $commit_subject =~ ^fix:.*$ ]]; then
        section="Fixed"
    elif [[ $commit_subject =~ ^docs:.*$ ]]; then
        section="Changed"
    elif [[ $commit_subject =~ ^refactor:.*$ ]]; then
        section="Changed"
    elif [[ $commit_subject =~ ^chore:.*$ ]]; then
        section="Changed"
    fi

    # Clean commit body (remove ClaudeCode footer and empty lines)
    local clean_body=$(echo "$commit_body" | sed -e '/^🤖 Generated with/,$d' -e '/^$/d' -e '/^Co-Authored-By:/d')

    # If body is empty or too short, use subject
    if [[ -z "$clean_body" ]] || [[ $(echo "$clean_body" | wc -l) -lt 2 ]]; then
        # Remove commit type prefix (e.g., "feat: " -> "")
        local clean_subject=$(echo "$commit_subject" | sed -E 's/^[a-z]+: //')
        clean_body="- $clean_subject"
    else
        # Format body content (ensure bullet points)
        clean_body=$(echo "$clean_body" | sed '/^-/!s/^/- /')
    fi

    # Return formatted CHANGELOG entry
    cat << EOF

## [$version] - $date

### $section

$clean_body

EOF
}

# Extract CHANGELOG content for a specific version
extract_version_changelog() {
    local version=$1

    # Use awk to extract content between version headers
    awk -v version="$version" '
        /^## \['"$version"'\]/ { found=1; next }
        found && /^## \[/ { exit }
        found { print }
    ' "$CHANGELOG_FILE"
}

# Insert CHANGELOG entry
update_changelog() {
    local version=$1
    local date=$(date +%Y-%m-%d)

    log_info "Updating $CHANGELOG_FILE with commit message..."

    # Create temporary file for CHANGELOG manipulation
    local temp_file=$(mktemp)

    # Read existing changelog or create new one
    if [[ -f "$CHANGELOG_FILE" ]]; then
        cat "$CHANGELOG_FILE" > "$temp_file"
    else
        cat > "$temp_file" << 'CHANGELOG_HEADER'
# Changelog

All notable changes to ClaudeCode Monitor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

CHANGELOG_HEADER
    fi

    # Find the insertion point (after "## [Unreleased]" or after header)
    local insert_line=$(grep -n "^## \[Unreleased\]" "$temp_file" | cut -d: -f1 | head -1)
    if [[ -z "$insert_line" ]]; then
        # Find first "##" after header
        insert_line=$(grep -n "^## " "$temp_file" | cut -d: -f1 | head -1)
        if [[ -z "$insert_line" ]]; then
            # No existing versions, append after header
            insert_line=$(wc -l < "$temp_file")
            insert_line=$((insert_line + 1))
        fi
    else
        insert_line=$((insert_line + 2))
    fi

    # Generate CHANGELOG entry from commit message
    local changelog_entry=$(extract_commit_changelog "$version" "$date")

    # Create new changelog with inserted entry
    head -n $((insert_line - 1)) "$temp_file" > "$CHANGELOG_FILE"
    echo "$changelog_entry" >> "$CHANGELOG_FILE"
    tail -n +$insert_line "$temp_file" >> "$CHANGELOG_FILE"

    rm "$temp_file"

    # Show what was extracted
    log_success "$CHANGELOG_FILE automatically updated from commit message"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  📝 Extracted CHANGELOG Entry${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "$changelog_entry" | sed 's/^/  /'
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
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

# Open editor for CHANGELOG (optional manual review/edit)
edit_changelog() {
    log_step "Opening $CHANGELOG_FILE for manual review..."

    # Detect editor
    local editor="${EDITOR:-vi}"
    if command -v code >/dev/null 2>&1; then
        editor="code --wait"
    elif command -v nano >/dev/null 2>&1; then
        editor="nano"
    fi

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  📝 CHANGELOG Manual Review${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "  The CHANGELOG has been auto-populated from your commit."
    echo ""
    echo "  You can now:"
    echo "  • Review the extracted content"
    echo "  • Add more details if needed"
    echo "  • Reorganize sections"
    echo "  • Or keep it as-is"
    echo ""
    echo "  ${GREEN}To proceed:${NC}"
    echo "  1. Review/edit the content in the editor"
    echo "  2. Save the file"
    echo "  3. CLOSE the editor window/tab (important!)"
    echo "  4. The script will continue automatically"
    echo ""
    echo -e "  ${YELLOW}⚠️  Do NOT press Ctrl+C (this will abort the release)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log_info "Press Enter to open editor ($editor)..."
    read -r

    echo "⏳ Waiting for you to close the editor..."
    $editor "$CHANGELOG_FILE"
    echo "✅ Editor closed!"

    # Check if changes were made
    if git diff --quiet "$CHANGELOG_FILE"; then
        log_info "No additional changes made (using auto-generated content)"
    else
        log_success "CHANGELOG manually updated"
    fi
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

# Create GitHub Release using gh CLI
create_github_release() {
    local version=$1

    log_step "Creating GitHub Release..."

    # Check if gh CLI is installed
    if ! command -v gh >/dev/null 2>&1; then
        log_warning "gh CLI not installed - falling back to browser"
        log_info "Install gh CLI: brew install gh"
        open_github_release "$version"
        return
    fi

    # Check if gh is authenticated
    if ! gh auth status >/dev/null 2>&1; then
        log_warning "gh CLI not authenticated - falling back to browser"
        log_info "Run: gh auth login"
        open_github_release "$version"
        return
    fi

    # Generate release title (remove commit type prefix)
    local commit_subject=$(git log -1 --format='%s')
    local release_title=$(echo "$commit_subject" | sed -E 's/^[a-z]+: //')

    # Extract CHANGELOG content for this version
    local release_notes=$(extract_version_changelog "$version")

    # If release notes are empty, use commit message
    if [[ -z "$release_notes" ]]; then
        release_notes="$commit_subject"
    fi

    # Create release using gh CLI
    log_info "Creating release v$version with gh CLI..."

    if echo "$release_notes" | gh release create "v$version" \
        --title "v$version - $release_title" \
        --notes-file - \
        --latest; then

        local release_url="$REPO_URL/releases/tag/v$version"
        log_success "GitHub Release created successfully!"
        log_info "Release URL: $release_url"

        # Open release in browser
        if command -v open >/dev/null 2>&1; then
            open "$release_url"
        elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$release_url"
        fi
    else
        log_error "Failed to create GitHub Release"
        log_warning "Falling back to manual release creation"
        open_github_release "$version"
    fi
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
    if [[ $# -lt 1 ]] || [[ $# -gt 2 ]]; then
        log_error "Usage: $0 [patch|minor|major|VERSION] [--edit]"
        echo ""
        echo "Examples:"
        echo "  $0 patch         # 0.2.2 → 0.2.3 (fully automated)"
        echo "  $0 patch --edit  # 0.2.2 → 0.2.3 (with manual CHANGELOG review)"
        echo "  $0 minor         # 0.2.2 → 0.3.0 (fully automated)"
        echo "  $0 major         # 0.2.2 → 1.0.0 (fully automated)"
        echo "  $0 0.3.0         # Explicit version (fully automated)"
        echo ""
        echo "Automation features:"
        echo "  • Auto-extracts commit message to CHANGELOG"
        echo "  • Auto-creates GitHub Release with gh CLI"
        echo "  • Use --edit flag to manually review CHANGELOG"
        exit 1
    fi

    local version_input=$1
    local edit_mode=false

    # Check for --edit flag
    if [[ $# -eq 2 ]]; then
        if [[ "$2" == "--edit" ]]; then
            edit_mode=true
            log_info "Edit mode enabled - CHANGELOG will be opened for manual review"
        else
            log_error "Invalid option: $2 (use --edit or omit)"
            exit 1
        fi
    fi

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

    # Edit CHANGELOG (only if --edit flag is set)
    if [[ "$edit_mode" == true ]]; then
        edit_changelog
    else
        log_info "Skipping manual CHANGELOG edit (using auto-extracted content)"
        log_info "Tip: Use --edit flag to manually review CHANGELOG"
    fi

    # Confirm release
    confirm_release "$current_version" "$new_version"

    # Git operations
    perform_git_operations "$new_version"

    # Push changes
    push_changes "$new_version"

    # Create GitHub Release (or open browser if gh is not available)
    create_github_release "$new_version"

    # Success message
    echo ""
    log_success "Release v$new_version completed successfully! 🎉"
    echo ""
    log_info "What happened:"
    echo "  ✅ Version bumped to v$new_version"
    echo "  ✅ CHANGELOG auto-generated from commit message"
    echo "  ✅ Changes committed and pushed to GitHub"
    echo "  ✅ Git tag v$new_version created"
    echo "  ✅ GitHub Release created (or browser opened)"
    echo ""
    log_info "Next steps:"
    echo "  • GitHub Actions will automatically update homebrew-tap"
    echo "  • Monitor: $REPO_URL/actions"
    echo "  • Verify: https://github.com/gwifloria/homebrew-tap/commits/main"
    echo ""
}

# Run main function
main "$@"
