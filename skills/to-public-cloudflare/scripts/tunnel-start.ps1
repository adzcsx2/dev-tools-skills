# Cloudflare Tunnel Start
# Starts specified tunnels (or all) from registry + launches health monitor
# Usage: tunnel-start [name1] [name2] ...

$CF_DIR = Join-Path $env:USERPROFILE ".cloudflared"
$REGISTRY_FILE = Join-Path $CF_DIR "tunnel-registry.json"

function Write-Info($msg) { Write-Host "  $msg" -ForegroundColor Blue }
function Write-Ok($msg)   { Write-Host "  $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  $msg" -ForegroundColor Yellow }

if (-not (Test-Path $REGISTRY_FILE)) {
    Write-Host "No tunnel registry found. Run 'tunnel-add' first." -ForegroundColor Red
    exit 1
}

$reg = Get-Content $REGISTRY_FILE -Raw -Encoding UTF8 | ConvertFrom-Json
$allTunnels = $reg.tunnels

# Filter by arguments if provided
$selectedTunnels = $allTunnels
if ($args.Count -gt 0) {
    $selectedTunnels = $allTunnels | Where-Object { $args -contains $_.name }
    $missing = $args | Where-Object { $_ -notin $allTunnels.name }
    if ($missing) {
        Write-Warn "Tunnels not found in registry: $($missing -join ', ')"
    }
}

if (-not $selectedTunnels -or $selectedTunnels.Count -eq 0) {
    Write-Host "No matching tunnels found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "  Starting Cloudflare Tunnels..." -ForegroundColor Cyan
Write-Host ""

foreach ($t in $selectedTunnels) {
    $configPath = Join-Path $CF_DIR $t.config_file

    if (-not (Test-Path $configPath)) {
        Write-Warn "[SKIP] $($t.name) - config not found: $($t.config_file)"
        continue
    }

    # Check if already running
    $existing = Get-CimInstance Win32_Process -Filter "name='cloudflared.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*$configPath*" } |
        Select-Object -First 1

    if ($existing) {
        Write-Info "[SKIP] $($t.name) already running (PID: $($existing.ProcessId))"
    } else {
        Start-Process -FilePath "cloudflared.exe" `
            -ArgumentList "tunnel","--config",$configPath,"run" `
            -WindowStyle Minimized
        Write-Ok "[START] $($t.name) - https://$($t.hostname) <- localhost:$($t.port)"
    }
}

# ---- Start health monitor ----
Write-Host ""
Write-Host "  Starting health monitor..." -ForegroundColor Cyan

$HC_SCRIPT = Join-Path $env:USERPROFILE "bin\tunnel-healthcheck.ps1"

# Kill existing healthcheck
$HC_PID_FILE = "$env:TEMP\tunnel-healthcheck.pid"
if (Test-Path $HC_PID_FILE) {
    $oldPid = Get-Content $HC_PID_FILE -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($oldPid) {
        Stop-Process -Id ([int]$oldPid) -Force -ErrorAction SilentlyContinue
    }
    Remove-Item $HC_PID_FILE -Force -ErrorAction SilentlyContinue
}

# Also kill any PowerShell running tunnel-healthcheck
Get-CimInstance Win32_Process -Filter "name='powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like '*tunnel-healthcheck*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

if (Test-Path $HC_SCRIPT) {
    Start-Process -FilePath "powershell" `
        -ArgumentList "-ExecutionPolicy","Bypass","-NoProfile","-File",$HC_SCRIPT `
        -WindowStyle Minimized
    Write-Ok "Health monitor running"
    Write-Info "Log: $env:TEMP\tunnel-healthcheck.log"
} else {
    Write-Warn "tunnel-healthcheck.ps1 not found in ~/bin/, health monitoring disabled"
}

# ---- Summary ----
Write-Host ""
Write-Host "  ========================================" -ForegroundColor White
Write-Host "  Tunnels started" -ForegroundColor Green
Write-Host "  ========================================" -ForegroundColor White
foreach ($t in $selectedTunnels) {
    Write-Host "  $($t.name): https://$($t.hostname)" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "  Commands:"
Write-Host "    tunnel-stop       Stop all tunnels"
Write-Host "    tunnel-list       Show tunnel status"
Write-Host "    type `"`$env:TEMP\tunnel-healthcheck.log`"  View health log"
Write-Host ""
