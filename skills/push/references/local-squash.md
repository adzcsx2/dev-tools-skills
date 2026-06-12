# 本地未推送提交整理（squash）细则

> 本文件服务于 `dt:push` 的 Step 4.5（本地未推送提交整理）。
> 主 SKILL.md 只保留触发条件和硬约束摘要，校验、聚合提交、执行、回退的完整流程全部在此。
> **本步骤会改写本地 commit 历史，必须严格按顺序执行下方每一步，任何一步无法满足就立即放弃整理、保留原历史。**

## 破坏性安全说明（先读再做）

整理采用 `git reset --soft @{u}` + 重建 **1 个聚合 commit** 的方式实现，它的安全边界如下：

- `git reset --soft` **只移动 HEAD 指针**，所有改动完整保留在暂存区，**不修改任何工作区文件、不删除任何代码**
- 整理基线固定为 upstream（`@{u}`），范围严格限定 `@{u}..HEAD`，**已推送到远程的提交永远不会被触碰**
- 这些 commit 从未推送，重建后用**普通 `git push`** 即可，**不需要也禁止 force-push**
- 整理只改变 commit 历史结构：多个未推送 commit 会被压成 1 个干净 commit，**整理前后最终代码内容必须完全一致**（由第 4 步强制校验）

只要严格按本文件流程执行，整理**不会**对现有代码造成破坏性改变。风险只来自"跳步"或"误把工作区其他变更卷进来"，下方流程已逐项堵死。

## 触发与跳过条件

- 仅在存在 upstream 且 `git rev-list --count @{u}..HEAD` ≥ 2 时才进入本步骤
- 本地未推送 commit < 2 个：无可合并对象，**跳过**，直接进入 Step 5
- 无 upstream（首次推送当前分支）：缺少"已推送基线"，**默认跳过整理**，原样首推；除非用户显式要求整理首推历史

## 第 0 步：前置守卫（强制，reset 前必须确认）

在执行任何 reset 之前，必须确认下面两点，否则**放弃整理**直接进入 Step 5：

1. **工作区必须干净**：执行 `git status --porcelain`，输出为空。
   - Step 4 已先行把所有工作区变更分组提交，正常情况下此处工作区应当干净
   - 若此处仍有未提交变更，说明状态异常，**禁止 reset**（否则会把这些变更与历史整理混在一起），保留原历史进入 Step 5 并提示用户
2. **记录回退锚点**（这一步必须在 reset 之前完成，否则丢失回退点）：

```bash
# 用专属变量名，避免与 git 内置的 ORIG_HEAD 撞名（reset 也会写 ORIG_HEAD）
SQUASH_ORIG=$(git rev-parse HEAD)
BASE=$(git rev-parse @{u})
```

记录整理前 `@{u}..HEAD` 的最终内容指纹，供第 4 步校验：

```bash
git diff "$BASE" HEAD > /tmp/dt-push-before.diff
```

## 第 1 步：安全边界校验（强制）

整理只能发生在"连续、纯本人、未推送"的提交序列上。按顺序校验，任一不满足就执行"保留原历史"（无需 reset，因为尚未 reset），进入 Step 5：

1. **整理基线**：基线固定为 `@{u}`，范围严格限定 `@{u}..HEAD`，基线及其之前的提交一律不动。
2. **作者一致性校验**：逐个比对 `@{u}..HEAD` 每个 commit 的作者邮箱与当前用户邮箱（`git config user.email`）：
   - 全部一致 → 通过
   - 中途出现**任何**他人提交（邮箱不一致）→ **中止整理**，保留全部原始 commit 不动
3. **连续性校验**：确认 `@{u}..HEAD` 中不存在 merge commit：

```bash
git log @{u}..HEAD --merges
```

有输出（存在 merge commit）→ **中止整理**，保留原历史。

4. **未推送校验**：再次确认待整理的每个 commit 都不在任何远程分支：

```bash
git branch -r --contains <sha>
```

任一 commit 已存在于某个远程分支 → **中止整理**，保留原历史。不要动态调整基线，不要尝试只整理部分提交，避免误改已经对外可见的历史。

只有全部校验通过，才进入第 2 步。

## 第 2 步：生成单个聚合 commit message

获取每个 commit 的元信息与改动文件：

```bash
git log @{u}..HEAD --pretty=format:'%h|%s' --name-only
```

必要时读取单个 commit 的完整 diff：

```bash
git show <sha> --stat
git show <sha>
```

**聚合规则**：

- 不再把未推送 commit 拆成多个逻辑分组；本步骤的目标是把 `@{u}..HEAD` 的全部最终改动压成 **1 个 commit**
- commit message 必须概括全部未推送改动的最终意图，而不是罗列每个旧 commit message
- 若被压缩的任一旧 commit 或最终 diff 涉及版本号更新，聚合 commit title / message 第一行必须明确包含目标版本号（如 `chore: 发布 1.2.2 并更新文档`），不得只写“整理提交”“发版准备”等模糊标题
- 修补型 message（`wip`、`fix typo`、`address review`、`修复上一个提交` 等）只作为判断上下文，**不得**原样保留到最终 message
- 若多个旧 commit 覆盖多个主题，最终 message 使用能覆盖整体变更的描述，例如 `feat: 完成推送流程优化`、`docs: 完善 push skill 文档`、`refactor: 简化本地提交整理流程`
- 若无法给出可信的聚合 message，**中止整理**，保留原历史进入 Step 5

## 第 3 步：整理执行（soft reset 后重建 1 个 commit，不用 force-push）

确认第 0–2 步全部通过后才执行。

```bash
# soft reset 到基线：撤销本地所有未推送 commit，改动完整保留在暂存区，工作区文件不变
git reset --soft "$BASE"

# 重建为 1 个聚合 commit：一次性暂存全部最终改动，避免按文件拆分时漏改或误分组
git add -A
git commit -m "<聚合后的 commit message>"
```

**执行要点（防漏、防污染）**：

- reset 后必须直接使用 `git add -A`，**禁止**按文件、按目录、按 patch 拆分提交
- 提交完成后，执行 `git status --porcelain` 确认暂存区/工作区**已清空**——若仍有残留文件未提交，说明整理状态异常，立即按第 5 步回退
- 重建提交时**只能**重新提交原本属于这些未推送 commit 的改动，不得混入其他变更（第 0 步已确认工作区干净，正常不会发生）
- 若某次 `git commit` 触发 pre-commit hook **改写了文件**（如格式化），会导致最终内容与整理前不一致 → 这属于第 4 步校验会拦截的情况，按第 5 步回退并提示用户先处理 hook

## 第 4 步：整理后强制一致性校验（gate，不通过必须回退）

重建完成后，**必须**校验整理只改了历史结构、没改最终代码：

```bash
# 1. 新 commit 数必须是 1
git rev-list --count @{u}..HEAD

# 2. 最终内容指纹必须与整理前完全一致
git diff "$BASE" HEAD > /tmp/dt-push-after.diff
diff /tmp/dt-push-before.diff /tmp/dt-push-after.diff
```

- 新 commit 数为 1 且两个 diff **完全一致**（`diff` 无输出）→ 整理成功，进入 Step 5 推送
- 新 commit 数不是 1 → 整理结果不符合"压成 1 个 commit"目标，**立即执行第 5 步回退**
- 两个 diff **不一致** → 整理破坏了代码内容，**立即执行第 5 步回退**，不得推送被破坏的历史

## 第 5 步：失败回退（恢复原始本地历史）

第 0–4 步任一环节失败（reset 后某步报错、漏文件、hook 改写、一致性校验不过等），立即恢复整理前的本地历史和干净工作区：

```bash
git reset --hard "$SQUASH_ORIG"
git status --porcelain
```

恢复后检查 `git status --porcelain`：

- 输出为空 → 停止整理，向用户报告失败原因，**保留原始 commit 历史**进入 Step 5 原样推送
- 输出不为空 → 停止整个 push 流程，向用户报告失败原因和当前 `git status`，等待人工决策

**禁止**创建新分支、**禁止** force-push、**禁止**推送被破坏的历史。

## 第 6 步：整理后的 commit message 生成

整理后的 commit message 基于**所有未推送 commit 的聚合改动**生成，规则与 Step 4 的 commit message 规则一致：

- 使用中文描述，按聚合改动判断 type（`feat` / `fix` / `refactor` / `docs` / `chore` / `style` / `test`）
- 描述概括全部最终改动的核心意图，而非罗列被合并的每个旧 commit message
- 若聚合改动涉及版本号更新，标题必须明确包含目标版本号
- 修补型 commit（`wip`、`fix typo` 等）的措辞**不得**保留进最终 message
- **禁止**追加 `Co-Authored-By` 行

## Dry-run 模式（预览）

执行 `/dt:push --preview` 时，本步骤仅展示整理方案，**不执行任何写入性 git 操作（禁止 reset / commit / push）**：

```
[preview] 本地未推送提交整理方案：

校验结果：5 个未推送 commit，全部由当前用户提交，中途无他人提交，可整理。

整理方式：全部未推送 commit 压成 1 个聚合 commit
  原始：a1b2c3d feat: 登录页 / d4e5f6a fix: 按钮样式 / 7a8b9c0 wip / 1122334 docs: 更新 README / 4455667 fix: 文案
  整理后：feat: 完善登录页并更新相关文档

整理后本地未推送 commit：5 → 1 个；最终代码内容不变。
```

若校验未通过（中途有他人提交 / 含 merge commit / 工作区不干净等），preview 中明确说明"不满足整理条件，将原样推送"。
