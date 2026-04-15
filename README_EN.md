# dev-tools-skills

A collection of Claude Code development tool skills, including cross-platform tools, Android development tools, and Flutter development tools.

## Installation

### Quick Install (Recommended)

**macOS / Linux:**
```bash
git clone git@github.com:adzcsx2/dev-tools-skills.git
cd dev-tools-skills
./install.sh
```

**Windows PowerShell:**
```powershell
git clone git@github.com:adzcsx2/dev-tools-skills.git
cd dev-tools-skills
.\install.ps1
```

### Selective Installation

Choose which plugins to install during setup:

```bash
# macOS/Linux - Install all plugins
./install.sh --all

# Only install common tools
./install.sh dev-tools

# Install common tools + Android tools
./install.sh dev-tools android-dev-tools

# Install common tools + Flutter tools
./install.sh dev-tools flutter-dev-tools
```

```powershell
# Windows - Install all plugins
.\install.ps1 --all

# Only install common tools
.\install.ps1 dev-tools

# Install common tools + Android tools
.\install.ps1 dev-tools android-dev-tools
```

## Included Plugins

### dev-tools (Common) — `dt:` prefix

| Skill | Description |
|-------|-------------|
| `dt:push` | One-push release workflow: auto stage, pull, per-file commit, push |
| `dt:update-remote-plugins` | Plugin management: audit skills, update configs, sync to local |
| `dt:code-note` | Multi-language code annotation: auto-detect language and apply comment style |

### android-dev-tools (Android) — `adt:` prefix

| Skill | Description |
|-------|-------------|
| `adt:init-android` | Generate/optimize claude.md for Android projects |
| `adt:gradle-build-performance` | Diagnose and optimize Gradle build performance |
| `adt:update-docs` | Auto-generate Chinese technical docs for Android projects |
| `adt:android-i18n` | i18n: audit hardcoded strings, generate multi-language resources |
| `adt:android-fold-adapter` | Foldable screen: diagnose and fix fold adaptation issues |
| `adt:auto-ui-test` | UI automation: Midscene visual-driven + ADB fast execution |

### flutter-dev-tools (Flutter) — `fdt:` prefix

| Skill | Description |
|-------|-------------|
| `fdt:init-flutter` | Generate/optimize claude.md for Flutter projects |
| `fdt:update-docs` | Auto-generate Chinese technical docs for Flutter projects |

## Project Structure

```
dev-tools-skills/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace registration
├── CLAUDE.md                     # Project rules
├── install.sh                    # macOS/Linux install script
├── install.ps1                   # Windows install script
└── plugins/
    ├── dev-tools/                # dt: Common tools
    │   ├── .claude-plugin/
    │   │   └── plugin.json
    │   └── skills/
    │       ├── push/
    │       ├── update-remote-plugins/
    │       └── code-note/
    ├── android-dev-tools/        # adt: Android tools
    │   ├── .claude-plugin/
    │   │   └── plugin.json
    │   └── skills/
    │       ├── init-android/
    │       ├── gradle-build-performance/
    │       ├── update-docs/
    │       ├── android-i18n/
    │       ├── android-fold-adapter/
    │       └── auto-ui-test/
    └── flutter-dev-tools/        # fdt: Flutter tools
        ├── .claude-plugin/
        │   └── plugin.json
        └── skills/
            ├── init-flutter/
            └── update-docs/
```

## Versions

- **dev-tools**: v1.0.0
- **android-dev-tools**: v2.15.0
- **flutter-dev-tools**: v1.1.0

## License

MIT License
