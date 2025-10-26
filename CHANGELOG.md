# Changelog

All notable changes to ClaudeCode Monitor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Homebrew formula for easy installation
- Automated testing script for formula validation
- Comprehensive release documentation

## [0.1.0] - TBD

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

[Unreleased]: https://github.com/yourname/claude-monitor/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/yourname/claude-monitor/releases/tag/v0.1.0
