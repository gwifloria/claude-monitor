# ClaudeCode Monitor

[English](README.md) | [简体中文](README.zh-CN.md)

**Real-time ClaudeCode status in your macOS menu bar.**

Stop switching windows to check if Claude finished. Never miss a confirmation prompt again.

![Menu Bar Preview](https://img.shields.io/badge/macOS-Menu%20Bar-blue?logo=apple)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Features

- 🔄 **Real-time Status** - Track multiple ClaudeCode projects simultaneously
- ⚠️ **Smart Alerts** - Confirmation prompts flash in menu bar (impossible to miss)
- ⠋ **Animated Indicator** - Beautiful 6-frame clockwise animation shows Claude working
- 🎯 **Priority Display** - Automatically shows most urgent status across all sessions
- 📊 **Multi-session** - Manage unlimited projects with independent status tracking
- 🚀 **Zero Impact** - Minimal resources (< 5MB RAM), fail-safe design
- 🔧 **Safe Setup** - Intelligent config merging with automatic backup

## Status Types

| Icon | Status | Description |
|------|--------|-------------|
| ⚠️ | **Attention** | User confirmation required (highest priority) |
| ⠇⠦⠴⠸⠙⠋ | **Processing** | Claude is working (6-frame clockwise animation) |
| ✅ | **Completed** | Task finished, ready for review |
| 💤 | **Idle** | Waiting for your next prompt |
| 💤0 | **Inactive** | No ClaudeCode sessions detected |

## Installation

**Prerequisites:** macOS, [ClaudeCode](https://claude.ai/code), [Homebrew](https://brew.sh)

### Option 1: Homebrew (Recommended)

```bash
# Add tap and install
brew install yourname/tap/claude-monitor

# Run setup (configures hooks and SwiftBar)
claude-monitor-setup

# Start monitoring
claude-monitor start
```

### Option 2: Manual Installation

```bash
git clone https://github.com/yourname/claude-monitor.git
cd claude-monitor
./install.sh
```

Both methods auto-configure dependencies (SwiftBar, jq) and ClaudeCode hooks.

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

ClaudeCode Monitor integrates seamlessly with ClaudeCode's built-in hooks system:

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│ ClaudeCode  │ event   │ Hook Bridge  │ update  │   Status    │
│   (CLI)     │────────>│ (Translator) │────────>│  Manager    │
│             │         │              │         │   (JSON)    │
└─────────────┘         └──────────────┘         └──────┬──────┘
                                                         │ read
                                                         ▼
                                                  ┌─────────────┐
                                                  │  SwiftBar   │
                                                  │ Menu Bar UI │
                                                  └─────────────┘
```

### Event Flow

**When you submit a prompt:**
1. `UserPromptSubmit` hook fires → Updates status to **⠇ Processing**
2. SwiftBar reads status every 1 second → Shows animated spinner
3. Claude finishes → `Stop` hook fires → Status becomes **✅ Completed**
4. You start new task → Status returns to **💤 Idle**

**When Claude needs confirmation:**
1. `Notification` hook fires → Status jumps to **⚠️ Attention** (highest priority)
2. Menu bar shows warning icon → Impossible to miss
3. You respond → Hook updates status → Animation continues

### Configured Hooks

| Hook Event | Trigger | Status Update | Priority |
|------------|---------|---------------|----------|
| `UserPromptSubmit` | You send a prompt | ⠋ **Processing** | P2 |
| `Notification` | Claude needs confirmation | ⚠️ **Attention** | P1 (highest) |
| `Stop` | Claude finishes entire response | ✅ **Completed** | P3 |
| `SessionStart` | New ClaudeCode session | 💤 **Idle** | P4 |
| `SessionEnd` | ClaudeCode exits | *(Remove session)* | — |

> **Note**: `SubagentStop` is intentionally **not** configured. Sub-agent completion doesn't mean the main task is done—Claude may launch multiple sub-agents or continue processing afterward.

### Data Storage

Status is stored in JSON at `~/.claude-monitor/sessions.json`:
```json
{
  "a3a5596b": {
    "project_name": "my-web-app",
    "project_path": "/Users/you/projects/my-web-app",
    "status": "processing",
    "priority": 3,
    "timestamp": 1706345678
  }
}
```

Each session is identified by MD5 hash of the project path, ensuring consistent tracking across hook invocations.

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
# Auto-cleanup runs every second (dead sessions removed within 5 min)
# Manual cleanup if needed:
~/.claude-monitor/lib/status_manager.sh clean-dead

# Or reset completely
rm ~/.claude-monitor/sessions.json && echo '{}' > ~/.claude-monitor/sessions.json
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

## Contributing

Contributions are welcome! Please read [docs/development-guide.md](docs/development-guide.md) for development setup and coding guidelines.

## License

MIT License - See LICENSE file for details

## Acknowledgments

- Built for [ClaudeCode](https://claude.ai/code) by Anthropic
- Uses [SwiftBar](https://github.com/swiftbar/SwiftBar) for menu bar integration
- Inspired by the need for better workflow awareness in AI-assisted development

---

**Note**: This tool is designed to be completely non-intrusive. If any errors occur in the monitoring system, they will never affect ClaudeCode's operation. The monitor fails gracefully and silently.