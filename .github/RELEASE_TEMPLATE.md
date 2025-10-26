## 🎉 ClaudeCode Monitor v{VERSION}

Real-time ClaudeCode status in your macOS menu bar.

Stop switching windows to check if Claude finished. Never miss a confirmation prompt again.

---

### ✨ Features

- 🔄 **Real-time Status** - Track multiple ClaudeCode projects simultaneously
- ⚠️ **Smart Alerts** - Confirmation prompts flash in menu bar (impossible to miss)
- ⠋ **Animated Indicator** - Beautiful 6-frame clockwise animation shows Claude working
- 🎯 **Priority Display** - Automatically shows most urgent status across all sessions
- 📊 **Multi-session** - Manage unlimited projects with independent status tracking
- 🚀 **Zero Impact** - Minimal resources (< 5MB RAM), fail-safe design

### 📦 Installation

**Via Homebrew (recommended):**

```bash
brew install gwifloria/tap/claude-monitor
claude-monitor-setup
claude-monitor start
```

**Manual installation:**

```bash
curl -fsSL https://github.com/gwifloria/claude-monitor/archive/refs/tags/v{VERSION}.tar.gz | tar xz
cd claude-monitor-{VERSION}
./install.sh
```

Or clone the repository:

```bash
git clone https://github.com/gwifloria/claude-monitor.git
cd claude-monitor
./install.sh
```

### 🚀 Quick Start

After installation:

```bash
# 1. Run setup (configures hooks and SwiftBar)
claude-monitor-setup

# 2. Start monitoring
claude-monitor start

# 3. Check status
claude-monitor status
```

The monitor icon will appear in your menu bar!

### 📊 Status Types

| Icon   | Status         | Description                                     |
| ------ | -------------- | ----------------------------------------------- |
| ⚠️     | **Attention**  | User confirmation required (highest priority)   |
| ⠇⠦⠴⠸⠙⠋ | **Processing** | Claude is working (6-frame clockwise animation) |
| ✅     | **Completed**  | Task finished, ready for review                 |
| 💤     | **Idle**       | Waiting for your next prompt                    |
| 💤0    | **Inactive**   | No ClaudeCode sessions detected                 |

### 🔧 How It Works

ClaudeCode Monitor integrates seamlessly with ClaudeCode's built-in hooks system to provide real-time status updates in your macOS menu bar via SwiftBar.

**Event Flow:**

1. You submit a prompt to ClaudeCode
2. `UserPromptSubmit` hook fires → Status: **⠋ Processing**
3. SwiftBar reads status every 1s → Displays animated spinner
4. Claude needs confirmation → `Notification` hook → Status: **⚠️ Attention**
5. You respond → Claude continues
6. Claude finishes → `Stop` hook → Status: **✅ Completed**

See [README.md](https://github.com/gwifloria/claude-monitor#how-it-works) for detailed architecture.

### 📚 Documentation

- **English**: [README.md](https://github.com/gwifloria/claude-monitor/blob/main/README.md)
- **简体中文**: [README.zh-CN.md](https://github.com/gwifloria/claude-monitor/blob/main/README.zh-CN.md)
- **Development Guide**: [docs/development-guide.md](https://github.com/gwifloria/claude-monitor/blob/main/docs/development-guide.md)

### 🐛 Troubleshooting

**Menu bar icon not appearing:**

```bash
# Check if SwiftBar is running
pgrep -f SwiftBar

# Restart SwiftBar
claude-monitor restart
```

**Status not updating:**

```bash
# Test hook manually
~/.claude/hooks/update_status.sh processing

# Enable debug mode
export CLAUDE_MONITOR_DEBUG=1
tail -f ~/.claude-monitor/debug.log
```

See [README.md#troubleshooting](https://github.com/gwifloria/claude-monitor#troubleshooting) for more solutions.

### 🗑️ Uninstall

**Via Homebrew:**

```bash
brew uninstall claude-monitor
rm -rf ~/.claude-monitor
```

**Manual installation:**

```bash
./uninstall.sh
```

### 🆕 What's New in v{VERSION}

{CHANGELOG_CONTENT}

---

### 🙏 Acknowledgments

- Built for [ClaudeCode](https://claude.ai/code) by Anthropic
- Uses [SwiftBar](https://github.com/swiftbar/SwiftBar) for menu bar integration
- Inspired by the need for better workflow awareness in AI-assisted development

### 📄 License

MIT License - See [LICENSE](https://github.com/gwifloria/claude-monitor/blob/main/LICENSE) file for details

---

**Full Changelog**: https://github.com/gwifloria/claude-monitor/commits/v{VERSION}
