# adt:update-docs

Android 项目文档自动生成工具，分析项目结构，生成中文技术文档，支持增量更新。

---

## 功能

- 分析 AndroidManifest.xml、build.gradle、Activity/Fragment、布局文件等生成多类型文档
- 支持增量更新：基于 Git 变更检测，只更新受影响的文档
- 生成的文档包括：项目概览、界面文档、导航文档、四大组件、通知文档、构建变体、依赖文档、API 文档
- 维护更新日志（CHANGELOG.md），每次更新生成详情文档并可链接跳转
- 将根目录散落的 md 文件迁移到 docs/ 目录集中管理
- 更新 README.md 显示最近更新摘要和文档快速链接
- 支持参数控制：`--force` 强制重新生成、`--dry-run` 仅分析不生成、按类型单独生成

## 用法

```bash
# 增量更新所有文档
/adt:update-docs

# 强制重新生成所有文档
/adt:update-docs --force

# 仅生成界面文档
/adt:update-docs interfaces
```

> 本文档由 SKILL.md 自动生成，请勿手动编辑。如需更新，修改 SKILL.md 后运行 `/adt:update-remote-plugins`。
