# ClaudeCode Monitor

[English](README.md) | [简体中文](README.zh-CN.md)

**Stop context-switching. Start flowing.**

Ever find yourself constantly switching between terminal windows to check if ClaudeCode finished? Missing critical "user confirmation needed" prompts because they're buried in another workspace? Working on multiple projects and losing track of which Claude is waiting for you?

**ClaudeCode Monitor solves this** by bringing real-time status directly to your macOS menu bar with a beautiful animated indicator.

![Menu Bar Preview](https://img.shields.io/badge/macOS-Menu%20Bar-blue?logo=apple)
![License](https://img.shields.io/badge/license-MIT-green)

---

## The Problem

When working with ClaudeCode, you face constant attention fragmentation:

### 🔄 Context Switching Tax
Every status check requires switching windows or workspaces, breaking your flow. You're writing code in your editor, but need to jump to the terminal every few minutes to see if Claude finished.

### ⚠️ Missed Notifications
ClaudeCode prompts for user confirmation, but you're in Slack, your browser, or another terminal tab. By the time you notice, you've already lost precious minutes—or forgot what you were doing.

### 🎯 Multi-Project Chaos
Running Claude in 3 different projects? Good luck remembering which one is processing, which needs your input, and which finished 10 minutes ago.

### ⏳ Uncertain Waiting
Is Claude still thinking? Did it crash? Should I check now or wait another minute? This uncertainty wastes time and mental energy.

### 📊 Status Blindness
When working in other applications, you're completely blind to ClaudeCode's state. You either check too often (wasting time) or too rarely (missing prompts).

---

## The Solution

ClaudeCode Monitor gives you **glanceable awareness** without ever leaving your current task:

**Before:** 🖥️→🔍→⌨️→🖥️→🔍 (constant switching)
**After:** 👀 (glance at menu bar) → ✅ (back to work)

### Visual Status Indicators

Watch Claude work in real-time with a smooth **6-frame clockwise animation**:

```
⠇ → ⠦ → ⠴ → ⠸ → ⠙ → ⠋  (processing)
⚠️  (needs your attention!)
✅  (completed, ready for review)
💤  (waiting for your next task)
```

### Priority-Based Display

The menu bar automatically shows the **most urgent** status across all projects:
1. **⚠️ Attention** (highest priority) - Drop everything, Claude needs you
2. **⠋ Processing** - Claude is working, you can focus elsewhere
3. **✅ Completed** - Ready for your review
4. **💤 Idle** - Waiting for your next prompt

### Multi-Project Awareness

Click the menu bar icon to see detailed status for every project:
```
Projects:
  ⚠️ my-web-app      (needs confirmation)
  ⠴ backend-api      (processing)
  ✅ docs-site       (completed)
  💤 mobile-app      (idle)
```

---

## Use Cases

### Scenario 1: Parallel Development
You're refactoring `project-a` while Claude reviews `project-b` and generates tests for `project-c`. One glance at your menu bar tells you:
- `project-b` review is done ✅
- `project-c` is still working ⠦
- `project-a` doesn't need attention yet 💤

**Result:** Zero context switches. You finish your current thought before checking completed work.

### Scenario 2: Long-Running Tasks
You ask Claude to analyze a large codebase (5-10 minutes). Instead of anxiously checking every 30 seconds, you:
1. See the processing animation ⠴
2. Switch to email/Slack
3. Get pulled back when menu bar shows ⚠️ (Claude has questions)

**Result:** Reclaim 5-10 minutes of productive work time per long task.

### Scenario 3: High-Frequency Interactions
Building a feature with Claude through multiple iterations. Each confirmation prompt could cost you 30-60 seconds of attention lag:
- Without monitor: 10 prompts × 45s = 7.5 minutes lost
- With monitor: ⚠️ appears → respond immediately → 0 lag

**Result:** 50-80% reduction in interaction latency.

---

## Features

- 🔄 **Real-time Status Tracking** - Monitor ClaudeCode activity across multiple projects simultaneously
  → *Solves: Context switching tax, status blindness*

- ⚠️ **Priority-based Alerts** - Attention-required tasks flash in your menu bar (impossible to miss)
  → *Solves: Missed notifications*

- 🎯 **Smart Status Display** - Automatically shows the most urgent status across all sessions
  → *Solves: Multi-project chaos*

- ⠋ **Animated Processing Indicator** - Beautiful 6-frame clockwise animation shows Claude is working
  → *Solves: Uncertain waiting*

- 📊 **Multi-session Support** - Track unlimited ClaudeCode sessions independently with project names
  → *Solves: Multi-project chaos*

- 🚀 **Zero Performance Impact** - Minimal resource usage (< 5MB RAM), non-intrusive operation
  → *Fail-safe design: Monitoring errors never affect ClaudeCode*

- 🔧 **Safe Installation** - Intelligent merging with existing ClaudeCode settings, automatic backup
  → *Never breaks your existing setup*

## Status Types

| Priority | Icon | Status | Description | When You See This |
|----------|------|--------|-------------|-------------------|
| 🔴 **P1** | ⚠️ | **Attention** | User confirmation required | Drop what you're doing—Claude needs you! |
| 🟡 **P2** | ⠇⠦⠴⠸⠙⠋ | **Processing** | Claude is actively working | Relax, grab coffee, Claude's got this |
| 🟢 **P3** | ✅ | **Completed** | Task finished, ready for review | Check results when you're ready |
| ⚪ **P4** | 💤 | **Idle** | Waiting for your next prompt | Claude is ready for your next task |
| ⚫ **—** | 💤0 | **Inactive** | No sessions detected | Start ClaudeCode in any project |

### Processing Animation

The processing indicator uses a smooth **clockwise rotation** that updates every second:

```
Frame 1: ⠇  (left column)      ●●○
Frame 2: ⠦  (bottom-left)      ○●●
Frame 3: ⠴  (bottom-right)     ○○●
Frame 4: ⠸  (right column)     ○●●
Frame 5: ⠙  (top-right)        ●○○
Frame 6: ⠋  (top-left)         ●●○
(repeat)
```

Each frame keeps one "anchor" dot fixed while moving two dots, creating a fluid circular motion that's easy on the eyes.

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
~/Library/Application Support/SwiftBar/claude_monitor.1s.sh
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

## Why This Matters

### The Cost of Context Switching

Research shows that context switching costs **23 minutes** of focus time per interruption ([UC Irvine study](https://www.ics.uci.edu/~gmark/chi08-mark.pdf)). When working with AI assistants:

- **10 status checks/day** × 2 minutes = **20 minutes lost**
- **3 missed prompts/day** × 10 minutes = **30 minutes lost**
- **Total: 50 minutes/day** = **4+ hours per week**

ClaudeCode Monitor eliminates this by moving status to your **peripheral vision**—always visible, never demanding attention unless absolutely necessary.

### Design Philosophy

1. **Glanceable** - Status visible without context switch
2. **Prioritized** - Show only what matters most
3. **Non-intrusive** - Peripheral awareness, not interruption
4. **Fail-safe** - Monitoring never breaks ClaudeCode
5. **Beautiful** - Smooth animations that don't distract

---

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