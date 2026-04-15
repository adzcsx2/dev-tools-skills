# init-flutter

为 Flutter 项目生成或优化 claude.md，使 AI 工具能够快速理解项目结构并优先复用现有实现。

---

## 功能

- 从 pubspec.yaml 和源码目录检测真实项目结构
- 合并已有规则（claude.md、README）
- 生成简洁低 token 的 AI 指导文件
- 四个必须段落：AI 工作原则、单一事实来源、局部一致性规则、项目强约束
- 文档索引格式校验（仅合法 Markdown 链接）
- 可选生成 checklist（API、依赖、模块）
- 不主动将 claude.md 添加到 .gitignore

## 用法

```bash
/fdt:init-flutter
```

---

> 本文档由 SKILL.md 自动生成，请勿手动编辑。如需更新，修改 SKILL.md 后运行 `/fdt:update-remote-plugins`。
