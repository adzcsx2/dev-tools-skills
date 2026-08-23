# dt:push

一键发布工作流：只读预览、同步 upstream、只分析 diff 并按逻辑分组提交、可选整理未推送提交、推送并可选创建 tag；默认不执行代码审查或测试门禁。

---

## 功能

- 开发完成，准备将代码推送到远程仓库
- 发版时需要更新文档版本号并创建 tag
- 需要自动生成提交信息并按逻辑分组提交
- 工作区有未暂存的变更，需要一键提交推送
- 已提交但尚未 push 的本地 commit 也会直接推送到远程
- 只分析 diff 的主题和文件关联以生成逻辑分组与 commit message，不执行代码审查、测试、静态分析、格式化、构建或安全扫描
- 分析中顺带发现的内容风险只在最终摘要提示，不阻止提交和推送
- 用户显式传入 `--squash`，且全部安全 gate 通过时，将本地未推送 commit 压成 1 个干净 commit 后再推送
- 如果当前目录是多仓库根目录，会先按稳定顺序在直接子 Git 仓库执行普通 `dt:push`；全部成功后，root 无 remote 时本地提交，有可用 remote 时同步、提交并推送 root

## 用法

- `/dt:push` - 自动暂存所有变更，按逻辑分组提交，推送到远程
- `/dt:push 1.2.2` - 更新文档版本号到 1.2.2，提交并打 tag
- `/dt:push --preview` - 预览分组方案与 commit messages，不执行任何写入性 git 操作
- `/dt:push --squash` - 明确授权整理未推送 commit 后再推送
- `/dt:push 1.2.2 --preview --squash` - 只读预览版本更新、整理和发布计划

## 行为说明

- 如果工作区有变更：先提交，再 push
- 如果工作区已干净，但本地分支存在未推送提交：直接 push，不应提示"没有需要处理的内容"
- 逻辑分组策略包含 P0、P1、P1.5、P2、P3、P4 六个优先级：字符串替换、符号重命名、TDD 功能包、目录聚类、同主题新增、独立变更
- TDD 场景下（P1.5 优先级），同一功能的实现、对应测试、需求总结文档必须合并为 1 个逻辑 commit；只有纯测试修改才单独作为 `test` commit；通过显式关联校验（模块路径/符号引用/特征词匹配）判定，不做简单目录归并
- P0/P1/P2 分组强制执行主题纯度校验：纯度 < 30% 的文件移出到独立 commit，确保远程日志可追溯
- **无审查与验证门禁**：默认不启动 code-review、security-review、TDD 或其他审查子代理，也不主动运行 format、lint、analyze、test、coverage、build 或安全扫描；只有用户在当前调用中明确要求时才执行
- **分析不阻止提交**：代码质量、测试覆盖、安全、隐私或文档一致性等内容风险只进入最终摘要，不修改用户文件、不请求确认、不阻止 `git add`、`git commit` 或 `git push`
- **仅流程故障停止**：只有参数、仓库/remote 选择、Git 冲突、hook、同步、提交、tag 或 push 命令实际失败时才停止
- **平台中立文档流程**：普通提交不读取或执行 Android 专属 `update-docs`；FastAPI 及其他非 Android 项目仅在提供版本号时更新通用版本记录
- 凡是提交内容涉及版本号更新，commit 标题必须明确包含目标版本号，例如 `chore: bump version to 1.2.2` 或 `docs: 更新版本号到 1.2.2`
- **preview 严格只读**：参数在任何 pull/stash 之前解析；preview 不 fetch、pull、stash、add、reset、commit、tag、push，也不修改文件或 refs
- **本地 commit 整理（显式授权）**：默认保留逻辑分组；只有传入 `--squash`，且本地有 ≥ 2 个未推送 commit、作者一致、无 merge commit、工作区干净、内容一致性 gate 通过时，才用 `git reset --soft` 压成 1 个 commit；已推送历史绝不改写或 force-push
- **全程只在当前分支操作，绝不创建新分支**；Git 未自动解决的冲突逐文件取证，按实际 rebase/stash 语义区分 upstream 基线与本地重放内容，不使用容易写反的固定 `ours/theirs = local/remote` 映射
- **upstream 与跨平台一致性**：pull/push 使用 configured upstream；无 upstream 时才选择明确 remote。PowerShell 不直接执行 Bash 专属变量、`head`、`/tmp` 或重定向语法
- **init-root 根目录编排**：识别 `commit_only_no_push` 与 `commit_and_push_after_children`；实时 remote 状态覆盖旧配置。先处理直接子 Git 仓库，任一失败则 root 不变；全部成功后，root 无 remote 时本地提交，有可唯一确定 remote 时执行普通 sync/commit/push/tag 流程

## 结构

主 `SKILL.md` 保留可线性执行的步骤骨架，执行细则拆分到 `references/`，避免单文件过长导致执行时遗漏步骤：

| reference                           | 内容                                                                                        |
| ----------------------------------- | ------------------------------------------------------------------------------------------- |
| `references/git-transport.md`        | 跨平台 pre-flight、upstream、preview、同步、push、tag 和 init-root 编排                     |
| `references/conflict-resolution.md` | rebase / stash 冲突取证、版本语义和用户决策                                                 |
| `references/commit-grouping.md`     | 工作区变更逻辑分组算法、TDD 功能包、主题纯度校验、commit message 规则                       |
| `references/local-squash.md`        | 显式 `--squash` 的未推送历史整理、内容一致性 gate 和失败回退                                |

---

> 本文档由 SKILL.md 自动生成，请勿手动编辑。如需更新，修改 SKILL.md 后运行 `/dt:update-remote-plugins`。
