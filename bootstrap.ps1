<#
  bootstrap.ps1 - set up the AVR (Arduino .ino + .S) toolkit on Windows.

  1. Download arduino-cli into a SHORT runtime path. (The AVR gcc toolchain fails
     with "device-specs" errors under very deep paths, so we keep it shallow under
     %LOCALAPPDATA%.)
  2. Install the arduino:avr core (avr-gcc + Uno core) into a contained data dir,
     so it never clobbers a system Arduino IDE setup.
  3. Download a contained Python (embeddable) for the wokwi-diagram skill helper
     and point AVR_TOOLKIT_PY at it -- no system/Store/PlatformIO Python needed.
  4. Install the wokwi-diagram skill into ~/.claude/skills.
  5. Start the Wokwi license clock.
  6. Smoke-test: compile the template sketch and run the skill helper.

  Needs internet on first run (arduino-cli + core download).
  The skill is installed as a live junction by default, so a later `git pull` updates
  it with no re-copy. Options: -Copy (independent copy instead of a junction),
  -AddAlias (New-AvrProject alias in $PROFILE).
#>
param([switch]$Copy, [switch]$AddAlias)
$ErrorActionPreference = "Stop"
$Repo = $PSScriptRoot
Write-Host "AVR toolkit repo: $Repo" -ForegroundColor Cyan

# Contained Python for the wokwi-diagram skill helper. We ship our own so the
# toolkit never depends on a system/Store/PlatformIO interpreter. The helper is
# pure stdlib, so the official embeddable package (no pip/venv) is all we need.
$PyVer = "3.12.7"

# 1) runtime dirs (SHORT path) -----------------------------------------------
$Runtime = Join-Path $env:LOCALAPPDATA "avr-asm-toolkit"
$AcliDir = Join-Path $Runtime "acli"
$DataDir = Join-Path $Runtime "adata"
New-Item -ItemType Directory -Force -Path $AcliDir, $DataDir | Out-Null
$Cli = Join-Path $AcliDir "arduino-cli.exe"
$Cfg = Join-Path $AcliDir "arduino-cli.yaml"

# 2) arduino-cli binary -------------------------------------------------------
if (-not (Test-Path $Cli)) {
    Write-Host "Downloading arduino-cli..." -ForegroundColor Cyan
    $zip = Join-Path $env:TEMP "arduino-cli-dl.zip"
    Invoke-WebRequest -Uri "https://downloads.arduino.cc/arduino-cli/arduino-cli_latest_Windows_64bit.zip" -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $AcliDir -Force
    Remove-Item $zip -Force
}

# contained config: keep cores/toolchain under our own data dir
@(
    "directories:",
    "  data: '$DataDir'",
    "  downloads: '$(Join-Path $DataDir 'staging')'",
    "  user: '$(Join-Path $DataDir 'user')'"
) | Set-Content -Path $Cfg -Encoding UTF8

# 3) arduino:avr core ---------------------------------------------------------
Write-Host "Installing arduino:avr core (one-time download)..." -ForegroundColor Cyan
& $Cli --config-file $Cfg core update-index
# Pin the core version so the IntelliSense paths in template/.vscode stay valid.
& $Cli --config-file $Cfg core install arduino:avr@1.8.8
if ($LASTEXITCODE -ne 0) { throw "arduino:avr core install failed (need internet)." }

# 4) persist AVR_TOOLKIT_HOME so build scripts find the toolchain -------------
[Environment]::SetEnvironmentVariable("AVR_TOOLKIT_HOME", $Runtime, "User")
$env:AVR_TOOLKIT_HOME = $Runtime
Write-Host "AVR_TOOLKIT_HOME = $Runtime  (persisted for your user)" -ForegroundColor Green

# 4b) contained Python for the wokwi-diagram skill --------------------------
# Download the official embeddable Python into our runtime dir (parallel to
# arduino-cli above) and point AVR_TOOLKIT_PY at it. Nothing here touches a
# system, Microsoft Store, or PlatformIO Python.
$PyDir = Join-Path $Runtime "python"
$Py    = Join-Path $PyDir "python.exe"
if (-not (Test-Path $Py)) {
    Write-Host "Downloading embeddable Python $PyVer..." -ForegroundColor Cyan
    $pyzip = Join-Path $env:TEMP "avrtk-python-embed.zip"
    Invoke-WebRequest -Uri "https://www.python.org/ftp/python/$PyVer/python-$PyVer-embed-amd64.zip" -OutFile $pyzip -UseBasicParsing
    New-Item -ItemType Directory -Force -Path $PyDir | Out-Null
    Expand-Archive -Path $pyzip -DestinationPath $PyDir -Force
    Remove-Item $pyzip -Force
}
if (-not (Test-Path $Py)) { throw "Python install failed (no python.exe at $Py)." }
[Environment]::SetEnvironmentVariable("AVR_TOOLKIT_PY", $Py, "User")
$env:AVR_TOOLKIT_PY = $Py
Write-Host "AVR_TOOLKIT_PY = $Py  (contained Python for the wokwi-diagram skill)" -ForegroundColor Green

# start the Wokwi license clock at first setup (don't clobber an existing stamp)
$Stamp = Join-Path $Runtime "wokwi-license-stamp"
if (-not (Test-Path $Stamp)) {
    $today = Get-Date -Format 'yyyy-MM-dd'
    @(
        "# avr-asm-toolkit wokwi license stamp",
        "# Date the Wokwi VS Code license was last activated/renewed (YYYY-MM-DD).",
        "# Edit by hand if it drifts, or run Reset-WokwiLicense.ps1 after you renew.",
        "activated=$today"
    ) | Set-Content -Path $Stamp -Encoding UTF8
    Write-Host "License stamp started ($today)." -ForegroundColor Green
}

# 5) install the wokwi-diagram skill -----------------------------------------
$SkillSrc  = Join-Path $Repo "common\skill\wokwi-diagram"
$SkillsDir = Join-Path $env:USERPROFILE ".claude\skills"
$SkillDst  = Join-Path $SkillsDir "wokwi-diagram"
New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
if (-not $Copy) {
    # default: junction so `git pull` updates the skill live (rmdir on a junction
    # removes only the link, never the repo files it points at)
    if (Test-Path $SkillDst) { cmd /c rmdir /S /Q "`"$SkillDst`"" | Out-Null }
    cmd /c mklink /J "`"$SkillDst`"" "`"$SkillSrc`"" | Out-Null
    Write-Host "Skill linked (junction) -> $SkillDst  (git pull keeps it current)" -ForegroundColor Green
} else {
    if (Test-Path $SkillDst) { cmd /c rmdir /S /Q "`"$SkillDst`"" | Out-Null }
    New-Item -ItemType Directory -Force -Path $SkillDst | Out-Null
    Copy-Item (Join-Path $SkillSrc "*") $SkillDst -Recurse -Force
    Write-Host "Skill copied -> $SkillDst" -ForegroundColor Green
}

# 6) optional alias -----------------------------------------------------------
if ($AddAlias) {
    if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Force -Path $PROFILE | Out-Null }
    if (-not (Select-String -Path $PROFILE -SimpleMatch "New-AvrProject.ps1" -Quiet)) {
        Add-Content $PROFILE "`nSet-Alias New-AvrProject `"$Repo\windows\New-AvrProject.ps1`""
        Write-Host "Added New-AvrProject alias to $PROFILE" -ForegroundColor Green
    }
}

# 7) smoke test: compile the template sketch ---------------------------------
$tmp = Join-Path $env:TEMP ("avrtk-smoke-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
& $Cli --config-file $Cfg compile --fqbn arduino:avr:uno --output-dir $tmp (Join-Path $Repo "common\template") 2>&1 | Out-Null
$ok = ($LASTEXITCODE -eq 0) -and (Get-ChildItem $tmp -Filter "*.ino.hex" -ErrorAction SilentlyContinue)
Remove-Item $tmp -Recurse -Force
if ($ok) { Write-Host "Smoke test OK - template sketch compiled." -ForegroundColor Green }
else     { Write-Host "Smoke test FAILED." -ForegroundColor Red; exit 1 }

# 7b) smoke test: the contained Python runs the skill helper -----------------
& $Py (Join-Path $Repo "common\skill\wokwi-diagram\scripts\wokwi_diagram.py") --help *> $null
if ($LASTEXITCODE -eq 0) { Write-Host "Python smoke test OK - wokwi-diagram helper runs." -ForegroundColor Green }
else { Write-Host "Python smoke test FAILED (helper did not run)." -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "Done. Open a NEW terminal (so AVR_TOOLKIT_HOME is set), then:" -ForegroundColor Cyan
Write-Host "  .\windows\New-AvrProject.ps1 Lab1 -Open"
