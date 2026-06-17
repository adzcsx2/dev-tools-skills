# dt:codex-sync-pull

从 dev-tools-skills 仓库中的 Codex 配置快照拉取并应用到当前机器，自动按 macOS / Windows / Linux 选择平台专属配置。

## 功能

- 从 `codex-sync/snapshot/` 应用已保存的 Codex 配置
- 根据当前系统选择 `config.darwin.toml` / `config.win32.toml` / `config.linux.toml`
- 同步 hooks、prompts、`AGENTS.md` 和用户级 skills
- 覆盖前自动备份旧文件到 `~/.codex-sync-backups/<timestamp>/`
- 不覆盖登录态、sessions、logs、sqlite、cache、plugin cache 和安装 ID

## 用法

```bash
/dt:codex-sync-pull
```

内部执行：

```bash
git pull --rebase
node scripts/codex-sync.js pull
```

> 本文档由 SKILL.md 自动生成，请勿手动编辑。如需更新，请修改 SKILL.md 后运行 `/dt:update-remote-plugins`。
