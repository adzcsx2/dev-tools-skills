# dev-tools-skills

A Claude Code development tools plugin with cross-platform tools, Android tools, and Flutter tools.

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

## Included Skills

### Common Tools — `dt:` prefix

| Skill | Description |
|-------|-------------|
| `dt:push` | One-push release workflow: auto stage, pull, per-file commit, push |
| `dt:update-remote-plugins` | Plugin management: audit skills, update configs, sync to local |
| `dt:code-note` | Multi-language code annotation: auto-detect language and apply comment style |

### Android Tools — `adt:` prefix

| Skill | Description |
|-------|-------------|
| `adt:init-android` | Generate/optimize claude.md for Android projects |
| `adt:gradle-build-performance` | Diagnose and optimize Gradle build performance |
| `adt:update-docs` | Auto-generate Chinese technical docs for Android projects |
| `adt:android-i18n` | i18n: audit hardcoded strings, generate multi-language resources |
| `adt:android-fold-adapter` | Foldable screen: diagnose and fix fold adaptation issues |
| `adt:auto-ui-test` | UI automation: Midscene visual-driven + ADB fast execution |

### Flutter Tools — `fdt:` prefix

| Skill | Description |
|-------|-------------|
| `fdt:init-flutter` | Generate/optimize claude.md for Flutter projects |
| `fdt:update-docs` | Auto-generate Chinese technical docs for Flutter projects |

## Version

v1.0.0

## License

MIT License
