# dt:install-project-hooks

项目级 hook 统一安装入口。支持 Claude Code 与 Codex，当前默认安装 `final-rule-audit`，未来新增项目 hook 时只维护本 skill 的 hook registry。

## 功能

- 生成 Claude 项目 hook：`.claude/settings.json`、当前 OS 对应的 `.claude/hooks/final-rule-audit.{ps1|sh}`
- 生成 Codex 项目 hook：`.codex/hooks.json`、当前 OS 对应的 `.codex/hooks/final-rule-audit.{ps1|sh}`
- 根据当前操作系统选择 hook 脚本：Windows 使用 `final-rule-audit.ps1` + `pwsh` 且提示输出到 stdout，macOS / Linux / WSL 使用 `final-rule-audit.sh`
- 只注册 `Stop` 事件
- 默认 fail-open，不自动修改业务代码
- 支持 `--claude`、`--codex`、`--all`、`--dry-run`
- 不安装 `.ai/skills` 多端同步，不生成 `sync-project-skills.sh`，不注册 `PostToolUse`

## 用法

```bash
/dt:install-project-hooks
/dt:install-project-hooks --claude
/dt:install-project-hooks --codex
/dt:install-project-hooks --dry-run
```

## 默认 hook

| Hook | Event | Claude target | Codex target |
| --- | --- | --- | --- |
| `final-rule-audit` | `Stop` | Windows: `.claude/hooks/final-rule-audit.ps1`<br>Unix-like: `.claude/hooks/final-rule-audit.sh` | Windows: `.codex/hooks/final-rule-audit.ps1`<br>Unix-like: `.codex/hooks/final-rule-audit.sh` |

---

> 本文档由 SKILL.md 生成；如需更新，请修改 SKILL.md 后运行 `/dt:update-remote-plugins`。
