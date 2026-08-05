<#
  bootstrap.ps1 - set up the AVR-assembly toolkit on a Windows machine.

  What it does:
    1. Ensures avra.exe exists (uses the committed binary; builds from source only
       if missing and Visual Studio C++ tools are available).
    2. Assembles a runtime folder (.runtime\avra = avra.exe + device includes) and
       persists AVRA_HOME to it for your user, so build scripts work anywhere.
    3. Installs the wokwi-diagram skill into ~/.claude/skills.
    4. Smoke-tests a build of the template blink.

  Options:
    -Link       install the skill as a junction (repo edits reflect live) instead of a copy
    -AddAlias   add a `New-AvrProject` alias to your PowerShell $PROFILE

  Prereqs not installed here: VS Code + the Wokwi extension (for emulation), Git,
  and optionally a real Python 3 (only for the wokwi-diagram skill's helper).
#>
param([switch]$Link, [switch]$AddAlias)
$ErrorActionPreference = "Stop"
$Repo = $PSScriptRoot
Write-Host "AVR toolkit repo: $Repo" -ForegroundColor Cyan

# 1) avra binary --------------------------------------------------------------
$AvraExe = Join-Path $Repo "windows\avra\avra.exe"
if (-not (Test-Path $AvraExe)) {
    Write-Host "avra.exe missing - building from source (needs Visual Studio C++)..." -ForegroundColor Yellow
    & (Join-Path $Repo "windows\build-avra\build_avra.bat")
    if (-not (Test-Path $AvraExe)) { throw "Could not obtain avra.exe." }
}

# 2) runtime folder + AVRA_HOME ----------------------------------------------
$Runtime = Join-Path $Repo ".runtime\avra"
$IncDst  = Join-Path $Runtime "includes"
New-Item -ItemType Directory -Force -Path $IncDst | Out-Null
Copy-Item $AvraExe (Join-Path $Runtime "avra.exe") -Force
Copy-Item (Join-Path $Repo "common\avra\includes\*") $IncDst -Recurse -Force
[Environment]::SetEnvironmentVariable("AVRA_HOME", $Runtime, "User")
$env:AVRA_HOME = $Runtime
Write-Host "AVRA_HOME = $Runtime  (persisted for your user)" -ForegroundColor Green

# 3) install the wokwi-diagram skill -----------------------------------------
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

# 4) optional alias -----------------------------------------------------------
if ($AddAlias) {
    if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Force -Path $PROFILE | Out-Null }
    if (-not (Select-String -Path $PROFILE -SimpleMatch "New-AvrProject.ps1" -Quiet)) {
        Add-Content $PROFILE "`nSet-Alias New-AvrProject `"$Repo\windows\New-AvrProject.ps1`""
        Write-Host "Added New-AvrProject alias to $PROFILE" -ForegroundColor Green
    }
}

# 5) smoke test ---------------------------------------------------------------
$tmp = Join-Path $env:TEMP ("avra-smoke-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
# -e/-d keep avra's EEPROM+obj outputs in $tmp instead of next to the source.
& (Join-Path $Runtime "avra.exe") -I $IncDst -o (Join-Path $tmp "fw.hex") -e (Join-Path $tmp "fw.eep.hex") -d (Join-Path $tmp "fw.obj") (Join-Path $Repo "common\template\src\main.asm") | Out-Null
$ok = ($LASTEXITCODE -eq 0) -and (Test-Path (Join-Path $tmp "fw.hex"))
Remove-Item $tmp -Recurse -Force
if ($ok) { Write-Host "Smoke test OK - template blink assembled." -ForegroundColor Green }
else     { Write-Host "Smoke test FAILED." -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "Done. Open a NEW terminal (so AVRA_HOME is picked up), then:" -ForegroundColor Cyan
Write-Host "  .\windows\New-AvrProject.ps1 Lab1 -Open"
