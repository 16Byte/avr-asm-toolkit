# AVR assembly project (ATmega328P) — notes for Claude

Bare-metal AVR **assembly** in **AVRASM2 syntax** (Mazidi textbook / Microchip
Studio dialect), assembled with `avra` and emulated in **Wokwi**.
This is **not** an Arduino or PlatformIO project — don't add a framework or
`platformio.ini`, and don't build with avr-gcc/`.S` GNU syntax.

## Build
Run the build script (**Ctrl+Shift+B** in VS Code): `build.ps1` on Windows,
`./build.sh` on macOS. It assembles `src/main.asm` → `build/firmware.hex`.
Toolchain: `avra`, located via the `AVRA_HOME` env var (set once per machine by
the toolkit's bootstrap). The PRAGMA/AVRPART notes avra prints are harmless.

## Run
Wokwi loads `build/firmware.hex` (see `wokwi.toml`) together with `diagram.json`.
avra emits HEX only (no ELF), so there's no source-level debug — the sim itself
works fully.

## Editing the circuit (diagram.json)
Use the **`wokwi-diagram`** skill. Run its Python helper with a real Python 3
(`py -3` on Windows, `python3` on macOS) — avoid the bare `python` on Windows,
which is often the Microsoft Store stub and fails. Always `validate` after edits,
and keep the wiring in sync with the pins the assembly uses.

## Assembly conventions
- Program starts at `RESET`; set up the stack (`SP = RAMEND`) first — no C runtime.
- Default example: LED on PB5 (Arduino D13). If you move a pin in code, update
  `diagram.json` to match (and vice-versa).
- New multi-file programs: keep `src/main.asm` as the entry and `.include` others.
