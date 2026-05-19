# ============================================================
# dev-tools-skills Installer for Windows PowerShell
# ============================================================

param(
    [switch]$All,
    [switch]$Uninstall,
    [switch]$Help,
    [string[]]$Categories = @()
)

$MarketplaceName = "dev-tools-skills"
$RepoUrl = "git@github.com:adzcsx2/dev-tools-skills.git"
$VSCodePromptsDir = if ($env:VSCODE_USER_PROMPTS_FOLDER) { $env:VSCODE_USER_PROMPTS_FOLDER } else { Join-Path $env:APPDATA "Code\User\prompts" }
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.ScriptName }
$PluginJson = Join-Path $ScriptDir ".claude-plugin\plugin.json"

$ClaudeDir = if ($env:CLAUDE_DIR) { $env:CLAUDE_DIR } else { Join-Path $env:USERPROFILE ".claude" }
$PluginsDir = Join-Path $ClaudeDir "plugins"
$CacheDir = Join-Path $PluginsDir "cache"
$MarketplaceDir = Join-Path $PluginsDir "marketplaces"
$SettingsFile = Join-Path $ClaudeDir "settings.json"
$KnownMktsFile = Join-Path $PluginsDir "known_marketplaces.json"
$InstalledFile = Join-Path $PluginsDir "installed_plugins.json"

$PluginName = ""
$Version = ""
$PluginKey = ""

$CommonSkills = @("init", "study", "push", "update-remote-plugins", "code-note", "to-public-cloudflare", "plan-doc", "project-skills")
$AndroidSkills = @("gradle-build-performance", "update-docs-android", "android-i18n", "android-fold-adapter", "auto-ui-test")
$FlutterSkills = @("update-docs-flutter")
$AllCategories = @("common", "android", "flutter")

function Write-Info($msg)  { Write-Host "[INFO] $msg" -ForegroundColor Blue }
function Write-Ok($msg)    { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)   { Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Test-Command($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Get-CategoryDesc($cat) {
    switch ($cat) {
        "common"  { "Common tools (dt:init, dt:study, dt:push, dt:update-remote-plugins, dt:code-note, dt:to-public-cloudflare, dt:plan-doc, dt:project-skills)" }
        "android" { "Android tools (adt:gradle-build-performance, adt:update-docs, adt:android-i18n, adt:android-fold-adapter, adt:auto-ui-test)" }
        "flutter" { "Flutter tools (fdt:update-docs)" }
        default    { "" }
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

function Require-File($path) {
    if (-not (Test-Path $path -PathType Leaf)) {
        Write-Err "Required file not found: $path"
        exit 1
    }
}

function Assert-PathInClaudeDir($path) {
    $resolvedClaude = [System.IO.Path]::GetFullPath($ClaudeDir)
    $resolvedPath = [System.IO.Path]::GetFullPath($path)
    if ($resolvedPath -ne $resolvedClaude -and -not $resolvedPath.StartsWith($resolvedClaude + [System.IO.Path]::DirectorySeparatorChar)) {
        Write-Err "Refusing to operate outside CLAUDE_DIR: $path"
        exit 1
    }
}

function Remove-PathIfExists($path) {
    if (Test-Path $path) {
        Assert-PathInClaudeDir $path
        Remove-Item $path -Recurse -Force
        Write-Info "Removed: $path"
    }
}

function Load-PluginMetadata {
    Require-File $PluginJson
    $plugin = Get-Content $PluginJson -Raw | ConvertFrom-Json

    if (-not $plugin.name -or -not $plugin.version) {
        Write-Err "Failed to read plugin metadata from $PluginJson"
        exit 1
    }

    $script:PluginName = $plugin.name
    $script:Version = $plugin.version
    $script:PluginKey = "${MarketplaceName}@${PluginName}"
}

function Ensure-ClaudeLayout {
    Ensure-Directory $ClaudeDir
    Ensure-Directory $PluginsDir
    Ensure-Directory $CacheDir
    Ensure-Directory $MarketplaceDir
}

function Install-VSCodePrompt {
    $promptsDir = Join-Path $ScriptDir ".github\prompts"
    if (-not (Test-Path $promptsDir -PathType Container)) {
        Write-Warn "VS Code Copilot prompts directory not found: $promptsDir"
        return
    }

    Ensure-Directory $VSCodePromptsDir
    $promptFiles = Get-ChildItem -Path $promptsDir -Filter '*.prompt.md' -File -ErrorAction SilentlyContinue
    if (-not $promptFiles) {
        Write-Warn "No VS Code Copilot prompt files found in: $promptsDir"
        return
    }

    foreach ($promptFile in $promptFiles) {
        $targetPath = Join-Path $VSCodePromptsDir $promptFile.Name
        Copy-Item $promptFile.FullName $targetPath -Force
        Write-Ok "Installed VS Code Copilot prompt: $targetPath"
    }
}

function Remove-VSCodePrompt {
    $promptsDir = Join-Path $ScriptDir ".github\prompts"
    if (-not (Test-Path $promptsDir -PathType Container)) { return }

    $promptFiles = Get-ChildItem -Path $promptsDir -Filter '*.prompt.md' -File -ErrorAction SilentlyContinue
    foreach ($promptFile in $promptFiles) {
        $promptPath = Join-Path $VSCodePromptsDir $promptFile.Name
        if (Test-Path $promptPath) {
            Remove-Item $promptPath -Force
            Write-Info "Removed: $promptPath"
        }
    }
}

function Read-JsonFile($path, $defaultJson) {
    if (Test-Path $path) {
        return Get-Content $path -Raw | ConvertFrom-Json
    }
    return $defaultJson | ConvertFrom-Json
}

function Write-JsonFile($path, $data) {
    $json = $data | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($path, $json, [System.Text.UTF8Encoding]::new($false))
}

function Ensure-SettingsPlugin {
    Ensure-Directory $ClaudeDir
    $settings = Read-JsonFile $SettingsFile '{}'
    if (-not $settings.PSObject.Properties['enabledPlugins']) {
        $settings | Add-Member -NotePropertyName 'enabledPlugins' -NotePropertyValue ([PSCustomObject]@{})
    }
    $settings.enabledPlugins | Add-Member -NotePropertyName $PluginKey -NotePropertyValue $true -Force
    Write-JsonFile $SettingsFile $settings
}

function Remove-SettingsPlugin {
    if (-not (Test-Path $SettingsFile)) { return }
    $settings = Read-JsonFile $SettingsFile '{}'
    if ($settings.PSObject.Properties['enabledPlugins'] -and $settings.enabledPlugins.PSObject.Properties[$PluginKey]) {
        $settings.enabledPlugins.PSObject.Properties.Remove($PluginKey)
        Write-JsonFile $SettingsFile $settings
    }
}

function Ensure-MarketplaceRegistration {
    Ensure-Directory $PluginsDir
    $mkts = Read-JsonFile $KnownMktsFile '{}'
    $installLocation = Join-Path $MarketplaceDir $MarketplaceName
    $timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.000Z')

    $mkts | Add-Member -NotePropertyName $MarketplaceName -NotePropertyValue (
        [PSCustomObject]@{
            source = [PSCustomObject]@{ source = 'git'; url = $RepoUrl }
            installLocation = $installLocation
            lastUpdated = $timestamp
        }
    ) -Force
    Write-JsonFile $KnownMktsFile $mkts
}

function Remove-MarketplaceRegistration {
    if (-not (Test-Path $KnownMktsFile)) { return }
    $mkts = Read-JsonFile $KnownMktsFile '{}'
    if ($mkts.PSObject.Properties[$MarketplaceName]) {
        $mkts.PSObject.Properties.Remove($MarketplaceName)
        Write-JsonFile $KnownMktsFile $mkts
    }
}

function Ensure-InstalledPlugin {
    Ensure-Directory $PluginsDir
    $installPath = Join-Path $CacheDir "$MarketplaceName\$PluginName\$Version"
    $timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.000Z')
    $installed = Read-JsonFile $InstalledFile '{"version":2,"plugins":{}}'

    if (-not $installed.PSObject.Properties['plugins']) {
        $installed | Add-Member -NotePropertyName 'plugins' -NotePropertyValue ([PSCustomObject]@{})
    }

    $entry = @(
        [PSCustomObject]@{
            scope = 'user'
            installPath = $installPath
            version = $Version
            installedAt = $timestamp
            lastUpdated = $timestamp
        }
    )

    $installed.plugins | Add-Member -NotePropertyName $PluginKey -NotePropertyValue $entry -Force
    Write-JsonFile $InstalledFile $installed
}

function Remove-InstalledPlugin {
    if (-not (Test-Path $InstalledFile)) { return }
    $installed = Read-JsonFile $InstalledFile '{"version":2,"plugins":{}}'
    if ($installed.PSObject.Properties['plugins'] -and $installed.plugins.PSObject.Properties[$PluginKey]) {
        $installed.plugins.PSObject.Properties.Remove($PluginKey)
        Write-JsonFile $InstalledFile $installed
    }
}

function Reset-ExistingInstallation {
    Write-Info "Resetting existing plugin state under $ClaudeDir..."
    Remove-SettingsPlugin
    Remove-InstalledPlugin
    Remove-MarketplaceRegistration
    Remove-VSCodePrompt
    Remove-PathIfExists (Join-Path $CacheDir "$MarketplaceName\$PluginName")
    Remove-PathIfExists (Join-Path $MarketplaceDir $MarketplaceName)
}

function Copy-WorkspaceSnapshot {
    param([string]$Target)

    Ensure-Directory $Target
    Copy-Item -Path (Join-Path $ScriptDir 'skills') -Destination $Target -Recurse -Force
    Copy-Item -Path (Join-Path $ScriptDir '.claude-plugin') -Destination $Target -Recurse -Force
    if (Test-Path (Join-Path $ScriptDir '.github')) {
        Copy-Item -Path (Join-Path $ScriptDir '.github') -Destination $Target -Recurse -Force
    }

    foreach ($file in @('README.md', 'README_EN.md', 'CLAUDE.md', 'LICENSE', 'install.sh', 'install.ps1', 'uninstall.sh', 'uninstall.ps1')) {
        $source = Join-Path $ScriptDir $file
        if (Test-Path $source) {
            Copy-Item -Path $source -Destination $Target -Force
        }
    }
}

function Install-Marketplace {
    $target = Join-Path $MarketplaceDir $MarketplaceName
    Write-Info "Setting up marketplace: $MarketplaceName..."

    Ensure-Directory $MarketplaceDir
    Remove-PathIfExists $target

    try {
        git clone $RepoUrl $target 2>$null
        Write-Ok 'Cloned marketplace from remote'
    } catch {
        Write-Warn 'Git clone failed, using local workspace snapshot...'
        Copy-WorkspaceSnapshot -Target $target
    }

    Ensure-MarketplaceRegistration
    Write-Ok "Marketplace ready at $target"
}

function Install-Skills {
    param([string[]]$Skills)

    $cacheDest = Join-Path $CacheDir "$MarketplaceName\$PluginName\$Version"
    Write-Info 'Installing skills to cache...'

    Ensure-Directory (Join-Path $cacheDest 'skills')
    Ensure-Directory (Join-Path $cacheDest '.claude-plugin')
    Copy-Item $PluginJson (Join-Path $cacheDest '.claude-plugin\plugin.json') -Force

    foreach ($skill in $Skills) {
        $src = Join-Path $ScriptDir "skills\$skill"
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination (Join-Path $cacheDest 'skills') -Recurse -Force
            Write-Ok "Copied skill: $skill"
        } else {
            Write-Warn "Skill not found: $skill (skipping)"
        }
    }

    # Install tunnel management scripts from to-public-cloudflare skill
    Install-TunnelScripts -CacheDest $cacheDest

    Ensure-SettingsPlugin
    Ensure-InstalledPlugin
    Write-Ok "Plugin registered with latest version: $Version"
}

function Install-TunnelScripts {
    param([string]$CacheDest)

    $scriptsSrc = Join-Path $CacheDest 'skills\to-public-cloudflare\scripts'
    if (-not (Test-Path $scriptsSrc)) { return }

    $binDir = Join-Path $env:USERPROFILE 'bin'
    Ensure-Directory $binDir

    Write-Info 'Installing tunnel management scripts to ~/bin/...'

    $scripts = Get-ChildItem -Path $scriptsSrc -Filter '*.ps1' -File -ErrorAction SilentlyContinue
    $scripts += Get-ChildItem -Path $scriptsSrc -Filter '*.sh' -File -ErrorAction SilentlyContinue

    foreach ($script in $scripts) {
        $dest = Join-Path $binDir $script.Name
        Copy-Item $script.FullName $dest -Force
        Write-Ok "Installed: ~/bin/$($script.Name)"
    }
}

function Uninstall-All {
    Write-Info "Uninstalling $MarketplaceName..."
    Reset-ExistingInstallation
    Write-Ok 'Uninstall complete!'
}

function Interactive-Select {
    Write-Host ''
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host '  dev-tools-skills Installer' -ForegroundColor Cyan
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Select skill categories to install:'
    Write-Host ''
    Write-Host "  [1] common  - $(Get-CategoryDesc 'common')" -ForegroundColor Green
    Write-Host "  [2] android - $(Get-CategoryDesc 'android')" -ForegroundColor Green
    Write-Host "  [3] flutter - $(Get-CategoryDesc 'flutter')" -ForegroundColor Green
    Write-Host ''
    Write-Host '  [a] Install ALL' -ForegroundColor Green
    Write-Host '  [q] Quit' -ForegroundColor Green
    Write-Host ''

    $choice = Read-Host 'Select (e.g. 1 2 or a)'

    switch ($choice) {
        { $_ -match '^[qQ]$' } { Write-Info 'Cancelled.'; exit 0 }
        { $_ -match '^[aA]$' } { return @('common', 'android', 'flutter') }
        default {
            $selected = @('common')
            foreach ($num in $choice.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)) {
                switch ($num) {
                    '1' { $selected = @('common') }
                    '2' { $selected += 'android' }
                    '3' { $selected += 'flutter' }
                }
            }
            return $selected | Select-Object -Unique
        }
    }
}

function Main {
    Write-Host ''
    Write-Host 'dev-tools-skills Installer' -ForegroundColor Cyan
    Write-Host ''

    if (-not (Test-Command 'git')) {
        Write-Err 'git is required but not installed.'
        exit 1
    }

    Load-PluginMetadata
    Ensure-ClaudeLayout

    if ($Help) {
        Write-Host 'Usage: .\install.ps1 [OPTIONS] [CATEGORY...]'
        Write-Host ''
        Write-Host 'Options:'
        Write-Host '  -All              Install all skill categories'
        Write-Host '  -Uninstall        Remove installed plugin'
        Write-Host '  -Help             Show this help'
        Write-Host ''
        Write-Host 'Categories:'
        Write-Host "  common   - $(Get-CategoryDesc 'common')"
        Write-Host "  android  - $(Get-CategoryDesc 'android')"
        Write-Host "  flutter  - $(Get-CategoryDesc 'flutter')"
        exit 0
    }

    if ($Uninstall) {
        Uninstall-All
        exit 0
    }

    $selectedCats = @()
    if ($All) {
        $selectedCats = @('common', 'android', 'flutter')
    } elseif ($Categories.Count -gt 0) {
        foreach ($category in $Categories) {
            if ($AllCategories -contains $category) {
                $selectedCats += $category
            } else {
                Write-Warn "Unknown category: $category (skipping)"
            }
        }
        if ($selectedCats -notcontains 'common') {
            $selectedCats = ,('common') + $selectedCats
        }
        $selectedCats = $selectedCats | Select-Object -Unique
    } else {
        $selectedCats = Interactive-Select
    }

    $allSkills = @()
    foreach ($category in $selectedCats) {
        $allSkills += Get-SkillsForCategory $category
    }
    $allSkills = $allSkills | Select-Object -Unique

    Write-Host 'Will install:' -ForegroundColor Blue
    foreach ($category in $selectedCats) {
        Write-Host "  - $category : $(Get-CategoryDesc $category)" -ForegroundColor Green
    }
    Write-Host ''

    Reset-ExistingInstallation
    Ensure-ClaudeLayout
    Install-Marketplace
    Install-Skills $allSkills
    Install-VSCodePrompt

    Write-Host '========================================' -ForegroundColor Green
    Write-Host '  Installation Complete!' -ForegroundColor Green
    Write-Host '========================================' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Installed skills:'
    foreach ($skill in $allSkills) {
        Write-Host "  - $skill" -ForegroundColor Green
    }
    Write-Host ''
    Write-Host 'Please restart Claude Code and reload VS Code Copilot chat to load the new commands.'
}

Main