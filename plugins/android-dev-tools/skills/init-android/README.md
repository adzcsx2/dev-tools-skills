# init-android

为 Android 项目生成或优化 claude.md，使 AI 工具能够快速理解项目的真实结构与构建方式，优先复用现有实现。

---

## 功能

- 检测真实项目结构（Gradle 配置和源码目录），而非套预设模板
- 合并已有规则文件（claude.md、common.mdc 等），不直接覆盖
- 生成简洁低 token 的 AI 指导文件（60-120 行），强调规则和复用优先级
- 检测语言混合情况（Java/Kotlin）、视图绑定方式（ButterKnife/ViewBinding/DataBinding）
- 识别复用入口：BaseActivity/BaseFragment、工具类、公共网络封装、资源规则
- 四个必须段落：AI 工作原则、单一事实来源、局部一致性规则、项目强约束
- 可选生成 checklist（API、依赖、模块），仅在明确请求时生成
- 不再自动更新 .gitignore，AI 生成文件可提交到版本控制共享

## 用法

```bash
/init-android
```

适用于：新项目初始化 AI 规则文件、现有项目 claude.md 瘦身降 token、AI 理解跑偏需要纠偏、旧项目/混合语言项目适配。

> 本文档由 SKILL.md 自动生成，请勿手动编辑。如需更新，修改 SKILL.md 后运行 `/adt:update-remote-plugins`。
