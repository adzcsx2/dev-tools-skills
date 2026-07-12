# Git 传输与跨平台执行细则

> 本文件服务于 `dt:push` 的 pre-flight、同步、push、tag 与 init-root 编排。
> 目标是让同一流程在 PowerShell、Git Bash、bash 和 zsh 中保持相同语义，并确保所有读写都作用于用户调用 skill 时的当前仓库。

## 1. 跨平台命令规则

- 优先逐条执行 Git 原生命令并直接读取输出，不依赖 shell 变量拼接。
- PowerShell 中将 `@{u}` 写成 `'@{u}'`，避免被解释为 hashtable。
- 不使用 `head`、`grep`、`sed`、`/tmp` 或系统 `diff` 才能完成的关键判断。
- 不把 remote、branch 或文件路径直接插入未经参数化的复合 shell 字符串。
- 路径参数始终使用 literal/quoted argument；文件列表较长时逐组传参，不生成可执行命令文本再二次求值。
- 禁止为绕过 shell 差异而切换分支、创建 worktree 或使用另一个仓库副本。

文档中的 `REMOTE`、`BRANCH`、`UPSTREAM` 表示 AI 从前序命令输出中记录的值，不要求在当前 shell 中创建同名环境变量。

## 2. 普通仓库只读 pre-flight

按顺序执行：

```bash
git rev-parse --is-inside-work-tree
git branch --show-current
git status --porcelain=v1 --untracked-files=all
git status --short --branch
git rev-parse --abbrev-ref --symbolic-full-name "@{u}"
git config --get branch.<当前分支>.remote
git config --get branch.<当前分支>.merge
```

其中 `<当前分支>` 必须替换为 `git branch --show-current` 返回的精确值，并作为单独参数传递。

处理规则：

| 状态 | 处理 |
| --- | --- |
| 非 Git 仓库 | 报告并退出 |
| detached HEAD / 当前分支为空 | 报告并退出，不创建或切换分支 |
| upstream 存在 | 记录其 configured remote 和 merge ref，不再猜测 remote |
| upstream 不存在 | 优先使用 `origin`；若无 `origin` 且只有一个 remote，使用该 remote；零个或多个无法唯一选择时停止并询问 |
| 工作区有 tracked/untracked 变更 | 允许继续；execute 模式同步前必须完整保存 |
| 工作区干净且有未推送 commit | 允许继续并直接走 push 路径 |

upstream 存在时，再读取：

```bash
git rev-list --count "@{u}..HEAD"
git log "@{u}..HEAD" --pretty=format:"%h|%an|%ae|%s"
```

不要运行 `git remote | head -1`。remote 的来源只能是 configured upstream、明确的 `origin` 或用户选择。

## 3. Preview 的只读边界

preview 只能执行不会改变 repository、index、working tree、stash 或 refs 的命令，例如：

```bash
git status
git diff
git diff --cached
git log
git rev-list
git show
git remote get-url <remote>
git config --get <key>
git tag -l <tag>
```

preview 禁止执行：

- `git fetch`、`git pull`、`git push`
- `git stash`、`git add`、`git reset`、`git commit`
- `git checkout`、`git restore`、`git switch`
- `git tag` 创建/删除操作
- 任何文档版本替换或临时文件写入

preview 开始和结束分别记录并比较：

```bash
git rev-parse HEAD
git status --porcelain=v1 --untracked-files=all
git stash list --format="%gd|%H|%s"
git show-ref --heads --tags
git for-each-ref --format="%(refname)|%(objectname)" refs/remotes
```

如果当前 Git 版本不支持其中某个只读命令，报告无法完成对应 gate；不得用写操作替代。

## 4. Execute 模式同步 upstream

### 4.1 有 upstream

先记录完整工作区状态。若工作区不干净：

```bash
git stash push --include-untracked --message "dt-push pre-sync"
```

确认 stash 命令成功且工作区已干净；否则停止。随后直接使用 configured upstream：

```bash
git pull --rebase
```

不额外拼接本地分支名，因为本地分支可能跟踪不同名的远程分支。

- rebase 成功：如创建了专用 stash，执行 `git stash pop` 恢复。
- rebase 冲突：先按 `conflict-resolution.md` 完成或停止；rebase 未完成前不得 pop stash。
- pull 以非冲突错误失败：停止，保留专用 stash，并报告恢复命令和当前状态；不得继续 commit/push。
- stash pop 冲突：按 `conflict-resolution.md` 的 stash restore 语义处理。
- stash pop 成功：确认本次专用 stash 已移除，且恢复后的变更与同步前文件集合一致。

只在本流程确实创建了 stash 时执行 pop，不得弹出用户原有 stash。

### 4.2 无 upstream

跳过 pull/rebase。记录 Step 2 已确定的 remote 与当前本地分支，留到首次 push 使用。

## 5. Push

### 5.1 有 upstream

正常情况直接执行：

```bash
git push
```

这会使用与 pull 相同的 tracking configuration，避免 remote/branch 漂移。

### 5.2 无 upstream

使用 pre-flight 已唯一确定的 remote 和当前分支：

```bash
git push -u <remote> <当前分支>
```

远程创建当前同名分支属于首次推送，不属于本 skill 禁止的本地新建分支。

### 5.3 non-fast-forward 重试

只有明确识别为远程领先/non-fast-forward 时才重试一次：

1. 执行 `git pull --rebase`（已有 upstream）或明确 remote/branch 的等价 rebase（首次 push 竞争场景）。
2. 有冲突时执行 `conflict-resolution.md`。
3. rebase 成功后重新执行与首次相同的 push 命令。
4. 第二次失败立即停止。

认证失败、权限失败、hook 拒绝、网络错误、受保护分支或远程策略拒绝都不能通过 rebase 重试，更不能 force-push。

## 6. Tag

仅在代码 push 成功且用户提供版本号时执行：

```bash
git tag -l "X.Y.Z"
```

- 本地已存在：停止并询问，不删除、不移动。
- 本地不存在：在创建前用 `git ls-remote --tags <remote> "refs/tags/X.Y.Z"` 检查远程同名 tag。
- 远程已存在：停止并询问。
- 两端都不存在：创建 `X.Y.Z`，再推送到与代码相同的 remote。
- tag push 失败：保留本地 tag，报告状态；不得删除远程 tag 或 force 更新。

## 7. init-root 多仓库编排

命中 `.ai/init-root.yml` 的 `root_git_policy: commit_only_no_push` 后：

1. 验证 root 是 Git 仓库；root 无 remote 可接受。
2. 读取 `child_projects[].path`，只接受 root 的直接子级路径。
3. 补充扫描直接子级目录中的 `.git`；去重后按稳定路径顺序处理。
4. 跳过不存在、非目录、非直接子级或不含 `.git` 的配置项，并在结果中说明。
5. preview：对子仓库和 root 仅执行第 3 节允许的只读命令，不 fetch/pull/stash/commit/push。
6. execute：逐个子仓库执行普通仓库流程，传递同一参数组合。
7. 任一子仓库失败：立即停止，不处理剩余子仓库，也不提交 root。
8. 子仓库全部成功后，检查 root `.gitignore` 中的 `# dt:init-root child repositories` block，并确认 index/工作区不包含子仓库内容。
9. root 有自身变更时按逻辑生成一个中文本地 commit；提交信息同样必须包含单行标题和非空改动说明正文；root 禁止 pull、squash、push 和 tag。

版本参数会作用于每个子仓库。若某个产品根目录不应统一给所有子仓库更新版本/tag，必须在 execute 前停止并让用户缩小调用范围。

## 8. 完成状态汇总

逐仓库输出：

- 路径、当前分支、upstream 或首次推送目标
- 同步结果
- 新建 commit 数及标题
- 是否执行 squash
- push 与 tag 结果
- root 是否仅本地 commit

不要在用户可见输出中粘贴可能含凭据的 remote URL；只显示 remote 名和已脱敏的 host/repository 摘要。
