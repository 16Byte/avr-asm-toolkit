#!/usr/bin/env bash
# new-avr-project.sh - scaffold a ready-to-code AVR assembly + Wokwi project (macOS).
#
# Composes a project from the shared template (common/template) plus the macOS
# overlay (build.sh + .vscode task).
#
# Usage:
#   ./macos/new-avr-project.sh Lab1
#   ./macos/new-avr-project.sh Lab2 --open
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
DEST_PARENT="${DEST_PARENT:-$HOME/Documents/PlatformIO/Projects}"

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
cp -R "$COMMON/." "$DEST/"     # shared: src/main.asm, wokwi.toml, diagram.json, CLAUDE.md, README, .gitignore
cp -R "$OVERLAY/." "$DEST/"    # macOS: build.sh, .vscode/tasks.json
chmod +x "$DEST/build.sh" 2>/dev/null || true

echo "Created AVR asm project -> $DEST"
echo "Next: 1) code \"$DEST\"   2) Ctrl+Shift+B   3) 'Wokwi: Start Simulator'"
if [ "$OPEN" = 1 ] && command -v code >/dev/null 2>&1; then code "$DEST"; fi
