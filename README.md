# avr-asm-toolkit

A portable, one-command setup for practicing **ATmega328P assembly** in **AVRASM2
syntax** (the Microchip Studio / Mazidi-textbook dialect), assembled with
[`avra`](https://github.com/Ro5bert/avra) and run in the **Wokwi** simulator — so
you can write real assembly and watch it drive a virtual Arduino Uno **without any
hardware, Microchip Studio, or a Windows-only toolchain**. Works on Windows and
macOS (Apple Silicon included).

It's also wired for **Claude Code**: every project it generates carries a
`CLAUDE.md`, and it installs a small skill for editing the circuit — so you can ask
Claude to help you build an assignment *and explain it as you go* (more below).

> **Heads up:** this is an unofficial, student-made convenience tool — **not**
> affiliated with or endorsed by any university, course, instructor, or textbook.
> It just glues together open-source pieces. Provided as-is. Please skim
> [CREDITS.md](CREDITS.md), including the note on using AI help responsibly on
> coursework.

## Quick start

**Windows** (PowerShell)
```powershell
git clone https://github.com/16Byte/avr-asm-toolkit.git $env:USERPROFILE\avr-asm-toolkit
cd $env:USERPROFILE\avr-asm-toolkit
.\bootstrap.ps1
.\windows\New-AvrProject.ps1 Lab1 -Open
```

**macOS (Apple Silicon)**
```bash
git clone https://github.com/16Byte/avr-asm-toolkit.git ~/avr-asm-toolkit
cd ~/avr-asm-toolkit
bash bootstrap.sh
bash macos/new-avr-project.sh Lab1 --open
```

> **macOS note:** on **Apple Silicon** the committed avra binary is used as-is — no
> compiler needed. On an **Intel Mac** (or if bootstrap reports it can't run avra),
> run `xcode-select --install`, then `bash bootstrap.sh` again to build it from source.

In the generated project: **Ctrl+Shift+B** builds `build/firmware.hex`, then run
**Wokwi: Start Simulator** (install the **Wokwi** VS Code extension first).

## How it's meant to be used — learning with Claude Code
The point isn't to have code written *for* you; it's to have a tutor that never
gets tired. Open a generated project in VS Code with **Claude Code** and try things
like:

- *"Here's this week's assignment: <paste it>. Help me write it in AVRASM2 in
  `src/main.asm`, and explain each new instruction as we go."*
- *"Why do we set the stack pointer to RAMEND before using `rcall`?"*
- *"Add a push button on pin 2 that pauses the blink, and walk me through the
  `sbis`/`PIND` logic."*
- *"Change the circuit: put an LED on pin 8 with a resistor"* — Claude edits
  `diagram.json` for you via the bundled **`wokwi-diagram`** skill, with correct
  pin names for the ELEGOO UNO R3 kit parts.

Because each project ships a `CLAUDE.md`, Claude already knows this is an avra /
AVRASM2 / Wokwi project (not Arduino) and builds/wires things the right way. Use it
to *understand* — then make sure the work you submit is genuinely your own.

## What bootstrap does
1. Ensures the `avra` binary exists (uses the committed one; builds from the
   vendored source only if missing).
2. Assembles `.runtime/avra/` (binary + device `includes/`) and persists
   **`AVRA_HOME`** to it — how every project finds avra, with no hardcoded paths.
3. Installs the **`wokwi-diagram`** skill into `~/.claude/skills`.
4. Smoke-tests a build of the template blink.

## Repo map
```
common/                     shared across OSes
  avra/includes/            device definition .inc files
  build-avra/avra-src/      vendored avra source (+ COPYING) — offline rebuildable
  build-avra/compat/        unistd.h shim (Windows/MSVC build only)
  skill/wokwi-diagram/      the diagram.json editing skill
  template/                 shared project files (src/main.asm, wokwi.toml,
                            diagram.json, CLAUDE.md, README, .gitignore)
windows/                    avra.exe, New-AvrProject.ps1, build.ps1 overlay,
                            build-avra/build_avra.bat (MSVC fallback)
macos/                      avra (arm64), *.sh scripts, build_avra.sh (clang)
bootstrap.ps1 / bootstrap.sh
```

## Prerequisites (not auto-installed)
- **VS Code + the Wokwi extension** — the simulator.
- **Git** — to clone.
- **Claude Code** — the AI tutor/pair-programmer (optional but the whole point).
- **Python 3** (optional) — only for the `wokwi-diagram` skill's helper
  (`py -3` on Windows, `python3` on macOS).
- **macOS only, and only as a fallback:** Xcode Command Line Tools. Apple-Silicon
  clones use the committed `macos/avra/avra` (arm64) as-is — no compiler needed. You
  only need Xcode CLT on an Intel Mac, or to rebuild the binary yourself.

## Rebuilding avra
Prebuilt binaries are committed for instant restore, but the source
(`common/build-avra/avra-src`) plus per-OS build scripts are included, so a binary
can always be regenerated offline.

## License & credits
This project's own files are MIT-licensed ([LICENSE](LICENSE)). It bundles **avra**
(GNU GPL v2, © The AVRA Authors) and its device includes. Full attribution and the
responsible-use note are in [CREDITS.md](CREDITS.md).
