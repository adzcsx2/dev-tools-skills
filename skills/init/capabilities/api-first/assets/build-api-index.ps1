[CmdletBinding()]
param(
    [string]$WorkspaceRoot = (Get-Location).Path,
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$WorkspaceRoot = [IO.Path]::GetFullPath($WorkspaceRoot)
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $WorkspaceRoot '.ai\index\backend-apis.json'
}
$OutputPath = [IO.Path]::GetFullPath($OutputPath)

$ignoredPathPattern = '(^|[\\/])(\.git|\.dart_tool|\.gradle|\.idea|\.venv|\.worktree|build|dist|example|examples|node_modules|target|third_party|vendor|venv)([\\/]|$)'
$httpMethods = @('get', 'post', 'put', 'delete', 'patch', 'head', 'options')
$routes = @{}
$inputSources = @{}
$warnings = [Collections.Generic.List[string]]::new()

function Get-RelativePath([string]$Path) {
    return [IO.Path]::GetRelativePath($WorkspaceRoot, $Path).Replace('\', '/')
}

function Normalize-RoutePath([string]$Prefix, [string]$Path) {
    $left = if ([string]::IsNullOrWhiteSpace($Prefix)) { '' } else { '/' + $Prefix.Trim('/') }
    $right = if ([string]::IsNullOrWhiteSpace($Path)) { '' } else { '/' + $Path.TrimStart('/') }
    $result = ($left + $right) -replace '/+', '/'
    if ([string]::IsNullOrWhiteSpace($result)) { return '/' }
    return $result
}

function Get-Property($Object, [string]$Name, $Default = $null) {
    if ($null -eq $Object) { return $Default }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $Default }
    return $property.Value
}

function Get-SchemaName($Schema) {
    if ($null -eq $Schema) { return '' }
    $reference = Get-Property $Schema '$ref' ''
    if ($reference) { return [string]$reference }
    return [string](Get-Property $Schema 'type' '')
}

function Add-InputSource([string]$AbsolutePath) {
    $relative = Get-RelativePath $AbsolutePath
    if (-not $inputSources.ContainsKey($relative)) {
        $inputSources[$relative] = (Get-FileHash -LiteralPath $AbsolutePath -Algorithm SHA256).Hash.ToLowerInvariant()
    }
}

function Add-Route {
    param(
        [string]$Method,
        [string]$Path,
        [string]$Summary = '',
        [string]$Description = '',
        [string[]]$Tags = @(),
        [string]$OperationId = '',
        [string]$Handler = '',
        [string[]]$Parameters = @(),
        [string[]]$RequestSchemas = @(),
        [string[]]$ResponseSchemas = @(),
        [string]$SourceKind,
        [string]$SourcePath,
        [int]$SourceLine = 0
    )

    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    $normalizedMethod = $Method.ToUpperInvariant()
    $normalizedPath = Normalize-RoutePath '' $Path
    $key = "$normalizedMethod $normalizedPath"
    if (-not $routes.ContainsKey($key)) {
        $routes[$key] = [ordered]@{
            method = $normalizedMethod
            path = $normalizedPath
            summary = $Summary
            description = $Description
            tags = [Collections.Generic.List[string]]::new()
            operation_id = $OperationId
            auth_hint = 'unknown'
            handler = $Handler
            parameters = [Collections.Generic.List[string]]::new()
            request_schemas = [Collections.Generic.List[string]]::new()
            response_schemas = [Collections.Generic.List[string]]::new()
            sources = [Collections.Generic.List[object]]::new()
        }
    }

    $route = $routes[$key]
    if (-not $route.summary -and $Summary) { $route.summary = $Summary }
    if (-not $route.description -and $Description) { $route.description = $Description }
    if (-not $route.operation_id -and $OperationId) { $route.operation_id = $OperationId }
    if (-not $route.handler -and $Handler) { $route.handler = $Handler }
    foreach ($value in @($Tags)) { if ($value -and -not $route.tags.Contains($value)) { $route.tags.Add($value) } }
    foreach ($value in @($Parameters)) { if ($value -and -not $route.parameters.Contains($value)) { $route.parameters.Add($value) } }
    foreach ($value in @($RequestSchemas)) { if ($value -and -not $route.request_schemas.Contains($value)) { $route.request_schemas.Add($value) } }
    foreach ($value in @($ResponseSchemas)) { if ($value -and -not $route.response_schemas.Contains($value)) { $route.response_schemas.Add($value) } }
    $sourceKey = "$SourceKind|$SourcePath|$SourceLine"
    $alreadyAdded = @($route.sources | Where-Object { "$($_.kind)|$($_.path)|$($_.line)" -eq $sourceKey }).Count -gt 0
    if (-not $alreadyAdded) {
        $route.sources.Add([ordered]@{ kind = $SourceKind; path = $SourcePath; line = $SourceLine })
    }
}

$allFiles = Get-ChildItem -LiteralPath $WorkspaceRoot -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch $ignoredPathPattern }

$openApiFiles = @($allFiles | Where-Object {
    $_.Extension -eq '.json' -and $_.Name -match '(?i)(openapi|swagger)'
})
foreach ($file in $openApiFiles) {
    try {
        $document = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
        $paths = Get-Property $document 'paths'
        if ($null -eq $paths) { continue }
        Add-InputSource $file.FullName
        foreach ($pathProperty in $paths.PSObject.Properties) {
            foreach ($method in $httpMethods) {
                $operationProperty = $pathProperty.Value.PSObject.Properties[$method]
                if ($null -eq $operationProperty) { continue }
                $operation = $operationProperty.Value
                $parameters = [Collections.Generic.List[string]]::new()
                $requestSchemas = [Collections.Generic.List[string]]::new()
                foreach ($parameter in @(Get-Property $operation 'parameters' @())) {
                    $schema = Get-Property $parameter 'schema'
                    $schemaName = Get-SchemaName $schema
                    $location = [string](Get-Property $parameter 'in' '')
                    $name = [string](Get-Property $parameter 'name' '')
                    $parameters.Add("${location}:${name}:$schemaName")
                    if ($location -eq 'body' -and $schemaName) { $requestSchemas.Add($schemaName) }
                }
                $requestBody = Get-Property $operation 'requestBody'
                if ($null -ne $requestBody) {
                    $content = Get-Property $requestBody 'content'
                    if ($null -ne $content) {
                        foreach ($contentType in $content.PSObject.Properties) {
                            $schemaName = Get-SchemaName (Get-Property $contentType.Value 'schema')
                            if ($schemaName) { $requestSchemas.Add($schemaName) }
                        }
                    }
                }
                $responseSchemas = [Collections.Generic.List[string]]::new()
                $responses = Get-Property $operation 'responses'
                if ($null -ne $responses) {
                    foreach ($response in $responses.PSObject.Properties) {
                        $schemaName = Get-SchemaName (Get-Property $response.Value 'schema')
                        if ($schemaName) { $responseSchemas.Add("$($response.Name):$schemaName") }
                    }
                }
                Add-Route -Method $method -Path $pathProperty.Name `
                    -Summary ([string](Get-Property $operation 'summary' '')) `
                    -Description ([string](Get-Property $operation 'description' '')) `
                    -Tags @((Get-Property $operation 'tags' @())) `
                    -OperationId ([string](Get-Property $operation 'operationId' '')) `
                    -Parameters @($parameters) -RequestSchemas @($requestSchemas) -ResponseSchemas @($responseSchemas) `
                    -SourceKind 'openapi' -SourcePath (Get-RelativePath $file.FullName)
            }
        }
    } catch {
        $warnings.Add("Could not parse OpenAPI candidate $(Get-RelativePath $file.FullName): $($_.Exception.Message)")
    }
}

$routeFilePattern = '(?i)(route|router|routing|controller|handler|http[_-]?server|endpoint|api)'
$sourceExtensions = @('.go', '.js', '.jsx', '.ts', '.tsx', '.py', '.java', '.kt', '.cs')
$routeFiles = @($allFiles | Where-Object {
    $_.Extension -in $sourceExtensions -and $_.FullName -match $routeFilePattern -and $_.BaseName -notmatch '(?i)(^test_|_test$|\.spec$|\.test$)'
})

foreach ($file in $routeFiles) {
    $lines = @(Get-Content -LiteralPath $file.FullName)
    $relative = Get-RelativePath $file.FullName
    $prefixes = @{ app = ''; router = ''; r = ''; e = '' }
    $classPrefix = ''
    $matchedFile = $false

    for ($index = 0; $index -lt $lines.Count; $index += 1) {
        $line = $lines[$index]
        if ($line -match '(?<name>[A-Za-z_]\w*)\s*:?=\s*(?<parent>[A-Za-z_]\w*)\.(?:Party|Group)\(\s*["''](?<path>[^"'']+)["'']') {
            $parentPrefix = if ($prefixes.ContainsKey($matches.parent)) { [string]$prefixes[$matches.parent] } else { '' }
            $prefixes[$matches.name] = Normalize-RoutePath $parentPrefix $matches.path
        }
        if ($line -match '@RequestMapping\(\s*(?:value\s*=\s*)?["''](?<path>[^"'']+)["'']') {
            $classPrefix = $matches.path
        }

        $routeMatch = [regex]::Match($line, '(?<receiver>[A-Za-z_]\w*)\.(?<method>Get|Post|Put|Delete|Patch|Head|Options|GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS)\(\s*["''](?<path>[^"'']+)["'']')
        if ($routeMatch.Success) {
            $receiver = $routeMatch.Groups['receiver'].Value
            $prefix = if ($prefixes.ContainsKey($receiver)) { [string]$prefixes[$receiver] } else { '' }
            Add-Route -Method $routeMatch.Groups['method'].Value -Path (Normalize-RoutePath $prefix $routeMatch.Groups['path'].Value) `
                -SourceKind 'code' -SourcePath $relative -SourceLine ($index + 1)
            $matchedFile = $true
            continue
        }

        $decoratorMatch = [regex]::Match($line, '@(?:app|router|blueprint)\.(?<method>get|post|put|delete|patch|head|options)\(\s*["''](?<path>[^"'']+)["'']', 'IgnoreCase')
        if ($decoratorMatch.Success) {
            Add-Route -Method $decoratorMatch.Groups['method'].Value -Path $decoratorMatch.Groups['path'].Value `
                -SourceKind 'code' -SourcePath $relative -SourceLine ($index + 1)
            $matchedFile = $true
            continue
        }

        $mappingMatch = [regex]::Match($line, '@(?<method>Get|Post|Put|Delete|Patch)Mapping\(\s*(?:value\s*=\s*)?["''](?<path>[^"'']+)["'']')
        if ($mappingMatch.Success) {
            Add-Route -Method $mappingMatch.Groups['method'].Value -Path (Normalize-RoutePath $classPrefix $mappingMatch.Groups['path'].Value) `
                -SourceKind 'code' -SourcePath $relative -SourceLine ($index + 1)
            $matchedFile = $true
        }
    }
    if ($matchedFile) { Add-InputSource $file.FullName }
}

if ($routes.Count -eq 0) {
    $warnings.Add('No routes were indexed. Adapt this project-local builder to the repository route-registration pattern before relying on API-first search.')
}
if ($openApiFiles.Count -eq 0) {
    $warnings.Add('No OpenAPI/Swagger JSON contract was found; indexed code routes may have incomplete summaries and schemas.')
}

$sortedRoutes = @($routes.Values | ForEach-Object {
    [ordered]@{
        method = $_.method
        path = $_.path
        summary = $_.summary
        description = $_.description
        tags = @($_.tags)
        operation_id = $_.operation_id
        auth_hint = $_.auth_hint
        handler = $_.handler
        parameters = @($_.parameters)
        request_schemas = @($_.request_schemas)
        response_schemas = @($_.response_schemas)
        sources = @($_.sources)
    }
} | Sort-Object path, method)

$document = [ordered]@{
    schema_version = 1
    generated_at_utc = [DateTime]::UtcNow.ToString('o')
    metadata = [ordered]@{
        route_count = $sortedRoutes.Count
        sources = @($inputSources.GetEnumerator() | Sort-Object Name | ForEach-Object {
            [ordered]@{ path = $_.Name; sha256 = $_.Value }
        })
        warnings = @($warnings)
    }
    routes = $sortedRoutes
}

[IO.Directory]::CreateDirectory((Split-Path -Parent $OutputPath)) | Out-Null
[IO.File]::WriteAllText($OutputPath, ($document | ConvertTo-Json -Depth 12) + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
Write-Output "API_INDEX_BUILT routes=$($sortedRoutes.Count) sources=$($inputSources.Count) warnings=$($warnings.Count) output=$OutputPath"
