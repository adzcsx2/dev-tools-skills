# dt:plan-doc

> Persist a multi-phase engineering plan as a durable task-scoped doc set under `docs/plan/<task-slug>/`, complete with progress pointer and subagent plan so AI can resume across sessions without losing state. Execution prompts prefer `/ecc:plan`, then `/everything-claude-code:plan`, and degrade to plain-language resume prompts if the user declines installation.

## Install

Bundled with the `dev-tools-skills` plugin. See the repo root `README.md` for install instructions.

## Quick Start

```bash
/dt:plan-doc <task-slug>            # generate 5 docs
/dt:plan-doc <task-slug> test       # generate 7 docs (include test plan + cases)
/dt:plan-doc                        # interactive mode
```

Test mode is also enabled automatically if the prompt body contains `测试 / 回归 / 自测 / QA / 验证 / 用例 / test / regression / verification`.

## Execution Command Resolution

When `plan-doc` prints the first execution prompt for the generated docs, it resolves the command in this order:

1. `/ecc:plan`
2. `/everything-claude-code:plan`
3. Ask the user whether to install one of them
4. If the user declines, print a slash-command-free resume prompt instead of blocking generation

## What It Generates

```
docs/plan/<task-slug>/
├── README.md           # task index
├── 00-执行文档.md      # progress pointer + subagent plan + per-phase checklists
├── 01-架构设计.md      # core decisions
├── 02-开发规范.md      # dev guide
├── 03-修复路线图.md    # phase breakdown, rollback
├── 04-测试计划.md      # (test mode only)
└── 05-测试用例清单.md  # (test mode only)
```

## Key Feature: Progress Pointer

`00-执行文档.md` contains a YAML-in-HTML-comment pointer that any AI must read before doing any work:

```markdown
<!-- progress-pointer:start -->
current_phase: 2
current_phase_status: coding
last_updated: 2026-05-10T14:22:00Z
next_action: "Implement BleManager.applyTargetDiff updated branch"
blockers: []
<!-- progress-pointer:end -->
```

This means you can hand the task off across sessions/agents/humans without re-planning from scratch.

## Comparison

| Tool | Output | Use when |
| --- | --- | --- |
| `/ecc:plan` | Plan in conversation | One-session, no persistence |
| `/everything-claude-code:plan` | Alternate plan command | Same role when `/ecc:plan` is unavailable |
| `/dt:plan-doc` | Durable file set with progress pointer | Multi-session, multi-phase |
| `/dt:init` | Project-level AI rules | First time in a repo |
| `/ecc:prp-plan` | PRD-driven plan artifacts | Start from product spec |

## Relation to Project CLAUDE.md

Expects the host project to have a "Task-Scoped Documentation" rule (established by `dt:init`). If missing, `plan-doc` will remind you to run `dt:init` — it will NOT modify CLAUDE.md or any `.cursor/rules/*.mdc` on its own.

## Full Spec

See [SKILL.md](./SKILL.md) for execution flow, stack-specific subagent plans, anti-patterns, and examples.
