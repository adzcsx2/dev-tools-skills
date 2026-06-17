# Project Hook Bootstrap

本文件保留在 `dt:init` mandatory read order 中，用于说明项目 hook 初始化已经委托给 `dt:install-project-hooks`。文件名保持不变，避免破坏既有引用。

## Delegation Rule

`dt:init` 不再直接生成 hook 脚本或维护 hook registry。需要项目级 hook 时，必须读取并执行：

```text
skills/install-project-hooks/SKILL.md
```

当前默认安装的唯一 hook 是 `final-rule-audit`。

## Required Default Hooks

默认安装 Claude 与 Codex 两端项目 hooks，除非用户明确要求只初始化其中一种工具。

Claude Code 目标文件：

```text
.claude/
├── settings.json
└── hooks/
    └── final-rule-audit.{ps1|sh}
```

Codex 目标文件：

```text
.codex/
├── hooks.json
└── hooks/
    └── final-rule-audit.{ps1|sh}
```

`dt:install-project-hooks` 必须按当前操作系统选择 hook 脚本和 command：Windows 使用 `final-rule-audit.ps1` + `pwsh -NoProfile -ExecutionPolicy Bypass -File ...`，并将提示输出到 stdout；macOS / Linux / WSL 使用 `final-rule-audit.sh`。

若本次带 `--dry-run`，这些文件只输出预览，不写盘。

## Removed Hook Defaults

默认不得再生成或注册：

- `sync-project-skills.sh`
- `PostToolUse` mirror refresh hook
- `.ai/skills` canonical mirror refresh
- `.claude/skills` 自动同步
- `.ai/exports/codex` 自动同步

## Verification Requirements

`dt:init` 完成后必须确认：

- Claude selected 时，`.claude/settings.json` 注册当前 OS 对应的 `Stop -> final-rule-audit.{ps1|sh}` command
- Codex selected 时，`.codex/hooks.json` 注册当前 OS 对应的 `Stop -> final-rule-audit.{ps1|sh}` command
- Windows selected 时不得注册 `.sh` command；Unix-like selected 时生成的 `final-rule-audit.sh` 可执行
- 未生成 `sync-project-skills.sh`
- 未注册 `PostToolUse` mirror refresh hook

无法验证运行时事件语义时，在 onboarding 摘要中标注 `not verified`。

## Boundary

- hook 是执行层，不是规则源
- hook 安装细节以 `dt:install-project-hooks` 为准
- final rule audit hook 是收尾 gate，不替代 AI 对项目规则的理解与修复责任
