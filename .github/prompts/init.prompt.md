---
name: "init"
description: "Initialize AI project context for any codebase: detect the real stack, summarize the repo, and generate or update CLAUDE.md plus Copilot project instructions."
argument-hint: "[optional focus] e.g. android app, react monorepo, python api"
agent: "agent"
model: ['GPT-5 (copilot)', 'Claude Sonnet 4.5 (copilot)']
---

分析当前工作区，按真实代码和配置完成一次跨技术栈项目初始化。

必须完成这些目标：

- 判断项目类型，可以是 Android、Flutter、React、Node.js、Python、Java 或混合仓库
- 只根据真实文件、目录和配置做结论，不要套模板
- 输出一份简洁的 onboarding 摘要，包含技术栈、关键入口、目录地图、主要约定和常用命令
- 生成或优化项目根目录的 CLAUDE.md
- 为 VS Code Copilot 增加项目级配置：如果项目已有 AGENTS.md 就更新它，否则创建或更新 .github/copilot-instructions.md
- 不要同时维护 AGENTS.md 和 .github/copilot-instructions.md 两套项目级指令
- 默认遵循先搜索、先复用、最小改动、局部一致

必须重点检测这些内容：

- 构建与依赖文件
- 主入口和目录结构
- 命名约定、测试结构、错误处理、异步风格
- 本地复用入口，例如 base 类、公共组件、utils、service、api client、repository、config

如果识别到特定技术栈，追加这些约束：

- Android：跟随 Java/Kotlin 现状、绑定方案、strings/colors 和既有工具类
- Flutter：跟随已有状态管理、路由、主题、网络和存储方案
- React/Web：跟随现有状态管理、样式方案、请求层和组件模式
- Python：跟随现有包结构、sync/async 风格、settings/schema/service 组织
- Java：跟随现有 DI、注解、模块和 controller/service/repository 结构

如果用户提供了参数，把它当作优先关注的项目类型或模块范围，但仍然要基于真实代码验证。