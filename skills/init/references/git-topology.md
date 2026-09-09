# Multi-Repository Root Git Topology

本文件定义 `dt:init` 在产品根目录包含多个独立子 Git 仓库时，如何建立根仓库、隔离子仓库并决定根提交是否推送。真实 Git 状态始终覆盖旧文档和旧配置。

## Trigger And Scope

- 只扫描当前目录的直接子目录。
- 直接子目录包含 `.git` 目录或 `.git` 文件时，视为独立子 Git 仓库。
- 排除隐藏目录、`docs`、`node_modules`、`build`、`dist`、`target` 等非项目目录。
- 未发现直接子 Git 仓库时，保持普通 `dt:init` 行为：不得仅为初始化 AI 规则而创建 Git、commit 或 push。
- 初始化阶段只处理根仓库；不得 commit 或 push 子仓库。子仓库后续由根目录 `dt:push` 编排。

## Root Git Detection

不要用父目录 Git 状态冒充当前根仓库。依次确认：

1. 当前目录是否存在 `.git` 目录或 `.git` 文件。
2. `git rev-parse --show-toplevel` 的规范化路径是否等于当前目录。
3. 当前分支、upstream 和 remote 是否可用。

若当前根没有自己的 `.git`，在非 `--dry-run` 模式执行 `git init`。不得为根仓库自动添加 remote，也不得创建、删除或改写子仓库 remote。

若已有根 Git 处于 detached HEAD 或当前分支为空，停止 root commit/push finalization 并报告；不得为完成 init 而创建或切换分支。新执行 `git init` 后的 unborn 默认分支不视为 detached HEAD，可在首次 commit 后继续。

## Root Remote Classification

按以下顺序确定根 push 目标：

1. 当前分支已有 configured upstream：使用其 remote 和 merge ref。
2. 无 upstream 但存在 `origin`：使用 `origin` 和当前分支。
3. 无 upstream、无 `origin`、只有一个 remote：使用该 remote 和当前分支。
4. 没有 remote：根仓库只能本地提交。
5. 有多个 remote 且无法唯一选择：根仓库仍可本地提交，但不得 push；报告需要用户选择 remote。

实际 Git remote/upstream 是事实来源。重复执行 `dt:init` 时必须重新分类，不得沿用过期 policy。

## Canonical Init-Root Config

发现直接子 Git 仓库时，创建或更新根目录 `.ai/init-root.yml`。不要写到 `docs/references/init-root.yml`。

支持两个 policy：

| 真实根状态 | `root_git_policy` | 行为 |
| --- | --- | --- |
| 无可用 remote | `commit_only_no_push` | 子仓库成功后，根只做本地 commit |
| remote 可唯一确定 | `commit_and_push_after_children` | 子仓库成功后，根同步、commit 并 push |

remote 可唯一确定时记录 `root_remote`。根没有 remote 时删除陈旧的 `root_remote` / `root_remote_status`；多个 remote 无法选择时删除陈旧 `root_remote`、使用 `commit_only_no_push` 并记录 `root_remote_status: ambiguous`，不得猜测。

`child_projects` 必须来自真实扫描，保存直接子路径、当前分支、remote 是否存在和真实 stack signals。路径去重后按稳定字典序写入。

## Ignore Child Repositories

确保根 `.gitignore` 包含受控 block：

```gitignore
# dt:init-root child repositories
/admin/
/backend/
/frontend/
```

- 保留 block 外的现有内容。
- 每次按当前真实直接子 Git 仓库全集重建 block，稳定排序、去重。
- 只写 anchored direct-child 路径，不写通配符，不写嵌套子路径。
- 在任何 root `git add` 或 commit 前完成此 block。
- 确认子仓库内容未进入 root index。若已被 root 跟踪，停止 root commit/push 并报告精确路径；未经用户确认不得自动执行批量 `git rm --cached`。

## Generated Root Rules

`CLAUDE.md`、`AGENTS.md` 与 Copilot 项目级配置必须按真实 policy 写入精简规则：

- 子仓库始终在各自目录独立同步、commit、push，根仓库不得暂存子仓库内容。
- 根目录 `dt:push` 先按稳定路径顺序处理所有直接子 Git 仓库。
- 任一子仓库失败时立即停止，不处理后续子仓库，也不 commit/push 根仓库。
- 所有子仓库成功后，根无 remote 则本地 commit；根有可唯一确定 remote 则同步、commit 并 push 当前分支。
- remote/upstream 后续发生变化时，以实时 Git 状态为准并刷新 `.ai/init-root.yml`。
- 禁止 force-push；不得自动添加、替换或改写 remote。

## Root Commit And Push Finalization

仅在非 `--dry-run` 且全部 init 内容验证通过后执行：

1. 再次确认 `.gitignore` 已覆盖全部直接子 Git 仓库，root index 不含子仓库内容。
2. 确认当前分支不是 detached HEAD；否则停止，不 commit/push。
3. remote 可唯一确定时，完整读取 `skills/push/references/git-transport.md`，只对根仓库执行普通仓库的只读 pre-flight 与 upstream 同步：安全保存全部工作区变更、同步、恢复后再继续；不得进入子仓库编排。
4. 只暂存本次 `dt:init` 创建或修改的根文件以及 `.ai/init-root.yml`、`.gitignore`；不得顺带提交用户无关改动。
5. 有 staged 变更时创建中文 Conventional Commit，标题和正文都必须说明项目 AI 上下文/根 Git 初始化；禁止 AI attribution。
6. 无可用 remote：保留本地 commit，报告 `commit_only_no_push`。
7. remote 可唯一确定：按同一 `git-transport.md` 目标 push 当前分支；执行 non-fast-forward 安全规则，不得 force-push。
8. push 失败时保留本地 commit，报告真实失败原因和当前分支；不得把认证、网络或权限失败伪装成成功。

如果工作区有用户预先存在的无关改动，同步时必须安全保存并恢复，但不得把它们加入 init commit。若无法可靠隔离本次变更，停止 commit/push 并请求用户处理，不得扩大提交范围。

## Dry-Run And Verification

`--dry-run` 只能输出：检测到的子仓库、预计 `.gitignore` block、预计 policy、根 commit 文件清单和 push 目标。禁止 `git init`、写配置、add、commit、fetch、pull、stash 或 push。

执行后至少验证：

- 根目录拥有自己的 `.git`。
- `.ai/init-root.yml` policy 与实时 remote 状态一致。
- `.gitignore` 覆盖全部直接子 Git 仓库。
- root index 不包含子仓库内容。
- 子仓库 `.git`、branch 和 remote 未被修改。
- 本地 commit 已创建；remote-enabled 根仓库还要确认当前提交已推送到 configured upstream/首次推送目标。

无法验证的项目明确写 `not verified`。
