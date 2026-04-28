#Requires -Version 5.1
<#
.SYNOPSIS
    Build Flutter Web for Florabit and copy output to web/flutter_web (Render /app/).
.NOTES
    Run from repo root. Keep --base-href /app/ unless you change Flask routes.
#>
$ErrorActionPreference = 'Stop'

$RepoRoot = $PSScriptRoot
$FlutterDir = Join-Path $RepoRoot 'app\app'
$BuildOut = Join-Path $FlutterDir 'build\web'
$DestDir = Join-Path $RepoRoot 'web\flutter_web'

if (-not (Test-Path -LiteralPath (Join-Path $FlutterDir 'pubspec.yaml'))) {
    Write-Error 'pubspec.yaml not found under app\app. Run this script from the florabit repo root.'
}

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
    Write-Error 'flutter is not in PATH. Install Flutter and reopen the terminal.'
}

Push-Location $FlutterDir
try {
    Write-Host '>> flutter pub get' -ForegroundColor Cyan
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Host '>> flutter build web --base-href /app/' -ForegroundColor Cyan
    & flutter build web --base-href /app/
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath (Join-Path $BuildOut 'index.html'))) {
    Write-Error "Build output missing: $BuildOut\index.html"
}

Write-Host ">> Clearing $DestDir then copying build/web..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
Get-ChildItem -LiteralPath $DestDir -Force | Remove-Item -Recurse -Force

Copy-Item -Path (Join-Path $BuildOut '*') -Destination $DestDir -Recurse -Force

Write-Host '>> Done. Next: git add web/flutter_web; git commit; git push' -ForegroundColor Green
