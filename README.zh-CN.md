# ClaudeCode 监控器

[English](README.md) | [简体中文](README.zh-CN.md)

**告别窗口切换，专注心流**

是否经常在终端窗口间来回切换，只为查看 ClaudeCode 是否完成？是否因为"需要用户确认"的提示被埋在其他工作区而错过？是否在多个项目中使用 Claude，却不记得哪个在处理、哪个在等你？

**ClaudeCode 监控器解决了这个问题**，通过精美的动画指示器将实时状态直接显示在 macOS 菜单栏中。

![Menu Bar Preview](https://img.shields.io/badge/macOS-Menu%20Bar-blue?logo=apple)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 痛点

使用 ClaudeCode 时，你会面临持续的注意力碎片化：

### 🔄 窗口切换成本
每次查看状态都需要切换窗口或工作区，打断心流。你正在编辑器中写代码，却需要每隔几分钟跳转到终端查看 Claude 是否完成。

### ⚠️ 错过通知
ClaudeCode 提示需要用户确认，但你正在 Slack、浏览器或另一个终端标签页中。等你注意到时，已经浪费了宝贵的几分钟——或者忘记了自己在做什么。

### 🎯 多项目混乱
在 3 个不同项目中运行 Claude？祝你能记住哪个在处理、哪个需要输入、哪个在 10 分钟前就完成了。

### ⏳ 不确定的等待
Claude 还在思考吗？崩溃了吗？我现在应该检查还是再等一分钟？这种不确定性浪费时间和精力。

### 📊 状态盲区
在其他应用中工作时，你完全看不到 ClaudeCode 的状态。你要么检查太频繁（浪费时间），要么检查太少（错过提示）。

---

## 解决方案

ClaudeCode 监控器为你提供**一目了然的感知**，无需离开当前任务：

**之前：** 🖥️→🔍→⌨️→🖥️→🔍（频繁切换）
**之后：** 👀（瞥一眼菜单栏）→ ✅（继续工作）

### 可视化状态指示器

通过流畅的 **6 帧顺时针动画**实时观看 Claude 工作：

```
⠇ → ⠦ → ⠴ → ⠸ → ⠙ → ⠋  (处理中)
⚠️  (需要你的注意！)
✅  (已完成，等待查看)
💤  (等待你的下一个任务)
```

### 基于优先级的显示

菜单栏自动显示所有项目中**最紧急**的状态：
1. **⚠️ 需要注意**（最高优先级）- 放下一切，Claude 需要你
2. **⠋ 处理中** - Claude 正在工作，你可以专注其他事情
3. **✅ 已完成** - 准备好供你查看
4. **💤 空闲** - 等待你的下一个提示

### 多项目感知

点击菜单栏图标查看每个项目的详细状态：
```
项目：
  ⚠️ my-web-app      (需要确认)
  ⠴ backend-api      (处理中)
  ✅ docs-site       (已完成)
  💤 mobile-app      (空闲)
```

---

## 使用场景

### 场景 1：并行开发
你正在重构 `project-a`，同时 Claude 在审查 `project-b` 并为 `project-c` 生成测试。瞥一眼菜单栏就能知道：
- `project-b` 审查完成 ✅
- `project-c` 仍在工作 ⠦
- `project-a` 还不需要关注 💤

**结果：**零次窗口切换。你可以先完成当前的思路，再去查看完成的工作。

### 场景 2：长时间运行任务
你让 Claude 分析一个大型代码库（5-10 分钟）。不必每 30 秒焦虑地检查一次，你可以：
1. 看到处理动画 ⠴
2. 切换到邮件/Slack
3. 当菜单栏显示 ⚠️ 时被拉回（Claude 有疑问）

**结果：**每个长任务回收 5-10 分钟的有效工作时间。

### 场景 3：高频交互
通过多次迭代与 Claude 构建功能。每个确认提示可能让你损失 30-60 秒的注意力延迟：
- 没有监控器：10 个提示 × 45 秒 = 7.5 分钟损失
- 有监控器：⚠️ 出现 → 立即响应 → 0 延迟

**结果：**交互延迟减少 50-80%。

---

## 功能特性

- 🔄 **实时状态跟踪** - 同时监控多个项目的 ClaudeCode 活动
  → *解决：窗口切换成本、状态盲区*

- ⚠️ **基于优先级的警报** - 需要注意的任务在菜单栏中闪烁（不可能错过）
  → *解决：错过通知*

- 🎯 **智能状态显示** - 自动显示所有会话中最紧急的状态
  → *解决：多项目混乱*

- ⠋ **动画处理指示器** - 精美的 6 帧顺时针动画显示 Claude 正在工作
  → *解决：不确定的等待*

- 📊 **多会话支持** - 独立跟踪无限个 ClaudeCode 会话及项目名称
  → *解决：多项目混乱*

- 🚀 **零性能影响** - 最小资源占用（< 5MB RAM），无干扰运行
  → *故障安全设计：监控错误永不影响 ClaudeCode*

- 🔧 **安全安装** - 智能合并现有 ClaudeCode 设置，自动备份
  → *永不破坏你的现有配置*

## 状态类型

| 优先级 | 图标 | 状态 | 描述 | 看到时的行动 |
|----------|------|--------|-------------|-------------------|
| 🔴 **P1** | ⚠️ | **需要注意** | 需要用户确认 | 放下手头工作——Claude 需要你！ |
| 🟡 **P2** | ⠇⠦⠴⠸⠙⠋ | **处理中** | Claude 正在积极工作 | 放松，喝杯咖啡，Claude 搞定了 |
| 🟢 **P3** | ✅ | **已完成** | 任务完成，准备查看 | 准备好时检查结果 |
| ⚪ **P4** | 💤 | **空闲** | 等待你的下一个提示 | Claude 已准备好接受你的下一个任务 |
| ⚫ **—** | 💤0 | **未激活** | 未检测到会话 | 在任意项目中启动 ClaudeCode |

### 处理动画

处理指示器使用每秒更新的流畅**顺时针旋转**：

```
帧 1: ⠇  (左列)          ●●○
帧 2: ⠦  (左下)          ○●●
帧 3: ⠴  (右下)          ○○●
帧 4: ⠸  (右列)          ○●●
帧 5: ⠙  (右上)          ●○○
帧 6: ⠋  (左上)          ●●○
(循环)
```

每一帧保持一个"锚点"固定，同时移动两个点，创造出对眼睛友好的流畅圆周运动。

## 前置要求

- 具有菜单栏访问权限的 macOS
- 已安装并配置 [ClaudeCode](https://claude.ai/code)
- [Homebrew](https://brew.sh)（推荐用于自动安装）

将自动安装的依赖：
- [SwiftBar](https://github.com/swiftbar/SwiftBar) - 菜单栏插件系统
- `jq` - JSON 处理器

## 快速安装

```bash
# 克隆仓库
git clone <repository-url>
cd claude-monitor

# 运行安装脚本
./install.sh
```

安装程序将：
1. 检查并安装依赖（SwiftBar、jq）
2. 选择安装范围（全局或特定项目）
3. 备份现有的 ClaudeCode 配置
4. 配置状态监控的 hooks
5. 安装 SwiftBar 插件
6. 可选启动监控器

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

## 菜单栏显示逻辑

菜单栏显示所有活动会话中**优先级最高**的状态：

1. **⚠️ 2** - 2 个项目需要注意（最高优先级）
2. **⠁ 1** - 1 个项目处理中
3. **✅ 3** - 3 个项目已完成
4. **💤** - 所有项目空闲
5. **💤0** - 无活动会话

点击图标查看每个项目的详细状态。

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
# 清理过期会话
~/.claude-monitor/lib/status_manager.sh clean

# 或完全重置
rm ~/.claude-monitor/sessions.json
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

## 配置

### 安装范围

**全局安装（推荐）**
- 系统范围监控所有 ClaudeCode 会话
- 使用 `~/.claude/settings.json`
- 跨所有项目工作

**项目特定安装**
- 仅监控特定项目中的 ClaudeCode
- 使用项目目录中的 `./.claude/settings.json`
- 每个项目需要单独设置

### 自定义

编辑配置文件以自定义行为：

```bash
# Status manager 设置
~/.claude-monitor/lib/status_manager.sh

# Hook 行为
~/.claude/hooks/update_status.sh

# 菜单栏显示
~/Library/Application Support/SwiftBar/claude_monitor.1s.sh
```

## 架构

```
┌─────────────────────┐
│  SwiftBar 菜单栏    │  (显示层)
└──────────┬──────────┘
           │ 读取
           ▼
┌─────────────────────┐
│  Status Manager     │  (数据层 - JSON 存储)
└──────────┬──────────┘
           ▲ 更新
           │
┌─────────────────────┐
│  Hook Bridge        │  (事件层)
└──────────┬──────────┘
           ▲ 触发
           │
┌─────────────────────┐
│  ClaudeCode Hooks   │  (事件源)
└─────────────────────┘
```

## 为什么这很重要

### 窗口切换的成本

研究表明，窗口切换每次中断会消耗 **23 分钟**的专注时间（[UC Irvine 研究](https://www.ics.uci.edu/~gmark/chi08-mark.pdf)）。使用 AI 助手时：

- **每天 10 次状态检查** × 2 分钟 = **损失 20 分钟**
- **每天 3 次错过提示** × 10 分钟 = **损失 30 分钟**
- **总计：每天 50 分钟** = **每周 4+ 小时**

ClaudeCode 监控器通过将状态移至你的**外围视觉**来消除这种损失——始终可见，除非绝对必要否则不会占用注意力。

### 设计理念

1. **一目了然** - 无需窗口切换即可看到状态
2. **优先级化** - 只显示最重要的内容
3. **无干扰** - 外围感知，而非中断
4. **故障安全** - 监控永不破坏 ClaudeCode
5. **精美** - 流畅的动画不会分散注意力

---

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