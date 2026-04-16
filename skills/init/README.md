# dt:init

统一的跨技术栈项目初始化入口。基于真实代码和配置生成或优化 CLAUDE.md、Copilot 项目级指令，建立 `/docs` 文档分类规则，并输出简洁的代码库 onboarding 摘要。

---

## 功能

- 支持 Android、Flutter、React、Python、Java、Node.js 等多种项目
- 检测真实构建文件、入口点、目录结构和现有编码约定
- 同时生成或优化 CLAUDE.md 与 Copilot 可读取的项目级配置
- 建立 `/docs` 文档根目录和标准分类映射，缺失时自动补齐必要目录
- 默认输出低 token 的 AI 规则文件，而不是长篇项目介绍
- 保留 Android 和 Flutter 的局部一致性强约束，同时适配其他技术栈
- 可在明确要求时生成经验证的 API、依赖、模块 checklist 文档
- 让后续 AI 复用既有文档分类目录，避免在 `/docs` 下创建同义重复目录或在根目录乱建文档
- 支持 `--experiment converge` 做新项目第一版或迁移早期的架构收敛
- 支持 `--experiment sync` 在新增目录、模块或文件结构后同步更新 AI 规则与路径映射
- 支持 `--dry-run` 先预览变更范围、风险、验证项和回滚点，再决定是否执行

## 用法

```bash
/dt:init

/dt:init web app --experiment converge --dry-run

/dt:init --experiment sync
```

---

> 本文档由 SKILL.md 自动生成，请勿手动编辑。如需更新，修改 SKILL.md 后运行 /dt:update-remote-plugins。
