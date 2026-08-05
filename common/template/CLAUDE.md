# AVR assembly project (ATmega328P) — notes for Claude

Bare-metal AVR **assembly** in **AVRASM2 syntax** (Mazidi textbook / Microchip
Studio dialect), assembled with `avra` and emulated in **Wokwi**.
This is **not** an Arduino or PlatformIO project — don't add a framework or
`platformio.ini`, and don't build with avr-gcc/`.S` GNU syntax.

## Build
Run the build script from the project root: **`./build.sh`** on macOS or
**`.\build.ps1`** on Windows (also bound to **Ctrl+Shift+B**). It assembles
`src/main.asm` → `build/firmware.hex`.

The script already knows where `avra` is — the standard per-user path the toolkit's
bootstrap installed it to — so just run it. **Do NOT search the filesystem for the
`avra` binary** (no `find`, no scanning home folders — on macOS that triggers a
cascade of scary permission prompts). If the script says avra is missing, the
toolkit bootstrap simply hasn't been run on this machine yet; run that once instead.
The PRAGMA/AVRPART notes avra prints while assembling are harmless.

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
