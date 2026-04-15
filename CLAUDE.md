# dev-tools-skills 项目规则

## SKILL.md Frontmatter 规则

所有 SKILL.md 的 YAML frontmatter 中，`description` 和其他字符串字段的值如果包含冒号 `:`，必须用双引号包裹。

```yaml
# 正确
description: "One-push release workflow: auto git add all changes, pull latest."
argument-hint: "[version] e.g. /dt:push 1.2.2"

# 错误 - 冒号会导致 YAML 解析失败
description: One-push release workflow: auto git add all changes, pull latest.
```

未加引号的冒号会触发 YAML 解析错误 `Nested mappings are not allowed in compact mappings`，导致 `npx skills` CLI 静默跳过该 skill。

**经验法则**：description 值始终用双引号包裹。
