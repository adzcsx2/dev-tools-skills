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
| `dt:init`                  | Universal project init: detect the real stack and generate or optimize CLAUDE.md, AGENT.md, Copilot instructions, and AI coding/docs constraints |
| `dt:study`                 | Study verified skill mistakes: capture them back into the workspace source skill and avoid cached copies           |
| `dt:push`                  | One-push release workflow: auto stage, pull, logical-group commit, push with --preview support                     |
| `dt:update-remote-plugins` | Remote plugin maintenance: update docs and config, then verify install-based local refresh uses the latest version |
| `dt:code-note`             | Multi-language code annotation: auto-detect language and apply comment style                                       |
| `dt:to-public-cloudflare`  | Cloudflare tunnel: one-click Named Tunnel setup, auto-detect project port, deploy global tunnel management scripts (tunnel-add/start/stop/remove/list) with health monitoring and auto-restart |
| `dt:plan-doc`              | Task-scoped plan docs: generate a multi-phase doc set under `docs/plan/<task-slug>/` with a progress pointer and subagent plan for cross-session resume; optional test docs via `test` arg or prompt keywords |

### Android Tools — `adt:` prefix

| Skill                          | Description                                                             |
| ------------------------------ | ----------------------------------------------------------------------- |
| `adt:gradle-build-performance` | Diagnose and optimize Gradle build performance                          |
| `adt:update-docs`              | Audit code changes first, then update all affected Android project docs |
| `adt:android-i18n`             | i18n: audit hardcoded strings, generate multi-language resources        |
| `adt:android-fold-adapter`     | Foldable screen: diagnose and fix fold adaptation issues                |
| `adt:auto-ui-test`             | UI automation: Midscene visual-driven + ADB fast execution              |

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
│   ├── gradle-build-performance/ # adt:gradle-build-performance
│   ├── update-docs-android/      # adt:update-docs
│   ├── android-i18n/             # adt:android-i18n
│   ├── android-fold-adapter/     # adt:android-fold-adapter
│   ├── auto-ui-test/             # adt:auto-ui-test
│   └── update-docs-flutter/      # fdt:update-docs
├── install.sh
├── install.ps1
├── uninstall.sh
└── uninstall.ps1
```

## Version

v1.1.5

## License

MIT License
