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

Installation also registers a global `/dt:init` prompt for VS Code Copilot so the same init workflow can be triggered in any project.

## Included Skills

### Common Tools — `dt:` prefix

| Skill                      | Description                                                                                                        |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `dt:init`                  | Universal project init: detect the real stack and generate or optimize CLAUDE.md plus Copilot project instructions |
| `dt:push`                  | One-push release workflow: auto stage, pull, per-file commit, push                                                 |
| `dt:update-remote-plugins` | Remote plugin maintenance: update docs and config, then verify install-based local refresh uses the latest version |
| `dt:code-note`             | Multi-language code annotation: auto-detect language and apply comment style                                       |

### Android Tools — `adt:` prefix

| Skill                          | Description                                                      |
| ------------------------------ | ---------------------------------------------------------------- |
| `adt:gradle-build-performance` | Diagnose and optimize Gradle build performance                   |
| `adt:update-docs`              | Auto-generate Chinese technical docs for Android projects        |
| `adt:android-i18n`             | i18n: audit hardcoded strings, generate multi-language resources |
| `adt:android-fold-adapter`     | Foldable screen: diagnose and fix fold adaptation issues         |
| `adt:auto-ui-test`             | UI automation: Midscene visual-driven + ADB fast execution       |

### Flutter Tools — `fdt:` prefix

| Skill             | Description                                               |
| ----------------- | --------------------------------------------------------- |
| `fdt:update-docs` | Auto-generate Chinese technical docs for Flutter projects |

## Project Structure

```text
dev-tools-skills/
├── .github/
│   ├── copilot-instructions.md
│   └── prompts/
│       └── init.prompt.md        # VS Code Copilot /dt:init
├── .claude-plugin/
│   ├── marketplace.json
│   └── plugin.json
├── skills/
│   ├── init/                     # dt:init
│   ├── push/
│   ├── update-remote-plugins/
│   ├── code-note/
│   ├── gradle-build-performance/
│   ├── update-docs-android/
│   ├── android-i18n/
│   ├── android-fold-adapter/
│   ├── auto-ui-test/
│   └── update-docs-flutter/
├── install.sh
├── install.ps1
├── uninstall.sh
└── uninstall.ps1
```

## Version

v1.1.1

## License

MIT License
