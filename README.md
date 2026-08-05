# avr-asm-toolkit

A portable, "nuke-proof" toolchain for **ATmega328P assembly** in **AVRASM2
syntax** (Mazidi textbook / Microchip Studio dialect), assembled with
[`avra`](https://github.com/Ro5bert/avra) and emulated in **Wokwi**. Clone it on
any machine, run one bootstrap script, and you're ready to write assembly and
simulate — no Microchip Studio, no Arduino framework, no PlatformIO build.

Built for CS 2230 / CS 4993 (Assembly Language / Machine Organization) and the
ELEGOO UNO R3 Super Starter Kit.

## Quick start

**Windows**
```powershell
git clone <this-repo-url> $env:USERPROFILE\avr-asm-toolkit
cd $env:USERPROFILE\avr-asm-toolkit
.\bootstrap.ps1
# new terminal, then:
.\windows\New-AvrProject.ps1 Lab1 -Open
```

**macOS (Apple Silicon)**
```bash
git clone <this-repo-url> ~/avr-asm-toolkit
cd ~/avr-asm-toolkit
# first time on a Mac you need the compiler: xcode-select --install
./bootstrap.sh
# new terminal (or: source ~/.zprofile), then:
./macos/new-avr-project.sh Lab1 --open
```

In a scaffolded project: **Ctrl+Shift+B** builds `build/firmware.hex`; then run
**Wokwi: Start Simulator** (VS Code + the Wokwi extension).

## What bootstrap does
1. Ensures the `avra` binary exists (uses the committed one; builds from the
   vendored source only if missing).
2. Assembles `.runtime/avra/` (binary + device `includes/`) and persists
   **`AVRA_HOME`** to it — this is how every project locates avra, with no
   hardcoded paths.
3. Installs the **`wokwi-diagram`** skill into `~/.claude/skills` (edit
   `diagram.json` circuits in code; see that skill's README).
4. Smoke-tests a build of the template blink.

## Repo map
```
common/                     shared across OSes
  avra/includes/            78 device definition .inc files
  build-avra/avra-src/      vendored avra source (offline rebuildable)
  build-avra/compat/        unistd.h shim (Windows/MSVC build only)
  skill/wokwi-diagram/      the diagram.json editing skill
  template/                 shared project files (src/main.asm, wokwi.toml,
                            diagram.json, CLAUDE.md, README, .gitignore)
windows/                    avra.exe, New-AvrProject.ps1, build.ps1 overlay,
                            build-avra/build_avra.bat (MSVC fallback)
macos/                      avra (arm64, built on first Mac setup), *.sh scripts,
                            build-avra/build_avra.sh (clang)
bootstrap.ps1 / bootstrap.sh
```

## Prerequisites a fresh machine still needs
Not auto-installed (documented so a wipe is predictable):
- **VS Code + the Wokwi extension** — the emulator.
- **Git** — to clone.
- **Python 3** (optional) — only for the `wokwi-diagram` skill's helper script.
- **macOS only:** Xcode Command Line Tools, to build the `avra` binary the first
  time. After that first build, commit `macos/avra/avra` so future Mac clones are
  instant:
  ```bash
  git add -f macos/avra/avra && git commit -m "macOS avra binary (arm64)"
  ```

## Rebuilding avra
The prebuilt binaries are committed for instant restore, but the source
(`common/build-avra/avra-src`, pinned to Ro5bert/avra @ c78607c) plus per-OS
build scripts are included, so a binary can always be regenerated offline.
