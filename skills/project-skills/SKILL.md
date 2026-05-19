---
name: dt:project-skills
description: "Manage canonical project-local AI skills under .ai/skills/: list skills, audit duplicates or overlaps, sync updates with confirmation, promote successful changes into skills, merge overlapping skills, and export tool-specific adapters on demand. Use when the user says summarize this into a skill, add this to a skill, update a project skill, or export skills to Copilot or Codex."
argument-hint: "<list|audit|sync|promote|merge|export> [args]"
origin: dev-tools-skills
---

> 中文环境要求
>
> - 面向用户的回复、确认提示和审计结论必须使用中文
> - 默认生成或更新的项目级 canonical skill 文件使用英文，便于 Claude、Cursor、Copilot、Codex 共用
> - 所有生成文件必须使用 UTF-8 编码

# project-skills Skill

统一的项目级 AI skill 生命周期入口。它以 `.ai/skills/` 作为唯一事实源，并默认把 Claude 需要的 project skill 同步镜像到项目内 `.claude/skills/`。

## Trigger

```text
/dt:project-skills <list|audit|sync|promote|merge|export> [args]
```

## When to Use

- 用户说“帮我总结一下加到 skill 里”“把这次修改沉淀成 skill”“把上面的经验补到对应 skill”
- 需要检查项目里已有 skill 是否重复、重叠、可融合
- 需要把一次成功实现提炼成可复用的项目级 skill
- 需要同步更新 `.ai/skills/` 下的 canonical skill，并把 Claude 镜像同步到 `.claude/skills/`，但更新前必须先征求确认
- 需要按需导出 Copilot 或 Codex 适配层

## Core Model

### 1. Canonical Source Only

项目级 skill 的唯一事实源始终是：

- `.ai/skills/`
- `.ai/skills/registry.yml`
- `.ai/skills/.updates/`

强制规则：

- 只修改 `.ai/skills/` 下的 canonical skill 和注册表
- 不直接手改 `.claude/skills/`、Copilot、Codex 或其他工具导出层
- 如需导出到其他工具，必须从 `.ai/skills/` 派生

### 2. Claude-First Mirror, Others On Demand

默认会为 Claude 项目级工作流维护一个派生镜像：`.claude/skills/`；Copilot、Codex 等导出层只有在用户明确要求时才生成。

这意味着：

- `.ai/skills/` 仍是唯一事实源
- `sync`、`promote`、`merge` 在更新 canonical source 后，默认同步 `tool_exports` 包含 `claude` 的 skill 到 `.claude/skills/`
- `.claude/skills/` 是派生镜像，可被 `sync` 覆盖，不是手改入口
- `export copilot ...`、`export codex ...` 只有显式要求时才执行

### 3. Proposal Before Write

除 `list` 外，任何会改动 `.ai/skills/` 的操作都必须先给出 proposal，再等待用户确认。

## Required Project Layout

如果目标项目没有下面这些路径，先提示用户运行 `/dt:init`；只有在用户明确允许时，才按 `dt:init` 的 Phase 3.6 约束补同一套最小骨架：

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

## Command Modes

### `list`

列出当前项目已有 project skill：

- skill 名称
- 用途摘要
- 当前状态（active / deprecated / merged）
- 是否存在待确认的更新提案

### `audit`

审计 `.ai/skills/`，重点检查：

- 重复 skill
- `When to Use` 高度重叠的 skill
- 明显应该合并却被拆开的 skill
- 缺少 canonical 说明、缺少 registry 记录、缺少状态字段的 skill

### `sync`

用于更新已有 project skill，并默认刷新 Claude 项目级镜像，但必须先征求确认。

执行步骤：

1. 扫描 `.ai/skills/` 与 `registry.yml`
2. 判断哪些 skill 因最近改动、规则漂移或描述过时而需要更新
3. 生成 proposal，写明：
   - 建议更新哪个 skill
   - 为什么要更新
   - 是补充、重写局部还是合并
   - 影响哪些 canonical 文件
   - 会同步哪些 skill 到 `.claude/skills/`
4. 等用户确认后先更新 `.ai/skills/`
5. 再把 `tool_exports` 包含 `claude` 的 skill 复制到 `.claude/skills/`
6. 最后报告 canonical 变更和 Claude 镜像变更

### `promote`

把一次“已经验证有效的实现”提炼成项目级 skill。

如果用户只说“帮我总结一下加到 skill 里”，默认进入 `promote`。

执行步骤：

1. 先读取本次改动、对话总结和相关代码路径
2. 对照已有 `.ai/skills/*/SKILL.md` 做重复检查
3. 做重叠检查和可融合判断
4. 输出 proposal：
   - 更新现有 skill
   - 新建 skill
   - 融合多个 skill
5. 用户确认后先写入 canonical source
6. 若目标 skill 的 `tool_exports` 包含 `claude`，再同步复制到 `.claude/skills/`

### `merge`

当两个或多个 skill 已明显重叠时，合并为一个更清晰的 canonical skill，并在 `registry.yml` 中标记被合并项。

### `export`

按需从 `.ai/skills/` 生成工具适配层。

规则：

- 只有用户明确说“生成 Copilot 版本”“导出 Codex 版本”时才执行
- 导出层是 view，不是事实源
- 不允许跳过 canonical source 直接在导出层手改
- Claude 不走 `export`；Claude 项目级镜像默认由 `sync` / `promote` / `merge` 维护到 `.claude/skills/`
- `export copilot` 默认沿用 `dt:init` 的 Copilot 路径规则：已有 `AGENTS.md` 就更新 `AGENTS.md`，否则更新 `.github/copilot-instructions.md`
- `export codex` 默认写入 `.ai/exports/codex/` 派生视图；若项目已有明确 Codex 约定，才复用项目既有位置

## Duplicate, Overlap, And Merge Heuristics

判断时至少检查这四类信号：

1. `When to Use` 是否服务同一类场景
2. 核心执行步骤是否大体相同
3. 产物和验收标准是否相同
4. 是否只是旧 skill 的一个新案例或新边界

默认判断规则：

- 如果只是给已有 skill 增加一个新边界或一条新规则，优先更新旧 skill
- 如果两个 skill 目标场景基本相同，但表达方式不同，优先建议 merge
- 如果只是“本次实现的流水账”，不要直接沉淀；必须先提炼成可复用规则
- 单次 promote 优先沉淀最小必要规则，不要把多个根因揉成一个巨型 skill

## Proposal Format

在任何写入前，先给出最小 proposal：

```text
project-skills proposal
- action: update existing | create new | merge existing
- target: <skill-name or skill set>
- rationale: <why>
- duplicate-check: <result>
- overlap-check: <result>
- export-impact: canonical only | plus claude mirror | plus copilot | plus codex
- files-to-change:
  - .ai/skills/...
  - .ai/skills/registry.yml
  - .claude/skills/...
Please confirm before apply.
```

## Registry Minimum Fields

`registry.yml` 至少维护这些字段：

- `id`
- `name`
- `purpose`
- `origin` (`manual` / `promoted` / `synced`)
- `status` (`active` / `deprecated` / `merged`)
- `overlaps_with`
- `merged_into`
- `last_reviewed_at`
- `tool_exports`
- `update_policy`

默认值：

- `tool_exports: [claude]`
- `update_policy: manual_confirm`

## Acceptance Criteria

只有同时满足下面条件，才算完成：

1. canonical 改动只发生在 `.ai/skills/` source，`.claude/skills/` 只作为同步镜像更新
2. 在写入前已完成重复检查、重叠检查和融合判断
3. 在写入前已给用户看过 proposal 并获得确认
4. 若 `tool_exports` 包含 `claude`，相关 skill 已同步复制到 `.claude/skills/`
5. 如果涉及其他导出层，导出来源明确来自 `.ai/skills/`
6. 如果只是补充旧 skill 的局部边界，没有无意义新建 skill
7. 如果发现多个 skill 可融合，已明确给出 merge 建议而不是静默保留重复内容
