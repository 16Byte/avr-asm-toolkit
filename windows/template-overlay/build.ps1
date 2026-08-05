<#
  build.ps1 - assemble an AVRASM2 project with avra into an Intel HEX
              that Wokwi (and a real programmer) can load.

  Usage:
    .\build.ps1                     # assembles src\main.asm -> build\firmware.hex
    .\build.ps1 -Src src\lab2.asm   # assemble a different entry file
    .\build.ps1 -Clean              # remove the build\ folder first

  avra is located via the AVRA_HOME environment variable, which the toolkit's
  bootstrap.ps1 sets once per machine. AVRA_HOME points at a folder containing
  avra.exe and an includes\ directory of device definitions.
#>
param(
    [string]$Src = "src\main.asm",
    [string]$Out = "build\firmware.hex",
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

# --- locate avra + its device-definition includes --------------
$AvraHome = $env:AVRA_HOME
if (-not $AvraHome) {
    Write-Host "ERROR: AVRA_HOME is not set." -ForegroundColor Red
    Write-Host "Run the toolkit's bootstrap.ps1 once to install avra and set AVRA_HOME." -ForegroundColor Yellow
    exit 1
}
$Avra     = Join-Path $AvraHome "avra.exe"
$Includes = Join-Path $AvraHome "includes"

if (-not (Test-Path $Avra)) {
    Write-Host "ERROR: avra.exe not found at $Avra (AVRA_HOME=$AvraHome)" -ForegroundColor Red
    Write-Host "Re-run bootstrap.ps1 to rebuild the runtime." -ForegroundColor Yellow
    exit 1
}
if (-not (Test-Path $Src)) {
    Write-Host "ERROR: source file not found: $Src" -ForegroundColor Red
    exit 1
}

# --- clean / prep output dir -----------------------------------
$OutDir = Split-Path $Out -Parent
if ($Clean -and $OutDir -and (Test-Path $OutDir)) { Remove-Item $OutDir -Recurse -Force }
if ($OutDir) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }

# --- assemble --------------------------------------------------
# avra always emits an EEPROM (.eep.hex) and a debug object (.obj); by default
# it drops them next to the SOURCE. Redirect both into the build dir with -e/-d
# so src\ stays clean.
$OutBase = Join-Path $OutDir ([IO.Path]::GetFileNameWithoutExtension($Out))
Write-Host "avra: $Src -> $Out" -ForegroundColor Cyan
& $Avra -I $Includes -o $Out -e "$OutBase.eep.hex" -d "$OutBase.obj" $Src
$code = $LASTEXITCODE

if ($code -ne 0) {
    Write-Host "Build FAILED (avra exit $code)" -ForegroundColor Red
    exit $code
}
Write-Host "Build OK -> $Out" -ForegroundColor Green
