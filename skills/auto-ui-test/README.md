# auto-ui-test

智能化的 Android 真机 UI 测试工具，根据场景自动选择最优执行方式（Midscene 视觉驱动 / ADB 快速执行 / 混合模式）。

---

## 功能

- 直接执行测试任务，AI 自动判断执行模式
- 文档驱动测试，自动跳过已通过的用例，仅执行 FAIL/待验证/无状态的用例
- 三种执行模式：视觉驱动（Midscene + GLM-4.6V）、快速执行（ADB Shell 内联）、混合模式
- 智能模式选择：根据是否需要识别 UI 元素、是否已知坐标、是否需要精确时序自动决策
- 测试完成后自动生成测试报告
- 支持测试报告、Bug 报告、步骤列表等多种文档格式

## 用法

```bash
# 直接执行测试任务
/auto-ui-test 点击Toast按钮，等待3秒后截图
/auto-ui-test 打开设置页面，验证版本号是否显示

# 文档驱动测试（推荐）
/auto-ui-test docs/test/UI_TEST_REPORT.md
/auto-ui-test /path/to/bug-report.md
```

环境要求：ADB 已安装、Playground CLI 已启动、Midscene Agent 已集成。

> 本文档由 SKILL.md 自动生成，请勿手动编辑。如需更新，修改 SKILL.md 后运行 `/adt:update-remote-plugins`。
