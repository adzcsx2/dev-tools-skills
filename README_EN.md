# dev-tools-skills

A shared toolkit for Claude Code and VS Code Copilot, including universal project init, common tools, Android tools, and Flutter tools.

## Installation

**macOS / Linux:**

```bash
git clone git@github.com:adzcsx2/dev-tools-skills.git
cd dev-tools-skills
./install.sh --all
```

**Windows PowerShell:**

```powershell
git clone git@github.com:adzcsx2/dev-tools-skills.git
cd dev-tools-skills
.\install.ps1 -All
```

For selective installation, see `./install.sh --help`.

`install.sh` and `install.ps1` now clear old cache entries, stale registrations, and the previous marketplace directory before reinstalling the latest version from `.claude-plugin/plugin.json`, so Claude does not keep using an older cached skill.

For cleanup only, use:

```bash
./uninstall.sh
```

```powershell
.\uninstall.ps1
```

Installation also registers the global `/dt:init` and `/study` prompts for VS Code Copilot.

## Included Skills

### Common Tools — `dt:` prefix

| Skill                      | Description                                                                                                        |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `dt:init`                  | Universal project init: detect the real stack, generate or optimize CLAUDE.md, AGENT.md, Copilot instructions, and bootstrap a canonical `.ai/skills/` workspace for project-level AI skills |
| `dt:study`                 | Study verified skill mistakes: capture them back into the workspace source skill and avoid cached copies           |
| `dt:push`                  | One-push release workflow: auto stage, pull, logical-group commit, push with --preview support                     |
| `dt:update-remote-plugins` | Remote plugin maintenance: update docs and config, then verify install-based local refresh uses the latest version |
| `dt:code-note`             | Multi-language code annotation: auto-detect language and apply comment style                                       |
| `dt:to-public-cloudflare`  | Cloudflare tunnel: one-click Named Tunnel setup, auto-detect project port, deploy global tunnel management scripts (tunnel-add/start/stop/remove/list) with health monitoring and auto-restart |
| `dt:plan-doc`              | Task-scoped plan docs: generate a multi-phase doc set under `docs/plan/<task-slug>-<YYYY-MM-DD>/` with a progress pointer and subagent plan; after plan confirmation it pauses, recommends `haiku` or `sonnet`, and resumes when the user replies `继续` (no switch needed if already on the recommended model) |
| `dt:project-skills`        | Project-local skill lifecycle management: use `.ai/skills/` as the canonical source, audit duplicates/overlaps, sync updates after confirmation, promote successful changes into skills, and export Copilot/Codex adapters on demand |

### Android Tools — `adt:` prefix

| Skill                          | Description                                                             |
| ------------------------------ | ----------------------------------------------------------------------- |
| `adt:gradle-build-performance` | Diagnose and optimize Gradle build performance                          |
| `adt:update-docs`              | Audit code changes first, then update all affected Android project docs |
| `adt:android-i18n`             | i18n: audit hardcoded strings, generate multi-language resources        |
| `adt:android-fold-adapter`     | Foldable screen: diagnose and fix fold adaptation issues                |

### Flutter Tools — `fdt:` prefix

| Skill             | Description                                                             |
| ----------------- | ----------------------------------------------------------------------- |
| `fdt:update-docs` | Audit code changes first, then update all affected Flutter project docs |

## Project Structure

```text
dev-tools-skills/
├── .github/
│   ├── copilot-instructions.md
│   └── prompts/
│       ├── init.prompt.md        # VS Code Copilot /dt:init
│       └── study.prompt.md       # VS Code Copilot /study
├── .claude-plugin/
│   ├── marketplace.json
│   └── plugin.json
├── skills/
│   ├── init/                     # dt:init
│   ├── study/                    # dt:study
│   ├── push/                     # dt:push
│   ├── update-remote-plugins/    # dt:update-remote-plugins
│   ├── code-note/                # dt:code-note
│   ├── to-public-cloudflare/     # dt:to-public-cloudflare
│   ├── plan-doc/                 # dt:plan-doc
│   ├── project-skills/           # dt:project-skills
│   ├── gradle-build-performance/ # adt:gradle-build-performance
│   ├── update-docs-android/      # adt:update-docs
│   ├── android-i18n/             # adt:android-i18n
│   ├── android-fold-adapter/     # adt:android-fold-adapter
│   └── update-docs-flutter/      # fdt:update-docs
├── install.sh
├── install.ps1
├── uninstall.sh
└── uninstall.ps1
```

## Version

v1.3.0

## License

MIT License
