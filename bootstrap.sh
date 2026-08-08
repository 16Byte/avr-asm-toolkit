#!/usr/bin/env bash
# bootstrap.sh - set up the AVR (Arduino .ino + .S) toolkit on macOS.
#
# 1. Download arduino-cli into the runtime dir.
# 2. Install the arduino:avr core (avr-gcc + Uno core) into a contained data dir,
#    so it never clobbers a system Arduino IDE setup.
# 3. Install the wokwi-diagram skill into ~/.claude/skills.
# 4. Start the Wokwi license clock.
# 5. Smoke-test: compile the template sketch.
#
# Needs internet on first run (arduino-cli + core download).
# Option: --link  install the skill as a symlink (repo edits reflect live).
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "AVR toolkit repo: $REPO"

RUNTIME="$HOME/.local/share/avr-asm-toolkit"
ACLI_DIR="$RUNTIME/acli"
DATA_DIR="$RUNTIME/adata"
mkdir -p "$ACLI_DIR" "$DATA_DIR"
CLI="$ACLI_DIR/arduino-cli"
CFG="$ACLI_DIR/arduino-cli.yaml"

# arduino-cli binary (Apple Silicon)
if [ ! -x "$CLI" ]; then
  echo "Downloading arduino-cli..."
  tgz="$(mktemp -t acli).tgz"
  curl -fsSL "https://downloads.arduino.cc/arduino-cli/arduino-cli_latest_macOS_ARM64.tar.gz" -o "$tgz"
  tar -xzf "$tgz" -C "$ACLI_DIR" arduino-cli
  chmod +x "$CLI"
  xattr -d com.apple.quarantine "$CLI" 2>/dev/null || true
  rm -f "$tgz"
fi

# contained config: keep cores/toolchain under our own data dir
cat > "$CFG" <<EOF
directories:
  data: '$DATA_DIR'
  downloads: '$DATA_DIR/staging'
  user: '$DATA_DIR/user'
EOF

echo "Installing arduino:avr core (one-time download)..."
"$CLI" --config-file "$CFG" core update-index
"$CLI" --config-file "$CFG" core install arduino:avr

# persist AVR_TOOLKIT_HOME
ZP="$HOME/.zprofile"
if ! grep -qF "AVR_TOOLKIT_HOME=" "$ZP" 2>/dev/null; then
  echo "export AVR_TOOLKIT_HOME=\"$RUNTIME\"" >> "$ZP"
fi
export AVR_TOOLKIT_HOME="$RUNTIME"
echo "AVR_TOOLKIT_HOME = $RUNTIME  (added to ~/.zprofile)"

# license stamp (don't clobber an existing one)
STAMP="$RUNTIME/wokwi-license-stamp"
if [ ! -f "$STAMP" ]; then
  TODAY="$(date +%Y-%m-%d)"
  {
    echo "# avr-asm-toolkit wokwi license stamp"
    echo "# Date the Wokwi VS Code license was last activated/renewed (YYYY-MM-DD)."
    echo "# Edit by hand if it drifts, or run macos/reset-wokwi-license.sh after you renew."
    echo "activated=$TODAY"
  } > "$STAMP"
  echo "License stamp started ($TODAY)."
fi

# install the wokwi-diagram skill
SKILL_SRC="$REPO/common/skill/wokwi-diagram"
SKILL_DST="$HOME/.claude/skills/wokwi-diagram"
mkdir -p "$HOME/.claude/skills"
if [ "${1:-}" = "--link" ]; then
  rm -rf "$SKILL_DST"; ln -s "$SKILL_SRC" "$SKILL_DST"; echo "Skill symlink -> $SKILL_DST"
else
  mkdir -p "$SKILL_DST"; cp -R "$SKILL_SRC/." "$SKILL_DST/"; echo "Skill copied -> $SKILL_DST"
fi

# smoke test: compile the template sketch
TMP="$(mktemp -d)"
if "$CLI" --config-file "$CFG" compile --fqbn arduino:avr:uno --output-dir "$TMP" "$REPO/common/template" >/dev/null 2>&1 \
   && ls "$TMP"/*.ino.hex >/dev/null 2>&1; then
  echo "Smoke test OK - template sketch compiled."
else
  echo "Smoke test FAILED." >&2; rm -rf "$TMP"; exit 1
fi
rm -rf "$TMP"

echo ""
echo "Done. Open a new terminal (or 'source ~/.zprofile'), then:"
echo "  ./macos/new-avr-project.sh Lab5 --open"
