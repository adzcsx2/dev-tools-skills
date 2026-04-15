# ============================================================
# dev-tools-skills Installer for Windows PowerShell
# Usage:
#   .\install.ps1                    # Interactive mode
#   .\install.ps1 -All               # Install all plugins
#   .\install.ps1 dev-tools          # Install specific plugins
#   .\install.ps1 dev-tools android-dev-tools
#   .\install.ps1 -Uninstall         # Remove installed plugins
# ============================================================

param(
    [switch]$All,
    [switch]$Uninstall,
    [switch]$Help,
    [string[]]$Plugins = @()
)

$MarketplaceName = "dev-tools-skills"
$RepoUrl = "git@github.com:adzcsx2/dev-tools-skills.git"

# Resolve paths
$ClaudeDir = if ($env:CLAUDE_DIR) { $env:CLAUDE_DIR } else { Join-Path $env:USERPROFILE ".claude" }
$PluginsDir = Join-Path $ClaudeDir "plugins"
$CacheDir = Join-Path $PluginsDir "cache"
$MarketplaceDir = Join-Path $PluginsDir "marketplaces"
$SettingsFile = Join-Path $ClaudeDir "settings.json"
$KnownMktsFile = Join-Path $PluginsDir "known_marketplaces.json"
$InstalledFile = Join-Path $PluginsDir "installed_plugins.json"

# All available plugins
$AllPlugins = @("dev-tools", "android-dev-tools", "flutter-dev-tools")

# Plugin descriptions
$PluginDesc = @{
    "dev-tools"           = "Common tools (dt:push, dt:update-remote-plugins, dt:code-note)"
    "android-dev-tools"   = "Android tools (adt:init-android, adt:update-docs, etc.)"
    "flutter-dev-tools"   = "Flutter tools (fdt:init-flutter, fdt:update-docs)"
}

# ============================================================
# Helper Functions
# ============================================================

function Write-Info($msg)  { Write-Host "[INFO] $msg" -ForegroundColor Blue }
function Write-Ok($msg)    { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)   { Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Test-Command($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Get-PluginVersion($pluginName) {
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    if (-not $scriptDir) { $scriptDir = $PSScriptRoot }
    $pluginJson = Join-Path $scriptDir "plugins\$pluginName\.claude-plugin\plugin.json"

    if (Test-Path $pluginJson) {
        $json = Get-Content $pluginJson -Raw | ConvertFrom-Json
        return $json.version
    }
    return "0.0.0"
}

function Ensure-Directory($path) {
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

# ============================================================
# JSON operations
# ============================================================

function Read-JsonFile($path) {
    if (Test-Path $path) {
        return Get-Content $path -Raw | ConvertFrom-Json
    }
    return [PSCustomObject]@{}
}

function Write-JsonFile($path, $data) {
    $data | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding UTF8
}

# ============================================================
# Settings.json operations
# ============================================================

function Ensure-SettingsPlugin($pluginKey) {
    $settings = Read-JsonFile $SettingsFile

    if (-not $settings.PSObject.Properties["enabledPlugins"]) {
        $settings | Add-Member -NotePropertyName "enabledPlugins" -NotePropertyValue ([PSCustomObject]@{})
    }

    if (-not $settings.enabledPlugins.PSObject.Properties[$pluginKey]) {
        $settings.enabledPlugins | Add-Member -NotePropertyName $pluginKey -NotePropertyValue $true
    } else {
        $settings.enabledPlugins.$pluginKey = $true
    }

    Write-JsonFile $SettingsFile $settings
}

function Remove-SettingsPlugin($pluginKey) {
    if (-not (Test-Path $SettingsFile)) { return }

    $settings = Read-JsonFile $SettingsFile

    if ($settings.PSObject.Properties["enabledPlugins"] -and
        $settings.enabledPlugins.PSObject.Properties[$pluginKey]) {
        $settings.enabledPlugins.PSObject.Properties.Remove($pluginKey)
        Write-JsonFile $SettingsFile $settings
    }
}

# ============================================================
# known_marketplaces.json operations
# ============================================================

function Ensure-MarketplaceRegistration {
    Ensure-Directory $PluginsDir

    $mkts = Read-JsonFile $KnownMktsFile

    $installLocation = Join-Path $MarketplaceDir $MarketplaceName
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.000Z")

    $mkts | Add-Member -NotePropertyName $MarketplaceName -NotePropertyValue (
        [PSCustomObject]@{
            source = [PSCustomObject]@{
                source = "git"
                url    = $RepoUrl
            }
            installLocation = $installLocation
            lastUpdated     = $timestamp
        }
    ) -Force

    Write-JsonFile $KnownMktsFile $mkts
}

function Remove-MarketplaceRegistration {
    if (-not (Test-Path $KnownMktsFile)) { return }

    $mkts = Read-JsonFile $KnownMktsFile

    if ($mkts.PSObject.Properties[$MarketplaceName]) {
        $mkts.PSObject.Properties.Remove($MarketplaceName)
        Write-JsonFile $KnownMktsFile $mkts
    }
}

# ============================================================
# installed_plugins.json operations
# ============================================================

function Ensure-InstalledPlugin($pluginName, $version) {
    $pluginKey = "${MarketplaceName}@${pluginName}"
    $installPath = Join-Path $CacheDir "$MarketplaceName\$pluginName\$version"
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.000Z")

    if (-not (Test-Path $InstalledFile)) {
        @{
            version = 2
            plugins = @{}
        } | ConvertTo-Json -Depth 10 | Set-Content $InstalledFile -Encoding UTF8
    }

    $installed = Read-JsonFile $InstalledFile

    $entry = @(
        [PSCustomObject]@{
            scope       = "user"
            installPath = $installPath
            version     = $version
            installedAt = $timestamp
            lastUpdated = $timestamp
        }
    )

    if (-not $installed.PSObject.Properties["plugins"]) {
        $installed | Add-Member -NotePropertyName "plugins" -NotePropertyValue ([PSCustomObject]@{})
    }

    $installed.plugins | Add-Member -NotePropertyName $pluginKey -NotePropertyValue $entry -Force

    Write-JsonFile $InstalledFile $installed
}

function Remove-InstalledPlugin($pluginName) {
    if (-not (Test-Path $InstalledFile)) { return }

    $pluginKey = "${MarketplaceName}@${pluginName}"
    $installed = Read-JsonFile $InstalledFile

    if ($installed.PSObject.Properties["plugins"] -and
        $installed.plugins.PSObject.Properties[$pluginKey]) {
        $installed.plugins.PSObject.Properties.Remove($pluginKey)
        Write-JsonFile $InstalledFile $installed
    }
}

# ============================================================
# Core operations
# ============================================================

function Install-Plugin($pluginName) {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.ScriptName }
    $pluginSrc = Join-Path $scriptDir "plugins\$pluginName"
    $version = Get-PluginVersion $pluginName

    if (-not (Test-Path $pluginSrc)) {
        Write-Err "Plugin source not found: $pluginSrc"
        return $false
    }

    Write-Info "Installing $pluginName v${version}..."

    # Copy to cache
    $cacheDest = Join-Path $CacheDir "$MarketplaceName\$pluginName\$version"
    Ensure-Directory $cacheDest
    Copy-Item -Path "$pluginSrc\*" -Destination $cacheDest -Recurse -Force
    Write-Ok "Cached to $cacheDest"

    # Register
    $pluginKey = "${MarketplaceName}@${pluginName}"
    Ensure-SettingsPlugin $pluginKey
    Write-Ok "Enabled in settings.json"

    Ensure-InstalledPlugin $pluginName $version
    Write-Ok "Registered in installed_plugins.json"

    Write-Ok "$pluginName v${version} installed!"
    return $true
}

function Install-Marketplace {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.ScriptName }
    $target = Join-Path $MarketplaceDir $MarketplaceName

    Write-Info "Setting up marketplace: $MarketplaceName..."

    if (Test-Path (Join-Path $target ".git")) {
        Write-Info "Marketplace exists, pulling latest..."
        Push-Location $target
        git pull 2>$null
        Pop-Location
    } else {
        Write-Info "Cloning marketplace..."
        if (Test-Path $target) { Remove-Item $target -Recurse -Force }
        Ensure-Directory $MarketplaceDir

        try {
            git clone $RepoUrl $target 2>$null
        } catch {
            Write-Warn "Git clone failed, using local copy..."
            Ensure-Directory $target
            Copy-Item -Path "$scriptDir\*" -Destination $target -Recurse -Force
        }
    }
    Write-Ok "Marketplace ready at $target"

    Ensure-MarketplaceRegistration
    Write-Ok "Marketplace registered"
}

function Uninstall-All {
    Write-Info "Uninstalling $MarketplaceName plugins..."

    foreach ($pluginName in $AllPlugins) {
        $pluginKey = "${MarketplaceName}@${pluginName}"

        Remove-SettingsPlugin $pluginKey
        Remove-InstalledPlugin $pluginName

        $cachePath = Join-Path $CacheDir "$MarketplaceName\$pluginName"
        if (Test-Path $cachePath) {
            Remove-Item $cachePath -Recurse -Force
            Write-Info "Removed cache: $cachePath"
        }
    }

    Remove-MarketplaceRegistration

    $mktPath = Join-Path $MarketplaceDir $MarketplaceName
    if (Test-Path $mktPath) {
        Remove-Item $mktPath -Recurse -Force
        Write-Info "Removed marketplace: $mktPath"
    }

    Write-Ok "Uninstall complete!"
}

# ============================================================
# Interactive selection
# ============================================================

function Interactive-Select {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  dev-tools-skills Plugin Installer" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available plugins:"
    Write-Host ""

    for ($i = 0; $i -lt $AllPlugins.Count; $i++) {
        $name = $AllPlugins[$i]
        Write-Host "  [$($i+1)] $name" -ForegroundColor Green
        Write-Host "      $($PluginDesc[$name])"
        Write-Host ""
    }

    Write-Host "  [a] Install ALL plugins" -ForegroundColor Green
    Write-Host "  [q] Quit without installing" -ForegroundColor Green
    Write-Host ""

    $choice = Read-Host "Select plugins to install (e.g. 1 2 or a)"

    switch ($choice) {
        { $_ -match "^[qQ]$" } {
            Write-Info "Cancelled."
            exit 0
        }
        { $_ -match "^[aA](ll)?$" } {
            return $AllPlugins
        }
        default {
            $selected = @()
            foreach ($num in $choice.Split(" ")) {
                $idx = [int]$num - 1
                if ($idx -ge 0 -and $idx -lt $AllPlugins.Count) {
                    $selected += $AllPlugins[$idx]
                }
            }
            return $selected
        }
    }
}

# ============================================================
# Main
# ============================================================

function Main {
    Write-Host ""
    Write-Host "dev-tools-skills Installer" -ForegroundColor Cyan
    Write-Host ""

    # Check prerequisites
    if (-not (Test-Command "git")) {
        Write-Err "git is required but not installed."
        exit 1
    }

    # Handle help
    if ($Help) {
        Write-Host "Usage: .\install.ps1 [OPTIONS] [PLUGIN...]"
        Write-Host ""
        Write-Host "Options:"
        Write-Host "  -All              Install all plugins"
        Write-Host "  -Uninstall        Remove all installed plugins"
        Write-Host "  -Help             Show this help"
        Write-Host ""
        Write-Host "Plugins:"
        foreach ($p in $AllPlugins) {
            Write-Host "  $p  - $($PluginDesc[$p])"
        }
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  .\install.ps1                              # Interactive mode"
        Write-Host "  .\install.ps1 -All                         # Install everything"
        Write-Host "  .\install.ps1 dev-tools                    # Install common tools only"
        Write-Host "  .\install.ps1 dev-tools android-dev-tools  # Install common + Android tools"
        exit 0
    }

    # Handle uninstall
    if ($Uninstall) {
        Uninstall-All
        exit 0
    }

    # Determine selection
    $selected = @()

    if ($All) {
        $selected = $AllPlugins
    } elseif ($Plugins.Count -gt 0) {
        foreach ($p in $Plugins) {
            if ($AllPlugins -contains $p) {
                $selected += $p
            } else {
                Write-Warn "Unknown plugin: $p (skipping)"
            }
        }
    } else {
        $selected = Interactive-Select
    }

    if ($selected.Count -eq 0) {
        Write-Err "No plugins selected."
        exit 1
    }

    # Always include dev-tools
    if ($selected -notcontains "dev-tools") {
        Write-Warn "Auto-including 'dev-tools' (required for dt:update-remote-plugins)"
        $selected = ,("dev-tools") + $selected
    }

    Write-Host "Will install:" -ForegroundColor Blue
    foreach ($p in $selected) {
        Write-Host "  - $p" -ForegroundColor Green
    }
    Write-Host ""

    # Install marketplace
    Install-Marketplace

    # Install each plugin
    foreach ($pluginName in $selected) {
        Install-Plugin $pluginName
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Installation Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installed plugins:"
    foreach ($p in $selected) {
        Write-Host "  - $p ($($PluginDesc[$p]))" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "Please restart Claude Code to load the new plugins."
    Write-Host ""
}

Main
