---
name: adt:android-e2e
description: "Android E2E visual testing via Midscene. Launch app, navigate screens, verify UI elements, take screenshots. Powered by visual AI — no DOM or accessibility labels required."
argument-hint: Describe the test scenario (e.g., "验证知识库空状态页面显示", "检查登录流程")
applyTo: "**/*.kt, **/AndroidManifest.xml"
---

> **中文环境要求**
>
> 本技能运行在中文环境下，请遵循以下约定：
> - 面向用户的回复、注释、提示信息必须使用中文
> - AI 内部处理过程可以使用英文
> - 所有生成的文件必须使用 UTF-8 编码
>
> ---

# Android E2E Skill

Vision-driven Android E2E testing using `npx @midscene/android@1`. Operates entirely from screenshots — can interact with ALL visible elements on screen regardless of technology stack (native Android, WebView, Flutter, React Native).

## Prerequisites

### 1. ADB Device Connected

```bash
adb devices  # Should show at least one "device"
```

### 2. Midscene Model Configuration

Model credentials must be configured as environment variables (recommended: `~/.zshrc`):

```bash
export MIDSCENE_MODEL_NAME="GLM-4.6V"
export MIDSCENE_MODEL_FAMILY="glm-v"
export MIDSCENE_MODEL_BASE_URL="https://open.bigmodel.cn/api/paas/v4"
export MIDSCENE_MODEL_API_KEY="your-api-key"
```

Supported model families (Midscene v1.8.5+): `doubao-vision`, `doubao-seed`, `gemini`, `qwen2.5-vl`, `qwen3-vl`, `qwen3.5`, `qwen3.6`, `glm-v`, `auto-glm`, `auto-glm-multilingual`, `vlm-ui-tars`, `vlm-ui-tars-doubao`, `vlm-ui-tars-doubao-1.5`, `gpt-5`.

### 3. App Installed on Device

Build and install the APK before running E2E tests:

```bash
# Build
./gradlew assembleLocalEnvDebug
# Install
adb install -r app/build/outputs/apk/localEnv/debug/*.apk
```

## Commands

### `connect` — Connect to Device

```bash
npx @midscene/android@1 connect
npx @midscene/android@1 connect --deviceId emulator-5554
```

### `take_screenshot` — Capture Current Screen

```bash
npx @midscene/android@1 take_screenshot
```

After taking a screenshot, **copy it to the project's `docs/screens/` directory** for documentation:

```bash
mkdir -p docs/screens
# Midscene prints the screenshot path — copy it:
cp <screenshot-path> docs/screens/<descriptive-name>.png
```

### `act` — Perform Actions + Verify

Use `act` to interact with the device. It autonomously handles tapping, typing, scrolling, swiping, waiting, and navigation. Describe the goal in natural language:

```bash
npx @midscene/android@1 act --prompt "点击底部'知识库'标签，验证显示'还没有文件加入知识库'"
```

Batch related operations into a single `act` command:

```bash
npx @midscene/android@1 act --prompt "点击文件标签，找到一个PDF文件，长按它，在弹出菜单中点击'加入知识库'，验证 Toast 显示'已加入知识库'"
```

### `disconnect` — End Session

```bash
npx @midscene/android@1 disconnect
```

## Workflow

### Standard E2E Test Flow

1. **Launch app** via ADB (faster than Midscene navigation):
   ```bash
   adb shell am start -n com.vertu.vbox/com.vertu.vbox.ui.splash.SplashActivity
   ```

2. **Connect** Midscene:
   ```bash
   npx @midscene/android@1 connect
   ```

3. **Act + Verify** in a single command:
   ```bash
   npx @midscene/android@1 act --prompt "描述你的测试场景..."
   ```

4. **Take additional screenshots** and copy to `docs/screens/`:
   ```bash
   npx @midscene/android@1 take_screenshot
   cp <screenshot-path> docs/screens/<name>.png
   ```

5. **Disconnect** when done:
   ```bash
   npx @midscene/android@1 disconnect
   ```

### Screenshot Management

All E2E screenshots MUST be saved to the project's `docs/screens/` directory:

```bash
# Create directory if not exists
mkdir -p docs/screens

# After each take_screenshot or act command, save the screenshot
# Midscene prints: "Screenshot saved: /var/folders/.../screenshot-*.png"
cp /var/folders/**/screenshot-*.png docs/screens/<name>.png
```

Naming convention: `<screen-name>-<action>.png`
- `knowledge-empty-state.png`
- `knowledge-stats-cards.png`
- `login-success.png`

## Critical Rules

1. **Never run Midscene commands in the background.** Each command must finish before the next one starts.
2. **Run only one Midscene command at a time.** Wait for previous command to finish.
3. **Allow enough time** — Midscene commands involve AI inference, typical `act` takes 30-90 seconds.
4. **Always report results** — After completion, summarize: what was tested, key findings, screenshots saved.
5. **Save ALL screenshots to `docs/screens/`** — This is the mandatory output artifact.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| ADB not found | `brew install android-platform-tools` |
| Device not listed | Check USB connection, enable USB debugging |
| Device "unauthorized" | Accept the USB debugging prompt on device |
| Device "offline" | `adb kill-server && adb start-server` |
| 401 auth error | Check `MIDSCENE_MODEL_API_KEY` env var |
| Invalid model family | Check `MIDSCENE_MODEL_FAMILY` matches supported values |
| Command timeout | Wake device: `adb shell input keyevent KEYCODE_WAKEUP` |

## Checklist

Before marking E2E test complete:
- [ ] App launched and visible on device
- [ ] Midscene `act` command(s) executed successfully
- [ ] All assertions passed (verify with act prompts)
- [ ] Screenshots saved to `docs/screens/` with descriptive names
- [ ] Midscene disconnected
