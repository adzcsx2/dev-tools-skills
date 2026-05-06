# dev-tools-skills - AI Skills Repository

## Project Overview

This repository contains reusable AI skills for Claude Code and VS Code Copilot. Skills are organized under `skills/*/SKILL.md` and installed via shell scripts to local AI tool directories.

**Skills Organization**:
- `dt:*` - Universal tools (init, study, push, update-remote-plugins, code-note)
- `adt:*` - Android tools (gradle-build-performance, update-docs, i18n, fold-adapter, auto-ui-test)
- `fdt:*` - Flutter tools (update-docs)

**Technical Stack**: Shell scripts, PowerShell scripts, Markdown documents, YAML frontmatter, JSON configuration

## Directory Structure

```
dev-tools-skills/
├── skills/              # Skill source files (SKILL.md + README.md per skill)
├── .github/             # GitHub configuration
│   ├── copilot-instructions.md
│   └── prompts/         # VS Code Copilot prompts
├── .claude-plugin/      # Plugin metadata (plugin.json, marketplace.json)
├── docs/                # Documentation root
│   ├── plan/            # Plans, roadmaps, todos
│   ├── design/          # Architecture, ADR, specs
│   ├── guide/           # Usage, runbooks
│   ├── modules/         # Module documentation
│   ├── references/      # Reference materials
│   ├── checklist/       # Checklists
│   └── reports/         # Test, audit, performance reports
├── install.sh           # Unix installer
├── install.ps1          # Windows installer
├── uninstall.sh         # Unix uninstaller
└── uninstall.ps1        # Windows uninstaller
```

## Coding Conventions

### File Naming
- Use kebab-case for directories and files
- Skill directories use name without prefix (e.g., `init/` not `dt-init/`)

### SKILL.md Requirements
- All YAML frontmatter string values containing colons must be double-quoted
- Description should always use double quotes as a safe practice

### Git Commit Style
- Use conventional prefixes: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`
- Commit messages in Chinese

### Documentation Rules
- New documents go under `/docs` by default
- Standard categories: `plan`, `product`, `design`, `guide`, `modules`, `references`, `checklist`, `reports`
- Product docs, PRDs, user stories, acceptance criteria, and feature scope docs go under `/docs/product`
- Check for existing semantically equivalent directories before creating new ones
- Do not create duplicate directories with singular/plural variants (e.g., both `plan` and `plans`)

## Reuse Priority Principles

When modifying this project:
1. Search target file's directory for similar implementations first
2. Reuse existing patterns, utilities, and calling conventions
3. Prefer minimal changes, avoid unrelated refactoring
4. Maintain consistency with target directory and adjacent code
5. Do not introduce new architectures unless explicitly requested

## Key Entry Points

- Skill sources: `skills/*/SKILL.md`
- Plugin metadata: `.claude-plugin/plugin.json`
- Installer logic: `install.sh` / `install.ps1`
- Copilot prompts: `.github/prompts/*.prompt.md`

## Common Commands

```bash
# Install all skills
./install.sh --all

# Uninstall
./uninstall.sh

# Install specific skill
./install.sh dt:init
```

## Single Sources of Truth

- Version and metadata: `.claude-plugin/plugin.json`
- Skill list: `skills/` directory scan
- Installation logic: `install.sh` / `install.ps1`
- Project rules: `CLAUDE.md`, `AGENT.md`, `.github/copilot-instructions.md`

## Skill Creation Workflow

When asked to "create skill" in this project, create a slash-command skill:

1. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter (`name`, `description` double-quoted, `argument-hint`)
2. Generate `skills/<skill-name>/README.md` from SKILL.md
3. Add skill to `install.sh` category variable (`COMMON_SKILLS` / `ANDROID_SKILLS` / `FLUTTER_SKILLS`)
4. Add skill to `install.ps1` category variable
5. Add `"./skills/<skill-name>"` to `.claude-plugin/marketplace.json` skills array
6. Add row to `README.md` and `README_EN.md` skills tables
7. Run `./install.sh --all` to verify

Assign prefix group: `dt:` (common), `adt:` (Android), `fdt:` (Flutter). Use kebab-case for directory names without prefix.

## Validation

When adding, removing, or renaming skills:
1. Update `install.sh` skill list
2. Update `install.ps1` skill list
3. Update `.claude-plugin/marketplace.json` if applicable
4. Update root `README.md` skills table
5. Update root `README_EN.md` skills table
