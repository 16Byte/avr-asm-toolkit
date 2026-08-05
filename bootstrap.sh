#!/usr/bin/env bash
# bootstrap.sh - set up the AVR-assembly toolkit on a macOS machine.
#
# What it does:
#   1. Ensures the avra binary exists (uses the committed macos/avra/avra; builds
#      from source with clang if missing -- needs Xcode Command Line Tools).
#   2. Assembles a runtime folder (.runtime/avra = avra + device includes) and
#      persists AVRA_HOME to it in ~/.zprofile.
#   3. Installs the wokwi-diagram skill into ~/.claude/skills.
#   4. Smoke-tests a build of the template blink.
#
# Option:  --link   install the skill as a symlink (repo edits reflect live)
#
# Prereqs not installed here: VS Code + the Wokwi extension (emulation), Git,
# python3 (only for the wokwi-diagram skill's helper).
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "AVR toolkit repo: $REPO"

# 1) avra binary --------------------------------------------------------------
AVRA_BIN="$REPO/macos/avra/avra"
if [ ! -x "$AVRA_BIN" ]; then
  echo "macOS avra binary missing - building from source..."
  bash "$REPO/macos/build-avra/build_avra.sh"
fi
xattr -d com.apple.quarantine "$AVRA_BIN" 2>/dev/null || true
chmod +x "$AVRA_BIN"

# 2) runtime folder + AVRA_HOME ----------------------------------------------
# Standard per-user install path (NOT inside the repo) so the build scripts can
# default to it without needing AVRA_HOME in the environment.
RUNTIME="$HOME/.local/share/avr-asm-toolkit/avra"
mkdir -p "$RUNTIME/includes"
cp "$AVRA_BIN" "$RUNTIME/avra"
cp "$REPO/common/avra/includes/"*.inc "$RUNTIME/includes/"
ZP="$HOME/.zprofile"
if ! grep -qF "AVRA_HOME=" "$ZP" 2>/dev/null; then
  echo "export AVRA_HOME=\"$RUNTIME\"" >> "$ZP"
fi
export AVRA_HOME="$RUNTIME"
echo "AVRA_HOME = $RUNTIME  (added to ~/.zprofile)"

# 3) install the wokwi-diagram skill -----------------------------------------
SKILL_SRC="$REPO/common/skill/wokwi-diagram"
SKILL_DST="$HOME/.claude/skills/wokwi-diagram"
mkdir -p "$HOME/.claude/skills"
if [ "${1:-}" = "--link" ]; then
  rm -rf "$SKILL_DST"
  ln -s "$SKILL_SRC" "$SKILL_DST"
  echo "Skill symlink -> $SKILL_DST"
else
  mkdir -p "$SKILL_DST"
  cp -R "$SKILL_SRC/." "$SKILL_DST/"
  echo "Skill copied -> $SKILL_DST"
fi

# 4) smoke test ---------------------------------------------------------------
TMP="$(mktemp -d)"
if "$RUNTIME/avra" -I "$RUNTIME/includes" -o "$TMP/fw.hex" -e "$TMP/fw.eep.hex" -d "$TMP/fw.obj" "$REPO/common/template/src/main.asm" >/dev/null 2>&1 \
   && [ -f "$TMP/fw.hex" ]; then
  echo "Smoke test OK - template blink assembled."
else
  echo "Smoke test FAILED." >&2; rm -rf "$TMP"; exit 1
fi
rm -rf "$TMP"

echo ""
echo "Done. Open a new terminal (or 'source ~/.zprofile'), then:"
echo "  ./macos/new-avr-project.sh Lab1 --open"
