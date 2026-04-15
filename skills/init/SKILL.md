---
name: init
description: "Initialize AI project context for any codebase. Detect Android, Flutter, React, Python, Java, Node.js and other stacks from real files, then generate or update CLAUDE.md, Copilot project instructions, a concise onboarding summary, and optional verified checklist docs."
origin: dev-tools-skills
---

> 中文环境要求
>
> - 面向用户的回复、注释、提示信息必须使用中文
> - AI 内部分析可以使用英文
> - 所有生成文件必须使用 UTF-8 编码
> - 对外输出优先简洁、明确、可执行，避免冗长项目介绍

# init Skill

统一的跨技术栈项目初始化入口。用于第一次进入一个仓库时，基于真实代码和配置生成 AI 可直接消费的项目级规则，而不是套模板。

## Trigger

```text
/init
```

## When to Use

- 第一次接手一个陌生仓库
- 需要为项目补充或优化 CLAUDE.md
- 需要让 VS Code Copilot 直接读取项目级规则
- 需要输出可快速浏览的代码库 onboarding 摘要
- 需要为 Android、Flutter、React、Python、Java、Node.js 等项目建立统一 AI 工作约束

## Core Goals

最终结果必须同时服务 Claude Code 和 VS Code Copilot，并满足以下目标：

1. 重点是 AI 工作规则，不是项目介绍文档
2. 所有结论必须来自真实代码、配置和目录扫描，不得凭经验补全
3. 优先帮助 AI 做正确决策：先搜索、先复用、最小改动、局部一致
4. 同时覆盖通用工程约束和技术栈特有约束
5. 默认输出应低 token、高密度、可执行
6. 若已有规则文件，优先增量优化，不直接覆盖

## Required Outputs

本技能默认产出以下内容：

1. 会话内 onboarding 摘要
2. 项目根目录 CLAUDE.md
3. Copilot 可读取的项目级配置

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

5. 配置与工具链
   tsconfig.json, eslint/prettier 配置, analysis_options.yaml,
   pytest.ini, tox.ini, mypy.ini, Dockerfile, docker-compose*,
   .github/workflows/, Makefile, CI 配置

6. 测试结构
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

## Phase 7. Generate Files

### 7.1 CLAUDE.md

默认行为是优化已有 CLAUDE.md，不是全量重写。只有以下情况才接近重写：

- 项目不存在 CLAUDE.md
- 现有内容严重过时且与代码冲突
- 用户明确要求重写

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
5. 项目强约束
6. 真实目录结构
7. 默认构建与测试方式
8. 文档索引

### 7.2 Copilot 项目级配置

如果使用 .github/copilot-instructions.md：

- 长度优先控制在 30 到 80 行
- 内容比 CLAUDE.md 更短，但不能丢掉高约束规则
- 只保留对所有任务都有帮助的规则
- 不能复制一整份 CLAUDE.md

如果项目已有 AGENTS.md：

- 优先在 AGENTS.md 中补充同等项目规则
- 不再新增 .github/copilot-instructions.md

### 7.3 Onboarding 摘要

在会话中输出一份 2 分钟可扫完的摘要，至少包含：

- 项目是什么
- 技术栈
- 关键入口
- 目录地图
- 一条典型请求或调用链
- 主要约定
- 常用命令
- 我想改哪里该看哪里

## Phase 8. Optional Checklist Docs

只有用户明确要求时，才生成 docs/checklist 文档。可选模板：

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

## Anti-Patterns to Avoid

- 把 init 写成 Android-only 或 Flutter-only 流程
- 看到框架关键词就直接套现代模板
- 同时生成 AGENTS.md 和 .github/copilot-instructions.md
- 把 CLAUDE.md 写成面向人的长篇项目介绍
- 把 Copilot 指令文件写成 CLAUDE.md 的完整拷贝
- 生成任何未经代码验证的 checklist 条目
