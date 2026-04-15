# ============================================================
# dev-tools-skills Installer for Windows PowerShell
# Usage:
#   .\install.ps1                    # Interactive mode
#   .\install.ps1 -All               # Install all skills
#   .\install.ps1 common             # Common tools only
#   .\install.ps1 common android     # Common + Android tools
#   .\install.ps1 -Uninstall         # Remove installed plugin
# ============================================================

param(
    [switch]$All,
    [switch]$Uninstall,
    [switch]$Help,
    [string[]]$Categories = @()
)

$MarketplaceName = "dev-tools-skills"
$PluginName = "dev-tools-skills"
$RepoUrl = "git@github.com:adzcsx2/dev-tools-skills.git"
$Version = "1.0.0"

# Paths
$ClaudeDir = if ($env:CLAUDE_DIR) { $env:CLAUDE_DIR } else { Join-Path $env:USERPROFILE ".claude" }
$PluginsDir = Join-Path $ClaudeDir "plugins"
$CacheDir = Join-Path $PluginsDir "cache"
$MarketplaceDir = Join-Path $PluginsDir "marketplaces"
$SettingsFile = Join-Path $ClaudeDir "settings.json"
$KnownMktsFile = Join-Path $PluginsDir "known_marketplaces.json"
$InstalledFile = Join-Path $PluginsDir "installed_plugins.json"
$PluginKey = "${MarketplaceName}@${PluginName}"

# Skill categories
$CommonSkills = @("push", "update-remote-plugins", "code-note")
$AndroidSkills = @("init-android", "gradle-build-performance", "update-docs-android", "android-i18n", "android-fold-adapter", "auto-ui-test")
$FlutterSkills = @("init-flutter", "update-docs-flutter")

$AllCategories = @("common", "android", "flutter")

# ============================================================
# Helpers
# ============================================================

function Write-Info($msg)  { Write-Host "[INFO] $msg" -ForegroundColor Blue }
function Write-Ok($msg)    { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)   { Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Test-Command($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Get-CategoryDesc($cat) {
    switch ($cat) {
        "common"  { "Common tools (dt:push, dt:update-remote-plugins, dt:code-note)" }
        "android" { "Android tools (adt:init-android, adt:update-docs, adt:gradle-build-performance, etc.)" }
        "flutter" { "Flutter tools (fdt:init-flutter, fdt:update-docs)" }
    }
}

function Get-SkillsForCategory($cat) {
    switch ($cat) {
        "common"  { $CommonSkills }
        "android" { $AndroidSkills }
        "flutter" { $FlutterSkills }
    }
}

function Ensure-Directory($path) {
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

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
# Config operations
# ============================================================

function Ensure-SettingsPlugin {
    $settings = Read-JsonFile $SettingsFile
    if (-not $settings.PSObject.Properties["enabledPlugins"]) {
        $settings | Add-Member -NotePropertyName "enabledPlugins" -NotePropertyValue ([PSCustomObject]@{})
    }
    if (-not $settings.enabledPlugins.PSObject.Properties[$PluginKey]) {
        $settings.enabledPlugins | Add-Member -NotePropertyName $PluginKey -NotePropertyValue $true
    } else {
        $settings.enabledPlugins.$PluginKey = $true
    }
    Write-JsonFile $SettingsFile $settings
}

function Remove-SettingsPlugin {
    if (-not (Test-Path $SettingsFile)) { return }
    $settings = Read-JsonFile $SettingsFile
    if ($settings.PSObject.Properties["enabledPlugins"] -and
        $settings.enabledPlugins.PSObject.Properties[$PluginKey]) {
        $settings.enabledPlugins.PSObject.Properties.Remove($PluginKey)
        Write-JsonFile $SettingsFile $settings
    }
}

function Ensure-MarketplaceRegistration {
    Ensure-Directory $PluginsDir
    $mkts = Read-JsonFile $KnownMktsFile
    $installLocation = Join-Path $MarketplaceDir $MarketplaceName
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.000Z")

    $mkts | Add-Member -NotePropertyName $MarketplaceName -NotePropertyValue (
        [PSCustomObject]@{
            source = [PSCustomObject]@{ source = "git"; url = $RepoUrl }
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

function Ensure-InstalledPlugin {
    $installPath = Join-Path $CacheDir "$MarketplaceName\$PluginName\$Version"
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.000Z")

    if (-not (Test-Path $InstalledFile)) {
        @{ version = 2; plugins = @{} } | ConvertTo-Json -Depth 10 | Set-Content $InstalledFile -Encoding UTF8
    }
    $installed = Read-JsonFile $InstalledFile

    $entry = @(
        [PSCustomObject]@{
            scope       = "user"
            installPath = $installPath
            version     = $Version
            installedAt = $timestamp
            lastUpdated = $timestamp
        }
    )

    if (-not $installed.PSObject.Properties["plugins"]) {
        $installed | Add-Member -NotePropertyName "plugins" -NotePropertyValue ([PSCustomObject]@{})
    }
    $installed.plugins | Add-Member -NotePropertyName $PluginKey -NotePropertyValue $entry -Force
    Write-JsonFile $InstalledFile $installed
}

function Remove-InstalledPlugin {
    if (-not (Test-Path $InstalledFile)) { return }
    $installed = Read-JsonFile $InstalledFile
    if ($installed.PSObject.Properties["plugins"] -and
        $installed.plugins.PSObject.Properties[$PluginKey]) {
        $installed.plugins.PSObject.Properties.Remove($PluginKey)
        Write-JsonFile $InstalledFile $installed
    }
}

# ============================================================
# Core operations
# ============================================================

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

function Install-Skills {
    param([string[]]$Skills)

    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.ScriptName }
    $cacheDest = Join-Path $CacheDir "$MarketplaceName\$PluginName\$Version"

    Write-Info "Installing skills to cache..."

    Ensure-Directory "$cacheDest\skills"
    Ensure-Directory "$cacheDest\.claude-plugin"

    # Copy plugin.json
    $pluginJson = Join-Path $scriptDir ".claude-plugin\plugin.json"
    if (Test-Path $pluginJson) {
        Copy-Item $pluginJson "$cacheDest\.claude-plugin\" -Force
    }

    # Copy selected skills
    foreach ($skill in $Skills) {
        $src = Join-Path $scriptDir "skills\$skill"
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination "$cacheDest\skills\" -Recurse -Force
            Write-Ok "Copied skill: $skill"
        } else {
            Write-Warn "Skill not found: $skill (skipping)"
        }
    }

    # Register
    Ensure-SettingsPlugin
    Write-Ok "Enabled in settings.json"

    Ensure-InstalledPlugin
    Write-Ok "Registered in installed_plugins.json"
}

function Uninstall-All {
    Write-Info "Uninstalling $MarketplaceName..."

    Remove-SettingsPlugin
    Remove-InstalledPlugin
    Remove-MarketplaceRegistration

    $cachePath = Join-Path $CacheDir $MarketplaceName
    if (Test-Path $cachePath) {
        Remove-Item $cachePath -Recurse -Force
        Write-Info "Removed cache: $cachePath"
    }

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
    Write-Host "  dev-tools-skills Installer" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select skill categories to install:"
    Write-Host ""
    Write-Host "  [1] common  - $(Get-CategoryDesc 'common')" -ForegroundColor Green
    Write-Host "  [2] android - $(Get-CategoryDesc 'android')" -ForegroundColor Green
    Write-Host "  [3] flutter - $(Get-CategoryDesc 'flutter')" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [a] Install ALL" -ForegroundColor Green
    Write-Host "  [q] Quit" -ForegroundColor Green
    Write-Host ""

    $choice = Read-Host "Select (e.g. 1 2 or a)"

    switch ($choice) {
        { $_ -match "^[qQ]$" } { Write-Info "Cancelled."; exit 0 }
        { $_ -match "^[aA]" }  { return @("common", "android", "flutter") }
        default {
            $selected = @("common")
            foreach ($num in $choice.Split(" ")) {
                switch ($num) {
                    "1" { $selected = @("common") }
                    "2" { $selected += "android" }
                    "3" { $selected += "flutter" }
                }
            }
            return $selected | Select-Object -Unique
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

    if (-not (Test-Command "git")) {
        Write-Err "git is required but not installed."
        exit 1
    }

    if ($Help) {
        Write-Host "Usage: .\install.ps1 [OPTIONS] [CATEGORY...]"
        Write-Host ""
        Write-Host "Options:"
        Write-Host "  -All              Install all skill categories"
        Write-Host "  -Uninstall        Remove installed plugin"
        Write-Host "  -Help             Show this help"
        Write-Host ""
        Write-Host "Categories:"
        Write-Host "  common   - $(Get-CategoryDesc 'common')"
        Write-Host "  android  - $(Get-CategoryDesc 'android')"
        Write-Host "  flutter  - $(Get-CategoryDesc 'flutter')"
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  .\install.ps1                    # Interactive mode"
        Write-Host "  .\install.ps1 -All               # Install everything"
        Write-Host "  .\install.ps1 common             # Common tools only"
        Write-Host "  .\install.ps1 common android     # Common + Android tools"
        exit 0
    }

    if ($Uninstall) {
        Uninstall-All
        exit 0
    }

    # Determine categories
    $selectedCats = @()

    if ($All) {
        $selectedCats = @("common", "android", "flutter")
    } elseif ($Categories.Count -gt 0) {
        foreach ($c in $Categories) {
            if ($AllCategories -contains $c) {
                $selectedCats += $c
            } else {
                Write-Warn "Unknown category: $c (skipping)"
            }
        }
        if ($selectedCats -notcontains "common") {
            Write-Warn "Auto-including 'common'"
            $selectedCats = ,("common") + $selectedCats
        }
    } else {
        $selectedCats = Interactive-Select
    }

    # Collect skills
    $allSkills = @()
    foreach ($cat in $selectedCats) {
        $allSkills += Get-SkillsForCategory $cat
    }
    $allSkills = $allSkills | Select-Object -Unique

    Write-Host "Will install:" -ForegroundColor Blue
    foreach ($cat in $selectedCats) {
        Write-Host "  - $cat : $(Get-CategoryDesc $cat)" -ForegroundColor Green
    }
    Write-Host ""

    # Install
    Install-Marketplace
    Install-Skills $allSkills

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Installation Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installed skills:"
    foreach ($skill in $allSkills) {
        Write-Host "  - $skill" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "Please restart Claude Code to load the new skills."
    Write-Host ""
}

Main
