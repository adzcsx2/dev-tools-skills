[CmdletBinding()]
param(
    [string]$WorkspaceRoot = (Get-Location).Path,
    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$WorkspaceRoot = [IO.Path]::GetFullPath($WorkspaceRoot)
$registryPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'capabilities\registry.json'
$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
$ignoredPathPattern = '(^|[\\/])(\.git|\.dart_tool|\.gradle|\.idea|\.venv|\.worktree|build|dist|example|examples|node_modules|target|third_party|vendor|venv)([\\/]|$)'
$files = @(Get-ChildItem -LiteralPath $WorkspaceRoot -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch $ignoredPathPattern })

function Get-RelativePath([string]$Path) {
    return [IO.Path]::GetRelativePath($WorkspaceRoot, $Path).Replace('\', '/')
}

function Find-BackendApiEvidence {
    $evidence = [Collections.Generic.List[string]]::new()
    foreach ($file in @($files | Where-Object {
        $_.Extension -in @('.json', '.yaml', '.yml') -and $_.Name -match '(?i)(openapi|swagger)'
    } | Select-Object -First 3)) {
        $evidence.Add("contract:$(Get-RelativePath $file.FullName)")
    }

    $routeNamePattern = '(?i)(route|router|routing|controller|handler|http[_-]?server|endpoint|api)'
    $routeSyntaxPattern = '(?:\.(?:Get|Post|Put|Delete|Patch|Head|Options|GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS)\s*\(|@(?:Get|Post|Put|Delete|Patch)Mapping\s*\(|@(?:app|router|blueprint)\.(?:get|post|put|delete|patch)\s*\(|HandleFunc\s*\()'
    $sourceExtensions = @('.go', '.js', '.jsx', '.ts', '.tsx', '.py', '.java', '.kt', '.cs')
    foreach ($file in @($files | Where-Object {
        $_.Extension -in $sourceExtensions -and $_.FullName -match $routeNamePattern -and $_.BaseName -notmatch '(?i)(^test_|_test$|\.spec$|\.test$)'
    })) {
        $match = Select-String -LiteralPath $file.FullName -Pattern $routeSyntaxPattern | Select-Object -First 1
        if ($null -ne $match) {
            $evidence.Add("route:$(Get-RelativePath $file.FullName):$($match.LineNumber)")
            if ($evidence.Count -ge 5) { break }
        }
    }
    return @($evidence)
}

function Find-FlutterAppEvidence {
    $evidence = [Collections.Generic.List[string]]::new()
    foreach ($pubspec in @($files | Where-Object { $_.Name -eq 'pubspec.yaml' })) {
        $content = Get-Content -LiteralPath $pubspec.FullName -Raw
        if ($content -notmatch '(?m)^\s+flutter:\s*$' -and $content -notmatch '(?m)^\s+sdk:\s*flutter\s*$') { continue }
        $packageRoot = Split-Path -Parent $pubspec.FullName
        if (-not (Test-Path -LiteralPath (Join-Path $packageRoot 'lib\main.dart') -PathType Leaf)) { continue }
        $platforms = @(@('android', 'ios', 'windows', 'macos', 'linux', 'web') | Where-Object {
            Test-Path -LiteralPath (Join-Path $packageRoot $_) -PathType Container
        })
        if ($platforms.Count -eq 0) { continue }
        $evidence.Add("package:$(Get-RelativePath $packageRoot);platforms=$($platforms -join ',')")
    }
    return @($evidence)
}

$resolved = [Collections.Generic.List[object]]::new()
foreach ($capability in @($registry.capabilities)) {
    $evidence = @(switch ([string]$capability.detector) {
        'backend-api' { @(Find-BackendApiEvidence) }
        'flutter-app' { @(Find-FlutterAppEvidence) }
        default { @() }
    })
    if ($evidence.Count -gt 0) {
        $resolved.Add([ordered]@{
            id = $capability.id
            version = $capability.version
            entry = $capability.entry
            evidence = $evidence
        })
    }
}

$result = [ordered]@{
    schema_version = 1
    workspace_root = $WorkspaceRoot
    capabilities = @($resolved)
}
if ($AsJson) { $result | ConvertTo-Json -Depth 8; exit 0 }

if ($resolved.Count -eq 0) {
    Write-Output 'INIT_CAPABILITIES none'
    exit 0
}
foreach ($item in $resolved) {
    Write-Output "INIT_CAPABILITY id=$($item.id) entry=$($item.entry) evidence=$($item.evidence -join ';')"
}
