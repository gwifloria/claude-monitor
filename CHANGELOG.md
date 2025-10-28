# Changelog

All notable changes to ClaudeCode Monitor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.5] - 2025-10-28

### Changed

- feat: Add append mode to claude-monitor-setup

Added third option to setup script for users with existing hooks.

Changes:

- Add "Append" mode to merge strategy selection
- Set Append as default (recommended) instead of Replace
- Update option numbering: 1=Replace, 2=Append (default), 3=Skip

Before:

1. Replace - Override existing hooks (recommended)
2. Skip - Keep existing hooks (monitor won't work)

After:

1. Replace - Override existing hooks
2. Append - Chain with existing hooks (recommended)
3. Skip - Keep existing hooks only

Why:

- Users with existing hooks (e.g., claude_code_logger.sh) can now keep them
- Append mode chains monitor hooks with existing hooks
- More flexible for multi-hook configurations
- Fixes issue where Replace would delete other useful hooks

Technical:

- generate_settings.sh already supported append mode
- Only setup script UI needed updating
- Default changed from 1 (replace) to 2 (append)

Usage example:
When user has existing hooks and chooses Append (option 2):
UserPromptSubmit: [existing_hook, monitor_hook]
Stop: [existing_hook, monitor_hook]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>

## [0.2.3] - 2025-10-27

### Added

- Add release.sh: One-command version bumping and release automation

### Changed

- optimize readme.md

### Fixed

- none

## [0.2.1] - 2024-10-26

### Fixed

- **Homebrew installation failure** - Removed `swiftbar` from formula dependencies
  - SwiftBar is a Cask (GUI app) and cannot be a dependency of a Formula (CLI tool)
  - Users now install SwiftBar separately: `brew install --cask swiftbar`
  - Added clear installation instructions in formula `caveats`

### Changed

- Updated installation steps in README to be a 4-step process
- Clarified that SwiftBar must be installed separately
- Improved setup documentation

## [0.2.0] - 2024-10-26

### ⚠️ Breaking Changes

- **Removed manual installation support** - Now exclusively uses Homebrew for installation
  - Removed `install.sh` and `uninstall.sh` scripts
  - Simplified installation to single Homebrew command

### Added

- Homebrew formula for easy installation
- Comprehensive Homebrew maintenance documentation (`docs/homebrew-maintenance.md`)
- Version update workflow demonstration

### Changed

- Simplified README installation instructions (Homebrew only)
- Reorganized repository structure for better clarity

### Removed

- Manual installation scripts (`install.sh`, `uninstall.sh`)
- Formula testing script (`test-formula.sh`)
- Temporary development files (`todos.md`)
- Redundant Homebrew setup documentation

### Documentation

- Consolidated Homebrew release guides into single maintenance document
- Updated both English and Chinese README files

## [0.1.0] - 2024-10-26

### Added

- 🎉 Initial release of ClaudeCode Monitor
- 🔄 Real-time status tracking for multiple ClaudeCode projects
- ⚠️ Smart alerts for confirmation prompts with flashing menu bar icon
- ⠋ Beautiful 6-frame clockwise spinner animation
- 🎯 Priority-based status display across all sessions
- 📊 Multi-session management with auto-cleanup
- 🚀 Minimal resource usage (< 5MB RAM)
- 🔧 Safe configuration management with automatic backup
- 🔄 SwiftBar integration for menu bar display
- 📝 Comprehensive documentation in English and Simplified Chinese

### Features

- **Hook Integration**: Seamlessly integrates with ClaudeCode's built-in hooks system

  - `UserPromptSubmit` → Processing status
  - `Notification` → Attention status (highest priority)
  - `Stop` → Completed status
  - `SessionStart` → Idle status with auto-cleanup
  - `SessionEnd` → Session removal

- **Status Management**:

  - JSON-based multi-session state store
  - File locking for concurrent safety
  - Auto-expiration of completed statuses (60s)
  - Auto-cleanup of dead sessions (5 min threshold)
  - Processing timeout handling (30 min auto-expire)

- **User Experience**:

  - One-line installation via shell script
  - Interactive setup wizard
  - Conflict detection with merge strategies
  - Automatic dependency installation (SwiftBar, jq)
  - Clean uninstallation with config restoration

- **Developer Experience**:
  - Debug mode with detailed logging
  - Manual testing commands
  - Session management CLI
  - SwiftBar process management script

### Installation Methods

- Manual installation via `install.sh`
- Homebrew formula (coming soon)

### Documentation

- English README with comprehensive guide
- Simplified Chinese README (README.zh-CN.md)
- Development guide for contributors
- Bug analysis and troubleshooting documentation
- CLAUDE.md with detailed architecture and design decisions

### Known Limitations

- macOS only (requires SwiftBar)
- Requires ClaudeCode CLI to be installed
- Requires Homebrew for dependency management

---

## Version History

- **0.1.0** - Initial public release
  - Core monitoring functionality
  - Multi-session support
  - SwiftBar menu bar integration
  - Comprehensive documentation

[Unreleased]: https://github.com/gwifloria/claude-monitor/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/gwifloria/claude-monitor/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/gwifloria/claude-monitor/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/gwifloria/claude-monitor/releases/tag/v0.1.0
