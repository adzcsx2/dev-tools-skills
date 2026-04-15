# 实施计划: 合并三个插件到 dev-tools-skills 单仓库

## 需求重述

1. 将 android-claude-skills 和 flutter-claude-skills 合并到 dev-tools-skills 单仓库
2. 识别可复用的通用 skill，放入 `plugins/dev-tools/` (dt: 前缀)
3. 平台特定 skill 保留在各自 plugin 中 (adt: / fdt: 前缀)
4. 单 marketplace 注册三个 plugin
5. 删除本地旧的独立 adt/fdt 安装，用 `dt:update-remote-plugins` 重新注册

---

## Phase 1: Skill 审计与分类

### 通用 Skills → `plugins/dev-tools/skills/` (dt: 前缀)

| Skill | 通用化改造 | 复杂度 |
|-------|----------|--------|
| `push` | 移除平台特定的 update-docs 调用和 pubspec.yaml 更新，改为自动检测项目类型或跳过 | 中 |
| `update-remote-plugins` | 改为扫描三个 plugin 目录，统一管理单 marketplace 下的多 plugin | 中 |
| `code-note` | 自动检测文件类型 (.kt/.java/.dart)，应用对应注释风格 | 低 |

### 平台特定 Skills → 保留在原 plugin 中

| Plugin | 保留的 Skills |
|--------|-------------|
| `android-dev-tools` (adt:) | init-android, gradle-build-performance, update-docs, android-i18n, android-fold-adapter, auto-ui-test |
| `flutter-dev-tools` (fdt:) | init-flutter, update-docs |

---

## Phase 2: 仓库结构重组

### 目标结构

```
dev-tools-skills/                           # 单 git 仓库
├── .claude-plugin/
│   └── marketplace.json                    # 注册三个 plugin
├── .gitignore
├── CLAUDE.md                               # YAML frontmatter 规则
├── LICENSE
├── README.md                               # 中文文档
├── README_EN.md                            # 英文文档
└── plugins/
    ├── dev-tools/                          # dt: 通用 skills
    │   ├── .claude-plugin/
    │   │   └── plugin.json                 # version: 1.0.0, skills: ["./skills/"]
    │   └── skills/
    │       ├── push/SKILL.md               # 通用化后的 push
    │       ├── update-remote-plugins/SKILL.md  # 适配单仓库多 plugin
    │       └── code-note/SKILL.md          # 自动检测语言类型
    ├── android-dev-tools/                  # adt: Android 特定 skills
    │   ├── .claude-plugin/
    │   │   └── plugin.json
    │   └── skills/                         # 移除 push, update-remote-plugins, code-note
    │       ├── init-android/
    │       ├── gradle-build-performance/
    │       ├── update-docs/
    │       ├── android-i18n/
    │       ├── android-fold-adapter/
    │       └── auto-ui-test/
    └── flutter-dev-tools/                  # fdt: Flutter 特定 skills
        ├── .claude-plugin/
        │   └── plugin.json
        └── skills/                         # 移除 push, update-remote-plugins, code-note
            ├── init-flutter/
            └── update-docs/
```

### 操作步骤

1. 将 `android-claude-skills/plugins/android-dev-tools/` 移到 `plugins/android-dev-tools/`
2. 将 `flutter-claude-skills/plugins/flutter-dev-tools/` 移到 `plugins/flutter-dev-tools/`
3. 从两个 plugin 中删除 `push/`, `update-remote-plugins/`, `code-note/` 目录
4. 创建 `plugins/dev-tools/` 目录及子结构
5. 编写三个通用 SKILL.md
6. 合并 marketplace.json 为单文件，注册三个 plugin
7. 编写根目录 README.md 和 README_EN.md
8. 编写 CLAUDE.md (YAML frontmatter 规则)
9. 删除旧的 `android-claude-skills/` 和 `flutter-claude-skills/` 目录

---

## Phase 3: 通用 SKILL.md 编写

### dt:push (通用化改造要点)

与平台特定版本的差异:
- **移除** Step 5 (调用 update-docs) → 改为可选: 检测项目类型，若为 Android/Flutter 则提示用户手动调用对应的 update-docs
- **移除** Step 3 中 `pubspec.yaml` 版本更新 → 改为通用文档版本更新 (仅 *.md 文件)
- **保留** 完整的 git 工作流 (pre-flight, pull, conflict resolution, per-file commit, push, tag)

### dt:update-remote-plugins (适配单仓库多 plugin)

关键改造:
- 扫描 `plugins/` 下所有子目录 (dev-tools, android-dev-tools, flutter-dev-tools)
- 每个 plugin 独立维护版本号和 plugin.json
- 单个 marketplace.json 管理所有 plugin
- 本地同步到 `~/.claude/plugins/cache/` 和 `~/.claude/plugins/marketplaces/` 下的 `dev-tools-skills/` 目录
- 注册时使用统一的 marketplace key: `dev-tools-skills`
- 三个 enabledPlugins: `dev-tools-skills@dev-tools`, `dev-tools-skills@android-dev-tools`, `dev-tools-skills@flutter-dev-tools`

### dt:code-note (自动检测语言)

改造要点:
- 自动检测文件扩展名 (.kt/.java → KDoc/JavaDoc, .dart → dartdoc, 其他 → 通用注释)
- 文件搜索模式改为 `**/*{FileName}.*`，匹配所有源码文件
- 根据检测结果应用对应的注释风格规则

---

## Phase 4: 配置文件编写

### marketplace.json

```json
{
  "owner": { "name": "adzcsx2" },
  "plugins": [
    {
      "name": "dev-tools",
      "version": "1.0.0",
      "path": "./plugins/dev-tools/"
    },
    {
      "name": "android-dev-tools",
      "version": "2.15.0",
      "path": "./plugins/android-dev-tools/"
    },
    {
      "name": "flutter-dev-tools",
      "version": "1.1.0",
      "path": "./plugins/flutter-dev-tools/"
    }
  ]
}
```

### 各 plugin.json

- `plugins/dev-tools/.claude-plugin/plugin.json` → name: "dev-tools", skills: ["./skills/"]
- `plugins/android-dev-tools/.claude-plugin/plugin.json` → 更新版本号，保留 skills 字段
- `plugins/flutter-dev-tools/.claude-plugin/plugin.json` → 更新版本号，保留 skills 字段

---

## Phase 5: 清理旧插件 & 注册新插件

### 删除旧安装

```bash
# 删除旧的 cache
rm -rf ~/.claude/plugins/cache/android-dev-tools/
rm -rf ~/.claude/plugins/cache/flutter-dev-tools/

# 删除旧的 marketplace
rm -rf ~/.claude/plugins/marketplaces/android-dev-tools/
rm -rf ~/.claude/plugins/marketplaces/flutter-dev-tools/
```

### 更新配置文件

1. `~/.claude/settings.json` → enabledPlugins 中删除旧的两个，添加三个新的
2. `~/.claude/plugins/known_marketplaces.json` → 删除旧的两个 marketplace，添加 `dev-tools-skills`
3. `~/.claude/plugins/installed_plugins.json` → 删除旧的两个，添加三个新的

### 注册新 marketplace

```bash
git clone git@github.com:adzcsx2/dev-tools-skills.git ~/.claude/plugins/marketplaces/dev-tools-skills
```

---

## Phase 6: 测试验证

1. 运行 `dt:update-remote-plugins` 测试插件同步
2. 验证三个 plugin 的 skill 都可用 (`dt:push`, `adt:init-android`, `fdt:init-flutter` 等)
3. 测试 `dt:push` 在通用项目中的工作流

---

## 风险评估

| 风险 | 级别 | 缓解措施 |
|------|------|---------|
| Claude Code 不支持单 marketplace 多 plugin | 中 | 验证 marketplace.json 中 plugins 数组格式 |
| 旧 plugin 删除后 skill 不可用 | 低 | 先注册新的再删除旧的 |
| update-remote-plugins 的路径全部变了 | 中 | 仔细测试路径引用 |
| 独立仓库的 git 历史丢失 | 低 | 用户已确认移植，旧仓库仍保留在 GitHub |

## 预估复杂度: 中

- 文件重组: ~20 个文件移动/删除
- 新增文件: ~10 个 (SKILL.md x3, plugin.json, marketplace.json, README, CLAUDE.md)
- 配置修改: 3 个本地 Claude 配置文件
