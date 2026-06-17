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

`install.sh` 和 `install.ps1` 会自动检测 Claude Code、VS Code Copilot 和 Codex。Claude Code 安装会先清理旧缓存、旧注册信息和旧 marketplace 目录，再按当前仓库 `.claude-plugin/plugin.json` 中的最新版本重新安装，避免 Claude 继续命中历史 skill 缓存。

如需单独清理，可使用：

```bash
./uninstall.sh
```

```powershell
.\uninstall.ps1
```

安装完成后，还会额外为 VS Code Copilot 注册全局 prompt，并为 Codex 同步兼容 skill wrapper（例如 `$dt-init`、`$dt-push`）。Codex 的 `/prompts:dt-*` alias 默认不生成；如需兼容旧入口，可设置 `DEV_TOOLS_SYNC_CODEX_PROMPTS=1`。

## 包含的 Skills

### 通用工具 — `dt:` 前缀

| Skill                      | 描述                                                                                                                                                                                                                                                                                                           |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `dt:init`                  | 通用项目初始化：识别真实技术栈并生成/优化 CLAUDE.md、AGENT.md、Copilot 配置，建立 `.ai/skills/` canonical skill 工作面，并生成 Claude/Codex 项目级 hook，用于 mirror refresh 和任务收尾规则审计                                                                                                                  |
| `dt:init-root`             | 多仓库产品根目录初始化：按顺序执行 `dt:init` 和 `dt:update-docs`，继承 Claude/Codex 项目级 hook 初始化，再配置根目录本地 git、子项目 `.gitignore` 忽略、root 只 commit 不 push 策略，以及根目录 `dt:push` 子仓库编排边界                              |
| `dt:study`                 | 修错回源：把已验证的 skill 失误直接沉淀回工作区里的源 SKILL，避免改在缓存副本上                                                                                                                                                                                                                                |
| `dt:push`                  | 一键发布工作流：自动暂存、拉取、按逻辑分组提交、推送，支持 --preview 预览                                                                                                                                                                                                                                      |
| `dt:execute-loop`          | 串行执行循环：用多个全新子代理重复执行同一个后续 command + prompt，默认 3 轮，支持 `-N` 指定次数                                                                                                                                                                                                                |
| `dt:update-remote-plugins` | 远程插件维护：更新配置与文档、验证 install 回流本地是否始终命中最新版本                                                                                                                                                                                                                                        |
| `dt:code-note`             | 多语言代码注释：自动检测语言类型并应用对应注释风格                                                                                                                                                                                                                                                             |
| `dt:to-public-cloudflare`  | Cloudflare 内网穿透：一键配置 Named Tunnel，自动侦察端口，自动部署全局 tunnel 管理脚本（tunnel-add/start/stop/remove/list），支持健康监测与自动重启                                                                                                                                                            |
| `dt:project-skills`        | 项目级 skill 生命周期：以 `.ai/skills/` 为唯一事实源，支持审计重复/重叠、确认后同步更新、把实现沉淀成 skill，可显式刷新 mirrors，并作为 Claude/Codex project hook 背后的 mirror refresh 规则源                                                                                                                 |
| `dt:work-report`           | 工作日报生成：基于 git log 和未提交改动，自动生成功能性中文日报（每条 ≤30 字），支持自然语言日期参数，并附可执行优化建议                                                                                                                                                                                       |
| `dt:local-worktree`        | 隔离本地开发 worktree：传入原仓库路径，在其同级目录生成独立 local 分支 worktree（`remote-<x>`→`local-<x>`）并执行 dt:init、审计重写 README，保证 CLAUDE.md/.ai/.claude/docs 等初始化产物不污染原分支、不被 push（CLAUDE.md 铁律 + PreToolUse hook 双拦截），合并业务代码时用白名单 checkout 脚本只带走真实源码 |
| `dt:update-docs`           | 跨平台文档自动生成：自动检测 Android/Flutter/其他项目类型，先审计代码改动，再全链路更新所有受影响文档 |
| `dt:codex-sync-push`       | Codex 配置同步推送：保存本机安全可迁移的 Codex 配置、hooks、prompts 和用户级 skills 到仓库，并继续执行 `dt:update-remote-plugins` |
| `dt:codex-sync-pull`       | Codex 配置同步拉取：从仓库快照按当前系统应用 macOS / Windows / Linux 平台专属配置，并同步 hooks、prompts 和用户级 skills |

### Android 工具 — `adt:` 前缀

| Skill                          | 描述                                                 |
| ------------------------------ | ---------------------------------------------------- |
| `adt:gradle-build-performance` | 诊断和优化 Gradle 构建性能 |
| `adt:android-i18n`             | 国际化：审计硬编码字符串，生成多语言资源 |
| `adt:android-fold-adapter`     | 折叠屏适配：诊断和修复折叠屏适配问题                 |
| `adt:android-e2e`              | E2E 视觉测试：基于 Midscene AI 的 Android 端到端测试 |

### Flutter 工具 — `fdt:` 前缀

> Flutter 文档更新已合并到 `dt:update-docs`，自动检测 Flutter 项目并应用对应规则。

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
├── scripts/
│   └── sync-dev-tools-skills-to-codex.js
├── skills/
│   ├── init/                     # dt:init
│   ├── init-root/                # dt:init-root
│   ├── study/                    # dt:study
│   ├── push/                     # dt:push
│   ├── execute-loop/             # dt:execute-loop
│   ├── update-remote-plugins/    # dt:update-remote-plugins
│   ├── code-note/                # dt:code-note
│   ├── to-public-cloudflare/     # dt:to-public-cloudflare
│   ├── project-skills/           # dt:project-skills
│   ├── work-report/              # dt:work-report
│   ├── local-worktree/           # dt:local-worktree
│   ├── update-docs/              # dt:update-docs (Android/Flutter/Generic)
│   ├── codex-sync-push/          # dt:codex-sync-push
│   ├── codex-sync-pull/          # dt:codex-sync-pull
│   ├── gradle-build-performance/ # adt:gradle-build-performance
│   ├── android-i18n/             # adt:android-i18n
│   ├── android-fold-adapter/     # adt:android-fold-adapter
│   └── android-e2e/              # adt:android-e2e
├── install.sh
├── install.ps1
├── uninstall.sh
└── uninstall.ps1
```

## 版本

v1.3.8

## License

MIT License
