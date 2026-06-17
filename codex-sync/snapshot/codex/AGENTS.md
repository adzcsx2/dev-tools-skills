# Codex Global Instructions

## Claude instruction bridge

Before starting project work, read and apply the user-level legacy Claude
instructions from these files when they exist.

### User-level common rules

Always treat these as global personal guidance for every project:

- `~/.claude/CLAUDE.md`
- `~/.claude/AGENTS.md`
- `~/.claude/rules/**/*.md`
- `~/.claude/the-security-guide.md`

Use `~/.claude/agents/*.md`, `~/.claude/skills/**/SKILL.md`,
and `~/.claude/commands/**/*.md` as user-level workflow references
when the current task names or clearly matches one of those workflows. Do not
load old plans, histories, caches, logs, or transient session files as rules
unless the user explicitly asks.

### dev-tools-skills command bridge

Legacy Claude command skills from
`~/Documents/github/dev-tools-skills/skills/` are exposed to Codex as
generated wrappers under `~/.agents/skills/`. Map command names by
replacing `:` with `-`:

- `/dt:init` or `dt:init` -> `$dt-init`
- `/dt:push` or `dt:push` -> `$dt-push`
- `/dt:study` or `dt:study` -> `$dt-study`
- `/dt:update-docs` or `dt:update-docs` -> `$dt-update-docs`
- `/adt:android-i18n` or `adt:android-i18n` -> `$adt-android-i18n`

When the user invokes one of these legacy command names in plain text, use the
matching Codex wrapper skill. The wrapper then reads the current source
`SKILL.md` from the `dev-tools-skills` repository, so source skill updates are
picked up at use time. If skills are added, removed, or renamed in that repo,
refresh wrappers with:

```bash
node ~/.codex/scripts/sync-dev-tools-skills-to-codex.js
```

Generated slash prompt aliases also exist under `~/.codex/prompts/`,
for example `/prompts:dt-init`, but skills are the primary interface.

### Project-level rules

For each project, also check for legacy project instruction files near the
project root and current working directory:

- `CLAUDE.md`
- `claude.md`
- `AGENT.md`
- `agent.md`
- `.claude/rules/**/*.md`

Codex natively loads `AGENTS.md` and `AGENTS.override.md`. The fallback
filenames above are configured in `~/.codex/config.toml` for projects
that have only legacy Claude-style instruction files. If a directory contains
both `AGENTS.md` and legacy files, read the legacy files explicitly because
Codex loads at most one instruction file per directory during automatic
discovery.

When Claude-specific instructions reference unavailable tools such as Claude's
Task tool, map the intent to available Codex capabilities: use codegraph tools
for code exploration when available, use `multi_tool_use.parallel` for parallel
local reads, use Codex skills/plugins when applicable, and use subagents only
when subagent tools are available in the current session.

Instruction precedence is:

1. System, developer, and explicit user instructions for the current thread.
2. Project `AGENTS.md` / `AGENTS.override.md`, with closer nested files taking
   precedence.
3. Project legacy Claude instruction files.
4. This global Codex bridge and the user-level Claude files above.

Always answer the user in Chinese unless the user explicitly requests another
language. Preserve code identifiers, commands, logs, and file paths in their
original language.
