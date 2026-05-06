# dt:to-public-cloudflare

将当前项目的本地服务通过 **Cloudflare Named Tunnel** 一键暴露到公网，绑定自定义域名，自动生成 `start-public.sh` 和 `start-public.ps1`。

## 使用方式

```bash
/dt:to-public-cloudflare
```

重置配置重新走流程：

```bash
/dt:to-public-cloudflare --force-reset
```

## 功能特性

- 自动检测并安装 cloudflared（支持 macOS/Linux/Windows）
- 引导 Cloudflare 账号登录与 zone 授权
- 全局配置缓存（`~/.cloudflared/to-public-cloudflare.json`），同项目无需重复配置
- 自动侦察项目启动命令与端口（支持 Node.js/Python/Go/Spring Boot/Docker 等）
- 通过 `cloudflared tunnel route dns` 自动创建 DNS CNAME，无需登录 Dashboard 手动配置
- 生成含看门狗重试机制的 `start-public.sh` + `start-public.ps1`
- PowerShell 启动模板通过 shell 包装复杂启动命令，避免 `Start-Process` 直接执行失败
- 启动脚本退出时自动清理 tunnel 进程，二次启动前自动回收残留 cloudflared
- 启动后实时显示公网地址
- Windows 下禁止使用 `start` 命令启动 cloudflared（进程会立即退出），一律用 PowerShell `Start-Process`
- 多 tunnel 场景启动前按命令行参数检查唯一性，防止重复进程
- 提供 start-all / stop-all 多 tunnel 管理模板

## 前置要求

| 条件                    | 说明                                    |
| ----------------------- | --------------------------------------- |
| Cloudflare 账号         | 免费账号即可                            |
| 域名已托管到 Cloudflare | https://dash.cloudflare.com/ → 添加站点 |
| 本地有可运行的服务      | 任意语言/框架                           |

## 示例输出

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  服务已启动
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  本机:        http://localhost:3000
  公网(HTTPS): https://my-app.long.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 重试机制

| 操作                     | 策略                           |
| ------------------------ | ------------------------------ |
| cloudflared 安装验证     | 3 次，指数退避                 |
| tunnel 创建 / DNS 路由   | 3 次，指数退避                 |
| 启动脚本中 tunnel 看门狗 | 5 次，指数退避（2→4→8→16→32s） |
| 本地服务启动等待         | 最多 30s                       |
