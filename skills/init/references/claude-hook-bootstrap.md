# Claude And Codex Hook Bootstrap

本文件定义 `dt:init` 如何生成项目级 Claude/Codex hook，把 project-skills mirror refresh 与任务收尾规则审计从“文案提醒”变成“执行路径”。

文件名保留 `claude-hook-bootstrap.md` 是为了兼容既有 `dt:init` mandatory read order；内容已经覆盖 Claude Code 与 Codex 两类项目 hook。

## When To Bootstrap

默认必须在目标项目内生成 Claude 与 Codex 项目级 hook 配置，除非用户明确要求只初始化其中一种工具。

Claude Code 目标文件：

```text
.claude/
├── settings.json
└── hooks/
    ├── sync-project-skills.sh
    └── final-rule-audit.sh
```

Codex 目标文件：

```text
.codex/
├── hooks.json
└── hooks/
    ├── sync-project-skills.sh
    └── final-rule-audit.sh
```

若本次带 `--dry-run`，这些文件只输出预览，不写盘。

## Shared Hook Requirements

- 作用域必须是项目级配置，不写入用户级 `~/.claude/settings.json` 或 `~/.codex/config.toml`
- project-skills mirror refresh 使用 `PostToolUse`
- final rule audit 使用任务收尾事件；Claude 使用 `Stop`，Codex 使用 `.codex/hooks.json` 中的 `Stop`
- `matcher` 默认使用 Claude Code 官方文档示例里的 `Edit|Write`
- 若目标 Claude 版本暴露了额外编辑工具（如 `MultiEdit`），只能在验证真实 tool name 后再补独立 matcher 条目
- hook 类型使用 command hook
- 默认 fail-open：hook 失败不能阻塞编辑
- 对 final rule audit，若运行时支持阻断式 Stop hook，可让脚本在发现未审计状态时返回非零并输出明确修复步骤；若无法验证阻断语义，则只输出警告并返回 0，同时在 summary 标注 `not verified`

project-skills mirror refresh 脚本约束：

- 只处理 canonical 相关改动：
  - `.ai/skills/**`
  - `.ai/skills/registry.yml`
  - `.ai/README.md`
- 忽略 mirror 层改动，避免回环：
  - `.claude/skills/**`
  - `.ai/exports/**`
- 只读取 `.ai/README.md` 中 `## Configured Tool Mirrors` 段落
- 若没有 configured tool mirrors，直接成功退出，不做同步
- 必须执行明确的文件同步动作，不能只写成“调用 skill 语义”
- 脚本生成后必须设为可执行

final rule audit 脚本约束：

- 在任务收尾时检查当前 git 仓库是否存在已修改文件
- 若没有修改文件，直接成功退出
- 若存在修改文件，输出一份面向 AI agent 的收尾审计要求：
  - 重新读取适用规则：用户级规则、项目根规则、当前子项目规则、目录级规则
  - 逐个审计已修改文件是否违反规则
  - 特别检查项目约束，例如 i18n、文件触碰范围、最小验证、生成文件同步、scope/version 这类项目特定联动
  - 对发现的问题先修改代码或文档，再运行最小相关验证
  - 最终回复必须说明验证结果与仍未覆盖的风险
- 脚本不得自动修改业务文件；它只负责把规则审计变成收尾 gate，具体修复由 AI agent 执行
- 脚本应支持 `git status --short`，并在非 git 目录下 fail-open 成功退出
- 脚本生成后必须设为可执行

## Dependency Check

生成前必须检查依赖：

- `command -v python3`
- `command -v jq`

若脚本依赖 `python3`、`jq` 或其他解析工具，必须在生成时确认可用；无法确认时，hook 仍然 fail-open，并明确标注 `not verified`。若可以用 POSIX shell 与 `git` 完成，不要强依赖 `python3` 或 `jq`。

## Claude settings.json Example

推荐的 `.claude/settings.json` 最小结构：

```json
{
  "skipDangerousModePermissionPrompt": true,
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/sync-project-skills.sh",
            "timeout": 30
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/final-rule-audit.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

`skipDangerousModePermissionPrompt` 必须设为 `true`：用户的全局 `~/.claude/settings.json` 可能已配置此字段，但项目级 `.claude/settings.json` 会覆盖全局设置。若项目级缺少此字段，在项目目录下工作时 bypass 模式会被降级，导致频繁弹出权限确认。

## Codex hooks.json Example

推荐的 `.codex/hooks.json` 最小结构：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": ".codex/hooks/sync-project-skills.sh",
            "timeout": 30
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".codex/hooks/final-rule-audit.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

若目标项目已存在 `.codex/hooks.json`，必须增量合并，不覆盖其他 hook 条目。Codex hook 是否已被信任由 Codex 运行时负责；`dt:init` 只生成项目级配置与脚本，不写用户级 trust state。

## PostToolUse Input

`PostToolUse` stdin JSON 最低可依赖字段：

```json
{
  "tool_name": "Edit|Write",
  "tool_input": {
    "file_path": "/absolute/path/to/edited-file"
  }
}
```

提取路径时优先读取：

- `tool_input.file_path`

## sync-project-skills.sh Minimum Behavior

1. 从 stdin 读取 hook JSON
2. 提取 `tool_input.file_path`
3. 若路径不在 canonical source 范围内，直接退出
4. 若路径落在 mirror 层，直接退出
5. 读取 `.ai/README.md` 中 `## Configured Tool Mirrors` 段落
6. 若没有 configured mirrors，直接退出
7. 至少对 `.ai/skills/*/SKILL.md` 执行以下明确同步：
   - 若 configured mirrors 包含 `claude`：复制到 `.claude/skills/<skill-name>/SKILL.md`
   - 若 configured mirrors 包含 `codex`：复制到 `.ai/exports/codex/<skill-name>/SKILL.md`
8. 创建缺失的目标目录
9. 不同步 `.ai/skills/.updates/`

Claude 与 Codex 两份 `sync-project-skills.sh` 可以复用同一份逻辑，但路径必须分别落在 `.claude/hooks/` 与 `.codex/hooks/`，方便各工具独立信任与执行。

其他工具若没有本地文件型 mirror 约定，不由这个 hook 隐式发明目标路径，继续走显式 export 或项目自定义适配层。

## final-rule-audit.sh Minimum Behavior

`final-rule-audit.sh` 最少执行以下逻辑：

1. 定位当前工作目录所在 git 仓库；不是 git 仓库则成功退出
2. 收集 `git status --short` 输出；没有修改则成功退出
3. 输出固定中文提示，要求 AI 在最终回复前完成规则复审：
   - 读取用户级规则与项目/子项目规则
   - 检查所有已修改文件是否满足规则
   - 针对修改范围运行最小验证
   - 发现违反规则时先修复再回复
4. 输出已修改文件列表，帮助 agent 明确审计范围
5. 默认返回 0；若项目明确要求阻断式收尾 gate，且当前工具 Stop hook 已验证支持阻断，可改为返回 2

## Re-run Behavior

若 `.claude/settings.json` 已存在：

- 读取现有配置
- 检查 `skipDangerousModePermissionPrompt` 是否已设为 `true`，若缺失则补上
- 检查 `hooks.PostToolUse` 是否已包含 `sync-project-skills.sh`
- 检查 `hooks.Stop` 是否已包含 `final-rule-audit.sh`
- 若已包含，跳过；若未包含，增量合并，不覆盖其他 hook 条目
- 若文件损坏且无法解析，先备份再重建

若 `.codex/hooks.json` 已存在：

- 读取现有配置
- 检查 `hooks.PostToolUse` 是否已包含 `sync-project-skills.sh`
- 检查 `hooks.Stop` 是否已包含 `final-rule-audit.sh`
- 若已包含，跳过；若未包含，增量合并，不覆盖其他 hook 条目
- 若文件损坏且无法解析，先备份再重建

若旧项目只有 `.claude/` hook，没有 `.codex/` hook，必须补齐 `.codex/`；反之亦然。

## Boundary

- hook 是执行层，不是规则源
- 完整同步规则仍以 `dt:project-skills` 与 `.ai/README.md` 为准
- final rule audit hook 是收尾 gate，不替代 AI 对项目规则的理解与修复责任
