---
name: dt:update-remote-plugins
description: "Audit and sync all plugins in the monorepo: generate per-skill README.md, update marketplace.json and plugin.json, commit, push, and sync to local Claude Code."
---

> **中文环境要求**
>
> 本技能运行在中文环境下，请遵循以下约定：
> - 面向用户的回复、注释、提示信息必须使用中文
> - AI 内部处理过程可以使用英文
> - 所有生成的文件必须使用 UTF-8 编码
>
> ---

# Update Remote Plugins

管理单仓库多 plugin 的发布流程：审计所有 skill、生成 README.md、更新配置文件、提交推送、同步到本地 Claude Code。

**本仓库结构：**

```
dev-tools-skills/                    # 单 marketplace 仓库
├── .claude-plugin/marketplace.json  # 注册所有 plugin
├── plugins/
│   ├── dev-tools/                   # dt: 通用 skill
│   ├── android-dev-tools/           # adt: Android skill
│   └── flutter-dev-tools/           # fdt: Flutter skill
```

**Marketplace 名称**: `dev-tools-skills`
**远程仓库**: `git@github.com:adzcsx2/dev-tools-skills.git`

## When to Use

- 修改了 `plugins/` 下任何 skill 后
- 发布新版本
- 同步中英文文档
- 新增或更新 skill 后重新生成 README

## Trigger

```
/dt:update-remote-plugins
```

---

## Workflow

### 1. Pull Latest Changes

**ALWAYS start by pulling latest changes** to avoid conflicts:

```bash
git fetch origin
git pull --rebase
```

If pull fails due to uncommitted changes:
```bash
git stash
git pull --rebase
# After resolving any conflicts, restore stash if needed
```

### 2. Scan All Plugins

列出所有 plugin 目录及其 skill：

```bash
# 扫描所有 plugin
ls -1 plugins/

# 预期输出:
# android-dev-tools
# dev-tools
# flutter-dev-tools
```

对每个 plugin，列出其 skill：
```bash
for plugin_dir in plugins/*/; do
  plugin_name=$(basename "$plugin_dir")
  echo "=== $plugin_name ==="
  ls -1 "${plugin_dir}skills/" 2>/dev/null || echo "(no skills)"
done
```

对每个 skill，读取其 SKILL.md 获取 name 和 description。

### 3. Detect Changes

Check if any file changed since last commit:
```bash
git diff HEAD --name-only -- plugins/
```

If changes detected, determine version bump **per plugin**:
- **Bug fix / minor update** → patch (+0.0.1)
- **New skill / feature** → minor (+0.1.0)
- **Breaking change** → major (+1.0.0)

### 4. Audit and Generate Skill READMEs

对**每个 plugin** 的每个 skill，生成或更新 README.md。

#### 4a. 识别需要审计的 skill

```bash
# 获取变更的 skill 目录列表
# 路径格式: plugins/{plugin-name}/skills/{skill-name}/SKILL.md
git diff HEAD --name-only -- plugins/ \
  | grep 'SKILL.md$' \
  | cut -d'/' -f2-4 \
  | sort -u
```

需要审计的 skill：
- **有变更的 skill** — SKILL.md 被修改
- **缺少 README.md 的 skill** — 无论是否变更

#### 4b. 检查每个 skill 目录

```bash
for plugin_dir in plugins/*/; do
  plugin_name=$(basename "$plugin_dir")
  for skill_dir in "${plugin_dir}skills/"*/; do
    skill_name=$(basename "$skill_dir")
    if [ ! -f "${skill_dir}README.md" ]; then
      echo "MISSING: ${plugin_name}/${skill_name}/README.md"
    fi
  done
done
```

#### 4c. 生成或更新 README.md

对每个需要处理的 skill，读取其 SKILL.md，提取以下信息：

| README 字段 | SKILL.md 来源 |
|---|---|
| 标题 | frontmatter 中的 `name` 字段 |
| 一句话描述 | H1 标题后的第一段文字（翻译为中文） |
| 功能列表 | `## When to Use` 等功能描述段落 |
| 用法 | `## Trigger`、`## Example Prompts` 等段落 |

**README.md 模板：**

```markdown
# {skill-name}

{一句话中文描述}

---

## 功能

{功能列表，每项一行，以 - 开头}

## 用法

{用法示例，保留原始代码块格式}

---

> 本文档由 SKILL.md 自动生成，请勿手动编辑。如需更新，修改 SKILL.md 后运行 `/dt:update-remote-plugins`。
```

### 5. Update Configuration Files (Per Plugin)

对每个有变更的 plugin，更新其 `plugin.json`：

**CRITICAL: 每个 plugin.json 必须包含 `skills` 字段:**
```json
{
  "name": "plugin-name",
  "version": "X.Y.Z",
  "skills": ["./skills/"]
}
```

然后更新根级 `marketplace.json`，同步所有 plugin 的版本号。

### 6. Sync Root README Files

**README.md (Chinese)** - 更新 skill 表格和项目结构。
**README_EN.md (English)** - 同步英文版本。

包含所有三个 plugin 的 skill 列表。

### 7. Commit and Push

```bash
git add .claude-plugin/marketplace.json README.md README_EN.md plugins/
git commit -m "feat: 更新插件 - {变更摘要}"
```

Push with retry:
```bash
git push || {
  git pull --rebase
  git rebase --continue 2>/dev/null
  git push
}
```

### 8. Sync Local Plugins (CRITICAL)

**ALWAYS sync to BOTH cache AND marketplace directories** — Claude Code reads from both.

```bash
# Marketplace 名称
MARKETPLACE_NAME="dev-tools-skills"

# 远程仓库
REPO_URL="git@github.com:adzcsx2/dev-tools-skills.git"

# === Sync to CACHE directory (per plugin) ===
for plugin_dir in plugins/*/; do
  plugin_name=$(basename "$plugin_dir")
  VERSION=$(cat "${plugin_dir}.claude-plugin/plugin.json" | grep '"version"' | head -1 | cut -d'"' -f4)

  CACHE_PATH="$HOME/.claude/plugins/cache/${MARKETPLACE_NAME}/${plugin_name}/${VERSION}"
  mkdir -p "$CACHE_PATH/skills" "$CACHE_PATH/.claude-plugin"
  cp -r "${plugin_dir}skills/"* "$CACHE_PATH/skills/"
  cp "${plugin_dir}.claude-plugin/plugin.json" "$CACHE_PATH/.claude-plugin/"
  echo "Synced to cache: $CACHE_PATH"
done

# === Sync to MARKETPLACE directory (git pull) ===
MARKETPLACE_PATH="$HOME/.claude/plugins/marketplaces/${MARKETPLACE_NAME}"

if [ ! -d "$MARKETPLACE_PATH/.git" ]; then
  echo "Marketplace not a git repo, cloning..."
  rm -rf "$MARKETPLACE_PATH"
  git clone "$REPO_URL" "$MARKETPLACE_PATH"
else
  echo "Marketplace is git repo, pulling latest..."
  git -C "$MARKETPLACE_PATH" pull
fi

# Verify
echo "=== Marketplace plugins ==="
ls -1 "$MARKETPLACE_PATH/plugins/"
```

### 9. Register Plugin (First Install Only)

**CRITICAL: Without these registrations, Claude Code will NOT load the plugin.**

#### 9a. Add to known_marketplaces.json

Ensure `~/.claude/plugins/known_marketplaces.json` has an entry:
```json
{
  "dev-tools-skills": {
    "source": {
      "source": "git",
      "url": "git@github.com:adzcsx2/dev-tools-skills.git"
    },
    "installLocation": "/Users/hoyn/.claude/plugins/marketplaces/dev-tools-skills",
    "lastUpdated": "2026-04-15T00:00:00.000Z"
  }
}
```

#### 9b. Add to enabledPlugins in settings.json

Ensure `~/.claude/settings.json` has the plugins enabled:
```json
{
  "enabledPlugins": {
    "dev-tools-skills@dev-tools": true,
    "dev-tools-skills@android-dev-tools": true,
    "dev-tools-skills@flutter-dev-tools": true
  }
}
```

#### 9c. Update installed_plugins.json

对每个 plugin，在 `~/.claude/plugins/installed_plugins.json` 中注册：
```json
{
  "version": 2,
  "plugins": {
    "dev-tools-skills@dev-tools": [
      {
        "scope": "user",
        "installPath": "/Users/xxx/.claude/plugins/cache/dev-tools-skills/dev-tools/1.0.0",
        "version": "1.0.0",
        "installedAt": "2026-04-15T00:00:00.000Z"
      }
    ],
    "dev-tools-skills@android-dev-tools": [...],
    "dev-tools-skills@flutter-dev-tools": [...]
  }
}
```

---

## Troubleshooting

### Issue 1: Skills Not Loading - Missing `skills` Field

**Root Cause:** `plugin.json` missing `"skills": ["./skills/"]` field

**Solution:**
```json
{
  "name": "plugin-name",
  "version": "X.Y.Z",
  "skills": ["./skills/"]
}
```

### Issue 2: Skills Not Loading - Marketplace Not a Git Repo

**Root Cause:** Claude Code requires marketplace directory to be a valid git clone.

**Solution:**
```bash
rm -rf ~/.claude/plugins/marketplaces/dev-tools-skills
git clone git@github.com:adzcsx2/dev-tools-skills.git ~/.claude/plugins/marketplaces/dev-tools-skills
```

### Issue 3: Plugin Not Loading - Missing Registration

**Root Cause:** Claude Code requires registration in 3 config files.

**Solution:** Verify all 3 files have entries:
```bash
grep "dev-tools-skills" ~/.claude/settings.json
grep "dev-tools-skills" ~/.claude/plugins/known_marketplaces.json
grep "dev-tools-skills" ~/.claude/plugins/installed_plugins.json
```

### Issue 4: Push Rejected

**Solution:**
```bash
git stash
git pull --rebase
git rebase --continue
git push
git stash pop
```

---

## Notes

1. **ALWAYS pull first** - 避免冲突
2. **ALWAYS sync to local** - 新窗口需要更新的插件
3. **Sync cache via cp, marketplace via git pull**
4. **Every plugin.json MUST have skills field**
5. **Commit message 使用中文**
6. Version format: semver (major.minor.patch)
7. Local paths:
   - Cache: `~/.claude/plugins/cache/dev-tools-skills/{plugin-name}/{version}/`
   - Marketplace: `~/.claude/plugins/marketplaces/dev-tools-skills/` (必须是 git clone)
   - Installed: `~/.claude/plugins/installed_plugins.json`
8. **首次安装需要注册 3 个文件** - `settings.json`、`known_marketplaces.json`、`installed_plugins.json`
9. README.md 文件由 SKILL.md 自动生成，请勿手动编辑
