# Homebrew 维护指南

本文档为 ClaudeCode Monitor 的维护者提供 Homebrew 发布和更新的完整流程。

## 📋 发布新版本（完整流程）

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
