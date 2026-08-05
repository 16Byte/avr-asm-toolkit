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

if [ -z "${AVRA_HOME:-}" ]; then
  echo "ERROR: AVRA_HOME is not set. Run the toolkit's bootstrap.sh once." >&2
  exit 1
fi
AVRA="$AVRA_HOME/avra"
INC="$AVRA_HOME/includes"
[ -x "$AVRA" ] || { echo "ERROR: avra not found/executable at $AVRA" >&2; exit 1; }
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
