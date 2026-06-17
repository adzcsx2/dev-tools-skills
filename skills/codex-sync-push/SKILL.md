---
name: dt:codex-sync-push
description: "Codex configuration sync push: save safe local Codex config, hooks, prompts, and user skills into this repository, then run dt:update-remote-plugins."
argument-hint: "e.g. /dt:codex-sync-push"
---

> 中文环境要求
>
> - 面向用户的回复、提示信息必须使用中文
> - 所有生成或更新的文件必须使用 UTF-8 编码且不带 BOM

# Codex Sync Push

把当前机器上可迁移的 Codex 配置保存到 dev-tools-skills 仓库，然后执行远程插件更新流程，让另一台电脑可以拉取并应用。

## When to Use

- 本机修改了 Codex `config.toml`、`AGENTS.md`、hooks、prompts 或用户级 skills
- 需要把 macOS / Windows 的 Codex 配置同步到另一台机器
- 需要把当前配置保存到 dev-tools-skills 远程事实源

## Safety Boundaries

脚本只做白名单采集，且会排除本机私有状态：

- 不保存 `auth.json`
- 不保存 sessions、logs、sqlite、cache、plugin cache
- 不保存 `installation_id`
- 不保存项目 trust 列表、hook trusted hash、marketplace 本地路径
- 不保存由 dev-tools-skills 自动生成的 Codex wrapper skills

`config.toml` 会保存成平台专属清洗版本，例如 `config.darwin.toml` 或 `config.win32.toml`。push 只更新当前系统对应的配置文件，并保留快照里已有的其他平台配置文件。pull 时只应用当前平台对应的文件，避免把 macOS 配置覆盖到 Windows。

## Execution

必须在 dev-tools-skills 仓库根目录执行：

```bash
node scripts/codex-sync.js push
```

脚本完成后，必须继续执行 `dt:update-remote-plugins` 的完整流程：

1. 打开并读取 `skills/update-remote-plugins/SKILL.md`
2. 按该 skill 的 Required Workflow 执行
3. 确保本次新增或更新的 `codex-sync/snapshot/`、`scripts/codex-sync.js`、相关 skill、README、安装脚本和 marketplace metadata 被提交并推送
4. 推送成功后执行安装脚本回流本地

## Expected Output

- `codex-sync/snapshot/manifest.json`
- `codex-sync/snapshot/codex/config.<platform>.toml`
- 可迁移的 `codex/AGENTS.md`、`hooks.json`、`prompts/`、`hooks/`
- 非 dev-tools 自动生成的 `agents/skills/`

## Notes

- 如果 Windows 还没有自己的 `config.win32.toml`，Windows pull 会跳过 `config.toml`，但仍会同步 hooks、prompts 和 skills。先在 Windows 上运行一次 `dt:codex-sync-push` 后，仓库会同时拥有 Windows 平台配置，并在后续 pull 时使用它。
- 如需强制同步某个本机专属路径，优先把 hook 或 MCP 配置改成跨平台写法，而不是关闭安全过滤。
