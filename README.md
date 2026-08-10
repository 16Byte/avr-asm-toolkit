# avr-asm-toolkit — Arduino `.ino` + `.S` (lab-style)

> **Branches:** this is **`arduino-cli`** (the default) — the Arduino-sketch variant
> that matches how the course *labs* are written (an Arduino `.ino` plus GNU-syntax
> assembly in `.S`, compiled with `arduino-cli`). An **`avra`** branch holds the
> alternative "textbook" variant (standalone AVRASM2 assembled with `avra`).

A portable, one-command setup for the CSCI 2230 / CSCI 4555 labs: write AVR
**assembly in `.S` files** called from an **Arduino sketch**, compile with
**arduino-cli** (the real Arduino toolchain), and run it in the **Wokwi** simulator —
so you can do the labs **without hardware**. Works on Windows and macOS (Apple
Silicon included). Deliverables stay exactly what the labs ask for: your `.ino` + `.S`.

It's also wired for **Claude Code**: every project it generates carries a `CLAUDE.md`
and it installs a small skill for editing the circuit — so you can ask Claude to help
you build an assignment *and explain it as you go*. Everything — bootstrapping,
compiling, simulating, and editing circuits — works **without** Claude Code; it's an
optional AI tutor layered on a plain arduino-cli + Wokwi setup, not the product itself.

> **Heads up:** this is an unofficial, student-made convenience tool — **not**
> affiliated with or endorsed by any university, course, instructor, or textbook.
> It glues together open-source pieces. Provided as-is. Please skim [CREDITS.md](CREDITS.md),
> including the note on using AI help responsibly on coursework.

## Quick start

**Windows** (PowerShell)
```powershell
git clone https://github.com/16Byte/avr-asm-toolkit.git $env:USERPROFILE\avr-asm-toolkit
cd $env:USERPROFILE\avr-asm-toolkit
.\bootstrap.ps1
.\windows\New-AvrProject.ps1 Lab5 -Open
```

**macOS (Apple Silicon)**
```bash
git clone https://github.com/16Byte/avr-asm-toolkit.git ~/avr-asm-toolkit
cd ~/avr-asm-toolkit
bash bootstrap.sh
bash macos/new-avr-project.sh Lab5 --open
```

> **First run needs internet:** bootstrap downloads `arduino-cli` and the `arduino:avr`
> core (which includes avr-gcc). No Xcode/Visual Studio needed — the core brings its
> own compiler.

## Prerequisites (not auto-installed)
- **VS Code + the Wokwi Simulator extension**, plus a **free Wokwi license key** — the
  simulator (getting the key is a step in "See the blink" below).
- **Git** — to clone.
- **Claude Code** — the AI tutor/pair-programmer (optional).
- **Python 3** — needed only by the `wokwi-diagram` skill's helper. On Windows
  **bootstrap installs a contained Python for you** and points `AVR_TOOLKIT_PY` at it
  (no system/Store/PlatformIO Python involved); on macOS the helper uses `python3`.

(arduino-cli, the AVR toolchain, and — on Windows — Python are downloaded by bootstrap;
you don't install them yourself.)

## See the blink
The generated project is an Arduino sketch: `<Name>.ino` (drives the program) + `blink.S`
(assembly it calls) + a ready circuit in `diagram.json` (an LED on pin 13). To run it:

1. **Install the Wokwi Simulator extension** in VS Code — Extensions panel, search
   **"Wokwi Simulator"**.
2. **Get a free license:** press **F1** and run **`Wokwi: Request a new License`**. Free
   for personal/open-source use; the key is time-limited, so re-run the same command when
   it lapses — a roughly monthly button press, not a paywall.
3. **Build:** press **Ctrl+Shift+B** (runs `arduino-cli` → `build/firmware.hex`).
4. **Open `diagram.json`** — that file *is* the Wokwi simulation; opening it launches the
   simulator view; press the green **play** button.

The on-board LED blinks. After any change to your code, rebuild (Ctrl+Shift+B) and
restart the simulation.

> The Wokwi simulator runs on Wokwi's servers, so it needs an internet connection. An
> offline mode exists — see [docs.wokwi.com/vscode/offline-mode](https://docs.wokwi.com/vscode/offline-mode).

## Doing a lab
The labs hand you files like `lab5_skeleton.ino` + `push_button.S`. Scaffold a project
named after the lab, then drop the lab's files in (keep the `.ino` named the same as the
folder, e.g. `Lab5/Lab5.ino`). Build with Ctrl+Shift+B, simulate in Wokwi, and submit the
`.ino` + `.S` the lab asks for. The starter `.ino`/`blink.S` show the exact structure.

## Editing the circuit
The starter circuit is a single LED on pin 13. Three free ways to change it (only the
first needs Claude Code):

1. **With Claude Code (fastest).** Describe the change in plain English — *"add a push
   button on pin 2 with a pull-up"* — and the bundled **`wokwi-diagram`** skill edits
   `diagram.json` with the correct part types and pin names. The skill knows the whole
   **ELEGOO UNO R3 kit** (LEDs, buttons, LCD1602, 7-segment, potentiometer, joystick,
   HC-SR04, DHT, servo, relay, 74HC595, photoresistor, thermistor…) — see
   [`common/skill/wokwi-diagram/references/parts.md`](common/skill/wokwi-diagram/references/parts.md).
2. **Free web editor.** Build the circuit visually at [wokwi.com](https://wokwi.com), then
   copy its `diagram.json` into your project.
3. **Hand-edit `diagram.json`** — plain JSON; use the pin/part names in the skill's
   [`parts.md`](common/skill/wokwi-diagram/references/parts.md).

Prefer editing graphically inside VS Code? A **paid Wokwi license** unlocks the built-in
diagram editor there.

## Use it to learn, not to cheat
Real talk: this makes it trivially easy to have Claude hand you a finished lab and move
on. Please don't — that's renting an answer, not learning. The whole point of an assembly
course is building a real mental model of how the CPU works, and that only forms when
*you* wrestle with the registers, the stack, and the bit-manipulation. Have Claude
**explain before it writes**, predict what an instruction does before you run it, and
write the code yourself once it clicks. And check your course's policy on AI help — what
you submit is your responsibility.

## Keeping the Wokwi license fresh
The free key lasts ~30 days. When it lapses, renew (F1 → `Wokwi: Request a new License`)
and run `windows\Reset-WokwiLicense.ps1` / `bash macos/reset-wokwi-license.sh` (or edit
the `wokwi-license-stamp` file) so the reminder resets. Builds print a gentle,
**non-blocking** reminder near the 30-day mark; silence it with
`AVR_TOOLKIT_NO_LICENSE_WARN=1`. It's an estimate anchored on your last renewal, not a
live check.

## What bootstrap does
1. Downloads `arduino-cli` into a short runtime dir under `%LOCALAPPDATA%` / `~/.local/share`.
2. Installs the `arduino:avr` core (avr-gcc + Uno core) into a contained data dir.
3. Persists **`AVR_TOOLKIT_HOME`** so the build scripts find the toolchain anywhere.
4. **Links** the **`wokwi-diagram`** skill into `~/.claude/skills` (so a later `git pull`
   updates it — don't move or delete the clone, since it backs the link) and starts the
   license clock.
5. Smoke-tests a compile of the template sketch.

## Updating
`git pull` in this clone updates the whole toolkit — the linked skill, the project
template, and the build scripts (new projects pick them up when scaffolded). Re-run
`bootstrap` only when you want to refresh the toolchain itself.

## Repo map
```
common/
  skill/wokwi-diagram/    the diagram.json editing skill
  base/                   shared boilerplate every project gets:
    CLAUDE.md, README.md, wokwi.toml, .gitignore, .vscode/
  templates/              curated project starters, chosen by project name on scaffold:
    blinky/               default — blinky.ino (-> <Name>.ino), blink.S, diagram.json
    Lab3/                 a lab — Lab3.ino, FatMonitor.S, diagram.json + LAB/pinouts/NOTES
windows/                  New-AvrProject.ps1, Reset-WokwiLicense.ps1, build.ps1 overlay
macos/                    new-avr-project.sh, reset-wokwi-license.sh, build.sh overlay
bootstrap.ps1 / bootstrap.sh
```

## License & credits
This project's own files are MIT-licensed ([LICENSE](LICENSE)). It does **not** bundle a
compiler — `arduino-cli` (Apache-2.0) and the Arduino AVR core are downloaded by bootstrap.
Full attribution and the responsible-use note are in [CREDITS.md](CREDITS.md).
