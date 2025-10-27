# Release Workflow Guide

Complete guide for releasing new versions of ClaudeCode Monitor using the automated release script.

## 🚀 Quick Start

```bash
# Patch release (bug fixes): 0.2.2 → 0.2.3
./release.sh patch

# Minor release (new features): 0.2.2 → 0.3.0
./release.sh minor

# Major release (breaking changes): 0.2.2 → 1.0.0
./release.sh major

# Explicit version
./release.sh 0.3.0
```

## 📋 Complete Release Process

### Step 1: Prepare for Release

**Before running the release script:**

```bash
# 1. Ensure all changes are committed
git status  # Should be clean

# 2. Ensure you're on main branch
git branch  # Should show * main

# 3. Pull latest changes
git pull origin main

# 4. Run tests (if applicable)
# brew audit --strict Formula/claude-monitor.rb
```

### Step 2: Run Release Script

```bash
./release.sh patch
```

**The script will:**

1. ✅ **Validate environment**
   - Check git repository status
   - Verify you're on main branch
   - Ensure working directory is clean
   - Verify required files exist

2. ✅ **Calculate version**
   - For `patch/minor/major`: Auto-increment from current version
   - For explicit version: Validate format (X.Y.Z)
   - Check version doesn't already exist

3. ✅ **Update files**
   - `VERSION`: New version number
   - `Formula/claude-monitor.rb`: Version + URL (SHA256 left empty for GitHub Actions)
   - `CHANGELOG.md`: Insert template for release notes

4. ✅ **Show preview**
   - Display diff of changed files

5. ✅ **Edit CHANGELOG**
   - Opens your default editor
   - Fill in Added/Changed/Fixed sections
   - Save and close when done

6. ✅ **Confirm release**
   - Shows summary (current → new version)
   - Asks for confirmation (y/N)

7. ✅ **Git operations**
   - Stage changed files
   - Create commit: `Release v0.3.0`
   - Create tag: `v0.3.0`

8. ✅ **Push to remote**
   - Push commits to `origin/main`
   - Push tag `v0.3.0`

9. ✅ **Open GitHub Release page**
   - Automatically opens browser to create release
   - Tag is pre-selected

### Step 3: Create GitHub Release

**In the opened GitHub page:**

1. **Title**: `v0.3.0 - Brief Description`
   - Example: `v0.3.0 - Automated Release System`

2. **Description**: Copy from CHANGELOG.md
   ```markdown
   ## What's Changed

   ### Added
   - Automated release script for version management
   - Comprehensive release workflow documentation

   ### Changed
   - Improved installation process

   ### Fixed
   - Path resolution in generate_settings.sh

   ---

   **Full Changelog**: https://github.com/gwifloria/claude-monitor/compare/v0.2.2...v0.3.0
   ```

3. **Options**:
   - [ ] Set as pre-release (only for beta/test releases)
   - [x] Set as latest release (for production releases)

4. **Click**: `Publish release`

### Step 4: Verify Automation

**Monitor GitHub Actions:**

1. Visit: https://github.com/gwifloria/claude-monitor/actions
2. Look for: `Update Homebrew Formula` workflow
3. Wait for: ✅ Green checkmark (usually < 1 minute)

**Verify homebrew-tap update:**

1. Visit: https://github.com/gwifloria/homebrew-tap/commits/main
2. Look for: Automated commit from GitHub Actions
3. Check: Formula version and SHA256 are correct

**Test installation:**

```bash
# Update local Homebrew cache
brew update

# Check available version
brew info gwifloria/tap/claude-monitor

# Upgrade (if already installed)
brew upgrade claude-monitor

# Or fresh install
brew reinstall gwifloria/tap/claude-monitor

# Verify version
claude-monitor-setup --help
```

## 🎯 Version Numbering Guide

Follow [Semantic Versioning](https://semver.org/):

| Bump Type | When to Use | Example |
|-----------|-------------|---------|
| **Patch** | Bug fixes, docs updates, minor tweaks | 0.2.2 → 0.2.3 |
| **Minor** | New features, non-breaking changes | 0.2.2 → 0.3.0 |
| **Major** | Breaking changes, major rewrites | 0.2.2 → 1.0.0 |

### Examples

**Patch (0.2.2 → 0.2.3)**:
- Fix: Status not updating after ClaudeCode exits
- Docs: Update installation instructions
- Refactor: Clean up status_manager.sh code

**Minor (0.2.2 → 0.3.0)**:
- Feature: Add support for custom notification sounds
- Feature: New CLI command for session management
- Enhancement: Improve SwiftBar plugin performance

**Major (0.2.2 → 1.0.0)**:
- Breaking: Change configuration file format
- Breaking: Remove support for older ClaudeCode versions
- Complete: Rewrite monitoring engine

## 📝 CHANGELOG Template

The release script automatically inserts this template:

```markdown
## [0.3.0] - 2025-10-27

### Added

-

### Changed

-

### Fixed

-
```

**Fill it in before continuing the release:**

```markdown
## [0.3.0] - 2025-10-27

### Added

- Automated release script (`release.sh`) for version management
- Comprehensive release workflow documentation

### Changed

- Simplified release process from 15 minutes to 2 minutes

### Fixed

- Path resolution bug in `generate_settings.sh`
- Hook script not found error during setup
```

## 🐛 Troubleshooting

### Problem: "Not on main branch"

```bash
# Switch to main branch
git checkout main

# Update from remote
git pull origin main
```

### Problem: "Working directory is not clean"

```bash
# Check what's changed
git status

# Option 1: Commit changes
git add .
git commit -m "Prepare for release"

# Option 2: Stash changes
git stash
# Later: git stash pop
```

### Problem: "Version already exists"

```bash
# Check existing tags
git tag -l

# If tag is wrong, delete it
git tag -d v0.3.0
git push origin :refs/tags/v0.3.0  # Delete remote tag

# Then run release script again
```

### Problem: GitHub Actions workflow failed

**Common causes:**

1. **403 Forbidden**: Token expired or insufficient permissions
   - Solution: Regenerate `HOMEBREW_TAP_TOKEN` with `repo` + `workflow` scopes
   - Update secret in https://github.com/gwifloria/claude-monitor/settings/secrets/actions

2. **SHA256 calculation error**: Release tarball not ready
   - Solution: Wait 2-3 minutes, then manually re-trigger workflow

3. **homebrew-tap push failed**: Branch protection or permissions
   - Solution: Check tap repository settings

**Manual fix if automation fails:**

```bash
# 1. Calculate SHA256 manually
curl -sL "https://github.com/gwifloria/claude-monitor/archive/refs/tags/v0.3.0.tar.gz" \
  | shasum -a 256 | awk '{print $1}'

# 2. Clone homebrew-tap
cd /tmp
git clone https://github.com/gwifloria/homebrew-tap.git
cd homebrew-tap

# 3. Update formula
sed -i '' 's/sha256 \".*\"/sha256 "CALCULATED_SHA"/' Formula/claude-monitor.rb

# 4. Commit and push
git commit -am "Update claude-monitor to v0.3.0"
git push origin main
```

### Problem: Editor doesn't open for CHANGELOG

The script tries to detect your editor in this order:

1. `$EDITOR` environment variable
2. VS Code (`code --wait`)
3. nano
4. vi

**Set your preferred editor:**

```bash
# In ~/.zshrc or ~/.bashrc
export EDITOR="code --wait"  # VS Code
export EDITOR="nano"          # Nano
export EDITOR="vi"            # Vim
```

### Problem: Browser doesn't open automatically

**macOS**: Should work automatically with `open` command

**Linux**: Requires `xdg-open` (usually pre-installed)

**Manual**: Copy URL from terminal output:
```
Opening GitHub Release page...
URL: https://github.com/gwifloria/claude-monitor/releases/new?tag=v0.3.0
```

## 📊 Release Checklist

Use this checklist before and after each release:

### Pre-Release

- [ ] All features/fixes are tested and working
- [ ] Documentation is updated (README, CLAUDE.md, etc.)
- [ ] All changes are committed to main branch
- [ ] Working directory is clean (`git status`)
- [ ] On main branch (`git branch`)
- [ ] Pulled latest changes (`git pull`)

### During Release

- [ ] Run `./release.sh [patch|minor|major|VERSION]`
- [ ] Script completes all validation checks
- [ ] Files are updated correctly (preview diff)
- [ ] CHANGELOG is filled with actual release notes
- [ ] Confirm release when prompted
- [ ] Git push succeeds

### Post-Release

- [ ] GitHub Release is created with notes
- [ ] GitHub Actions workflow succeeds
- [ ] homebrew-tap repository is updated
- [ ] Formula version and SHA256 are correct
- [ ] Test installation: `brew reinstall gwifloria/tap/claude-monitor`
- [ ] Verify `claude-monitor-setup` works
- [ ] Monitor for user issues in next 24 hours

## 🔄 Rollback Procedure

If a release has critical issues:

### Option 1: Quick Patch Release

```bash
# Fix the issue
git add .
git commit -m "Fix critical issue"

# Release patch version
./release.sh patch  # e.g., 0.3.0 → 0.3.1
```

### Option 2: Revert Release (Nuclear Option)

**⚠️ Only use if release is severely broken**

```bash
# 1. Revert commit
git revert HEAD
git push origin main

# 2. Delete tag
git tag -d v0.3.0
git push origin :refs/tags/v0.3.0

# 3. Delete GitHub Release
# Visit: https://github.com/gwifloria/claude-monitor/releases
# Delete the release

# 4. Revert homebrew-tap
cd /path/to/homebrew-tap
git revert HEAD
git push origin main
```

## 📈 Release Metrics

Track these metrics for each release:

| Metric | Target | How to Check |
|--------|--------|-------------|
| Time to release | < 5 min | Script start to GitHub Release |
| GitHub Actions duration | < 2 min | Actions page |
| Installation success rate | > 95% | User reports |
| Issues reported | < 2 | GitHub issues |

## 🎓 Advanced Usage

### Pre-release / Beta Versions

For testing before official release:

```bash
# Create pre-release with -test suffix
./release.sh 0.3.0-test

# On GitHub Release page:
# - Check "Set as a pre-release"
# - Add warning in description
```

### Multiple Releases in One Day

If you need to release multiple patches:

```bash
./release.sh 0.3.1  # First patch
./release.sh 0.3.2  # Second patch
./release.sh 0.3.3  # Third patch
```

Each release will have its own CHANGELOG entry.

### Dry-run Mode (Future Enhancement)

Currently not implemented, but planned:

```bash
./release.sh --dry-run patch
# Would show what would happen without actually doing it
```

## 📚 Related Documentation

- [Homebrew Maintenance Guide](homebrew-maintenance.md) - Complete Homebrew workflow
- [GitHub Actions Setup](github-actions-setup.md) - Automation configuration
- [Development Guide](development-guide.md) - Developer setup

## 🤝 Contributing

If you improve the release script or workflow:

1. Test thoroughly with pre-releases
2. Update this documentation
3. Submit PR with clear description
4. Add entry to CHANGELOG under `[Unreleased]`

---

**Last Updated**: 2025-10-27
**Maintained by**: gwifloria
**Questions?**: Open an issue on GitHub
