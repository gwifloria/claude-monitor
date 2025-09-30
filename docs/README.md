# ClaudeCode Monitor

A macOS menu bar application that displays real-time ClaudeCode status across multiple projects, reducing attention fragmentation and improving workflow awareness.

## Features

- 🔄 **Real-time Status Monitoring** - Track ClaudeCode activity across multiple projects
- ⚠️ **Priority-based Display** - Attention-required tasks flash and take precedence
- 🎯 **Smart Refresh Rates** - Adaptive refresh based on current activity
- 🔧 **Safe Configuration** - Intelligent merging with existing ClaudeCode settings
- 📊 **Multi-project Support** - Monitor multiple ClaudeCode sessions simultaneously

## Status Types

| Status | Icon | Description |
|--------|------|-------------|
| **Attention** | ⚠️ (flashing) | User confirmation required (highest priority) |
| **Processing** | 🔄 | ClaudeCode is actively working |
| **Completed** | ✅ | Task finished, ready for next step |
| **Idle** | 💤 | Waiting for user input |
| **Connected** | 🤖 | Session just started |

## Installation

### Prerequisites

- macOS with menu bar access
- [SwiftBar](https://github.com/swiftbar/SwiftBar) installed
- [ClaudeCode](https://claude.ai/code) installed and configured
- `jq` command-line JSON processor

### Quick Install

1. **Install dependencies:**
   ```bash
   # Install SwiftBar
   brew install --cask swiftbar

   # Install jq
   brew install jq
   ```

2. **Install ClaudeCode Monitor:**
   ```bash
   git clone <repository-url>
   cd claude-monitor
   ./install.sh
   ```

3. **Restart SwiftBar** to load the plugin

## Usage

### Menu Bar Display

The menu bar icon shows the highest priority status with count:
- `⚠️ 2` - 2 projects need attention
- `🔄 1` - 1 project processing
- `✅ 3` - 3 projects completed
- `💤` - All projects idle

### Dropdown Menu

Click the menu bar icon to see:
- Status summary with counts
- Individual project statuses
- Quick navigation to project directories
- Cleanup and refresh options

### Refresh Rates

The plugin automatically adjusts refresh rates:
- **Attention state**: 10 seconds
- **Processing state**: 15 seconds
- **Idle state**: 30 seconds

## Configuration

### ClaudeCode Hooks

The installation automatically configures these hooks in `~/.claude/settings.json`:

- `UserPromptSubmit` → Processing status
- `Notification` → Attention status
- `SubagentStop` → Completed status
- `Stop` → Idle status
- `SessionStart` → Connected status
- `SessionEnd` → Remove session

### Manual Configuration

If you need to manually configure hooks:

```bash
# Generate new configuration
./scripts/generate_settings.sh generate > new_settings.json

# Merge with existing configuration
./scripts/generate_settings.sh merge ~/.claude/settings.json > merged_settings.json
```

## Troubleshooting

### Enable Debug Mode

```bash
export CLAUDE_MONITOR_DEBUG=1
```

Debug information is logged to `~/.claude-monitor/debug.log`

### Test Status Manager

```bash
# Check current status
~/.claude-monitor/lib/status_manager.sh summary

# List all sessions
~/.claude-monitor/lib/status_manager.sh list

# Clean expired statuses
~/.claude-monitor/lib/status_manager.sh clean
```

### Common Issues

**Menu bar icon not appearing:**
- Verify SwiftBar is running
- Check plugin is executable: `ls -la ~/Library/Application\ Support/SwiftBar/claude_monitor.5s.sh`
- Restart SwiftBar

**Status not updating:**
- Verify ClaudeCode configuration: `cat ~/.claude/settings.json`
- Check hook script is executable: `ls -la ~/.claude/hooks/update_status.sh`
- Enable debug mode and check logs

**Multiple ClaudeCode sessions not tracked:**
- Each session is identified by project path + process ID
- Status is automatically cleaned when sessions end

## File Structure

```
claude-monitor/
├── install.sh              # Main installation script
├── uninstall.sh            # Complete removal script
├── lib/
│   └── status_manager.sh    # Core status management
├── hooks/
│   └── update_status.sh     # ClaudeCode hook handler
├── plugins/
│   └── claude_monitor.5s.sh # SwiftBar menu plugin
├── scripts/
│   └── generate_settings.sh # Configuration generator
└── docs/
    └── README.md           # This file
```

## Uninstall

To completely remove ClaudeCode Monitor:

```bash
./uninstall.sh
```

This will:
- Remove all installed files
- Restore original ClaudeCode configuration from backup
- Clean up any running processes
- Remove SwiftBar plugin

## Development

### Status Manager API

```bash
# Update project status
./lib/status_manager.sh update <status>

# Remove current project session
./lib/status_manager.sh remove

# List all active sessions
./lib/status_manager.sh list

# Get menu bar summary
./lib/status_manager.sh summary

# Clean expired completed statuses
./lib/status_manager.sh clean
```

### Adding Custom Hooks

To add additional hooks or modify behavior:

1. Edit `scripts/generate_settings.sh`
2. Update hook types in `hooks/update_status.sh`
3. Modify display logic in `plugins/claude_monitor.5s.sh`
4. Run `./install.sh` to apply changes

## License

[Add your license information here]

## Contributing

[Add contribution guidelines here]