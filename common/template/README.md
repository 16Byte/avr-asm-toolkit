# AVR Assembly (ATmega328P) — Wokwi project

Bare-metal AVR **assembly** in **AVRASM2 syntax** (Mazidi textbook / Microchip
Studio dialect), assembled with [`avra`] and emulated in **Wokwi**.

## Build
- VS Code: **Ctrl+Shift+B**
- Terminal: `.\build.ps1` (Windows) or `./build.sh` (macOS)

Output: `build/firmware.hex`.

## Run in Wokwi
1. Install the **Wokwi Simulator** extension in VS Code (one-time).
2. **Get a free license:** F1 → **`Wokwi: Request a new License`** (free for personal
   use; re-run it when the key lapses).
3. **Build** first: **Ctrl+Shift+B** (creates `build/firmware.hex`).
4. **Open `diagram.json`** — that file *is* the Wokwi simulation (the virtual
   Arduino + wiring). Opening it launches the simulator; press the green **play**
   button to start. The LED should blink.

Rebuild (Ctrl+Shift+B) and restart the simulation after each change to your assembly.
The simulator needs an internet connection (offline mode:
https://docs.wokwi.com/vscode/offline-mode).

The free Wokwi key lasts ~30 days. Builds show a gentle, non-blocking reminder near expiry;
when it lapses, renew (same F1 command) and run `reset-wokwi-license` (or edit the
`wokwi-license-stamp` file) so the reminder resets.

## Changing the circuit
Three ways, only the first needs Claude Code:
- **Claude Code** — ask it; the `wokwi-diagram` skill edits `diagram.json` with correct
  pin names for the ELEGOO UNO R3 kit parts.
- **Free web editor** — build it at https://wokwi.com, then copy its `diagram.json` here.
- **Hand-edit `diagram.json`** — plain JSON; see the skill's `references/parts.md` for pin
  names.

The three above are free. If you buy a **paid Wokwi license**, the graphical diagram editor
inside VS Code is unlocked too — same thing, just in-editor.

## Files
```
src/main.asm        your assembly (edit this)
build.ps1 / build.sh  assembles src/main.asm -> build/firmware.hex
wokwi.toml          points Wokwi at the hex
diagram.json        virtual board + wiring
.vscode/tasks.json  Ctrl+Shift+B build task
```

The `avra` toolchain (binary + device `includes/`) is located via the `AVRA_HOME`
environment variable, set once per machine by the toolkit's bootstrap script.

[`avra`]: https://github.com/Ro5bert/avra
