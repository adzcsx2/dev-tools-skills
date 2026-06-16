---
name: dt:execute-loop
description: "Execute another skill command repeatedly in fresh serial subagents. Defaults to 3 runs and supports -N to set the run count."
argument-hint: "[-N] <command> <prompt> e.g. /dt:execute-loop -3 /dt:push 发布当前改动"
---

> **中文环境要求**
>
> 本技能运行在中文环境下，请遵循以下约定：
>
> - 面向用户的回复、确认提示和执行总结必须使用中文
> - AI 内部处理过程可以使用英文
> - 所有生成文件必须使用 UTF-8 编码
>
> ---

# execute-loop Skill

串行创建多个全新子代理，重复执行同一个后续 command + prompt。适合让多个没有前文上下文的代理按同一条命令独立推进同一个任务。

## When to Use

- 需要让同一个 skill command 被多个新子代理串行执行
- 希望每一轮都不继承上一轮对话上下文，只基于当前仓库状态和同一段输入重新判断
- 需要默认 3 轮，或显式指定执行轮数
- 需要复用已有 command skill，而不是把 loop 逻辑写进目标 skill

## Example Prompts

- `/dt:execute-loop /dt:push 发布当前改动`
- `/dt:execute-loop -3 /dt:push 发布当前改动`
- `/dt:execute-loop -2 /dt:update-docs 审计这次改动并更新相关文档`
- `$dt-execute-loop -3 $dt-push 发布当前改动`

---

## Command Parameters

| Parameter | Description |
| --------- | ----------- |
| no `-N`   | 默认执行 3 轮 |
| `-N`      | 执行 N 轮，例如 `-3` 表示 3 轮；N 必须是 1 到 10 的整数 |
| `command` | 必填。要交给子代理执行的 command，例如 `/dt:push`、`/dt:update-docs`、`$dt-push` |
| `prompt`  | 必填。传给目标 command 的完整需求文本 |

---

## Execution Contract

`execute-loop` 是编排技能，不直接实现目标 command 的业务逻辑。每一轮都必须让子代理读取并执行目标 command 对应的 skill。

核心约束：

- 串行执行：第 1 轮完成后才能启动第 2 轮，以此类推
- 全新上下文：每一轮都必须创建新的子代理，不复用上一轮子代理，也不继承当前对话上下文
- 输入一致：每一轮都传入完全相同的 `command + prompt`
- 状态基于仓库：每一轮只能基于当时的工作区真实文件、git 状态和目标 skill 规则判断
- 失败即停：任一轮执行失败、遇到目标 skill 要求人工决策的阻塞、或子代理能力不可用时，停止后续轮次
- 服从目标 skill：目标 command 的硬约束优先级高于 loop；例如 `/dt:push` 的不建分支、冲突处理、push 安全规则必须照常生效

## Parsing Rules

1. 读取原始参数文本。
2. 如果第一个 token 匹配 `^-([1-9][0-9]*)$`，把数字作为执行次数，并从参数中移除该 token。
3. 如果没有 `-N`，执行次数默认为 3。
4. 如果次数不是 1 到 10 的整数，停止并提示用户修正。
5. 剩余参数的第一个 token 是 `command`。
6. 剩余全部文本是 `prompt`，必须原样保留。
7. 如果缺少 `command` 或 `prompt`，停止并展示用法示例。

有效 command token 示例：

```text
/dt:push
/dt:update-docs
$dt-push
$dt-update-docs
```

## Subagent Mapping

### Claude Code

使用 Claude 的 Task / subagent 能力。每轮必须新建一个 Task，并明确要求子代理执行：

```text
请在一个全新上下文中执行以下命令和需求。

命令：<command>
需求：<prompt>

要求：
1. 先读取并遵循命令对应的 source skill / command 说明。
2. 只基于当前仓库真实状态执行。
3. 不依赖父对话或其他轮次的上下文。
4. 执行完成后用中文返回结果、验证情况和阻塞项。
```

### Codex

使用 Codex 当前会话可用的 subagent / multi-agent 能力。创建子代理时必须满足：

- `fork_context: false`，确保不继承当前线程上下文
- 每轮创建新的 agent，不复用旧 agent
- 如工具支持传入 skill item，可把目标 command 对应的 Codex wrapper skill 一并传入
- 如当前 Codex 环境没有可用子代理工具，停止执行并说明：当前环境无法满足 `execute-loop` 的核心要求

Codex 子代理 prompt 模板：

```text
请在全新上下文中执行以下 command skill。

Command: <command>
Prompt: <prompt>

执行要求：
1. 如果 command 是 `$dt-*`，先读取对应 Codex wrapper，再读取 source skill。
2. 如果 command 是 `/dt:*`，按 dev-tools-skills 映射读取对应 source skill。
3. 严格遵循目标 skill 的全部硬约束。
4. 不依赖父对话或其他轮次上下文。
5. 完成后用中文报告：已做事项、验证命令与结果、阻塞项。
```

## Execution Flow

### Step 0: Parse And Validate

按 Parsing Rules 得到：

- `run_count`
- `target_command`
- `target_prompt`

执行前回显：

```text
execute-loop 参数：
- 目标命令：<target_command>
- 执行轮数：<run_count>
- 需求：<target_prompt>
```

如果目标 command 明显不是当前环境可解析的 skill command，停止并提示用户改成 `/dt:*`、`/adt:*`、`$dt-*` 或 `$adt-*` 形式。

### Step 1: Capability Check

确认当前运行环境能创建子代理：

- Claude Code：Task / subagent 可用
- Codex：multi-agent / subagent 工具可用，且能以新上下文启动

如果不可用，停止执行。不得退化为在父上下文里循环执行，因为这会破坏本 skill 的核心语义。

### Step 2: Run Serial Loop

从 1 到 `run_count` 逐轮执行：

1. 输出当前轮次：`开始第 i/run_count 轮`
2. 创建全新子代理
3. 传入相同的 `target_command + target_prompt`
4. 等待该轮完成
5. 记录该轮状态：
   - `success`：正常完成
   - `blocked`：目标 skill 要求人工决策或环境缺失
   - `failed`：子代理执行失败或验证失败
6. 如果状态不是 `success`，停止后续轮次

### Step 3: Final Summary

最终输出必须包含：

- 目标命令
- 原始需求
- 计划轮数与实际完成轮数
- 每轮结果摘要
- 失败或阻塞原因（如有）
- 子代理报告的验证命令与结果

输出模板：

```text
execute-loop 执行总结
- 目标命令：<target_command>
- 计划轮数：<run_count>
- 完成轮数：<completed_count>

轮次结果：
1. <success|blocked|failed> - <摘要>
2. <success|blocked|failed> - <摘要>

验证：
- <命令或 not verified>：<结果>

遗留问题：
- <无或具体问题>
```

## Safety Rules

- 不允许因为 loop 需要继续而绕过目标 skill 的确认、冲突处理或安全限制
- 不允许把失败轮次的上下文注入下一轮继续尝试
- 不允许把 `run_count` 提升到用户未指定的次数
- 不允许并行执行，因为并行执行会让多个子代理同时写同一工作区，容易产生冲突
- 如果目标 command 会执行 git commit、push、删除、发布、部署等写入性操作，仍按用户给出的命令执行，但一旦目标 skill 停止或要求人工确认，`execute-loop` 必须停止
