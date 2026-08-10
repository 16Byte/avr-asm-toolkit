# AVR Arduino + assembly (ATmega328P) — Wokwi project

An Arduino sketch (`<Name>.ino`) that calls AVR **assembly** in `.S` files (GNU / avr-gcc
syntax), compiled with `arduino-cli`, simulated in Wokwi. This is the structure the course
labs use.

## Build
- VS Code: **Ctrl+Shift+B**
- Terminal: `.\build.ps1` (Windows) or `./build.sh` (macOS)

Output: `build/firmware.hex` (+ `build/firmware.elf`).

## Run in Wokwi
1. Install the **Wokwi Simulator** extension in VS Code (one-time).
2. **Get a free license:** F1 → **`Wokwi: Request a new License`** (re-run it when the key lapses).
3. **Build** first: **Ctrl+Shift+B**.
4. **Open `diagram.json`** — that file *is* the Wokwi simulation; press the green **play** button.

Needs an internet connection (offline mode: https://docs.wokwi.com/vscode/offline-mode). The
free key lasts ~30 days; builds show a non-blocking reminder near expiry — renew (same F1
command) and run `reset-wokwi-license` (or edit `wokwi-license-stamp`) to reset it.

## Files
```
<Name>.ino    Arduino sketch — drives the program; calls the .S
<Name>.S      AVR assembly (sbi/cbi ...) the .ino calls (e.g. blink.S, FatMonitor.S)
wokwi.toml    points Wokwi at build/firmware.hex + .elf
diagram.json  virtual board + wiring
build.ps1 / build.sh   arduino-cli compile -> build/firmware.hex
.vscode/tasks.json     Ctrl+Shift+B build task
```

## Changing the circuit
Three free ways (only the first needs Claude Code):
- **Claude Code** — ask it; the `wokwi-diagram` skill edits `diagram.json` with correct pin
  names for the ELEGOO UNO R3 kit parts.
- **Free web editor** — build it at https://wokwi.com, then copy its `diagram.json` here.
- **Hand-edit `diagram.json`** — plain JSON; see the skill's `references/parts.md` for pin names.

A **paid Wokwi license** also unlocks the graphical diagram editor inside VS Code.

## For a lab
If you scaffolded with a lab's name (e.g. `Lab3`), its starter `.ino` + `.S` and pre-wired
`diagram.json` are already here — plus `LAB.md` / `pinouts.md` / `NOTES.md` for reference.
Do the graded work in the `.S`; submit the `.ino` + `.S` the lab asks for.
