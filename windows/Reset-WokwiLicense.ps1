<#
  Reset-WokwiLicense.ps1 - record that you just renewed the Wokwi license.

  Writes today's date into the toolkit's license stamp so the build-time reminder
  restarts its ~30-day countdown. Run this right after renewing in VS Code
  (F1 -> "Wokwi: Request a new License").

  The stamp lives in the toolkit runtime; this finds it via AVR_TOOLKIT_HOME,
  defaulting to the standard install path if that isn't set.
#>
$ErrorActionPreference = "Stop"
$Home2 = if ($env:AVR_TOOLKIT_HOME) { $env:AVR_TOOLKIT_HOME } else { Join-Path $env:LOCALAPPDATA "avr-asm-toolkit" }
$Stamp = Join-Path $Home2 "wokwi-license-stamp"
$today = Get-Date -Format 'yyyy-MM-dd'
@(
    "# avr-asm-toolkit wokwi license stamp",
    "# Date the Wokwi VS Code license was last activated/renewed (YYYY-MM-DD).",
    "# Edit by hand if it drifts, or run Reset-WokwiLicense.ps1 after you renew.",
    "activated=$today"
) | Set-Content -Path $Stamp -Encoding UTF8
Write-Host "Wokwi license stamp reset to $today" -ForegroundColor Green
Write-Host "  $Stamp"
