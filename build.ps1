[CmdletBinding()]
param(
    [string]$OutDir = "dist",
    [switch]$UseNpx
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $scriptRoot

$packageJson = Join-Path $scriptRoot "package.json"
if (-not (Test-Path $packageJson)) {
    throw "package.json not found in $scriptRoot"
}

$pkg = Get-Content -Raw $packageJson | ConvertFrom-Json
$name = [string]$pkg.name
$version = [string]$pkg.version
if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($version)) {
    throw "package.json must contain 'name' and 'version'."
}

$distPath = Join-Path $scriptRoot $OutDir
if (-not (Test-Path $distPath)) {
    New-Item -ItemType Directory -Path $distPath -Force | Out-Null
}

$vsixName = "$name-$version.vsix"
$vsixPath = Join-Path $distPath $vsixName

function Test-CommandExists {
    param([Parameter(Mandatory = $true)][string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

$useGlobalVsce = (-not $UseNpx) -and (Test-CommandExists -Command "vsce.cmd")

if ($useGlobalVsce) {
    Write-Host "Using global vsce.cmd..." -ForegroundColor Cyan
    & cmd /c vsce.cmd package --out $vsixPath
}
else {
    if (-not (Test-CommandExists -Command "npx.cmd")) {
        throw "Neither 'vsce.cmd' nor 'npx.cmd' was found. Install Node.js/npm or global vsce."
    }

    Write-Host "Using npx.cmd @vscode/vsce..." -ForegroundColor Cyan
    & cmd /c npx.cmd --yes @vscode/vsce package --out $vsixPath
}

if (-not (Test-Path $vsixPath)) {
    throw "Build finished but VSIX file was not found: $vsixPath"
}

Write-Host "VSIX created:" -ForegroundColor Green
Write-Host $vsixPath
