# Midscene 配置参考

## 智谱 GLM-4.6V 配置（推荐）

性价比最高的配置方案，适合日常测试。

### 获取API Key

1. 访问 https://open.bigmodel.cn/
2. 注册/登录账号
3. 进入控制台 → API密钥
4. 创建新的API Key

### 环境变量配置

```bash
# 方式1: 临时配置（当前终端）
export MIDSCENE_MODEL_API_KEY="your-api-key-here"
export MIDSCENE_MODEL_NAME="glm-4.6v"
export MIDSCENE_MODEL_BASE_URL="https://open.bigmodel.cn/api/paas/v4"
export MIDSCENE_MODEL_FAMILY="glm-v"

# 方式2: 永久配置（写入shell配置文件）
echo 'export MIDSCENE_MODEL_API_KEY="your-api-key-here"' >> ~/.zshrc
echo 'export MIDSCENE_MODEL_NAME="glm-4.6v"' >> ~/.zshrc
echo 'export MIDSCENE_MODEL_BASE_URL="https://open.bigmodel.cn/api/paas/v4"' >> ~/.zshrc
echo 'export MIDSCENE_MODEL_FAMILY="glm-v"' >> ~/.zshrc
source ~/.zshrc

# 方式3: 项目级配置（.env文件）
cat > /path/to/project/.env << 'EOF'
MIDSCENE_MODEL_API_KEY=your-api-key-here
MIDSCENE_MODEL_NAME=glm-4.6v
MIDSCENE_MODEL_BASE_URL=https://open.bigmodel.cn/api/paas/v4
MIDSCENE_MODEL_FAMILY=glm-v
EOF
```

### 验证配置

```bash
# 检查环境变量
echo $MIDSCENE_MODEL_API_KEY
echo $MIDSCENE_MODEL_NAME

# 测试Midscene
npx @midscene/android@1 connect --deviceId YOUR_DEVICE_ID
npx @midscene/android@1 act --prompt "截取当前屏幕"
```

## 其他模型配置

### OpenAI GPT-4V

```bash
export MIDSCENE_MODEL_API_KEY="sk-xxx"
export MIDSCENE_MODEL_NAME="gpt-4o"
```

### Anthropic Claude

```bash
export MIDSCENE_MODEL_API_KEY="sk-ant-xxx"
export MIDSCENE_MODEL_NAME="claude-3-5-sonnet-20241022"
```

## Midscene 命令参考

### 连接管理

```bash
# 连接设备
npx @midscene/android@1 connect --deviceId DEVICE_ID

# 断开连接
npx @midscene/android@1 disconnect

# 查看连接状态
npx @midscene/android@1 status
```

### 执行操作

```bash
# 执行单步操作
npx @midscene/android@1 act --prompt "点击登录按钮"

# 执行多步操作（不推荐，建议分步执行）
npx @midscene/android@1 act --prompt "1. 点击设置 2. 点击关于"

# 使用断言
npx @midscene/android@1 assert --prompt "屏幕上显示'登录成功'"
```

### 截图

```bash
# 截取当前屏幕
npx @midscene/android@1 take_screenshot

# 截图并保存到指定路径
npx @midscene/android@1 take_screenshot --output ./screenshots/test1.png
```

### 元素查询

```bash
# 查询元素
npx @midscene/android@1 query --prompt "找到所有按钮"

# 获取元素信息
npx @midscene/android@1 query --prompt "获取登录按钮的位置"
```

## Prompt 编写技巧

### ✅ 好的Prompt

```bash
# 具体明确
npx @midscene/android@1 act --prompt "点击列表中标记为'日志示例'的第三项"

# 包含等待
npx @midscene/android@1 act --prompt "点击提交按钮，等待3秒后截图"

# 中文UI直接描述
npx @midscene/android@1 act --prompt "点击'取消当前Toast'按钮"
```

### ❌ 避免的Prompt

```bash
# 太模糊
npx @midscene/android@1 act --prompt "点击按钮"

# 链式操作太多
npx @midscene/android@1 act --prompt "点A，点B，点C，点D，点E"

# 不包含验证
npx @midscene/android@1 act --prompt "点击登录"
```

## 常见问题

### 连接超时

```bash
# 检查ADB连接
adb devices

# 重启ADB服务
adb kill-server
adb start-server

# 重新连接Midscene
npx @midscene/android@1 disconnect
npx @midscene/android@1 connect --deviceId DEVICE_ID
```

### 模型响应慢

- 检查网络连接
- 考虑切换到更快的模型
- 对于简单操作，使用ADB快速执行模式

### 中文识别问题

GLM-4.6V 对中文UI支持良好，如遇问题：
- 使用更具体的描述
- 结合截图进行验证
- 考虑使用坐标方式

## 费用参考

| 模型 | 输入价格 | 输出价格 | 适合场景 |
|------|---------|---------|---------|
| GLM-4.6V | ¥0.005/千tokens | ¥0.05/千tokens | 日常测试（推荐） |
| GPT-4o | $2.5/百万tokens | $10/百万tokens | 高精度需求 |
| Claude 3.5 | $3/百万tokens | $15/百万tokens | 复杂理解 |
