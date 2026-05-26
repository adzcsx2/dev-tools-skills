# /adt:android-e2e — Android E2E 视觉测试

使用 Midscene 驱动的 Android 视觉 E2E 测试技能。基于截图的 AI 视觉识别，无需 DOM 或无障碍标签即可操作屏幕上任意可见元素。支持原生 Android、WebView、Flutter、React Native 等技术栈。

## 快速开始

```bash
# 1. 启动 App
adb shell am start -n <package>/<activity>

# 2. 连接 Midscene
npx @midscene/android@1 connect

# 3. 执行测试 + 验证
npx @midscene/android@1 act --prompt "点击知识库标签，验证空状态显示"

# 4. 截图保存
npx @midscene/android@1 take_screenshot
cp <截图路径> docs/screens/<名称>.png
```

## 前置条件

- ADB 设备已连接
- Midscene 模型已配置（`~/.zshrc` 中设置 `MIDSCENE_MODEL_*` 环境变量）
- App 已安装到设备

## 前置依赖

- [android-device-automation](https://midscenejs.com) — 底层 Android 自动化引擎

> 本文档由 SKILL.md 自动生成，请勿手动编辑。如需更新，请修改 SKILL.md 后运行 /dt:update-remote-plugins。
