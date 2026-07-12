# Git 冲突取证与处理细则

> 本文件由 `dt:push` 的 upstream rebase、push 重试和 stash restore 共用。
> Git 已自动合并的文件直接继续；任何仍出现在 unmerged index 中的文件都需要语义判断，不再使用“轻冲突自动拼接”规则。

## 1. 安全原则

- 先确认当前操作类型：rebase、stash restore，或其他明确的 Git 操作。
- 不根据 `ours` / `theirs` 的英文名称猜测“本地/远程”。rebase 会改变两者相对普通 merge 的业务含义。
- 不直接删除冲突标记并把两边文本串联；即使行号不重叠，也可能破坏语法、顺序、唯一键或业务约束。
- 不使用 `git checkout --ours/--theirs`，除非已按本文件确认当前操作语义且用户明确选择了对应版本。
- 不创建或切换分支，不创建 worktree，不 force-push，不跳过 commit hook。
- 无法可靠解释任一冲突时停止并报告，不以“自动修复”为目标冒险覆盖。

## 2. Step A：确认确实存在未解决冲突

同时检查命令退出状态和 unmerged index：

```bash
git status --short --branch
git diff --name-only --diff-filter=U
git ls-files -u
```

- 没有 unmerged 文件：说明 Git 已自动合并，继续后续流程，不展示冲突提示。
- 存在 unmerged 文件：进入 Step B。

## 3. Step B：识别操作上下文

检查 Git 状态和仓库内部状态文件，判断属于哪一种：

| 操作 | `ours` / stage 2 | `theirs` / stage 3 |
| --- | --- | --- |
| rebase | 正在 rebase 到的 upstream 基线 | 正在重放的本地 commit |
| stash pop/apply | 同步后的当前工作树版本 | 正在恢复的 stash 版本 |
| 普通 merge（若外部状态导致） | 当前分支版本 | 被合并进来的版本 |

用户可见名称必须使用表中的业务名称，例如“upstream 基线”和“本地重放 commit”，不要只显示 `ours` / `theirs`，也不要一律称作 remote/local。

如果无法确认当前操作类型，停止并展示 `git status`，不得继续选择版本。

## 4. Step C：逐文件取证

对每个 unmerged 文件收集：

```bash
git diff --cc -- <file>
git show :1:<file>
git show :2:<file>
git show :3:<file>
```

某个 stage 对新增/删除文件不存在属于正常情况，必须明确标记为“该版本不存在”，不能把读取失败当成空文件。

每个文件向用户展示：

1. 文件路径和冲突块数量。
2. 当前操作类型。
3. stage 2、stage 3 各自的业务名称与相关片段。
4. 删除/新增/二进制等特殊状态。
5. AI 推荐的处理方式及理由。
6. 拟处理后的关键片段。

仅展示相关片段，不输出整个大文件，也不输出 remote URL 中可能存在的凭据。

## 5. Step D：用户决策

对每个文件请求以下三种选择之一：

- `upstream/current`：保留当前基线或同步后的工作树版本。
- `local/stashed`：保留正在重放的本地 commit 或正在恢复的 stash 版本。
- `merge`：基于双方语义生成合并结果。

命令映射必须根据 Step B 的操作上下文确定：

### rebase

```bash
# upstream/current
git checkout --ours -- <file>

# local
git checkout --theirs -- <file>
```

### stash restore 或普通 merge

```bash
# current
git checkout --ours -- <file>

# stashed/incoming
git checkout --theirs -- <file>
```

选择 `merge` 时：

1. 根据 base、stage 2、stage 3 和 surrounding diff 生成完整合并方案。
2. 先展示关键结果及保留/删除理由。
3. 用户确认后才写回。
4. 验证文件中不再包含 `<<<<<<<`、`=======`、`>>>>>>>`。

每种选择完成后执行 `git add -- <file>`，再处理下一个文件。

## 6. Step E：继续或结束当前操作

确认没有 unmerged 文件：

```bash
git diff --name-only --diff-filter=U
git status --short --branch
```

- rebase：执行 `git rebase --continue`；若进入下一轮冲突，重复 Step A–E。
- stash restore：所有文件解决并暂存后，检查专用 stash 是否仍存在。只有确认恢复内容完整后才允许删除本流程创建的 stash；不得删除用户其他 stash。
- 普通 merge：仅在外部流程确实创建 merge 状态时按 Git 状态指引继续，不额外创建 merge commit 来绕过 rebase。

`git rebase --continue` 若打开交互式编辑器，使用非交互方式保留原 commit message；不得修改为绕过 hook 的空提交或跳过提交。

## 7. 失败处理

以下任一情况发生时停止整个 push 流程：

- 无法识别操作上下文。
- 无法读取或解释冲突版本。
- 用户没有确认重冲突的处理方式。
- `git rebase --continue` 重复失败。
- stash 内容无法确认完整恢复。
- 处理后仍有冲突标记或 unmerged index。

停止时输出仓库路径、当前分支、操作类型和 `git status --short --branch`，并给出最小恢复建议。不得自动执行 `rebase --abort`、`reset --hard`、创建备份分支或 force-push，除非用户在看到状态后另行明确授权。
