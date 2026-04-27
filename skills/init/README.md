# dt:init

Unified cross-stack project initialization entry. Generates or optimizes CLAUDE.md, Copilot project-level instructions, establishes `/docs` taxonomy rules, and outputs concise codebase onboarding summary based on real code and configuration.

---

## Features

- Supports Android, Flutter, React, Python, Java, Node.js and other projects
- Detects real build files, entry points, directory structure, and existing coding conventions
- Generates or optimizes CLAUDE.md and Copilot-readable project configuration
- Establishes `/docs` root and standard category taxonomy, **forces creation of missing standard category directories** (plan, design, guide, modules, references, checklist, reports)
- Outputs low-token AI rule files by default, not lengthy project introductions
- Preserves Android and Flutter local consistency constraints, adapts to other tech stacks
- Can generate verified API, dependency, and module checklist documentation when explicitly requested
- Ensures subsequent AI reuses existing documentation category directories, avoiding duplicate semantic directories under `/docs` or scattered docs in repo root
- Supports `--experiment converge` for new project first version or early migration architecture convergence
- Supports `--experiment sync` to sync update AI rules and path mappings after adding directories, modules, or file structures
- Supports `--dry-run` to preview change scope, risks, verification items, and rollback points before execution

## Language Requirement

**ALL generated documentation files (CLAUDE.md, AGENT.md, checklists) MUST be in English.**

## Usage

```bash
/dt:init

/dt:init web app --experiment converge --dry-run

/dt:init --experiment sync
```

---

> This document is auto-generated from SKILL.md. Do not edit manually. To update, modify SKILL.md and run /dt:update-remote-plugins.
