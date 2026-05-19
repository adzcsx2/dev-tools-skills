# dt:project-skills

统一的项目级 AI skill 生命周期入口。只维护目标项目里的 canonical source：`.ai/skills/`，用于列出项目 skill、审计重复和重叠、在确认后同步更新、把成功实现沉淀成 skill，以及按需导出 Copilot / Codex 适配层。

---

## 功能特性

- 以 `.ai/skills/` 为唯一事实源，避免多工具副本漂移
- 支持 `list`、`audit`、`sync`、`promote`、`merge`、`export`
- 当用户说“帮我总结一下加到 skill 里”时，默认走 `promote`
- 写入前自动做重复检查、重叠检查、融合判断
- 更新前必须先给出 proposal 并等待用户确认
- 默认只维护 canonical source；Copilot、Codex 导出层按需生成

## 使用方法

```bash
/dt:project-skills list
/dt:project-skills audit
/dt:project-skills sync
/dt:project-skills promote
/dt:project-skills merge
/dt:project-skills export copilot
```

## 默认规则

- 项目级 skill 的唯一事实源是 `.ai/skills/`
- 不直接手改 `.claude/`、Copilot、Codex 等导出层
- 任何会改动 canonical source 的操作都必须先确认
- 如果只是旧 skill 的一个新边界，优先更新旧 skill，不要盲目新建

---

> 本文档由 SKILL.md 自动生成，请勿手动编辑。如需更新，请修改 SKILL.md 后运行 /dt:update-remote-plugins。
