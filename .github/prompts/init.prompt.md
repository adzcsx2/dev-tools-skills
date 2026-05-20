---
name: "init"
description: "Initialize AI project context for any codebase: detect the real stack, summarize the repo, generate or update CLAUDE.md, AGENT.md (universal AI tool rules), Copilot project instructions, bootstrap a canonical .ai/skills workspace, record configured tool mirrors, and establish a stable /docs taxonomy."
argument-hint: "[optional focus] [--experiment [converge|sync]] [--dry-run]"
agent: "agent"
model: ["GPT-5 (copilot)", "Claude Sonnet 4.5 (copilot)"]
---

分析当前工作区，按真实代码和配置完成一次跨技术栈项目初始化。

必须完成这些目标：

- 判断项目类型，可以是 Android、Flutter、React、Node.js、Python、Java 或混合仓库
- 只根据真实文件、目录和配置做结论，不要套模板
- 输出一份简洁的 onboarding 摘要，包含技术栈、关键入口、目录地图、主要约定和常用命令
- 生成或优化项目根目录的 CLAUDE.md
- 生成或优化项目根目录的 AGENT.md（通用 AI 工具规范）
- 为 VS Code Copilot 增加项目级配置：如果项目已有 AGENTS.md 就更新它，否则创建或更新 .github/copilot-instructions.md
- 不要同时维护 AGENTS.md 和 .github/copilot-instructions.md 两套项目级指令
- 建立项目级 AI framework：创建或升级 `.ai/README.md`、`.ai/skills/registry.yml`、`.ai/skills/.updates/` 和 `.ai/skills/project-skills/SKILL.md`
- 检测项目里哪些 tool mirrors 已经配置，并只为这些工具建立或刷新 project-skills 派生层
- 把 configured tool mirrors 写回 `.ai/README.md`，供后续 `dt:project-skills` 优先复用
- 项目级 skill 的唯一事实源是 `.ai/skills/`；如果后续要改 skill，只能改 canonical source，不能直接改工具导出层
- 默认建立 canonical-first 接入：`.ai/skills/` 是事实源；只有项目里已配置的工具才接收 skill 自动同步，未配置工具不创建镜像
- 统一项目文档到 `/docs`，建立标准文档分类；已有语义等价目录时必须复用，不能重复创建同义目录
- 默认遵循先搜索、先复用、最小改动、局部一致
- 如果项目曾经执行过 init，必须把旧版 CLAUDE.md、AGENT.md、AGENTS.md 或 Copilot 指令增量升级到当前 init 标准，而不是只报告已存在
- 当前 init 标准只约束后续 AI coding 行为，不要求主动重构既有源码；只有后续需求触碰到相关文件时才按新规则执行
- 生成的 CLAUDE.md、AGENT.md 和 checklist 文档必须使用英文
- 生成的 AI 规则必须面向 AI vibe coding：低 token、高密度、小文件、单职责、可检索
- 生成的 AI 规则必须包含触碰文件原则、计划触发条件和最小验证规则

如果用户显式传入 `--experiment`，按 experimental 模式执行，并遵循这些规则：

- 只有显式传入 `--experiment` 才能进入 experimental 模式，不能自动进入
- `--experiment converge` 用于新项目第一版或迁移早期的架构收敛
- `--experiment sync` 用于已有 AI 友好架构在新增目录、模块或文件结构后的同步更新
- 如果只写 `--experiment` 而没有指定 `converge` 或 `sync`，只有在用户意图和仓库事实都明确时才能推断，否则必须先澄清
- Experimental 模式允许修改架构，包括源码移动重命名、模块拆分合并、构建配置调整、依赖组织整理和规则文件更新
- 进入 experimental 模式后，必须先输出 dry-run 预览；如果带 `--dry-run`，只预览不落盘
- Dry-run 至少包含：拟变更对象、依据、影响范围、风险、预期收益、最小验证项、回滚点
- 执行时序必须是：先常规侦察，再判定 `converge` 或 `sync`，再 dry-run，执行结构改动后重新扫描，最后才更新 CLAUDE.md、AGENT.md 和 Copilot 项目级配置
- Copilot 项目级配置仍然只能维护 AGENTS.md 或 .github/copilot-instructions.md 之一，不能同时维护两份
- 所有项目级规则必须基于变更后重新扫描的结果生成，不能基于变更前状态写入
- Experimental 模式不得顺带做无关业务功能改动

必须重点检测这些内容：

- 构建与依赖文件
- 主入口和目录结构
- 文档目录与 `/docs` 下已有分类
- 命名约定、测试结构、错误处理、异步风格
- 本地复用入口，例如 base 类、公共组件、utils、service、api client、repository、config

关于文档目录，必须遵循这些规则：

- 默认文档根目录是 `/docs`
- 如果没有 `/docs`，需要创建 `/docs`
- 标准文档分类至少识别 `plan`、`product`、`design`、`guide`、`modules`、`references`、`checklist`、`reports`
- `product` 用于产品需求、PRD、用户故事、验收标准和功能范围；如果已有 `/docs/requirements`、`/docs/prd` 或语义等价目录，则复用它
- `api` 不是默认强制分类；只有项目或用户需求明确需要 API 文档分类时才创建
- 如果项目已有语义等价目录，例如 `/docs/plans`，则复用它，不要再创建 `/docs/plan`
- 如果缺少某个需要的分类且不存在语义等价目录，则创建对应分类目录
- 生成的 CLAUDE.md 和 Copilot 项目级配置必须写入文档归档规则，确保后续 AI 不在根目录或 `/docs` 下乱建同义文档目录
- 生成的 CLAUDE.md 和 AGENT.md 必须显式写入 project-skills 规则：用户说“帮我总结一下加到 skill 里”时，先做重复检查、重叠检查、融合判断，再给 proposal，确认后才写入 `.ai/skills/`
- 生成的 CLAUDE.md 和 AGENT.md 必须显式写入：项目级 skill 只同步到已配置工具；工具镜像不是事实源，不能直接手改

关于 AI vibe coding，必须写入这些规则：

- 源码文件优先控制在 500 行以内；接近或超过 500 行时，优先拆分职责清晰的组件、service、helper、module、section 或测试文件
- 不要继续向已经过大的文件追加无关逻辑；单个文件只承担一个清晰职责
- 新增代码优先放在可复用、可测试、可检索的小单元中
- 生成文件、lockfile、迁移文件、快照、vendor、第三方代码、协议生成物、框架强制入口和已有大型遗留文件不受 500 行偏好约束
- 如果修改遗留大型文件，优先最小变更；只有用户要求重构或收益明确时才拆分
- 不要为了满足 500 行偏好而主动重构未被需求触碰的既有代码；该规则用于约束后续新增代码和正在修改的文件

关于后续 AI coding 范围和验证，必须写入这些规则：

- 只修改与当前需求、bug 或用户指令直接相关的文件，不做顺手格式化、批量 import 重排、全仓库 lint fix 或无关重命名
- 工作区已有未由当前 AI 产生的改动时，必须保留并绕开，不要覆盖、回滚或重写
- 预计修改超过 3 个源码文件、跨模块、新增依赖、改 public API/数据模型/路由/权限/持久化格式，或需求不清晰时，必须先给简短计划或向用户确认
- 每次代码改动后优先运行与改动范围最小相关的 test、lint、typecheck、build 或 smoke 验证
- 没有可执行验证命令时，必须明确写 `not verified` 或同等说明，不得声称通过

如果识别到特定技术栈，追加这些约束：

- Android：跟随 Java/Kotlin 现状、绑定方案、strings/colors 和既有工具类
- Flutter：跟随已有状态管理、路由、主题、网络和存储方案
- React/Web：跟随现有状态管理、样式方案、请求层和组件模式
- Python：跟随现有包结构、sync/async 风格、settings/schema/service 组织
- Java：跟随现有 DI、注解、模块和 controller/service/repository 结构

如果用户提供了参数，把它当作优先关注的项目类型或模块范围，但仍然要基于真实代码验证。
