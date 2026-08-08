<#
  New-AvrProject.ps1 - scaffold a ready-to-code Arduino (.ino + .S) + Wokwi project.

  A project is an Arduino sketch folder: <Name>/<Name>.ino plus assembly in .S files.
  Composes the shared template (common\template) + the Windows overlay (build.ps1 +
  .vscode task), and renames the starter .ino to match the folder (Arduino requires
  the main sketch file to share the folder's name).

  For a lab: scaffold with the lab's name, then replace the starter .ino/.S with the
  lab's provided files (e.g. Lab5.ino + push_button.S).

  Examples:
    .\windows\New-AvrProject.ps1 Lab5
    .\windows\New-AvrProject.ps1 -Name Lab5 -Open
    .\windows\New-AvrProject.ps1 Homework3 -Path D:\school
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Name,
    [string]$Path = (Join-Path $env:USERPROFILE "Documents\Arduino"),
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
Copy-Item "$Common\*"  $Dest -Recurse -Force    # shared: template.ino, blink.S, wokwi.toml, diagram.json, CLAUDE.md, README, .gitignore
Copy-Item "$Overlay\*" $Dest -Recurse -Force    # windows: build.ps1, .vscode\tasks.json

# Arduino requires the main .ino to match the folder name.
$starter = Join-Path $Dest "template.ino"
if (Test-Path $starter) { Move-Item $starter (Join-Path $Dest "$Name.ino") -Force }

Write-Host "Created Arduino+asm project -> $Dest" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1) code `"$Dest`""
Write-Host "  2) Ctrl+Shift+B            # build -> build\firmware.hex"
Write-Host "  3) Open diagram.json to run it in Wokwi"

if ($Open) {
    $code = Get-Command code -ErrorAction SilentlyContinue
    if ($code) { & code $Dest }
    else { Write-Host "(VS Code 'code' CLI not on PATH -- open the folder manually)" -ForegroundColor Yellow }
}
