# 00 · 执行文档（Execution Log）

> **AI 必读**：进入本任务前，先读本文件的"当前进度指针"，再决定从哪里继续。
> 不要绕过进度指针直接执行。不要跳 Phase。

---

## 1. 当前进度指针

<!-- progress-pointer:start -->
```yaml
current_phase: 1
current_phase_status: not_started
last_updated: {{CREATED_TIMESTAMP}}
last_actor: main-agent
last_commit: null
next_action: "{{FIRST_NEXT_ACTION}}"
blockers: []
```
<!-- progress-pointer:end -->

### 进度指针字段定义

| 字段 | 说明 | 允许值 |
| --- | --- | --- |
| `current_phase` | 当前所在 Phase 编号 | 1~{{MAX_PHASE}} |
| `current_phase_status` | 当前 Phase 状态 | `not_started` / `planning` / `coding` / `self_testing` / `in_review` / `completed` / `blocked` |
| `last_updated` | 指针最近更新时间（ISO 8601 UTC） | 自动填 |
| `last_actor` | 最近操作者 | `main-agent` / `subagent:<name>` / `human` |
| `last_commit` | 最近提交的 git hash | `abc1234` 或 `null` |
| `next_action` | 下一步具体动作（一句话） | 纯文本 |
| `blockers` | 当前阻塞项 | 字符串数组，`[]` 表示无阻塞 |

---

## 2. 断点续做协议（AI 每次进入本任务前必跑）

1. **读指针**：打开本文件，读取第 1 节 `progress-pointer` 块。
2. **对齐状态**：根据 `current_phase` + `current_phase_status` 跳到第 5 节对应 Phase 的 Checklist。
3. **从最近未完成项继续**：找到第一个未勾选的 `[ ]`，从该项开始；不要重做已勾选项。
4. **完成一步**：勾选对应项 → 更新进度指针 → 追加第 6 节执行日志。
5. **遇到阻塞**：把 blocker 写入指针 `blockers` 数组，`current_phase_status=blocked`，停止并报告用户。
6. **切 Phase**：当前 Phase 全部勾选且验收通过，才能 `current_phase +1`。

**禁止**：跳 Phase、清空 Checklist 重做、省略执行日志追加。

---

## 3. 执行规划概览

{{PHASE_OVERVIEW_TABLE}}

---

## 4. 子代理规划（{{STACK}} 项目）

### 4.1 各 Phase 的推荐子代理

{{SUBAGENT_TABLE}}

### 4.2 调用协议

- **编码**：由 main-agent 主导；不委托。
- **构建修复**：构建/分析失败时委托给对应 build-resolver agent 做最小 diff 修复。
- **Review**：每个 Phase PR 发起前主动调用 reviewer agent 过一遍并落地反馈。
- **测试**：AI 不执行真机测试，输出自测脚本 + 日志关键字交给人工。
- **文档更新**：进度指针由 main-agent 自己更新；反哺阶段可调用 docs-updater agent 协助。

### 4.3 子代理调用禁区

- 不得用 subagent 做核心业务逻辑编码
- 不得用 subagent 更新进度指针（main-agent 责任）
- 不得用 subagent 决定跳过 checklist 项或切 Phase

---

## 5. Phase 详细 Checklist

{{PHASE_CHECKLISTS}}

---

## 6. 执行日志

按时间倒序追加。每完成一个 checklist 项或切换 Phase，必须追加一行。

| 时间 (UTC) | Actor | 事件 | Phase / Checklist | Commit |
| --- | --- | --- | --- | --- |
| {{CREATED_TIMESTAMP}} | main-agent | 任务创建，执行文档初始化 | Phase 1 · 准备 | - |

---

## 7. 执行指令模板（丢给 AI 的 prompt）

每个 Phase 开始前，先按下面顺序选择执行入口：

1. 优先用 `/ecc:plan`
2. 如果没有 `/ecc:plan`，改用 `/everything-claude-code:plan`
3. 如果两者都没有，先提示用户安装；若用户拒绝安装，则使用下方降级版 prompt

### 7.1 首选模板（有 slash plan command 时）

```text
{{PLAN_COMMAND}}

请先阅读 docs/plan/{{TASK_DIR}}/00-执行文档.md 第 1 节进度指针，
再阅读 01-架构设计.md、02-开发规范.md、03-修复路线图.md 对应 Phase 的小节。

按 00-执行文档.md 第 2 节的"断点续做协议"执行：
从 Phase {{N}} Checklist 的第一个未勾选项开始，完成一项就更新指针并追加执行日志。

约束：
- 严格遵守 02-开发规范.md 的禁止/必须项
- 不触碰上游单一事实源
- 只做 Phase {{N}} 范围，不要顺手做 Phase {{N+1}}
- 子代理调用遵守 00-执行文档.md 第 4 节规划表

完成 Phase {{N}} 所有 checklist 后，停下并输出下一步建议，不自动进入 Phase {{N+1}}。
```

其中 `{{PLAN_COMMAND}}` 只能替换为 `/ecc:plan` 或 `/everything-claude-code:plan`。

### 7.2 降级模板（用户拒绝安装时）

```text
请先阅读 docs/plan/{{TASK_DIR}}/00-执行文档.md 第 1 节进度指针，
再阅读 01-架构设计.md、02-开发规范.md、03-修复路线图.md 对应 Phase 的小节。

按 00-执行文档.md 第 2 节的"断点续做协议"执行：
从 Phase {{N}} Checklist 的第一个未勾选项开始，完成一项就更新指针并追加执行日志。

约束：
- 严格遵守 02-开发规范.md 的禁止/必须项
- 不触碰上游单一事实源
- 只做 Phase {{N}} 范围，不要顺手做 Phase {{N+1}}
- 子代理调用遵守 00-执行文档.md 第 4 节规划表

完成 Phase {{N}} 所有 checklist 后，停下并输出下一步建议，不自动进入 Phase {{N+1}}。
```

替换 `{{N}}` 为当前 Phase 号即可。

---

**上一份**：[README.md](./README.md) | **下一份**：[01-架构设计.md](./01-架构设计.md)
