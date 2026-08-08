<#
  build.ps1 - compile this Arduino sketch (.ino + any .S files) with arduino-cli
  into build/firmware.hex (+ .elf) for Wokwi.

  arduino-cli is located via AVR_TOOLKIT_HOME (set by bootstrap.ps1); it defaults
  to the standard install path if the env var isn't set, so the build works even
  in a bare shell (e.g. when Claude runs it) without searching the filesystem.

  Usage:
    .\build.ps1            # compile this sketch folder
    .\build.ps1 -Clean     # remove build\ first
#>
param([switch]$Clean)
$ErrorActionPreference = "Stop"

$Home2 = if ($env:AVR_TOOLKIT_HOME) { $env:AVR_TOOLKIT_HOME } else { Join-Path $env:LOCALAPPDATA "avr-asm-toolkit" }
$Cli = Join-Path $Home2 "acli\arduino-cli.exe"
$Cfg = Join-Path $Home2 "acli\arduino-cli.yaml"
if (-not (Test-Path $Cli)) {
    Write-Host "ERROR: arduino-cli not found at $Cli" -ForegroundColor Red
    Write-Host "Run the toolkit's bootstrap.ps1 once. Do NOT search the filesystem." -ForegroundColor Yellow
    exit 1
}

$Build = "build"
if ($Clean -and (Test-Path $Build)) { Remove-Item $Build -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Build | Out-Null

Write-Host "arduino-cli compile (arduino:avr:uno)..." -ForegroundColor Cyan
& $Cli --config-file $Cfg compile --fqbn arduino:avr:uno --output-dir $Build .
if ($LASTEXITCODE -ne 0) { Write-Host "Build FAILED" -ForegroundColor Red; exit $LASTEXITCODE }

# normalize output to stable names so wokwi.toml never changes per project
$hex = Get-ChildItem "$Build\*.ino.hex" | Where-Object { $_.Name -notlike '*with_bootloader*' } | Select-Object -First 1
$elf = Get-ChildItem "$Build\*.ino.elf" | Select-Object -First 1
if ($hex) { Copy-Item $hex.FullName (Join-Path $Build "firmware.hex") -Force }
if ($elf) { Copy-Item $elf.FullName (Join-Path $Build "firmware.elf") -Force }
Write-Host "Build OK -> build\firmware.hex" -ForegroundColor Green

# --- Wokwi license reminder (non-blocking, estimate only) --------------------
# Free Wokwi keys last ~30 days; the real expiry is in VS Code's encrypted store,
# so we estimate from a date stamp (written at bootstrap, refreshed by
# Reset-WokwiLicense.ps1). This must never affect the build.
if ($env:AVR_TOOLKIT_NO_LICENSE_WARN -ne "1") {
    try {
        $stamp = Join-Path $Home2 "wokwi-license-stamp"
        if (Test-Path $stamp) {
            $line = (Select-String -Path $stamp -Pattern '^\s*activated\s*=' | Select-Object -First 1).Line
            $val  = if ($line) { ($line -split '=', 2)[1].Trim() } else { $null }
            $act  = [datetime]::MinValue
            if ($val -and [datetime]::TryParseExact($val, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$act)) {
                $days = ([datetime]::Today - $act.Date).Days
                if ($days -ge 24) {
                    $state = if ($days -ge 30) { "was set ~$days days ago and has probably expired (free keys last ~30)." }
                             else { "was set ~$days days ago; free keys last ~30." }
                    Write-Host ""
                    Write-Host "[wokwi] Your Wokwi license $state" -ForegroundColor Yellow
                    Write-Host "        Renew: F1 in VS Code -> 'Wokwi: Request a new License'" -ForegroundColor Yellow
                    Write-Host "        Then record it: run Reset-WokwiLicense.ps1 in your avr-asm-toolkit," -ForegroundColor Yellow
                    Write-Host "        or edit $stamp and set today's date." -ForegroundColor Yellow
                    Write-Host "        (estimate only; silence with AVR_TOOLKIT_NO_LICENSE_WARN=1)" -ForegroundColor DarkGray
                }
            }
        }
    } catch { }
}
