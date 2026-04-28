# dt:init

统一跨技术栈项目初始化入口。基于真实代码和配置，生成或优化 CLAUDE.md、AGENT.md、Copilot 项目级指令，建立 `/docs` 分类规则，写入 AI vibe coding 约束，并输出简洁的代码库入门摘要。

---

## 功能特性

- 支持 Android、Flutter、React、Python、Java、Node.js 等项目
- 检测真实构建文件、入口点、目录结构和已有编码规范
- 生成或优化 CLAUDE.md、AGENT.md 及 Copilot 可读的项目配置
- 建立 `/docs` 根目录及标准分类体系，**强制创建缺失的标准分类目录**（plan、product、design、guide、modules、references、checklist、reports）
- 默认输出低 token 消耗的 AI 规则文件，而非冗长的项目介绍
- 写入 AI vibe coding 约束：小文件、单一职责、源文件 500 行偏好（含显式例外）、变更文件纪律、计划优先触发、最低验证要求、紧凑可检索文档
- 保留 Android 和 Flutter 本地一致性约束，适配其他技术栈
- 可在明确请求时生成已验证的 API、依赖和模块清单文档
- 确保后续 AI 复用已有文档分类目录，避免在 `/docs` 下创建语义重复目录或在仓库根目录散落文档
- 再次运行时自动升级旧版 init 生成的规则文件至当前 init skill 标准
- 支持 `--experiment converge` 用于新项目首次版本或早期迁移架构收敛
- 支持 `--experiment sync` 在新增目录、模块或文件结构后同步更新 AI 规则和路径映射
- 支持 `--dry-run` 预览变更范围、风险、验证项和回滚点后再执行

## 语言要求

**所有生成的文档文件（CLAUDE.md、AGENT.md、清单文件）必须使用英文。**

## 使用方法

```bash
/dt:init
/dt:init [optional focus]
/dt:init --experiment converge
/dt:init --experiment sync
/dt:init --experiment converge --dry-run
```

### 参数说明

| 参数                      | 说明                                                             |
| ----------------------- | -------------------------------------------------------------- |
| 无参数                     | 标准 init，只做侦察、总结和规则文件生成或优化，不允许主动改架构；如果项目已有旧版 init 产物，会增量升级到当前标准 |
| `[optional focus]`      | 可选关注模块、技术栈或目录范围，例如 `web app`、`android`，所有结论仍必须由真实代码验证          |
| `--experiment converge` | 启用架构收敛模式，用于新项目第一版或迁移早期对已落地结构做统一                                |
| `--experiment sync`     | 启用同步更新模式，用于已有架构在新增目录、模块或调用链后同步更新 AI 规则与路径映射                    |
| `--dry-run`             | 只输出侦察结果、变更预览、风险、验证项和回滚点，不落盘、不移动文件、不改配置                         |

> 注意：`--experiment` 只允许使用这个开关名，不接受其他别名。只写 `--experiment` 但未指定 `converge` 或 `sync` 时，需要先澄清意图。

---

> 本文档由 SKILL.md 自动生成，请勿手动编辑。如需更新，请修改 SKILL.md 后运行 /dt:update-remote-plugins。
