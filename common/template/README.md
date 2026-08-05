# AVR Assembly (ATmega328P) — Wokwi project

Bare-metal AVR **assembly** in **AVRASM2 syntax** (Mazidi textbook / Microchip
Studio dialect), assembled with [`avra`] and emulated in **Wokwi**.

## Build
- VS Code: **Ctrl+Shift+B**
- Terminal: `.\build.ps1` (Windows) or `./build.sh` (macOS)

Output: `build/firmware.hex`.

## Run in Wokwi
Build first, then run **Wokwi: Start Simulator** (or open `diagram.json`).

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
