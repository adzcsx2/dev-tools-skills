# API 接口清单模板

> 这是 init-android skill 使用的模板文件，用于在用户明确要求时生成 docs/checklist/api.md。
> 本模板只允许输出从源码实际扫描到的接口信息。

---

# API 接口清单

> 本文档只记录项目中实际存在的 API 接口或网络服务定义，供 AI 开发时参考。

## 生成规则

- 仅记录从 Retrofit 接口、Service 定义、网络层代码中真实扫描到的接口
- 方法、路径、接口名、源码位置必须来自真实代码
- 不得写示例接口
- 如果请求参数或响应结构无法可靠提取，则只记录接口签名和源码位置
- 如果项目没有规范的 Retrofit 接口文件，可以按网络类或请求封装类归档
- 以下字段仅在能从代码或配置中直接验证时才允许输出：BASE_URL、说明、认证、请求参数、返回类型
- 无法验证的字段必须省略，不能用占位文本补齐

## 基础信息

- 可选 BASE_URL: {BASE_URL}
- 来源文件:
  - {SOURCE_FILE}
  - {SOURCE_FILE}

## 接口列表

### {API_GROUP}

#### {API_NAME}

- 方法: {HTTP_METHOD}
- 路径: {API_PATH}
- 源码位置: {SOURCE_FILE}

可选字段：
- 说明: {API_DESC}
- 认证: {AUTH_TYPE}

更多可选补充：
- 请求参数: {REQUEST_PARAMS_SUMMARY}
- 返回类型: {RESPONSE_TYPE}

## 更新规则

- 新增接口时同步更新
- 删除或迁移接口时及时清理
- 只记录真实可验证内容
