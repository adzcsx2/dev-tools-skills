---
name: dt:to-public-cloudflare
description: "Cloudflare Named Tunnel one-click setup: install cloudflared, login, configure tunnel with custom domain, auto-detect project port, push DNS route, and generate start-public.sh + start-public.ps1 with retry."
argument-hint: "[--force-reset] e.g. /dt:to-public-cloudflare or /dt:to-public-cloudflare --force-reset"
---

> **中文环境要求**
>
> 本技能运行在中文环境下：
>
> - 面向用户的回复、注释、提示信息必须使用中文
> - AI 内部处理过程可以使用英文
> - 所有生成的文件必须使用 UTF-8 编码（无 BOM）
>
> ---

# to-public-cloudflare Skill

将当前项目的本地服务通过 **Cloudflare Named Tunnel** 一键暴露到公网，绑定自定义域名，生成可复用的启动脚本。

**核心命令**：`/dt:to-public-cloudflare`

参数说明：

- 无参数：按上次配置（全局缓存）自动续用，跳过已完成的步骤
- `--force-reset`：强制重新走全部配置流程（忽略缓存）

---

## 全局缓存文件

配置持久化到 `~/.cloudflared/to-public-cloudflare.json`，格式：

```json
{
  "domain": "long.com",
  "tunnels": [
    {
      "name": "aaa",
      "id": "<tunnel-id>",
      "hostname": "aaa.long.com",
      "port": 3000,
      "project": "/Users/xxx/my-project"
    }
  ]
}
```

每次执行时：

1. 读取缓存，识别当前项目目录匹配的条目
2. 有匹配条目：提示"检测到已配置 tunnel：aaa.long.com → 端口 3000，是否继续？"（y 直接跳到 Step 8 生成脚本）
3. 无匹配：走完整 9 步流程

---

## 重试工具函数（贯穿全流程）

在执行网络相关命令时，统一使用以下重试逻辑：

```bash
# retry_cmd <max_attempts> <sleep_seconds> <cmd...>
retry_cmd() {
  local max=$1 sleep_sec=$2; shift 2
  local attempt=1
  while [ $attempt -le $max ]; do
    if "$@"; then return 0; fi
    echo "[重试 $attempt/$max] 命令失败，${sleep_sec}s 后重试：$*"
    sleep "$sleep_sec"
    attempt=$((attempt + 1))
    sleep_sec=$((sleep_sec * 2))  # 指数退避
  done
  echo "[错误] 重试 $max 次仍失败：$*"
  return 1
}
```

PowerShell 等效：

```powershell
function Invoke-WithRetry {
  param([int]$MaxAttempts=3, [int]$InitialSleep=2, [scriptblock]$ScriptBlock)
  $attempt = 1; $sleep = $InitialSleep
  while ($attempt -le $MaxAttempts) {
    try { & $ScriptBlock; return } catch {
      Write-Warn "[重试 $attempt/$MaxAttempts] 失败：$_，${sleep}s 后重试"
      Start-Sleep -Seconds $sleep; $attempt++; $sleep *= 2
    }
  }
  throw "[错误] 重试 $MaxAttempts 次仍失败"
}
```

---

## Step 1：检测并安装 cloudflared

```bash
command -v cloudflared
```

**未安装时按平台处理**：

| 平台        | 命令                                            | 备用                                                                                                                  |
| ----------- | ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| macOS       | `brew install cloudflared`                      | 若无 brew → 提示安装 brew: https://brew.sh，然后重试                                                                  |
| Linux (apt) | `sudo apt-get install -y cloudflared`           | 若 apt 无此包，先添加 repo：https://pkg.cloudflare.com/index.html                                                     |
| Linux (dnf) | `sudo dnf install -y cloudflared`               | 同上                                                                                                                  |
| Windows     | `winget install --id Cloudflare.cloudflared -e` | 若无 winget，用 `choco install cloudflared`；都没有则提示手动下载：https://github.com/cloudflare/cloudflared/releases |

安装后验证：

```bash
cloudflared --version
```

输出示例：`cloudflared version 2024.x.x`。若仍失败，报错并退出。

---

## Step 2：检测登录状态

检查 cert.pem 是否存在：

```bash
# macOS/Linux
ls ~/.cloudflared/cert.pem 2>/dev/null

# Windows
Test-Path "$env:USERPROFILE\.cloudflared\cert.pem"
```

**不存在时**：

```bash
cloudflared tunnel login
```

该命令会打开浏览器，用户在 Cloudflare Dashboard 选择授权的 zone（域名）。授权完成后 `cert.pem` 自动写入。

提示用户：

```
请在浏览器中完成授权，选择你的域名（zone）。
如浏览器未自动打开，请手动访问终端显示的链接。
授权完成后，按任意键继续...
```

等待用户按键后，验证 cert.pem 是否生成（重试 3 次，间隔 2s）。

---

## Step 3：确认域名

从全局缓存读取 `domain`：

- **有缓存**：提示"当前域名是 `long.com`，是否保留？（y/n）"
  - y → 使用缓存域名
  - n → 提示重新输入
- **无缓存**：提示"请输入你在 Cloudflare 上已托管的域名（如 long.com）："

提示前置条件：

```
域名须已添加到 Cloudflare 并完成 NS 配置。
如未完成：https://dash.cloudflare.com/ → 添加站点 → 按向导修改 NS 记录
```

输入后校验格式（至少包含一个点，无协议前缀），不合法则提示重新输入。

---

## Step 4：校验授权作用域

执行：

```bash
retry_cmd 3 2 cloudflared tunnel list
```

- **成功（包括空列表）**：授权正常，继续
- **返回 401/403 或报认证错误**：提示重新登录，跳回 Step 2

---

## Step 5：输入 tunnel 名并创建

询问用户：

```
请输入 tunnel 名（英文+数字+-，如 my-app）：
```

合法性校验：只允许 `[a-z0-9-]`，不能以 `-` 开头或结尾。

**查询是否已存在**：

```bash
cloudflared tunnel list --output json 2>/dev/null | grep -q "\"name\":\"$TUNNEL_NAME\""
```

若 jq 可用，用：

```bash
cloudflared tunnel list --output json | jq -e ".[] | select(.name==\"$TUNNEL_NAME\")"
```

- **已存在**：提示"tunnel `aaa` 已存在，是否复用？（y）/ 换一个名字（n）"
  - y → 从 JSON 中读取 tunnel-id，跳到 Step 6
  - n → 重新输入
- **不存在**：
  ```bash
  retry_cmd 3 2 cloudflared tunnel create "$TUNNEL_NAME"
  ```
  解析输出中的 tunnel-id（格式 UUID），确认 `~/.cloudflared/<id>.json` 已生成。

合成完整 hostname = `<tunnel-name>.<domain>`（如 `aaa.long.com`）。

---

## Step 6：检测项目启动命令与端口

在项目根目录按以下优先级侦察（从高到低），找到第一个有效端口即停止：

| 优先级 | 来源文件                                                               | 侦察方式                                  |
| ------ | ---------------------------------------------------------------------- | ----------------------------------------- |
| 1      | `start.sh` / `start.ps1` / `run.sh`                                    | 搜索 `PORT=` / `--port`                   |
| 2      | `package.json` scripts.dev/start                                       | 搜索 `-p \d+` / `--port \d+` / `PORT=\d+` |
| 3      | `.env` / `.env.local` / `.env.development`                             | 搜索 `^PORT=\d+`                          |
| 4      | `vite.config.*` / `next.config.*`                                      | 搜索 `port:\s*\d+`                        |
| 5      | Python: `app.run(port=` / `uvicorn ... --port` / `manage.py runserver` | 搜索 `port=\d+` / `--port \d+`；默认 8000 |
| 6      | Spring Boot: `application.properties/yml`                              | 搜索 `server\.port=\d+`                   |
| 7      | Go: `ListenAndServe\(":\d+`                                            | 正则搜索                                  |
| 8      | `docker-compose.yml`                                                   | 搜索 `ports:` 中的宿主端口                |

**有侦察结果时**：

```
检测到启动命令：npm run dev
端口：3000（来源：package.json scripts.dev）
是否修改端口？直接回车保留 3000，或输入新端口号：
```

用户输入新端口时：

1. 修改原配置文件中的端口（精确替换，只改端口数字，不改其他参数）
2. 改动前展示 diff
3. 让用户确认

**无侦察结果时**：

```
未能自动检测到启动命令或端口。
请输入项目启动命令（如 npm run dev、python main.py、./start.sh）：
请输入服务监听端口（如 3000）：
```

---

## Step 7：生成 cloudflare 配置并推送路由

**生成项目内配置文件** `<project>/.cloudflared/config.yml`（写入项目，建议加入 .gitignore）：

```yaml
tunnel: <tunnel-id>
credentials-file: /Users/<user>/.cloudflared/<tunnel-id>.json
ingress:
  - hostname: aaa.long.com
    service: http://localhost:3000
  - service: http_status:404
```

Windows 路径用 `\` → 写入时改为 `/`（cloudflared 在 Windows 也接受 `/`）。

**推送 DNS CNAME（无需进 Dashboard）**：

```bash
retry_cmd 3 3 cloudflared tunnel route dns "$TUNNEL_NAME" "$HOSTNAME"
```

该命令在 Cloudflare 自动创建 CNAME：`aaa.long.com → <tunnel-id>.cfargotunnel.com`。

成功后验证：

```bash
cloudflared tunnel info "$TUNNEL_NAME"
```

输出中应含 "connector" 和 hostname 信息。

---

## Step 8：生成启动脚本

在项目根生成 `start-public.sh`（macOS/Linux）和 `start-public.ps1`（Windows），注意：

- 如果项目根已有 `start.sh`（或 `start.ps1`），**以它为模板追加 tunnel 逻辑，而非全部重写**；保留原启动命令不变
- 若无原脚本，从零生成

### start-public.sh 模板

```bash
#!/usr/bin/env bash
# <项目名> 公网启动脚本（Cloudflare Named Tunnel）
# 公网地址：https://<hostname>
# 自动生成，请勿手动修改 tunnel 相关配置

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TUNNEL_NAME="<tunnel-name>"
HOSTNAME="<hostname>"
PORT=<port>
CONFIG_FILE="$ROOT/.cloudflared/config.yml"
TUNNEL_LOG="/tmp/${TUNNEL_NAME}-tunnel.log"
TUNNEL_PID_FILE="$ROOT/.cloudflared/${TUNNEL_NAME}.pid"
CLEANUP_DONE=0

cleanup_stale_tunnel() {
  if [ -f "$TUNNEL_PID_FILE" ]; then
    OLD_TUNNEL_PID="$(cat "$TUNNEL_PID_FILE" 2>/dev/null || true)"
    if [ -n "$OLD_TUNNEL_PID" ] && kill -0 "$OLD_TUNNEL_PID" 2>/dev/null; then
      echo -e "${YELLOW}[提示] 检测到上次残留的 Cloudflare Tunnel 进程（PID: $OLD_TUNNEL_PID），正在清理...${NC}"
      kill "$OLD_TUNNEL_PID" 2>/dev/null || true
      wait "$OLD_TUNNEL_PID" 2>/dev/null || true
    fi
    rm -f "$TUNNEL_PID_FILE"
  fi
}

# ========== 检查 cloudflared ==========
if ! command -v cloudflared &>/dev/null; then
  echo -e "${RED}[错误] 未找到 cloudflared，请先运行 /dt:to-public-cloudflare 完成安装${NC}"
  exit 1
fi

# ========== 启动项目 ==========
# [如有原 start.sh 则将其原始启动命令插入此处]
echo -e "${BOLD}▶ 启动项目服务（端口 $PORT）...${NC}"
<original-start-command> &
APP_PID=$!

# 等待端口就绪（最多 30s）
echo -n "  等待服务启动"
for i in $(seq 1 60); do
  if lsof -iTCP:$PORT -sTCP:LISTEN &>/dev/null 2>&1 || \
     ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
    echo -e " ${GREEN}就绪${NC}"
    break
  fi
  echo -n "."
  sleep 0.5
  if [ $i -eq 60 ]; then
    echo -e " ${RED}超时${NC}"
    echo -e "${RED}[错误] 服务未能在 30s 内启动，请检查启动命令${NC}"
    kill $APP_PID 2>/dev/null || true
    exit 1
  fi
done

# ========== 启动 Cloudflare Tunnel（带看门狗重试）==========
echo -e "${BOLD}▶ 启动 Cloudflare Tunnel (${TUNNEL_NAME})...${NC}"

start_tunnel() {
  cloudflared tunnel --config "$CONFIG_FILE" run "$TUNNEL_NAME" >"$TUNNEL_LOG" 2>&1 &
  local tunnel_pid=$!
  printf '%s\n' "$tunnel_pid" > "$TUNNEL_PID_FILE"
  echo "$tunnel_pid"
}

cleanup_stale_tunnel
TUNNEL_PID=$(start_tunnel)
TUNNEL_RETRY=0
MAX_TUNNEL_RETRY=5
WATCH_INTERVAL=15

monitor_tunnel() {
  while true; do
    sleep $WATCH_INTERVAL
    if ! kill -0 $TUNNEL_PID 2>/dev/null; then
      TUNNEL_RETRY=$((TUNNEL_RETRY + 1))
      if [ $TUNNEL_RETRY -gt $MAX_TUNNEL_RETRY ]; then
        echo -e "\n${RED}[错误] Tunnel 重试 $MAX_TUNNEL_RETRY 次仍失败，查看日志：$TUNNEL_LOG${NC}"
        kill $APP_PID 2>/dev/null || true
        exit 1
      fi
      SLEEP_SEC=$((TUNNEL_RETRY * 2))
      echo -e "\n${YELLOW}[Tunnel 断线] 第 $TUNNEL_RETRY 次重连，${SLEEP_SEC}s 后重试...${NC}"
      sleep $SLEEP_SEC
      TUNNEL_PID=$(start_tunnel)
    fi
  done
}

monitor_tunnel &
MONITOR_PID=$!

# ========== 打印公网地址 ==========
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  服务已启动${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  本机:        http://localhost:${PORT}"
echo -e "  公网(HTTPS): ${BOLD}https://${HOSTNAME}${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  按 ${BOLD}Ctrl+C${NC} 停止所有服务"
echo ""

# ========== 清理 ==========
cleanup() {
  local exit_code=$?
  if [ "$CLEANUP_DONE" -eq 1 ]; then
    return
  fi
  CLEANUP_DONE=1

  echo -e "\n${YELLOW}▶ 正在停止服务...${NC}"
  for pid in "${MONITOR_PID:-}" "${TUNNEL_PID:-}" "${APP_PID:-}"; do
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
  done
  rm -f "$TUNNEL_PID_FILE"
  echo -e "${GREEN}▶ 已停止${NC}"
  return "$exit_code"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

wait $APP_PID
```

### start-public.ps1 模板

```powershell
# <项目名> 公网启动脚本（Cloudflare Named Tunnel）
# 公网地址：https://<hostname>
# 自动生成，请勿手动修改 tunnel 相关配置

$TunnelName = "<tunnel-name>"
$Hostname   = "<hostname>"
$Port       = <port>
$Root       = $PSScriptRoot
$ConfigFile = Join-Path $Root ".cloudflared\config.yml"
$TunnelLog  = "$env:TEMP\$TunnelName-tunnel.log"
$TunnelPidFile = Join-Path $Root ".cloudflared\$TunnelName.pid"

function Stop-StaleTunnel {
  if (-not (Test-Path $TunnelPidFile)) { return }

  $oldPid = (Get-Content $TunnelPidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
  if ($oldPid) {
    $oldProcess = Get-Process -Id ([int]$oldPid) -ErrorAction SilentlyContinue
    if ($oldProcess) {
      Write-Host "[提示] 检测到上次残留的 Cloudflare Tunnel 进程（PID: $oldPid），正在清理..." -ForegroundColor Yellow
      Stop-Process -Id $oldProcess.Id -Force -ErrorAction SilentlyContinue
    }
  }

  Remove-Item $TunnelPidFile -Force -ErrorAction SilentlyContinue
}

# 检查 cloudflared
if (-not (Get-Command cloudflared -ErrorAction SilentlyContinue)) {
    Write-Host "[错误] 未找到 cloudflared，请先运行 /dt:to-public-cloudflare" -ForegroundColor Red
    exit 1
}

# 启动项目
Write-Host "▶ 启动项目服务（端口 $Port）..." -ForegroundColor White
# [如有原 start.ps1 则将其原始启动命令写入 $AppCommand；复杂命令统一交给 shell 执行]
$AppCommand = "<original-start-command>"
$PowerShellShell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
$AppProcess = Start-Process -FilePath $PowerShellShell `
  -ArgumentList "-NoLogo","-NoProfile","-Command",$AppCommand `
  -WorkingDirectory $Root -PassThru -NoNewWindow

# 等待端口就绪（最多 30s）
Write-Host -NoNewline "  等待服务启动"
$ready = $false
for ($i = 0; $i -lt 60; $i++) {
    $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($conn) { Write-Host " 就绪" -ForegroundColor Green; $ready = $true; break }
    Write-Host -NoNewline "."
    Start-Sleep -Milliseconds 500
}
if (-not $ready) {
    Write-Host " 超时" -ForegroundColor Red
    Write-Host "[错误] 服务未能在 30s 内启动" -ForegroundColor Red
    Stop-Process -Id $AppProcess.Id -Force -ErrorAction SilentlyContinue
    exit 1
}

# 启动 Tunnel（带重试看门狗）
Write-Host "▶ 启动 Cloudflare Tunnel ($TunnelName)..." -ForegroundColor White

function Start-Tunnel {
  $process = Start-Process cloudflared -ArgumentList "tunnel","--config",$ConfigFile,"run",$TunnelName `
        -PassThru -NoNewWindow -RedirectStandardOutput $TunnelLog -RedirectStandardError $TunnelLog
  [System.IO.File]::WriteAllText($TunnelPidFile, $process.Id.ToString(), [System.Text.UTF8Encoding]::new($false))
  return $process
}

Stop-StaleTunnel
$TunnelProcess = Start-Tunnel
$TunnelRetry = 0
$MaxRetry = 5

$WatchJob = Start-Job -ScriptBlock {
    param($tp, $max, $cfg, $name, $log)
    $retry = 0; $sleep = 2
    while ($true) {
        Start-Sleep -Seconds 15
        if ($tp.HasExited) {
            $retry++
            if ($retry -gt $max) { Write-Output "[错误] Tunnel 重试 $max 次失败"; return }
            Write-Output "[Tunnel 断线] 第 $retry 次重连，${sleep}s 后重试..."
            Start-Sleep -Seconds $sleep; $sleep *= 2
            $tp = Start-Process cloudflared -ArgumentList "tunnel","--config",$cfg,"run",$name `
                -PassThru -NoNewWindow -RedirectStandardOutput $log -RedirectStandardError $log
        }
    }
} -ArgumentList $TunnelProcess, $MaxRetry, $ConfigFile, $TunnelName, $TunnelLog

# 打印公网地址
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor White
Write-Host "  服务已启动" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor White
Write-Host "  本机:        http://localhost:$Port"
Write-Host "  公网(HTTPS): https://$Hostname" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor White
Write-Host "  按 Ctrl+C 停止所有服务"
Write-Host ""

# 等待并清理
try {
    $AppProcess | Wait-Process
} finally {
    Stop-Job $WatchJob -ErrorAction SilentlyContinue
    Remove-Job $WatchJob -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $TunnelProcess.Id -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $AppProcess.Id -Force -ErrorAction SilentlyContinue
  Remove-Item $TunnelPidFile -Force -ErrorAction SilentlyContinue
    Write-Host "`n▶ 已停止" -ForegroundColor Yellow
}
```

---

## Step 9：重试保障总结

| 操作                                  | 重试策略                                 |
| ------------------------------------- | ---------------------------------------- |
| `cloudflared --version` 安装验证      | 最多 3 次，间隔 2s                       |
| `cloudflared tunnel list`（授权校验） | 最多 3 次，间隔 2s（指数退避）           |
| `cloudflared tunnel create`           | 最多 3 次，间隔 2s（指数退避）           |
| `cloudflared tunnel route dns`        | 最多 3 次，间隔 3s（指数退避）           |
| 启动脚本中 tunnel run（看门狗重启）   | 最多 5 次，间隔 2/4/8/16/32s（指数退避） |
| 端口等待（本地服务就绪）              | 最多 60 次 × 0.5s = 30s                  |

---

## 更新全局缓存

完整流程走完后，更新 `~/.cloudflared/to-public-cloudflare.json`：

```bash
# 读取现有 JSON
CACHE_FILE="$HOME/.cloudflared/to-public-cloudflare.json"
[ -f "$CACHE_FILE" ] || echo '{"tunnels":[]}' > "$CACHE_FILE"

# 追加或更新当前项目的 tunnel 条目（用 python3 兜底，jq 优先）
if command -v jq &>/dev/null; then
  NEW_ENTRY=$(jq -n \
    --arg name "$TUNNEL_NAME" --arg id "$TUNNEL_ID" \
    --arg hostname "$HOSTNAME" --argjson port "$PORT" \
    --arg project "$PWD" \
    '{name:$name,id:$id,hostname:$hostname,port:$port,project:$project}')
  jq --arg domain "$DOMAIN" \
    --arg project "$PWD" \
    --argjson entry "$NEW_ENTRY" \
    '.domain = $domain |
     .tunnels = ((.tunnels // []) | map(select(.project != $project)) + [$entry])' \
    "$CACHE_FILE" > /tmp/cf-cache-tmp.json && mv /tmp/cf-cache-tmp.json "$CACHE_FILE"
else
  python3 -c "
import json, os, sys
f = '$CACHE_FILE'
data = json.load(open(f)) if os.path.exists(f) else {'tunnels':[]}
data['domain'] = '$DOMAIN'
data['tunnels'] = [t for t in data.get('tunnels',[]) if t.get('project') != '$PWD']
data['tunnels'].append({'name':'$TUNNEL_NAME','id':'$TUNNEL_ID','hostname':'$HOSTNAME','port':$PORT,'project':'$PWD'})
json.dump(data, open(f,'w'), indent=2, ensure_ascii=False)
"
fi
```

---

## 完成提示

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  配置完成！
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  公网地址：https://aaa.long.com
  启动脚本：./start-public.sh（macOS/Linux）
           .\start-public.ps1（Windows）

  提示：
  - 首次运行需要 Cloudflare edge 建立连接，可能需要 10-30s
  - 如脚本中途失败请查看 /tmp/<tunnel>-tunnel.log
  - 管理 tunnel：https://dash.cloudflare.com/
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 注意事项

1. **域名必须已托管到 Cloudflare**（NS 记录已指向 Cloudflare）才能用 `tunnel route dns` 自动创建 CNAME
2. `cert.pem` 是账户级凭证，一个账户只需 `tunnel login` 一次
3. 每个 tunnel 对应一个 credentials JSON 文件，请勿删除 `~/.cloudflared/<id>.json`
4. 生成的 `start-public.sh` / `start-public.ps1` 可提交到 git；`.cloudflared/config.yml` 中有本地路径，建议加入 `.gitignore`
5. Windows 用户首次运行 ps1 可能需要：`Set-ExecutionPolicy -Scope Process RemoteSigned`
6. tunnel 名在 Cloudflare 账户内全局唯一，同名 tunnel 不能重复创建

---

## Windows 常见陷阱与最佳实践

### 陷阱 1：`start` 命令在 .bat 中不可靠（必须避免）

Windows `.bat` 文件中用 `start` 后台启动 cloudflared **会失败**：

```bat
:: 错误写法 —— 进程会立即退出，报 "The system cannot find the file <title>"
start "cloudflared-build" /min cloudflared.exe tunnel --config "config.yml" run
```

**原因**：`start` 的第一个带引号参数会被当作窗口标题，但在某些环境（MSYS2/Git Bash/某些 CMD 版本）下，`start` 会将标题误解为要执行的可执行文件名，导致进程立即退出。

**正确做法**：在 .bat 中通过 PowerShell 启动：

```bat
:: 正确写法 —— 进程可靠存活
powershell -Command "Start-Process -FilePath 'cloudflared.exe' -ArgumentList 'tunnel','--config','%USERPROFILE%\.cloudflared\config.yml','run' -WindowStyle Minimized"
```

**重要**：生成任何 Windows 启动脚本（.bat 或 .ps1）时，**禁止使用 `start` 命令启动 cloudflared**，一律用 PowerShell `Start-Process`。

### 陷阱 2：进程唯一性 —— 防止重复启动

多次执行启动脚本会产生多个 cloudflared 进程，导致：
- 重复的 tunnel 连接（浪费资源）
- Cloudflare 返回 1033 错误（连接冲突）
- stop 时残留孤儿进程

**启动前必须检查**（按命令行参数匹配，而非窗口标题）：

```bat
:: .bat 中检查唯一性
powershell -Command "Get-CimInstance Win32_Process -Filter \"name='cloudflared.exe'\" | Where-Object {$_.CommandLine -like '*config-build*'} | Select-Object -First 1" 2>nul | findstr /i "cloudflared" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [SKIP] tunnel already running
) else (
    powershell -Command "Start-Process -FilePath 'cloudflared.exe' -ArgumentList 'tunnel','--config','config.yml','run' -WindowStyle Minimized"
)
```

```powershell
# .ps1 中检查唯一性
$existing = Get-CimInstance Win32_Process -Filter "name='cloudflared.exe'" |
    Where-Object { $_.CommandLine -like "*$ConfigFile*" }
if ($existing) {
    Write-Host "[SKIP] tunnel already running (PID: $($existing.ProcessId))"
} else {
    Start-Process cloudflared -ArgumentList "tunnel","--config",$ConfigFile,"run" -WindowStyle Minimized
}
```

### 陷阱 3：停止 tunnel 要按命令行精确匹配

用窗口标题 `taskkill /FI "WINDOWTITLE eq ..."` 不可靠（`Start-Process` 不设置窗口标题）。正确做法：

```bat
:: 按 command line 匹配杀进程
powershell -Command "Get-CimInstance Win32_Process -Filter \"name='cloudflared.exe'\" | Where-Object {$_.CommandLine -like '*config-web*' -or $_.CommandLine -like '*config-build*'} | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }"
```

### 多 tunnel 管理（start-all / stop-all）模板

当一台机器跑多个 tunnel 时，推荐以下 .bat 模板：

```bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ---- 定义 tunnel 列表 ----
set "tunnel_count=2"
set "t1_config=%USERPROFILE%\.cloudflared\config-web.yml"
set "t2_config=%USERPROFILE%\.cloudflared\config-build.yml"

:: ---- 唯一性检查 + 启动 ----
for /l %%i in (1,1,%tunnel_count%) do (
    set "tconfig=!t%%i_config!"

    powershell -Command "Get-CimInstance Win32_Process -Filter \"name='cloudflared.exe'\" | Where-Object {$_.CommandLine -like '*!tconfig!*'} | Select-Object -First 1" 2>nul | findstr /i "cloudflared" >nul 2>&1
    if !errorlevel! equ 0 (
        echo   [SKIP] !tconfig! already running
    ) else (
        powershell -Command "Start-Process -FilePath 'cloudflared.exe' -ArgumentList 'tunnel','--config','!tconfig!','run' -WindowStyle Minimized"
        echo   [START] !tconfig! started
    )
)

:: ---- stop-all 模板 ----
:: powershell -Command "Get-CimInstance Win32_Process -Filter \"name='cloudflared.exe'\" | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }"
endlocal
```

### 诊断命令

当 tunnel 无法访问时，按以下顺序排查：

```bash
# 1. 检查 tunnel 是否有活跃连接（最关键）
cloudflared tunnel info <tunnel-id-or-name>
# "does not have any active connection" = tunnel 进程没在跑

# 2. 检查本地服务是否在监听
netstat -ano | grep ":<port> " | grep LISTEN

# 3. 本地直接 curl 测试
curl -s -o /dev/null -w "%{http_code}" http://localhost:<port>/

# 4. 通过域名 curl 测试
curl -s -o /dev/null -w "%{http_code}" https://<hostname>/
# 返回 530 + "error code: 1033" = tunnel 进程未连接到 Cloudflare edge

# 5. 检查是否有 cloudflared 进程在跑
powershell -Command "Get-CimInstance Win32_Process -Filter \"name='cloudflared.exe'\" | Select-Object ProcessId, CommandLine | Format-List"

# 6. 前台运行看详细日志（调试用）
cloudflared.exe tunnel --config "config.yml" run
```
