---
name: fdt:update-docs
description: "Auto-generate Chinese technical documentation for Flutter projects. Analyzes structure, generates widgets, navigation, routes, state management, and API docs. Also migrates root md files to docs/ and updates README with quick links."
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

Flutter 项目文档自动生成工具。分析项目结构，生成中文技术文档，支持增量更新。

## When to Use

- 为 Flutter 应用生成项目文档
- 创建界面文档（Widget、控件分析）
- 文档化导航流程和路由关系
- 列出状态管理方案和分层结构
- 文档化 API 接口
- 将根目录 md 文件迁移到 docs/ 集中管理
- 更新 README 并添加分类文档快捷链接
- 跟踪文档变更并记录详细更新日志

## Example Prompts

- `/fdt:update-docs`
- "为我的 Flutter 项目生成文档"
- "使用 --force 更新文档"
- "只生成界面文档"

---

## Command Parameters

| Parameter | Description |
|-----------|-------------|
| No args | 增量更新所有文档 |
| `--force` | 强制重新生成所有文档 |
| `--dry-run` | 仅分析，不生成文件 |
| `widgets` | 仅生成界面文档 |
| `navigation` | 仅生成导航/路由文档 |
| `state` | 仅生成状态管理文档 |
| `api` | 仅生成 API 文档 |

---

## Document Structure

```
README.md
├── 最近更新（3条摘要 + 链接到 CHANGELOG）
└── ...

docs/
├── CHANGELOG.md              # 更新列表（每条有链接到详情）
├── PROJECT_OVERVIEW.md       # 项目概览
├── WIDGETS.md                # 界面/Widget 文档
├── NAVIGATION.md             # 导航/路由文档
├── STATE_MANAGEMENT.md       # 状态管理文档
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
- `pubspec.yaml`
- `lib/main.dart`
- `android/` or `ios/` directory

Exit if not a Flutter project.

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
  "version": "1.0",
  "projectType": "flutter",
  "lastUpdate": "2026-04-14T10:30:00Z",
  "lastCommit": "abc1234def5678",
  "documents": {
    "PROJECT_OVERVIEW.md": {
      "updatedAt": "2026-04-14T10:30:00Z",
      "sourceFiles": ["pubspec.yaml"],
      "lastCommit": "abc1234"
    }
  },
  "updateHistory": [
    {
      "date": "2026-04-14",
      "diffFile": "update-list/update-2026-04-14.md",
      "summary": "新增登录功能文档，更新 API 接口说明",
      "documentsUpdated": ["WIDGETS.md", "API.md"]
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
| `lib/**/*_page.dart`, `lib/**/*_screen.dart` | WIDGETS.md, NAVIGATION.md |
| `lib/**/*_widget.dart`, `lib/**/*_dialog.dart` | WIDGETS.md |
| `lib/**/routes.dart`, `lib/**/router.dart`, `lib/**/*_route*.dart` | NAVIGATION.md |
| `pubspec.yaml` | PROJECT_OVERVIEW.md, DEPENDENCIES.md |
| `lib/**/*_api.dart`, `lib/**/*_service.dart`, `lib/**/*_repository.dart` | API.md |
| `lib/**/*_state.dart`, `lib/**/*_notifier.dart`, `lib/**/*_bloc.dart`, `lib/**/*_cubit.dart`, `lib/**/*_provider.dart` | STATE_MANAGEMENT.md |
| `lib/**/*_model.dart`, `lib/**/*_entity.dart` | API.md, DEPENDENCIES.md |

### 5. Analyze Project

#### 5.1 Analyze pubspec.yaml
Extract: name, version, description, Flutter/Dart SDK constraints, dependencies, dev_dependencies

#### 5.2 Analyze Directory Structure
Use Glob to find: `lib/**/*.dart`

#### 5.3 Analyze Pages/Screens
Use Glob: `lib/**/*_page.dart`, `lib/**/*_screen.dart`, `lib/**/*_view.dart`

#### 5.4 Analyze Widgets
Use Glob: `lib/**/*_widget.dart`, `lib/**/*_dialog.dart`, `lib/**/*_bottom_sheet.dart`

#### 5.5 Analyze Navigation/Routing
Detect routing approach:
- Named routes: `MaterialApp(routes: ...)`
- `go_router`: `GoRouter(...)` in `lib/`
- `auto_route`: `@MaterialAutoRouter` annotations
- `GetX`: `GetPage(...)` routes
- Navigator 1.0: `Navigator.push(...)`

Use Grep: `GoRoute`, `GetPage`, `MaterialPageRoute`, `Navigator.push`, `context.go(`, `context.push(`

#### 5.6 Analyze State Management
Detect state management approach:
- `setState`: grep for `setState(()`
- `ChangeNotifier` / `Provider`: grep for `ChangeNotifier`, `Consumer`, `Provider`, `context.watch`, `context.read`
- `Riverpod`: grep for `ProviderScope`, `ref.watch`, `ref.read`, `@riverpod`
- `BLoC` / `Cubit`: grep for `BlocProvider`, `BlocBuilder`, `context.read<`, `emit(`
- `GetX`: grep for `GetxController`, `Get.put`, `Obx(`, `Get.find`
- `MobX`: grep for `@observable`, `@action`, `Store`

#### 5.7 Analyze API Interfaces
Use Grep: `@GET`, `@POST`, `@PUT`, `@DELETE`, `dio.get`, `dio.post`, `http.get`, `http.post`

### 6. Migrate Root MD Files to docs/

Scan root directory for markdown files (excluding README.md) and migrate to appropriate docs/ subdirectories.

### 7. Generate Documents

All docs go in `docs/` directory:

| Document | Content |
|----------|---------|
| PROJECT_OVERVIEW.md | 项目概览（名称、版本、SDK、技术栈、目录结构） |
| WIDGETS.md | 界面文档（页面、Widget、控件分析、功能说明） |
| NAVIGATION.md | 导航文档（路由方案、页面跳转关系、命名路由列表） |
| STATE_MANAGEMENT.md | 状态管理文档（方案、Provider/Bloc/Riverpod 列表） |
| DEPENDENCIES.md | 依赖文档（Flutter/Dart SDK、第三方依赖列表） |
| API.md | API 接口文档（URL、请求方法、参数说明） |
| CHANGELOG.md | **更新列表，支持点击查看详情** |
| update-list/*.md | **每次更新的详细内容** |

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
- 新增 `POST /user/login` 登录接口
  - 请求参数: `email`, `password`
  - 返回: `token`, `userInfo`

### WIDGETS.md

**变更类型**: 新增页面

**变更内容**:
- 新增 LoginPage 登录页面
  - 支持邮箱密码登录
  - 支持忘记密码跳转
- 更新 HomePage 说明
  - 新增用户信息展示区域

### NAVIGATION.md

**变更类型**: 更新路由

**变更内容**:
- 新增 /login 路由
  - 对应 LoginPage
  - 支持从 /home 跳转
```

### 8.3 Git Commit Detailed Analysis (CRITICAL)

**分析每个提交中每个文件的变动，多处变动都要写上：**

```markdown
## Git 提交详细分析

### a7f334e - 修复登录页面输入验证逻辑

**变动文件**:
- `lib/pages/login/login_page.dart`
  - 新增邮箱格式验证
  - 修复密码长度检查
  - 新增错误提示文案
- `lib/services/auth_service.dart`
  - 修复登录接口超时处理
  - 新加重试逻辑
- `lib/widgets/loading_button.dart`
  - 新增加载状态切换

### 612a131 - 新增用户注册流程

**变动文件**:
- `lib/pages/register/register_page.dart`
  - 新增注册页面
- `lib/services/auth_service.dart`
  - 新增注册接口
- `lib/routes/app_routes.dart`
  - 新增 /register 路由
```

**注意**：
- 每个文件的**多处变动都要列出**
- 不要写"保持不变"的文件列表
- 只写有实际变动的文件

### 8.4 What to EXCLUDE from Update Log (CRITICAL)

**以下内容只有在发生实际变动时才写入更新日志：**

| 内容类型 | 排除规则 |
|----------|----------|
| **项目统计** | Pages/Widgets 数量等统计数据，**不变动不写** |
| **页面列表** | Page/Screen 名称列表，**不变动不写** |
| **路由列表** | 路由配置，**不变动不写** |
| **状态管理** | Provider/Bloc 列表，**不变动不写** |
| **依赖库版本** | dio/flutter_riverpod 等版本号，**不变动不写** |
| **技术栈** | Flutter/Riverpod/BLoC 等技术选型，**不变动不写** |

### 8.5 Comment-Only Changes (Simplified Format)

**如果源文件只是添加了注释（没有代码逻辑变更）：**

```markdown
### API.md

**变更类型**: 新增注释

**变更内容**:
- 以下文件新增代码注释：
  - `lib/services/api_service.dart`
  - `lib/services/user_service.dart`
```

**不要展开列出完整的接口内容，只说明哪些文件增加了注释。**

### 8.6 How to Detect Actual Changes (CRITICAL)

**适用于所有文档，不只是 API.md**

**Before writing to update log, verify:**

1. **Read existing doc content** before regeneration
2. **After regeneration**, compare new content with old
3. **Only record actual differences**:
   - New sections added
   - Sections removed
   - Content modified (not just formatting)
4. **Skip if only metadata changed** (timestamps, etc.)

### 8.7 Ignore Code Formatting Changes (CRITICAL)

**代码格式化变化不应记录到更新日志：**

| 变化类型 | 是否记录 | 示例 |
|----------|----------|------|
| 新增 Widget/方法 | 记录 | 新增 `LoginPage` |
| 删除 Widget/方法 | 记录 | 删除 `OldPage` |
| 修改方法参数 | 记录 | 参数 `email` 改为 `phone` |
| 代码换行/缩进 | 不记录 | `setState(() {` 换行 |
| 代码格式化 | 不记录 | IDE 自动格式化 |
| 注释变化 | 简化记录 | 只列出文件名，不展开内容 |

**检测方法：**

```bash
# 忽略空白变化，检查是否有实际内容变化
git diff HEAD --ignore-all-space -- docs/API.md

# 如果忽略空白后没有变化，则不记录
if git diff HEAD --ignore-all-space --quiet -- docs/API.md; then
  echo "No actual changes, skip recording"
fi

# 检查源代码是否有逻辑变化（不只是格式化）
git diff HEAD --ignore-all-space -- "*.dart"
```

### 8.8 Source Code Change Detection

**分析源代码变更时，区分格式化和逻辑变化：**

```markdown
## Git 提交详细分析

### e205804 - 重构图片加载,提高加载效率

**变动文件**:
- `lib/services/image_service.dart`
  - 代码格式化（换行调整）← 无需详细展开
  - 新增 `CachedNetworkImage` 替换旧图片加载 ← 实际变更
- `lib/utils/oss_utils.dart`
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

## 2026-04-14 - 登录功能文档更新

**变更概述**: 新增用户登录相关文档，更新 API 接口说明

| 文档 | 变更类型 | 简介 |
|------|----------|------|
| API.md | 新增接口 | 新增 `/user/login` 登录接口 |
| WIDGETS.md | 新增页面 | 新增 LoginPage 登录页面 |
| NAVIGATION.md | 更新路由 | 新增 /login 路由配置 |

[查看详情](update-list/update-2026-04-14.md)

---

## 2026-04-10 - 首次文档生成

**变更概述**: 生成完整项目文档

| 文档 | 变更类型 | 简介 |
|------|----------|------|
| PROJECT_OVERVIEW.md | 新增 | 项目概览文档 |
| WIDGETS.md | 新增 | 界面文档 |
| ... | ... | ... |

[查看详情](update-list/update-2026-04-10.md)

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
| YYYY-MM-DD | 新增用户登录相关文档，更新 API 接口说明 |
| YYYY-MM-DD | 新增界面文档、导航流程文档 |
| YYYY-MM-DD | 首次生成项目文档 |

> 查看全部更新: [更新记录](docs/CHANGELOG.md)

---

### 快速开始
| 文档 | 描述 |
|------|------|
| [项目概览](docs/PROJECT_OVERVIEW.md) | 项目简介、版本信息、技术栈 |
| [界面文档](docs/WIDGETS.md) | 页面与 Widget 列表 |
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

### Route Detection
```
GoRoute\(path:\s*['"]([^'"]+)['"]
GetPage\(name:\s*['"]([^'"]+)['"]
MaterialPageRoute\(builder:.*?(\w+Page|Screen)
Navigator\.push\(
context\.go\(['"]([^'"]+)['"]
context\.push\(['"]([^'"]+)['"]
```

### State Management Detection
```
setState\(()
ChangeNotifier
context\.watch<(\w+)>
context\.read<(\w+)>
ref\.watch\(
ref\.read\(
BlocProvider<(\w+)>
BlocBuilder<(\w+),\s*(\w+)>
Get\.put<(\w+)>()
Obx\(
Store<(\w+)>
```

### API Interface Detection
```
@GET\(["']([^"']+)["']\)
@POST\(["']([^"']+)["']\)
dio\.get\(['"]([^'"]+)['"]
dio\.post\(['"]([^'"]+)['"]
http\.get\(Uri\.parse\(['"]([^'"]+)['"]
```

### Widget Type Detection
```
class\s+(\w+)\s+extends\s+StatefulWidget
class\s+(\w+)\s+extends\s+StatelessWidget
class\s+(\w+)\s+extends\s+HookWidget
class\s+(\w+)\s+extends\s+ConsumerWidget
class\s+(\w+)\s+extends\s+ConsumerStatefulWidget
```

---

## Widget Type Mapping

| Dart Pattern | Type | Category |
|-------------|------|----------|
| extends StatefulWidget | StatefulWidget | Page/Widget |
| extends StatelessWidget | StatelessWidget | Page/Widget |
| extends HookWidget | HookWidget | Page/Widget |
| extends ConsumerWidget | Riverpod Widget | Page/Widget |
| extends ConsumerStatefulWidget | Riverpod State Widget | Page/Widget |
| extends StatelessWidget with _prefix | Private Widget | Component |

---

## Notes

1. All documents are written in **Chinese**
2. Time format uses ISO 8601 standard
3. **CHANGELOG.md**: Serves as update list with links to details
4. **update-list/**: Contains detailed update content (can be regenerated)
5. **README.md**: Shows only 3 most recent updates
6. **Document changes**: Record actual document changes, not just git commits
7. **Old update-list files**: Can be deleted and regenerated if needed
8. Root md files are migrated to docs/ and deleted from root
9. Duplicate detection: keep more detailed version when merging
