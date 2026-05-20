# dt:project-skills

统一的项目级 AI skill 生命周期入口。以 `.ai/skills/` 为唯一事实源，并在更新 canonical source 后自动刷新项目里已经配置好的工具镜像，用于列出项目 skill、审计重复和重叠、在确认后同步更新、把成功实现沉淀成 skill，以及按需导出额外工具适配层。

---

## 功能特性

- 以 `.ai/skills/` 为唯一事实源，避免多工具副本漂移
- 优先复用 `dt:init` 写入 `.ai/README.md` 的 configured mirrors 记录
- `sync` / `promote` / `merge` 会自动同步到项目里已配置的工具镜像；未配置工具不创建、不刷新
- 支持 `list`、`audit`、`sync`、`promote`、`merge`、`export`
- 当用户说“帮我总结一下加到 skill 里”时，默认走 `promote`
- 写入前自动做重复检查、重叠检查、融合判断
- 更新前必须先给出 proposal 并等待用户确认
- Claude / Codex 等已配置镜像由同步流程自动维护；Copilot 或其他额外导出层按需生成

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
- 不直接手改 `.claude/skills/`、`.ai/exports/codex/`、Copilot 等导出层
- 只有项目里已配置的工具镜像会接收自动同步；否则只更新 canonical source
- 任何会改动 canonical source 的操作都必须先确认
- 如果只是旧 skill 的一个新边界，优先更新旧 skill，不要盲目新建

---

> 本文档由 SKILL.md 自动生成，请勿手动编辑。如需更新，请修改 SKILL.md 后运行 /dt:update-remote-plugins。
