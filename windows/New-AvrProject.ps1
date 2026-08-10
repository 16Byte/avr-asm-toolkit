<#
  New-AvrProject.ps1 - scaffold a ready-to-code Arduino (.ino + .S) + Wokwi project.

  A project is an Arduino sketch folder: <Name>/<Name>.ino plus assembly in .S files.
  Composes:  common\base  (shared boilerplate)  +  a template  +  the Windows overlay.

  Template selection is CURATED BY NAME: if the project name matches a folder in
  common\templates (case-insensitive, e.g. Lab3 / lab3 -> templates\Lab3), that template
  is used -- so a known lab comes up with its own .ino + .S starter and canonical
  diagram.json already in place. Any other name falls back to the default 'blinky'
  template. The main starter .ino is renamed to match the folder (Arduino requires the
  main sketch file to share the folder's name).

  Examples:
    .\windows\New-AvrProject.ps1 Lab3          # -> Lab3 template (body-fat monitor)
    .\windows\New-AvrProject.ps1 MyThing       # -> blinky (default)
    .\windows\New-AvrProject.ps1 -Name Lab3 -Open
    .\windows\New-AvrProject.ps1 Homework3 -Path D:\school
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Name,
    [string]$Path = (Join-Path $env:USERPROFILE "Documents\Arduino"),
    [string]$Template,
    [switch]$Open,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$RepoRoot      = Split-Path $PSScriptRoot -Parent
$Base          = Join-Path $RepoRoot "common\base"
$TemplatesRoot = Join-Path $RepoRoot "common\templates"
$Overlay       = Join-Path $PSScriptRoot "template-overlay"
foreach ($p in @($Base, $TemplatesRoot, $Overlay)) {
    if (-not (Test-Path $p)) { throw "Template part not found: $p" }
}

# Pick the template: explicit -Template wins; else name-match; else 'blinky'.
$Pick = if ($Template) { $Template } else { $Name }
$TplDir = Get-ChildItem $TemplatesRoot -Directory -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -ieq $Pick } | Select-Object -First 1
if (-not $TplDir) {
    $TplDir = Get-ChildItem $TemplatesRoot -Directory | Where-Object { $_.Name -ieq "blinky" } | Select-Object -First 1
    if (-not $TplDir) { throw "Default template 'blinky' not found under $TemplatesRoot" }
    $matched = $false
} else {
    $matched = ($TplDir.Name -ine "blinky")
}

$Dest = Join-Path $Path $Name
if ((Test-Path $Dest) -and -not $Force) {
    throw "Destination already exists: $Dest  (use -Force to overwrite)"
}

New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Copy-Item "$Base\*"          $Dest -Recurse -Force   # shared: CLAUDE.md, README, wokwi.toml, .gitignore, .vscode
Copy-Item "$($TplDir.FullName)\*" $Dest -Recurse -Force   # template: <starter>.ino, .S, diagram.json (+ lab docs)
Copy-Item "$Overlay\*"       $Dest -Recurse -Force   # windows: build.ps1, .vscode\tasks.json

# Arduino requires the main .ino to match the folder name: rename the single root .ino.
$ino = Get-ChildItem $Dest -Filter *.ino -File | Select-Object -First 1
if ($ino -and $ino.BaseName -ine $Name) {
    Move-Item $ino.FullName (Join-Path $Dest "$Name.ino") -Force
}

if ($matched) {
    Write-Host "Template '$($TplDir.Name)' matched by name -> circuit + starter files installed." -ForegroundColor Green
} else {
    Write-Host "No template named '$Pick' -> used default 'blinky'." -ForegroundColor Yellow
}
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
