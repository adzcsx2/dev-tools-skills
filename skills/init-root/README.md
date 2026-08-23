# dt:init-root

多仓库产品根目录初始化编排入口：先执行 `dt:init` 与 `dt:update-docs`，再隔离直接子 Git 仓库，并根据根仓库真实 remote 状态创建本地初始化提交或同步后推送根仓库。

## 功能

- 适用于前端、后端、管理端、移动端等子项目各自拥有 `.git` 的产品根目录
- 不复制 `dt:init` 逻辑；执行时直接读取并执行 `dt:init`
- 继承 `dt:init` 通过 `dt:install-project-hooks` 安装的 final rule audit 收尾审计 hook
- `dt:init` 完成后继续执行 `dt:update-docs`，生成跨端定位文档
- 扫描根目录直接子级 git 项目，并写入根 `.gitignore`
- 根目录没有独立 `.git` 时自动初始化根 Git，并创建本地初始化提交
- 根目录已有可唯一确定的 upstream/remote 时，安全同步、提交并推送根当前分支
- 在根规则文件中写入“子仓库稳定顺序优先、任一失败不处理 root、root 按实时 remote 决定本地提交或远程推送”的策略
- 创建 `.ai/init-root.yml`，使用 `commit_only_no_push` 或 `commit_and_push_after_children` 供后续 `dt:push` 识别

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
- root 仓库不能暂存子项目内容；全部子仓库成功后，root 无 remote 时仅本地提交，有 remote 时同步、提交并推送
- 初始化阶段不提交或推送子仓库，也不会自动添加、替换 remote 或 force-push

---

> 本文档由 SKILL.md 生成；如需更新，请修改 SKILL.md 后运行 `/dt:update-remote-plugins`。
