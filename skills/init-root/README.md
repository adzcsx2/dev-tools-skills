# dt:init-root

多仓库产品根目录初始化编排入口：先执行 `dt:init`，再执行 `dt:update-docs`，最后补充根目录本地 git、子项目忽略规则和 push 策略。

## 功能

- 适用于前端、后端、管理端、移动端等子项目各自拥有 `.git` 的产品根目录
- 不复制 `dt:init` 逻辑；执行时直接读取并执行 `dt:init`
- `dt:init` 完成后继续执行 `dt:update-docs`，生成跨端定位文档
- 扫描根目录直接子级 git 项目，并写入根 `.gitignore`
- 在根目录初始化本地 git 仓库，但不配置 remote
- 在 `AGENT.md` 写入多仓库根目录 git 策略：root 只 commit 不 push，子项目各自 push
- 创建 `.ai/init-root.yml` 作为 root-only git policy 标记，供 `dt:push` 识别

## 用法

```bash
/dt:init-root
/dt:init-root frontend backend
/dt:init-root --dry-run
```

## 行为说明

- 根目录用于 AI 理解整体项目、跨端关系、文档和协调状态
- 子项目仍保留各自 git 仓库和远程仓库
- 从根目录执行 `dt:push` 时只能提交根目录文件，不能 push
- 需要推送前端、后端等代码时，必须进入对应子项目目录分别执行 `dt:push`

---

> 本文档由 SKILL.md 生成；如需更新，请修改 SKILL.md 后运行 `/dt:update-remote-plugins`。
