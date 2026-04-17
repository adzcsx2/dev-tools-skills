---
name: "study"
description: "study：围绕问题沉淀可复用结论，做根因分析与复盘，提炼规则和经验，形成持续演进的学习记录。"
argument-hint: "[target-skill] [issue-summary]"
agent: "agent"
model: ["GPT-5 (copilot)", "Claude Sonnet 4.5 (copilot)"]
---

基于当前工作区，将一次已确认并修复的 skill 问题沉淀回 source skill。

必须先判断这些前提：

- 先定位当前工作区仓库根，并确认存在 `skills/`、`.claude-plugin/plugin.json`、根 README 和安装脚本等 dev-tools-skills 结构
- 如果当前工作区没有对应仓库结构，必须明确拒绝，不执行落库
- 所有结论都只能基于当前工作区真实文件和目录

执行时必须遵循这些规则：

- 只允许修改仓库内的 source skill 文件，目标以 `skills/*/SKILL.md` 为准
- 严禁修改 `~/.claude` 下的任何缓存、安装产物或用户环境文件
- 禁止输出、依赖或引用绝对路径，只使用工作区相对路径表达
- 单次只处理一个根因，最终规则数控制在 1 到 3 条
- 编辑时优先改现有段落而不是新增大段重复内容
- 如果 source skill 的对外说明或使用预期发生变化，按需同步对应 skill README
- 只有在新增、删除、重命名 skill，或改到安装与发布面时，才同步根 README、installer 和 marketplace

输出要求：

- 先说明定位到的仓库根和目标 source skill
- 再给出准备落库的最小改动内容，保持中文、简短、可执行
- 如果信息不足以确定唯一根因，明确说明不足，不要硬写多条
