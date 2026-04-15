---
name: dt:push
description: "One-push release workflow: auto git add all changes, pull latest, per-file commit, generate docs, push to remote with optional tag."
argument-hint: "[version] e.g. /dt:push 1.2.2"
---

> **中文环境要求**
>
> 本技能运行在中文环境下，请遵循以下约定：
> - 面向用户的回复、注释、提示信息必须使用中文
> - AI 内部处理过程可以使用英文
> - 所有生成的文件必须使用 UTF-8 编码
>
> ---

# push Skill

一键发布工作流：自动暂存所有变更、拉取最新代码、逐文件提交、推送到远程仓库。

**重要：所有 git 命令均在用户当前工作目录执行。**

## When to Use

- 开发完成，准备将代码推送到远程仓库
- 发版时需要更新文档版本号并创建 tag
- 需要自动生成提交信息并逐文件提交
- 工作区有未暂存的变更，需要一键提交推送

## Example Prompts

- `/dt:push` - 自动暂存所有变更，逐文件提交，推送到远程
- `/dt:push 1.2.2` - 更新文档版本号到 1.2.2，提交并打 tag

---

## Command Parameters

| Parameter | Description |
|-----------|-------------|
| No args | 自动 git add 所有变更，逐文件提交，推送到远程 |
| `X.Y.Z` | 额外将文档中的版本号更新为指定版本，并创建 tag |

---

## Execution Flow

### Step 0: Pre-flight Checks

在执行任何操作之前，验证环境是否满足要求：

```bash
# 1. 确认在 git 仓库中
git rev-parse --is-inside-work-tree

# 2. 确认 remote origin 存在
git remote get-url origin

# 3. 确认工作区有变更（已暂存或未暂存）
git status --porcelain
```

**检查结果处理**：

| 检查项 | 失败时 |
|--------|--------|
| 非 git 仓库 | 提示用户，退出 |
| 无 remote origin | 提示用户，退出 |
| 工作区无任何变更 | 提示用户没有需要提交的更改，退出 |

### Step 1: 拉取最新代码并处理冲突

在提交之前，先拉取远程最新代码，避免推送时冲突。

**执行流程**：

1. **检测当前分支名和远程名**：
   ```bash
   BRANCH=$(git branch --show-current)
   REMOTE=$(git remote | head -1)
   ```
2. **检查是否有未提交的变更** — 如果有，先 `git stash` 保存，拉取完成后 `git stash pop` 恢复
3. **执行拉取**：
   ```bash
   git pull --rebase $REMOTE $BRANCH
   ```
4. **如果 stash 了变更** → 执行 `git stash pop` 恢复工作区

**冲突处理策略**：

#### 无冲突

直接继续下一步。

#### 简单冲突（自动解决）

以下情况自动解决，无需用户介入：

| 冲突类型 | 解决方式 |
|---------|---------|
| 一方删除、另一方未修改 | 接受删除 |
| 一方修改、另一方未修改 | 接受修改方的版本 |
| 一方新增文件、另一方无操作 | 保留新增文件 |
| 仅换行/空白符差异 | `git checkout --theirs` 保留远程版本 |

解决后执行：
```bash
git add <resolved files>
git rebase --continue
```

#### 复杂冲突（提示用户）

以下情况需要用户手动处理：

| 冲突类型 | 原因 |
|---------|------|
| 双方修改了同一文件的同一区域 | 无法自动判断应保留哪个版本 |
| 冲突涉及 3 个以上文件 | 影响范围大，需要人工判断 |
| 二进制文件冲突 | 无法合并内容 |

处理流程：
1. 暂停当前流程
2. 显示冲突详情（哪些文件、冲突内容摘要）
3. 提示用户手动解决冲突
4. 用户解决后，执行 `git add <resolved files>` + `git rebase --continue`
5. 重新执行 `/dt:push` 继续剩余流程

```bash
# 用户手动解决冲突后，执行：
git add <resolved files>
git rebase --continue

# 然后重新执行：
/dt:push
```

### Step 2: Parse Arguments

从 `args` 中提取版本号（可选）。

**如果提供了版本号**，校验格式是否为 semver (`X.Y.Z`)：
- 格式不合法 → 提示用户并退出
- 格式合法 → 进入 Step 3

**如果未提供版本号** → 跳过 Step 3，直接进入 Step 4

### Step 3: Update Version in Documents (Only when version is provided)

扫描项目中的文档文件，将版本号更新为指定版本。

**重要：此步骤在 Step 4 之前执行，此步骤提交的文件不会出现在 Step 4 的文件扫描中。**

**需要检查并更新的文件（按优先级）**：

| 文件 | 更新内容 |
|------|----------|
| `README.md` | 版本号相关描述 |
| `README_EN.md` | 英文 README 中的版本号 |
| `docs/PROJECT_OVERVIEW.md` | 项目概览中的版本信息 |
| `docs/CHANGELOG.md` | 在顶部插入新版本记录 |
| `docs/.doc-metadata.json` | metadata 中的版本信息（如有） |
| 其他 `docs/*.md` | 任何包含旧版本号的文档 |

**版本号检测策略**：

1. 从 `README.md` 或 `docs/PROJECT_OVERVIEW.md` 中查找当前版本号
2. 使用 Grep 搜索文档中的旧版本号，**使用锚定模式**避免误匹配：
   - 匹配 `版本 X.Y.Z`、`version X.Y.Z`、`vX.Y.Z`、`版本：X.Y.Z` 等带上下文的模式
   - **不要**匹配 `minSdkVersion`、`compileSdk`、依赖库版本号等非项目版本号
   - **不要**匹配 `build.gradle`、`build.gradle.kts`、`pubspec.yaml` 等构建配置文件中的依赖版本
3. 搜索范围限制在 `*.md` 和 `docs/` 目录下的文件

**替换后验证**：
- 替换完成后，用 `git diff` 检查所有变更
- 向用户展示变更摘要，确认无误后提交
- 如果发现误替换，手动修正后再提交

**提交版本号变更**：
```bash
git add <changed doc files>
git commit -m "chore: bump version to X.Y.Z"
```

### Step 4: Per-File Commit for All Changes

自动暂存所有工作区变更，然后逐文件提交。

**添加所有变更**：
```bash
git add .
```

**获取变更文件列表**（基于 HEAD）：
```bash
git diff HEAD --name-only
```

**对每个文件生成独立 commit**。

执行逻辑（伪代码，非直接运行的脚本）：

1. 读取变更文件列表，按文件路径排序
2. 对每个文件：
   a. `git reset HEAD -- <file>` 将文件从暂存区取出
   b. `git diff -- <file>` 分析该文件的具体变更内容（相对于工作区）
   c. 根据变更内容生成 commit message（中文）
   d. `git add <file>` 重新暂存该文件
   e. `git commit -m "<message>"` 提交
   f. **如果 commit 失败**（如 pre-commit hook 拒绝）→ 停止循环，保留当前状态，提示用户处理

**Commit message 生成规则**：

| 变更类型 | type | 示例 |
|----------|------|------|
| 新增功能/文件 | `feat` | `feat: 新增 UserViewModel 用户状态管理` |
| Bug 修复 | `fix` | `fix: 修复登录页面输入框焦点丢失问题` |
| 重构 | `refactor` | `refactor: 重构网络请求拦截器结构` |
| 文档 | `docs` | `docs: 更新 API 接口说明文档` |
| 配置/构建 | `chore` | `chore: 更新依赖版本` |
| 样式/资源 | `style` | `style: 更新登录页面布局样式` |

**Commit message 要求**：
- 使用中文描述
- 根据文件变更内容自动判断 type
- 描述要具体，包含文件中的关键变更点
- 保持简洁，一行描述清楚即可

### Step 5: Push to Remote

**推送代码**：
```bash
git push $REMOTE $BRANCH
```

**如果推送失败**（远程有新提交），执行重试：

```bash
git pull --rebase $REMOTE $BRANCH
```

- **如果 rebase 无冲突** → 直接 `git push origin HEAD`
- **如果有简单冲突** → 自动解决（参见 Step 1 的冲突处理策略）
- **如果有复杂冲突** → 停止，提示用户手动处理冲突，执行 `/dt:push` 重新推送

**创建 Tag（仅当提供了版本号时）**：

首先检查 tag 是否已存在：
```bash
git tag -l "X.Y.Z"
```

- **tag 不存在** → 创建并推送：
  ```bash
  git tag "X.Y.Z"
  git push origin "X.Y.Z"
  ```
- **tag 已存在** → 提示用户，询问是否删除重建或跳过

Tag 命名格式：直接使用用户提供的版本号，例如 `1.2.2`

---

## Expected Outcome

执行完成后，远程仓库应包含：
- N 个新 commit（每个文件一个 commit + 可选的版本号 commit）
- 可选：1 个新 tag（`X.Y.Z`）

## Notes

1. **所有 git 命令在用户当前工作目录执行**，不是 ~/.claude 或插件目录
2. 所有 commit message 使用中文
3. 逐文件提交时，按文件路径的字母顺序依次提交
4. 版本号仅更新文档中的记录，不修改项目构建文件
5. 如果某个文件的变更只有代码格式化，commit message 中标注为 `style`
6. push 失败时自动重试一次，冲突无法解决时交给用户
7. Tag 直接使用用户提供的版本号，不添加 `v` 前缀，例如 `1.2.2`
8. Step 3 在 Step 4 之前执行，Step 3 提交的文件不会在 Step 4 中重复提交
9. Step 1 提前拉取代码，大幅降低 Step 5 推送时的冲突概率
