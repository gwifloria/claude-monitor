# ClaudeCode Monitor 开发指南

## 项目架构原则

### 状态管理设计

#### 1. 会话标识策略
```bash
# ✅ 推荐：基于项目路径的唯一标识
session_id=$(echo -n "$project_path" | md5 | cut -c1-8)

# ❌ 避免：基于进程ID的动态标识
session_id="${project_name}_$$"  # 每次执行都不同
```

**设计理由**：
- 项目路径在会话生命周期内保持不变
- 支持多次hook调用的状态一致性
- 避免同一项目的重复会话记录

#### 2. 状态优先级系统
```bash
STATUS_PRIORITY = {
    "attention": 4,    # 最高优先级：需要用户关注
    "processing": 3,   # 高优先级：正在处理
    "completed": 2,    # 中优先级：任务完成
    "idle": 1,         # 低优先级：空闲状态
    "connected": 1     # 低优先级：仅连接
}
```

**状态转换规则**：
- 高优先级状态覆盖低优先级状态
- 相同优先级状态后执行覆盖先执行
- `attention` 状态具有最高显示权重

#### 3. 生命周期管理
```bash
# 会话创建
SessionStart -> update_status("connected")

# 状态更新
UserPromptSubmit -> update_status("processing")
Notification -> update_status("attention")
SubagentStop -> update_status("completed")
Stop -> update_status("idle")

# 会话销毁
SessionEnd -> remove_session()
```

---

## Hook设计模式

### 集中式状态管理模式

```bash
# 所有hook事件统一路由
ClaudeCode Hook -> update_status.sh -> status_manager.sh -> JSON存储

# 优势
1. 统一的状态更新逻辑
2. 集中的错误处理
3. 一致的日志记录
4. 简化的调试过程
```

### Hook脚本最佳实践

#### 1. 输入验证
```bash
# 严格的参数验证
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <status>" >&2
    exit 1
fi

# 状态值白名单验证
case "$STATUS" in
    "processing"|"attention"|"completed"|"idle"|"connected"|"disconnected")
        ;;
    *)
        echo "Error: Invalid status '$STATUS'" >&2
        exit 1
        ;;
esac
```

#### 2. 智能状态更新
```bash
# 根据状态重要性采用不同策略
case "$STATUS" in
    "processing"|"attention")
        # 重要状态：强制创建会话
        "$STATUS_MANAGER" update "$STATUS"
        ;;
    *)
        # 普通状态：仅在会话存在时更新
        if [[ $("$STATUS_MANAGER" has-sessions) == "true" ]]; then
            "$STATUS_MANAGER" update "$STATUS"
        fi
        ;;
esac
```

#### 3. 错误处理和降级
```bash
# 优雅降级：状态管理器不可用时的处理
if [[ ! -f "$STATUS_MANAGER" ]]; then
    # 记录错误但不阻塞ClaudeCode
    echo "Warning: Status manager not found" >&2
    exit 0  # 正常退出，不影响主流程
fi
```

---

## UI显示逻辑设计

### 状态图标映射
```bash
# 闪烁注意状态显示
get_attention_display() {
    local count="$1"
    local timestamp=$(date +%s)
    local blink=$((timestamp % 2))  # 每秒闪烁

    if [[ $blink -eq 0 ]]; then
        echo "⚠️ $count | color=#ea6161"    # 显示图标
    else
        echo "   $count | color=#ea6161"    # 隐藏图标（空格占位）
    fi
}

get_status_display() {
    case "$status" in
        "attention")
            get_attention_display "$count"              # 红色闪烁
            ;;
        "processing")
            echo "🔄 $count | color=orange"             # 橙色旋转
            ;;
        "completed")
            echo "✅ $count | color=green"              # 绿色静态
            ;;
        "idle")
            echo "💤 $count | color=gray"               # 灰色静态
            ;;
        *)
            echo "󰋗 | color=gray dropdown=false"        # 不活跃状态
            ;;
    esac
}
```

### 会话存在性验证
```bash
# 区分"无会话"和"空闲会话"
has_any_sessions=$("$STATUS_MANAGER" has-sessions)

if [[ "$has_any_sessions" == "false" ]]; then
    # 完全无会话：显示不活跃图标
    echo "󰋗 | color=gray dropdown=false"
    show_inactive_menu
else
    # 有会话但都空闲：显示空闲图标
    echo "💤 $idle_count | color=gray"
    show_active_menu
fi
```

---

## 测试策略

### 单元测试覆盖
```bash
# 状态管理器测试
test_session_creation()
test_session_update()
test_session_removal()
test_duplicate_session_handling()
test_status_priority_logic()

# Hook脚本测试
test_valid_status_acceptance()
test_invalid_status_rejection()
test_session_lifecycle_management()

# SwiftBar插件测试
test_no_sessions_display()
test_single_session_display()
test_multiple_sessions_priority()
test_status_icon_mapping()
```

### 集成测试场景
```bash
# 端到端工作流验证
scenario_1_fresh_installation()
scenario_2_multiple_projects()
scenario_3_session_interruption()
scenario_4_swiftbar_restart()
scenario_5_config_migration()
```

### 性能测试
```bash
# 确保监控不影响ClaudeCode性能
test_hook_execution_time()      # <100ms
test_status_update_frequency()  # 合理的刷新间隔
test_memory_usage()             # 监控内存泄漏
```

---

## 部署最佳实践

### 安装顺序优化
```bash
1. 依赖检查与自动安装
   - jq: JSON处理工具
   - SwiftBar: 菜单栏插件系统
   - Homebrew: 包管理器（可选自动安装）

2. 用户选择收集
   - 安装范围：全局 vs 项目级
   - 配置冲突处理：替换 vs 追加 vs 保留
   - SwiftBar启动偏好

3. 安全备份
   - settings.json -> settings.json.backup.{timestamp}
   - 备份路径记录到 ~/.claude-monitor/backup_path.txt

4. 核心文件部署
   - 状态管理器 -> ~/.claude-monitor/lib/
   - Hook脚本 -> ~/.claude/hooks/ 或 ./.claude/hooks/
   - SwiftBar插件 -> ~/Library/Application Support/SwiftBar/

5. 配置生成与合并
   - 生成新的hook配置
   - 与现有settings.json智能合并
   - JSON语法验证

6. 功能验证测试
   - 状态管理器可执行性
   - SwiftBar插件加载
   - Hook脚本权限

7. 可选启动
   - 用户确认后启动SwiftBar
   - 显示使用指南
```

### 错误恢复策略
```bash
# 安装失败时的回滚机制
rollback_on_failure() {
    if [[ -f "$backup_path" ]]; then
        cp "$backup_path" "$CLAUDE_SETTINGS_FILE"
        echo "Configuration restored from backup"
    fi

    # 清理部分安装的文件
    rm -f ~/.claude/hooks/update_status.sh
    rm -rf ~/.claude-monitor/

    echo "Installation rolled back due to errors"
}

trap rollback_on_failure ERR
```

---

## 调试和监控

### 调试模式设计
```bash
# 环境变量控制的调试级别
export CLAUDE_MONITOR_DEBUG=1    # 基础调试信息
export CLAUDE_MONITOR_VERBOSE=1  # 详细执行日志
export CLAUDE_MONITOR_TRACE=1    # 函数调用跟踪

# 日志输出格式
[2025-01-27 14:30:25] [INFO] Session a3a5596b updated to processing
[2025-01-27 14:30:26] [DEBUG] SwiftBar refresh triggered
[2025-01-27 14:30:27] [TRACE] get_status_display(processing, 1) called
```

### 实时监控命令
```bash
# 状态监控
watch -n 2 'status_manager.sh summary'

# 会话详情
status_manager.sh list | column -t -s'|'

# SwiftBar插件测试
~/Library/Application\ Support/SwiftBar/claude_monitor.5s.sh

# 日志跟踪
tail -f ~/.claude-monitor/debug.log | grep ERROR
```

### 性能监控
```bash
# Hook执行时间统计
time ~/.claude/hooks/update_status.sh processing

# JSON文件大小监控
du -h ~/.claude-monitor/sessions.json

# SwiftBar刷新频率分析
grep "refresh triggered" ~/.claude-monitor/debug.log | wc -l
```

---

## 常见陷阱与避免方法

### 1. 文件锁竞争
```bash
# ❌ 避免：无锁的并发写入
echo '{}' > sessions.json  # 多个进程同时写入会冲突

# ✅ 推荐：基于目录的原子锁
acquire_lock() {
    local timeout=5
    while ! mkdir "$LOCK_FILE" 2>/dev/null && (( timeout > 0 )); do
        sleep 0.1
        ((timeout--))
    done
}
```

### 2. JSON格式破坏
```bash
# ❌ 避免：直接字符串拼接
echo "{\"key\": \"$value\"}" > file.json  # $value包含特殊字符时破坏JSON

# ✅ 推荐：使用jq处理
jq --arg key "$key" --arg value "$value" '. + {($key): $value}' file.json
```

### 3. 路径空格处理
```bash
# ❌ 避免：未引用的路径变量
cd $project_path  # 路径包含空格时失败

# ✅ 推荐：正确的路径引用
cd "$project_path"
```

### 4. 进程残留
```bash
# ❌ 避免：kill不完整
pkill SwiftBar  # 可能无法清理所有相关进程

# ✅ 推荐：完整的进程清理
pkill -f "SwiftBar"
sleep 2
pgrep -f "SwiftBar" && pkill -9 -f "SwiftBar"
```

---

## 代码质量检查

### Shell脚本最佳实践
```bash
#!/bin/bash

# 严格模式
set -euo pipefail

# 常量声明
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${HOME}/.claude-monitor/config.json"

# 函数错误处理
function_with_error_handling() {
    local input="$1"

    if [[ -z "$input" ]]; then
        echo "Error: Input required" >&2
        return 1
    fi

    # 函数逻辑
    echo "Processing: $input"
}

# 主函数模式
main() {
    function_with_error_handling "$@"
}

# 错误处理
trap 'echo "Error at line $LINENO" >&2' ERR

# 执行主函数
main "$@"
```

### 代码审查检查清单
- [ ] 所有变量都正确引用 (`"$var"` 而非 `$var`)
- [ ] 错误处理覆盖所有关键操作
- [ ] 文件路径处理支持空格和特殊字符
- [ ] JSON操作使用jq而非字符串拼接
- [ ] 并发安全（文件锁、原子操作）
- [ ] 资源清理（临时文件、进程、锁）
- [ ] 输入验证和边界条件检查
- [ ] 调试信息输出（可通过环境变量控制）

---

## 维护和扩展指南

### 新增状态类型
1. 在 `update_status.sh` 中添加状态验证
2. 在 `status_manager.sh` 中定义优先级
3. 在 `claude_monitor.5s.sh` 中添加图标映射
4. 更新文档和测试用例

### 新增Hook类型
1. 确定Hook的触发时机和频率
2. 设计对应的状态更新逻辑
3. 在 `generate_settings.sh` 中添加配置
4. 测试Hook的性能影响

### 平台扩展支持
- Linux: 替换SwiftBar为其他状态栏工具
- Windows: 使用系统托盘API
- 通用: 提供命令行界面作为fallback

通过遵循这些开发指南，可以确保ClaudeCode Monitor项目的代码质量、可维护性和扩展性，同时避免重复遇到已知的设计陷阱。

---

# 项目背景与需求规格（原 init.md 内容）

## 项目背景与目标

开发一个基于 SwiftBar 的 macOS 菜单栏应用，通过 ClaudeCode 的 hooks 系统实时显示 ClaudeCode 的工作状态，解决用户在使用 ClaudeCode 时的注意力碎片化问题。

### 核心痛点

- 用户需要频繁切换到 ClaudeCode 界面查看处理进度
- 错过需要用户确认的操作（如 proceed 确认）
- 任务完成后用户沉浸在其他工作中，未及时处理下一步

## 技术架构

### 依赖组件

1. **SwiftBar** - macOS 菜单栏工具（开源）
2. **ClaudeCode** - Anthropic 命令行工具
3. **Hooks 系统** - ClaudeCode 内置的生命周期钩子

### ClaudeCode Hooks 说明

- `PreToolUse`: 工具调用前执行（可阻止调用）
- `PostToolUse`: 工具调用完成后执行
- `UserPromptSubmit`: 用户提交 prompt 后、Claude 处理前执行
- `Notification`: ClaudeCode 发送通知时执行
- `Stop`: ClaudeCode 完成响应时执行
- `SubagentStop`: 子代理任务完成时执行
- `PreCompact`: ClaudeCode 准备执行压缩操作前执行
- `SessionStart`: 会话开始或恢复时执行
- `SessionEnd`: 会话结束时执行

## 功能需求

### 状态显示规范

#### 1. 用户确认等待状态

- **触发条件**: 需要用户确认操作（如 proceed）
- **显示效果**: ⚠️ 图标闪烁
- **用户行为**: 提醒用户切换到 ClaudeCode 界面完成确认
- **实现 Hook**: `Notification`

#### 2. 任务处理中状态

- **触发条件**: 用户提交 prompt 后
- **显示效果**: 🔄 旋转图标或进度指示器
- **用户行为**: 告知用户 ClaudeCode 正在处理，可以继续其他工作
- **实现 Hook**: `UserPromptSubmit`

#### 3. 任务完成状态

- **触发条件**: 子代理任务完成
- **显示效果**: ✅ 完成图标
- **用户行为**: 提醒用户任务已完成，可以开始新任务
- **实现 Hook**: `SubagentStop`

#### 5. 工具调用状态（可选）

- **触发条件**: ClaudeCode 准备调用工具时
- **显示效果**: 🔧 工具图标
- **用户行为**: 告知用户正在执行具体操作（如文件读写、网络请求）
- **实现 Hook**: `PreToolUse` → `PostToolUse`

#### 6. 会话断开状态

- **触发条件**: ClaudeCode 会话结束
- **显示效果**: ❌ 或 📴 断开图标
- **用户行为**: 提醒用户需要重新启动 ClaudeCode
- **实现 Hook**: `SessionEnd`

#### 7. 数据压缩状态（可选）

- **触发条件**: ClaudeCode 执行上下文压缩
- **显示效果**: 📦 压缩图标
- **用户行为**: 告知用户正在优化会话内容，可能需要等待
- **实现 Hook**: `PreCompact`

### Hook 使用策略

#### 核心状态管理 Hooks

```json
{
  "hooks": {
    "UserPromptSubmit": "~/.claude/hooks/update_status.sh processing",
    "Notification": "~/.claude/hooks/update_status.sh attention",
    "SubagentStop": "~/.claude/hooks/update_status.sh completed",
    "Stop": "~/.claude/hooks/update_status.sh idle",
    "SessionEnd": "~/.claude/hooks/update_status.sh disconnected"
  }
}
```

#### 可选增强功能 Hooks

```json
{
  "hooks": {
    "PreToolUse": "~/.claude/hooks/update_status.sh tool_pending",
    "PostToolUse": "~/.claude/hooks/update_status.sh tool_completed",
    "PreCompact": "~/.claude/hooks/update_status.sh compacting",
    "SessionStart": "~/.claude/hooks/update_status.sh connected"
  }
}
```

## 技术实现要求

### 自动化安装

1. **SwiftBar 安装脚本**

   - 检测系统是否已安装 SwiftBar
   - 提供 Homebrew 安装命令
   - 配置 SwiftBar 插件目录

2. **ClaudeCode 配置**
   - 智能修改 `~/.claude/settings.json`（支持现有配置合并）
   - 添加必要的 hooks 配置
   - 创建状态更新脚本
   - 备份原有配置文件

## 配置管理策略

### 现有配置处理

项目需要处理用户已有 `~/.claude/settings.json` 的情况：

#### 1. 配置文件检测与备份

- 检测 `~/.claude/settings.json` 是否存在
- 如果存在，创建备份文件 `settings.json.backup.{timestamp}`
- 解析现有 JSON 配置

#### 2. Hooks 配置合并策略

```bash
# 示例处理逻辑
if [ -f ~/.claude/settings.json ]; then
    # 读取现有配置
    existing_config=$(cat ~/.claude/settings.json)

    # 检查是否已有 hooks 配置
    if echo "$existing_config" | jq -e '.hooks' > /dev/null; then
        # 合并新的 hooks，保留用户原有的 hooks
        jq '.hooks += {
            "UserPromptSubmit": "~/.claude/hooks/update_status.sh processing",
            "Notification": "~/.claude/hooks/update_status.sh attention",
            "SubagentStop": "~/.claude/hooks/update_status.sh completed",
            "Stop": "~/.claude/hooks/update_status.sh idle",
            "SessionEnd": "~/.claude/hooks/update_status.sh disconnected"
        }' ~/.claude/settings.json > ~/.claude/settings.json.tmp
    else
        # 添加整个 hooks 对象
        jq '. + {"hooks": {...}}' ~/.claude/settings.json > ~/.claude/settings.json.tmp
    fi

    mv ~/.claude/settings.json.tmp ~/.claude/settings.json
else
    # 创建新的配置文件
    echo '{"hooks": {...}}' > ~/.claude/settings.json
fi
```

#### 3. 冲突处理机制

- **Hook 名称冲突**：如果用户已配置相同的 hook，提供选项：
  - 保留用户原有配置（默认）
  - 覆盖为菜单栏工具配置
  - 链式调用（先执行原有，再执行菜单栏工具）
- **配置验证**：安装完成后验证 JSON 格式正确性

#### 4. 卸载支持

- 提供卸载脚本，能够：
  - 移除菜单栏工具添加的 hooks
  - 恢复原有配置（从备份恢复）
  - 清理相关脚本文件

### 安全考虑

- 在修改配置前询问用户确认
- 显示将要添加的 hooks 配置
- 提供回滚机制

## 项目交付物

1. **SwiftBar 插件脚本** (.sh)
2. **ClaudeCode hooks 脚本集**
3. **自动安装配置脚本**
4. **用户使用文档**

## 需要澄清的问题

1. **Stop vs SubagentStop 的区别**：

   - `Stop`: ClaudeCode 主进程完成一次完整的响应
   - `SubagentStop`: 特定子任务（如文件操作、代码生成等）完成
   - 需要确认这两个 hook 的具体触发时机和使用场景

2. **状态持久化策略**：

   - 状态信息存储位置和格式
   - 多会话情况下的状态管理

3. **错误处理**：
   - ClaudeCode 异常退出时的状态重置
   - Hook 脚本执行失败的回退机制

## 状态优先级分析

### 🎯 **核心必需状态**（影响用户工作流）

- `UserPromptSubmit`: 处理中状态 - **必需**
- `Notification`: 需要用户确认 - **必需**
- `SubagentStop`: 任务完成 - **必需**
- `Stop`: 空闲状态 - **必需**
- `SessionEnd`: 会话断开 - **强烈建议**（避免用户对着断开的会话发送 prompt）

### 🔧 **增强功能状态**（提升用户体验）

- `PreToolUse/PostToolUse`: 工具调用状态 - **可选**（但对长时间工具调用很有用）
- `PreCompact`: 压缩状态 - **可选**（压缩通常很快，不太需要提示）
- `SessionStart`: 连接状态 - **可选**（用户通常知道自己启动了 ClaudeCode）

### 💡 **实现建议**

1. **第一版本**：只实现核心必需状态，确保基本功能稳定
2. **后续版本**：根据用户反馈逐步添加增强功能
3. **配置化**：允许用户在配置文件中启用/禁用特定状态显示