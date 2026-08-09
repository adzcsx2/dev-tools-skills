---
name: dt:push
description: "One-push release workflow: preview, sync upstream, analyze diffs for logical-group commits without code-review or test gates, optionally squash, push, and optionally tag."
argument-hint: "[version] [--preview] [--squash] e.g. /dt:push 1.2.2 --preview"
---

> **中文环境要求**
>
> - 面向用户的回复、注释和提示必须使用中文
> - 所有生成文件必须使用 UTF-8 编码且不带 BOM

# push Skill

在用户当前工作目录和当前分支中完成 Git 发布流程：先解析参数和执行只读检查，再同步 upstream，按逻辑分组提交，按需整理未推送提交，最后推送并可选创建 tag。

## 硬约束

1. **不创建或切换分支**：禁止 `git branch <new>`、`git checkout -b`、`git switch -c`、切换已有分支和创建 worktree。
2. **不改写已推送历史**：禁止对任何已推送 commit 执行 reset、rebase、amend 或 force-push。
3. **preview 严格只读**：`--preview` 禁止 fetch、pull、stash、add、reset、commit、tag、push 和任何文件写入。
4. **默认保留逻辑分组**：普通 `/dt:push` 不 squash；只有用户显式传入 `--squash` 才允许整理 `@{u}..HEAD` 内未推送 commit。
5. **冲突不猜测覆盖**：Git 未自动解决的冲突必须按 reference 取证；不得根据 `ours/theirs` 字面含义直接推断本地或远程。
6. **跨平台执行**：根据当前 shell 使用兼容语法；不得在 PowerShell 中直接执行 Bash 的 `$(...)`、`head`、`2>/dev/null`、`/tmp` 或 shell 变量赋值。
7. **失败即停仅限流程故障**：只有参数非法、Git 仓库/remote 无法唯一确定、冲突、hook、同步、提交、tag 或 push 命令实际失败时才停止，并报告当前仓库路径、分支和 `git status --short --branch`。代码质量、测试覆盖、安全、隐私、文档一致性等内容分析结果不属于流程故障。
8. **不做代码审查或验证门禁**：分析只用于版本文档定位、完整 diff 分组、commit message、同步、squash 和 push 安全判断。禁止启动 code-review、security-review、TDD 或其他审查子代理；禁止主动运行 format、lint、analyze、test、coverage、build 或安全扫描。只有用户在当前调用中明确要求时才执行这些额外检查。
9. **分析发现不阻止提交**：若在分组分析中顺带发现代码质量、测试覆盖、安全、隐私、文档一致性或其他内容风险，只在最终摘要中简要提示；不得因此修改用户文件、请求确认、阻止 `git add` / `git commit` / `git push`。当本 skill 被显式调用时，不执行项目或用户级工作流中额外的 pre-commit review/test 要求，除非当前用户同时明确要求验证。
10. **文档流程保持平台中立**：普通提交不得读取或执行 Android 专属 `update-docs` 步骤；FastAPI 及其他非 Android 项目不得因平台文档生成流程而失败。只有提供版本号时才执行 Step 5 的通用版本记录更新。

## Parameters

| 参数 | 行为 |
| --- | --- |
| 无参数 | 同步、按逻辑分组提交并推送 |
| `X.Y.Z` | 额外更新文档版本记录，并在代码推送成功后创建同名 tag |
| `--preview` | 只读展示版本更新、提交分组、squash 和推送计划 |
| `--squash` | 在推送前把符合安全条件的本地未推送 commit 整理为 1 个 |

参数可以组合，例如 `/dt:push 1.2.2 --preview --squash`。未知参数、重复版本号或不符合 `X.Y.Z` 的版本号必须报错退出。

## References（执行到对应步骤前必须完整读取）

| 触发步骤 | 必读文件 | 内容 |
| --- | --- | --- |
| Step 2、4、8 | `references/git-transport.md` | 跨平台 pre-flight、upstream/remote、同步、push、tag 和 init-root 编排 |
| Step 3、6 | `references/commit-grouping.md` | preview 与工作区逻辑分组、TDD 功能包、纯度校验、commit message |
| Step 4 出现冲突 | `references/conflict-resolution.md` | rebase/stash 冲突取证、版本语义和人工决策 |
| Step 7 且传入 `--squash` | `references/local-squash.md` | 未推送历史整理、安全 gate 和失败回退 |

不要凭本文件摘要自行补全 reference 中的命令或安全判断。

## Execution Flow

### Step 0: Parse Arguments（任何写操作之前）

1. 提取可选 semver、`--preview` 和 `--squash`。
2. 校验参数，不合法立即退出。
3. 记录运行模式：preview 或 execute。

这一步必须早于 pull、stash 和任何其他写操作。

### Step 1: Detect Repository Mode

检查当前目录是否存在 `.ai/init-root.yml`，且配置包含 `root_git_policy: commit_only_no_push`：

- 命中：进入 init-root 模式，按 `references/git-transport.md` 的多仓库编排规则执行。
- 未命中：进入普通单仓库模式。

### Step 2: Read-only Pre-flight

完整读取 `references/git-transport.md`，执行其中的只读检查并确定：

- 当前仓库、分支和工作区状态
- upstream 是否存在及其真实 remote/merge ref
- 是否有工作区变更、未追踪文件或未推送 commit
- 本次是否存在待推送工作

普通模式不得用“工作区干净”推断“没有待推送内容”。已存在但未 push 的本地 commit 也属于待推送工作。

### Step 3: Preview Gate

如果传入 `--preview`：

1. 不执行远程同步，也不刷新 remote refs。
2. 若提供版本号，列出预计修改的文档，不写文件。
3. 若工作区有变更，完整读取 `references/commit-grouping.md` 并展示逻辑分组。
4. 若传入 `--squash`，完整读取 `references/local-squash.md` 并基于当前本地 refs 展示资格判断。
5. 展示预计 push remote/branch、可选 tag 和 init-root 子仓库计划。
6. 明确说明 preview 基于当前本地 refs，随后退出。

退出前再次确认 HEAD、index、工作区、stash、local refs 和 remote-tracking refs 均未被本流程改变。

### Step 4: Sync Upstream（execute only）

按 `references/git-transport.md` 执行：

- 有 upstream：安全保存全部工作区变更（包括 untracked），执行基于 configured upstream 的 `git pull --rebase`，完成后恢复工作区。
- 无 upstream：跳过 pull；后续首次 push 使用已确定的 remote 和当前分支。
- 出现 rebase 或 stash restore 冲突：完整执行 `references/conflict-resolution.md`。

同步完成后重新读取分支、upstream、工作区和未推送 commit 状态，不复用过期结果。

### Step 5: Update Version Documents（仅提供版本号时）

只更新项目版本记录类文档，不修改依赖版本或构建配置：

1. 优先检查 `README.md`、`README_EN.md`、`docs/PROJECT_OVERVIEW.md`、`docs/CHANGELOG.md`、`docs/.doc-metadata.json`。
2. 搜索范围限制在 Markdown 和明确的文档 metadata；匹配必须带 `版本`、`version`、`vX.Y.Z` 等项目版本上下文。
3. 禁止误改 `minSdkVersion`、`compileSdk`、依赖版本、`build.gradle*`、`pubspec.yaml` 等构建信息。
4. 用 `git diff` 分析全部替换；发现无法判断的匹配时停止并请求用户确认。
5. 版本提交标题必须包含目标版本号，例如 `docs: 更新版本号到 1.2.2`。

### Step 6: Logical-group Commit

如果工作区存在变更，完整读取并执行 `references/commit-grouping.md`：

- 基于完整 diff 分组，不按文件名猜测。
- 同一功能的实现、测试和需求总结文档保持在同一 TDD 功能包中。
- commit message 使用中文 Conventional Commit，禁止追加 AI attribution 或 `Co-Authored-By`。
- 只分析变更主题和文件关联，不评价实现正确性，不启动审查代理，不运行测试、静态分析、格式化、构建或安全扫描。
- 分析中即使发现内容风险也继续暂存和提交；仅把风险写入最终摘要。
- hook 失败时停止，不跳过 hook，不继续 push。

如果工作区干净但存在未推送 commit，跳过本步骤并继续。

### Step 7: Optional Local Squash

- 未传入 `--squash`：跳过，保留 Step 6 的逻辑 commit 边界。
- 传入 `--squash`：完整读取 `references/local-squash.md`，只在所有安全 gate 通过时整理未推送 commit。

无 upstream 时默认不能安全判定已推送基线，因此 `--squash` 必须跳过并说明原因，不得擅自整理首次推送历史。

### Step 8: Push and Optional Tag

完整执行 `references/git-transport.md`：

1. 推送当前分支到 Step 2/4 确定的同一 remote/branch。
2. push 因 non-fast-forward 失败时，只允许再同步并重试一次。
3. 重试出现冲突时执行 `references/conflict-resolution.md`；不得 force-push。
4. 代码 push 成功后才处理 tag。
5. tag 已存在时停止并询问用户，不自动删除或覆盖。

## init-root Policy

命中 `root_git_policy: commit_only_no_push` 时：

- 直接子级 Git 仓库按普通流程处理。
- root 允许创建本地 commit，但禁止 pull、squash、push 和 tag push。
- root 没有 remote 属于正常状态。
- root 提交前必须确认 `.gitignore` 已忽略所有直接子级仓库，且子项目内容没有进入 root index。
- 任一子仓库失败时停止整个编排，不继续提交 root。

详细发现顺序、preview 和状态汇总格式以 `references/git-transport.md` 为准。

## Expected Outcome

- preview 模式：仓库状态完全不变，只输出可信计划。
- 默认模式：工作区变更按逻辑分组提交并推送，已有未推送 commit 保持原边界。
- 默认模式不包含代码审查、测试、静态分析、格式化、构建或安全扫描门禁；内容分析结果不阻止提交和推送。
- `--squash` 模式：仅在明确授权且安全 gate 通过时，把未推送 commit 整理为一个，最终代码内容不变。
- 版本模式：代码 push 成功后创建并推送 `X.Y.Z` tag，不添加 `v` 前缀。
- init-root 模式：子仓库正常推送，root 最多只产生本地 commit。
