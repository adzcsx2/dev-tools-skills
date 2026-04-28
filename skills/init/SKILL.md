---
name: dt:init
description: "Initialize AI project context for any codebase. Detect Android, Flutter, React, Python, Java, Node.js and other stacks from real files, then generate or update CLAUDE.md, AGENT.md (universal AI tool rules), Copilot project instructions, a concise onboarding summary, establish a /docs taxonomy, and optionally create verified checklist docs."
argument-hint: "[optional focus] [--experiment [converge|sync]] [--dry-run]"
origin: dev-tools-skills
---

> Language Requirements
>
> - **ALL generated documentation files (CLAUDE.md, AGENT.md, checklists) MUST be in English**
> - User-facing responses and comments should follow user's preferred language
> - AI internal analysis may use English
> - All generated files must use UTF-8 encoding
> - Output should be concise, clear, and actionable

# init Skill

统一的跨技术栈项目初始化入口。用于第一次进入一个仓库时，基于真实代码和配置生成 AI 可直接消费的项目级规则，而不是套模板。

## Trigger

```text
/dt:init [optional focus] [--experiment [converge|sync]] [--dry-run]
```

## When to Use

- 第一次接手一个陌生仓库
- 需要为项目补充或优化 CLAUDE.md
- 需要让 VS Code Copilot 直接读取项目级规则
- 需要输出可快速浏览的代码库 onboarding 摘要
- 需要为 Android、Flutter、React、Python、Java、Node.js 等项目建立统一 AI 工作约束
- 项目曾经执行过 init，但需要把 AI 规则文件升级到当前 init skill 的最新 AI 工作标准
- 新项目框架搭建后的第一个版本，需要做 AI 友好架构收敛
- 项目已经采用该架构，但新增了目录、模块或文件结构，需要同步更新 AI 规则与路径映射

## Command Parameters

- 无参数：标准 init。只做侦察、总结和规则文件生成或优化，不允许主动改架构；如果项目已有旧版 init 产物，必须增量升级规则文件到当前 init skill 标准
- `[optional focus]`：可选关注模块、技术栈或目录范围，但所有结论仍必须由真实代码验证
- `--experiment converge`：启用 experimental 架构收敛模式，用于新项目第一版或迁移早期对已落地结构做统一
- `--experiment sync`：启用 experimental 同步更新模式，用于已有 AI 友好架构在新增目录、模块或调用链后做规则与结构同步
- `--experiment`：只允许使用这个开关名进入 experimental 模式，不接受其他别名
- `--dry-run`：只输出侦察结果、变更预览、风险、验证项和回滚点，不落盘、不移动文件、不改配置

## Execution Modes

- 标准模式：不带 `--experiment`。按常规 init 流程工作，不允许架构级改动
- Experimental 模式：只有显式传入 `--experiment` 才能启用，绝不能自动进入
- 如果只写了 `--experiment`，但没有指定 `converge` 或 `sync`，只有在用户意图和仓库事实都明确时才能推断；无法明确时，必须先澄清
- Experimental 模式可以修改架构，但仍然必须基于真实代码、单一事实来源、最小必要改动和可验证结果

## Core Goals

最终结果必须同时服务 Claude Code 和 VS Code Copilot，并满足以下目标：

1. 重点是 AI 工作规则，不是项目介绍文档
2. 所有结论必须来自真实代码、配置和目录扫描，不得凭经验补全
3. 优先帮助 AI 做正确决策：先搜索、先复用、最小改动、局部一致
4. 同时覆盖通用工程约束和技术栈特有约束
5. 默认输出应低 token、高密度、可执行
6. 若已有规则文件，优先增量优化，不直接覆盖
7. Experimental 模式必须显式启用，并且必须先预览、后执行、最后重扫并更新规则
8. 必须建立并固化 `/docs` 文档分类规则，避免后续 AI 乱建文档目录
9. 重复执行 init 时，必须把旧版 AI 规则文件升级到当前 skill 的最新标准，而不是只报告“已存在”
10. 当前 init 标准约束后续 AI coding 行为，不要求主动重构既有源码；只有后续需求触碰到相关文件时才按新规则执行

## Required Outputs

本技能默认产出以下内容：

1. 会话内 onboarding 摘要
2. 项目根目录 CLAUDE.md
3. 项目根目录 AGENT.md（通用 AI 工具规范）
4. Copilot 可读取的项目级配置
5. `/docs` 文档根目录及必要的分类目录骨架

Copilot 配置规则：

- 如果项目已存在 AGENTS.md，则优先更新 AGENTS.md，不再额外创建 .github/copilot-instructions.md
- 如果项目不存在 AGENTS.md，则创建或更新 .github/copilot-instructions.md
- 不要同时维护 AGENTS.md 和 .github/copilot-instructions.md 两套项目级指令文件，避免冲突

## Phase 1. Reconnaissance

先做并行侦察，不要一开始就通读所有文件。至少扫描以下信号：

```text
1. 包管理与构建清单
   package.json, pnpm-workspace.yaml, yarn.lock, bun.lockb
   pyproject.toml, requirements.txt, poetry.lock, Pipfile
   pom.xml, build.gradle, build.gradle.kts, settings.gradle, settings.gradle.kts
   Cargo.toml, go.mod, pubspec.yaml

2. 框架指纹
   next.config.*, vite.config.*, angular.json, nuxt.config.*
   manage.py, settings.py, flask app, fastapi main, spring boot main
   AndroidManifest.xml, app/src/main/, lib/main.dart

3. 入口点
   main.*, index.*, app.*, server.*, src/main/, cmd/, lib/main.dart

4. 目录快照
   顶层和二级目录，忽略 .git, node_modules, dist, build, target,
   .next, .dart_tool, .gradle, __pycache__, vendor

5. 文档目录
   docs/, doc/, documentation/, wiki/ 及 /docs 下现有分类目录
   识别语义等价目录，例如 plan/plans、guide/guides、reference/references

6. 配置与工具链
   tsconfig.json, eslint/prettier 配置, analysis_options.yaml,
   pytest.ini, tox.ini, mypy.ini, Dockerfile, docker-compose*,
   .github/workflows/, Makefile, CI 配置

7. 测试结构
   tests/, test/, __tests__/, integration_test/, e2e/, src/test/, src/androidTest/
   *.spec.*, *.test.*, *_test.py, *_test.go
```

## Phase 2. Stack Detection

必须根据真实文件判断项目类型，可同时识别多种技术栈共存。至少覆盖以下分支：

### 2.1 Android

识别信号：

- settings.gradle 或 settings.gradle.kts
- build.gradle 或 build.gradle.kts
- AndroidManifest.xml

额外必须检测：

- Java / Kotlin 混合情况
- ButterKnife / ViewBinding / DataBinding 使用情况
- BaseActivity / BaseFragment / Adapter / Http / Utils 等复用入口
- 资源、日志、Toast、存储等强约束工具类

### 2.2 Flutter

识别信号：

- pubspec.yaml
- lib/main.dart
- android/ 或 ios/ 目录

额外必须检测：

- 状态管理方案及混用情况
- 路由、主题、网络、存储方案
- 公共 Widget / Service / Utils / Base 类入口

### 2.3 Web / Node.js / React

识别信号：

- package.json
- next.config._, vite.config._, webpack 配置
- src/, app/, pages/, server/ 目录

额外必须检测：

- React / Next.js / Vue / Express / NestJS 等实际框架
- 路由、状态管理、请求层、样式方案
- UI 组件库、shared hooks、utils、api client 复用入口
- 不要因为看到少量 Zustand、Redux、React Query 就自动推断完整架构

### 2.4 Python

识别信号：

- pyproject.toml, requirements.txt, setup.py, manage.py
- app/, src/, project/ 等源码目录

额外必须检测：

- Django / FastAPI / Flask / Celery / Click 等实际框架
- 虚拟环境与依赖管理方式
- settings、schema、service、repository、client 组织方式
- 同步 / 异步风格与 typing 使用情况

### 2.5 Java / JVM

识别信号：

- pom.xml
- build.gradle / build.gradle.kts
- src/main/java, src/main/kotlin

额外必须检测：

- Spring Boot / Spring MVC / plain Java / Kotlin JVM
- controller / service / repository / config 分层是否真实存在
- DI、注解风格、模块结构、测试目录

### 2.6 其他项目

如果不是以上典型栈，也必须输出：

- 能确认的语言与构建工具
- 主入口和关键目录
- 现有命名、测试、依赖和错误处理模式
- 未确认部分明确标注 unknown，不要猜测

## Phase 3. Single Sources of Truth

必须显式建立单一事实来源，避免文档与代码冲突：

- 构建、版本、依赖：以真实构建文件为准
- 模块列表：以 settings.gradle、workspace 配置、package workspaces、monorepo 配置等为准
- 项目特有规则：以已有 CLAUDE.md、AGENTS.md、.github/copilot-instructions.md、README、开发规范文档为准
- 真实目录结构：以源码扫描结果为准
- 默认命令：以 package scripts、Makefile、Gradle、Maven、Flutter、Python 工具配置为准
- 若文档与代码冲突，以代码和构建配置为准

## Phase 3.5 Documentation Taxonomy

必须把项目文档统一收敛到 `/docs` 下，并建立语义优先的分类映射。

### 3.5.1 Docs Root

- 默认文档根目录是 `/docs`
- 如果仓库没有 `/docs`，需要创建 `/docs`
- 如果仓库已有 `doc/`、`documentation/`、`wiki/` 等目录，不要直接删除；先判断是否已承担主文档目录职责
- 只要项目最终仍缺少 `/docs`，就必须创建 `/docs` 作为后续 AI 的标准文档入口

### 3.5.2 Standard Categories

**默认标准分类目录（必须创建，若不存在）**：

- `plan`：计划、方案、roadmap、todo
- `product`：产品需求、PRD、用户故事、验收标准、功能范围
- `design`：设计、架构、ADR、spec
- `guide`：接入、使用、操作、runbook
- `modules`：模块说明、目录边界、组件总览
- `references`：参考资料、术语、索引
- `checklist`：核对清单、审计清单、初始化清单
- `reports`：测试、审计、性能、复盘报告

如果用户、团队规范或仓库现状明确存在额外分类语义，也必须纳入分类表；例如用户明确要求 `hello` 是一个文档分类，而项目中没有语义等价目录时，就创建 `/docs/hello`。

**注意**：`api` 不再作为默认强制分类，可根据项目需要按需创建。

### 3.5.3 Semantic Folder Mapping

分类以语义为准，不以字面完全一致为准。

- 如果标准分类已有语义等价目录，则复用现有目录，不再重复创建
- 例如已有 `/docs/plans`，就不要再创建 `/docs/plan`
- 例如已有 `/docs/requirements`、`/docs/prd` 或 `/docs/product-docs`，就不要再创建 `/docs/product`
- 例如已有 `/docs/references`，就不要再创建 `/docs/reference`
- 例如已有 `/docs/guides`，就不要再创建 `/docs/guide`
- 只有在找不到语义等价目录时，才创建标准目录名

### 3.5.4 Creation Rules

**强制要求：必须创建缺失的标准分类目录**

- 若 `/docs` 不存在，创建 `/docs`
- 若 `/docs` 存在但缺少分类层级，**必须立即创建缺失的标准分类目录**，不得只列出不创建
- 标准分类目录：`plan`、`product`、`design`、`guide`、`modules`、`references`、`checklist`、`reports`
- 若项目已有分类但命名不完全标准，优先保留原目录并记录映射，不强制重命名
- 不要因为同时存在 `plan` 和 `plans` 的可能性就创建两个目录
- 不要在仓库根目录、临时目录或任意子模块下随意散落新文档，除非项目已有明确且稳定的非 `/docs` 约定

**执行要求**：
1. 识别 `/docs` 下已存在的目录
2. 对比标准分类列表，找出缺失目录
3. **使用 Bash 工具执行 `mkdir -p` 创建所有缺失目录**
4. 在输出中明确列出已创建的目录
5. 不得只输出"缺失目录"列表而不执行创建操作

### 3.5.5 Future AI Rules

初始化后，生成的 CLAUDE.md 和 Copilot 项目级配置必须显式写入这些规则：

- 新文档默认放在 `/docs` 下
- 新建文档前，先检查 `/docs` 及其现有分类是否已有语义等价目录
- 已有语义等价目录时，必须复用，不能再创建同义新目录
- 只有在分类语义明确且不存在等价目录时，才允许创建新的文档分类目录
- 默认不要在仓库根目录新增零散 `.md` 文档
- 如果文档归类语义不明确，先搜索现有文档结构，再决定归档位置

## Phase 4. Convention Detection

必须检测而不是猜测：

### 4.1 命名与组织

- 文件命名风格：kebab-case、camelCase、PascalCase、snake_case
- 类、组件、模块命名模式
- 测试命名模式
- feature-first、layer-first、package-first 或混合目录结构

### 4.2 代码模式

- 错误处理方式
- 依赖注入还是直接 import / new
- 异步模式
- 状态管理或数据流风格
- 是否存在历史代码与新代码混用

### 4.3 Git 约定

- 最近提交信息风格
- 分支命名模式
- PR 合并方式
- 如果 git 历史不存在或过浅，明确写 unavailable

## Phase 5. Mandatory Reuse Rules

无论什么技术栈，生成的 AI 配置都必须前置固化这些规则：

- 修改前先搜索目标文件同目录和同类实现
- 优先复用已有实现、公共工具和既有调用链
- 优先最小改动，不做无关重构
- 保持目标目录、相邻代码和现有风格一致
- 不主动引入新架构、新封装、新库，除非用户明确要求
- 局部已有旧写法或混合写法时，优先跟随局部，而不是强行全局统一

## Phase 5.5 AI Vibe Coding Constraints

生成的 AI 配置必须面向长期 AI coding 使用，降低上下文成本并减少单文件失控。

必须写入以下通用约束：

- 源码文件优先控制在 500 行以内；接近或超过 500 行时，优先拆分职责清晰的组件、service、helper、module、section 或测试文件
- 不要继续向已经过大的文件追加无关逻辑；除非当前变更本身是局部 bug fix 或必须保持框架入口完整
- 单个文件只承担一个清晰职责；跨职责逻辑应按项目现有目录结构拆分
- 新增代码优先放在可复用、可测试、可检索的小单元中，避免大段内联实现
- AI 面向文档必须低 token、高密度、可锚定；长文档应拆分到 `/docs` 对应分类，并通过索引互链
- 例外必须明确：生成文件、lockfile、迁移文件、快照、vendor、第三方代码、协议生成物、框架强制入口和已有大型遗留文件不受 500 行偏好约束
- 如果修改遗留大型文件，优先做最小变更；只有在用户要求重构或存在明确收益时才拆分
- 不要为了满足 500 行偏好而主动重构未被需求触碰的既有代码；该规则用于约束后续新增代码和正在修改的文件

生成 CLAUDE.md、AGENT.md、AGENTS.md 或 .github/copilot-instructions.md 时，必须用精简语言包含这些约束，不得因此突破各自长度预算。

## Phase 5.6 Change Scope, Planning, and Verification

生成的 AI 配置必须固化后续 coding 的范围控制和验证规则。

### 5.6.1 Touched-File Discipline

- 只修改与当前需求、bug 或用户指令直接相关的文件
- 不做顺手格式化、批量 import 重排、全仓库 lint fix 或无关重命名，除非用户明确要求
- 如果工作区已有未由当前 AI 产生的改动，必须保留并绕开；不要覆盖、回滚或重写用户改动
- 修改大文件时只触碰必要片段；不要借机整理整文件
- 新增文件前先确认现有目录、模块或工具是否已经能承载该职责

### 5.6.2 Plan-First Triggers

后续 AI coding 遇到以下情况时，必须先给出简短计划或向用户确认，再执行：

- 预计修改超过 3 个源码文件
- 跨模块、跨包、跨服务或跨端改动
- 新增依赖、构建配置、脚本、CI 或运行时配置
- 改动 public API、数据模型、路由、权限、持久化格式或迁移逻辑
- 需要重构、移动文件、拆分模块或改变目录边界
- 需求、验收标准或影响范围不清晰

### 5.6.3 Standard Verification

- 每次代码改动后优先运行与改动范围最小相关的 test、lint、typecheck、build 或 smoke 验证
- 如果仓库提供默认验证命令，必须在生成的 AI 规则文件中记录
- 如果没有可执行验证命令，必须明确写 `not verified` 或同等说明，不得声称通过
- 文档-only 改动至少检查链接、路径、分类和规则文件一致性
- 验证失败时，优先修复当前改动引入的问题；不要顺手修复无关历史问题

## Phase 6. Stack-Specific Local Consistency Rules

### Android 必须额外写入

- Java 文件优先延续 Java，Kotlin 文件优先延续 Kotlin
- ButterKnife、ViewBinding、DataBinding 并存时，优先跟随目标文件和同目录模式
- 文本优先复用 strings.xml，颜色优先复用 colors.xml
- Toast、日志、SharedPreferences、常量、Utils 优先复用既有封装

### Flutter 必须额外写入

- 已有 setState 的页面优先延续 setState
- 已使用 Provider、BLoC、Riverpod、GetX 的模块优先延续原方案
- 文本优先走既有国际化方案
- 样式、路由、网络、存储优先复用既有封装

### Web / React 必须额外写入

- 已有状态管理、样式方案、请求层优先延续原方案
- 优先复用现有组件、hooks、api client、schema、constants
- 不主动把 CSS Modules 改成 Tailwind，也不主动把 REST 改成 GraphQL 或 tRPC

### Python 必须额外写入

- 优先沿用现有包结构、依赖管理、格式化和测试方案
- 已有 sync 或 async 风格优先保持一致
- 优先复用 settings、client、service、schema、repository 等既有模块

### Java / JVM 必须额外写入

- 优先沿用已有 DI、注解、模块和测试组织方式
- 不主动引入新的分层或响应式框架
- 优先复用现有 controller、service、repository、util、config 入口

## Phase 6.5 Experimental Architecture Mode

本阶段只在显式传入 `--experiment` 时启用，不能自动进入。

### 6.5.1 Submodes

- `converge`：用于新项目第一版、迁移早期或结构混杂阶段，对已落地的目录、模块、依赖和规则入口做架构收敛
- `sync`：用于已有 AI 友好架构在新增目录、模块、文件结构或调用链后做同步更新，不重新发明架构，只让代码事实与规则文件重新一致

### 6.5.2 Applicability

只有同时满足以下条件时，才允许进入 experimental 模式：

- 仓库中存在真实代码、目录、模块、构建配置或调用链证据
- 可以判定本次属于 `converge` 或 `sync` 之一
- 影响范围可描述，且可以给出 dry-run 预览
- 可以定义最小验证项
- 用户已显式传入 `--experiment`

### 6.5.3 Forbidden Conditions

出现以下任一情况时，不得执行 experimental 架构改动：

- 用户未传入 `--experiment`
- 只有口头目标，没有真实代码或构建证据
- 无法判定 `converge` 还是 `sync`
- 无法建立单一事实来源
- 无法给出 dry-run 预览
- 无法给出回滚说明
- 任务本质是新增业务功能，而不是结构收敛或同步更新
- 改动会导致同时维护 AGENTS.md 和 .github/copilot-instructions.md
- 无法提供任何最小验证路径，且风险高到无法接受

### 6.5.4 Allowed Change Scope

Experimental 模式允许以下改动：

- 源码移动与重命名
- 模块拆分与合并
- 构建配置调整
- 依赖组织整理
- 导出关系、路径映射、入口索引更新
- CLAUDE.md 更新
- AGENTS.md 或 .github/copilot-instructions.md 二选一更新
- 与架构收敛或同步更新直接相关的测试、文档和配置引用修正

Experimental 模式不允许以下改动：

- 顺带开发无关业务功能
- 借机重写不相关模块
- 把局部问题扩大成全仓库无边界重构
- 在没有代码证据的前提下引入理想化新架构

### 6.5.5 Dry-Run Requirements

只要进入 experimental 模式，就必须先给出 dry-run 预览；`--dry-run` 只是在此基础上停止执行，不落盘。

Dry-run 至少必须包含：

- 拟变更对象
- 每项变更的代码或配置依据
- 影响范围
- 潜在风险
- 预期收益
- 最小验证项
- 回滚点

如果传入 `--dry-run`：

- 只输出侦察结论、变更预览和回滚说明
- 不创建、不修改、不移动任何文件
- 不更新 CLAUDE.md
- 不更新 AGENTS.md
- 不更新 .github/copilot-instructions.md

### 6.5.6 Execution Order

Experimental 模式必须遵循以下时序：

1. 先完成 Phase 1 到 Phase 6 的常规侦察和局部一致性判断
2. 判定本次属于 `converge` 或 `sync`
3. 输出 dry-run 预览
4. 如果带 `--dry-run`，到此结束，不落盘
5. 先更新构建与模块声明，再执行源码移动、重命名、拆分或合并
6. 再更新依赖组织、导出关系、路径映射和相关引用
7. 完成结构改动后，重新扫描项目事实
8. 只基于变更后重新扫描的结果，更新 CLAUDE.md 与 Copilot 项目级配置
9. 完成最小验证
10. 输出回滚说明、验证结果和 residual risk

### 6.5.7 Config Update Rules

- Claude 侧更新项目根目录 CLAUDE.md
- Copilot 侧只能更新 AGENTS.md 或 .github/copilot-instructions.md 其中之一
- 如果项目已存在 AGENTS.md，则只更新 AGENTS.md
- 如果项目不存在 AGENTS.md，则只更新 .github/copilot-instructions.md
- 不要同时维护 AGENTS.md 和 .github/copilot-instructions.md
- Experimental 模式下，所有项目级规则必须基于变更后重新扫描结果生成，不能基于变更前状态写入

### 6.5.8 Rollback Requirements

Experimental 模式必须输出回滚说明。

回滚说明至少包含：

- 回滚单位
- 受影响文件类型
- 已移动或重命名的路径
- 已调整的构建配置
- 已调整的依赖组织
- 已更新的 CLAUDE.md 与 Copilot 规则文件
- 需要反向恢复的关键步骤
- 无法自动回滚的部分

如果无法自动回滚，必须明确说明：

- 哪些改动只能人工回滚
- 哪些状态在执行后不可无损恢复
- 哪些风险需要由用户决定是否接受

### 6.5.9 Minimum Verification

Experimental 模式至少完成以下四层验证：

- 构建层：确认模块声明、源码路径、依赖关系、构建入口未失配
- 引用层：确认关键 import、导出关系、入口文件、关键调用链未断裂
- 规则层：确认 CLAUDE.md 与 Copilot 项目级配置和变更后结构一致
- 范围层：确认没有越界改动到无关业务逻辑或无关目录

如果仓库存在默认验证命令：

- 优先运行项目已有构建、测试、lint 或最小 smoke 验证命令
- `converge` 模式至少运行一个可代表结构正确性的验证
- `sync` 模式至少运行与受影响范围相关的最小验证

如果仓库没有可执行验证命令：

- 必须明确说明未验证
- 不得把“未验证”写成“已通过”

## Phase 7. Generate Files

### 7.1 CLAUDE.md

默认行为是优化已有 CLAUDE.md，不是全量重写。只有以下情况才接近重写：

- 项目不存在 CLAUDE.md
- 现有内容严重过时且与代码冲突
- 用户明确要求重写

**Language Requirement**: CLAUDE.md MUST be written in English.

生成结果要求：

- 60 到 120 行优先
- 采用规则 + 路径索引的高密度写法
- 不复制 README 大段内容
- 不展开完整依赖表、完整构建教程、完整架构宣讲

必须显式包含：

1. AI 工作原则
2. 单一事实来源
3. 复用优先级
4. 局部一致性规则
5. AI vibe coding 约束（低 token、小文件、单职责、500 行偏好与例外）
6. 触碰文件原则、计划触发条件和最小验证规则
7. 真实目录结构
8. 默认构建与测试方式
9. 文档索引
10. `/docs` 文档根目录、分类映射和新文档落位规则
11. 若本仓库已有旧版 init 产物，本次已升级 AI 规则文件到当前 init skill 标准的说明
12. 当前标准只约束后续 AI coding，不主动要求重构未被需求触碰的既有源码

Experimental 模式补充要求：

- CLAUDE.md 必须基于变更后重新扫描的结果生成
- 不得根据变更前结构写入 experimental 规则
- `converge` 模式写入收敛后的主规则与目录边界
- `sync` 模式只同步已在代码中稳定出现的结构事实

文档规则补充要求：

- 必须写明 `/docs` 是否为标准文档根目录
- 必须写明标准分类到现有目录的映射，例如 `plan -> /docs/plans`
- 必须写明后续新增文档先复用现有映射目录，不能创建同义重复目录
- **必须在初始化时创建缺失的标准分类目录**，不得只列出不创建
- 在 CLAUDE.md 中明确列出已创建的目录和复用的现有目录映射

### 7.2 AGENT.md

AGENT.md 是面向所有 AI 工具的通用规范文件，不包含平台特定语法。

**生成位置**：项目根目录 AGENT.md

**Language Requirement**: AGENT.md MUST be written in English.

**内容要求**：

- 50 到 80 行优先
- 采用纯文本描述，避免使用特定平台语法
- 不包含 Tool 调用、特定 Agent 指令等平台相关内容

**必须包含**：

1. **项目概览**
   - 项目名称和用途
   - 技术栈列表
   - 目录结构说明

2. **通用编码规范**
   - 文件命名约定
   - 代码风格规则
   - AI vibe coding 约束：小文件、单职责、500 行偏好与例外
   - 触碰文件原则、计划触发条件和最小验证规则
   - 测试要求
   - 提交信息格式

3. **复用优先原则**（与 CLAUDE.md 保持一致）
   - 先搜索再修改
   - 保持局部一致性
   - 最小改动原则
   - 不主动引入新架构

4. **关键路径索引**
   - 主入口文件位置
   - 公共组件/工具类位置
   - 文档目录结构

5. **常用命令**
   - 构建、测试、运行命令

**与 CLAUDE.md 的区别**：

| 特性 | CLAUDE.md | AGENT.md |
|------|-----------|----------|
| 目标平台 | Claude Code | 所有 AI 工具 |
| 语法 | 包含 Claude 特定指令 | 纯文本，无平台语法 |
| 长度 | 60-120 行 | 50-80 行 |
| 内容密度 | 高密度规则+路径索引 | 通用描述+规范 |

**生成时机**：

- 在 CLAUDE.md 生成之后
- 在 Copilot 配置生成之前
- 如果项目已存在 AGENT.md，优先增量优化而非全量覆盖

**Experimental 模式补充要求**：

- AGENT.md 必须基于变更后重新扫描的结果生成
- 与 CLAUDE.md 保持一致的项目事实
- 避免引入 experimental 阶段的临时状态描述

### 7.3 Copilot 项目级配置

**Language Requirement**: Copilot project-level configuration MUST be written in English.

如果使用 .github/copilot-instructions.md：

- 长度优先控制在 30 到 80 行
- 内容比 CLAUDE.md 更短，但不能丢掉高约束规则
- 只保留对所有任务都有帮助的规则
- 不能复制一整份 CLAUDE.md
- 必须包含精简版 AI vibe coding 约束：优先小文件、单职责、接近 500 行时拆分、生成/锁定/迁移等文件例外
- 必须包含精简版触碰文件、计划触发和最小验证规则
- 必须包含精简版文档归档规则：文档放 `/docs`、先查现有分类、避免创建同义目录

如果项目已有 AGENTS.md：

- 优先在 AGENTS.md 中补充同等项目规则
- 不再新增 .github/copilot-instructions.md
- 同样要补入 AI vibe coding 约束
- 同样要补入触碰文件、计划触发和最小验证规则
- 同样要补入文档归档和目录复用规则

Experimental 模式补充要求：

- Copilot 项目级配置必须基于变更后重新扫描结果更新
- 仍然只能维护 AGENTS.md 或 .github/copilot-instructions.md 之一
- 不能在 experimental 模式下同时更新两份 Copilot 规则文件

### 7.4 Onboarding 摘要

在会话中输出一份 2 分钟可扫完的摘要，至少包含：

- 项目是什么
- 技术栈
- 关键入口
- 目录地图
- 一条典型请求或调用链
- 主要约定
- 常用命令
- 我想改哪里该看哪里
- 文档应该放在哪个 `/docs` 分类目录

如果启用 experimental 模式，摘要还必须额外包含：

- 本次属于 `converge` 还是 `sync`
- 变更涉及的关键目录或模块
- 风险点
- 最小验证结果
- 回滚说明摘要

## Phase 8. Optional Checklist Docs

**Language Requirement**: All checklist documentation MUST be written in English.

只有用户明确要求时，才生成 `/docs` 下的 checklist 文档；如果项目已有语义等价目录，如 `/docs/checklists`，则复用该目录，不再创建 `/docs/checklist`。可选模板：

- references/checklist-templates/api.md
- references/checklist-templates/dependencies.md
- references/checklist-templates/modules.md

所有 checklist 都必须满足：

- 只写真实扫描到的信息
- 不保留占位字段
- 不补示例内容
- 无法验证的字段直接省略

## Best Practices

1. 先并行侦察，再定向读取，避免一上来通读整个仓库
2. 优先增强已有规则文件，不要无脑覆盖
3. 结论必须能在代码或配置中找到证据
4. 统一流程要服务所有项目，但输出内容必须跟随具体栈变化
5. 不确定的地方明确写 unknown，优先正确而不是看起来完整
6. Experimental 模式先做 dry-run，再做结构改动，再做变更后重扫
7. 能用 `sync` 解决时，不要滥用 `converge`
8. 文档分类先看语义映射，再决定目录名，不要机械按单数或复数重复建目录

## Anti-Patterns to Avoid

- 把 init 写成 Android-only 或 Flutter-only 流程
- 看到框架关键词就直接套现代模板
- 同时生成 AGENTS.md 和 .github/copilot-instructions.md
- 把 CLAUDE.md 写成面向人的长篇项目介绍
- 把 Copilot 指令文件写成 CLAUDE.md 的完整拷贝
- 生成任何未经代码验证的 checklist 条目
- 未传入 `--experiment` 却自动进入 experimental 模式
- 还在侦察阶段就开始移动文件或改架构
- 未完成最小验证就先写入 CLAUDE.md 或 Copilot 项目级配置
- 在 `sync` 模式下顺带做大规模架构重构
- 在 `converge` 模式下夹带无关业务功能开发
- 基于变更前状态生成 experimental 规则文件
- 看到 `/docs/plans` 还额外创建 `/docs/plan`
- 在已有 `/docs` 分类结构时，仍然把新文档丢到仓库根目录
- 未检查现有语义等价目录就新建 `/docs` 子目录
- **只列出缺失目录而不实际创建（违反强制要求）**
- 项目已有旧版 CLAUDE.md、AGENT.md 或 Copilot 指令时，因为文件已存在就跳过规则升级
- 重复执行 init 时，把“升级旧版 AI 规则标准”误解为要主动改造项目源码
- 把 500 行偏好误写成对生成文件、lockfile、迁移、vendor 或框架入口的无条件硬限制
- 重复执行 init 时，为了满足新标准而主动改造未被需求触碰的既有源码
- 标准模式生成规则文件后，不记录任何后续 coding 验证方式
- AI 后续执行小需求时，顺手格式化、重排或修复无关文件
- 跨模块或高风险改动不先计划就直接执行
