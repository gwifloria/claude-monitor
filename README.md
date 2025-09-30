# ClaudeCode Monitor

A macOS menu bar application that displays real-time ClaudeCode status across multiple projects, reducing attention fragmentation and improving workflow awareness.

![Menu Bar Preview](https://img.shields.io/badge/macOS-Menu%20Bar-blue?logo=apple)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- 🔄 **Real-time Status Tracking** - Monitor ClaudeCode activity across multiple projects simultaneously
- ⚠️ **Priority-based Alerts** - Attention-required tasks are prominently displayed with visual indicators
- 🎯 **Smart Status Display** - Automatically shows the most important status in your menu bar
- 🔧 **Safe Installation** - Intelligent merging with existing ClaudeCode settings, with automatic backup
- 📊 **Multi-session Support** - Track multiple ClaudeCode sessions independently
- 🚀 **Zero Performance Impact** - Minimal resource usage, non-intrusive operation

## Status Types

| Icon | Status | Description |
|------|--------|-------------|
| ⚠️ | **Attention** | User confirmation required (highest priority) |
| ⠁⠈⠐⠠⠄⠂ | **Processing** | ClaudeCode is actively working on your request |
| ✅ | **Completed** | Task finished, ready for next step |
| 💤 | **Idle** | Waiting for user input |
| 💤0 | **Inactive** | No ClaudeCode sessions detected |

## Prerequisites

- macOS with menu bar access
- [ClaudeCode](https://claude.ai/code) installed and configured
- [Homebrew](https://brew.sh) (recommended for automatic installation)

Dependencies that will be installed automatically:
- [SwiftBar](https://github.com/swiftbar/SwiftBar) - Menu bar plugin system
- `jq` - JSON processor

## Quick Install

```bash
# Clone the repository
git clone <repository-url>
cd claude-monitor

# Run installation script
./install.sh
```

The installer will:
1. Check and install dependencies (SwiftBar, jq)
2. Choose installation scope (global or project-specific)
3. Backup your existing ClaudeCode configuration
4. Configure hooks for status monitoring
5. Install SwiftBar plugin
6. Optionally start the monitor

## Usage

### Starting the Monitor

```bash
~/.claude-monitor/scripts/swiftbar_manager.sh start
```

### Viewing Status

Click the menu bar icon to see:
- Overall status summary with counts
- Individual project statuses
- Quick navigation to project directories
- Cleanup and refresh options

### Managing the Monitor

```bash
# Stop monitoring
~/.claude-monitor/scripts/swiftbar_manager.sh stop

# Restart
~/.claude-monitor/scripts/swiftbar_manager.sh restart

# Check status
~/.claude-monitor/scripts/swiftbar_manager.sh status
```

## How It Works

ClaudeCode Monitor integrates with ClaudeCode's built-in hooks system to capture lifecycle events:

```
User submits prompt → ClaudeCode Hook → Status Update → Menu Bar Display
```

**Configured Hooks:**
- `UserPromptSubmit` → Processing status
- `Notification` → Attention status (user action needed)
- `SubagentStop` → Completed status
- `Stop` → Idle status
- `SessionStart` → Connected status
- `SessionEnd` → Remove session

Status is stored in JSON format at `~/.claude-monitor/sessions.json` and displayed in your menu bar via SwiftBar.

## Menu Bar Display Logic

The menu bar shows the **highest priority** status across all active sessions:

1. **⚠️ 2** - 2 projects need attention (highest priority)
2. **⠁ 1** - 1 project processing
3. **✅ 3** - 3 projects completed
4. **💤** - All projects idle
5. **💤0** - No active sessions

Click the icon to see detailed status for each project.

## Troubleshooting

### Enable Debug Mode

```bash
export CLAUDE_MONITOR_DEBUG=1
tail -f ~/.claude-monitor/debug.log
```

### Common Issues

**Menu bar icon not appearing:**
```bash
# Check if SwiftBar is running
pgrep -f SwiftBar

# Restart SwiftBar
~/.claude-monitor/scripts/swiftbar_manager.sh restart
```

**Status not updating:**
```bash
# Test hook manually
~/.claude/hooks/update_status.sh processing

# Check hook configuration
cat ~/.claude/settings.json | jq .hooks

# Verify sessions are tracked
cat ~/.claude-monitor/sessions.json | jq .
```

**Multiple duplicate sessions:**
```bash
# Clean stale sessions
~/.claude-monitor/lib/status_manager.sh clean

# Or reset completely
rm ~/.claude-monitor/sessions.json
```

### Getting Help

1. Check [docs/README.md](docs/README.md) for detailed documentation
2. Review [docs/development-guide.md](docs/development-guide.md) for technical details
3. See [docs/bug-analysis.md](docs/bug-analysis.md) for known issues and solutions

## Uninstall

To completely remove ClaudeCode Monitor:

```bash
./uninstall.sh
```

This will:
- Remove all installed files
- Restore original ClaudeCode configuration from backup
- Clean up SwiftBar plugin
- Remove runtime data

## Configuration

### Installation Scopes

**Global Installation (Recommended)**
- Monitors all ClaudeCode sessions system-wide
- Uses `~/.claude/settings.json`
- Works across all projects

**Project-Specific Installation**
- Only monitors ClaudeCode in specific project
- Uses `./.claude/settings.json` in project directory
- Requires setup per project

### Customization

Edit configuration files to customize behavior:

```bash
# Status manager settings
~/.claude-monitor/lib/status_manager.sh

# Hook behavior
~/.claude/hooks/update_status.sh

# Menu bar display
~/Library/Application Support/SwiftBar/claude_monitor.3s.sh
```

## Architecture

```
┌─────────────────────┐
│  SwiftBar Menu Bar  │  (Display Layer)
└──────────┬──────────┘
           │ reads
           ▼
┌─────────────────────┐
│  Status Manager     │  (Data Layer - JSON storage)
└──────────┬──────────┘
           ▲ updates
           │
┌─────────────────────┐
│  Hook Bridge        │  (Event Layer)
└──────────┬──────────┘
           ▲ triggers
           │
┌─────────────────────┐
│  ClaudeCode Hooks   │  (Event Source)
└─────────────────────┘
```

## Contributing

Contributions are welcome! Please read [docs/development-guide.md](docs/development-guide.md) for development setup and coding guidelines.

## License

[Add your license here]

## Acknowledgments

- Built for [ClaudeCode](https://claude.ai/code) by Anthropic
- Uses [SwiftBar](https://github.com/swiftbar/SwiftBar) for menu bar integration
- Inspired by the need for better workflow awareness in AI-assisted development

---

**Note**: This tool is designed to be completely non-intrusive. If any errors occur in the monitoring system, they will never affect ClaudeCode's operation. The monitor fails gracefully and silently.