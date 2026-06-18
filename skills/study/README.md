# dt:study

把已确认并修复的问题沉淀为用户级 memory 或个人规则；默认不修改当前项目、插件源文件或缓存副本。

---

## 功能

- 可从任意目录触发，调用目录只作为上下文来源
- 默认产出用户级 memory / personal rule，而不是回写 source skill
- 单次只处理一个根因，保持规则短、明确、可执行
- 当前运行环境没有 memory 写入工具时，输出可保存的 `Memory candidate`
- Claude/Codex 都不得默认修改当前项目或 `dev-tools-skills` 源文件

## 用法

- `/dt:study`
- `/dt:study 以后执行仓库维护类技能时，调用目录和执行目标必须分开`
- `把这次已确认并修复的问题整理成用户级 memory，规则写短一点`

---

> 本文档由 SKILL.md 自动生成，请勿手动编辑。如需更新，修改 SKILL.md 后运行 `/dt:update-remote-plugins`。
