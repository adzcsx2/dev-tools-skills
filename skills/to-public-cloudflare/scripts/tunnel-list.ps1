# Cloudflare Tunnel List
# Shows all registered tunnels with their status

$CF_DIR = Join-Path $env:USERPROFILE ".cloudflared"
$REGISTRY_FILE = Join-Path $CF_DIR "tunnel-registry.json"

if (-not (Test-Path $REGISTRY_FILE)) {
    Write-Host "No tunnel registry found. Run 'tunnel-add' to create a tunnel." -ForegroundColor Yellow
    exit 0
}

$reg = Get-Content $REGISTRY_FILE -Raw -Encoding UTF8 | ConvertFrom-Json
$domain = $reg.domain

Write-Host ""
Write-Host "  Cloudflare Tunnels ($domain)" -ForegroundColor Cyan
Write-Host "  ================================" -ForegroundColor Cyan
Write-Host ""

$tunnels = $reg.tunnels
if (-not $tunnels -or $tunnels.Count -eq 0) {
    Write-Host "  No tunnels registered. Run 'tunnel-add' to create one." -ForegroundColor Yellow
    exit 0
}

# Header
Write-Host ("  {0,-18} {1,-35} {2,-7} {3,-10} {4,-12}" -f "Name", "Hostname", "Port", "Process", "Health") -ForegroundColor White
Write-Host ("  {0,-18} {1,-35} {2,-7} {3,-10} {4,-12}" -f "----", "--------", "----", "-------", "------")

foreach ($t in $tunnels) {
    $configPath = Join-Path $CF_DIR $t.config_file

    # Check process
    $procInfo = Get-CimInstance Win32_Process -Filter "name='cloudflared.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*$configPath*" } |
        Select-Object -First 1
    $processStatus = if ($procInfo) { "running" } else { "stopped" }

    # Check health (quick 5s timeout)
    $healthStatus = "unknown"
    if ($procInfo) {
        try {
            $null = Invoke-WebRequest -Uri "https://$($t.hostname)/" -TimeoutSec 5 -UseBasicParsing
            $healthStatus = "ok"
        } catch {
            if ($_.Exception.Response) {
                $healthStatus = "ok"
            } else {
                $healthStatus = "unreachable"
            }
        }
    }

    # Color coding
    $procColor = if ($processStatus -eq "running") { "Green" } else { "Red" }
    $healthColor = switch ($healthStatus) {
        "ok"         { "Green" }
        "unreachable" { "Red" }
        default      { "DarkGray" }
    }

    Write-Host -NoNewline ("  {0,-18} " -f $t.name)
    Write-Host -NoNewline ("{0,-35} " -f $t.hostname)
    Write-Host -NoNewline ("{0,-7} " -f $t.port)
    Write-Host -NoNewline ("$processStatus" -f "")
    Write-Host -NoNewline ("{0,-10} " -f "")
    Write-Host -NoNewline ("$healthStatus" -f "")

    # Manual color output
    $namePad = $t.name.PadRight(18)
    $hostPad = $t.hostname.PadRight(35)
    $portPad = "$($t.port)".PadRight(7)

    # Overwrite with colors
    $cursorTop = [Console]::CursorTop - 1
    [Console]::SetCursorPosition(2, $cursorTop)
    Write-Host "$namePad " -NoNewline -ForegroundColor White
    Write-Host "$hostPad " -NoNewline -ForegroundColor Cyan
    Write-Host "$portPad " -NoNewline -ForegroundColor White
    $procPad = $processStatus.PadRight(10)
    Write-Host "$procPad " -NoNewline -ForegroundColor $procColor
    Write-Host $healthStatus -ForegroundColor $healthColor
}

Write-Host ""
