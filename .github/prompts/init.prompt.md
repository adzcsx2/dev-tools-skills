---
name: "init"
description: "Initialize AI project context for any codebase: detect the real stack, summarize the repo, generate or update CLAUDE.md plus Copilot project instructions, and establish a stable /docs taxonomy."
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
- 为 VS Code Copilot 增加项目级配置：如果项目已有 AGENTS.md 就更新它，否则创建或更新 .github/copilot-instructions.md
- 不要同时维护 AGENTS.md 和 .github/copilot-instructions.md 两套项目级指令
- 统一项目文档到 `/docs`，建立标准文档分类；已有语义等价目录时必须复用，不能重复创建同义目录
- 默认遵循先搜索、先复用、最小改动、局部一致

如果用户显式传入 `--experiment`，按 experimental 模式执行，并遵循这些规则：

- 只有显式传入 `--experiment` 才能进入 experimental 模式，不能自动进入
- `--experiment converge` 用于新项目第一版或迁移早期的架构收敛
- `--experiment sync` 用于已有 AI 友好架构在新增目录、模块或文件结构后的同步更新
- 如果只写 `--experiment` 而没有指定 `converge` 或 `sync`，只有在用户意图和仓库事实都明确时才能推断，否则必须先澄清
- Experimental 模式允许修改架构，包括源码移动重命名、模块拆分合并、构建配置调整、依赖组织整理和规则文件更新
- 进入 experimental 模式后，必须先输出 dry-run 预览；如果带 `--dry-run`，只预览不落盘
- Dry-run 至少包含：拟变更对象、依据、影响范围、风险、预期收益、最小验证项、回滚点
- 执行时序必须是：先常规侦察，再判定 `converge` 或 `sync`，再 dry-run，执行结构改动后重新扫描，最后才更新 CLAUDE.md 和 Copilot 项目级配置
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
- 标准文档分类至少识别 `plan`、`design`、`guide`、`api`、`modules`、`references`、`checklist`、`reports`
- 如果项目已有语义等价目录，例如 `/docs/plans`，则复用它，不要再创建 `/docs/plan`
- 如果缺少某个需要的分类且不存在语义等价目录，则创建对应分类目录
- 生成的 CLAUDE.md 和 Copilot 项目级配置必须写入文档归档规则，确保后续 AI 不在根目录或 `/docs` 下乱建同义文档目录

如果识别到特定技术栈，追加这些约束：

- Android：跟随 Java/Kotlin 现状、绑定方案、strings/colors 和既有工具类
- Flutter：跟随已有状态管理、路由、主题、网络和存储方案
- React/Web：跟随现有状态管理、样式方案、请求层和组件模式
- Python：跟随现有包结构、sync/async 风格、settings/schema/service 组织
- Java：跟随现有 DI、注解、模块和 controller/service/repository 结构

如果用户提供了参数，把它当作优先关注的项目类型或模块范围，但仍然要基于真实代码验证。
