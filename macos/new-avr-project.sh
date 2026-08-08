#!/usr/bin/env bash
# new-avr-project.sh - scaffold a ready-to-code Arduino (.ino + .S) + Wokwi project (macOS).
#
# A project is an Arduino sketch folder: <Name>/<Name>.ino plus assembly in .S files.
# Composes the shared template + the macOS overlay, and renames the starter .ino to
# match the folder (Arduino requires the main sketch file to share the folder's name).
#
# For a lab: scaffold with the lab's name, then replace the starter .ino/.S with the
# lab's provided files (e.g. Lab5.ino + push_button.S).
#
# Usage:
#   ./macos/new-avr-project.sh Lab5
#   ./macos/new-avr-project.sh Lab5 --open
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
COMMON="$REPO/common/template"
OVERLAY="$SCRIPT_DIR/template-overlay"
for p in "$COMMON" "$OVERLAY"; do
  [ -d "$p" ] || { echo "template part not found: $p" >&2; exit 1; }
done

DEST="$DEST_PARENT/$NAME"
[ -e "$DEST" ] && { echo "destination already exists: $DEST" >&2; exit 1; }
mkdir -p "$DEST"
cp -R "$COMMON/." "$DEST/"
cp -R "$OVERLAY/." "$DEST/"
[ -f "$DEST/template.ino" ] && mv "$DEST/template.ino" "$DEST/$NAME.ino"
chmod +x "$DEST/build.sh" 2>/dev/null || true

echo "Created Arduino+asm project -> $DEST"
echo "Next: 1) code \"$DEST\"   2) Ctrl+Shift+B   3) open diagram.json (Wokwi)"
if [ "$OPEN" = 1 ] && command -v code >/dev/null 2>&1; then code "$DEST"; fi
