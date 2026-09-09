# Output Files

本文件定义 `dt:init` 生成或升级的项目级规则文件、Copilot 配置、onboarding 摘要以及可选 checklist 的要求。

## Output Constraints

生成的 AI 配置文件（`CLAUDE.md`、`AGENTS.md`、Copilot 项目级配置）必须完整覆盖这些原则：

- GP-2 Single Sources of Truth
- GP-3 Reuse-First
- GP-4 File-Touch Discipline
- GP-5 Plan-First Triggers
- GP-6 Minimal Verification
- GP-7 AI Vibe Coding Constraints（精简版）
- GP-8 Copilot Config Exclusivity
- GP-9 Documentation Taxonomy（精简版）
- SR 维度（精简版，按栈裁剪）：规则模块化 + 索引、目录级 Mock 隔离、Linter 强制边界、接口 -> 确认 -> 业务 -> 测试 分步工作流、依赖注入隔离、集成测试反 Mock 与环境防呆（见 `scoped-rules-and-enforcement.md`）
- Worktree Location Policy：所有新 Git worktree 统一放在 `<project-root>/.worktree/<worktree-name>`，项目根 `.gitignore` 忽略 `/.worktree/`
- Logs Location Policy：项目根目录必须存在 `logs/`；所有新生成的项目日志文件统一写入 `<project-root>/logs/`
- 检测到直接子 Git 仓库时，必须包含 `git-topology.md` 的根/子仓库隔离、失败顺序和基于真实 remote 的根提交/推送规则

## CLAUDE.md

默认行为是优化已有 `CLAUDE.md`，不是全量重写。只有以下情况才接近重写：

- 项目不存在 `CLAUDE.md`
- 现有内容严重过时且与代码冲突
- 用户明确要求重写

生成结果要求：

- 60 到 120 行优先
- 采用规则 + 路径索引的高密度写法
- 不复制 README 大段内容；不展开完整依赖表、完整构建教程、完整架构宣讲

必须显式包含：

1. 单一事实来源与证据要求
2. 复用优先规则
3. 触碰文件原则与计划触发条件
4. 最小验证规则，包含仓库默认验证命令
5. AI vibe coding 约束（精简版）
6. Copilot 配置互斥规则
7. 文档根目录、分类映射、新文档落位规则（含中文文档命名、任务聚合与审计 / 性能 / 评估 / 复盘 reports 主题目录规则）
8. 真实目录结构、默认构建与测试方式
9. 若项目生成了 Claude/Codex final rule audit hook，最终回复前必须复审适用规则、已修改文件和最小验证结果；发现违反规则时先修复
10. 明确 `.ai/skills` 多端同步、configured mirrors、`sync-project-skills.sh` 和 `PostToolUse` mirror refresh 不属于当前 init 默认能力
11. 若本次已升级旧版 AI 规则文件，注明已升级到当前 init 标准
12. 当前标准只约束后续 AI coding，不主动重构未被需求触碰的既有源码
13. 禁止在 git commit message 中包含任何形式的 AI 署名行（如 `Co-Authored-By: Claude ... <noreply@anthropic.com>` 等），不限于特定模型版本
14. 规则模块化与按需加载：主控 `CLAUDE.md` 只保留红线 + 指向细则文件的索引；细则按主题拆到 `.ai/rules/<topic>.md`（仅项目有真实关注点时建立）
15. 目录级隔离：生产代码目录（如 `src/`）禁止引入 Mock 数据、伪造返回值或测试专用库；测试目录（如 `tests/`）允许 Mock / Stub / Spy
16. Linter 强制边界：记录哪些依赖 / import 边界由项目已有的 Linter / 静态检查强制（如 ESLint `no-restricted-imports`、Ruff、ArchUnit）；不擅自引入项目未采用的新工具
17. 分步开发工作流：后续 AI coding 遵循接口约定 -> 人类确认 -> 编写业务 -> 编写测试 四步，避免在单次任务里为了测试好写而改业务逻辑
18. 依赖注入隔离（栈感知）：外部 API/DB/网络依赖必须经接口或注入传入，业务函数内禁止直接实例化或发真实请求；具体写法按本项目侦察到的栈生成（后端 / Flutter / Web 等各异），侦察不到外部依赖则不写
19. 测试策略与环境防呆（栈感知）：单元测试外补集成测试（连测试库/服务、禁用 Mock）与负面边界测试；Mock 必须用环境判断包裹，按栈选写法（Node `process.env`、Flutter `kReleaseMode`/`--dart-define`、Web `import.meta.env`），禁止跨栈套用；无测试栈时只建议不强制
20. Worktree 统一路径：项目根目录创建并保留本地 `.worktree/`，所有后续 Git worktree 必须使用 `<project-root>/.worktree/<worktree-name>`；不得在项目根目录创建平级 worktree 或默认使用外部目录，根 `.gitignore` 必须包含 `/.worktree/`
21. 日志统一路径：项目根目录必须保留 `logs/`；所有新生成的运行、调试、执行、测试、构建和审计日志文件都写入该目录，不得散落到根目录或 `/docs`
22. 多仓库根 Git（条件项）：直接子 Git 仓库写入 root `.gitignore` 且不得进入 root index；根 `dt:push` 先处理子仓库，任一失败不处理 root；根无 remote 时本地 commit，根 remote 可唯一确定时同步、commit 并 push

注意：第 14 至 19 项必须按本项目实际侦察到的技术栈裁剪；第 22 项只在检测到直接子 Git 仓库时生成。未触发的条件项不写。

若启用 experimental 模式，`CLAUDE.md` 必须基于变更后重新扫描的结果生成。

## AGENTS.md

`AGENTS.md` 是面向所有 AI 工具的通用规范文件，同时可作为 Copilot 项目级配置；不包含平台特定语法。

内容要求：

- 50 到 80 行优先
- 采用纯文本描述，避免使用特定平台语法
- 不包含 Tool 调用、特定 Agent 指令等平台相关内容

必须包含：

1. 项目概览：项目名称和用途、技术栈列表、目录结构说明
2. 单一事实来源：构建文件胜过文档，目录扫描结果胜过经验推断
3. 通用编码规范：复用优先、AI vibe coding 约束、触碰文件与计划触发、最小验证、文件命名约定、提交信息格式
4. Copilot 项目级配置互斥：不同时维护 `AGENTS.md` 与 `.github/copilot-instructions.md`
5. 项目级 hook 规则：若存在 final rule audit hook，则任务收尾前重新审计规则、已修改文件与最小验证结果；`.ai/skills` 多端同步和 mirror refresh 不属于当前 init 默认能力
6. 关键路径索引：主入口、公共组件/工具类位置、文档目录结构、中文命名的任务聚合子目录约定，以及审计 / 性能 / 评估 / 复盘报告的 `docs/reports/<中文报告主题>/` 目录约定
7. 常用命令：构建、测试、运行命令
8. 规则与强制：规则按主题模块化、主文件只写索引；生产目录禁止 Mock、测试目录允许 Mock；记录由 Linter 强制的边界；遵循接口 -> 确认 -> 业务 -> 测试 的分步工作流；外部依赖经注入隔离、补集成测试与环境防呆（均按本项目栈裁剪，不适用的栈不写）
9. Worktree 位置规则：项目根目录使用本地 `.worktree/` 作为唯一默认容器，所有新 worktree 放在其子目录中，且根 `.gitignore` 忽略 `/.worktree/`
10. 日志位置规则：项目根目录使用 `logs/` 作为唯一默认日志目录，所有新生成的项目日志文件写入其中，不得散落到根目录或 `/docs`
11. 多仓库根 Git（条件项）：子仓库独立提交/推送且被 root anchored ignore；所有子仓库成功后，root 按实时 remote 状态本地提交或同步并推送

若启用 experimental 模式，`AGENTS.md` 必须基于变更后重新扫描的结果生成。

兼容升级规则：如果项目已有旧版 `AGENT.md`，提取并合并仍然有效的规则到 `AGENTS.md`，不再生成或继续维护 `AGENT.md`。

新项目硬性规则：输出文件只能是 `AGENTS.md`，不得创建 `AGENT.md`。

## Copilot Project Instructions

规则文件选择：

- 项目已有 `AGENTS.md` -> 更新 `AGENTS.md`
- 项目不存在 `AGENTS.md` -> 创建或更新 `.github/copilot-instructions.md`

无论使用哪一个，内容要求一致：

- 长度优先控制在 30 到 80 行；不能复制一整份 `CLAUDE.md`
- 只保留对所有任务都有帮助的规则
- 必须包含精简版 GP-2 至 GP-9：单一事实来源、复用优先、触碰文件与计划触发、最小验证、AI vibe coding、配置文件互斥、文档归档与中文命名规则
- 必须包含精简版 SR 维度：生产目录禁止 Mock、测试目录允许 Mock；记录由 Linter 强制的依赖边界；遵循接口 -> 确认 -> 业务 -> 测试 分步工作流；外部依赖经注入隔离、补集成测试与环境防呆（按本项目栈裁剪）；细则按需读取 `.ai/rules/<topic>.md`
- 必须包含 Worktree Location Policy：所有新 worktree 只创建在 `<project-root>/.worktree/<worktree-name>`，根 `.gitignore` 忽略 `/.worktree/`
- 必须包含 Logs Location Policy：项目根目录存在 `logs/`，所有新生成的项目日志文件统一写入 `<project-root>/logs/`
- 如果项目已安装 final rule audit hook，必须补一句：任务收尾前必须复审规则、已修改文件和最小验证结果；发现违反规则时先修复
- 检测到直接子 Git 仓库时，必须补充精简的 root/child index、顺序、失败停止和 root remote push policy

若启用 experimental 模式，Copilot 项目级配置必须基于变更后重新扫描结果更新。

## Onboarding Summary

在会话中输出一份 2 分钟可扫完的摘要，至少包含：

- 项目是什么、技术栈、关键入口、目录地图
- 一条典型请求或调用链
- 主要约定、常用命令
- 我想改哪里该看哪里
- 文档应该放在哪个 `/docs` 分类目录
- 文档文件名、任务目录名和报告主题目录名必须使用中文，标准分类目录名保持英文
- 审计 / 性能 / 评估 / 复盘类报告应放在 `docs/reports/<中文报告主题>/`；`CHANGELOG.md` 可保留在 `docs/reports/` 根下
- 任务收尾规则：若项目生成了 final rule audit hook，最终回复前必须复审适用规则、已修改文件和最小验证结果；发现违反规则时先修复
- 规则如何组织：主控文件红线 + 索引、细则在哪、生产目录禁止 Mock、哪些边界由 Linter 强制、后续写代码遵循接口 -> 确认 -> 业务 -> 测试
- worktree 统一位置：项目根 `.worktree/`，以及该目录已由根 `.gitignore` 忽略
- 日志统一位置：项目根 `logs/`，所有新生成的项目日志文件写入该目录

若启用 experimental 模式，摘要还必须额外包含：

- 本次属于 `converge` 还是 `sync`
- 变更涉及的关键目录或模块
- 风险点
- 最小验证结果
- 回滚说明摘要

## Optional Checklist Docs

只有用户明确要求时，才生成 `/docs` 下的 checklist 文档；如果项目已有语义等价目录，如 `/docs/checklists`，则复用该目录。

可选模板：

- `references/checklist-templates/api.md`
- `references/checklist-templates/dependencies.md`
- `references/checklist-templates/modules.md`

所有 checklist 都必须满足：

- 只写真实扫描到的信息
- 不保留占位字段
- 不补示例内容
- 无法验证的字段直接省略
