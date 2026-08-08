#!/usr/bin/env bash
# build.sh - compile this Arduino sketch (.ino + any .S files) with arduino-cli
# into build/firmware.hex (+ .elf) for Wokwi.
#
# arduino-cli is located via AVR_TOOLKIT_HOME (set by bootstrap.sh); it defaults to
# the standard install path if the var isn't set, so the build works even in a bare
# shell (e.g. when Claude runs it) without searching the filesystem.
#
# Usage: ./build.sh          # compile this sketch
#        ./build.sh --clean  # remove build/ first
set -euo pipefail

CLEAN=0
[ "${1:-}" = "--clean" ] && CLEAN=1

HOME2="${AVR_TOOLKIT_HOME:-$HOME/.local/share/avr-asm-toolkit}"
CLI="$HOME2/acli/arduino-cli"
CFG="$HOME2/acli/arduino-cli.yaml"
if [ ! -x "$CLI" ]; then
  echo "ERROR: arduino-cli not found at $CLI" >&2
  echo "Run the toolkit's bootstrap.sh once. Do NOT search the filesystem." >&2
  exit 1
fi

[ "$CLEAN" = 1 ] && rm -rf build
mkdir -p build

echo "arduino-cli compile (arduino:avr:uno)..."
"$CLI" --config-file "$CFG" compile --fqbn arduino:avr:uno --output-dir build .

# normalize output to stable names so wokwi.toml never changes per project
hex="$(ls build/*.ino.hex 2>/dev/null | grep -v with_bootloader | head -1 || true)"
elf="$(ls build/*.ino.elf 2>/dev/null | head -1 || true)"
[ -n "$hex" ] && cp "$hex" build/firmware.hex
[ -n "$elf" ] && cp "$elf" build/firmware.elf
echo "Build OK -> build/firmware.hex"

# --- Wokwi license reminder (non-blocking, estimate only) --------------------
if [ "${AVR_TOOLKIT_NO_LICENSE_WARN:-}" != "1" ]; then
  stamp="$HOME2/wokwi-license-stamp"
  if [ -f "$stamp" ]; then
    val="$(grep -E '^[[:space:]]*activated[[:space:]]*=' "$stamp" 2>/dev/null | head -1 | cut -d= -f2 | tr -d '[:space:]' || true)"
    act="$(date -j -f "%Y-%m-%d" "$val" "+%s" 2>/dev/null || true)"
    if [ -n "$act" ]; then
      days=$(( ( $(date "+%s") - act ) / 86400 ))
      if [ "$days" -ge 24 ]; then
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
