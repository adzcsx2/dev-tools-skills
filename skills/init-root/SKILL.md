---
name: dt:init-root
description: "Initialize a multi-repository project root by running dt:init first, then dt:update-docs, then configuring root commit-only/no-push behavior, child-repository ignores, and root-level dt:push orchestration boundaries. Use when a parent folder represents one product made from frontend/backend/other child repositories."
argument-hint: "[optional focus] [--dry-run]"
origin: dev-tools-skills
---

> Language Requirements
>
> - User-facing responses must be in Chinese
> - Generated root rule additions should follow the target file's existing language
> - All generated files must use UTF-8 encoding without BOM

# init-root Skill

`dt:init-root` 是多仓库产品根目录初始化编排入口。它不复制 `dt:init` 的内部流程；执行时必须先完整执行 `dt:init`，再完整执行 `dt:update-docs`，最后只追加根目录多仓库差异规则。

## Trigger

```text
/dt:init-root [optional focus] [--dry-run]
```

## Purpose

用于这类目录：

```text
product-root/
├── frontend/   # has its own .git and remote
├── backend/    # has its own .git and remote
└── admin/      # has its own .git and remote
```

根目录用于 AI 理解整体产品、前后端关系、文档和跨端定位；子项目仍保留各自 `.git` 和远程仓库。

## Execution Order

### Step 1. Execute `dt:init`

Read and execute `skills/init/SKILL.md` exactly as the source of truth.

- Follow its mandatory reference read order
- Preserve its CodeGraph, docs taxonomy, `.ai/skills/`, `CLAUDE.md`, `AGENT.md`, Copilot config, review, and `.gitignore` behavior
- Pass through the user's optional focus when it helps stack detection
- If `--dry-run` is present, keep `dt:init` in dry-run mode

Do not reimplement or summarize `dt:init` inside this skill. If `dt:init` changes later, `dt:init-root` must pick up the new behavior by re-reading it.

### Step 2. Execute `dt:update-docs`

After `dt:init` completes, read and execute `skills/update-docs/SKILL.md`.

- Use normal incremental mode by default
- If `--dry-run` is present, run `dt:update-docs --dry-run`
- Build docs from actual root and child-project evidence
- The documentation focus is cross-project orientation: which child directory is frontend, backend, admin, mobile, shared library, infrastructure, or unknown

### Step 3. Detect Child Git Projects

Scan only direct child directories of the current root.

A child project is any direct child directory that contains a `.git` directory or `.git` file. Exclude hidden/system directories such as `.git`, `.ai`, `.claude`, `.codegraph`, `docs`, `node_modules`, `build`, `dist`, and `target`.

For each detected child project, collect:

- Directory name
- Whether it has `origin` remote
- Current branch when available
- Stack signals from its top-level build files

If no child git project is detected, write `unknown` in the summary and do not invent projects.

### Step 4. Initialize Root Local Git

The root repository is local-only coordination state.

- If the current root is not a git repository, run `git init` in the root
- Do not add a remote to the root repository
- Do not change child repositories
- Create or update `.ai/init-root.yml` with the detected child project list and `root_git_policy: commit_only_no_push`
- This policy means the root repository itself is commit-only/no-push; `dt:push` from root may still orchestrate detected child git repositories from their own directories.
- If `--dry-run` is present, only preview these changes

### Step 5. Ignore Child Projects From Root Git

Ensure the root `.gitignore` contains an anchored block for detected child git projects:

```gitignore
# dt:init-root child repositories
/frontend/
/backend/
```

Rules:

- Keep existing `.gitignore` entries
- Update the existing `# dt:init-root child repositories` block if present
- Add only detected child git project directories
- Keep `.codegraph/` behavior from `dt:init`
- Do not write nested child paths unless they are direct children of root

### Step 6. Add Root Git Policy To `AGENT.md`

Update root `AGENT.md` with a concise "Multi-Repo Root Git Policy" section:

- Root repository is local-only coordination state
- Running `dt:push` from root may orchestrate detected child git repositories from their own directories
- Root files are committed only in the root repository and the root repository must not push
- Child projects are committed and pushed from their own repositories, never through root git staging
- Do not stage child project contents from the root repository
- Do not add a root remote unless the user explicitly asks

If `CLAUDE.md` or Copilot project instructions already contain git workflow sections, add the same rule there only when it is necessary for consistency. Avoid duplicating long text.

### Step 7. Verification

Verify with the smallest useful checks:

```bash
git status --short
git rev-parse --is-inside-work-tree
git remote -v
```

Also confirm:

- `.ai/init-root.yml` exists unless `--dry-run`
- Root `.gitignore` contains all detected child git project directories
- `AGENT.md` contains the multi-repo root git policy
- Child repositories still have their own `.git`

Report `not verified` for any check that cannot run.

## Boundaries

- Do not rewrite `dt:init`
- Do not copy `dt:init` reference content into this skill
- Do not run `dt:push` automatically
- Do not push the root repository
- Do not create, delete, or rewrite child project remotes
- Do not add child project files to the root commit
- Do not assume directory roles from names alone; use stack evidence where possible and mark unknown when unclear
