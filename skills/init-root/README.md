# dt:init-root

多仓库产品根目录初始化编排入口：先执行 `dt:init`，再执行 `dt:update-docs`，最后补充根目录本地 git、子项目忽略规则和 push 策略。

## 功能

- 适用于前端、后端、管理端、移动端等子项目各自拥有 `.git` 的产品根目录
- 不复制 `dt:init` 逻辑；执行时直接读取并执行 `dt:init`
- `dt:init` 完成后继续执行 `dt:update-docs`，生成跨端定位文档
- 扫描根目录直接子级 git 项目，并写入根 `.gitignore`
- 在根目录初始化本地 git 仓库，但不配置 remote
- 在 `AGENT.md` 写入多仓库根目录 git 策略：root 只 commit 不 push，根目录 `dt:push` 可编排子项目各自 push
- 创建 `.ai/init-root.yml` 作为 root commit-only/no-push policy 标记，供 `dt:push` 识别 root 与子仓库编排边界

## 用法

```bash
/dt:init-root
/dt:init-root frontend backend
/dt:init-root --dry-run
```

## 行为说明

- 根目录用于 AI 理解整体项目、跨端关系、文档和协调状态
- 子项目仍保留各自 git 仓库和远程仓库
- 从根目录执行 `dt:push` 时，直接子级 git 仓库会在各自目录中按普通规则提交并推送
- root 仓库自身只提交根目录协调文件，不能 push，也不能从 root 暂存子项目内容

---

> 本文档由 SKILL.md 生成；如需更新，请修改 SKILL.md 后运行 `/dt:update-remote-plugins`。
