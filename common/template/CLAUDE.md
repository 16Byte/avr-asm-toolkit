# AVR project (ATmega328P) — Arduino `.ino` + `.S` — notes for Claude

This is an **Arduino sketch** that does its real work in **AVR assembly** (`.S` files,
GNU / avr-gcc syntax), compiled with **arduino-cli** and simulated in **Wokwi**. This
matches the course labs (an `.ino` plus a `.S`, e.g. `Lab5.ino` + `push_button.S`).
It is **not** AVRASM2/Microchip-Studio syntax, and **not** a PlatformIO project.

## Do the work in assembly — this is the point of the course
When asked to implement behavior (blink, read a button, drive a display, count,
debounce, …), put the actual logic in a **`.S` file** using AVR instructions
(`sbi`/`cbi`/`sbis`/`sbic`, branches, loops) and keep the **`.ino` as minimal glue** —
`setup()`/`loop()` that call `extern "C"` routines defined in the `.S`.

- Do **NOT** implement the task in C++ inside the `.ino`.
- Do **NOT** reach for Arduino libraries (LiquidCrystal, Servo, Wire, …) to do the
  work — that skips the exercise the course is grading.
- If something is genuinely impractical in pure assembly (e.g. a full LCD driver),
  **say so and propose the assembly approach** (or the minimal glue the lab expects)
  rather than silently writing it in C++.
- **Exception:** when a lab provides a skeleton `.ino` that already uses specific
  library/framework calls, follow the lab's structure and do the ToDo parts in the
  `.S` exactly as the lab directs.

When in doubt, ask which parts should be assembly vs. glue — don't default to the
easy C++ path.

## Build
Run the build script (**Ctrl+Shift+B**): `.\build.ps1` (Windows) / `./build.sh` (macOS).
It runs `arduino-cli compile --fqbn arduino:avr:uno` and normalizes the output to
`build/firmware.hex` + `build/firmware.elf`. arduino-cli is located via `AVR_TOOLKIT_HOME`
(set by the toolkit bootstrap); the script defaults to the standard install path, so just
run it. **Do NOT search the filesystem** for arduino-cli or a compiler — if the script says
it's missing, the toolkit bootstrap hasn't been run on this machine yet; run that instead.

## Run
Open `diagram.json` to launch Wokwi (needs the Wokwi VS Code extension + a free license).
`wokwi.toml` points at `build/firmware.hex` (+ `.elf`, so source-level debug works).

## Assembly conventions (avr-gcc / GNU `.S`)
- Assembly lives in `.S` files (capital S → the C preprocessor runs, so
  `#include <avr/io.h>` works). Use `_SFR_IO_ADDR(PORTB)` etc. for `in`/`out`/`sbi`/`cbi`.
- Expose routines with `.global name` … `name:` … `ret`, and call them from the `.ino`
  as `extern "C" void name(void);` (avr-gcc calling convention).
- The `.ino` uses the Arduino framework (`setup`/`loop`, `delay`, and `DDRB`/`PORTB`
  from `<avr/io.h>`). Practice the labs' instructions in the `.S`: `sbi`, `cbi`, `sbis`, `sbic`.

## Editing the circuit (diagram.json)
Use the **`wokwi-diagram`** skill. Run its Python helper with `py -3` (Windows) / `python3`
(macOS) — not the bare `python` on Windows. Always `validate` after edits; keep the wiring
in sync with the pins the code uses.

## For a lab
Replace `<Name>.ino` + `blink.S` with the lab's provided files (keep the `.ino` named to
match the folder). Submit the `.ino` + `.S` the lab asks for.
