param()

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.ScriptName }
$InstallScript = Join-Path $ScriptDir "install.ps1"

if (-not (Test-Path $InstallScript -PathType Leaf)) {
    Write-Host "[ERROR] install.ps1 not found: $InstallScript" -ForegroundColor Red
    exit 1
}

& $InstallScript -Uninstall