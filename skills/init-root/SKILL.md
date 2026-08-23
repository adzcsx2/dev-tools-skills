---
name: dt:init-root
description: "Initialize a multi-repository product root by running dt:init and dt:update-docs, isolating direct child Git repositories, creating root Git when missing, committing root initialization locally, and pushing root when a configured remote is available."
argument-hint: "[optional focus] [--dry-run]"
origin: dev-tools-skills
---

> Language Requirements
>
> - User-facing responses must be in Chinese
> - Generated root rule additions should follow the target file's existing language
> - All generated files must use UTF-8 encoding without BOM

# init-root Skill

`dt:init-root` 是多仓库产品根目录初始化编排入口。它不复制 `dt:init` 的内部流程；执行时先执行 `dt:init`，再执行 `dt:update-docs`，最后按 `dt:init` 的 Git topology 协议一次性完成根本地 commit 或根 remote push。

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
- Preserve its CodeGraph, docs taxonomy, `CLAUDE.md`, `AGENT.md`, Copilot config, `dt:install-project-hooks` final rule audit hook, review, and `.gitignore` behavior
- Preserve its direct-child Git detection, `.ai/init-root.yml`, root rule generation, and root/child index boundaries
- Pass through the user's optional focus when it helps stack detection
- If `--dry-run` is present, keep `dt:init` in dry-run mode
- Defer only `dt:init` Step 13 root Git finalization until Step 6 below, so `dt:update-docs` output joins the same root commit/push. This changes sequencing, not the Git policy

Do not reimplement or summarize `dt:init` inside this skill. If `dt:init` changes later, `dt:init-root` must pick up the new behavior by re-reading it.

### Step 2. Execute `dt:update-docs`

After `dt:init` completes, read and execute `skills/update-docs/SKILL.md`.

- Use normal incremental mode by default
- If `--dry-run` is present, run `dt:update-docs --dry-run`
- Build docs from actual root and child-project evidence
- The documentation focus is cross-project orientation: which child directory is frontend, backend, admin, mobile, shared library, infrastructure, or unknown

### Step 3. Refresh Child Git Evidence

Scan only direct child directories of the current root.

A child project is any direct child directory that contains a `.git` directory or `.git` file. Exclude hidden/system directories such as `.git`, `.claude`, `.codex`, `.codegraph`, `docs`, `node_modules`, `build`, `dist`, and `target`.

For each detected child project, collect:

- Directory name
- Whether it has `origin` remote
- Current branch when available
- Stack signals from its top-level build files

If no child git project is detected, write `unknown` in the summary and do not invent projects. Because this skill is specifically for a multi-repository root, do not initialize or commit root Git until at least one real direct child Git repository is confirmed.

### Step 4. Ignore Child Projects From Root Git

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
- Confirm no child project content is already present in the root index before root commit/push

### Step 5. Add Root Git Policy To `AGENT.md`

Update root `AGENT.md` with a concise "Multi-Repo Root Git Policy" section:

- Root and child repositories keep independent indexes, histories and remotes
- Running `dt:push` from root must orchestrate detected child git repositories from their own directories in stable order
- Any child failure stops later children and root processing
- Root without remote is committed locally; root with a uniquely selected remote is synced, committed and pushed after all children succeed
- Child projects are committed and pushed from their own repositories, never through root git staging
- Do not stage child project contents from the root repository
- Do not add/replace remotes or force-push unless the user explicitly asks

If `CLAUDE.md` or Copilot project instructions already contain git workflow sections, add the same rule there only when it is necessary for consistency. Avoid duplicating long text.

### Step 6. Finalize Root Git Topology Once

Complete `dt:init` Step 13 now, after `dt:update-docs`, child ignore, and root rule generation:

- Fully read and apply `skills/init/references/git-topology.md`
- Create root Git with `git init` when root has no independent `.git`
- Use `.ai/init-root.yml` as the only canonical init-root config; never write `docs/references/init-root.yml`
- Root without a usable remote: create the root initialization commit locally and use `commit_only_no_push`
- Root with a uniquely selected upstream/remote: use `commit_and_push_after_children`, sync safely, create the root initialization commit, and push the current root branch
- Do not add or rewrite root/child remotes, do not push child repositories during initialization, and never force-push
- If `--dry-run` is present, preview topology, files, commit and push target without any Git write

### Step 7. Verification

Verify with the smallest useful checks:

```bash
git status --short
git rev-parse --is-inside-work-tree
git remote -v
```

Also confirm:

- `.ai/init-root.yml` exists unless `--dry-run`
- Its `root_git_policy` matches the real root remote/upstream state
- Root `.gitignore` contains all detected child git project directories
- `AGENT.md` contains the multi-repo root git policy
- Claude/Codex final rule audit hook files generated by `dt:init` still exist unless `--dry-run`
- Final rule audit hook is present for generated Claude/Codex hook configs unless the user explicitly disabled that tool target
- Child repositories still have their own `.git`
- A root local commit exists; if root remote is usable, the root current branch is also pushed successfully

Report `not verified` for any check that cannot run.

## Boundaries

- Do not rewrite `dt:init`
- Do not copy `dt:init` reference content into this skill
- Do not run the full `dt:push` child orchestration automatically during initialization
- Do not commit or push child repositories during initialization
- Do not create, delete, or rewrite child project remotes
- Do not add or rewrite the root remote; only use a remote/upstream already configured by the user
- Do not create or switch root branches; detached HEAD stops root commit/push finalization
- Do not force-push
- Do not add child project files to the root commit
- Do not assume directory roles from names alone; use stack evidence where possible and mark unknown when unclear
