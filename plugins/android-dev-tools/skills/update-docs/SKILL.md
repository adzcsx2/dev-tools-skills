---
name: adt:update-docs
description: Auto-generate Chinese technical documentation for Android projects. Analyzes structure, generates interfaces, navigation, components, notifications, and API docs. Also migrates root md files to docs/ and updates README with quick links.
---

> **中文环境要求**
>
> 本技能运行在中文环境下，请遵循以下约定：
> - 面向用户的回复、注释、提示信息必须使用中文
> - AI 内部处理过程可以使用英文
> - 所有生成的文件必须使用 UTF-8 编码
>
> ---

# update-docs Skill

Android 项目文档自动生成工具。分析项目结构，生成中文技术文档，支持增量更新。

## When to Use

- Generating project documentation for Android apps
- Creating interface documentation with control analysis
- Documenting navigation flows and Activity-Fragment relationships
- Listing Android four components (Activity, Service, Receiver, Provider)
- Documenting notification channels and API endpoints
- Migrating root directory md files to docs/ for centralized management
- Updating README with categorized doc quick links
- Tracking document changes with detailed update logs

## Example Prompts

- "/update-docs"
- "Generate documentation for my Android project"
- "Update project docs with --force"
- "Only generate interface documentation"

---

## Command Parameters

| Parameter | Description |
|-----------|-------------|
| No args | Incremental update of all docs |
| `--force` | Force regenerate all docs |
| `--dry-run` | Analyze only, don't generate files |
| `interfaces` | Generate interface docs only |
| `navigation` | Generate navigation docs only |
| `components` | Generate four components docs only |
| `notifications` | Generate notification docs only |
| `api` | Generate API docs only |

---

## Document Structure

```
README.md
├── 最近更新（3条摘要 + 链接到 CHANGELOG）
└── ...

docs/
├── CHANGELOG.md              # 更新列表（每条有链接到详情）
├── PROJECT_OVERVIEW.md       # 项目概览
├── INTERFACES.md             # 界面文档
├── NAVIGATION.md             # 导航文档
├── COMPONENTS.md             # 四大组件
├── NOTIFICATIONS.md          # 通知文档
├── BUILD_VARIANTS.md         # 构建变体
├── DEPENDENCIES.md           # 依赖文档
├── API.md                    # API 文档
├── .doc-metadata.json        # 元数据
└── update-list/              # 详情目录（可重新生成）
    └── update-YYYY-MM-DD.md  # 每次更新的详细内容
```

---

## Execution Flow

### 1. Verify Project Type

Check for these files:
- `settings.gradle` or `settings.gradle.kts`
- `build.gradle` or `build.gradle.kts`
- `app/src/main/AndroidManifest.xml`

Exit if not an Android project.

### 2. Clean Old Update Files (Optional)

If `--force` is used, clean old update files:

```bash
# Remove old update-list directory (can be regenerated)
rm -rf docs/update-list/
rm -f docs/UPDATE_INDEX.md
```

### 3. Load/Create Metadata

Check `docs/.doc-metadata.json`:

```json
{
  "version": "1.3",
  "projectType": "android",
  "lastUpdate": "2026-03-12T10:30:00Z",
  "lastCommit": "abc1234def5678",
  "documents": {
    "PROJECT_OVERVIEW.md": {
      "updatedAt": "2026-03-12T10:30:00Z",
      "sourceFiles": ["build.gradle", "settings.gradle"],
      "lastCommit": "abc1234"
    }
  },
  "updateHistory": [
    {
      "date": "2026-03-12",
      "diffFile": "update-list/update-2026-03-12.md",
      "summary": "新增铸造功能文档，更新 API 接口说明",
      "documentsUpdated": ["INTERFACES.md", "API.md"]
    }
  ]
}
```

### 4. Analyze Git Changes

**Git-based Change Detection:**
1. Read `docs/.doc-metadata.json` to get `lastUpdate` date
2. Run `git log --since="{lastUpdate}" --oneline --no-merges` to get new commits
3. For each commit, get changed files
4. Map changed files to affected documents

**File to Document Mapping:**
| Source File Pattern | Affected Documents |
|---------------------|-------------------|
| `**/*Activity.kt`, `**/*Activity.java` | INTERFACES.md, NAVIGATION.md |
| `**/*Fragment.kt`, `**/*Fragment.java` | INTERFACES.md, NAVIGATION.md |
| `**/res/layout/*.xml` | INTERFACES.md |
| `**/http/*Api.kt`, `**/api/*.kt` | API.md |
| `AndroidManifest.xml` | COMPONENTS.md, NAVIGATION.md |
| `build.gradle`, `build.gradle.kts` | BUILD_VARIANTS.md, DEPENDENCIES.md |
| `**/notification/*`, `*Notification*.kt` | NOTIFICATIONS.md |

### 5. Analyze Project

#### 5.1 Analyze AndroidManifest.xml
Extract: applicationId, versionCode, versionName, four components list, permissions list

#### 5.2 Analyze build.gradle
Extract: compileSdkVersion, buildTypes, productFlavors, dependencies

#### 5.3 Analyze Activity/Fragment
Use Glob to find: `**/*Activity.java`, `**/*Activity.kt`, `**/*Fragment.java`, `**/*Fragment.kt`

#### 5.4 Analyze Layout Files
Use Glob: `**/res/layout/*.xml`

#### 5.5 Analyze Notification Config
Use Grep: `NotificationChannel`, `NotificationManager`

#### 5.6 Analyze API Interfaces
Use Grep: `@GET`, `@POST`, `@PUT`, `@DELETE`

### 6. Migrate Root MD Files to docs/

Scan root directory for markdown files (excluding README.md) and migrate to appropriate docs/ subdirectories.

### 7. Generate Documents

All docs go in `docs/` directory:

| Document | Content |
|----------|---------|
| PROJECT_OVERVIEW.md | Project overview |
| INTERFACES.md | Interface docs (control analysis, functionality) |
| NAVIGATION.md | Navigation docs (Activity-Fragment relationships) |
| COMPONENTS.md | Four components docs |
| NOTIFICATIONS.md | Notification docs |
| BUILD_VARIANTS.md | Build variants docs |
| DEPENDENCIES.md | Dependencies docs |
| API.md | API interface docs (URL and method) |
| CHANGELOG.md | **Update list with links to details** |
| update-list/*.md | **Detailed update content per update** |

---

## 8. Generate Update Detail Document (CRITICAL)

Generate a detailed update document in `docs/update-list/` for each update:

### 8.1 Filename Convention
- Format: `update-YYYY-MM-DD.md`
- If file exists for today, append number: `update-YYYY-MM-DD-2.md`

### 8.2 Document Content Structure

**MUST include actual document changes, NOT just git commits:**

```markdown
# 更新详情 - YYYY-MM-DD

## 概述

**更新时间**: YYYY-MM-DD HH:MM
**触发方式**: Git 提交分析 / --force 强制更新
**关联提交**: abc1234, def5678

## 文档变更详情

### API.md

**变更类型**: 新增接口

**变更内容**:
- 新增 `POST /mint/nft` NFT 铸造接口
  - 请求参数: `imageHash`, `walletAddress`
  - 返回: `transactionHash`, `status`
- 新增 `GET /user/wallet` 钱包地址查询接口

### INTERFACES.md

**变更类型**: 新增组件

**变更内容**:
- 新增 CastDialog 铸造确认对话框
  - 支持显示铸造进度
  - 支持失败重试
- 更新 AlbumActivity 说明
  - 新增铸造状态显示逻辑

### NAVIGATION.md

**变更类型**: 更新流程

**变更内容**:
- 新增 WalletConnect 连接流程
  - ReviewActivity → WalletConnectResponseActivity
  - 支持返回重连逻辑
```

### 8.3 Git Commit Detailed Analysis (CRITICAL)

**分析每个提交中每个文件的变动，多处变动都要写上：**

```markdown
## Git 提交详细分析

### a7f334e - 修复作品页铸造失败重试逻辑与Toast文案

**变动文件**:
- `CastDialog.kt`
  - 新增重试按钮点击事件
  - 更新错误提示文案
  - 新增铸造状态监听
- `WCController.kt`
  - 修复连接断开重连逻辑
  - 新增超时处理
- `MintPendingManager.kt`
  - 新增待处理队列管理
  - 新增状态回调接口
- `AlbumActivity.kt`
  - 更新铸造状态显示

### 612a131 - 重构完成第一版-铸造流程跑通

**变动文件**:
- `MyApplication.kt`
  - 初始化铸造管理器
- `ReviewActivity.kt`
  - 新增铸造入口
- `CastDialog.kt`
  - 重构铸造对话框
- `MintHelper.kt`
  - 新增铸造辅助类
- `WCController.kt`
  - 集成钱包连接
```

**注意**：
- 每个文件的**多处变动都要列出**
- 不要写"保持不变"的文件列表
- 只写有实际变动的文件

### 8.3 What to EXCLUDE from Update Log (CRITICAL)

**以下内容只有在发生实际变动时才写入更新日志：**

| 内容类型 | 排除规则 |
|----------|----------|
| **项目统计** | Activities/Fragments/Services 数量等统计数据，**不变动不写** |
| **组件列表** | Activity/Fragment 名称列表，**不变动不写** |
| **通知渠道** | 通知渠道配置，**不变动不写** |
| **构建变体** | stageEnv/releaseEnv 等配置，**不变动不写** |
| **依赖库版本** | CameraX/OkHttp/Retrofit 等版本号，**不变动不写** |
| **技术栈** | Kotlin/MVVM/Room 等技术选型，**不变动不写** |

### 8.4 Comment-Only Changes (Simplified Format)

**如果源文件只是添加了注释（没有代码逻辑变更）：**

```markdown
### API.md

**变更类型**: 新增注释

**变更内容**:
- 以下文件新增代码注释：
  - `BaseApi.kt`
  - `CenterApi.kt`
  - `AIApi.kt`
```

**不要展开列出完整的接口内容，只说明哪些文件增加了注释。**

### 8.5 How to Detect Actual Changes (CRITICAL)

**适用于所有文档，不只是 API.md**

**Before writing to update log, verify:**

1. **Read existing doc content** before regeneration
2. **After regeneration**, compare new content with old
3. **Only record actual differences**:
   - New sections added
   - Sections removed
   - Content modified (not just formatting)
4. **Skip if only metadata changed** (timestamps, etc.)

### 8.6 Ignore Code Formatting Changes (CRITICAL)

**代码格式化变化不应记录到更新日志：**

| 变化类型 | 是否记录 | 示例 |
|----------|----------|------|
| 新增接口/方法 | ✅ 记录 | 新增 `POST /mint/nft` |
| 删除接口/方法 | ✅ 记录 | 删除 `GET /old/api` |
| 修改接口参数 | ✅ 记录 | 参数 `userId` 改为 `walletAddress` |
| 代码换行/缩进 | ❌ 不记录 | `builder.addHeader("token", x)` 换行 |
| 代码格式化 | ❌ 不记录 | IDE 自动格式化 |
| 注释变化 | ⚠️ 简化记录 | 只列出文件名，不展开内容 |

**检测方法：**

```bash
# 忽略空白变化，检查是否有实际内容变化
git diff HEAD --ignore-all-space -- docs/API.md

# 如果忽略空白后没有变化，则不记录
if git diff HEAD --ignore-all-space --quiet -- docs/API.md; then
  echo "No actual changes, skip recording"
fi

# 检查源代码是否有逻辑变化（不只是格式化）
git diff HEAD --ignore-all-space -- "*.kt" "*.java"
```

### 8.7 Source Code Change Detection

**分析源代码变更时，区分格式化和逻辑变化：**

```markdown
## Git 提交详细分析

### e205804 - 重构图片加载,提高加载效率

**变动文件**:
- `HttpUtils.kt`
  - 代码格式化（换行调整）← 无需详细展开
  - 新增 `LoggingInterceptor` 替换旧日志拦截器 ← 实际变更
- `ALiYunOSS.kt`
  - 新增文件哈希计算方法 ← 实际变更
```

**规则**：
- 如果文件只有格式化变化，写"代码格式化（无需详细展开）"
- 如果有实际逻辑变化，只写逻辑变化的部分
- 不要因为代码格式化而展开列出无意义的内容

---

## 9. Update CHANGELOG.md (Update List)

CHANGELOG.md serves as the update list with clickable links to details:

```markdown
# 文档更新日志

> 本文档记录项目文档的所有更新历史。点击查看详情。

---

## 2026-03-12 - 铸造功能文档更新

**变更概述**: 新增 NFT 铸造相关文档，更新 WalletConnect 集成说明

| 文档 | 变更类型 | 简介 |
|------|----------|------|
| API.md | 新增接口 | 新增 `/mint/nft` 铸造接口、钱包查询接口 |
| INTERFACES.md | 新增组件 | 新增 CastDialog 对话框，更新 AlbumActivity |
| NAVIGATION.md | 更新流程 | 新增 WalletConnect 连接导航流程 |

[查看详情](update-list/update-2026-03-12.md)

---

## 2026-03-09 - 首次文档生成

**变更概述**: 生成完整项目文档

| 文档 | 变更类型 | 简介 |
|------|----------|------|
| PROJECT_OVERVIEW.md | 新增 | 项目概览文档 |
| INTERFACES.md | 新增 | 界面文档 |
| ... | ... | ... |

[查看详情](update-list/update-2026-03-09.md)

---

[← 返回主文档](../README.md)
```

**CHANGELOG Update Rules:**
1. **Newest first**: Insert new updates at the TOP
2. **Summary table**: Show document, change type, and brief description
3. **Detail link**: Each update has a link to `update-list/update-YYYY-MM-DD.md`
4. **No limit**: Keep all history (old update-list files can be regenerated)

---

## 10. Update README.md

README.md shows **3 most recent updates**:

```markdown
## 文档导航

> 快速访问: [文档中心](docs/) | [更新记录](docs/CHANGELOG.md)

### 最近更新

| 日期 | 描述 |
|------|------|
| YYYY-MM-DD | 新增 NFT 铸造相关文档，更新 WalletConnect 集成说明 |
| YYYY-MM-DD | 新增界面文档、导航流程文档 |
| YYYY-MM-DD | 首次生成项目文档 |

> 查看全部更新: [更新记录](docs/CHANGELOG.md)

---

### 快速开始
| 文档 | 描述 |
|------|------|
| [项目概览](docs/PROJECT_OVERVIEW.md) | 项目简介、版本信息、技术栈 |
| [开发环境](docs/SETUP.md) | 环境配置与开发指南 |
...
```

**README Update Rules:**
1. **3 recent updates**: Show the latest 3 updates
2. **Link to CHANGELOG**: Point to `docs/CHANGELOG.md` for full history
3. **Brief description**: Summarize each update in one sentence

---

## 11. Update Metadata

Update `docs/.doc-metadata.json` with:

1. **Update timestamps** for modified documents
2. **Update lastCommit** to current HEAD
3. **Append to updateHistory** array
4. **Update stats** section

---

## Analysis Patterns

### Activity Jump Detection
```
startActivity\(new Intent\(.*?,\s*(\w+Activity)\.class\)\)
ActivityUtil\.next\(.*?,\s*(\w+Activity)\.class\)
(\w+Activity)\.start\(
```

### Fragment Switch Detection
```
beginTransaction\(\)[\s\S]*?replace\((\w+),\s*(\w+Fragment)
viewPager\.setCurrentItem\((\d+)\)
```

### Control Detection
```
findViewById\(R\.id\.(\w+)\)
binding\.(\w+)
android:onClick="(\w+)"
```

### Notification Channel Detection
```
NotificationChannel\(["']([^"']+)["'],\s*["']([^"']+)["']
```

### API Interface Detection
```
@GET\(["']([^"']+)["']\)
@POST\(["']([^"']+)["']\)
["'](https?://[^"']+)["']
["'](\/api\/[^"']+)["']
```

---

## Control Type Mapping

| XML Tag | Type | Category |
|---------|------|----------|
| TextView | TextView | Display |
| EditText | EditText | Input |
| Button | Button | Interactive |
| ImageButton | ImageButton | Interactive |
| ImageView | ImageView | Display |
| RecyclerView | RecyclerView | Container |
| ViewPager2 | ViewPager2 | Container |
| CheckBox | CheckBox | Input |
| Switch | Switch | Input |

---

## Notes

1. All documents are written in **Chinese**
2. Time format uses ISO 8601 standard
3. **CHANGELOG.md**: Serves as update list with links to details
4. **update-list/**: Contains detailed update content (can be regenerated)
5. **README.md**: Shows only 1 most recent update
6. **Document changes**: Record actual document changes, not just git commits
7. **Old update-list files**: Can be deleted and regenerated if needed
8. Root md files are migrated to docs/ and deleted from root
9. Duplicate detection: keep more detailed version when merging
