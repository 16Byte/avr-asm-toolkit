# AVR Assembly (ATmega328P) — Wokwi project

Bare-metal AVR **assembly** in **AVRASM2 syntax** (Mazidi textbook / Microchip
Studio dialect), assembled with [`avra`] and emulated in **Wokwi**.

## Build
- VS Code: **Ctrl+Shift+B**
- Terminal: `.\build.ps1` (Windows) or `./build.sh` (macOS)

Output: `build/firmware.hex`.

## Run in Wokwi
1. Install the **Wokwi Simulator** extension in VS Code (one-time) — the simulation
   won't run without it.
2. **Build** first: **Ctrl+Shift+B** (creates `build/firmware.hex`).
3. **Open `diagram.json`** — that file *is* the Wokwi simulation (the virtual
   Arduino + wiring). Opening it launches the simulator; press the green **play**
   button to start. The LED should blink.

Rebuild (Ctrl+Shift+B) and restart the simulation after each change to your assembly.

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
