# 本地未推送提交整理（显式 `--squash`）

> 本文件只在用户显式传入 `--squash` 时适用。
> 默认 `/dt:push` 必须跳过本文件，以保留工作区逻辑分组产生的 commit 边界。

## 1. 破坏性边界

本步骤会移动本地 HEAD 并重建 commit。必须同时满足：

- 用户明确传入 `--squash`。
- configured upstream 存在。
- 范围严格限定为 `@{u}..HEAD`。
- 该范围至少包含 2 个 commit。
- 全部 commit 作者邮箱等于当前 `git config user.email`。
- 不包含 merge commit。
- 未推送 commit 不被任何已知 remote-tracking ref 包含。
- 工作区和 index 完全干净。
- 不需要 force-push 即可推送结果。

任一条件不满足：不执行 reset，保留原历史进入 push，并说明跳过原因。

无 upstream 时即使用户传入 `--squash` 也默认跳过，因为缺少可靠的已推送基线。不得自行选择 root commit 或猜测远程边界。

## 2. Preview

preview 只能读取当前本地 refs，不能 fetch、reset、commit 或写临时文件。

执行只读检查：

```bash
git status --porcelain=v1 --untracked-files=all
git rev-list --count "@{u}..HEAD"
git log "@{u}..HEAD" --pretty=format:"%H|%an|%ae|%s"
git log "@{u}..HEAD" --merges --pretty=format:"%H|%s"
git config user.email
```

逐个候选 commit 使用 `git branch -r --contains <sha>` 检查已知 remote-tracking refs。preview 输出必须注明：结果基于当前本地 refs，未刷新远程状态。

展示：

- 候选 commit 数和标题。
- 每项 gate 的结果。
- 预计聚合 commit message。
- 整理后 commit 数变化。
- “本次 preview 未修改仓库”。

## 3. 第 0 步：execute 前置守卫

同步 upstream、版本提交和逻辑分组提交全部完成后，重新执行：

```bash
git status --porcelain=v1 --untracked-files=all
git rev-parse HEAD
git rev-parse "@{u}"
git rev-list --count "@{u}..HEAD"
```

要求工作区输出为空且未推送 commit 数至少为 2。

在 AI 运行状态中记录：

- `SQUASH_ORIG`：整理前精确 HEAD SHA。
- `BASE`：整理前精确 upstream SHA。
- `BEFORE_TREE`：`git rev-parse "HEAD^{tree}"` 的结果。
- `BEFORE_DIFF_HASH`：`git diff --binary "@{u}" HEAD | git hash-object --stdin` 的结果。

这些名称表示必须保留的值，不要求通过 shell 变量保存。禁止依赖 `/tmp` 或系统 `diff`。

## 4. 第 1 步：安全校验

### 4.1 作者与结构

```bash
git config user.email
git log "@{u}..HEAD" --pretty=format:"%H|%an|%ae|%s"
git log "@{u}..HEAD" --merges --pretty=format:"%H|%s"
```

- 当前用户邮箱为空：跳过 squash。
- 任一作者邮箱不一致：跳过 squash。
- 存在 merge commit：跳过 squash。

### 4.2 已知远程可见性

对每个候选 SHA 执行：

```bash
git branch -r --contains <sha>
```

任一 commit 被任何 remote-tracking ref 包含：跳过 squash。不得缩小范围后部分整理，也不得 force-push。

### 4.3 基线稳定性

再次读取 `git rev-parse "@{u}"`，必须仍等于记录的 `BASE`。如果变化，重新开始整个资格判断，不得沿用旧边界。

## 5. 第 2 步：生成单个聚合 commit message

读取全部候选 commit 与最终 diff：

```bash
git log "@{u}..HEAD" --pretty=format:"%h|%s" --name-only
git diff --stat "@{u}" HEAD
git diff "@{u}" HEAD
```

规则：

- message 概括最终整体意图，不罗列旧 message。
- 使用中文 Conventional Commit。
- 涉及版本号时标题必须包含目标版本号。
- `wip`、`fix typo`、`address review` 等修补措辞不得保留。
- 禁止追加 AI attribution 或 `Co-Authored-By`。
- 无法生成可信聚合标题时跳过 squash。

## 6. 第 3 步：重建单个 commit

只有第 0–2 步全部通过才能执行：

```bash
git reset --soft <BASE>
git add -A
git commit -m "<聚合后的 commit message>"
```

- `<BASE>` 必须使用第 0 步记录的精确 SHA，不能在 reset 后重新解析 `@{u}`。
- reset 后必须一次性 `git add -A`，不得重新按文件拆组。
- commit/hook 失败立即进入第 8 节回退。
- commit 后工作区必须干净，否则回退。

## 7. 第 4 步：强制一致性 gate

整理后验证：

```bash
git rev-list --count "@{u}..HEAD"
git rev-parse "HEAD^{tree}"
git diff --binary "@{u}" HEAD | git hash-object --stdin
git status --porcelain=v1 --untracked-files=all
```

必须同时满足：

- 未推送 commit 数恰好为 1。
- 新 `HEAD^{tree}` 等于 `BEFORE_TREE`。
- 新 diff hash 等于 `BEFORE_DIFF_HASH`。
- 工作区和 index 为空。
- upstream 仍等于 `BASE`。

任一不满足立即回退，禁止 push 当前结果。

## 8. 第 5 步：失败回退

只有在第 0 步已确认工作区干净、已记录 `SQUASH_ORIG`，并且本流程已经执行 soft reset 后，才允许：

```bash
git reset --hard <SQUASH_ORIG>
git status --porcelain=v1 --untracked-files=all
git rev-parse HEAD
git rev-parse "HEAD^{tree}"
```

恢复后的 HEAD 必须等于 `SQUASH_ORIG`，tree 必须等于 `BEFORE_TREE`，工作区必须为空。

- 全部一致：报告 squash 失败，保留原历史继续普通 push。
- 任一不一致：停止整个 push 流程，禁止 push，报告当前状态等待用户决策。

禁止创建备份分支、禁止 force-push、禁止推送未通过一致性 gate 的历史。
