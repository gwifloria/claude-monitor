# Homebrew 发布指南

本文档说明如何将 ClaudeCode Monitor 发布到 Homebrew。

## 📋 发布前准备清单

- [ ] 所有功能已测试并正常工作
- [ ] 更新 `VERSION` 文件到新版本号
- [ ] 更新 `README.md` 中的版本信息
- [ ] 更新 `Formula/claude-monitor.rb` 中的版本号
- [ ] 创建 Git tag

## 🚀 发布步骤

### 1. 更新版本号

```bash
# 编辑 VERSION 文件
echo "0.1.0" > VERSION

# 同步更新 Formula 中的版本号
# 编辑 Formula/claude-monitor.rb:
#   version "0.1.0"
#   url "https://github.com/yourname/claude-monitor/archive/refs/tags/v0.1.0.tar.gz"
```

### 2. 创建 Git Tag 和 GitHub Release

```bash
# 提交所有更改
git add .
git commit -m "Release v0.1.0"

# 创建 tag
git tag -a v0.1.0 -m "Release version 0.1.0"

# 推送到 GitHub
git push origin main
git push origin v0.1.0
```

### 3. 在 GitHub 创建 Release

1. 访问 GitHub 仓库页面
2. 点击 "Releases" → "Create a new release"
3. 选择刚才创建的 tag `v0.1.0`
4. 填写 Release 标题: "v0.1.0 - Initial Release"
5. 填写 Release 说明 (可以从下面的模板复制)
6. 点击 "Publish release"

**Release 说明模板:**

```markdown
## 🎉 ClaudeCode Monitor v0.1.0

Real-time ClaudeCode status in your macOS menu bar.

### ✨ Features

- 🔄 Real-time status tracking for multiple ClaudeCode projects
- ⚠️ Smart alerts for confirmation prompts (impossible to miss)
- ⠋ Beautiful 6-frame clockwise animation
- 🎯 Priority display across all sessions
- 📊 Multi-session management
- 🚀 Zero impact on ClaudeCode performance

### 📦 Installation

**Via Homebrew (recommended):**
\`\`\`bash
brew install yourname/tap/claude-monitor
claude-monitor-setup
claude-monitor start
\`\`\`

**Manual installation:**
\`\`\`bash
git clone https://github.com/yourname/claude-monitor.git
cd claude-monitor
./install.sh
\`\`\`

### 📚 Documentation

- [README](https://github.com/yourname/claude-monitor/blob/main/README.md)
- [中文文档](https://github.com/yourname/claude-monitor/blob/main/README.zh-CN.md)

### 🙏 Acknowledgments

Built for [ClaudeCode](https://claude.ai/code) by Anthropic.
```

### 4. 获取压缩包的 SHA256

GitHub 会自动生成源码压缩包，下载后计算 SHA256:

```bash
# 下载 GitHub 自动生成的 tar.gz
# URL 格式: https://github.com/yourname/claude-monitor/archive/refs/tags/v0.1.0.tar.gz
curl -L "https://github.com/yourname/claude-monitor/archive/refs/tags/v0.1.0.tar.gz" -o claude-monitor-0.1.0.tar.gz

# 计算 SHA256
shasum -a 256 claude-monitor-0.1.0.tar.gz

# 复制输出的哈希值,更新到 Formula/claude-monitor.rb 的 sha256 字段
```

### 5. 创建 Homebrew Tap 仓库

```bash
# 在 GitHub 创建新仓库: homebrew-tap
# 仓库必须以 "homebrew-" 开头

# 克隆仓库
git clone https://github.com/yourname/homebrew-tap.git
cd homebrew-tap

# 复制 Formula
cp ../claude-monitor/Formula/claude-monitor.rb .

# 更新 Formula 中的 sha256 (从步骤 4 获取)
# 编辑 claude-monitor.rb:
#   sha256 "实际的SHA256哈希值"

# 提交并推送
git add claude-monitor.rb
git commit -m "Add claude-monitor formula v0.1.0"
git push origin main
```

### 6. 本地测试安装

```bash
# 从本地 tap 安装测试
brew install --build-from-source yourname/tap/claude-monitor

# 验证安装
claude-monitor-setup
claude-monitor start
claude-monitor status

# 测试卸载
brew uninstall claude-monitor

# 清理测试环境
rm -rf ~/.claude-monitor
```

### 7. 更新项目 README

在主项目的 README.md 中添加 Homebrew 安装说明:

```markdown
## 📦 Installation

**Via Homebrew (recommended):**
\`\`\`bash
brew install yourname/tap/claude-monitor
claude-monitor-setup
claude-monitor start
\`\`\`

**Manual installation:**
\`\`\`bash
git clone https://github.com/yourname/claude-monitor.git
cd claude-monitor
./install.sh
\`\`\`
```

## 🧪 本地测试

在发布前，使用本地 Formula 测试:

```bash
# 测试 Formula 语法
brew audit --strict --online Formula/claude-monitor.rb

# 测试安装 (使用本地文件)
brew install --build-from-source Formula/claude-monitor.rb

# 测试功能
claude-monitor-setup
claude-monitor start
~/.claude/hooks/update_status.sh processing

# 检查菜单栏图标是否出现并显示正确状态

# 清理测试
brew uninstall claude-monitor
rm -rf ~/.claude-monitor
```

## 📝 版本更新流程

当需要发布新版本时:

1. 更新 `VERSION` 文件
2. 更新 `Formula/claude-monitor.rb` 中的 version 和 url
3. 提交更改并创建新 tag
4. 在 GitHub 创建新 Release
5. 计算新的 SHA256 并更新 Formula
6. 更新 homebrew-tap 仓库中的 Formula
7. 推送更改

## 🔧 常见问题

### Formula 安装失败

检查:
- URL 是否正确指向 GitHub Release
- SHA256 是否匹配压缩包
- 依赖项是否正确安装 (SwiftBar, jq)

### 测试命令失败

确保 status_manager.sh 有正确的使用说明输出:
```bash
./lib/status_manager.sh --help
# 应该输出使用说明
```

### 用户反馈安装问题

让用户运行:
```bash
brew doctor
brew update
brew reinstall claude-monitor
claude-monitor-setup
```

## 🎯 下一步

发布到 Homebrew Core (可选,需要更多用户验证):
1. 确保项目有足够的 stars 和使用者
2. 确保项目稳定运行 30 天以上
3. 提交 PR 到 https://github.com/Homebrew/homebrew-core

## 📚 相关资源

- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [How to Create and Maintain a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
- [Acceptable Formulae](https://docs.brew.sh/Acceptable-Formulae)
