---
name: dt:study
description: "Capture one verified lesson as user-level memory or a personal rule without modifying project files by default."
argument-hint: "[issue-summary]"
origin: dev-tools-skills
---

> 中文环境要求
>
> - 面向用户的回复、注释、提示信息必须使用中文
> - AI 内部分析可以使用英文
> - 所有生成或更新的文档必须使用 UTF-8 编码
> - 输出优先简洁、可执行，避免扩写成长篇复盘

# Study Skill

统一的用户级经验沉淀入口。用于把一次已经确认并修复的问题整理成可复用的个人规则或 memory，避免重复踩坑，而不是写冗长复盘或默认修改项目文件。

## Trigger

```text
/dt:study [target-skill] [issue-summary]
/dt:study [issue-summary]
```

## When to Use

- 某个问题已经确认根因并完成修复，需要沉淀为用户级记忆
- 需要把一次真实失误沉淀成 1 到 3 条可执行规则，而不是保留在对话里
- 需要跨项目复用个人偏好、流程边界、检查清单或安全约束
- 需要避免把一次经验误写进当前项目、插件缓存或 `dev-tools-skills` 源仓库

## Execution Target

本 skill 可从任意目录触发，但默认执行目标是用户级 memory / personal rule，不是当前项目，也不是 `dev-tools-skills` 仓库。

- Claude：优先使用可用的用户级记忆能力；没有记忆能力时，输出可保存的 `Memory candidate`
- Codex：wrapper 必须把调用目录视为上下文来源，不得把工具 `workdir` 指向调用目录后直接改文件
- 默认不修改当前项目文件、`dev-tools-skills` 源文件、`~/.claude` 缓存、marketplace 副本或安装结果
- 只有用户明确要求写入某个项目规则文件或修改某个 source skill 时，才切换到对应仓库修改流程

## Example Prompts

- `/dt:study 以后执行 dt:update-remote-plugins 时可以从任意目录触发，但命令工作目录必须切到 dev-tools-skills`
- `/dt:study 只补一个根因，不要写长复盘`
- `把这次已确认并修复的问题整理成用户级 memory，规则写短一点`
- `整理成可复用规则，但不要修改当前项目文件或插件源文件`

## Execution Flow

### 1. Confirm Memory Scope

先确认本次要沉淀的是用户级规则，而不是项目级文档或 source skill 修改。

强制约束：

- 默认不修改当前项目文件、`dev-tools-skills` 源文件、`~/.claude` 缓存、marketplace 副本或安装结果
- 调用目录只作为上下文来源；不得因为当前 cwd 是某个仓库就把经验写进该仓库
- 如果当前运行环境提供用户级 memory 写入工具，优先写入用户级 memory
- 如果没有可用的 memory 写入工具，只输出一条可保存的 memory 文本，不擅自创建替代文件
- 只有用户明确要求“写进某个项目规则文件”或“修改某个 skill 源文件”时，才转入对应项目/仓库修改流程

### 2. Capture Only One Root Cause

单次只沉淀一个根因。

- 先基于真实现象、已完成修复和用户确认的偏好确认唯一根因
- 一次只写 1 个根因
- 最终只落 1 到 3 条规则；超过 3 条说明范围过大，需要拆分下一次再写

### 3. Write A Memory Candidate

产出必须短、明确、可执行。

- 用第一人称或规则式表达，例如“当我执行 X 时，必须 Y”
- 包含触发条件、必须动作和禁止动作
- 避免绝对路径，除非该路径是用户级固定事实源且用户明确要求保留
- 不写事件经过、对话摘要、长篇复盘

### 4. Save Or Return

根据当前运行环境保存或返回结果。

- 有用户级 memory 工具：写入 memory 后报告已保存的规则摘要
- 无用户级 memory 工具：输出 `Memory candidate:` 后跟 1 到 3 条规则，提示当前环境未自动写入
- 如果规则只适用于某个项目，应明确标注项目范围；否则默认作为跨项目用户级偏好

### 5. Optional Escalation To Source Changes

只有用户明确要求时，才把 memory 转为文件修改。

- 写入项目规则文件时，先说明目标文件和范围
- 修改 `dev-tools-skills` source skill 时，必须切到 `dev-tools-skills` 仓库并遵循 `dt:update-remote-plugins`
- 不把“个人偏好”伪装成项目通用规则，除非用户明确要推广到项目

### 6. Example: wrapper 执行目录问题

如果某个 wrapper 可以从任意目录触发，但实际命令必须作用到固定仓库，说明“调用目录”和“执行目标”没有分清。

正确沉淀方式：

- 根因只写一个：wrapper 误把 invocation cwd 当成所有技能的执行目标
- 规则只保留最小必要约束，例如：
  1. 调用目录不等于执行目标；每个 wrapper 必须显式声明 workflow target
  2. 仓库维护类技能可从任意目录触发，但命令 workdir 必须切到事实源仓库
  3. 项目型技能才默认作用于 invocation cwd

## Acceptance Criteria

- 默认不修改当前项目、source skill、缓存、副本或安装目录
- 输出或保存的是用户级 memory / personal rule
- 本次只沉淀 1 个根因，且最终新增或改写的规则总数为 1 到 3 条
- 规则包含触发条件、必须动作和禁止动作
- 没有长篇复盘、事件流水账或不可执行的泛泛总结
- 如果当前环境无法自动写入 memory，已输出可保存的 `Memory candidate`

## Notes

1. 事实源是已验证的真实问题和用户确认的偏好，不是当前 cwd
2. 沉淀的是用户级可复用规则，不是事件经过
3. 一次只解决一个根因，避免把多个问题揉成模糊长段落
4. 能写 1 条 memory 就不要写 5 条；能用短规则表达就不要写长复盘
