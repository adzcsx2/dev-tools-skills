# dt:plan-doc-tr

> Full pipeline: generate task-scoped documentation set via `dt:plan-doc`, then execute with strict TDD, then auto code review. Three-phase mandatory pipeline ensures no phase is skipped.

## Install

Bundled with the `dev-tools-skills` plugin. See the repo root `README.md` for install instructions.

## Quick Start

```bash
/dt:plan-doc-tr <task-slug>            # plan-doc + TDD + review
/dt:plan-doc-tr <task-slug> test       # include test plan docs
```

## Three-Phase Pipeline

| Phase | What Happens | Tool |
|-------|-------------|------|
| **Phase 1: Plan-Doc** | Generates task-scoped documentation set under `docs/plan/<slug>-YYYY-MM-DD/` | `dt:plan-doc` skill |
| **Phase 2: TDD** | Strict RED->GREEN->IMPROVE->REPEAT cycle, 80%+ coverage | `tdd-guide` agent |
| **Phase 3: Review** | Security, structure, patterns, style audit; auto-fix CRITICAL | `code-reviewer` agent |

## Phase 1 Detail

Phase 1 delegates entirely to `/dt:plan-doc`, which runs its full flow:

1. Restate requirements
2. Ask clarifying questions (if needed)
3. Emit generation plan -> **wait for** "yes"/"proceed"
4. Model-switch checkpoint -> **wait for** `继续`
5. Generate all docs
6. Print first execution prompt

After Phase 1 completes, the user must explicitly confirm to proceed with Phase 2 (TDD).

## Comparison

| Tool | Output | Use when |
|------|--------|----------|
| `/dt:plan-doc` | Document set only | Need docs, will implement separately |
| `/dt:plan-doc-tr` | Docs + TDD + Review | Full pipeline: plan, implement, review in one flow |
| `/ecc:plan-t-r` | In-conversation plan + TDD + Review | Quick plan without persistent docs |

## Full Spec

See [SKILL.md](./SKILL.md) for detailed execution flow, hard checks, self-check report format, and constraints.
