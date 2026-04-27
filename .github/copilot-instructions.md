# Project Guidelines

## Scope

AI skills repository for Claude Code and VS Code Copilot. Skills are organized under `skills/*/SKILL.md`.

## Editing Rules

- User-facing responses and comments should follow user's preferred language
- **ALL generated documentation files (CLAUDE.md, AGENT.md, checklists) MUST be in English**
- Keep SKILL.md files focused on actionable workflow rules
- **SKILL.md frontmatter**: All string values containing colons must be double-quoted
- Use kebab-case for directories and files
- Git commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:` prefixes, Chinese messages

## Repository Conventions

- Skill sources: `skills/*/SKILL.md`
- Each skill has `README.md` generated from `SKILL.md`
- Installer changes must mirror in `install.sh` and `install.ps1`
- Metadata: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`

## Reuse Priority

When modifying:
1. Search target directory for similar implementations first
2. Reuse existing patterns and conventions
3. Prefer minimal changes
4. Maintain consistency with adjacent code

## Documentation Rules

- New documents go under `/docs` by default
- Standard categories: `plan`, `design`, `guide`, `modules`, `references`, `checklist`, `reports`
- Check for existing semantically equivalent directories before creating new ones
- Do not create duplicate directories (e.g., both `plan` and `plans`)

## Validation Checklist

When adding, removing, or renaming skills:
1. Update `install.sh` skill list
2. Update `install.ps1` skill list
3. Update `.claude-plugin/marketplace.json` if applicable
4. Update root `README.md` skills table
5. Update root `README_EN.md` skills table

## Entry Points

- Skill sources: `skills/*/SKILL.md`
- Plugin metadata: `.claude-plugin/plugin.json`
- Installer: `install.sh` / `install.ps1`
- Copilot prompts: `.github/prompts/*.prompt.md`