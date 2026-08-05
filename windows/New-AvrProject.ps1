<#
  New-AvrProject.ps1 - scaffold a ready-to-code AVR assembly + Wokwi project.

  Composes a new project from the shared template (common\template) plus the
  Windows overlay (build.ps1 + .vscode task), so you can start writing assembly
  immediately (Ctrl+Shift+B to build, then start the Wokwi sim).

  Examples:
    .\windows\New-AvrProject.ps1 Lab1
    .\windows\New-AvrProject.ps1 -Name Lab2 -Open
    .\windows\New-AvrProject.ps1 Homework3 -Path D:\school
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Name,
    [string]$Path = (Join-Path $env:USERPROFILE "Documents\PlatformIO\Projects"),
    [switch]$Open,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path $PSScriptRoot -Parent
$Common   = Join-Path $RepoRoot "common\template"
$Overlay  = Join-Path $PSScriptRoot "template-overlay"
foreach ($p in @($Common, $Overlay)) {
    if (-not (Test-Path $p)) { throw "Template part not found: $p" }
}

$Dest = Join-Path $Path $Name
if ((Test-Path $Dest) -and -not $Force) {
    throw "Destination already exists: $Dest  (use -Force to overwrite)"
}

New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Copy-Item "$Common\*"  $Dest -Recurse -Force    # shared: src\main.asm, wokwi.toml, diagram.json, CLAUDE.md, README, .gitignore
Copy-Item "$Overlay\*" $Dest -Recurse -Force    # windows: build.ps1, .vscode\tasks.json

Write-Host "Created AVR asm project -> $Dest" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1) code `"$Dest`""
Write-Host "  2) Ctrl+Shift+B            # build -> build\firmware.hex"
Write-Host "  3) Run 'Wokwi: Start Simulator'"

if ($Open) {
    $code = Get-Command code -ErrorAction SilentlyContinue
    if ($code) { & code $Dest }
    else { Write-Host "(VS Code 'code' CLI not on PATH -- open the folder manually)" -ForegroundColor Yellow }
}
