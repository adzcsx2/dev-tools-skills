---
name: dt:push
description: "One-push release workflow: auto git add all changes, pull latest, logical-group commit, push to remote with optional tag."
argument-hint: "[version|--preview] e.g. /dt:push 1.2.2 or /dt:push --preview"
---

> **中文环境要求**
>
> 本技能运行在中文环境下，请遵循以下约定：
>
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
- 已经执行 `git add` / `git commit`，但本地提交尚未 push 到远程

## Example Prompts

- `/dt:push` - 自动暂存所有变更，按逻辑分组提交，推送到远程
- `/dt:push 1.2.2` - 更新文档版本号到 1.2.2，提交并打 tag
- `/dt:push --preview` - 预览分组方案与 commit messages，不执行任何 git 操作

---

## Command Parameters

| Parameter   | Description                                               |
| ----------- | --------------------------------------------------------- |
| No args     | 自动 git add 所有变更，按逻辑分组提交，推送到远程         |
| `X.Y.Z`     | 额外将文档中的版本号更新为指定版本，并创建 tag            |
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

# 3. 确认当前分支
git branch --show-current

# 4. 获取上游分支（如果存在）
git rev-parse --abbrev-ref --symbolic-full-name @{u}

# 5. 确认工作区状态（已暂存或未暂存）
git status --porcelain

# 6. 检查本地是否有未推送提交（仅在存在上游分支时执行）
git rev-list --count @{u}..HEAD
```

**检查结果处理**：

| 检查项                       | 处理方式                                                            |
| ---------------------------- | ------------------------------------------------------------------- |
| 非 git 仓库                  | 提示用户，退出                                                      |
| 无 remote origin             | 提示用户，退出                                                      |
| 无当前分支                   | 提示用户，退出                                                      |
| 无 upstream                  | 允许继续；Step 1 跳过 pull，Step 5 首次 push 时使用 `git push -u`   |
| 工作区有变更                 | 允许继续；后续会走 Step 4 自动分组提交                              |
| 工作区无变更但存在未推送提交 | 允许继续；跳过 Step 4，直接在同步远程后执行 Step 5 推送已有本地提交 |
| 工作区无变更且无未推送提交   | 若未提供版本号则退出；若提供版本号则继续执行 Step 3 生成版本提交    |

**关键原则**：

- `dt:push` 判断的是“是否存在待推送工作”，而不是仅判断“工作区是否脏”
- “待推送工作”包含三类：工作区变更、版本号参数触发的文档更新、已提交但尚未 push 的本地 commit

### Step 1: 拉取最新代码并处理冲突

在提交之前，先拉取远程最新代码，避免推送时冲突。

**执行流程**：

1. **检测当前分支名、远程名和上游分支**：
   ```bash
   BRANCH=$(git branch --show-current)
   REMOTE=$(git remote | head -1)
   UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)
   ```
2. **如果不存在 upstream** — 跳过本步骤中的 pull/rebase，直接进入 Step 2
3. **检查是否有未提交的变更** — 如果有，先 `git stash` 保存，拉取完成后 `git stash pop` 恢复
4. **执行拉取**：
   ```bash
   git pull --rebase $REMOTE $BRANCH
   ```
5. **如果 stash 了变更** → 执行 `git stash pop` 恢复工作区

**冲突处理策略**：

#### 无冲突

直接继续下一步。

#### 有冲突时：逐文件提示用户决策

只要出现冲突，**不要静默自动解决，也不要只给出“请手动处理后重试”**。必须对每个冲突文件逐个提示用户，由用户明确选择：

- 使用远程版本
- 使用本地版本
- 合并两个版本

**先收集冲突文件列表**：

```bash
git diff --name-only --diff-filter=U
```

**对每个冲突文件，在询问用户之前必须展示这些信息**：

1. 文件路径、冲突类型、受影响的冲突块数量
2. 本地版本（`ours`）相关代码片段
3. 远程版本（`theirs`）相关代码片段
4. 冲突摘要（仅展示相关片段，不要整文件刷屏）
5. AI 建议的处理方式，以及建议理由

**建议使用的 git 数据来源**：

```bash
git diff --merge -- <file>
git show :2:<file>   # 本地版本 / ours
git show :3:<file>   # 远程版本 / theirs
```

**建议生成规则**：

| 场景                                                               | 建议                                                           |
| ------------------------------------------------------------------ | -------------------------------------------------------------- |
| 远程只包含文档、锁文件、生成文件或格式化更新，本地包含真实功能变更 | 优先建议“合并”或“使用本地版本”，避免丢失功能代码               |
| 本地仅是格式化、注释、无语义微调，远程包含明确业务修复             | 优先建议“使用远程版本”                                         |
| 双方修改不同代码块，语义可兼容                                     | 优先建议“合并两个版本”                                         |
| 双方修改同一接口、同一条件分支、同一文案语义                       | 默认建议“合并两个版本”，不要直接猜测覆盖                       |
| 二进制文件或无法展示文本 diff                                      | 展示文件信息并说明风险，仍然让用户在“远程 / 本地 / 合并”中选择 |

**对每个文件的交互流程**：

1. 展示本地/远程代码片段、冲突摘要、建议和理由
2. 明确询问用户选择：`remote` / `local` / `merge`
3. 根据用户选择执行：

```bash
# 用户选择 remote
git checkout --theirs -- <file>
git add <file>

# 用户选择 local
git checkout --ours -- <file>
git add <file>
```

4. 如果用户选择 `merge`：
   - 基于本地版本与远程版本生成合并方案
   - 先向用户展示拟合并后的关键片段和处理理由
   - 用户确认后再写回文件并执行 `git add <file>`
5. 当前文件解决后，再处理下一个冲突文件
6. 所有冲突文件都解决并已暂存后，再执行：

```bash
git rebase --continue
```

7. 如果 `git rebase --continue` 后进入下一轮冲突，重复上述逐文件流程，直到 rebase 完成
8. 如果冲突发生在 `git stash pop`，也使用同样的逐文件流程；处理完成后再继续后续步骤

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

| 文件                       | 更新内容                      |
| -------------------------- | ----------------------------- |
| `README.md`                | 版本号相关描述                |
| `README_EN.md`             | 英文 README 中的版本号        |
| `docs/PROJECT_OVERVIEW.md` | 项目概览中的版本信息          |
| `docs/CHANGELOG.md`        | 在顶部插入新版本记录          |
| `docs/.doc-metadata.json`  | metadata 中的版本信息（如有） |
| 其他 `docs/*.md`           | 任何包含旧版本号的文档        |

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

### Step 4: Logical-Group Commit for Workspace Changes

自动暂存所有工作区变更，按**逻辑分组**提交，同一逻辑变更合并为 1 个 commit。

**跳过条件**：

- 如果 Step 0 已确认“工作区无变更但存在未推送提交”，则**跳过整个 Step 4**
- 这类场景不应提示“没有需要处理的内容”，而应保留现有本地 commit，直接进入 Step 5 推送

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

| 优先级 | 分组规则                                                                                            | 示例场景                                 |
| ------ | --------------------------------------------------------------------------------------------------- | ---------------------------------------- |
| P0     | **相同字符串替换**：多个文件的 diff 中出现相同的 `- old` / `+ new` 字符串对（剔除上下文行后仍重合） | 多文件统一替换 baseUrl 域名              |
| P1     | **同一符号重命名**：函数名、类名、常量名在多文件同步变动                                            | 函数重命名后波及的所有调用方文件         |
| P2     | **同一目录 / 功能模块**：路径前缀相同且 diff 语义相关（如同属一个 feature 分支的改动）              | `app/api/meeting/*` 内的多个文件一同修改 |
| P3     | **同主题批量新增**：在同一次操作中新增的一组文件（如新 skill 的 SKILL.md + README.md）              | 新增 skill 时一并提交两个新文件          |
| P4     | **独立变更**：不匹配任何上述规则的文件，回退为**单文件 commit**                                     | 彼此无关的零散修改                       |

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

| 变更类型      | type       | 示例                                    |
| ------------- | ---------- | --------------------------------------- |
| 新增功能/文件 | `feat`     | `feat: 新增会议模块 API 接口与对应文档` |
| Bug 修复      | `fix`      | `fix: 修复登录页面输入框焦点丢失问题`   |
| 重构          | `refactor` | `refactor: 重构网络请求拦截器结构`      |
| 文档          | `docs`     | `docs: 更新 API 接口说明文档`           |
| 配置/构建     | `chore`    | `chore: 更新依赖版本`                   |
| 样式/资源     | `style`    | `style: 更新登录页面布局样式`           |

**P0 字符串替换组**专属描述格式：`chore: 统一 <变更对象> 为 <新值>` 或 `refactor: 将 <旧值> 重命名为 <新值>`

**Commit message 要求**：

- 使用中文描述
- 根据分组整体变更内容自动判断 type
- 描述要概括整组变更的核心意图，而非列举每个文件
- 保持简洁，一行描述清楚即可
- **禁止**在 commit message 中追加 `Co-Authored-By` 行

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

如果前面没有产生新的工作区提交，但 Step 0 检测到本地分支领先 upstream，则此处直接推送已有本地 commit。

**推送代码**：

- **已有 upstream**：

  ```bash
  git push $REMOTE $BRANCH
  ```

- **无 upstream（首次推送当前分支）**：

  ```bash
  git push -u $REMOTE $BRANCH
  ```

**如果推送失败**（远程有新提交），执行重试：

```bash
git pull --rebase $REMOTE $BRANCH
```

- **如果 rebase 无冲突** → 直接 `git push origin HEAD`
- **如果 rebase 有冲突** → 严格复用 Step 1 的“逐文件提示用户决策”流程：先逐文件展示本地/远程代码和建议，再让用户为每个文件选择 `remote` / `local` / `merge`
- **所有冲突文件处理并 `git rebase --continue` 成功后** → 再次执行 `git push origin HEAD`

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

- 已有但尚未推送的本地 commit 被同步到远程
- 如工作区存在文件变更：生成 N 个新 commit（按逻辑分组，外加可选的版本号 commit）
- 可选：1 个新 tag（`X.Y.Z`）

## Notes

1. **所有 git 命令在用户当前工作目录执行**，不是 ~/.claude 或插件目录
2. 所有 commit message 使用中文
3. Step 4 按逻辑分组提交；变更文件 ≤ 3 个时整体合为 1 个 commit
4. 版本号仅更新文档中的记录，不修改项目构建文件
5. 如果某个文件的变更只有代码格式化，commit message 中标注为 `style`
6. push 失败时自动重试一次；若重试拉取出现冲突，必须逐文件展示本地/远程代码、给出建议，并让用户逐个选择 `remote` / `local` / `merge`
7. Tag 直接使用用户提供的版本号，不添加 `v` 前缀，例如 `1.2.2`
8. Step 3 在 Step 4 之前执行，Step 3 提交的文件不会在 Step 4 中重复提交
9. Step 1 提前拉取代码，大幅降低 Step 5 推送时的冲突概率
10. `/dt:push --preview` 仅预览分组方案与 commit messages，不执行任何 git 操作
11. 已 `git commit` 但未 `git push` 的场景属于正常路径；工作区干净时不能据此直接退出
