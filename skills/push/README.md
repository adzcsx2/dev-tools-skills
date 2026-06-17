# dt:push

一键发布工作流：自动暂存所有变更、拉取最新代码、按逻辑分组提交、推送到远程仓库。

---

## 功能

- 开发完成，准备将代码推送到远程仓库
- 发版时需要更新文档版本号并创建 tag
- 需要自动生成提交信息并按逻辑分组提交
- 工作区有未暂存的变更，需要一键提交推送
- 已提交但尚未 push 的本地 commit 也会直接推送到远程
- 本地堆积多个未推送的零散 commit（全部自己提交、中途无他人提交）时，压成 1 个干净 commit 后再推送
- 如果当前目录是 `dt:init-root` 初始化出的多仓库根目录（存在 `.ai/init-root.yml` 且标记 `root_git_policy: commit_only_no_push`），会先发现直接子级 git 仓库并在各子仓库目录执行普通 `dt:push`；root 仓库只创建本地 commit，绝不 push

## 用法

- `/dt:push` - 自动暂存所有变更，按逻辑分组提交，推送到远程
- `/dt:push 1.2.2` - 更新文档版本号到 1.2.2，提交并打 tag
- `/dt:push --preview` - 预览分组方案与 commit messages，不执行任何写入性 git 操作

## 行为说明

- 如果工作区有变更：先提交，再 push
- 如果工作区已干净，但本地分支存在未推送提交：直接 push，不应提示"没有需要处理的内容"
- 逻辑分组策略包含 P0、P1、P1.5、P2、P3、P4 六个优先级：字符串替换、符号重命名、TDD 功能包、目录聚类、同主题新增、独立变更
- TDD 场景下（P1.5 优先级），同一功能的实现、对应测试、需求总结文档必须合并为 1 个逻辑 commit；只有纯测试修改才单独作为 `test` commit；通过显式关联校验（模块路径/符号引用/特征词匹配）判定，不做简单目录归并
- P0/P1/P2 分组强制执行主题纯度校验：纯度 < 30% 的文件移出到独立 commit，确保远程日志可追溯
- 凡是提交内容涉及版本号更新，commit 标题必须明确包含目标版本号，例如 `chore: bump version to 1.2.2` 或 `docs: 更新版本号到 1.2.2`
- **本地 commit 整理（推送前）**：仅当本地有 ≥ 2 个未推送 commit、全部由当前用户提交、中途无他人提交且无 merge commit 时，用 `git reset --soft` 把这些 commit 压成 1 个干净 commit；**只动 `@{u}..HEAD` 内未推送提交，已推送的提交绝不 reset / rebase / amend / force-push**；整理只改历史结构、不改最终代码；中途出现他人提交或校验不通过时保留原历史原样推送
- **全程只在当前分支操作，绝不创建新分支**；冲突按严重程度分级：轻冲突（双方改不同行）自动 merge 不提醒，重冲突（双方改同一行）才逐文件提示用户三选一（remote / local / merge）；无冲突时静默继续
- **init-root 根目录例外**：root 仓库是本地协调状态，允许没有 remote；执行时先编排直接子级 git 仓库按普通规则提交/推送，再跳过 root 的 pull、squash、push 和 tag push，只提交未被 `.gitignore` 忽略的 root 文件

## 结构

主 `SKILL.md` 保留可线性执行的步骤骨架，三类细则拆分到 `references/`，避免单文件过长导致执行时遗漏步骤：

| reference                           | 内容                                                                                        |
| ----------------------------------- | ------------------------------------------------------------------------------------------- |
| `references/conflict-resolution.md` | 冲突分级分流完整流程（Step 1 / Step 5 共用）                                                |
| `references/commit-grouping.md`     | 工作区变更逻辑分组算法、TDD 功能包、主题纯度校验、commit message 规则                       |
| `references/local-squash.md`        | 本地未推送提交压成 1 个干净 commit（含破坏性安全说明、前置守卫、一致性校验 gate、失败回退） |

---

> 本文档由 SKILL.md 自动生成，请勿手动编辑。如需更新，修改 SKILL.md 后运行 `/dt:update-remote-plugins`。
