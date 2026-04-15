---
name: fdt:init-flutter
description: "Initialize or optimize claude.md for Flutter projects. Detect real project structure from pubspec.yaml and source folders, merge existing rules, and generate a concise low-token AI guidance file that prioritizes reusing existing architecture, utilities, and coding patterns. Optionally generate minimal verified checklist docs for APIs, dependencies, and modules when explicitly requested."
---

> 中文环境要求
>
> - 面向用户的回复、注释、提示信息必须使用中文
> - AI 内部分析可以使用英文
> - 所有生成文件必须使用 UTF-8 编码
> - 对外输出优先简洁、明确、可执行，避免冗长项目介绍

# init-flutter Skill

为 Flutter 项目生成或优化 claude.md，使 AI 工具能够：

- 快速理解项目的真实结构与构建方式
- 优先复用现有实现，而不是重新设计一套
- 遵循项目已有编码规范、目录组织和局部写法
- 在尽量少的 token 下获得足够高价值的上下文
- 兼容传统 Flutter 项目、纯 Dart 与 Flutter 混合项目、历史页面与新代码并存项目

## When to Use

- 新项目需要初始化 AI 规则文件
- 现有项目的 claude.md 需要瘦身、去重、降 token
- 项目已有 README、docs，但 AI 仍容易理解跑偏
- 希望 AI 优先复用现有架构、工具类、公共组件、状态管理、目录结构
- 旧项目、混合项目、历史页面和新页面共存，需要 AI 跟随现状而不是套现代模板

## Trigger

```text
/fdt:init-flutter
```

## Core Goals

最终生成或更新的 claude.md 必须满足以下目标：

1. 重点是"AI 工作规则"，不是"项目介绍文档"
2. 优先帮助 AI 做正确决策，而不是堆背景信息
3. 明确单一事实来源，避免与真实工程配置冲突
4. 强化"先搜索、先复用、最小改动、局部一致"
5. 避免默认套用 BLoC、Clean Architecture、GetX、Riverpod 等现代 Flutter 模板
6. 对历史项目保持保守，不擅自迁移状态管理方案、绑定架构层次

## Execution Flow

### 1. Verify Project Type

确认当前目录是 Flutter 项目。至少满足以下条件之一：

- 存在 `pubspec.yaml` 且包含 `flutter:` 或 `dependencies` 中有 `flutter` 相关包
- 存在 `lib/main.dart`
- 存在 `android/` 或 `ios/` 目录（Flutter 项目特征）
- `flutter --version` 可执行

如果不是 Flutter 项目，直接退出并说明原因。

### 2. Discover Existing Guidance

优先读取并分析已有规则和文档，禁止直接按模板覆盖：

- claude.md
- README.md
- analysis_options.yaml（项目代码规范）
- docs/architecture/*
- docs/development/*
- docs/checklist/*
- 其他明确用于 AI 规则或开发规范的文件

目标不是复制这些文档，而是抽取其中对 AI 最关键的高频约束、真实事实和复用入口。

### 3. Build Single Sources of Truth

以下信息必须只从真实来源提取：

- 项目名称、版本、SDK 约束、依赖：以 `pubspec.yaml` 为准
- Flutter/Dart SDK 版本：以 `pubspec.yaml` 中的 `environment` 为准
- 项目特有开发规则：优先以已有 claude.md 和明确的开发规范文件为准
- 真实目录结构：以 `lib/` 源码目录扫描结果为准
- 现有编码模式：以相邻代码、公共基类、工具类、状态管理、UI 组件为准
- 默认构建命令：来自 `pubspec.yaml` 和已有项目文档

如果文档与代码冲突，以代码和配置为准；若两者都不明确，再保留谨慎描述。

### 4. Detect Local Coding Patterns

必须检测而不是臆测：

#### 4.1 State Management

检测项目使用的状态管理方案，而不是套预设模板：

- Provider / Riverpod / BLoC / Cubit / GetX / MobX / StatelessWidget + setState
- 是否存在多种状态管理方案混用
- 哪些页面/模块使用哪种方案

生成规则时必须写明：
修改代码时优先跟随目标文件和同目录已有状态管理模式，不因为偏好擅自迁移。

#### 4.2 Project Structure

- 实际源码目录如何命名（feature-first / layer-first / 其他）
- 业务是按 feature/、pages/、widgets/、models/、services/ 组织，还是其他方式
- 是否有明显的公共模块和本地 package
- 是否存在老架构与新写法混用

#### 4.3 Reuse Entrypoints

优先识别这些复用入口：

- BasePage / BaseWidget / BaseState / BaseViewModel
- utils / helper / manager / provider / repository / service / model / widget
- 公共 Dialog、公共 Widget、公共网络封装、公共响应体、公共常量、公共工具类
- 主题配置、路由配置、国际化配置、存储工具、日志工具、权限工具

#### 4.4 Architecture Reality

检查项目真实结构，而不是套预设模板：

- 实际目录如何命名
- 是否使用自由路由、命名路由、auto_route、go_router
- 是否有明显的分层（data/domain/presentation）
- 是否存在老架构与新写法混用

不要因为检测到少量 ChangeNotifier、Bloc 或 Riverpod provider 就自动断言项目使用某种完整架构。

### 5. Generate or Optimize claude.md

默认行为是"优化已有 claude.md"，不是"全量重写"。

只有在以下情况才接近重写：

- 项目不存在 claude.md
- 现有 claude.md 明显是低质量模板、信息严重过时、与实际代码大量冲突
- 用户明确要求重写

生成结果必须符合：

- 目标长度控制在 60 到 120 行
- 使用"规则 + 路径索引"的高密度写法
- 保留高频、高约束、高复用信息
- 删除低频背景描述和教程式内容
- 不重复 README 中的大段项目介绍
- 不展开完整依赖表、完整构建说明、完整部署教程
- 不写通用 Flutter 教程式代码示例
- 不要把 claude.md 写成"项目介绍优先、构建说明优先、人类阅读友好"的长文档
- 必须写成"AI 决策优先、复用优先级明确、冲突规则统一、低频信息压缩"的规则文件
- 下列低频部分应删除或压缩为一句话或一个索引链接：项目概述大段描述、网络请求示例代码、完整依赖表、面向人的 Claude Code 使用说明

### 6. Required Structure of claude.md

生成的 claude.md 应优先包含这些部分：

1. AI 工作原则
2. 单一事实来源
3. 复用优先级
4. 局部一致性规则
5. 项目强约束
6. 真实目录结构
7. 默认构建方式
8. 文档索引

每一部分都应短、硬、可执行。

### 6.1 四个必须写死的段落

生成的 claude.md 必须显式包含并优先前置以下四段，不能只在其他章节中隐含表达：

#### A. AI 工作原则

至少要明确写出：

- 先搜索目标文件同目录和同类实现
- 优先复用已有实现
- 优先最小改动
- 不主动引入新架构、新封装、新库

#### B. 单一事实来源

至少要明确写出：

- 构建与版本以 pubspec.yaml 为准
- Flutter/Dart SDK 以 pubspec.yaml 中的 environment 为准
- 项目特有开发规则以已有 claude.md 和开发规范文件为准
- 目录结构以实际源码目录为准

#### C. 局部一致性规则

至少要明确写出：

- 已有 setState 的文件优先延续 setState
- 已使用 Provider 的模块优先延续 Provider
- 多种状态管理并存时，优先跟随目标文件和同目录模式
- 不要因为偏好擅自迁移页面

#### D. 项目强约束

至少要优先检查并写入：

- 国际化字符串复用规则（AppLocalizations 或 hardcoded）
- 主题/样式复用规则（ThemeData / 自定义主题类）
- 路由复用规则（命名路由 / go_router / auto_route）
- 网络请求统一规则（Dio / http）
- 存储统一规则（shared_preferences / hive / get_storage）
- Utils 类复用规则

这些规则优先级高于命名规范、示例代码和通用 Flutter 最佳实践。

### 6.2 文档索引格式规则

如果 claude.md 包含"相关文档"或"文档索引"部分，必须遵循以下格式规则：

- 每一项都必须使用合法 Markdown 链接，禁止输出裸路径
- 同一列表中的格式必须统一，不能一部分是裸路径，一部分是 Markdown 链接
- 链接路径必须直接指向真实存在的文件，优先使用相对路径
- 如果某文档不存在，则省略该项，不要保留占位条目

正确示例：

- [API 端点列表](./docs/checklist/api.md)
- [依赖库清单](./docs/checklist/dependencies.md)
- [架构概览](./docs/architecture/overview.md)

错误示例：

- ./docs/checklist/api.md - API 端点列表
- [依赖库清单](./docs/checklist/dependencies.md) - 第三方库列表
- .. /docs/checklist/api.md

### 7. Mandatory Reuse Rules

生成 claude.md 时必须尽量固化这些规则：

- 修改前先搜索目标文件同目录和同类实现
- 优先复用现有 Widget、Page、Service、Model、Utils、Manager
- 优先在已有类中扩展，不轻易新增平行封装
- 优先最小改动，不做无关重构
- 已有 setState 的页面优先延续 setState
- 已使用 Provider/BLoC/Riverpod 的模块优先延续原有方案
- 保持相邻代码的命名、调用链、目录组织和异常处理方式一致
- 不主动引入新的 BLoC、Clean Architecture、Riverpod、GetX、三方库，除非用户明确要求
- 对传统项目和历史页面保持保守，不把局部修改升级成架构改造
- 如果目标目录已有旧写法或混合写法，优先与该局部保持一致

### 8. Project-Specific Constraints

如果项目中存在明确的资源、工具、常量、存储、日志规范，必须前置写入 claude.md，例如：

- 文本不得硬编码，优先使用国际化方案
- 样式不得硬编码，优先使用 ThemeData 或主题扩展
- 路由统一使用既有路由方案
- 网络请求统一使用既有封装
- 存储统一使用既有封装
- KEY、常量、工具方法优先复用已有定义
- 已有同类 Utils 时优先追加方法，不新建重复工具类

注意：这些规则必须来自真实项目实现或已有规范，不能凭空推荐。

不要让命名规范、网络请求示例、技术栈介绍抢在这些强约束之前占据主要篇幅。

### 9. Optional Checklist Generation

默认不生成 docs/checklist/*。

只有在以下情况才生成：

- 用户明确要求生成
- 项目几乎没有任何文档，需要建立最小索引
- 扫描结果足够可靠，不会产生大量模板化伪信息

如果生成 checklist，必须遵循：

- 只记录从项目中真实扫描到的内容
- 不得虚构模块、接口、依赖
- 不得预设 bloc、riverpod、freezed、getx 等项目未使用内容
- 如果信息提取不可靠，则宁可少写，也不要编造

### 10. Optional .gitignore Update（可选执行）

生成或更新 claude.md 后，**不要主动**将其添加到 .gitignore。

这些文件可以提交到版本控制，方便团队成员共享 AI 配置。

如果用户**明确要求**将 AI 生成文件加入 .gitignore，则可按以下条目添加：

```
# AI guidance files (generated, do not commit)
claude.md
docs/checklist/api.md
docs/checklist/dependencies.md
docs/checklist/modules.md
```

执行方式：

1. 读取项目根目录的 .gitignore
2. 检查是否已包含上述条目
3. 如果没有，在文件末尾追加（用空行与已有内容分隔），并注释说明是 AI 生成的文件
4. 不要删除或修改 .gitignore 中已有的其他条目

### 11. Output Standard

对用户的总结说明要包含：

- 生成或更新了什么
- 依据哪些真实来源抽取规则
- 删除了哪些冗余内容
- 保留了哪些项目特有约束
- 是否生成了 checklist
- 是否改动了 .gitignore
- 哪些地方仍建议用户人工确认

如果输出 claude.md，还必须检查一遍：

- 文档索引中的所有链接是否为合法 Markdown 链接
- 是否混用了裸路径和 Markdown 链接
- 是否引用了不存在的 docs 文件
- 是否出现多余的 `.`、缺失的 `[]()` 或损坏的列表格式

## Anti-Patterns

禁止以下做法：

- 把 claude.md 写成 README 的重复版本
- 把 claude.md 写成项目介绍优先、构建说明优先的说明文档
- 把通用 Flutter 最佳实践直接套进旧项目
- 自动宣称项目是 BLoC / Clean Architecture / Riverpod 项目
- 默认生成一批内容空泛的 checklist 文档
- 在 modules.md、dependencies.md、api.md 中填充模板示例
- 在"相关文档"部分输出裸路径、损坏链接或混合格式列表
- 把命名规范、网络示例、构建教程放在状态管理、路由、主题、存储复用规则之前
- 因为检测到少量新写法就要求全项目迁移
- 忽略已有规则文件，直接覆盖
- 输出冗长、低频、难执行的说明

## Expected Outcome

高质量结果应满足：

- AI 首次读取后能快速知道"先去哪看、优先复用什么、不能乱改什么"
- claude.md 长度明显缩短，但决策信息更强
- 规则更贴近真实代码，而不是通用模板
- 面对旧项目、混合状态管理、并存架构方案时，AI 行为更稳定
- 减少 AI 自己新起架构、重复造工具、擅自迁移技术方案的概率
