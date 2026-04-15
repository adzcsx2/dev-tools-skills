# dev-tools-skills

Claude Code 开发工具技能集合，包含通用工具、Android 开发工具和 Flutter 开发工具。

## 安装

### 快速安装 (推荐)

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

### 选择性安装

安装时可选择需要的 plugin：

```bash
# macOS/Linux - 安装所有 plugin
./install.sh --all

# 只安装通用工具
./install.sh dev-tools

# 安装通用工具 + Android 工具
./install.sh dev-tools android-dev-tools

# 安装通用工具 + Flutter 工具
./install.sh dev-tools flutter-dev-tools
```

```powershell
# Windows - 安装所有 plugin
.\install.ps1 --all

# 只安装通用工具
.\install.ps1 dev-tools

# 安装通用工具 + Android 工具
.\install.ps1 dev-tools android-dev-tools
```

## 包含的 Plugins

### dev-tools (通用) — `dt:` 前缀

| Skill | 描述 |
|-------|------|
| `dt:push` | 一键发布工作流：自动暂存、拉取、逐文件提交、推送 |
| `dt:update-remote-plugins` | 插件管理：审计 skill、更新配置、同步到本地 |
| `dt:code-note` | 多语言代码注释：自动检测语言类型并应用对应注释风格 |

### android-dev-tools (Android) — `adt:` 前缀

| Skill | 描述 |
|-------|------|
| `adt:init-android` | 生成/优化 Android 项目的 claude.md |
| `adt:gradle-build-performance` | 诊断和优化 Gradle 构建性能 |
| `adt:update-docs` | 自动生成 Android 项目中文技术文档 |
| `adt:android-i18n` | 国际化：审计硬编码字符串，生成多语言资源 |
| `adt:android-fold-adapter` | 折叠屏适配：诊断和修复折叠屏适配问题 |
| `adt:auto-ui-test` | UI 自动化测试：Midscene 视觉驱动 + ADB 快速执行 |

### flutter-dev-tools (Flutter) — `fdt:` 前缀

| Skill | 描述 |
|-------|------|
| `fdt:init-flutter` | 生成/优化 Flutter 项目的 claude.md |
| `fdt:update-docs` | 自动生成 Flutter 项目中文技术文档 |

## 项目结构

```
dev-tools-skills/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace 注册
├── CLAUDE.md                     # 项目规则
├── install.sh                    # macOS/Linux 安装脚本
├── install.ps1                   # Windows 安装脚本
└── plugins/
    ├── dev-tools/                # dt: 通用工具
    │   ├── .claude-plugin/
    │   │   └── plugin.json
    │   └── skills/
    │       ├── push/
    │       ├── update-remote-plugins/
    │       └── code-note/
    ├── android-dev-tools/        # adt: Android 工具
    │   ├── .claude-plugin/
    │   │   └── plugin.json
    │   └── skills/
    │       ├── init-android/
    │       ├── gradle-build-performance/
    │       ├── update-docs/
    │       ├── android-i18n/
    │       ├── android-fold-adapter/
    │       └── auto-ui-test/
    └── flutter-dev-tools/        # fdt: Flutter 工具
        ├── .claude-plugin/
        │   └── plugin.json
        └── skills/
            ├── init-flutter/
            └── update-docs/
```

## 版本

- **dev-tools**: v1.0.0
- **android-dev-tools**: v2.15.0
- **flutter-dev-tools**: v1.1.0

## License

MIT License
