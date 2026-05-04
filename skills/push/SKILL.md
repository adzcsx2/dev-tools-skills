---
name: dt:push
description: "One-push release workflow: auto git add all changes, pull latest, logical-group commit, push to remote with optional tag."
argument-hint: "[version|--preview] e.g. /dt:push 1.2.2 or /dt:push --preview"
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

一键发布工作流：自动暂存所有变更、拉取最新代码、按逻辑分组提交、推送到远程仓库。

**重要：所有 git 命令均在用户当前工作目录执行。**

## When to Use

- 开发完成，准备将代码推送到远程仓库
- 发版时需要更新文档版本号并创建 tag
- 需要自动生成提交信息并按逻辑分组提交
- 工作区有未暂存的变更，需要一键提交推送

## Example Prompts

- `/dt:push` - 自动暂存所有变更，按逻辑分组提交，推送到远程
- `/dt:push 1.2.2` - 更新文档版本号到 1.2.2，提交并打 tag
- `/dt:push --preview` - 预览分组方案与 commit messages，不执行任何 git 操作

---

## Command Parameters

| Parameter | Description |
|-----------|-------------|
| No args | 自动 git add 所有变更，按逻辑分组提交，推送到远程 |
| `X.Y.Z` | 额外将文档中的版本号更新为指定版本，并创建 tag |
| `--preview` | 仅预览逻辑分组方案与 commit messages，不执行任何 git 操作 |

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

### Step 4: Logical-Group Commit for All Changes

自动暂存所有工作区变更，按**逻辑分组**提交，同一逻辑变更合并为 1 个 commit。

**添加所有变更**：
```bash
git add .
```

**获取变更文件列表**（基于 HEAD）：
```bash
git diff HEAD --name-only
```

#### 4.1 逻辑分组策略

先完整读取所有文件的 diff，再按以下规则（优先级从高到低）归并到分组：

| 优先级 | 分组规则 | 示例场景 |
|-------|---------|---------|
| P0 | **相同字符串替换**：多个文件的 diff 中出现相同的 `- old` / `+ new` 字符串对（剔除上下文行后仍重合） | 多文件统一替换 baseUrl 域名 |
| P1 | **同一符号重命名**：函数名、类名、常量名在多文件同步变动 | 函数重命名后波及的所有调用方文件 |
| P2 | **同一目录 / 功能模块**：路径前缀相同且 diff 语义相关（如同属一个 feature 分支的改动） | `app/api/meeting/*` 内的多个文件一同修改 |
| P3 | **同主题批量新增**：在同一次操作中新增的一组文件（如新 skill 的 SKILL.md + README.md） | 新增 skill 时一并提交两个新文件 |
| P4 | **独立变更**：不匹配任何上述规则的文件，回退为**单文件 commit** | 彼此无关的零散修改 |

**分组执行逻辑**（伪代码）：

```
1. 读取所有变更文件及其 diff
2. 字符串替换检测（P0）：
   a. 提取每个文件中所有 "-旧 / +新" 行对
   b. 对 (旧, 新) 做哈希分组
   c. 出现在 ≥ 2 个文件中的 (旧, 新) 对 → 这些文件归为同一 P0 分组
3. 符号重命名检测（P1）：
   a. 对剩余文件检测标识符（函数名/类名）的统一替换
   b. 在 ≥ 2 个文件中出现同一标识符变化 → 归为 P1 分组
4. 目录聚类（P2）：
   a. 对剩余文件按目录前缀聚合
   b. 同目录下 ≥ 2 个文件有关联 diff → 归为 P2 分组
5. 同主题新增（P3）：
   a. 剩余新增文件中，位于同一目录或明显成套的（如 SKILL.md + README.md）→ 归为 P3 分组
6. 其余文件 → 各自独立 P4 单文件 commit
```

#### 4.2 小批量快速路径

**变更文件总数 ≤ 3 个**：跳过分组分析，直接将全部文件合并为 **1 个 commit**，避免过度切分。

#### 4.3 分组提交执行

对每个分组（含单文件 P4）依次执行：

```bash
git reset HEAD                  # 清空暂存区
git add <该分组所有文件>
git commit -m "<分组 commit message>"
```

**如果 commit 失败**（如 pre-commit hook 拒绝）→ 停止，保留当前状态，提示用户处理后手动重新执行。

#### 4.4 Commit message 生成规则

分组 commit message 基于**该分组所有文件的聚合 diff** 生成，而非单文件 diff：

| 变更类型 | type | 示例 |
|----------|------|------|
| 新增功能/文件 | `feat` | `feat: 新增会议模块 API 接口与对应文档` |
| Bug 修复 | `fix` | `fix: 修复登录页面输入框焦点丢失问题` |
| 重构 | `refactor` | `refactor: 重构网络请求拦截器结构` |
| 文档 | `docs` | `docs: 更新 API 接口说明文档` |
| 配置/构建 | `chore` | `chore: 更新依赖版本` |
| 样式/资源 | `style` | `style: 更新登录页面布局样式` |

**P0 字符串替换组**专属描述格式：`chore: 统一 <变更对象> 为 <新值>` 或 `refactor: 将 <旧值> 重命名为 <新值>`

**Commit message 要求**：
- 使用中文描述
- 根据分组整体变更内容自动判断 type
- 描述要概括整组变更的核心意图，而非列举每个文件
- 保持简洁，一行描述清楚即可

#### 4.5 Dry-run 模式（预览）

执行 `/dt:push --preview` 时，Step 4 仅展示分组结果与生成的 commit messages，**不执行任何 git 操作**：

```
[preview] 检测到 N 个逻辑分组：

分组 1（P0 字符串替换，3 个文件）
  文件：app/api/meeting.py, docs/api.md, scripts/sync_swagger.sh
  将提交：chore: 统一测试环境域名地址为 new.example.com

分组 2（P3 同主题新增，2 个文件）
  文件：skills/push/SKILL.md, skills/push/README.md
  将提交：feat: 新增 push skill 文档

分组 3（P4 独立，1 个文件）
  文件：README.md
  将提交：docs: 更新项目简介

输入 yes 确认执行，或输入 no 退出。
```

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
3. Step 4 按逻辑分组提交；变更文件 ≤ 3 个时整体合为 1 个 commit
4. 版本号仅更新文档中的记录，不修改项目构建文件
5. 如果某个文件的变更只有代码格式化，commit message 中标注为 `style`
6. push 失败时自动重试一次，冲突无法解决时交给用户
7. Tag 直接使用用户提供的版本号，不添加 `v` 前缀，例如 `1.2.2`
8. Step 3 在 Step 4 之前执行，Step 3 提交的文件不会在 Step 4 中重复提交
9. Step 1 提前拉取代码，大幅降低 Step 5 推送时的冲突概率
10. `/dt:push --preview` 仅预览分组方案与 commit messages，不执行任何 git 操作
