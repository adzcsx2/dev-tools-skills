---
name: adt:auto-ui-test
description: Android UI自动化测试 - Midscene视觉驱动 + ADB快速执行，支持文档驱动测试
compatibility: darwin, linux
---

> **中文环境要求**
>
> 本技能运行在中文环境下，请遵循以下约定：
> - 面向用户的回复、注释、提示信息必须使用中文
> - AI 内部处理过程可以使用英文
> - 所有生成的文件必须使用 UTF-8 编码
>
> ---

# Android UI 自动化测试

智能化的Android真机UI测试工具，根据场景自动选择最优执行方式。

## 使用方式

### 方式1: 直接执行测试任务

```bash
/auto-ui-test 点击Toast按钮，等待3秒后截图
/auto-ui-test 打开设置页面，验证版本号是否显示
```

### 方式2: 文档驱动测试（推荐）

```bash
/auto-ui-test docs/test/UI_TEST_REPORT.md
/auto-ui-test /path/to/bug-report.md
```

**智能过滤**：自动跳过状态为 PASS 的测试用例，仅执行 FAIL/待验证/无状态的用例。

---

## 执行模式

根据任务特征自动选择执行模式：

| 模式 | 适用场景 | 工具 | 优势 |
|------|---------|------|------|
| 视觉驱动 | 需要识别UI元素、动态判断 | Midscene + GLM-4.6V | 智能理解界面 |
| 快速执行 | 精确时序、竞态测试、批量操作 | ADB Shell内联 | 毫秒级响应 |
| 混合模式 | 先定位坐标，后快速执行 | 两者结合 | 兼顾精度和速度 |

### 模式选择指南

```
需要识别屏幕内容？
  ├─ 是 → Midscene视觉驱动
  └─ 否 → 已知精确坐标？
              ├─ 是 → 需要精确时序？
              │       ├─ 是 → ADB快速执行
              │       └─ 否 → 两者皆可
              └─ 否 → Midscene视觉驱动
```

---

## 环境配置

### 前置条件

1. **ADB已安装**
   ```bash
   # 验证ADB安装
   adb --version
   ```

2. **启动 Playground CLI**（用于调试和可视化操作）
   ```bash
   npx --yes @midscene/android-playground
   ```

3. **集成 Midscene Agent**（项目依赖）
   ```bash
   npm install @midscene/android --save-dev
   ```

### 设备准备

```bash
# 1. 开启USB调试（手机设置）
设置 → 关于手机 → 连续点击版本号7次 → 开发者选项 → USB调试

# 2. 连接设备并授权
adb devices
# 在手机上点击"允许USB调试"
```

### 详细文档

Midscene Android 完整配置指南: https://midscenejs.com/zh/android-getting-started.html

---

## 文档驱动测试

### 工作流程

```
1. 读取文档 → 2. 提取测试用例 → 3. 过滤PASS用例 → 4. 执行测试 → 5. 报告结果
```

### 测试用例过滤规则

| 状态 | 行为 |
|------|------|
| PASS / 已通过 / ✅ | **跳过** |
| FAIL / 待验证 / PENDING / ❌ | **执行** |
| 无状态标记 | **执行** |

### 支持的文档格式

#### 格式1: 测试报告

```markdown
## 测试用例: TC-001
**步骤**:
1. 点击"短Toast"按钮
2. 等待4秒
3. 点击"取消"按钮
**预期结果**: 应用不崩溃
**状态**: FAIL

## 测试用例: TC-002
**步骤**:
1. 进入设置页面
2. 点击关于
**预期结果**: 显示版本号
**状态**: PASS
```

#### 格式2: Bug报告

```markdown
## Bug: Toast连续点击崩溃
**复现步骤**:
1. 打开App
2. 快速连续点击Toast按钮
**预期**: 不崩溃
**实际**: 崩溃
**状态**: 待验证
```

#### 格式3: 步骤列表

```markdown
## 测试清单
- [x] 登录功能正常        ← 已通过，跳过
- [ ] 注销后数据清除      ← 待测试，执行
- [ ] 设置保存生效        ← 待测试，执行
```

### 执行后行为

测试完成后，询问用户是否更新原文档：
- 更新状态（FAIL → PASS 或标注新问题）
- 添加实际结果
- 更新测试时间

---

## Midscene视觉驱动模式

### 基本流程

```bash
# 1. 连接设备
npx @midscene/android@1 connect --deviceId DEVICE_ID

# 2. 执行操作
npx @midscene/android@1 act --prompt "点击列表中第三项"

# 3. 验证结果
npx @midscene/android@1 take_screenshot

# 4. 断开连接
npx @midscene/android@1 disconnect
```

### 最佳实践

```bash
# ✅ 每次只执行一个操作，等待完成
npx @midscene/android@1 act --prompt "点击短Toast按钮"

# ✅ 使用具体的UI元素描述
npx @midscene/android@1 act --prompt "点击列表中标记为'日志示例'的条目"

# ✅ 操作后截图验证
npx @midscene/android@1 act --prompt "点击按钮后等待3秒"
npx @midscene/android@1 take_screenshot
```

### 常见问题

```bash
# 设备黑屏/无响应
adb shell am force-stop com.example.app
adb shell am start -n com.example.app/.MainActivity

# Midscene连接问题
npx @midscene/android@1 disconnect
npx @midscene/android@1 connect --deviceId DEVICE_ID
```

---

## ADB快速执行模式

### 基本语法

```bash
# 多命令内联执行（设备端快速执行）
adb -s DEVICE_ID shell "cmd1 && sleep N && cmd2"
```

### 使用场景

| 场景 | 命令示例 |
|------|---------|
| 快速连续点击 | `adb shell "input tap 500 500 && sleep 0.1 && input tap 500 500"` |
| 点击后等待再操作 | `adb shell "input tap 1098 543 && sleep 1 && input tap 1098 1593"` |
| 竞态条件测试 | `adb shell "input tap x y && sleep 0.01 && input tap x y"` |
| 批量循环操作 | `adb shell "for i in 1 2 3 4 5; do input tap 500 500; sleep 0.1; done"` |

### 高级用法：设备端脚本

```bash
# 创建测试脚本
cat > /tmp/test.sh << 'EOF'
#!/system/bin/sh
input tap 500 500
sleep 0.1
input tap 500 600
sleep 0.1
input tap 500 700
EOF

# 推送并执行
adb push /tmp/test.sh /data/local/tmp/
adb shell "sh /data/local/tmp/test.sh"
```

### 适用场景判断

```
✅ 适用ADB快速执行：
   - 已知精确坐标
   - 需要精确时序控制
   - 批量重复操作
   - 测试竞态条件
   - AI执行速度不够快

❌ 不适用（使用Midscene）：
   - 需要根据屏幕内容动态判断
   - 需要验证UI显示结果
   - 复杂的用户交互流程
```

---

## 混合模式（最佳实践）

结合两者优势：Midscene定位坐标 → ADB快速执行

```bash
# Step 1: 使用Midscene定位元素坐标
npx @midscene/android@1 take_screenshot
# 分析截图，获取按钮坐标: (1098, 543)

# Step 2: 使用ADB快速执行精确时序操作
adb shell "input tap 1098 543 && sleep 0.01 && input tap 1098 543"

# Step 3: 使用Midscene验证结果
npx @midscene/android@1 take_screenshot
```

---

## 测试报告生成

### 强制要求

**每次测试完成后必须生成测试报告**，存放于项目目录：

```
<项目目录>/docs/test/report/UI_TEST_REPORT_YYYYMMDD_HHMMSS.md
```

### 报告生成流程

```
测试执行完成 → 生成报告 → 显示完整路径 → 提示用户查看
```

### 报告目录结构

```
<项目目录>/docs/test/
├── report/                              # 测试报告目录
│   ├── UI_TEST_REPORT_20260319_143052.md
│   ├── UI_TEST_REPORT_20260319_160231.md
│   └── ...
├── UI_TEST_CHECKLIST.md                 # 测试清单（可选）
└── screenshots/                         # 测试截图（可选）
```

### 报告内容

```markdown
# UI自动化测试报告

**测试时间**: 2026-03-19 14:30:52
**测试设备**: Pixel 6 (Android 14)
**测试模式**: 文档驱动 / 直接执行

## 测试汇总

| 总数 | 通过 | 失败 | 跳过 |
|------|------|------|------|
| 5    | 3    | 1    | 1    |

## 详细结果

### TC-001: Toast功能测试
- **状态**: ✅ PASS
- **执行模式**: Midscene视觉驱动
- **步骤**: 点击Toast按钮 → 等待4秒 → 验证显示
- **截图**: docs/test/screenshots/tc001.png

### TC-002: 竞态条件测试
- **状态**: ❌ FAIL
- **执行模式**: ADB快速执行
- **步骤**: 快速连续点击
- **错误**: 应用崩溃
- **日志片段**: FATAL EXCEPTION at com.example...

## 缺陷列表

| ID | 优先级 | 描述 | 状态 |
|----|--------|------|------|
| BUG-001 | P1 | Toast连续点击崩溃 | 待修复 |

## 修复建议

### BUG-001: Toast连续点击崩溃
- **代码位置**: ToastHelper.kt:45
- **建议**: 添加点击防抖处理
```

### 测试完成提示

测试完成后，必须显示报告完整路径：

```
✅ 测试完成！

📄 测试报告: /Users/xxx/project/docs/test/report/UI_TEST_REPORT_20260319_143052.md

📊 结果汇总: 5个用例，3通过，1失败，1跳过
```

---

## 完整示例

### 文档驱动测试示例

```bash
# 用户执行
/auto-ui-test docs/test/UI_TEST_REPORT.md

# AI执行流程：
1. 读取文档，发现5个测试用例
2. 过滤：2个PASS跳过，3个待验证执行
3. 执行TC-001（Midscene视觉驱动）
4. 执行TC-003（ADB快速执行，竞态测试）
5. 执行TC-005（混合模式）
6. 生成结果汇总
7. 询问是否更新原文档
```

### 直接执行示例

```bash
# 用户执行
/auto-ui-test 测试Toast连续点击是否崩溃

# AI判断：竞态测试 → ADB快速执行模式
# 执行命令
adb shell "input tap 1098 543 && sleep 0.01 && input tap 1098 543"
# 验证结果
adb logcat -d | grep -E "FATAL EXCEPTION|AndroidRuntime"
```

---

## 常见问题

### Q: 如何获取元素坐标？

```bash
# 方法1: 使用debug-screen.sh（推荐）
scripts/debug-screen.sh
# 输出: /tmp/android_debug_xxx/ui_dump.xml
# 从bounds属性计算中心点

# 方法2: Midscene截图分析
npx @midscene/android@1 take_screenshot
# 读取截图，视觉定位
```

### Q: Midscene执行太慢怎么办？

使用ADB快速执行模式，或混合模式（Midscene定位一次，ADB多次执行）。

### Q: 如何测试需要登录的功能？

```bash
# 先完成登录（可使用ADB快速输入）
adb shell "input text username && input keyevent 66"
adb shell "input text password && input keyevent 66"

# 然后执行测试
/auto-ui-test 测试个人中心功能
```

---

## 相关技能

- `adt:android-adb` - ADB基础操作
- `android-device-automation` - Midscene完整文档
- `ecc:tdd` - 测试驱动开发
- `ecc:e2e` - 端到端测试
