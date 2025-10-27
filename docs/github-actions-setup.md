# GitHub Actions 自动化配置指南

本指南帮助你配置 GitHub Actions，实现 Homebrew formula 的自动更新。

## 快速设置（5 分钟）

### 步骤 1: 创建 Personal Access Token

1. 访问 https://github.com/settings/tokens/new
2. 填写以下信息：
   - **Note**: `HOMEBREW_TAP_TOKEN`
   - **Expiration**: 选择 **No expiration** 或 **1 year**
   - **Select scopes**:
     - ✅ `repo` (勾选父选项，所有子选项自动勾选)
     - ✅ `workflow`

3. 点击 **Generate token**
4. **重要**: 立即复制生成的 token（格式：`ghp_xxxxxxxxxxxx`）
   - ⚠️ Token 只显示一次，离开页面后无法再查看

### 步骤 2: 添加 Secret 到仓库

1. 访问主仓库的 Settings → Secrets and variables → Actions
   - 直达链接：https://github.com/gwifloria/claude-monitor/settings/secrets/actions

2. 点击 **New repository secret**

3. 填写信息：
   - **Name**: `HOMEBREW_TAP_TOKEN`（必须完全匹配此名称）
   - **Secret**: 粘贴步骤 1 复制的 token

4. 点击 **Add secret**

### 步骤 3: 验证配置

创建一个测试 release 来验证自动化是否工作：

```bash
# 创建测试 tag
git tag -a v0.2.2-test -m "Test automation"
git push origin v0.2.2-test

# 在 GitHub 上创建 release
# 1. 访问 https://github.com/gwifloria/claude-monitor/releases/new
# 2. 选择 tag: v0.2.2-test
# 3. 标题: Test Automation
# 4. 勾选 "Set as a pre-release"
# 5. 点击 "Publish release"

# 观察 GitHub Actions
# 访问 https://github.com/gwifloria/claude-monitor/actions
# 应该看到 "Update Homebrew Formula" workflow 开始运行
```

**如果 workflow 成功**:
- ✅ homebrew-tap 仓库会出现新的 commit
- ✅ 可以删除测试 release 和 tag

**如果 workflow 失败**:
- 点击失败的 workflow 查看错误日志
- 常见问题参见下方故障排除

---

## 工作流程详解

### 触发条件

Workflow 在以下情况下自动触发：
- 在 GitHub 上发布新的 Release（非 Draft）
- 触发时机：点击 "Publish release" 按钮后立即执行

### 自动化步骤

1. **下载 tarball**: 从 GitHub Release 下载源码压缩包
2. **计算 SHA256**: 对压缩包计算 checksum
3. **更新 formula**: 在 homebrew-tap 仓库中更新 `claude-monitor.rb`
4. **提交推送**: 自动 commit 并 push 到 homebrew-tap

### 涉及的文件

**主仓库** (`gwifloria/claude-monitor`):
- `.github/workflows/update-homebrew.yml` - GitHub Actions workflow 配置
- `Formula/claude-monitor.rb` - Formula 模板（SHA256 可留空）

**Homebrew tap** (`gwifloria/homebrew-tap`):
- `claude-monitor.rb` - 实际使用的 formula（自动更新）

---

## 故障排除

### 问题 1: Workflow 失败 - 403 Forbidden

**错误信息**:
```
Error: Resource not accessible by integration
```

**原因**: Token 权限不足

**解决方案**:
1. 检查 token 是否包含 `repo` 和 `workflow` 权限
2. 如果不确定，重新创建 token（参考步骤 1）
3. 更新仓库 secret（参考步骤 2）

### 问题 2: Workflow 未触发

**症状**: 发布 release 后，Actions 页面没有新的 workflow 运行

**可能原因**:
- Release 被标记为 Draft（草稿）
- Workflow 文件有语法错误

**解决方案**:
```bash
# 1. 检查 workflow 文件语法
cat .github/workflows/update-homebrew.yml

# 2. 确保 release 不是 Draft 状态
# 访问 https://github.com/gwifloria/claude-monitor/releases
# Draft releases 不会触发 workflow

# 3. 手动触发（需要 workflow_dispatch 配置）
# 或删除 release 重新发布
```

### 问题 3: SHA256 计算错误

**错误信息**:
```
Error: Failed to download archive
```

**原因**: GitHub Release 的 tarball 不存在或无法访问

**解决方案**:
1. 检查 tag 是否正确推送到 GitHub
2. 访问 `https://github.com/gwifloria/claude-monitor/archive/refs/tags/v0.3.0.tar.gz` 测试下载
3. 等待 2-3 分钟后重试（GitHub 生成 tarball 需要时间）

### 问题 4: homebrew-tap 未更新

**症状**: Workflow 显示成功，但 homebrew-tap 没有新 commit

**检查步骤**:
1. 访问 https://github.com/gwifloria/homebrew-tap/commits/main
2. 查看最新 commit 的时间和内容
3. 检查 workflow 日志中是否有推送成功的消息

**可能原因**:
- Token 只有 read 权限，没有 write 权限
- homebrew-tap 仓库受保护（分支保护规则）

**解决方案**:
```bash
# 验证 token 权限
# 使用 token 手动推送测试：
cd /tmp
git clone https://github.com/gwifloria/homebrew-tap.git
cd homebrew-tap
echo "# test" >> README.md
git add README.md
git commit -m "Test push with token"
git push https://YOUR_TOKEN@github.com/gwifloria/homebrew-tap.git

# 如果推送失败，说明 token 权限不足，需要重新创建
```

---

## 安全最佳实践

### Token 管理

**✅ 推荐做法**:
- 为每个用途创建单独的 token
- 定期轮换 token（每 6-12 个月）
- 设置过期时间
- 记录 token 用途和创建日期

**❌ 避免**:
- 在代码中硬编码 token
- 在公开场合分享 token
- 使用过于宽泛的权限
- 与他人共享 Personal Access Token

### 权限最小化

本 workflow 只需要以下权限：

| 权限 | 用途 | 必需 |
|------|------|------|
| `repo` | 读取主仓库、写入 homebrew-tap | ✅ |
| `workflow` | 更新 workflow 文件（如需要） | ✅ |

**不需要的权限**:
- ❌ `admin:org`
- ❌ `delete_repo`
- ❌ `user:email`

### 审计日志

定期检查 GitHub Actions 的执行记录：

```bash
# 访问 Actions 历史
# https://github.com/gwifloria/claude-monitor/actions

# 检查异常活动：
# - 未知的 workflow 运行
# - 频繁的失败
# - 不寻常的时间执行
```

---

## 迁移到自动化

如果你之前使用手动流程，迁移步骤如下：

### 1. 备份当前 homebrew-tap

```bash
cd ~/projects
git clone https://github.com/gwifloria/homebrew-tap.git homebrew-tap-backup
```

### 2. 配置 GitHub Actions

按照上方"快速设置"完成配置

### 3. 测试自动化

```bash
# 使用 pre-release 测试
git tag -a v0.2.2-auto-test -m "Test automation"
git push origin v0.2.2-auto-test

# 创建 pre-release
# 检查 homebrew-tap 是否正确更新
```

### 4. 清理旧流程

自动化生效后，可以删除：
- ✅ 本地 homebrew-tap 仓库 clone（不再需要）
- ✅ 手动更新的脚本（如果有）
- ✅ 文档中的手动步骤提醒

---

## FAQ

**Q: Token 过期后怎么办？**

A: 创建新 token，更新仓库 secret，无需修改 workflow 配置。

**Q: 可以用于其他项目吗？**

A: 可以！只需修改 workflow 中的 `formula-name` 和 `homebrew-tap` 参数。

**Q: 支持私有仓库吗？**

A: 支持，但需要确保 token 对两个仓库都有访问权限。

**Q: 可以自动创建 release 吗？**

A: workflow 只负责更新 formula，release 仍需手动创建（或使用其他 workflow）。

**Q: 如何回滚错误的更新？**

A: 访问 homebrew-tap 仓库，使用 `git revert` 回滚自动提交即可。

---

## 参考资源

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [mislav/bump-homebrew-formula-action](https://github.com/mislav/bump-homebrew-formula-action)
- [Creating Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)

---

**提示**: 配置完成后，将本文档链接加入书签，方便后续维护时查阅。
