# Copies the project-level icon.png into the mobile assets folder as app_icon.png
# Run this from the repository root (PowerShell)

$src = Join-Path $PSScriptRoot "..\..\assets\icon.png"
$destDir = Join-Path $PSScriptRoot "assets"
$dest = Join-Path $destDir "app_icon.png"

if (-Not (Test-Path $src)) {
    Write-Error "Source icon not found: $src"
    exit 1
}

if (-Not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir | Out-Null
}

Copy-Item -Path $src -Destination $dest -Force
Write-Output "Copied $src -> $dest"
