# Homebrew 发布快速指南

本文档提供 ClaudeCode Monitor 发布到 Homebrew 的快速步骤概览。

## 🎯 目标

让用户可以通过以下简单命令安装：

```bash
brew install yourname/tap/claude-monitor
claude-monitor-setup
claude-monitor start
```

## ⚡ 快速步骤

### 1️⃣ 更新版本号（2 分钟）

```bash
# 更新 VERSION 文件
echo "0.1.0" > VERSION

# 更新 Formula 中的版本
# 编辑 Formula/claude-monitor.rb 第 6 行:
version "0.1.0"
```

### 2️⃣ 本地测试（5 分钟）

```bash
# 运行测试脚本
./test-formula.sh

# 如果测试通过，继续下一步
# 如果失败，修复问题后重新测试
```

### 3️⃣ 创建 GitHub Release（10 分钟）

```bash
# 提交所有更改
git add .
git commit -m "Release v0.1.0"

# 创建并推送 tag
git tag -a v0.1.0 -m "Release version 0.1.0"
git push origin main
git push origin v0.1.0
```

然后在 GitHub 网页上：

1. 进入仓库页面 → Releases → Create a new release
2. 选择 tag: `v0.1.0`
3. 标题: `v0.1.0 - Initial Release`
4. 内容复制 `.github/RELEASE_TEMPLATE.md`（替换 {VERSION} 为 0.1.0）
5. 点击 "Publish release"

### 4️⃣ 获取并更新 SHA256（5 分钟）

```bash
# 下载 GitHub Release 压缩包
curl -L "https://github.com/yourname/claude-monitor/archive/refs/tags/v0.1.0.tar.gz" -o claude-monitor-0.1.0.tar.gz

# 计算 SHA256
shasum -a 256 claude-monitor-0.1.0.tar.gz

# 复制输出结果，更新 Formula/claude-monitor.rb 第 5 行:
sha256 "实际的哈希值"
```

### 5️⃣ 创建 Homebrew Tap（一次性，15 分钟）

```bash
# 在 GitHub 创建新仓库: homebrew-tap
# ⚠️ 仓库名必须是 "homebrew-tap"

# 克隆仓库
git clone https://github.com/yourname/homebrew-tap.git
cd homebrew-tap

# 复制 Formula（已更新 SHA256 的版本）
cp ../claude-monitor/Formula/claude-monitor.rb .

# 提交并推送
git add claude-monitor.rb
git commit -m "Add claude-monitor formula v0.1.0"
git push origin main
```

### 6️⃣ 测试 Homebrew 安装（5 分钟）

```bash
# 添加你的 tap
brew tap yourname/tap

# 安装
brew install claude-monitor

# 验证
claude-monitor-setup
claude-monitor start

# 检查菜单栏是否出现图标
```

## ✅ 完成！

现在任何人都可以通过以下命令安装：

```bash
brew install yourname/tap/claude-monitor
```

---

## 📝 后续版本更新流程

发布新版本 (如 v0.2.0) 时：

```bash
# 1. 更新版本号
echo "0.2.0" > VERSION
# 编辑 Formula/claude-monitor.rb 更新 version 和 url

# 2. 提交并创建 tag
git commit -am "Release v0.2.0"
git tag -a v0.2.0 -m "Release version 0.2.0"
git push origin main && git push origin v0.2.0

# 3. 在 GitHub 创建 Release

# 4. 更新 SHA256
curl -L "https://github.com/yourname/claude-monitor/archive/refs/tags/v0.2.0.tar.gz" | shasum -a 256

# 5. 更新 homebrew-tap
cd ../homebrew-tap
cp ../claude-monitor/Formula/claude-monitor.rb .
git commit -am "Update claude-monitor to v0.2.0"
git push

# 6. 用户更新
brew upgrade claude-monitor
```

---

## 🆘 常见问题

### Q: Formula 安装测试失败？

```bash
# 检查语法
brew audit --strict Formula/claude-monitor.rb

# 检查样式
brew style Formula/claude-monitor.rb

# 自动修复样式
brew style --fix Formula/claude-monitor.rb
```

### Q: SHA256 不匹配？

确保下载的压缩包 URL 和 Formula 中的 URL 完全一致。GitHub 对同一个 tag 生成的压缩包 SHA256 是固定的。

### Q: 用户报告安装失败？

让用户运行：

```bash
brew doctor
brew update
brew reinstall yourname/tap/claude-monitor
```

### Q: 如何发布到 Homebrew Core？

Homebrew Core 有严格要求：

- 项目需要有一定知名度（通常要求 30+ GitHub stars）
- 需要稳定运行至少 30 天
- 提交 PR 到 https://github.com/Homebrew/homebrew-core

建议先在自己的 tap 中运行几个月，积累用户反馈后再考虑。

---

## 📚 详细文档

- 完整发布流程: [HOMEBREW_RELEASE.md](HOMEBREW_RELEASE.md)
- 测试脚本: [test-formula.sh](test-formula.sh)
- Formula 文件: [Formula/claude-monitor.rb](Formula/claude-monitor.rb)
- Release 模板: [.github/RELEASE_TEMPLATE.md](.github/RELEASE_TEMPLATE.md)

---

## ⏱️ 预计时间

- **首次发布**: 约 45 分钟

  - 本地测试: 5 分钟
  - 创建 Release: 10 分钟
  - 配置 SHA256: 5 分钟
  - 创建 Homebrew Tap: 15 分钟
  - 验证安装: 10 分钟

- **后续版本**: 约 15 分钟
  - 已有 tap，只需更新 Formula

---

**提示**: 将 `yourname` 替换为你的 GitHub 用户名！
