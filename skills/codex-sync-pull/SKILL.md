---
name: dt:codex-sync-pull
description: "Codex configuration sync pull: apply the saved Codex config snapshot from this repository to the current macOS, Windows, or Linux machine."
argument-hint: "e.g. /dt:codex-sync-pull"
---

> 中文环境要求
>
> - 面向用户的回复、提示信息必须使用中文
> - 所有生成或更新的文件必须使用 UTF-8 编码且不带 BOM

# Codex Sync Pull

从 dev-tools-skills 仓库中的 `codex-sync/snapshot/` 读取已保存的 Codex 配置快照，并根据当前操作系统应用到本机 Codex 配置目录。

## When to Use

- 另一台机器已经运行过 `dt:codex-sync-push` 并推送到远程
- 当前机器需要同步 Codex hooks、prompts、用户级 skills 和平台匹配的配置
- Windows / macOS 之间需要共享同一套 Codex 工作流

## Execution Target

本 skill 可从任意目录触发，但执行目标始终是 `dev-tools-skills` 仓库。

- Claude：开始执行前先切换到已安装或已 clone 的 `dev-tools-skills` 仓库根目录
- Codex：wrapper 必须把工具 `workdir` 设置为 `dev-tools-skills` 仓库根目录
- 不得把调用目录当成同步脚本所在目录
- 所有相对路径（如 `scripts/codex-sync.js`、`codex-sync/snapshot/`）都相对于 `dev-tools-skills` 仓库根目录解析

## Safety Boundaries

pull 会先备份被覆盖的文件到：

```text
~/.codex-sync-backups/<timestamp>/
```

pull 不会写入或覆盖：

- `auth.json`
- sessions、logs、sqlite、cache、plugin cache
- `installation_id`

`config.toml` 会优先应用当前平台对应的清洗配置：

- macOS: `config.darwin.toml`
- Windows: `config.win32.toml`
- Linux: `config.linux.toml`

如果快照里没有当前平台的配置，pull 会跳过 `config.toml` 并继续同步其他内容。需要平台专属配置时，先在对应系统上执行一次 `dt:codex-sync-push` 生成该平台的配置文件。

## Execution

在 `dev-tools-skills` 仓库根目录执行：

```bash
git pull --rebase
node scripts/codex-sync.js pull
```

执行完成后，提示用户重启 Codex 或开启新线程，让配置、hooks 和 skills 生效。

## Expected Output

- 当前平台的 `~/.codex/config.toml` 被应用或被安全跳过
- `~/.codex/AGENTS.md`、`hooks.json`、`prompts/`、`hooks/` 被同步
- `~/.agents/skills/` 中的用户级 skills 被同步
- 覆盖前的旧文件已备份

## Notes

- Windows 上执行时使用 PowerShell 或 Codex 可用 shell 都可以；核心同步脚本是 Node.js，路径处理使用 Node `path` API。
- 如果同步后的 hook command 只包含 macOS 命令，应该在 `hooks.json` 中补充 `commandWindows`，再从源机器重新 push。
