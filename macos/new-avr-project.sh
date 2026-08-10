#!/usr/bin/env bash
# new-avr-project.sh - scaffold a ready-to-code Arduino (.ino + .S) + Wokwi project (macOS).
#
# A project is an Arduino sketch folder: <Name>/<Name>.ino plus assembly in .S files.
# Composes:  common/base (shared boilerplate) + a template + the macOS overlay.
#
# Template selection is CURATED BY NAME: if the project name matches a folder in
# common/templates (case-insensitive, e.g. Lab3 -> templates/Lab3), that template is used
# -- so a known lab comes up with its own .ino + .S starter and canonical diagram.json.
# Any other name falls back to the default 'blinky' template. The main starter .ino is
# renamed to match the folder (Arduino requires the main sketch file to share its name).
#
# Usage:
#   ./macos/new-avr-project.sh Lab3          # -> Lab3 template (body-fat monitor)
#   ./macos/new-avr-project.sh MyThing       # -> blinky (default)
#   ./macos/new-avr-project.sh Lab3 --open
#   ./macos/new-avr-project.sh Homework3 ~/school
set -euo pipefail

NAME=""; DEST_PARENT=""; OPEN=0
for a in "$@"; do
  case "$a" in
    --open) OPEN=1 ;;
    *) if [ -z "$NAME" ]; then NAME="$a"; elif [ -z "$DEST_PARENT" ]; then DEST_PARENT="$a"; fi ;;
  esac
done
if [ -z "$NAME" ]; then echo "usage: new-avr-project.sh <name> [dest-parent] [--open]" >&2; exit 1; fi
DEST_PARENT="${DEST_PARENT:-$HOME/Documents/Arduino}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
BASE="$REPO/common/base"
TEMPLATES="$REPO/common/templates"
OVERLAY="$SCRIPT_DIR/template-overlay"
for p in "$BASE" "$TEMPLATES" "$OVERLAY"; do
  [ -d "$p" ] || { echo "template part not found: $p" >&2; exit 1; }
done

# Pick the template by name (case-insensitive); fall back to 'blinky'.
lc() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
TPL=""
for d in "$TEMPLATES"/*/; do
  [ -d "$d" ] || continue
  [ "$(lc "$(basename "$d")")" = "$(lc "$NAME")" ] && { TPL="$d"; break; }
done
MATCHED=1
if [ -z "$TPL" ]; then TPL="$TEMPLATES/blinky/"; MATCHED=0; fi
[ -d "$TPL" ] || { echo "template not found: $TPL" >&2; exit 1; }

DEST="$DEST_PARENT/$NAME"
[ -e "$DEST" ] && { echo "destination already exists: $DEST" >&2; exit 1; }
mkdir -p "$DEST"
cp -R "$BASE/." "$DEST/"
cp -R "$TPL." "$DEST/"
cp -R "$OVERLAY/." "$DEST/"

# Arduino requires the main .ino to match the folder name: rename the single root .ino.
ino="$(find "$DEST" -maxdepth 1 -name '*.ino' | head -n1)"
[ -n "$ino" ] && [ "$(basename "$ino" .ino)" != "$NAME" ] && mv "$ino" "$DEST/$NAME.ino"
chmod +x "$DEST/build.sh" 2>/dev/null || true

if [ "$MATCHED" = 1 ]; then echo "Template '$(basename "$TPL")' matched by name -> circuit + starter files installed."
else echo "No template named '$NAME' -> used default 'blinky'."; fi
echo "Created Arduino+asm project -> $DEST"
echo "Next: 1) code \"$DEST\"   2) Ctrl+Shift+B   3) open diagram.json (Wokwi)"
if [ "$OPEN" = 1 ] && command -v code >/dev/null 2>&1; then code "$DEST"; fi
