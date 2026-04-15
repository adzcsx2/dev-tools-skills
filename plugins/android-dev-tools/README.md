# Android Dev Tools

All-in-one Android development toolkit for Claude Code.

## Version

2.11.3

## Included Skills

| Skill | Description |
|-------|-------------|
| `init-android` | Initialize claude.md for Android projects. Analyzes project structure, generates AI development guidelines, build environment config, and creates checklist documents in docs/checklist/. |
| `apply-remote-sign` | Automatically configure remote APK signing for Android projects. Supports Groovy DSL (build.gradle) and Kotlin DSL (build.gradle.kts). |
| `gradle-build-performance` | Debug and optimize Android/Gradle build performance. Use when builds are slow, investigating CI/CD performance, analyzing build scans, or identifying compilation bottlenecks. |
| `update-docs` | Auto-generate Chinese technical documentation for Android projects. Analyzes structure, generates interfaces, navigation, components, notifications, and API docs. |
| `android-i18n` | Audit Android project for hardcoded Chinese strings, generate i18n resource files, and refactor code to use string resources. |
| `android-fold-adapter` | Diagnose and fix Android foldable screen adaptation issues. Handles Activity recreation, window size changes, and multi-window mode. |
| `code-note` | Add Chinese comments to Kotlin/Java source files. Supports classes, methods, and complex logic. |
| `auto-ui-test` | Android UI automation testing with Midscene visual driver + ADB execution. Supports document-driven testing mode. |
| `update-remote-plugins` | Sync marketplace.json, plugin.json, and README files, then commit and push to remote. Also syncs to local Claude Code plugins directory. |

## Usage

```bash
# Initialize claude.md for Android project
/init-android

# Configure remote signing
/adt:apply-remote-sign

# Debug build performance
/adt:gradle-build-performance

# Generate documentation
/adt:update-docs

# Internationalization audit
/adt:android-i18n

# Foldable screen adaptation
/adt:android-fold-adapter

# Add Chinese comments
/adt:code-note

# UI automation testing
/adt:auto-ui-test

# Sync and publish plugin updates
/adt:update-remote-plugins
```

## Repository Structure

```
plugins/android-dev-tools/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── init-android/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── checklist-templates/
│   ├── apply-remote-sign/
│   │   └── SKILL.md
│   ├── gradle-build-performance/
│   │   └── SKILL.md
│   ├── update-docs/
│   │   └── SKILL.md
│   ├── android-i18n/
│   │   └── SKILL.md
│   ├── android-fold-adapter/
│   │   └── SKILL.md
│   ├── code-note/
│   │   └── SKILL.md
│   ├── auto-ui-test/
│   │   ├── SKILL.md
│   │   └── references/
│   └── update-remote-plugins/
│       └── SKILL.md
└── README.md
```

## Author

**adzcsx2** - [GitHub](https://github.com/adzcsx2)
