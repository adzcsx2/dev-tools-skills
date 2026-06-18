# dt:codex-sync-push

保存当前机器上可迁移的 Codex 配置、hooks、prompts 和用户级 skills 到 dev-tools-skills 仓库，然后执行 `dt:update-remote-plugins` 推送到远程。

## 功能

- 白名单采集 `~/.codex` 中可复用的配置文件
- 保存非 dev-tools 自动生成的 `~/.agents/skills`
- 排除登录态、sessions、logs、sqlite、cache、plugin cache、安装 ID 等本机私有状态
- 将 `config.toml` 保存为 `config.darwin.toml` / `config.win32.toml` 等平台专属清洗版本
- push 只更新当前系统对应的配置文件，并保留快照里已有的其他平台配置文件
- 保存完成后要求继续执行 `dt:update-remote-plugins`
- 可从任意目录触发，但执行目录必须切到 `dev-tools-skills` 仓库根目录

## 用法

```bash
/dt:codex-sync-push
```

内部执行：

```bash
node scripts/codex-sync.js push
```

> 本文档由 SKILL.md 自动生成，请勿手动编辑。如需更新，请修改 SKILL.md 后运行 `/dt:update-remote-plugins`。
