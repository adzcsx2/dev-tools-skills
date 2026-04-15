# Project Guidelines

## Scope

This repository contains reusable AI skills and installation assets for Claude Code and VS Code Copilot.

## Editing Rules

- User-facing responses, comments, and generated docs should be in Chinese unless a file is explicitly English
- Keep SKILL.md files focused on actionable workflow rules, not long project introductions
- If a YAML frontmatter string contains a colon, wrap it in double quotes
- Prefer one unified cross-stack init workflow in skills/init/SKILL.md instead of stack-specific init variants

## Repository Conventions

- Skill sources live under skills/*/SKILL.md
- Per-skill README.md files are generated from SKILL.md and should stay aligned with the skill content
- Root README.md and README_EN.md must be updated when skills are added, removed, or renamed
- Installer changes must be mirrored in both install.sh and install.ps1
- Marketplace metadata lives in .claude-plugin/plugin.json and .claude-plugin/marketplace.json

## Copilot And Claude Support

- The unified init entrypoint is /init
- Project-level Copilot guidance should use .github/copilot-instructions.md unless a repo already standardizes on AGENTS.md
- Avoid maintaining both AGENTS.md and .github/copilot-instructions.md for the same workspace

## Validation

- When removing or merging skills, also clean up installer lists and marketplace skill registrations
- Preserve low-token, high-signal outputs for generated CLAUDE.md and Copilot instruction files