# Project Bootstrap

本文件定义 `dt:init` 如何建立项目级 AI 规则基线。`.ai/skills` 多端同步、configured mirrors、项目级 skill 元管理和工具镜像导出已经从默认 init 中移除。

## Bootstrap Scope

`dt:init` 只负责以下项目级初始化：

- 生成或增量升级 `CLAUDE.md`
- 生成或增量升级 `AGENT.md`
- 生成或增量升级 Copilot 项目级配置（`AGENTS.md` 或 `.github/copilot-instructions.md` 二选一）
- 建立 `/docs` 文档根目录和必要分类目录
- 仅在项目存在真实关注点或明确隔离价值时，建立 `docs/references/ai-rules/<topic>.md` scoped rules
- 委托 `dt:install-project-hooks` 安装项目级 Claude/Codex hooks

## Removed Defaults

默认不得再创建或维护：

- `.ai/skills/`
- `.ai/skills/registry.yml`
- `.ai/skills/.updates/`
- `.ai/README.md` 的 `## Configured Tool Mirrors`
- `.ai/exports/`
- `.claude/skills/`
- `sync-project-skills.sh`
- `PostToolUse` mirror refresh hook

如果旧项目已经存在这些路径，`dt:init` 不主动删除；只是不再把它们作为新标准继续强化，也不得在新生成的规则文件中要求继续使用它们。若用户明确要求清理旧产物，应先输出清理计划并等待确认。

## Project Rule Baseline

生成或升级规则文件时，至少写清：

- 结论必须来自真实代码、配置或目录扫描
- 复用优先、局部一致、最小改动
- 只修改与当前需求直接相关的文件
- 需求不清、跨 3+ 源码文件、改 public API / 数据模型 / 路由 / 权限 / 持久化格式时先计划
- 修改后运行最小相关验证；无法验证时明确写 `not verified`
- 文档默认归档到 `/docs` 标准分类
- 若项目安装了 final rule audit hook，最终回复前必须复审适用规则、已修改文件和验证结果

## Hook Delegation

项目级 hook 的唯一默认安装入口是：

```text
skills/install-project-hooks/SKILL.md
```

`dt:init` 在生成规则文件之后调用该 skill。`dt:init` 自身不得复制 hook 脚本正文，也不得直接维护 Claude/Codex hook registry。

## Boundaries

- 不把项目级 rules 和项目级 hooks 混成同一套协议
- 不把 `docs/references/ai-rules/` scoped rules 等同于 `.ai/skills/` 多端同步
- 不创建空的 `docs/references/ai-rules/<topic>.md`；只有项目有真实关注点或明确隔离价值时才创建
- 不主动删除旧 `.ai/skills` 产物；删除必须由用户明确要求并先确认计划
