#!/usr/bin/env bash
# build.sh - assemble an AVRASM2 project with avra into an Intel HEX for Wokwi.
#
# Usage:
#   ./build.sh                    # assembles src/main.asm -> build/firmware.hex
#   ./build.sh src/lab2.asm       # different entry file
#   ./build.sh --clean            # remove build/ first
#
# avra is located via AVRA_HOME (set once per machine by the toolkit bootstrap.sh).
set -euo pipefail

CLEAN=0
if [ "${1:-}" = "--clean" ]; then CLEAN=1; shift; fi
SRC="${1:-src/main.asm}"
OUT="${2:-build/firmware.hex}"

# Find avra: honor $AVRA_HOME if set, else fall back to the standard per-user
# install path the bootstrap uses. This makes the build work even when the calling
# shell never sourced your profile (e.g. an AI assistant running it in a bare,
# non-login shell) -- so nothing ever needs to go hunting across the filesystem.
: "${AVRA_HOME:=$HOME/.local/share/avr-asm-toolkit/avra}"
AVRA="$AVRA_HOME/avra"
INC="$AVRA_HOME/includes"
if [ ! -x "$AVRA" ]; then
  echo "ERROR: avra not found at $AVRA" >&2
  echo "Run the toolkit's bootstrap.sh once to install it. Do NOT search the filesystem." >&2
  exit 1
fi
[ -f "$SRC" ]  || { echo "ERROR: source file not found: $SRC" >&2; exit 1; }

OUTDIR="$(dirname "$OUT")"
[ "$CLEAN" = 1 ] && [ -n "$OUTDIR" ] && rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

# avra always emits an EEPROM (.eep.hex) and a debug object (.obj), by default
# next to the SOURCE. Redirect both into the build dir with -e/-d so src/ stays clean.
OUTBASE="${OUT%.*}"
echo "avra: $SRC -> $OUT"
"$AVRA" -I "$INC" -o "$OUT" -e "$OUTBASE.eep.hex" -d "$OUTBASE.obj" "$SRC"
echo "Build OK -> $OUT"

# --- Wokwi license reminder (non-blocking, estimate only) --------------------
# Free Wokwi keys last ~30 days. We can't read the real expiry (it's in VS Code's
# encrypted secret store), so we estimate from a date stamp written at bootstrap
# and refreshed by reset-wokwi-license.sh. This must never affect the build.
if [ "${AVR_TOOLKIT_NO_LICENSE_WARN:-}" != "1" ]; then
  stamp="$AVRA_HOME/wokwi-license-stamp"
  if [ -f "$stamp" ]; then
    val="$(grep -E '^[[:space:]]*activated[[:space:]]*=' "$stamp" 2>/dev/null | head -1 | cut -d= -f2 | tr -d '[:space:]' || true)"
    act="$(date -j -f "%Y-%m-%d" "$val" "+%s" 2>/dev/null || true)"
    if [ -n "$act" ]; then
      days=$(( ( $(date "+%s") - act ) / 86400 ))
      if [ "$days" -ge 24 ]; then   # 0-23 and future (negative) stay silent
        if [ "$days" -ge 30 ]; then
          echo "[wokwi] Your Wokwi license was set ~$days days ago and has probably expired (free keys last ~30)."
        else
          echo "[wokwi] Your Wokwi license was set ~$days days ago; free keys last ~30."
        fi
        echo "        Renew: F1 in VS Code -> 'Wokwi: Request a new License'"
        echo "        Then record it: run reset-wokwi-license.sh in your avr-asm-toolkit,"
        echo "        or edit $stamp and set today's date."
        echo "        (estimate only; silence with AVR_TOOLKIT_NO_LICENSE_WARN=1)"
      fi
    fi
  fi
fi
