# ✅ Homebrew 发布准备完成

ClaudeCode Monitor 已经完成 Homebrew 发布的所有准备工作！

---

## 📦 新增文件一览

### 核心文件
- ✅ `VERSION` - 版本号管理（当前: 0.1.0）
- ✅ `Formula/claude-monitor.rb` - Homebrew Formula 定义

### 文档
- ✅ `HOMEBREW_RELEASE.md` - 完整发布指南（详细步骤）
- ✅ `QUICK_START_HOMEBREW.md` - 快速开始指南（45分钟完成首次发布）
- ✅ `CHANGELOG.md` - 版本变更日志
- ✅ `.github/RELEASE_TEMPLATE.md` - GitHub Release 模板

### 工具脚本
- ✅ `test-formula.sh` - 本地测试脚本（验证 Formula 正确性）

### 更新的文件
- ✅ `README.md` - 添加 Homebrew 安装说明（英文）
- ✅ `README.zh-CN.md` - 添加 Homebrew 安装说明（中文）

---

## 🚀 发布流程总览

### 准备阶段（已完成 ✅）
- [x] 创建 Homebrew Formula
- [x] 编写测试脚本
- [x] 准备文档
- [x] 更新 README

### 发布阶段（待执行 ⏳）

#### 步骤 1: 本地测试（5分钟）
```bash
./test-formula.sh
```

#### 步骤 2: 创建 GitHub Release（10分钟）
```bash
git add .
git commit -m "Release v0.1.0"
git tag -a v0.1.0 -m "Release version 0.1.0"
git push origin main
git push origin v0.1.0
```

然后在 GitHub 网页创建 Release（使用 `.github/RELEASE_TEMPLATE.md` 模板）

#### 步骤 3: 更新 SHA256（5分钟）
```bash
curl -L "https://github.com/yourname/claude-monitor/archive/refs/tags/v0.1.0.tar.gz" -o claude-monitor-0.1.0.tar.gz
shasum -a 256 claude-monitor-0.1.0.tar.gz
# 复制输出，更新 Formula/claude-monitor.rb 的 sha256 字段
```

#### 步骤 4: 创建 Homebrew Tap（一次性，15分钟）
```bash
# 在 GitHub 创建仓库: homebrew-tap
git clone https://github.com/yourname/homebrew-tap.git
cd homebrew-tap
cp ../claude-monitor/Formula/claude-monitor.rb .
git add claude-monitor.rb
git commit -m "Add claude-monitor formula v0.1.0"
git push origin main
```

#### 步骤 5: 测试安装（5分钟）
```bash
brew tap yourname/tap
brew install claude-monitor
claude-monitor-setup
claude-monitor start
```

---

## 📋 发布前检查清单

在执行发布前，请确认：

- [ ] 所有功能已测试并正常工作
- [ ] `VERSION` 文件设置为 `0.1.0`
- [ ] `Formula/claude-monitor.rb` 版本号正确
- [ ] 替换所有 `yourname` 为你的 GitHub 用户名
- [ ] 替换所有 `<repository-url>` 为实际的仓库 URL
- [ ] 运行 `./test-formula.sh` 通过所有测试
- [ ] README 中的 Homebrew 安装命令正确

---

## 🔄 需要替换的占位符

在发布前，请全局搜索并替换以下占位符：

1. **yourname** → 你的 GitHub 用户名
   - 出现位置: README.md, README.zh-CN.md, Formula/*.rb, HOMEBREW_RELEASE.md

2. **<repository-url>** → 实际的 GitHub 仓库 URL
   - 出现位置: README.md, README.zh-CN.md

### 快速替换命令

```bash
# 替换 GitHub 用户名（将 YOUR_GITHUB_USERNAME 改为你的用户名）
export GITHUB_USER="YOUR_GITHUB_USERNAME"

# 批量替换
find . -type f \( -name "*.md" -o -name "*.rb" \) -not -path "./.git/*" -exec sed -i '' "s/yourname/$GITHUB_USER/g" {} +

# 验证替换
grep -r "yourname" . --include="*.md" --include="*.rb" --exclude-dir=.git
```

---

## 🎯 用户使用体验

发布后，用户的安装体验将是：

### 当前方式（手动安装）
```bash
git clone https://github.com/yourname/claude-monitor.git
cd claude-monitor
./install.sh
# 多个交互式提示...
```

### 新方式（Homebrew）
```bash
brew install yourname/tap/claude-monitor
claude-monitor-setup
claude-monitor start
```

**改进点:**
- ✅ 从 3 行 + 交互 → 3 行命令
- ✅ 自动处理依赖
- ✅ 标准化的 macOS 安装方式
- ✅ 易于更新: `brew upgrade claude-monitor`
- ✅ 易于卸载: `brew uninstall claude-monitor`

---

## 📊 预计影响

### 降低安装门槛
- **技术门槛**: 🔴🔴🔴 → 🟢 （需要懂 Git → 只需要 Homebrew）
- **时间成本**: 5-10 分钟 → 2 分钟
- **错误风险**: 中 → 低（Homebrew 处理依赖）

### 提升专业度
- ✅ 符合 macOS 开发者习惯
- ✅ 易于分享: `brew install yourname/tap/claude-monitor`
- ✅ 自动更新支持

### 扩大用户群
- 开发者更愿意尝试有 Homebrew 支持的工具
- 降低非技术用户的使用门槛
- 更容易在社区推广

---

## 🧪 测试清单

发布前务必测试：

```bash
# 1. Formula 语法检查
brew audit --strict Formula/claude-monitor.rb

# 2. Formula 样式检查
brew style Formula/claude-monitor.rb

# 3. 本地安装测试
./test-formula.sh

# 4. 功能测试
claude-monitor-setup
claude-monitor start
~/.claude/hooks/update_status.sh processing
# 检查菜单栏是否显示动画

# 5. 卸载测试
brew uninstall claude-monitor
# 验证清理干净
```

---

## 📚 后续优化建议

### 短期（1-2 周内）
- [ ] 收集用户反馈
- [ ] 修复安装过程中的问题
- [ ] 改进错误提示

### 中期（1-2 个月）
- [ ] 添加 Homebrew 服务支持 (`brew services start claude-monitor`)
- [ ] 优化 SwiftBar 自动启动逻辑
- [ ] 添加配置文件模板

### 长期（3-6 个月）
- [ ] 积累 GitHub stars（目标 30+）
- [ ] 稳定运行，收集用户数据
- [ ] 考虑提交到 Homebrew Core

---

## 🆘 支持资源

### 官方文档
- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [How to Create a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
- [Acceptable Formulae](https://docs.brew.sh/Acceptable-Formulae)

### 项目文档
- 快速开始: `QUICK_START_HOMEBREW.md`（45分钟完成发布）
- 详细指南: `HOMEBREW_RELEASE.md`（完整步骤）
- 测试脚本: `./test-formula.sh`

### 常见问题
参见 `HOMEBREW_RELEASE.md` 的 "🔧 常见问题" 章节

---

## 🎉 总结

你的项目现在已经完全准备好发布到 Homebrew！

**下一步操作:**
1. 阅读 `QUICK_START_HOMEBREW.md`（推荐，快速上手）
2. 或阅读 `HOMEBREW_RELEASE.md`（完整详细版）
3. 替换所有 `yourname` 占位符
4. 运行 `./test-formula.sh` 验证
5. 按照指南创建 GitHub Release
6. 创建 Homebrew Tap 仓库
7. 发布！

**预计首次发布时间**: 45 分钟
**后续版本更新时间**: 15 分钟

---

**祝发布顺利！** 🚀

如有问题，参考项目文档或在 GitHub Issues 提问。
