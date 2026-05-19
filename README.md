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
| `dt:init`                  | 通用项目初始化：识别真实技术栈并生成/优化 CLAUDE.md、AGENT.md、Copilot 配置，建立 `.ai/skills/` 项目级 canonical skill 工作面与 AI 编码/文档约束 |
| `dt:study`                 | 修错回源：把已验证的 skill 失误直接沉淀回工作区里的源 SKILL，避免改在缓存副本上 |
| `dt:push`                  | 一键发布工作流：自动暂存、拉取、按逻辑分组提交、推送，支持 --preview 预览      |
| `dt:update-remote-plugins` | 远程插件维护：更新配置与文档、验证 install 回流本地是否始终命中最新版本         |
| `dt:code-note`             | 多语言代码注释：自动检测语言类型并应用对应注释风格                              |
| `dt:to-public-cloudflare`  | Cloudflare 内网穿透：一键配置 Named Tunnel，自动侦察端口，自动部署全局 tunnel 管理脚本（tunnel-add/start/stop/remove/list），支持健康监测与自动重启 |
| `dt:plan-doc`              | 任务聚合文档：在 `docs/plan/<task-slug>-<YYYY-MM-DD>/` 下生成含进度指针和子代理规划的多阶段计划文档集；确认计划后会暂停并提示切到 `haiku` 或 `sonnet`，已在推荐模型时可直接输入 `继续` 再生成文档 |
| `dt:project-skills`        | 项目级 skill 生命周期：以 `.ai/skills/` 为唯一事实源，支持审计重复/重叠、确认后同步更新、把实现沉淀成 skill，并按需导出 Copilot / Codex 适配层 |

### Android 工具 — `adt:` 前缀

| Skill                          | 描述                                              |
| ------------------------------ | ------------------------------------------------- |
| `adt:gradle-build-performance` | 诊断和优化 Gradle 构建性能                        |
| `adt:update-docs`              | 先审计代码改动，再全链路更新 Android 项目相关文档 |
| `adt:android-i18n`             | 国际化：审计硬编码字符串，生成多语言资源          |
| `adt:android-fold-adapter`     | 折叠屏适配：诊断和修复折叠屏适配问题              |

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

## 版本

v1.3.0

## License

MIT License
