---
name: dt:init
description: "Initialize AI project context for any codebase. Detect Android, Flutter, React, Python, Java, Node.js and other stacks from real files, then generate or update CLAUDE.md, AGENT.md (universal AI tool rules), Copilot project instructions, bootstrap a canonical .ai/skills workspace for project-level skills, produce a concise onboarding summary, establish a /docs taxonomy, and optionally create verified checklist docs."
argument-hint: "[optional focus] [--experiment [converge|sync]] [--dry-run]"
origin: dev-tools-skills
---

> Language Requirements
>
> - **ALL generated documentation files (CLAUDE.md, AGENT.md, checklists) MUST be in English**
> - User-facing responses and comments should follow user's preferred language
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
2. 同时覆盖通用工程约束和技术栈特有约束
3. 所有结论来自真实代码（→ GP-1）
4. 优先增量升级已有规则文件，不直接覆盖（→ GP-10）
5. `--experiment` 必须显式启用，绝不自动进入（详见 Execution Modes 与 Phase 6.5）
6. 生成的 CLAUDE.md、AGENT.md、Copilot 配置必须完整包含 GP-2 至 GP-9

## Required Outputs

本技能默认产出以下内容：

1. 会话内 onboarding 摘要
2. 项目根目录 CLAUDE.md
3. 项目根目录 AGENT.md（通用 AI 工具规范）
4. Copilot 可读取的项目级配置
5. `.ai/README.md` 与 `.ai/skills/` 项目级 AI framework 骨架
6. `/docs` 文档根目录及必要的分类目录骨架

Copilot 配置文件选择规则（→ GP-8）。

---

## § General Principles

本节集中定义所有跨阶段复用的原则。各 Phase 和输出章节不再重复陈述，仅按编号引用。

### GP-1: Evidence-Only Conclusions

所有结论必须来自真实代码、配置文件或目录扫描。不推断、不猜测、不凭经验补全。

### GP-2: Single Sources of Truth

- 构建、版本、依赖：以真实构建文件为准
- 模块列表：以 settings.gradle、workspace 配置、package workspaces、monorepo 配置等为准
- 项目特有规则：以已有 CLAUDE.md、AGENTS.md、.github/copilot-instructions.md、README、开发规范文档为准
- 真实目录结构：以源码扫描结果为准
- 默认命令：以 package scripts、Makefile、Gradle、Maven、Flutter、Python 工具配置为准
- 项目级 canonical skills：以 `.ai/skills/` 为唯一事实源；工具导出层不是事实源
- 若文档与代码冲突，以代码和构建配置为准

### GP-3: Reuse-First

- 修改前先搜索目标文件同目录和同类实现
- 优先复用已有实现、公共工具和既有调用链
- 优先最小改动，不做无关重构
- 保持目标目录、相邻代码和现有风格一致
- 不主动引入新架构、新封装、新库，除非用户明确要求
- 局部已有旧写法或混合写法时，优先跟随局部，而不是强行全局统一

### GP-4: File-Touch Discipline

- 只修改与当前需求、bug 或用户指令直接相关的文件
- 不做顺手格式化、批量 import 重排、全仓库 lint fix 或无关重命名，除非用户明确要求
- 如果工作区已有未由当前 AI 产生的改动，必须保留并绕开；不要覆盖、回滚或重写用户改动
- 修改大文件时只触碰必要片段；不要借机整理整文件
- 新增文件前先确认现有目录、模块或工具是否已经能承载该职责

### GP-5: Plan-First Triggers

后续 AI coding 遇到以下情况时，必须先给出简短计划或向用户确认，再执行：

- 预计修改超过 3 个源码文件
- 跨模块、跨包、跨服务或跨端改动
- 新增依赖、构建配置、脚本、CI 或运行时配置
- 改动 public API、数据模型、路由、权限、持久化格式或迁移逻辑
- 需要重构、移动文件、拆分模块或改变目录边界
- 需求、验收标准或影响范围不清晰

### GP-6: Minimal Verification

- 每次代码改动后优先运行与改动范围最小相关的 test、lint、typecheck、build 或 smoke 验证
- 如果仓库提供默认验证命令，必须在生成的 AI 规则文件中记录
- 如果没有可执行验证命令，必须明确写 `not verified` 或同等说明，不得声称通过
- 文档-only 改动至少检查链接、路径、分类和规则文件一致性
- 验证失败时，优先修复当前改动引入的问题；不要顺手修复无关历史问题

### GP-7: AI Vibe Coding Constraints

- 源码文件优先控制在 500 行以内；接近或超过 500 行时，优先拆分职责清晰的组件、service、helper、module 或测试文件
- 不要继续向已经过大的文件追加无关逻辑；除非当前变更本身是局部 bug fix 或必须保持框架入口完整
- 单个文件只承担一个清晰职责；跨职责逻辑应按项目现有目录结构拆分
- 新增代码优先放在可复用、可测试、可检索的小单元中，避免大段内联实现
- AI 面向文档必须低 token、高密度、可锚定；长文档应拆分到 `/docs` 对应分类，并通过索引互链
- 例外（不受 500 行约束）：生成文件、lockfile、迁移文件、快照、vendor、第三方代码、协议生成物、框架强制入口和已有大型遗留文件
- 不要为了满足 500 行偏好而主动重构未被需求触碰的既有代码

### GP-8: Copilot Config Exclusivity

- 项目已存在 AGENTS.md → 只更新 AGENTS.md，不创建 .github/copilot-instructions.md
- 项目不存在 AGENTS.md → 创建或更新 .github/copilot-instructions.md
- 永远不同时维护两份 Copilot 项目级指令文件

### GP-9: Documentation Taxonomy

**规则根**：默认文档根目录是 `/docs`，新文档默认放 `/docs` 下。

**标准分类**：`plan`、`product`、`design`、`guide`、`modules`、`references`、`checklist`、`reports`。

**语义优先**：新建目录前必须检查是否已有语义等价目录，有则复用，不得创建同义重复目录。

**强制创建**：初始化时必须创建所有缺失的标准分类目录，不得只列出不创建。

**任务聚合**：一个工作项会产出 ≥3 份关联文档时，统一聚合到 `docs/plan/<task-slug>/` 子目录，配 `README.md` 索引，不分散到顶级分类。完整协议参见 `dt:plan-doc`。

### GP-10: Incremental Upgrade on Re-run

- 项目已有 CLAUDE.md、AGENT.md 或 Copilot 配置时，必须增量升级到当前 init skill 最新标准
- "文件已存在"不是跳过升级的理由
- 升级 AI 规则文件不等于重构源码；当前标准只约束后续 AI coding，不主动改造未被需求触碰的既有代码

---

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

（→ GP-2）在侦察后显式建立各类事实来源映射，记录发现的构建文件、workspace 配置、现有规则文件路径，用于后续生成阶段。

## Phase 3.5 Documentation Taxonomy

必须把项目文档统一收敛到 `/docs` 下，并建立语义优先的分类映射（→ GP-9）。

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

如果用户、团队规范或仓库现状明确存在额外分类语义，也必须纳入分类表。

**注意**：`api` 是按需分类，不在标准列表中，可根据项目需要创建。

### 3.5.3 Semantic Folder Mapping

分类以语义为准，不以字面完全一致为准。

- 如果标准分类已有语义等价目录，则复用现有目录，不再重复创建
- 例如已有 `/docs/plans`，就不要再创建 `/docs/plan`
- 例如已有 `/docs/requirements`、`/docs/prd` 或 `/docs/product-docs`，就不要再创建 `/docs/product`
- 只有在找不到语义等价目录时，才创建标准目录名

### 3.5.4 Creation Rules

**强制要求：必须创建缺失的标准分类目录**

- 若 `/docs` 不存在，创建 `/docs`
- 若 `/docs` 存在但缺少分类层级，**必须立即创建缺失的标准分类目录**，不得只列出不创建
- 若项目已有分类但命名不完全标准，优先保留原目录并记录映射，不强制重命名
- 不要在仓库根目录、临时目录或任意子模块下随意散落新文档，除非项目已有明确且稳定的非 `/docs` 约定

**执行要求**：
1. 识别 `/docs` 下已存在的目录
2. 对比标准分类列表，找出缺失目录
3. **使用 Bash 工具执行 `mkdir -p` 创建所有缺失目录**
4. 在输出中明确列出已创建的目录

### 3.5.5 Task-Scoped Documentation

**触发条件**：一个工作项会产出 ≥3 份关联文档时，使用任务聚合子目录；1-2 份独立文档按传统分类归档。

**位置约定**：`/docs/plan/<task-slug>/`，`<task-slug>` 使用英文 kebab-case。

**最低结构要求**：

- `README.md`：任务背景、文档清单、建议阅读顺序、关联源码、任务状态
- `00-执行文档.md`：进度指针、断点续做协议、Phase checklist、执行日志

**其他约定**：

- 任务聚合子目录内的文档不重复落到 `docs/design/`、`docs/guide/` 等顶级分类
- 任务聚合文档不直接修改项目单一事实源
- `docs/README.md` 的计划文档章节必须列出活跃任务子目录

**完整协议**（进度指针格式、子代理规划表、文件编号约定、`00-执行文档.md` 内部文件名约定等）→ 参见 `dt:plan-doc`。

### 3.5.6 Future AI Rules

初始化后，生成的 CLAUDE.md 和 Copilot 项目级配置必须显式写入 GP-9 的精简版本：

- 新文档默认放在 `/docs` 下
- 新建文档前，先检查 `/docs` 及其现有分类是否已有语义等价目录，有则复用
- 默认不要在仓库根目录新增零散 `.md` 文档
- 多文档工作项（≥3 份关联文档）统一聚合到 `docs/plan/<task-slug>/` 并配 `README.md` 索引

## Phase 3.6 Project AI Framework Bootstrap

标准 init 完成后，必须在目标项目内建立最小 project-skills 工作骨架，作为项目级 AI skill 的 canonical source。

### 3.6.1 Canonical Location

项目级 skill 的唯一事实源必须是：

```text
.ai/
├── README.md
└── skills/
    ├── registry.yml
    ├── .updates/
    └── project-skills/
        └── SKILL.md

.claude/
└── skills/
    └── project-skills/
        └── SKILL.md
```

强制要求：

- 若 `.ai/` 不存在，必须创建 `.ai/`
- 若 `.ai/skills/` 不存在，必须创建 `.ai/skills/`
- 若 `registry.yml` 不存在，必须创建最小注册表
- 若 `.updates/` 不存在，必须创建，用于存放待确认更新提案
- 若 `project-skills/SKILL.md` 不存在，必须创建项目内元 skill，说明 `.ai/skills/` 是 canonical source
- 若 `.claude/skills/` 不存在，必须创建 `.claude/skills/`
- init 完成时，必须把 bootstrapped 的 `project-skills` 从 `.ai/skills/project-skills/` 同步复制一份到 `.claude/skills/project-skills/`

`registry.yml` 最小字段至少包含：

- `id`
- `name`
- `purpose`
- `origin`
- `status`
- `overlaps_with`
- `merged_into`
- `last_reviewed_at`
- `tool_exports`
- `update_policy`

默认值建议：

- `status: active`
- `overlaps_with: []`
- `merged_into: null`
- `last_reviewed_at: <today-iso-date>`
- `tool_exports: [claude]`
- `update_policy: manual_confirm`

bootstrapped `.ai/skills/project-skills/SKILL.md` 至少包含这些内容：

- 标题明确为项目内 project-skills 元 skill
- 写清 `.ai/skills/` 是唯一事实源
- 写清“帮我总结一下加到 skill 里”默认触发重复检查、重叠检查、融合判断、proposal、确认后写入
- 写清默认只维护 canonical source；Copilot、Codex 导出层按需生成
- 写清任何 tool export 都不能反向成为事实源

建议使用下面的最小模板：

```markdown
---
name: project-skills
description: Canonical project-local skill governance. Use when summarizing successful changes into reusable project skills or updating existing project skills.
---

# project-skills

- Canonical source: `.ai/skills/`
- Claude mirror: `.claude/skills/`
- Do not edit tool export layers directly
- Do not edit `.claude/skills/` directly; refresh it by syncing from `.ai/skills/`
- When the user says "summarize this into a skill" or similar, first run duplicate-check, overlap-check, and merge-check
- Show a proposal before writing any canonical skill update
- Export Copilot or Codex views only on explicit request
```

### 3.6.2 Bootstrap Rules

默认建立 Claude-first 的项目级接入：canonical source 在 `.ai/skills/`，Claude 镜像在 `.claude/skills/`；Copilot、Codex 或其他工具导出层仍然按需生成。

这意味着：

- init 默认创建 `.ai/skills/` canonical source
- init 默认创建 `.claude/skills/` Claude project mirror
- init 必须把 project skill 规则写进生成的 `CLAUDE.md` 和 `AGENT.md`
- init 不主动创建 Copilot 或 Codex 的 skill 适配文件
- 只有用户后续明确要求时，才从 `.ai/skills/` 导出到其他工具
- 如果本次带 `--dry-run`，`.ai/` 骨架也只允许输出预览，不得实际创建目录或文件
- 如果本次带 `--dry-run`，`.claude/skills/` 镜像也只允许输出预览，不得实际创建目录或文件

### 3.6.3 Canonical-Only Rule

生成的项目级规则文件必须显式写入以下约束：

- 修改、沉淀、合并项目级 skill 时，只允许修改 `.ai/skills/` 下的 canonical 文件
- `.claude/skills/`、Copilot、Codex 等工具侧文件是导出层，不是事实源
- Claude 项目级 skill 默认通过同步把 `.ai/skills/` 复制到 `.claude/skills/`，不能直接手改 `.claude/skills/`
- 如需同步到其他工具，必须从 `.ai/skills/` 导出，不能直接手改导出层
- 当用户说“帮我总结一下加到 skill 里”或类似表达时，默认先做重复检查、重叠检查、融合判断，再给出 proposal，确认后才写入

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

## Phase 5. Output Constraints

生成的 AI 配置文件（CLAUDE.md、AGENT.md、Copilot 项目级配置）必须完整覆盖以下 General Principles（各文件长度预算允许精简表达，但不得遗漏）：

- GP-2（Single Sources of Truth）
- GP-3（Reuse-First）
- GP-4（File-Touch Discipline）
- GP-5（Plan-First Triggers）
- GP-6（Minimal Verification）
- GP-7（AI Vibe Coding Constraints）精简版
- GP-8（Copilot Config Exclusivity）
- GP-9（Documentation Taxonomy）精简版
- `.ai/skills/` canonical-only 规则与 project-skills proposal-first 工作流

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
- 无法给出 dry-run 预览或回滚说明
- 任务本质是新增业务功能，而不是结构收敛或同步更新
- 改动会导致同时维护 AGENTS.md 和 .github/copilot-instructions.md

### 6.5.4 Allowed Change Scope

Experimental 模式允许：

- 源码移动与重命名、模块拆分与合并
- 构建配置调整、依赖组织整理
- 导出关系、路径映射、入口索引更新
- CLAUDE.md 更新
- AGENTS.md 或 .github/copilot-instructions.md 二选一更新（→ GP-8）
- 与架构收敛或同步更新直接相关的测试、文档和配置引用修正

Experimental 模式不允许：

- 顺带开发无关业务功能
- 借机重写不相关模块
- 在没有代码证据的前提下引入理想化新架构

### 6.5.5 Dry-Run Requirements

只要进入 experimental 模式，就必须先给出 dry-run 预览；`--dry-run` 只是在此基础上停止执行。

Dry-run 至少包含：拟变更对象、每项变更的代码或配置依据、影响范围、潜在风险、预期收益、最小验证项、回滚点。

如果传入 `--dry-run`：只输出侦察结论、变更预览和回滚说明，不创建、不修改、不移动任何文件，不更新任何规则文件。

### 6.5.6 Execution Order

1. 先完成 Phase 1-4、Phase 6 的侦察和局部一致性判断（Phase 5 的输出约束在结构改动完成后执行）
2. 判定本次属于 `converge` 或 `sync`
3. 输出 dry-run 预览
4. 如果带 `--dry-run`，到此结束，不落盘
5. 先更新构建与模块声明，再执行源码移动、重命名、拆分或合并
6. 再更新依赖组织、导出关系、路径映射和相关引用
7. 完成结构改动后，重新扫描项目事实
8. 只基于变更后重新扫描的结果，更新 CLAUDE.md 与 Copilot 项目级配置
9. 完成最小验证（→ GP-6）
10. 输出回滚说明、验证结果和 residual risk

### 6.5.7 Config Update Rules

- Claude 侧更新项目根目录 CLAUDE.md
- Copilot 侧只能更新 AGENTS.md 或 .github/copilot-instructions.md 其中之一（→ GP-8）
- Experimental 模式下，所有项目级规则必须基于变更后重新扫描结果生成，不能基于变更前状态写入

### 6.5.8 Rollback Requirements

Experimental 模式必须输出回滚说明，至少包含：

- 回滚单位；受影响文件类型
- 已移动或重命名的路径；已调整的构建配置；已调整的依赖组织
- 已更新的 CLAUDE.md 与 Copilot 规则文件
- 需要反向恢复的关键步骤；无法自动回滚的部分

如果无法自动回滚，必须明确说明哪些改动只能人工回滚，哪些状态在执行后不可无损恢复，哪些风险需要由用户决定是否接受。

### 6.5.9 Minimum Verification

Experimental 模式至少完成以下四层验证：

- 构建层：确认模块声明、源码路径、依赖关系、构建入口未失配
- 引用层：确认关键 import、导出关系、入口文件、关键调用链未断裂
- 规则层：确认 CLAUDE.md 与 Copilot 项目级配置和变更后结构一致
- 范围层：确认没有越界改动到无关业务逻辑或无关目录

如果仓库存在默认验证命令，优先运行（→ GP-6）。如果没有，必须明确说明未验证，不得写成已通过。

## Phase 7. Generate Files

### 7.1 CLAUDE.md

默认行为是优化已有 CLAUDE.md，不是全量重写（→ GP-10）。只有以下情况才接近重写：

- 项目不存在 CLAUDE.md
- 现有内容严重过时且与代码冲突
- 用户明确要求重写

**Language Requirement**: CLAUDE.md MUST be written in English.

生成结果要求：

- 60 到 120 行优先
- 采用规则 + 路径索引的高密度写法
- 不复制 README 大段内容；不展开完整依赖表、完整构建教程、完整架构宣讲

**必须显式包含**：

1. 单一事实来源与证据要求（GP-2）
2. 复用优先规则（GP-3）
3. 触碰文件原则与计划触发条件（GP-4、GP-5）
4. 最小验证规则（GP-6），包含仓库默认验证命令
5. AI vibe coding 约束（GP-7 精简版）
6. Copilot 配置互斥规则（GP-8）
7. 文档根目录、分类映射、新文档落位规则（GP-9 精简版，含任务聚合规则）
8. 真实目录结构、默认构建与测试方式
9. 项目级 skill 的唯一事实源是 `.ai/skills/`，修改 skill 时只改 canonical source，不手改导出层
10. 当用户要求“总结并加到 skill”时，先做重复/重叠/融合判断，先提 proposal 再写入
11. 若本次已升级旧版 AI 规则文件，注明已升级到当前 init skill 标准
12. 当前标准只约束后续 AI coding，不主动重构未被需求触碰的既有源码

Experimental 模式补充要求：CLAUDE.md 必须基于变更后重新扫描的结果生成，不得根据变更前结构写入规则。

### 7.2 AGENT.md

AGENT.md 是面向所有 AI 工具的通用规范文件，不包含平台特定语法。

**生成位置**：项目根目录 AGENT.md

**Language Requirement**: AGENT.md MUST be written in English.

**内容要求**：

- 50 到 80 行优先
- 采用纯文本描述，避免使用特定平台语法
- 不包含 Tool 调用、特定 Agent 指令等平台相关内容

**必须包含**：

1. 项目概览：项目名称和用途、技术栈列表、目录结构说明
2. 单一事实来源（GP-2）：构建文件胜过文档，目录扫描结果胜过经验推断
3. 通用编码规范：复用优先（GP-3）、AI vibe coding 约束（GP-7）、触碰文件与计划触发（GP-4、GP-5）、最小验证（GP-6）、文件命名约定、提交信息格式
4. Copilot 项目级配置互斥（GP-8）：不同时维护 AGENTS.md 与 .github/copilot-instructions.md
5. 项目级 skill 规则：`.ai/skills/` 是唯一事实源，只改 canonical source，工具导出层按需生成
6. 关键路径索引：主入口、公共组件/工具类位置、文档目录结构、任务聚合子目录约定（GP-9）
7. 常用命令：构建、测试、运行命令

**与 CLAUDE.md 的区别**：

| 特性 | CLAUDE.md | AGENT.md |
|------|-----------|----------|
| 目标平台 | Claude Code | 所有 AI 工具 |
| 语法 | 包含 Claude 特定指令 | 纯文本，无平台语法 |
| 长度 | 60-120 行 | 50-80 行 |

生成时机：在 CLAUDE.md 生成之后、Copilot 配置生成之前。已存在时优先增量优化而非全量覆盖（→ GP-10）。

Experimental 模式补充要求：AGENT.md 必须基于变更后重新扫描的结果生成，与 CLAUDE.md 保持一致。

### 7.3 Copilot 项目级配置

**Language Requirement**: Copilot project-level configuration MUST be written in English.

规则文件选择（→ GP-8）：项目已有 AGENTS.md 则更新 AGENTS.md；否则创建或更新 .github/copilot-instructions.md。

无论使用 .github/copilot-instructions.md 还是 AGENTS.md，内容要求一致：

- 长度优先控制在 30 到 80 行；不能复制一整份 CLAUDE.md
- 只保留对所有任务都有帮助的规则
- 必须包含精简版 GP-2 至 GP-9：单一事实来源（GP-2）、复用优先（GP-3）、触碰文件与计划触发（GP-4、GP-5）、最小验证（GP-6）、AI vibe coding 约束（GP-7）、配置文件互斥（GP-8）、文档归档规则（GP-9，含任务聚合）
- 如果项目已建立 `.ai/skills/`，必须补一句：项目级 skill 只改 `.ai/skills/` canonical source，不手改导出层

Experimental 模式：Copilot 项目级配置必须基于变更后重新扫描结果更新（→ 6.5.7）。

### 7.4 Onboarding 摘要

在会话中输出一份 2 分钟可扫完的摘要，至少包含：

- 项目是什么、技术栈、关键入口、目录地图
- 一条典型请求或调用链
- 主要约定、常用命令
- 我想改哪里该看哪里
- 文档应该放在哪个 `/docs` 分类目录
- 项目级 skill 在 `.ai/skills/`，默认只维护 canonical source，导出到其他工具需显式要求

如果启用 experimental 模式，摘要还必须额外包含：本次属于 `converge` 还是 `sync`、变更涉及的关键目录或模块、风险点、最小验证结果、回滚说明摘要。

## Phase 8. Optional Checklist Docs

**Language Requirement**: All checklist documentation MUST be written in English.

只有用户明确要求时，才生成 `/docs` 下的 checklist 文档；如果项目已有语义等价目录，如 `/docs/checklists`，则复用该目录。可选模板：

- references/checklist-templates/api.md
- references/checklist-templates/dependencies.md
- references/checklist-templates/modules.md

所有 checklist 都必须满足：只写真实扫描到的信息；不保留占位字段；不补示例内容；无法验证的字段直接省略。

## Best Practices

1. 先并行侦察，再定向读取，避免一上来通读整个仓库
2. 优先增强已有规则文件，不要无脑覆盖（→ GP-10）
3. 结论必须能在代码或配置中找到证据（→ GP-1）
4. 统一流程要服务所有项目，但输出内容必须跟随具体栈变化
5. 不确定的地方明确写 unknown，优先正确而不是看起来完整
6. Experimental 模式先做 dry-run，再做结构改动，再做变更后重扫
7. 能用 `sync` 解决时，不要滥用 `converge`
8. 文档分类先看语义映射，再决定目录名，不要机械按单数或复数重复建目录

## Anti-Patterns to Avoid

以下是正文规则之外容易犯的错误（与正文规则一一对应的反向陈述已省略）：

- 把 init 写成 Android-only 或 Flutter-only 流程
- 看到框架关键词就直接套现代模板，不验证真实文件
- 未传入 `--experiment` 却自动进入 experimental 模式
- 还在侦察阶段就开始移动文件或改架构
- 只列出缺失的标准分类目录而不实际创建（→ GP-9 强制创建规则）
- 重复执行 init 时，把"升级旧版 AI 规则标准"误解为要主动重构项目源码（→ GP-10）
- 把 500 行偏好误写成对生成文件、lockfile、迁移、vendor 或框架入口的无条件硬限制（→ GP-7）
- 未完成最小验证就先写入规则文件，或把"未验证"写成"已通过"（→ GP-6）
- 在 `sync` 模式下顺带做大规模架构重构；在 `converge` 模式下夹带无关业务功能
- 基于变更前状态生成 experimental 规则文件（→ 6.5.7）
- 工作项会产出多份关联文档时，仍把它们分散到顶级分类而不聚合到 `docs/plan/<task-slug>/`（→ GP-9）
- AI 进入任务目录不先读进度指针就开工，重头执行已完成的 Phase（→ `dt:plan-doc`）
- 把进度指针更新委托给 subagent（必须由 main-agent 自己维护）（→ `dt:plan-doc`）
