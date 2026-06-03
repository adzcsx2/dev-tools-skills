---
name: dt:init
description: "Initialize AI project context for any codebase. Detect the real stack, generate or update CLAUDE.md, AGENT.md, Copilot instructions, bootstrap canonical .ai/skills, and for Claude Code projects generate a project-level PostToolUse hook for project-skill mirror refresh."
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

统一的跨技术栈项目初始化入口。`dt:init` 现在是**主编排 skill**：它只负责按顺序读取 `references/` 下的协议、侦察仓库事实、再生成或升级项目级 AI 规则。详细规则已经拆到 reference 文件中，不要再依赖通读一个超长文件来记忆全部约束。

## Trigger

```text
/dt:init [optional focus] [--experiment [converge|sync]] [--dry-run]
```

## When to Use

- 第一次接手一个陌生仓库
- 需要为项目补充或优化 `CLAUDE.md`
- 需要让 VS Code Copilot 直接读取项目级规则
- 需要输出可快速浏览的代码库 onboarding 摘要
- 需要建立或升级 `.ai/skills/` 项目级 canonical skill 工作面
- 项目曾经执行过 init，但需要把旧版规则文件升级到当前标准
- 项目进入 Claude Code 工作流，需要生成项目级 hook 来执行 project-skills mirror refresh
- 项目需要补齐 `/docs` 分类规则、报告归档规则和 project-skills 约束
- 用户显式要求 `--experiment converge` 或 `--experiment sync`

## Command Parameters

- 无参数：标准 init。只做侦察、总结和规则文件生成或优化，不允许主动改架构
- `[optional focus]`：可选关注模块、技术栈或目录范围，但所有结论仍必须由真实代码验证
- `--experiment converge`：启用 experimental 架构收敛模式
- `--experiment sync`：启用 experimental 同步更新模式
- `--experiment`：只允许使用这个开关名，不接受其他别名
- `--dry-run`：只输出侦察结果、变更预览、风险、验证项和回滚点，不落盘、不移动文件、不改配置

## Main Responsibility

`dt:init` 只负责这几件事：

1. 基于真实代码侦察仓库事实
2. 按 reference 协议建立 `/docs`、`.ai/skills/`、configured mirrors 记录和项目级规则文件
3. 在 Claude Code 项目里 bootstrap `.claude/settings.json` 与 `.claude/hooks/sync-project-skills.sh`
4. 增量升级已有 `CLAUDE.md`、`AGENT.md`、Copilot 配置，不无脑覆盖
5. 生成 onboarding 摘要与最小验证结果

完整同步语义、proposal 规则、duplicate-check / overlap-check / merge-check，统一由 `dt:project-skills` 负责；`init` 不重复展开那套细则。

## Required Outputs

本技能默认产出以下内容：

1. 会话内 onboarding 摘要
2. 项目根目录 `CLAUDE.md`
3. 项目根目录 `AGENT.md`
4. Copilot 可读取的项目级配置（`AGENTS.md` 或 `.github/copilot-instructions.md` 二选一）
5. `.ai/README.md`、`.ai/skills/registry.yml`、`.ai/skills/.updates/`、`.ai/skills/project-skills/SKILL.md`
6. （仅当前环境为 Claude Code，或用户明确要求 Claude 项目自动化时）`.claude/settings.json` 与 `.claude/hooks/sync-project-skills.sh`
7. `/docs` 文档根目录及必要分类目录骨架
8. 可选 checklist（仅用户明确要求时）

## Mandatory Read Order

在开始生成任何文件前，**必须按顺序读取这些 reference**：

1. `references/general-principles.md`
2. `references/recon-and-stack-detection.md`
3. `references/docs-taxonomy.md`
4. `references/project-bootstrap.md`
5. `references/claude-hook-bootstrap.md`
6. `references/output-files.md`

按条件追加读取：

- 传入 `--experiment`：再读取 `references/experimental-mode.md`
- 用户明确要求 checklist：再读取
  - `references/checklist-templates/api.md`
  - `references/checklist-templates/dependencies.md`
  - `references/checklist-templates/modules.md`

执行要求：

- 未读取必需 reference 前，不得开始生成 `CLAUDE.md`、`AGENT.md`、Copilot 配置或 hook 文件
- `dt:init` 负责**编排顺序**，reference 负责**细节规则**
- 不要在主 skill 里再把 reference 全文复述一遍
- 如果 reference 与旧版项目规则冲突，按 reference + 真实代码做增量升级，不要直接跳过

## Execution Workflow

### Step 0. CodeGraph Auto-Init (run first)

在开始任何侦察或文件生成之前，必须先检查并初始化 CodeGraph：

- 检测本机是否安装了 `codegraph` CLI（执行 `which codegraph` 或 `codegraph` 可用性检查）
- 检测项目根目录下是否已存在 `.codegraph/` 文件夹
- 当本机已安装 `codegraph` 且项目不存在 `.codegraph/` 时，自动执行 `codegraph init -i` 初始化索引
- 如果 `codegraph` 未安装或 `.codegraph/` 已存在，静默跳过
- 此步骤的执行结果应反映在 onboarding 摘要中（标明 CodeGraph 是否已初始化或跳过）

### Step 1. Parse Mode

- 判断当前是标准模式还是 experimental 模式
- 若只写了 `--experiment` 但未指定 `converge|sync`，且无法从用户意图与仓库事实推断，必须先澄清
- 若带 `--dry-run`，所有落盘动作都只输出预览

### Step 2. Read References

- 严格按 `Mandatory Read Order` 读取必需 reference
- 只在需要时再读取 conditional reference

### Step 3. Reconnaissance

- 按 `references/recon-and-stack-detection.md` 做并行侦察
- 先扫构建文件、入口、目录快照、文档目录、测试结构、工具链配置
- 只基于真实文件和目录得出结论

### Step 4. Stack Detection And Conventions

- 识别 Android、Flutter、Web/Node、Python、Java/JVM 或混合仓库
- 建立 single sources of truth
- 判断命名、测试、错误处理、异步风格和 git 约定

### Step 5. Docs Taxonomy

- 按 `references/docs-taxonomy.md` 建立 `/docs` 根目录和标准分类
- 应用语义优先目录映射
- 把审计 / 性能 / 评估 / 复盘类报告的主题目录规则写进后续生成文件

### Step 6. Project Bootstrap

- 按 `references/project-bootstrap.md` 建立 `.ai/skills/` canonical source
- 写入 `.ai/README.md` 的 configured mirrors 固定段落
- bootstrap 项目内 `project-skills` 元 skill
- 如果适用，再按 `references/claude-hook-bootstrap.md` 生成 Claude project hook

### Step 7. Experimental Flow

- 仅在显式传入 `--experiment` 时执行
- 必须先读 `references/experimental-mode.md`
- 先给 dry-run 预览，再决定是否落盘
- 只在该 reference 允许的范围内做结构改动

### Step 8. Generate Output Files

- 按 `references/output-files.md` 生成或增量升级：
  - `CLAUDE.md`
  - `AGENT.md`
  - Copilot 项目级配置
  - onboarding 摘要
  - 可选 checklist

### Step 9. Minimal Verification

- 优先运行与改动范围最小相关的 test / lint / typecheck / build / smoke
- 如果没有可执行验证命令，必须明确写 `not verified`
- 文档-only 变更至少检查路径、目录规则和规则文件一致性

### Step 10. Code Review Generated Rules

在所有文件生成和验证完成后，对产出的规则文件做一次完整性审查：

- 检查 `CLAUDE.md` 是否完整覆盖了 `references/output-files.md` 要求的 13 项必备内容
- 检查 `AGENT.md` 是否完整覆盖了 7 项必备内容
- 检查 Copilot 项目级配置是否涵盖精简版 GP-2 至 GP-9
- 交叉检查各文件之间的一致性（单一事实来源声明、skill canonical 规则、文档分类规则是否在各文件中一致）
- 检查是否有遗漏的规则类别：安全、测试、编码风格、Git 工作流、性能、Agent 编排、Hook 系统
- 对照 `references/general-principles.md` 的 GP-1 至 GP-10，逐项确认关键约束已写入对应文件
- 发现缺失或冲突时，补充或修正对应文件
- 输出一份简短的 review 结论到会话中：列出已覆盖的规则类别、发现的 gap 及是否已修复

## Minimum Rules Generated Files Must Carry

生成的 `CLAUDE.md`、`AGENT.md`、Copilot 项目级配置，至少必须体现这些约束：

- `.ai/skills/` 是唯一 canonical source
- 工具导出层不是事实源，不手改 `.claude/skills/`、`.ai/exports/`
- 如果项目存在 Claude project hook，则 canonical 改动后由 hook 触发 mirror refresh
- 任务聚合文档使用 `docs/plan/<task-slug>/`
- 审计 / 性能 / 评估 / 复盘类报告使用 `docs/reports/<report-topic>/`
- `CHANGELOG.md` 这类持续更新日志可保留在 `docs/reports/` 根下
- 需求不清或跨 3+ 源码文件时先计划
- 所有结论必须来自真实代码、配置或目录扫描

## Best Practices

1. 先并行侦察，再定向读取，避免一上来通读整个仓库
2. 优先增强已有规则文件，不要无脑覆盖
3. 能复用 reference 里的固定协议时，不要在主 skill 里重新发明步骤
4. 能用标准模式解决时，不要滥用 `--experiment`
5. 对未知项明确写 `unknown`，优先正确而不是看起来完整

## Anti-Patterns To Avoid

- 未读取 reference 就开始生成规则文件
- 看到框架关键词就直接套模板，不验证真实文件
- 未传入 `--experiment` 却自动进入 experimental 模式
- 把旧版规则文件升级误解为主动重构项目源码
- 把审计 / 性能 / 评估 / 复盘类报告直接平铺到 `docs/reports/`
- 把 `.claude/skills/`、`.ai/exports/` 当作事实源直接修改
- 未完成最小验证就宣称已通过
