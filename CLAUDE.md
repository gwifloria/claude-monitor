# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Important: Code Hygiene Rules

**CRITICAL**: When modifying or refactoring code in this repository, you MUST:

1. **Delete obsolete files** - Never leave renamed/replaced files behind
2. **Update all references** - Search and replace ALL occurrences (use `grep -rn "old_name"`)
3. **Verify installation** - Test `./install.sh` after changes to ensure no broken paths
4. **Clean residual code** - Remove unused functions, variables, and comments
5. **Clean up before finishing** - ALWAYS run cleanup commands at the end of your session

**Example**: If renaming `file.3s.sh` → `file.1s.sh`, you must:
- Delete `file.3s.sh` immediately after creating `file.1s.sh`
- Update ALL scripts that reference it (install.sh, uninstall.sh, docs, etc.)
- Test installation to catch any missed references

### Session Cleanup Protocol

**MANDATORY**: At the end of EVERY work session, run these cleanup commands:

```bash
# 1. Clean expired sessions
~/.claude-monitor/lib/status_manager.sh clean

# 2. Reset session state (removes all monitoring data)
rm ~/.claude-monitor/sessions.json && echo '{}' > ~/.claude-monitor/sessions.json

# 3. Remove duplicate/test plugins from SwiftBar Plugins directory
rm -rf ~/Library/Application\ Support/SwiftBar/Plugins/claude*
rm -rf ~/Library/Application\ Support/SwiftBar/Plugins/cc_*

# 4. Verify clean state
~/.claude-monitor/lib/status_manager.sh summary
# Expected output: "idle|0|0|0|0"

# 5. Restart SwiftBar to apply cleanup
~/.claude-monitor/scripts/swiftbar_manager.sh restart
```

**Why this matters**:
- **Session state**: Each ClaudeCode session creates monitoring state that persists
- **Plugin duplication**: SwiftBar loads plugins from both root AND `Plugins/` subdirectory
- **Test artifacts**: Development creates multiple plugin versions (1s, 3s, 30s, etc.)

Without cleanup you'll see:
- Multiple duplicate monitors in menu bar (one per plugin file)
- Conflicting animations (some clockwise, some counter-clockwise from old code)
- Stale session data causing incorrect status display

**When to clean**:
- ✅ After completing development tasks
- ✅ Before testing installation/features
- ✅ When user reports duplicate monitors
- ✅ At the end of EVERY conversation with the user

---

## Documentation Maintenance

**Bilingual README Management**

This project maintains README in both English and Simplified Chinese:
- `README.md` - English (primary, displayed by GitHub)
- `README.zh-CN.md` - Simplified Chinese

### Update Protocol

When modifying README content, you MUST update BOTH versions:

1. **Update English first** (`README.md`)
   - Make all content changes
   - Ensure structure is clear and well-organized

2. **Sync to Chinese** (`README.zh-CN.md`)
   - Translate all changed content
   - Keep structure **identical** to English version
   - Maintain same heading levels, sections, and ordering

3. **Translation Guidelines**
   - ✅ **Translate**: All descriptive text, explanations, use cases
   - ❌ **Do NOT translate**:
     - Code blocks and commands
     - File paths
     - JSON examples
     - Technical terms (Hook, SwiftBar, Status Manager, JSON)
     - Function/variable names
     - URLs

4. **Verification Checklist**
   - [ ] Both files have language switcher at top
   - [ ] Section structure matches exactly
   - [ ] Code blocks are identical
   - [ ] All links work in both versions
   - [ ] Technical terms consistent

### Example Translation

**English:**
```markdown
### 🔄 Context Switching Tax
Every status check requires switching windows or workspaces, breaking your flow.
```

**Chinese:**
```markdown
### 🔄 窗口切换成本
每次查看状态都需要切换窗口或工作区，打断心流。
```

**Why this matters**: Bilingual documentation makes the project accessible to Chinese developers while maintaining international visibility. Out-of-sync documentation creates confusion and poor user experience.

---

## Project Overview

**claude-monitor** is a macOS menu bar monitoring tool that integrates with ClaudeCode through its hooks system to display real-time status updates via SwiftBar.

### Core Value Proposition

Reduces attention fragmentation when working with ClaudeCode by providing at-a-glance status visibility in the macOS menu bar, eliminating the need to constantly switch windows to check progress or catch notification prompts.

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────┐
│                    SwiftBar Menu Bar                     │
│         (claude_monitor.1s.sh - UI Display)              │
└────────────────────┬────────────────────────────────────┘
                     │ reads status
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Status Manager (status_manager.sh)          │
│          JSON-based multi-session state store            │
└────────────────────┬────────────────────────────────────┘
                     ▲ updates
                     │
┌─────────────────────────────────────────────────────────┐
│          Hook Bridge (update_status.sh)                  │
│     Translates ClaudeCode events to status updates      │
└────────────────────┬────────────────────────────────────┘
                     ▲ triggered by
                     │
┌─────────────────────────────────────────────────────────┐
│              ClaudeCode Hooks System                     │
│   (UserPromptSubmit, Notification, Stop, etc.)          │
└─────────────────────────────────────────────────────────┘
```

### Hook Configuration

The project configures these ClaudeCode lifecycle hooks:

| Hook | Status | Priority | Description |
|------|--------|----------|-------------|
| `UserPromptSubmit` | `processing` | 3 | User submitted a prompt, Claude is working |
| `Notification` | `attention` | 4 | User action required (highest priority) |
| `Stop` | `completed` | 2 | Claude finished the entire response |
| `SessionStart` | `connected` | 1 | New session established, cleans dead sessions first |
| `SessionEnd` | (remove) | - | Clean up session data |

**Note**: `SubagentStop` hook is intentionally not configured. Sub-agent completion doesn't indicate the main task is done, as Claude may launch multiple sub-agents or continue processing after a sub-agent finishes.

### Status Priority System

Higher priority statuses take precedence in menu bar display:
- **Attention (4)**: Flashing warning icon - immediate user action needed
- **Processing (3)**: Animated spinner - Claude is working
- **Completed (2)**: Green checkmark - task done, ready for review
- **Idle/Connected (1)**: Gray sleep icon - waiting for input

## File Structure

```
claude-monitor/
├── install.sh                      # Main installation script
├── uninstall.sh                    # Complete removal script
├── CLAUDE.md                       # This file
├── lib/
│   └── status_manager.sh           # Core status management (CRUD + locking)
├── hooks/
│   └── update_status.sh            # ClaudeCode hook handler
├── plugins/
│   └── claude_monitor.1s.sh        # SwiftBar menu bar plugin (1s refresh)
├── scripts/
│   ├── swiftbar_manager.sh         # SwiftBar process management
│   └── generate_settings.sh        # Configuration generator
└── docs/
    ├── release-workflow.md         # Release automation guide
    ├── homebrew-maintenance.md     # Homebrew publishing
    ├── github-actions-setup.md     # CI/CD configuration
    └── development-guide.md        # Developer reference

Installed Locations:
~/.claude-monitor/                  # Runtime data and scripts
  ├── lib/status_manager.sh         # Copied from project
  ├── scripts/swiftbar_manager.sh   # Copied from project
  ├── sessions.json                 # Multi-session state (auto-created)
  ├── refresh_rate.txt              # Dynamic refresh config
  └── debug.log                     # Debug output (if enabled)

~/.claude/                          # ClaudeCode config
  ├── settings.json                 # hooks configuration
  └── hooks/update_status.sh        # Copied from project

~/Library/Application Support/SwiftBar/
  └── claude_monitor.1s.sh          # SwiftBar plugin
```

## Development Commands

### Installation & Setup
```bash
# Install ClaudeCode Monitor
./install.sh

# Uninstall completely
./uninstall.sh

# Start/stop monitoring
~/.claude-monitor/scripts/swiftbar_manager.sh start
~/.claude-monitor/scripts/swiftbar_manager.sh stop
~/.claude-monitor/scripts/swiftbar_manager.sh restart
~/.claude-monitor/scripts/swiftbar_manager.sh status
```

### Testing & Debugging
```bash
# Enable debug logging
export CLAUDE_MONITOR_DEBUG=1

# Test hook triggers manually
~/.claude/hooks/update_status.sh processing
~/.claude/hooks/update_status.sh attention
~/.claude/hooks/update_status.sh completed

# Check status manager operations
~/.claude-monitor/lib/status_manager.sh summary
~/.claude-monitor/lib/status_manager.sh list
~/.claude-monitor/lib/status_manager.sh clean
~/.claude-monitor/lib/status_manager.sh clean-dead

# View debug logs
tail -f ~/.claude-monitor/debug.log

# Test SwiftBar plugin directly
~/Library/Application\ Support/SwiftBar/claude_monitor.1s.sh
```

### Development Workflow

When modifying code during development:

```bash
# After editing source files, sync to installed location
cp hooks/update_status.sh ~/.claude/hooks/
cp lib/status_manager.sh ~/.claude-monitor/lib/
cp plugins/claude_monitor.1s.sh ~/Library/Application\ Support/SwiftBar/

# Restart SwiftBar to see changes
~/.claude-monitor/scripts/swiftbar_manager.sh restart
```

## Key Design Decisions

### Session Identification Strategy

Sessions are identified by MD5 hash of project absolute path:
```bash
session_id=$(echo -n "$project_path" | md5 | cut -c1-8)
```

**Why**: Ensures same project always has same session ID across hook invocations, preventing duplicate sessions.

### Auto-Cleanup of Dead Sessions

The monitor automatically detects and removes sessions for terminated ClaudeCode processes through multiple mechanisms:

1. **SessionStart Hook Cleanup** (immediate)
   - Runs when a new ClaudeCode session starts
   - Cleans dead sessions before registering the new session
   - Ensures fresh state at session initialization

2. **SwiftBar Auto-Cleanup** (periodic)
   - Runs on every SwiftBar refresh (1s interval)
   - Uses `ps` + `lsof` to verify active claude CLI processes
   - Removes sessions without corresponding processes after 5min threshold
   - Handles cases where `SessionEnd` hook didn't fire (crashes, force-quit, etc.)

3. **Status Expiration** (time-based)
   - **completed**: Auto-expires to idle after 60 seconds
   - **attention**: Auto-expires to idle after 10 minutes
   - **processing**: Auto-expires to idle after 30 minutes without updates
     - Handles time limit scenarios where session stops responding but process remains alive
     - Prevents perpetual "processing" display when ClaudeCode reaches conversation limits

This multi-layer cleanup ensures displayed status always reflects actual running ClaudeCode instances.

### State Persistence

Status stored in JSON file (`~/.claude-monitor/sessions.json`):
```json
{
  "a3a5596b": {
    "project_name": "claude-monitor",
    "project_path": "/Users/user/projects/claude-monitor",
    "status": "processing",
    "priority": 3,
    "timestamp": 1706345678,
    "last_updated": 1706345678.123
  }
}
```

**Concurrency Safety**: Uses directory-based file locking to prevent race conditions during concurrent hook execution.

### Configuration Management

Installation intelligently merges with existing `~/.claude/settings.json`:
- Backs up original configuration with timestamp
- Offers merge strategies: replace, append, or preserve existing hooks
- Validates JSON integrity before applying changes
- Stores backup path for easy rollback

## Known Issues & Solutions

### Issue: Stale Sessions After Abnormal Exit
**Cause**: `SessionEnd` hook doesn't fire when ClaudeCode crashes or is force-killed
**Solution**: Auto-cleanup runs every second, removes dead sessions within 5 minutes

### Issue: False 💤 Icon When No Sessions Exist
**Cause**: Plugin showed "idle" even before first ClaudeCode session
**Solution**: Added `has-sessions` check to distinguish inactive vs idle states

### Issue: Status Not Updating in Real-Time
**Cause**: Hook script permissions or missing dependencies
**Solution**: Installation script ensures executable permissions and validates dependencies

### Issue: Processing Status Persists After Time Limit ✅ FIXED
**Cause**: When ClaudeCode reaches time limit, process may remain alive but stop triggering hooks
**Solution**: Processing status auto-expires to idle after 30 minutes without `last_updated` changes (lib/status_manager.sh:129)

## Troubleshooting

### Quick Diagnostics
```bash
# Check if SwiftBar is running
pgrep -f SwiftBar

# Check if sessions are tracked
cat ~/.claude-monitor/sessions.json | jq .

# Verify hook configuration
cat ~/.claude/settings.json | jq .hooks

# Test hook execution
~/.claude/hooks/update_status.sh processing && echo "Hook works!"
```

### Common Problems

**Menu bar icon not appearing**
1. Verify SwiftBar is installed and running
2. Check plugin file exists and is executable: `ls -l ~/Library/Application\ Support/SwiftBar/claude_monitor.1s.sh`
3. Restart SwiftBar: `~/.claude-monitor/scripts/swiftbar_manager.sh restart`

**Status not updating when using ClaudeCode**
1. Verify hooks are configured: `cat ~/.claude/settings.json | jq .hooks`
2. Test hook manually: `~/.claude/hooks/update_status.sh processing`
3. Check for errors: `export CLAUDE_MONITOR_DEBUG=1` and watch `~/.claude-monitor/debug.log`

**Multiple duplicate sessions showing**
1. Auto-cleanup removes dead sessions within 5 minutes
2. Manual cleanup: `~/.claude-monitor/lib/status_manager.sh clean-dead`
3. Full reset: `rm ~/.claude-monitor/sessions.json && echo '{}' > ~/.claude-monitor/sessions.json`

## Configuration Safety

The project prioritizes safe configuration management:

1. **Pre-installation backup**: Original `settings.json` backed up with timestamp
2. **Conflict detection**: Detects existing hooks and offers merge strategies
3. **JSON validation**: Validates configuration before applying changes
4. **Easy rollback**: Backup path stored in `~/.claude-monitor/backup_path.txt`
5. **Clean uninstall**: Restores original configuration from backup

## Performance Considerations

- **Hook execution time**: < 100ms (minimal impact on ClaudeCode)
- **SwiftBar refresh rate**: 3 seconds (balances responsiveness and CPU usage)
- **Dynamic refresh**: Can be tuned based on status priority
- **Memory footprint**: < 5MB (JSON file + shell scripts)
- **Concurrent safety**: File locking prevents race conditions

## Context for Development

This tool solves a real workflow problem: when using ClaudeCode for complex multi-step tasks, users often miss notification prompts or don't realize tasks have completed, leading to workflow interruptions and context switching overhead.

The design emphasizes:
- **Non-intrusive**: Glanceable status without stealing focus
- **Safe configuration**: Never breaks existing ClaudeCode setup
- **Multi-session aware**: Handles multiple projects gracefully
- **Fail-safe**: Errors in monitoring never affect ClaudeCode operation