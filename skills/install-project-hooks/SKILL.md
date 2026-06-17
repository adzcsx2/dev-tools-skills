---
name: "dt:install-project-hooks"
description: "Install project-level Claude and Codex hooks for the current repository. Currently installs final-rule-audit and serves as the single registry for future project hooks."
argument-hint: "[--claude|--codex|--all] [--dry-run]"
origin: dev-tools-skills
---

> Language Requirements
>
> - User-facing responses must be in Chinese
> - Generated hook scripts and configuration comments should use English where practical, but hook runtime messages may be Chinese
> - All generated files must use UTF-8 without BOM

# install-project-hooks Skill

统一的项目级 hook 安装入口。`dt:init` 和其他初始化流程只调用本 skill，不再在各自 skill 中重复实现 hook 生成细节。

## Trigger

```text
/dt:install-project-hooks [--claude|--codex|--all] [--dry-run]
```

## Purpose

- 为当前项目安装 Claude Code 与 Codex 项目级 hooks
- 维护项目 hook registry，未来新增 hook 只在本 skill 中定义
- 当前唯一默认 hook 是 `final-rule-audit`
- 不安装 `.ai/skills` mirror refresh，不生成 `sync-project-skills.sh`，不注册 `PostToolUse`

## Command Parameters

- 无参数：等同 `--all`，同时安装 Claude 与 Codex 项目 hooks
- `--all`：安装 Claude 与 Codex hooks
- `--claude`：只安装 Claude hooks
- `--codex`：只安装 Codex hooks
- `--dry-run`：只输出将创建或合并的文件、hook 事件、风险和验证项，不写盘

若同时传入 `--claude` 和 `--codex`，按 `--all` 处理。

## Hook Registry

当前 registry：

| Hook | Event | Claude target | Codex target | Blocking |
| --- | --- | --- | --- | --- |
| `final-rule-audit` | `Stop` | Windows: `.claude/hooks/final-rule-audit.ps1`<br>Unix-like: `.claude/hooks/final-rule-audit.sh` | Windows: `.codex/hooks/final-rule-audit.ps1`<br>Unix-like: `.codex/hooks/final-rule-audit.sh` | fail-open by default |

新增 hook 时必须先更新本表，再更新对应安装、合并、验证规则。

## Required Outputs

Claude 目标文件：

```text
.claude/
├── settings.json
└── hooks/
    └── final-rule-audit.{ps1|sh}
```

Codex 目标文件：

```text
.codex/
├── hooks.json
└── hooks/
    └── final-rule-audit.{ps1|sh}
```

本 skill 不创建或维护：

- `.ai/skills/`
- `.ai/exports/`
- `.claude/skills/`
- `sync-project-skills.sh`
- `PostToolUse` mirror refresh hooks

## Shared Requirements

- 作用域必须是项目级配置，不写入用户级 `~/.claude/settings.json` 或 `~/.codex/config.toml`
- hook 类型使用 command hook
- `final-rule-audit` 使用 `Stop` 事件，`matcher` 使用空字符串
- 必须按当前操作系统生成并注册 hook：
  - Windows：生成 `final-rule-audit.ps1`，命令使用 `pwsh -NoProfile -ExecutionPolicy Bypass -File <hook-path>`
  - macOS / Linux / WSL：生成 `final-rule-audit.sh`，命令直接指向 `<hook-path>`
- 只注册当前操作系统对应的 managed hook command；如果已有本 skill 早期生成的另一平台 `final-rule-audit.{sh|ps1}` command，或旧版 Windows `powershell.exe ... final-rule-audit.ps1` command，必须从配置中移除，避免重复触发、Windows 调用 `.sh` 或回落到 Windows PowerShell 5.1
- 默认 fail-open：脚本默认返回 0，不能阻塞正常收尾
- 若项目未来明确要求阻断式收尾 gate，且当前工具 Stop hook 已验证支持阻断，才允许把脚本调整为非零返回
- hook 脚本不得自动修改业务代码；它只输出收尾审计要求，修复必须由 AI agent 在读取 hook 反馈后显式执行
- Windows PowerShell 脚本必须输出到 stdout，不写 stderr，避免 fail-open 提示在 PowerShell 里被渲染成红色错误
- Unix-like 脚本生成后必须 `chmod +x`；Windows PowerShell 脚本不执行 `chmod`

## final-rule-audit Behavior

`final-rule-audit.{ps1|sh}` 最少执行以下逻辑：

1. 定位当前工作目录所在 git 仓库；不是 git 仓库则成功退出
2. 收集 `git status --short` 输出；没有修改则成功退出
3. 输出固定中文提示，要求 AI 在最终回复前完成规则复审：
   - 重新读取适用规则：用户级规则、项目根规则、当前子项目规则、目录级规则
   - 检查所有已修改文件是否满足规则
   - 针对修改范围运行最小验证
   - 发现违反规则时先修复再回复
4. 输出已修改文件列表，帮助 agent 明确审计范围
5. 默认返回 0

推荐脚本内容可等价于：

Windows PowerShell：

```powershell
$repo = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repo)) {
    exit 0
}

$status = git -C $repo status --short 2>$null
if ($LASTEXITCODE -ne 0 -or $null -eq $status -or [string]::IsNullOrWhiteSpace(($status -join "`n"))) {
    exit 0
}

[Console]::Out.WriteLine(@'
[final-rule-audit] 检测到当前仓库存在未提交改动。最终回复前必须完成：
1. 重新读取适用规则：用户级规则、项目根规则、当前子项目规则、目录级规则。
2. 审计所有已修改文件是否违反规则、范围约束或项目约定。
3. 针对本次修改运行最小相关验证；无法运行时明确说明 not verified。
4. 发现违反规则时先修复，再回复用户。

已修改文件：
'@)

foreach ($line in $status) {
    [Console]::Out.WriteLine($line)
}

exit 0
```

Unix-like shell：

```bash
#!/usr/bin/env bash
set -u

repo="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
status="$(git -C "$repo" status --short 2>/dev/null)" || exit 0

if [ -z "$status" ]; then
  exit 0
fi

cat >&2 <<'EOF'
[final-rule-audit] 检测到当前仓库存在未提交改动。最终回复前必须完成：
1. 重新读取适用规则：用户级规则、项目根规则、当前子项目规则、目录级规则。
2. 审计所有已修改文件是否违反规则、范围约束或项目约定。
3. 针对本次修改运行最小相关验证；无法运行时明确说明 not verified。
4. 发现违反规则时先修复，再回复用户。

已修改文件：
EOF
printf '%s\n' "$status" >&2

exit 0
```

## Claude settings.json

Windows 推荐最小结构：

```json
{
  "skipDangerousModePermissionPrompt": true,
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File .claude/hooks/final-rule-audit.ps1",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

Unix-like 环境使用同一结构，但 command 改为 `.claude/hooks/final-rule-audit.sh`。

`skipDangerousModePermissionPrompt` 必须设为 `true`：用户的全局 `~/.claude/settings.json` 可能已配置此字段，但项目级 `.claude/settings.json` 会覆盖全局设置。若项目级缺少此字段，在项目目录下工作时 bypass 模式会被降级，导致频繁弹出权限确认。

若 `.claude/settings.json` 已存在：

- 读取现有配置
- 检查 `skipDangerousModePermissionPrompt` 是否已设为 `true`，若缺失则补上
- 按当前 OS 计算 expected command：
  - Windows：`pwsh -NoProfile -ExecutionPolicy Bypass -File .claude/hooks/final-rule-audit.ps1`
  - Unix-like：`.claude/hooks/final-rule-audit.sh`
- 检查 `hooks.Stop` 是否已包含 expected command
- 若已包含，跳过；若未包含，增量合并，不覆盖其他 hook 条目
- 若存在本 skill 早期生成的 stale managed command（例如 Windows 上的 `.claude/hooks/final-rule-audit.sh` 或 `powershell.exe ... .claude/hooks/final-rule-audit.ps1`），移除该 managed command 后再合并 expected command
- 若文件损坏且无法解析，先备份再重建

## Codex hooks.json

Windows 推荐最小结构：

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/hooks/final-rule-audit.ps1",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

Unix-like 环境使用同一结构，但 command 改为 `.codex/hooks/final-rule-audit.sh`。

若 `.codex/hooks.json` 已存在：

- 读取现有配置
- 按当前 OS 计算 expected command：
  - Windows：`pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/hooks/final-rule-audit.ps1`
  - Unix-like：`.codex/hooks/final-rule-audit.sh`
- 检查 `hooks.Stop` 是否已包含 expected command
- 若已包含，跳过；若未包含，增量合并，不覆盖其他 hook 条目
- 若存在本 skill 早期生成的 stale managed command（例如 Windows 上的 `.codex/hooks/final-rule-audit.sh` 或 `powershell.exe ... .codex/hooks/final-rule-audit.ps1`），移除该 managed command 后再合并 expected command
- 若文件损坏且无法解析，先备份再重建

Codex hook 是否已被信任由 Codex 运行时负责；本 skill 只生成项目级配置与脚本，不写用户级 trust state。

## Execution Workflow

1. Parse target tools：默认 `--all`，按参数裁剪 Claude/Codex
2. Detect project root：优先使用当前工作目录；若在 git 仓库内，记录 git root
3. Detect OS：Windows 选择 `.ps1` + `pwsh ... -File`，macOS / Linux / WSL 选择 `.sh`
4. If `--dry-run`：输出目标文件、将注册的 hook、合并策略和验证项后停止
5. Generate Claude hook files when selected
6. Generate Codex hook files when selected
7. Merge existing JSON config incrementally
8. Unix-like 环境对 generated hook scripts 执行 `chmod +x`
9. Verify files and hook registration

## Verification

至少检查：

```bash
test -x .claude/hooks/final-rule-audit.sh || true
test -x .codex/hooks/final-rule-audit.sh || true
test -f .claude/hooks/final-rule-audit.ps1 || true
test -f .codex/hooks/final-rule-audit.ps1 || true
```

并确认：

- Claude selected 时，`.claude/settings.json` 存在且 `hooks.Stop` 注册当前 OS 对应的 `final-rule-audit.{ps1|sh}` command
- Codex selected 时，`.codex/hooks.json` 存在且 `hooks.Stop` 注册当前 OS 对应的 `final-rule-audit.{ps1|sh}` command
- Windows selected 时，配置不得注册 `.claude/hooks/final-rule-audit.sh`、`.codex/hooks/final-rule-audit.sh` 或任何 `powershell.exe ... final-rule-audit.ps1` command
- 没有生成 `sync-project-skills.sh`
- 没有注册 `PostToolUse` mirror refresh hook

无法验证运行时事件语义时，在结果中标注 `not verified`。

## Boundaries

- 不修改业务代码
- 不修改用户级 Claude/Codex 配置
- 不安装 `.ai` 多端同步功能
- 不创建 `.ai/skills`、`.ai/exports`、`.claude/skills`
- 不删除用户已有 hook；只增量合并本 skill 管理的 hook
