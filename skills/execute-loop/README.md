# dt:execute-loop

串行创建多个全新子代理，重复执行同一个后续 command + prompt。默认 3 轮，支持用 `-N` 指定轮数。

---

## 功能

- 包装已有 command skill，不复制目标 skill 的业务逻辑
- 每一轮都创建新的子代理，不继承父对话或上一轮上下文
- 串行执行，避免多个代理同时写同一工作区
- 默认执行 3 轮，可用 `-3`、`-2` 等形式指定次数
- 任一轮失败、阻塞或需要人工决策时，立即停止后续轮次

## 用法

- `/dt:execute-loop /dt:push 发布当前改动`
- `/dt:execute-loop -3 /dt:push 发布当前改动`
- `/dt:execute-loop -2 /dt:update-docs 审计这次改动并更新相关文档`
- `$dt-execute-loop -3 $dt-push 发布当前改动`

## 行为说明

- 第一个可选参数 `-N` 表示执行 N 轮；未提供时默认 3 轮
- N 必须是 1 到 10 的整数，避免误触发大量写入性任务
- `command` 可以是 `/dt:*`、`/adt:*`、`$dt-*`、`$adt-*` 等当前环境能解析的 skill command
- `command` 后的所有文本都会作为原始 prompt 透传给每一轮子代理
- Claude Code 下使用 Task / subagent 能力；Codex 下使用可用的 multi-agent / subagent 能力，并要求新 agent 不继承上下文
- 如果当前环境没有子代理能力，必须停止；不会退化为在父上下文里循环执行

---

> 本文档由 SKILL.md 自动生成，请勿手动编辑。如需更新，修改 SKILL.md 后运行 `/dt:update-remote-plugins`。
