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

## 硬约束：不创建新分支

本 skill 全程在**用户当前分支**上操作，任何情况下都 **禁止**：

- 创建新分支（`git branch <new>` / `git checkout -b` / `git switch -c`）
- 切换到其他已有分支
- 创建 worktree
- 以"备份"、"规避冲突"、"rebase 失败救援"等任何名义生成新分支

唯一例外：远程尚未存在当前分支时，`git push -u` 会在远程创建同名分支 —— 这是当前分支的首次推送，不属于"新建分支"。

如果冲突 / rebase / push 无法继续推进，**必须停下**并向用户报告当前状态（`git status` 输出 + 建议的下一步），让用户人工决策，**不得**自动创建新分支来绕过。

## 硬约束：本地 commit 整理只动未推送提交

Step 4.5 会把多个本地 commit 整理（squash）成 1 个干净 commit。该能力受以下硬约束限制：

- **只允许操作 `@{u}..HEAD` 范围内、尚未推送到远程的本地 commit**
- **绝对禁止**对已推送到远程的 commit 执行 reset / rebase / amend / force-push 等任何改写历史的操作
- 整理时**禁止**触碰位于 upstream 之内（已推送）的任何提交
- 整理前后都不创建新分支、不切换分支、不创建 worktree
- 整理失败或无法安全判定边界时，**保留原始 commit 历史不动**，进入 Step 5 原样推送；若 reset 后回退仍无法恢复干净状态，则停止整个 push 流程并报告

## When to Use

- 开发完成，准备将代码推送到远程仓库
- 发版时需要更新文档版本号并创建 tag
- 需要自动生成提交信息并按逻辑分组提交
- 工作区有未暂存的变更，需要一键提交推送
- 已经执行 `git add` / `git commit`，但本地提交尚未 push 到远程
- 本地堆积了多个未推送的零散 commit（且都是自己提交、中途无他人提交），希望压成 1 个干净 commit 后再推送

## Example Prompts

- `/dt:push` - 自动暂存所有变更，按逻辑分组提交，推送到远程
- `/dt:push 1.2.2` - 更新文档版本号到 1.2.2，提交并打 tag
- `/dt:push --preview` - 预览分组方案与 commit messages，不执行任何写入性 git 操作

---

## Command Parameters

| Parameter   | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| No args     | 自动 git add 所有变更，按逻辑分组提交，推送到远程               |
| `X.Y.Z`     | 额外将文档中的版本号更新为指定版本，并创建 tag                  |
| `--preview` | 仅预览逻辑分组方案与 commit messages，不执行任何写入性 git 操作 |

---

## References（按需读取，不要凭主文件骨架执行细则）

主 SKILL.md 只保留可线性执行的步骤骨架。以下三个步骤的**完整强制规则**已拆到 `references/`，执行到对应步骤时**必须先打开并完整执行**对应文件，避免"执行到一半忘记前面的约束"：

| 触发步骤                 | 必读 reference                      | 内容                                                                                                          |
| ------------------------ | ----------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| Step 1 / Step 5 出现冲突 | `references/conflict-resolution.md` | 冲突分级分流（轻冲突自动 merge / 重冲突逐文件三选一）完整流程 Step A–E                                        |
| Step 4 工作区分组提交    | `references/commit-grouping.md`     | P0–P4 分组算法、TDD 功能包、主题纯度校验、commit message 规则、preview 格式                                   |
| Step 4.5 本地提交整理    | `references/local-squash.md`        | 破坏性安全说明、第 0–6 步（前置守卫 / 校验 / 聚合提交 / soft reset 重建单个 commit / 一致性 gate / 失败回退） |

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

# 7. 列出本地未推送提交及其作者（用于 Step 4.5 判断是否可整理）
git log @{u}..HEAD --pretty=format:'%h|%an|%ae|%s'

# 8. 获取当前用户的提交身份
git config user.name
git config user.email
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
| 分离 HEAD / 非预期分支状态   | **停止**并提示用户，不自动创建或切换分支                            |

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

- 先判断 `git pull --rebase` 是否真的产生冲突（检查退出码 + `git diff --name-only --diff-filter=U` 是否有输出）
- **无冲突** → 静默继续下一步，**不要**向用户显示任何冲突相关提示或确认
- **有冲突** → 按 `references/conflict-resolution.md` 的"先分级、再分流"流程处理：轻冲突（双方改不同行）自动 merge 不提醒；重冲突（双方改同一行）才逐文件展示差异，让用户三选一（`remote` / `local` / `merge`）

> **必读**：出现冲突时，完整执行 `references/conflict-resolution.md`（Step A–E）。Step 5 推送重试遇到的冲突也复用同一文件，不要在此处展开重复流程。

**分支硬约束**：冲突无法通过分级分流解决时，**停止并报告**当前 `git status`，让用户人工决策，**不得**创建任何新分支绕过。

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

**标题强制要求**：只要本次提交内容涉及版本号更新，commit title / message 第一行必须明确写出目标版本号 `X.Y.Z`，不得只写“更新版本”“发版准备”等模糊标题。示例：`chore: bump version to 1.2.2`、`docs: 更新版本号到 1.2.2`。

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

#### 4.1 执行分组提交

工作区变更的分组算法、TDD 功能包约束、主题纯度校验、commit message 规则与 dry-run 格式，**全部在 `references/commit-grouping.md` 中**。进入本步骤后必须完整执行该 reference 的全部强制步骤。

骨架要点（细节以 reference 为准）：

1. **小批量快速路径**：变更文件 ≤ 3 个 → 直接合并为 1 个 commit，跳过分组分析
2. **分组优先级**：`P0 字符串替换 > P1 符号重命名 > P1.5 TDD 功能包 > P2 目录模块 > P3 同主题新增 > P4 独立`
3. **TDD 功能包（P1.5）**：同一功能的实现 + 测试 + 需求总结文档必须合并为 1 个 commit，不得拆成"功能 commit"+"测试 commit"
4. **主题纯度校验**：P0 / P1 / P2 分组内每个文件纯度 < 30% 时强制移出到 P4 独立 commit，避免无关改动被主题 commit 吞掉
5. **逐组提交**：`git reset HEAD` → `git add <该组文件>` → `git commit -m "<message>"`；commit 失败（如 hook 拒绝）→ 停止并提示用户
6. **`--preview`**：仅展示分组方案与 commit messages，不执行任何写入性 git 操作

> **必读**：执行分组前完整阅读 `references/commit-grouping.md`，不要只凭上述骨架提交。

### Step 4.5: Squash Local Unpushed Commits（本地未推送提交整理）

在推送之前，把本地**未推送**的多个零散 commit 压成 **1 个干净 commit**。本步骤只保留最终代码版本，不保留旧 commit 的内部逻辑边界；会改写本地 commit 历史，**绝不触碰已推送到远程的提交**，完整流程在 `references/local-squash.md`。

**触发与跳过条件**：

- 仅在存在 upstream 且 `git rev-list --count @{u}..HEAD` ≥ 2 时才进入本步骤
- 本地未推送 commit < 2 个 → **跳过**，直接进入 Step 5
- 无 upstream（首次推送当前分支）：缺少"已推送基线"，**默认跳过整理**原样首推；除非用户显式要求

骨架要点（细节与精确命令以 reference 为准，**必须严格按 reference 的步骤顺序执行**）：

1. **第 0 步 前置守卫**：reset 前先确认 `git status --porcelain` 为空（工作区干净），并先记录回退锚点 `SQUASH_ORIG=$(git rev-parse HEAD)`、基线 `BASE=$(git rev-parse @{u})` 和整理前内容指纹。工作区不干净 → 放弃整理
2. **第 1 步 安全边界校验**：基线固定 `@{u}`；作者全部为当前用户（邮箱比对）；无 merge commit；全部未推送。任一不满足 → 保留原历史进入 Step 5
3. **第 2 步 聚合分析**：读取 `@{u}..HEAD` 的 commit message 与 diff，生成 1 个覆盖所有未推送改动的聚合 commit message；不再按多个逻辑组拆分重建
4. **第 3 步 soft reset 重建单个 commit**：`git reset --soft "$BASE"` 后使用 `git add -A` 一次性暂存全部最终改动，并提交为 1 个聚合 commit；提交完成后确认暂存区/工作区已清空
5. **第 4 步 强制一致性校验（gate）**：整理后 `git diff "$BASE" HEAD` 必须与整理前指纹完全一致，且新 commit 数必须为 1；不一致 → 回退
6. **第 5 步 失败回退**：任一步失败立即 `git reset --hard "$SQUASH_ORIG"` 恢复原历史和干净工作区；若恢复后工作区仍不干净则停止整个 push 流程并报告；**禁止** force-push、**禁止**推送被破坏的历史
7. **`--preview`**：仅展示整理方案，不执行任何写入性 git 操作（禁止 reset / commit / push）

> **必读且强制顺序**：执行整理前完整阅读 `references/local-squash.md`。记录回退锚点（第 0 步）**必须在 reset 之前完成**，否则丢失回退点。绝不能只凭上述骨架就执行 reset。

### Step 5: Push to Remote

如果前面没有产生新的工作区提交，但 Step 0 检测到本地分支领先 upstream，则此处直接推送已有本地 commit（含 Step 4.5 整理后的提交）。

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
- **如果 rebase 有冲突** → 严格执行 `references/conflict-resolution.md` 的分级分流流程（与 Step 1 完全一致）：轻冲突自动 merge 不提醒，重冲突才逐文件展示差异让用户选择 `remote` / `local` / `merge`
- **所有冲突文件处理并 `git rebase --continue` 成功后** → 再次执行 `git push origin HEAD`

**分支硬约束**：push 失败 / rebase 失败时，若无法通过分级分流解决，直接停止并向用户展示 `git status`，**不得**创建任何新分支规避冲突。

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

- 已有但尚未推送的本地 commit 被同步到远程；若满足整理条件，这些 commit 已合并为 1 个干净 commit
- 如工作区存在文件变更：生成 N 个新 commit（按逻辑分组，外加可选的版本号 commit）
- 可选：1 个新 tag（`X.Y.Z`）

本地 commit 整理保证：最终推送到远程的代码内容与整理前完全一致，仅 commit 历史结构变得更精简；已推送到远程的旧提交不受任何影响。

## Notes

1. **所有 git 命令在用户当前工作目录执行**，不是 ~/.claude 或插件目录
2. 所有 commit message 使用中文
3. Step 4 按逻辑分组提交；变更文件 ≤ 3 个时整体合为 1 个 commit
4. TDD 场景下，同一功能的实现、对应测试、需求总结文档必须归入同一个逻辑 commit；只有纯测试修改才单独作为 `test` commit
5. 版本号仅更新文档中的记录，不修改项目构建文件；**凡是涉及版本号更新的 commit，标题必须明确包含目标版本号**
6. 如果某个文件的变更只有代码格式化，commit message 中标注为 `style`
7. push 失败时自动重试一次；若重试拉取出现冲突，先按严重程度分级：轻冲突（双方修改不同行）自动 merge 不提醒，重冲突（双方修改同一行）才逐文件展示差异让用户选择 `remote` / `local` / `merge`；任何情况下都不得通过创建新分支规避冲突
8. Tag 直接使用用户提供的版本号，不添加 `v` 前缀，例如 `1.2.2`
9. Step 3 在 Step 4 之前执行，Step 3 提交的文件不会在 Step 4 中重复提交
10. Step 1 提前拉取代码，大幅降低 Step 5 推送时的冲突概率
11. `/dt:push --preview` 仅预览分组方案与 commit messages，不执行任何写入性 git 操作
12. 已 `git commit` 但未 `git push` 的场景属于正常路径；工作区干净时不能据此直接退出
13. **主题纯度校验是强制步骤**（细则见 `references/commit-grouping.md`）：P0 / P1 / P2 分组不能只凭"文件里命中主题模式"就纳入整个文件，必须计算纯度：纯度 ≥ 30% 保留在原分组；纯度 < 30% 强制移出到 P4 独立 commit，不询问用户。P1.5 则必须通过显式关联校验。这一规则用于避免 bug 修复、重构等不相关修改被主题 commit（如"统一国际化..."）吞掉，导致远程日志无法追溯真实变更
14. **本地 commit 整理（Step 4.5）只动未推送提交**（细则见 `references/local-squash.md`）：仅当本地有 ≥ 2 个未推送 commit、全部由当前用户提交、中途无他人提交、且不含 merge commit 时，才把这些未推送 commit 用 `git reset --soft` 压成 1 个干净 commit。已推送到远程的提交绝不 reset / rebase / amend / force-push。整理只改历史结构，不改最终代码；任一校验不通过或整理失败，保留原始本地历史并原样推送
15. **细则已拆分到 `references/`**：Step 1/5 冲突处理、Step 4 分组提交、Step 4.5 本地整理的完整强制规则分别在 `conflict-resolution.md`、`commit-grouping.md`、`local-squash.md`。执行到对应步骤时必须先完整阅读对应 reference，不要只凭主文件骨架执行
