# dev-tools-skills

Claude Code 与 VS Code Copilot 通用开发工具技能集合，包含统一项目初始化、通用工具、Android 开发工具和 Flutter 开发工具。

## 安装

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

选择性安装请查看 `./install.sh --help`。

`install.sh` 和 `install.ps1` 现在会先清理旧缓存、旧注册信息和旧 marketplace 目录，再按当前仓库 `.claude-plugin/plugin.json` 中的最新版本重新安装，避免 Claude 继续命中历史 skill 缓存。

如需单独清理，可使用：

```bash
./uninstall.sh
```

```powershell
.\uninstall.ps1
```

安装完成后，还会额外为 VS Code Copilot 注册全局的 `/dt:init` 和 `/study` prompt。

## 包含的 Skills

### 通用工具 — `dt:` 前缀

| Skill                      | 描述                                                                            |
| -------------------------- | ------------------------------------------------------------------------------- |
| `dt:init`                  | 通用项目初始化：识别真实技术栈并生成/优化 CLAUDE.md 与 Copilot 项目级配置       |
| `dt:study`                 | 修错回源：把已验证的 skill 失误直接沉淀回工作区里的源 SKILL，避免改在缓存副本上 |
| `dt:push`                  | 一键发布工作流：自动暂存、拉取、逐文件提交、推送                                |
| `dt:update-remote-plugins` | 远程插件维护：更新配置与文档、验证 install 回流本地是否始终命中最新版本         |
| `dt:code-note`             | 多语言代码注释：自动检测语言类型并应用对应注释风格                              |

### Android 工具 — `adt:` 前缀

| Skill                          | 描述                                              |
| ------------------------------ | ------------------------------------------------- |
| `adt:gradle-build-performance` | 诊断和优化 Gradle 构建性能                        |
| `adt:update-docs`              | 先审计代码改动，再全链路更新 Android 项目相关文档 |
| `adt:android-i18n`             | 国际化：审计硬编码字符串，生成多语言资源          |
| `adt:android-fold-adapter`     | 折叠屏适配：诊断和修复折叠屏适配问题              |
| `adt:auto-ui-test`             | UI 自动化测试：Midscene 视觉驱动 + ADB 快速执行   |

### Flutter 工具 — `fdt:` 前缀

| Skill             | 描述                                              |
| ----------------- | ------------------------------------------------- |
| `fdt:update-docs` | 先审计代码改动，再全链路更新 Flutter 项目相关文档 |

## 项目结构

```
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
│   ├── push/                   # dt:push
│   ├── update-remote-plugins/  # dt:update-remote-plugins
│   ├── code-note/              # dt:code-note
│   ├── gradle-build-performance/
│   ├── update-docs-android/    # adt:update-docs
│   ├── android-i18n/
│   ├── android-fold-adapter/
│   ├── auto-ui-test/
│   └── update-docs-flutter/    # fdt:update-docs
├── install.sh
├── install.ps1
├── uninstall.sh
└── uninstall.ps1
```

## 版本

v1.1.4

## License

MIT License
