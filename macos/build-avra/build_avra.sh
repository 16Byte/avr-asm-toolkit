#!/usr/bin/env bash
# build_avra.sh - build the avra assembler from vendored source on macOS.
#
# Produces macos/avra/avra (native, arm64 on Apple Silicon). Run this once on a
# fresh Mac, then commit the resulting binary so future clones are instant.
# Requires the Xcode Command Line Tools (clang):  xcode-select --install
#
# macOS has <unistd.h>, so unlike the Windows build no compat shim is needed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"
SRC="$REPO/common/build-avra/avra-src"
OUT="$REPO/macos/avra/avra"

if ! command -v cc >/dev/null 2>&1; then
  echo "ERROR: no C compiler (cc/clang). Install Xcode CLT: xcode-select --install" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"
echo "Building avra with cc (clang) from $SRC ..."
cc -O2 -o "$OUT" "$SRC"/*.c
chmod +x "$OUT"
echo "Built $OUT"
"$OUT" --version 2>/dev/null | head -1 || true
echo "Now commit it:  git add -f macos/avra/avra && git commit -m 'macOS avra binary'"
