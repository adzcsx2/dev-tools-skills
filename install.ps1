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
$CodexDir = if ($env:CODEX_DIR) { $env:CODEX_DIR } else { Join-Path $env:USERPROFILE ".codex" }
$CodexScriptsDir = Join-Path $CodexDir "scripts"
$CodexSyncScriptName = "sync-dev-tools-skills-to-codex.js"
$CodexSyncSource = Join-Path $ScriptDir "scripts\$CodexSyncScriptName"
$CodexSyncTarget = Join-Path $CodexScriptsDir $CodexSyncScriptName

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

$CommonSkills = @("init", "init-root", "study", "push", "update-remote-plugins", "code-note", "to-public-cloudflare", "project-skills", "work-report", "local-worktree", "update-docs")
$AndroidSkills = @("gradle-build-performance", "android-i18n", "android-fold-adapter", "android-e2e")
$FlutterSkills = @()
$AllCategories = @("common", "android", "flutter")

function Write-Info($msg)  { Write-Host "[INFO] $msg" -ForegroundColor Blue }
function Write-Ok($msg)    { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)   { Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Test-Command($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Detect-Tools {
    $script:HAS_CLAUDE = $false
    $script:HAS_COPILOT = $false
    $script:HAS_CODEX = $false
    if (Test-Path (Join-Path $env:USERPROFILE ".claude")) {
        $script:HAS_CLAUDE = $true
    }
    if (Test-Path $VSCodePromptsDir) {
        $script:HAS_COPILOT = $true
    }
    if ((Test-Path $CodexDir) -or (Test-Command 'codex')) {
        $script:HAS_CODEX = $true
    }
}

function Select-Tools {
    Detect-Tools

    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host '  Select Target Tools' -ForegroundColor Cyan
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Select tools to install to:'
    Write-Host ''

    $claudeStatus = '(未安装)'
    $copilotStatus = '(未安装)'
    $codexStatus = '(未安装)'
    if ($HAS_CLAUDE) { $claudeStatus = '(已安装)' }
    if ($HAS_COPILOT) { $copilotStatus = '(已安装)' }
    if ($HAS_CODEX) { $codexStatus = '(已安装)' }

    Write-Host "  [1] Claude Code       $claudeStatus" -ForegroundColor Green
    Write-Host "  [2] VS Code Copilot   $copilotStatus" -ForegroundColor Green
    Write-Host "  [3] Codex             $codexStatus" -ForegroundColor Green
    Write-Host '  [a] All (自动检测已有工具)' -ForegroundColor Green
    Write-Host ''

    $choice = Read-Host 'Select'

    switch ($choice) {
        '1' {
            if (-not $HAS_CLAUDE) {
                Write-Err 'Claude Code 未安装，无法选择此选项'
                exit 1
            }
            $script:INSTALL_CLAUDE = $true
            $script:INSTALL_COPILOT = $false
            $script:INSTALL_CODEX = $false
        }
        '2' {
            if (-not $HAS_COPILOT) {
                Write-Err 'VS Code Copilot 未安装，无法选择此选项'
                exit 1
            }
            $script:INSTALL_CLAUDE = $false
            $script:INSTALL_COPILOT = $true
            $script:INSTALL_CODEX = $false
        }
        '3' {
            if (-not $HAS_CODEX) {
                Write-Err 'Codex 未安装，无法选择此选项'
                exit 1
            }
            $script:INSTALL_CLAUDE = $false
            $script:INSTALL_COPILOT = $false
            $script:INSTALL_CODEX = $true
        }
        { $_ -match '^[aA]$' } {
            $script:INSTALL_CLAUDE = $HAS_CLAUDE
            $script:INSTALL_COPILOT = $HAS_COPILOT
            $script:INSTALL_CODEX = $HAS_CODEX
            if (-not $INSTALL_CLAUDE -and -not $INSTALL_COPILOT -and -not $INSTALL_CODEX) {
                Write-Err '未检测到 Claude Code、VS Code Copilot 和 Codex，无法安装'
                exit 1
            }
        }
        default {
            Write-Err "无效选择: $choice"
            exit 1
        }
    }

    Write-Host ''
    if ($INSTALL_CLAUDE) { Write-Info '将安装到 Claude Code' }
    if ($INSTALL_COPILOT) { Write-Info '将安装到 VS Code Copilot' }
    if ($INSTALL_CODEX) { Write-Info '将同步到 Codex' }
    Write-Host ''
}

function Get-CategoryDesc($cat) {
    switch ($cat) {
        "common"  { "Common tools (dt:init, dt:init-root, dt:study, dt:push, dt:update-remote-plugins, dt:code-note, dt:to-public-cloudflare, dt:project-skills, dt:work-report, dt:update-docs)" }
        "android" { "Android tools (adt:gradle-build-performance, adt:android-i18n, adt:android-fold-adapter, adt:android-e2e)" }
        "flutter" { "Flutter tools (merged into dt:update-docs)" }
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

# Read the `name` field from a SKILL.md YAML frontmatter (handles quoted/unquoted)
function Get-SkillName($mdFile) {
    $inFrontmatter = $false
    $fenceCount = 0
    $lineNo = 0
    foreach ($line in Get-Content $mdFile) {
        $lineNo++
        if ($lineNo -eq 1) { $line = $line -replace '^\uFEFF', '' }
        if ($line -match '^---\s*$') {
            $fenceCount++
            if ($fenceCount -eq 1) { $inFrontmatter = $true; continue }
            if ($fenceCount -ge 2) { break }
        }
        if ($inFrontmatter -and $line -match '^name:\s*(.+?)\s*$') {
            return $matches[1].Trim('"', "'")
        }
    }
    return $null
}

# Convert a skill name (e.g. dt:push) into a cross-platform-safe Copilot command
# name (e.g. dt-push). Colons are illegal in Windows file names, so the slash
# command becomes /dt-push on every platform.
function Get-PromptCommandName($skillName) {
    return $skillName -replace ':', '-'
}

# Build the set of prompt file names this installer would generate (one per skill)
function Get-ExpectedPromptFiles {
    $expected = @{}
    $skillDirs = Get-ChildItem -Path (Join-Path $ScriptDir 'skills') -Directory -ErrorAction SilentlyContinue
    foreach ($skillDir in $skillDirs) {
        $mdFile = Join-Path $skillDir.FullName 'SKILL.md'
        if (-not (Test-Path $mdFile)) { continue }
        $cmdName = Get-SkillName $mdFile
        if (-not $cmdName) { continue }
        $expected["$(Get-PromptCommandName $cmdName).prompt.md"] = $true
    }
    return $expected
}

# Derive the namespace prefixes this installer owns (e.g. dt, adt, fdt) from the
# generated prompt file names. A prefix is the text before the first hyphen of a
# command name (dt:push -> dt-push.prompt.md -> dt). Used so cleanup only ever
# touches files this installer is responsible for, never prompts owned by other
# tools (e.g. ecc-*.prompt.md from a different plugin).
function Get-InstallerOwnedPrefixes {
    $prefixes = @{}
    foreach ($fname in (Get-ExpectedPromptFiles).Keys) {
        $prefix = ($fname -split '-', 2)[0]
        if ($prefix) { $prefixes[$prefix] = $true }
    }
    return $prefixes
}

# Generate one Copilot prompt file per skill, deriving the command name (e.g. dt-push)
# from each SKILL.md `name` field so the slash command becomes /dt-push.
function Install-VSCodePrompt {
    $skillsDir = Join-Path $ScriptDir 'skills'
    if (-not (Test-Path $skillsDir -PathType Container)) {
        Write-Warn "Skills directory not found: $skillsDir"
        return
    }

    Ensure-Directory $VSCodePromptsDir
    $installedAny = $false

    $skillDirs = Get-ChildItem -Path $skillsDir -Directory -ErrorAction SilentlyContinue
    foreach ($skillDir in $skillDirs) {
        $mdFile = Join-Path $skillDir.FullName 'SKILL.md'
        if (-not (Test-Path $mdFile)) { continue }

        $cmdName = Get-SkillName $mdFile
        if (-not $cmdName) {
            Write-Warn "Skipping $mdFile (no name field found)"
            continue
        }

        $promptCmd = Get-PromptCommandName $cmdName
        $targetPath = Join-Path $VSCodePromptsDir "$promptCmd.prompt.md"
        Copy-Item $mdFile $targetPath -Force
        Write-Ok "Installed VS Code Copilot prompt: /$promptCmd"
        $installedAny = $true
    }

    if (-not $installedAny) {
        Write-Warn "No skills with a SKILL.md found in: $skillsDir"
    }

    # Clean up stale prompts that this installer previously generated but no longer
    # does. IMPORTANT: only touch files whose namespace prefix (dt/adt/fdt) belongs
    # to this installer. Prompts owned by other tools (e.g. ecc-*.prompt.md) are
    # left untouched so installers can coexist in the shared user prompts dir.
    $expected = Get-ExpectedPromptFiles
    $ownedPrefixes = Get-InstallerOwnedPrefixes
    $destPromptFiles = Get-ChildItem -Path $VSCodePromptsDir -Filter '*.prompt.md' -File -ErrorAction SilentlyContinue
    foreach ($dpf in $destPromptFiles) {
        $prefix = ($dpf.Name -split '-', 2)[0]
        # Skip files not owned by this installer's namespaces.
        if (-not $ownedPrefixes.ContainsKey($prefix)) { continue }

        if (-not $expected.ContainsKey($dpf.Name)) {
            Remove-Item $dpf.FullName -Force
            Write-Info "Removed stale prompt: $($dpf.FullName)"
        }
    }
}

function Remove-VSCodePrompt {
    if (-not (Test-Path (Join-Path $ScriptDir 'skills') -PathType Container)) { return }

    $expected = Get-ExpectedPromptFiles
    foreach ($fname in $expected.Keys) {
        $promptPath = Join-Path $VSCodePromptsDir $fname
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
    if (Test-Path (Join-Path $ScriptDir 'scripts')) {
        Copy-Item -Path (Join-Path $ScriptDir 'scripts') -Destination $Target -Recurse -Force
    }

    foreach ($file in @('README.md', 'README_EN.md', 'CLAUDE.md', 'LICENSE', 'install.sh', 'install.ps1', 'uninstall.sh', 'uninstall.ps1')) {
        $source = Join-Path $ScriptDir $file
        if (Test-Path $source) {
            Copy-Item -Path $source -Destination $Target -Force
        }
    }
}

function Install-CodexSync {
    if (-not (Test-Path $CodexSyncSource -PathType Leaf)) {
        Write-Warn "Codex sync script not found: $CodexSyncSource"
        return
    }

    if (-not (Test-Command 'node')) {
        Write-Warn 'Node.js not found; skipped Codex skill wrapper sync.'
        return
    }

    Ensure-Directory $CodexScriptsDir
    Copy-Item $CodexSyncSource $CodexSyncTarget -Force

    Write-Info 'Syncing Codex skill wrappers...'
    if (-not $env:DEV_TOOLS_SYNC_CODEX_PROMPTS) {
        $env:DEV_TOOLS_SYNC_CODEX_PROMPTS = '0'
    }
    & node $CodexSyncTarget $ScriptDir
    if ($LASTEXITCODE -ne 0) {
        Write-Err 'Codex skill wrapper sync failed.'
        exit $LASTEXITCODE
    }
    Write-Ok 'Codex skill wrappers synced.'
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
    Remove-VSCodePrompt
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

    # Detect installed tools
    $script:INSTALL_CLAUDE = $true
    $script:INSTALL_COPILOT = $true
    $script:INSTALL_CODEX = $true
    Detect-Tools

    if ($Help) {
        Write-Host 'Usage: .\install.ps1 [OPTIONS] [CATEGORY...]'
        Write-Host ''
        Write-Host 'Options:'
        Write-Host '  -All              Install all skill categories (auto-detects Claude/Copilot/Codex)'
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
        if (-not (Test-Command 'git')) {
            Write-Err 'git is required but not installed.'
            exit 1
        }
        Load-PluginMetadata
        Ensure-ClaudeLayout
        Uninstall-All
        exit 0
    }

    $selectedCats = @()
    if ($All) {
        $script:INSTALL_CLAUDE = $HAS_CLAUDE
        $script:INSTALL_COPILOT = $HAS_COPILOT
        $script:INSTALL_CODEX = $HAS_CODEX
        $selectedCats = @('common', 'android', 'flutter')
    } elseif ($Categories.Count -gt 0) {
        $script:INSTALL_CLAUDE = $HAS_CLAUDE
        $script:INSTALL_COPILOT = $HAS_COPILOT
        $script:INSTALL_CODEX = $HAS_CODEX
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
        Select-Tools
        if ($INSTALL_CLAUDE) {
            $selectedCats = Interactive-Select
        }
    }

    if (-not $INSTALL_CLAUDE -and -not $INSTALL_COPILOT -and -not $INSTALL_CODEX) {
        Write-Err '未检测到 Claude Code、VS Code Copilot 和 Codex，无法安装'
        exit 1
    }

    # --- Claude Code install ---
    if ($INSTALL_CLAUDE) {
        if (-not (Test-Command 'git')) {
            Write-Err 'git is required but not installed.'
            exit 1
        }
        Load-PluginMetadata
        Ensure-ClaudeLayout

        $allSkills = @()
        foreach ($category in $selectedCats) {
            $allSkills += Get-SkillsForCategory $category
        }
        $allSkills = $allSkills | Select-Object -Unique

        Write-Host 'Installing to Claude Code:' -ForegroundColor Blue
        foreach ($category in $selectedCats) {
            Write-Host "  - $category : $(Get-CategoryDesc $category)" -ForegroundColor Green
        }
        Write-Host ''

        Reset-ExistingInstallation
        Ensure-ClaudeLayout
        Install-Marketplace
        Install-Skills $allSkills
    }

    # --- VS Code Copilot install ---
    if ($INSTALL_COPILOT) {
        Write-Host ''
        Write-Host 'Installing to VS Code Copilot:' -ForegroundColor Blue
        Write-Host ''

        Remove-VSCodePrompt
        Install-VSCodePrompt
    }

    # --- Codex skill wrapper sync ---
    if ($INSTALL_CODEX) {
        Write-Host ''
        Write-Host 'Syncing to Codex:' -ForegroundColor Blue
        Write-Host ''
        Install-CodexSync
    }

    Write-Host ''
    Write-Host '========================================' -ForegroundColor Green
    Write-Host '  Installation Complete!' -ForegroundColor Green
    Write-Host '========================================' -ForegroundColor Green
    Write-Host ''

    if ($INSTALL_CLAUDE) {
        Write-Host 'Installed Claude Code skills:'
        foreach ($skill in $allSkills) {
            Write-Host "  - $skill" -ForegroundColor Green
        }
        Write-Host ''
    }

    if ($INSTALL_COPILOT) {
        Write-Host 'Installed VS Code Copilot prompts.'
        Write-Host ''
    }

    if ($INSTALL_CODEX) {
        Write-Host 'Synced Codex skill wrappers.'
        Write-Host ''
    }

    Write-Host 'Please restart the installed target tools to load the new commands.'
}

Main
