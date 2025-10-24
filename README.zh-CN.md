# ClaudeCode 监控器

[English](README.md) | [简体中文](README.zh-CN.md)

**macOS 菜单栏实时显示 ClaudeCode 状态**

无需切换窗口查看 Claude 是否完成，再也不会错过确认提示。

![Menu Bar Preview](https://img.shields.io/badge/macOS-Menu%20Bar-blue?logo=apple)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 功能特性

- 🔄 **实时状态** - 同时跟踪多个 ClaudeCode 项目
- ⚠️ **智能警报** - 确认提示在菜单栏闪烁（不可能错过）
- ⠋ **动画指示器** - 精美的 6 帧顺时针动画显示 Claude 正在工作
- 🎯 **优先级显示** - 自动显示所有会话中最紧急的状态
- 📊 **多会话** - 独立状态跟踪，管理无限项目
- 🚀 **零影响** - 最小资源占用（< 5MB RAM），故障安全设计
- 🔧 **安全设置** - 智能配置合并，自动备份

## 状态类型

| 图标 | 状态 | 描述 |
|------|--------|-------------|
| ⚠️ | **需要注意** | 需要用户确认（最高优先级） |
| ⠇⠦⠴⠸⠙⠋ | **处理中** | Claude 正在工作（6 帧顺时针动画） |
| ✅ | **已完成** | 任务完成，准备查看 |
| 💤 | **空闲** | 等待你的下一个提示 |
| 💤0 | **未激活** | 未检测到 ClaudeCode 会话 |

## 安装

**前置要求：** macOS、[ClaudeCode](https://claude.ai/code)、[Homebrew](https://brew.sh)

```bash
git clone <repository-url>
cd claude-monitor
./install.sh
```

安装程序自动配置依赖（SwiftBar、jq）和 ClaudeCode hooks。

## 使用方法

### 启动监控器

```bash
~/.claude-monitor/scripts/swiftbar_manager.sh start
```

### 查看状态

点击菜单栏图标查看：
- 带计数的总体状态摘要
- 各个项目的状态
- 快速导航到项目目录
- 清理和刷新选项

### 管理监控器

```bash
# 停止监控
~/.claude-monitor/scripts/swiftbar_manager.sh stop

# 重启
~/.claude-monitor/scripts/swiftbar_manager.sh restart

# 检查状态
~/.claude-monitor/scripts/swiftbar_manager.sh status
```

## 工作原理

ClaudeCode 监控器与 ClaudeCode 的内置 hooks 系统无缝集成：

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│ ClaudeCode  │ event   │ Hook Bridge  │ update  │   Status    │
│   (CLI)     │────────>│ (转换器)      │────────>│  Manager    │
│             │         │              │         │   (JSON)    │
└─────────────┘         └──────────────┘         └──────┬──────┘
                                                         │ read
                                                         ▼
                                                  ┌─────────────┐
                                                  │  SwiftBar   │
                                                  │ 菜单栏 UI   │
                                                  └─────────────┘
```

### 事件流程

**当你提交提示时：**
1. `UserPromptSubmit` hook 触发 → 更新状态为 **⠇ 处理中**
2. SwiftBar 每 1 秒读取状态 → 显示动画旋转器
3. Claude 完成 → `Stop` hook 触发 → 状态变为 **✅ 已完成**
4. 你开始新任务 → 状态返回 **💤 空闲**

**当 Claude 需要确认时：**
1. `Notification` hook 触发 → 状态跳转到 **⚠️ 需要注意**（最高优先级）
2. 菜单栏显示警告图标 → 不可能错过
3. 你响应 → Hook 更新状态 → 动画继续

### 配置的 Hooks

| Hook 事件 | 触发时机 | 状态更新 | 优先级 |
|------------|---------|---------------|----------|
| `UserPromptSubmit` | 你发送提示 | ⠋ **处理中** | P2 |
| `Notification` | Claude 需要确认 | ⚠️ **需要注意** | P1（最高） |
| `Stop` | Claude 完成整个响应 | ✅ **已完成** | P3 |
| `SessionStart` | 新的 ClaudeCode 会话 | 💤 **空闲** | P4 |
| `SessionEnd` | ClaudeCode 退出 | *（移除会话）* | — |

> **注意**：`SubagentStop` **有意不配置**。Sub-agent 完成并不意味着主任务完成——Claude 可能启动多个 sub-agents 或在之后继续处理。

### 数据存储

状态存储在 `~/.claude-monitor/sessions.json` 的 JSON 中：
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

每个会话通过项目路径的 MD5 哈希标识，确保跨 hook 调用的一致跟踪。

## 故障排查

### 启用调试模式

```bash
export CLAUDE_MONITOR_DEBUG=1
tail -f ~/.claude-monitor/debug.log
```

### 常见问题

**菜单栏图标未出现：**
```bash
# 检查 SwiftBar 是否运行
pgrep -f SwiftBar

# 重启 SwiftBar
~/.claude-monitor/scripts/swiftbar_manager.sh restart
```

**状态未更新：**
```bash
# 手动测试 hook
~/.claude/hooks/update_status.sh processing

# 检查 hook 配置
cat ~/.claude/settings.json | jq .hooks

# 验证会话是否被跟踪
cat ~/.claude-monitor/sessions.json | jq .
```

**多个重复会话：**
```bash
# 自动清理每秒运行（5分钟内移除死会话）
# 需要时手动清理：
~/.claude-monitor/lib/status_manager.sh clean-dead

# 或完全重置
rm ~/.claude-monitor/sessions.json && echo '{}' > ~/.claude-monitor/sessions.json
```

### 获取帮助

1. 查看 [docs/README.md](docs/README.md) 获取详细文档
2. 查阅 [docs/development-guide.md](docs/development-guide.md) 了解技术细节
3. 参见 [docs/bug-analysis.md](docs/bug-analysis.md) 了解已知问题和解决方案

## 卸载

完全移除 ClaudeCode 监控器：

```bash
./uninstall.sh
```

这将：
- 移除所有已安装的文件
- 从备份还原原始 ClaudeCode 配置
- 清理 SwiftBar 插件
- 移除运行时数据

## 贡献

欢迎贡献！请阅读 [docs/development-guide.md](docs/development-guide.md) 了解开发设置和编码指南。

## 许可证

MIT License - 详见 LICENSE 文件

## 致谢

- 为 Anthropic 的 [ClaudeCode](https://claude.ai/code) 构建
- 使用 [SwiftBar](https://github.com/swiftbar/SwiftBar) 进行菜单栏集成
- 受到 AI 辅助开发中更好工作流感知需求的启发

---

**注意**：此工具设计为完全无干扰。如果监控系统发生任何错误，它们永远不会影响 ClaudeCode 的操作。监控器会优雅且安静地失败。