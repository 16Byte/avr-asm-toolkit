<#
  Sim-Run.ps1 - run this sketch headless in Wokwi and capture the serial output,
  so Claude can answer "why isn't this working?" by actually running it and reading
  what it prints (then diagnosing), and so labs can be auto-checked.

  Runs in Wokwi's CLOUD (project uploaded; metered) - on demand, not every edit.
  Needs a WOKWI_CLI_TOKEN you set (https://wokwi.com/dashboard/ci):
    [Environment]::SetEnvironmentVariable('WOKWI_CLI_TOKEN','wok_...','User')

  Usage (from a project dir with wokwi.toml + build.ps1):
    .\Sim-Run.ps1                                   # run 5s, print serial
    .\Sim-Run.ps1 -Input "22`n33`n44`n"             # feed typed input (stdin->serial)
    .\Sim-Run.ps1 -ExpectText "The sum is 99"       # assert (exit 0 if seen)
    .\Sim-Run.ps1 -FailText "Error" -Timeout 8000
    .\Sim-Run.ps1 -Scenario test.yaml               # official automation scenario
#>
param(
    [int]$Timeout = 5000,
    [string]$InputText,
    [string]$ExpectText,
    [string]$FailText,
    [string]$Scenario,
    [string]$LogFile = "build\serial.log",
    [switch]$Build
)
$ErrorActionPreference = "Stop"

$Home2 = if ($env:AVR_TOOLKIT_HOME) { $env:AVR_TOOLKIT_HOME } else { Join-Path $env:LOCALAPPDATA "avr-asm-toolkit" }
$Wok = Join-Path $Home2 "wokwi-cli\wokwi-cli.exe"
if (-not (Test-Path $Wok)) {
    Write-Host "ERROR: wokwi-cli not found at $Wok. Run the toolkit's bootstrap.ps1." -ForegroundColor Red; exit 1
}

# token: process env first, else the User-scoped value the user persisted (never printed)
$tok = $env:WOKWI_CLI_TOKEN
if (-not $tok) { $tok = [Environment]::GetEnvironmentVariable("WOKWI_CLI_TOKEN", "User") }
if (-not $tok) {
    Write-Host "ERROR: WOKWI_CLI_TOKEN is not set." -ForegroundColor Red
    Write-Host "Get one at https://wokwi.com/dashboard/ci, then:" -ForegroundColor Yellow
    Write-Host "  [Environment]::SetEnvironmentVariable('WOKWI_CLI_TOKEN','wok_...','User')" -ForegroundColor Yellow
    exit 1
}
$env:WOKWI_CLI_TOKEN = $tok

if ($Build -or -not (Test-Path "build\firmware.hex")) {
    if (Test-Path ".\build.ps1") { & .\build.ps1 | Out-Null }
    else { Write-Host "WARNING: no build.ps1 here; wokwi.toml must point at existing firmware." -ForegroundColor Yellow }
}

$OutDir = Split-Path $LogFile -Parent
if ($OutDir -and -not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }

$cliArgs = @('.', '--timeout', "$Timeout", '--serial-log-file', $LogFile)
if ($Scenario) { $cliArgs += @('--scenario', $Scenario) }
if ($ExpectText) { $cliArgs += @('--expect-text', $ExpectText) }
if ($FailText) { $cliArgs += @('--fail-text', $FailText) }
if ($InputText) { $cliArgs += '--interactive' }

Write-Host "wokwi-cli run: timeout=${Timeout}ms$(if($InputText){' (feeding input)'})" -ForegroundColor Cyan
if ($InputText) { $InputText | & $Wok @cliArgs } else { & $Wok @cliArgs }
$code = $LASTEXITCODE

Write-Host "----- serial output -----" -ForegroundColor DarkCyan
if (Test-Path $LogFile) { Get-Content $LogFile } else { Write-Host "(no serial captured)" }
Write-Host "-------------------------" -ForegroundColor DarkCyan
# exit codes: 0 = ran/expect met; 1 = expect-not-met or fail-text hit; 42 = timeout.
Write-Host "wokwi-cli exit $code" -ForegroundColor $(if ($code -eq 0) { 'Green' } elseif ($code -eq 42) { 'Yellow' } else { 'Red' })
exit $code
