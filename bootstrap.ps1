<#
  bootstrap.ps1 - set up the AVR (Arduino .ino + .S) toolkit on Windows.

  1. Download arduino-cli into a SHORT runtime path. (The AVR gcc toolchain fails
     with "device-specs" errors under very deep paths, so we keep it shallow under
     %LOCALAPPDATA%.)
  2. Install the arduino:avr core (avr-gcc + Uno core) into a contained data dir,
     so it never clobbers a system Arduino IDE setup.
  3. Install the wokwi-diagram skill into ~/.claude/skills.
  4. Start the Wokwi license clock.
  5. Smoke-test: compile the template sketch.

  Needs internet on first run (arduino-cli + core download).
  Options: -Link (skill as a junction) -AddAlias (New-AvrProject alias in $PROFILE).
#>
param([switch]$Link, [switch]$AddAlias)
$ErrorActionPreference = "Stop"
$Repo = $PSScriptRoot
Write-Host "AVR toolkit repo: $Repo" -ForegroundColor Cyan

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
& $Cli --config-file $Cfg core install arduino:avr
if ($LASTEXITCODE -ne 0) { throw "arduino:avr core install failed (need internet)." }

# 4) persist AVR_TOOLKIT_HOME so build scripts find the toolchain -------------
[Environment]::SetEnvironmentVariable("AVR_TOOLKIT_HOME", $Runtime, "User")
$env:AVR_TOOLKIT_HOME = $Runtime
Write-Host "AVR_TOOLKIT_HOME = $Runtime  (persisted for your user)" -ForegroundColor Green

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
if ($Link) {
    if (Test-Path $SkillDst) { cmd /c rmdir /S /Q "`"$SkillDst`"" | Out-Null }
    cmd /c mklink /J "`"$SkillDst`"" "`"$SkillSrc`"" | Out-Null
    Write-Host "Skill junction -> $SkillDst" -ForegroundColor Green
} else {
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

Write-Host ""
Write-Host "Done. Open a NEW terminal (so AVR_TOOLKIT_HOME is set), then:" -ForegroundColor Cyan
Write-Host "  .\windows\New-AvrProject.ps1 Lab1 -Open"
