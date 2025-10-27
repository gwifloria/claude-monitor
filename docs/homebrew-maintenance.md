# Homebrew 维护指南

本文档为 ClaudeCode Monitor 的维护者提供 Homebrew 发布和更新的完整流程。

## ⚡ 推荐：自动化发布流程（GitHub Actions）

**从 v0.2.2+ 开始，项目使用 GitHub Actions 自动更新 Homebrew formula，大幅简化发布流程。**

### 工作原理

当你在 GitHub 创建新 Release 时，GitHub Actions 会自动：
1. 下载新版本的 tarball
2. 计算 SHA256 checksum
3. 更新 `gwifloria/homebrew-tap` 仓库中的 formula
4. 提交并推送更改

**完全无需手动操作 homebrew-tap 仓库！**

### 一次性设置（只需执行一次）

#### 1. 创建 GitHub Personal Access Token

访问 https://github.com/settings/tokens/new 并创建 token：

**Token 配置：**
- Name: `HOMEBREW_TAP_TOKEN`
- Expiration: 1 year 或 No expiration（推荐）
- Scopes（权限）:
  - ✅ `repo` (所有子权限)
  - ✅ `workflow`

**重要**: 创建后立即复制 token（只显示一次）

#### 2. 添加 Secret 到主仓库

1. 访问 https://github.com/gwifloria/claude-monitor/settings/secrets/actions
2. 点击 **New repository secret**
3. Name: `HOMEBREW_TAP_TOKEN`
4. Value: 粘贴刚才创建的 token
5. 点击 **Add secret**

### 简化的发布流程（5-10 分钟）

```bash
# 1. 更新版本号
echo "0.3.0" > VERSION

# 2. 更新 Formula（仅版本号和 URL，SHA256 无需填写）
# 编辑 Formula/claude-monitor.rb:
#   version "0.3.0"
#   url "https://github.com/gwifloria/claude-monitor/archive/refs/tags/v0.3.0.tar.gz"
#   sha256 "" # 留空，GitHub Actions 会自动更新 homebrew-tap

# 3. 更新 CHANGELOG.md

# 4. 提交并创建 tag
git add .
git commit -m "Release v0.3.0"
git tag -a v0.3.0 -m "Release version 0.3.0"
git push origin main && git push origin v0.3.0

# 5. 在 GitHub 创建 Release（参考 .github/RELEASE_TEMPLATE.md）
# ✅ GitHub Actions 会自动更新 homebrew-tap！
```

### 验证自动化是否成功

1. **检查 GitHub Actions 运行状态**:
   - 访问 https://github.com/gwifloria/claude-monitor/actions
   - 查看 "Update Homebrew Formula" workflow 是否成功运行

2. **验证 homebrew-tap 更新**:
   ```bash
   # 方法1：GitHub 网页查看
   # 访问 https://github.com/gwifloria/homebrew-tap/commits/main
   # 应该看到一个新的提交：更新到你的版本

   # 方法2：命令行查看
   brew update
   brew info gwifloria/tap/claude-monitor  # 检查版本是否正确
   ```

3. **测试安装**:
   ```bash
   brew upgrade claude-monitor
   claude-monitor-setup
   claude-monitor start
   ```

### 故障排除

**Workflow 失败：403 错误**
- 原因：`HOMEBREW_TAP_TOKEN` 权限不足或过期
- 解决：重新创建 token，确保选中 `repo` 和 `workflow` 权限

**Workflow 失败：SHA256 计算错误**
- 原因：GitHub Release 未正确创建或 tarball 不存在
- 解决：检查 Release 页面，确保 tag 对应的 Source code (tar.gz) 可下载

**homebrew-tap 未更新**
- 原因：Workflow 可能没有触发
- 解决：手动触发 workflow 或查看 Actions 页面的错误日志

---

## 📋 备选：手动发布流程（不推荐）

**仅在 GitHub Actions 不可用时使用。** 以下是完整的手动流程：

### 1. 准备发布

```bash
# 确保所有功能已测试
# 确保所有更改已提交到 main 分支

# 决定版本号（遵循语义化版本）
# - Patch (x.x.1): 修复 bug
# - Minor (x.1.0): 新功能，向后兼容
# - Major (1.0.0): Breaking changes
```

### 2. 更新版本号

```bash
# 更新 VERSION 文件
echo "0.2.0" > VERSION

# 更新 CHANGELOG.md（参考下方模板）

# 更新 Formula/claude-monitor.rb
# - version "0.2.0"
# - url "https://github.com/gwifloria/claude-monitor/archive/refs/tags/v0.2.0.tar.gz"
```

### 3. 创建 Git Tag 和 GitHub Release

```bash
# 提交所有更改
git add .
git commit -m "Release v0.2.0"

# 创建 annotated tag
git tag -a v0.2.0 -m "Release version 0.2.0"

# 推送到 GitHub
git push origin main
git push origin v0.2.0
```

### 4. 在 GitHub 创建 Release

1. 访问 GitHub 仓库 → Releases → Create a new release
2. 选择刚创建的 tag `v0.2.0`
3. 标题: `v0.2.0 - [Brief Description]`
4. 内容参考 `.github/RELEASE_TEMPLATE.md`
5. 发布 Release

### 5. 更新 Formula SHA256

```bash
# GitHub 会自动生成源码压缩包，下载并计算 SHA256
curl -L "https://github.com/gwifloria/claude-monitor/archive/refs/tags/v0.2.0.tar.gz" -o claude-monitor-0.2.0.tar.gz

# 计算 SHA256
shasum -a 256 claude-monitor-0.2.0.tar.gz

# 输出示例: abc123def456... claude-monitor-0.2.0.tar.gz
# 复制哈希值
```

### 6. 更新 Homebrew Tap

```bash
# 编辑 Formula/claude-monitor.rb，更新 sha256 字段
# sha256 "从上一步获取的哈希值"

# 切换到 homebrew-tap 仓库
cd ../homebrew-tap

# 复制更新后的 Formula
cp ../claude-monitor/Formula/claude-monitor.rb .

# 提交并推送
git add claude-monitor.rb
git commit -m "Update claude-monitor to v0.2.0"
git push origin main
```

### 7. 验证安装

```bash
# 更新本地 tap
brew update

# 升级到新版本
brew upgrade claude-monitor

# 验证版本
claude-monitor --version  # 如果有版本命令

# 测试功能
claude-monitor-setup
claude-monitor start
```

## 🔧 快速更新流程（已有 Tap）

后续版本更新只需约 15 分钟：

```bash
# 1. 更新版本号和文档
echo "0.3.0" > VERSION
# 编辑 CHANGELOG.md 和 Formula/claude-monitor.rb

# 2. 提交并创建 tag
git add .
git commit -m "Release v0.3.0"
git tag -a v0.3.0 -m "Release version 0.3.0"
git push origin main && git push origin v0.3.0

# 3. 创建 GitHub Release

# 4. 更新 SHA256 并推送到 Tap
curl -L "https://github.com/gwifloria/claude-monitor/archive/refs/tags/v0.3.0.tar.gz" | shasum -a 256
# 编辑 Formula 更新 sha256
cd ../homebrew-tap
cp ../claude-monitor/Formula/claude-monitor.rb .
git commit -am "Update claude-monitor to v0.3.0"
git push
```

## 📝 CHANGELOG 模板

```markdown
## [0.2.0] - YYYY-MM-DD

### Added

- 新功能描述

### Changed

- 变更描述

### Deprecated

- 废弃功能描述

### Removed

- 移除功能描述

### Fixed

- 修复问题描述

### Security

- 安全更新描述
```

## 🧪 本地测试 Formula

在发布前测试 Formula：

```bash
# 语法检查
brew audit --strict Formula/claude-monitor.rb

# 样式检查
brew style Formula/claude-monitor.rb

# 自动修复样式问题
brew style --fix Formula/claude-monitor.rb

# 从本地 Formula 安装测试
brew uninstall claude-monitor  # 如果已安装
brew install --build-from-source Formula/claude-monitor.rb

# 验证功能
claude-monitor-setup
claude-monitor start

# 清理测试
brew uninstall claude-monitor
```

## 🆘 常见问题

### SHA256 不匹配错误

**原因**: Formula 中的 SHA256 与实际压缩包不符

**解决方案**:

```bash
# 重新下载并计算
rm claude-monitor-*.tar.gz
curl -L "https://github.com/gwifloria/claude-monitor/archive/refs/tags/v0.2.0.tar.gz" -o claude-monitor-0.2.0.tar.gz
shasum -a 256 claude-monitor-0.2.0.tar.gz

# 更新 Formula 中的 sha256 字段
```

### 用户报告安装失败

让用户尝试：

```bash
brew doctor          # 检查 Homebrew 健康状况
brew update          # 更新 Homebrew
brew upgrade         # 升级所有包
brew reinstall gwifloria/tap/claude-monitor
```

### Formula 安装后命令不可用

检查：

```bash
# 1. 检查 bin 目录是否正确创建
ls -la $(brew --prefix)/bin/claude-monitor*

# 2. 检查权限
chmod +x $(brew --prefix)/bin/claude-monitor*

# 3. 检查 PATH
echo $PATH | grep $(brew --prefix)/bin
```

### SwiftBar 插件未安装

手动检查：

```bash
# 检查插件是否存在
ls -la "$HOME/Library/Application Support/SwiftBar/claude_monitor.1s.sh"

# 手动运行 setup
claude-monitor-setup

# 重启 SwiftBar
claude-monitor restart
```

## 🎯 发布到 Homebrew Core（可选）

**要求**:

- 项目稳定运行至少 30 天
- GitHub stars 达到一定数量（通常 30+）
- 有活跃的维护和用户群
- 符合 Homebrew 质量标准

**流程**:

1. Fork https://github.com/Homebrew/homebrew-core
2. 将 Formula 添加到 `Formula/` 目录
3. 提交 Pull Request
4. 等待 Homebrew 维护者审核

**注意**: 建议先在自己的 Tap 运行几个月，积累用户反馈后再申请。

## 📚 相关资源

- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Creating and Maintaining a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
- [Acceptable Formulae](https://docs.brew.sh/Acceptable-Formulae)
- [Homebrew Formula API](https://rubydoc.brew.sh/Formula)

## 📋 版本发布检查清单

在每次发布前，请确认：

- [ ] 所有功能已测试并正常工作
- [ ] 更新 `VERSION` 文件
- [ ] 更新 `CHANGELOG.md`
- [ ] 更新 `Formula/claude-monitor.rb` 版本号和 URL
- [ ] 运行 `brew audit --strict Formula/claude-monitor.rb`
- [ ] 创建 Git tag
- [ ] 推送到 GitHub
- [ ] 创建 GitHub Release
- [ ] 计算并更新 SHA256
- [ ] 更新 homebrew-tap 仓库
- [ ] 本地测试安装
- [ ] 验证功能正常

## 🔄 回滚流程

如果发布后发现严重问题：

```bash
# 1. 从 homebrew-tap 回滚
cd homebrew-tap
git revert HEAD
git push

# 2. 标记 GitHub Release 为 pre-release 或删除

# 3. 发布修复版本（如 v0.2.1）
```

---

**提示**: 保持发布流程的一致性，使用脚本自动化重复步骤。
