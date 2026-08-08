#!/usr/bin/env bash
# reset-wokwi-license.sh - record that you just renewed the Wokwi license.
#
# Writes today's date into the toolkit's license stamp so the build-time reminder
# restarts its ~30-day countdown. Run right after renewing in VS Code
# (F1 -> "Wokwi: Request a new License").
#
# Finds the stamp via AVR_TOOLKIT_HOME, defaulting to the standard install path.
set -euo pipefail
: "${AVR_TOOLKIT_HOME:=$HOME/.local/share/avr-asm-toolkit}"
STAMP="$AVR_TOOLKIT_HOME/wokwi-license-stamp"
TODAY="$(date +%Y-%m-%d)"
{
  echo "# avr-asm-toolkit wokwi license stamp"
  echo "# Date the Wokwi VS Code license was last activated/renewed (YYYY-MM-DD)."
  echo "# Edit by hand if it drifts, or run macos/reset-wokwi-license.sh after you renew."
  echo "activated=$TODAY"
} > "$STAMP"
echo "Wokwi license stamp reset to $TODAY"
echo "  $STAMP"
