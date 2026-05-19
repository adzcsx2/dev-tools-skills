# dev-tools-skills Project Rules

## Project Overview

AI Skills repository for Claude Code and VS Code Copilot. Provides a collection of reusable skills.

**Tech Stack**: Shell scripts, PowerShell scripts, Markdown documents

**Skills Organization**:

- `dt:*` - Common tools (init, study, push, update-remote-plugins, code-note)
- `adt:*` - Android tools (gradle-build-performance, update-docs, i18n, fold-adapter)
- `fdt:*` - Flutter tools (update-docs)

## Single Sources of Truth

- Version and metadata: `.claude-plugin/plugin.json`
- Skills list: `skills/` directory scan
- Installation logic: `install.sh` / `install.ps1`
- Project rules: `CLAUDE.md`, `AGENT.md`, `.github/copilot-instructions.md`

## Reuse Priority

Search target file's directory and similar implementations before modifying. Prioritize reusing existing patterns, common utilities, and established calling conventions.

## Local Consistency Rules

- Maintain consistency with target directory, adjacent code, and existing style
- Do not proactively introduce new architectures, new wrappers, or new libraries
- File naming uses kebab-case

## SKILL.md Frontmatter Rules

All SKILL.md YAML frontmatter string values containing colons `:` must be double-quoted.

```yaml
# Correct
description: "One-push release workflow: auto git add all changes, pull latest."
argument-hint: "[version] e.g. /dt:push 1.2.2"

# Wrong - colons will cause YAML parsing failure
description: One-push release workflow: auto git add all changes, pull latest.
```

**Rule of thumb**: Always double-quote description values.

## Directory Structure

```
dev-tools-skills/
├── skills/              # Skill source files (each skill contains SKILL.md + README.md)
├── .github/
│   ├── copilot-instructions.md
│   └── prompts/         # VS Code Copilot prompts
├── .claude-plugin/      # Plugin metadata
├── docs/                # Documentation root
├── install.sh / install.ps1
└── uninstall.sh / uninstall.ps1
```

## Documentation Rules

- New documents default to `/docs`
- Standard category directories: `plan`, `product`, `design`, `guide`, `modules`, `references`, `checklist`, `reports`
- Product docs, PRDs, user stories, acceptance criteria, and feature scope docs go under `/docs/product`
- Check `/docs` and existing categories for semantically equivalent directories before creating new ones
- Reuse existing semantically equivalent directories; do not create duplicate directories with similar names

**Current Status**: `/docs` and all standard category directories created, no existing semantically equivalent directories.

## Naming and Conventions

- Git commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:` prefixes, commit messages in Chinese
- Skill directories: no prefix (e.g., `init/` not `dt-init/`)
- File naming: kebab-case

## Skill Creation Workflow

When the user says "create skill" or "add skill" in this project, they mean creating a new command skill that can be invoked via slash command (e.g., `/dt:foo`, `/adt:bar`). Follow this workflow:

### Step 1: Create Skill Directory

```
skills/<skill-name>/SKILL.md    # Skill source (required)
skills/<skill-name>/README.md   # Generated from SKILL.md (required)
```

- Skill directory uses kebab-case, no prefix (e.g., `my-tool/` not `dt-my-tool/`)
- Assign to correct prefix group: `dt:` (common), `adt:` (Android), `fdt:` (Flutter)

### Step 2: SKILL.md Template

```yaml
---
name: <prefix>:<skill-name>
description: "<One-line description with double quotes>"
argument-hint: "[args] e.g. /<prefix>:<skill-name> ..."
---
```

- All YAML frontmatter string values containing colons MUST be double-quoted
- Always double-quote `description` as a safe practice

### Step 3: Register Skill in All Install Targets

After creating SKILL.md and README.md, update ALL of the following:

1. `install.sh` — add skill name to the correct category variable (`COMMON_SKILLS`, `ANDROID_SKILLS`, or `FLUTTER_SKILLS`)
2. `install.ps1` — add skill name to the matching category variable
3. `.claude-plugin/marketplace.json` — add `"./skills/<skill-name>"` to the skills array
4. Root `README.md` — add row to the correct skills table
5. Root `README_EN.md` — add row to the correct skills table

### Step 4: Verify

Run `./install.sh --all` to verify installation and confirm the skill is registered as a slash command.

## Validation Checklist

When adding, removing, or modifying skills:

1. `install.sh` skill list
2. `install.ps1` skill list
3. `.claude-plugin/marketplace.json` (if applicable)
4. Root `README.md` skills table
5. Root `README_EN.md` skills table
