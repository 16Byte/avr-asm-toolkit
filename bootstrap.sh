#!/usr/bin/env bash
# bootstrap.sh - set up the AVR (Arduino .ino + .S) toolkit on macOS.
#
# 1. Download arduino-cli into the runtime dir.
# 2. Install the arduino:avr core (avr-gcc + Uno core) into a contained data dir,
#    so it never clobbers a system Arduino IDE setup.
# 3. Download a contained wokwi-cli (headless sim: screenshots/run/lint); using it
#    needs a WOKWI_CLI_TOKEN that YOU set (never this script) - see the final note.
# 4. Install the wokwi-diagram skill into ~/.claude/skills.
# 5. Start the Wokwi license clock.
# 6. Smoke-test: compile the template sketch.
#
# Needs internet on first run (arduino-cli + core download).
# The skill is symlinked by default, so a later 'git pull' updates it with no re-copy.
# Option: --copy  install an independent copy instead of a symlink.
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
# Pin the core version so the IntelliSense paths in template/.vscode stay valid.
"$CLI" --config-file "$CFG" core install arduino:avr@1.8.8

# persist AVR_TOOLKIT_HOME
ZP="$HOME/.zprofile"
if ! grep -qF "AVR_TOOLKIT_HOME=" "$ZP" 2>/dev/null; then
  echo "export AVR_TOOLKIT_HOME=\"$RUNTIME\"" >> "$ZP"
fi
export AVR_TOOLKIT_HOME="$RUNTIME"
echo "AVR_TOOLKIT_HOME = $RUNTIME  (added to ~/.zprofile)"

# point AVR_TOOLKIT_PY at the system python3 (macOS ships one; the wokwi-diagram
# helper is pure stdlib, so no venv/pip is needed). Kept as a var for parity with
# Windows, where bootstrap installs a contained Python.
PY3="$(command -v python3 || true)"
if [ -n "$PY3" ]; then
  if ! grep -qF "AVR_TOOLKIT_PY=" "$ZP" 2>/dev/null; then
    echo "export AVR_TOOLKIT_PY=\"$PY3\"" >> "$ZP"
  fi
  export AVR_TOOLKIT_PY="$PY3"
  echo "AVR_TOOLKIT_PY = $PY3"
else
  echo "WARNING: python3 not found - install it for the wokwi-diagram skill helper." >&2
fi

# contained wokwi-cli (headless sim: screenshots/run/lint). Using it needs a
# WOKWI_CLI_TOKEN that YOU set (never this script) - see the note at the end.
WOK_DIR="$RUNTIME/wokwi-cli"
WOK="$WOK_DIR/wokwi-cli"
if [ ! -x "$WOK" ]; then
  echo "Downloading wokwi-cli..."
  mkdir -p "$WOK_DIR"
  arch="$(uname -m)"; asset="wokwi-cli-macos-arm64"
  [ "$arch" = "x86_64" ] && asset="wokwi-cli-macos-x64"
  curl -fsSL "https://github.com/wokwi/wokwi-cli/releases/latest/download/$asset" -o "$WOK"
  chmod +x "$WOK"
  xattr -d com.apple.quarantine "$WOK" 2>/dev/null || true
fi
echo "wokwi-cli -> $WOK"

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
if [ "${1:-}" = "--copy" ]; then
  rm -rf "$SKILL_DST"; mkdir -p "$SKILL_DST"; cp -R "$SKILL_SRC/." "$SKILL_DST/"; echo "Skill copied -> $SKILL_DST"
else
  # default: symlink so 'git pull' updates the skill live
  rm -rf "$SKILL_DST"; ln -s "$SKILL_SRC" "$SKILL_DST"; echo "Skill symlinked -> $SKILL_DST  (git pull keeps it current)"
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

# wokwi-cli smoke test (no token needed for --help)
if "$WOK" --help >/dev/null 2>&1; then echo "wokwi-cli smoke test OK."; else echo "wokwi-cli smoke test FAILED." >&2; exit 1; fi

echo ""
echo "Done. Open a new terminal (or 'source ~/.zprofile'), then:"
echo "  ./macos/new-avr-project.sh Lab5 --open"
echo ""
echo "wokwi-cli features (screenshots/run/lint) need a free API token:"
echo "  1) get one at https://wokwi.com/dashboard/ci  (starts 'wok_')"
echo "  2) persist it yourself, e.g. add to ~/.zprofile:"
echo "       export WOKWI_CLI_TOKEN=wok_..."
echo "  Never commit or share the token."
