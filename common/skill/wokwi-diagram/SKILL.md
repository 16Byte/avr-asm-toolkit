---
name: wokwi-diagram
description: >-
  Create and edit Wokwi diagram.json circuit layouts programmatically — add,
  move, wire, and remove components (LEDs, buttons, resistors, potentiometers,
  7-segment and LCD displays, HC-SR04, DHT, servo, relay, 74HC595, joystick,
  and the rest of the ELEGOO UNO R3 kit) and validate the wiring. Use this
  whenever the user wants to change the virtual board/breadboard layout, add or
  connect a component in Wokwi, edit diagram.json, or set up a circuit for an
  Arduino/ATmega328P simulation — even if they don't say "diagram.json" by name.
  Replaces Wokwi's paid graphical editor.
---

# Wokwi diagram.json editor

Wokwi's drag-and-drop editor is a paid feature, so build and modify the circuit
by editing `diagram.json` directly. A helper script does the fiddly parts (valid
JSON, correct pin names, sensible placement) and — most importantly — validates
the result, because a mistyped pin produces a dead circuit that looks fine.

## When you're asked to change a circuit

1. **Read the current `diagram.json`** in the project (and glance at the assembly
   in `src/` if the wiring needs to match specific pins the code uses).
2. **Look up each part** in `references/parts.md` — it maps every ELEGOO kit
   component to its Wokwi `type` and its exact pin names + attrs. For anything not
   listed, the pins are at `https://docs.wokwi.com/parts/<type>`.
3. **Make the edits with the script** (preferred over hand-editing — it prevents
   JSON and pin-name mistakes):

   ```bash
   # Use the toolkit's own Python (bootstrap installs it and sets AVR_TOOLKIT_PY).
   # On macOS AVR_TOOLKIT_PY may be unset — fall back to python3 there.
   PY="${AVR_TOOLKIT_PY:-python3}"
   SC="$HOME/.claude/skills/wokwi-diagram/scripts/wokwi_diagram.py"

   "$PY" "$SC" list
   "$PY" "$SC" add wokwi-led led_red --attr color=red
   "$PY" "$SC" add wokwi-resistor r1 --attr value=220
   "$PY" "$SC" connect uno:8 r1:1
   "$PY" "$SC" connect r1:2 led_red:A
   "$PY" "$SC" connect led_red:C uno:GND.1
   "$PY" "$SC" validate
   ```
   `AVR_TOOLKIT_PY` points at the contained interpreter `bootstrap.ps1` drops in
   `%LOCALAPPDATA%\avr-asm-toolkit\python` — no system, Microsoft Store, or
   PlatformIO Python involved. If it's empty, re-run `bootstrap.ps1`. Never use the
   bare `python` on Windows (it's usually the Store stub and fails).

4. **Always run `validate`** afterward, and treat its two output kinds differently:
   - **Issues** (`- ...`: unknown parts, invalid pin names, duplicate ids) are your
     mistakes — **fix them silently** before telling the user it's done.
   - **Warnings** (`! ...`: things that work in Wokwi but are wrong on the real ELEGOO
     kit, e.g. a rail powered across its center split) are a **user decision, not a
     bug**. **Don't quietly ship them and don't quietly "fix" them either — stop and
     ask** with `AskUserQuestion`, *mid-response*, before calling it done, whenever the
     wiring you're about to make (or just made) would warn — even if the user never
     mentioned hardware. Write the question to **teach, assuming the student does NOT
     already know**: state the real-world fact plainly — *it won't work on the physical
     ELEGOO breadboard you're using in the lab* (the reason Dr. Song shows in the
     videos) — then why Wokwi still lights up. Order the options with the simplest
     **hardware-correct** fix first (label it "(Recommended)"), and only take a sim-only
     option if they pick it.
5. Summarize what you wired and remind them to rebuild (Ctrl+Shift+B) and restart
   the Wokwi simulation so it reloads the diagram.

## Script commands
`list` · `add TYPE ID [--anchor SPOT --ref ID] [--top --left --rotate --attr k=v]` ·
`move ID [--anchor SPOT --ref ID] [--top --left --rotate]` · `attr ID --attr k=v` ·
`connect A:PIN B:PIN [--color] [--plug]` · `plug ID PIN BBID:HOLE [--rotate R]` ·
`remove ID` · `validate`. Run with `--file path/to/diagram.json` if not in the project dir.

- `connect` auto-colors by net (black=GND, red=5V/VCC, green=signal); override
  with `--color`.
- **`plug ID PIN BBID:HOLE [--rotate R]` is the way to seat a component on the board.**
  It computes the part's `top`/`left` so PIN lands in that grid hole (`$bb` alone does
  NOT move the part — you must position it), sets rotation, and wires **every** leg in
  with `$bb` plugs. e.g. `add wokwi-led led1` then `plug led1 C bb1:18t.e` → LED seated,
  anode auto-placed at `19t.e`. Calibrated for LED (0/90/180/270), resistor (0/180),
  6mm button (90); other parts/rotations error with the list of what's known.
- `connect ... --plug` is the low-level primitive (wires one leg with `$bb`, no
  positioning) — prefer `plug`. Use plain colored cables only for jumpers (hole↔hole,
  Uno↔hole). See *Wiring correctly* below.

## Placing parts (anchors, not guesswork)
Don't drop parts at arbitrary coordinates. Put each part in a named spot **relative
to the Uno** with `--anchor`, then confirm the spot with the user:

- Anchors: `below` · `above` · `left` · `right` · `below-left` · `below-right` ·
  `above-left` · `above-right`. `below`/`above` center the part horizontally on the
  board (`above` mirrors `below`); `left`/`right` center it vertically; corners align
  to the board's edges.
- **Breadboards** have calibrated spots on all four sides: `below`/`above` sit them
  flat, centered on the Uno; `left`/`right` **rotate them 90°/270°** so they stand
  vertically alongside the board. The script sets `rotate` for you (and clears it if
  you later `move` the breadboard back to `below`/`above`).
- `--ref ID` anchors to another part instead of the Uno (e.g. place a resistor
  `--anchor right --ref led1`).
- Sensible defaults: a **breadboard goes `--anchor below`** (centered under the Uno);
  a single part the user just wants "next to the board" goes `--anchor right`.

**Z-order (draw order = list order).** Later parts in `parts[]` render on top. Big
background parts (breadboards) must come *before* the board and the components that sit
on them, so `add` inserts a breadboard at the **front** of `parts[]` automatically
(matching what Wokwi's own editor emits) — keep adding the board, LEDs, resistors, etc.
afterward and they'll draw on top of it. (If you ever hand-edit the JSON, preserve this
order: breadboards → board → components.)

**Confirm-then-adjust flow.** After placing, tell the user where it landed and offer
the alternatives, e.g. *"Put the breadboard centered below the Uno — want it above,
left, or right instead?"* If they pick another, re-place with
`move ID --anchor <spot>` (no need to delete/re-add). Only fall back to explicit
`--top/--left` for fine nudges the anchors don't cover; those override the anchor.

```bash
"$PY" "$SC" add wokwi-breadboard-half bb1 --anchor below   # centered under the Uno
"$PY" "$SC" move bb1 --anchor above                         # user preferred above
```

Calibration lives at the top of `scripts/wokwi_diagram.py`. General centering uses
`PART_SIZE` + `GAP`; exact, in-sim-measured spots (including the rotated breadboard
positions) live in `ANCHOR_OVERRIDES`, keyed by `(type, anchor)`. The full/half
breadboards are calibrated on all four sides; `breadboard-mini` and small parts fall
back to computed geometry. To calibrate another part, drop it in the sim, read its
`top`/`left`/`rotate`, and add a row to `ANCHOR_OVERRIDES` (offsets from a 0,0 board).

- Without `--anchor` or `--top/--left`, `add` falls back to auto-stacking parts to
  the right of the board so they don't overlap.

## Wiring correctly
Read `references/schema.md` for the diagram.json format and the standard wiring
patterns (LED+resistor, button pull-up/pull-down, analog sensor→ADC, 7-segment,
74HC595, etc.). Key rules:

- Pin names are exact and case-sensitive: `GND.1`, `2.l`, `A0`, `V+`.
- **Plug components in, don't cable them.** A component's legs seat directly in
  breadboard holes (`connect COMP:PIN bb1:HOLE --plug`) — the no-solder lab reality and
  much more legible. Reserve colored cables for jumpers (hole↔hole, Uno↔hole).
- **One pin per hole.** A real hole fits one leg/wire; never put two endpoints on the
  same hole. To tap a node where a leg sits (e.g. LED anode at `26t.e`), use another
  hole in the **same column** (`26t.d` — same number/block, different row). `validate`
  warns on doubled holes (works in Wokwi, impossible on the real board) → treat it as
  the same stop-and-ask gate (usually just move to the adjacent hole).
- **Breadboard holes/rails: you already know the names — wire immediately, don't go
  reading Wokwi docs (they don't publish them).** Holes `<col>t.<a-e>` /
  `<col>b.<f-j>` (e.g. `bb1:45t.c`, `bb1:26b.j`), rails `tp|tn|bp|bn.<n>` (e.g.
  `bb1:bn.25`). The `t` section is the **"abcde side"** (rows a-e), the `b` section is
  the **"fghij side"** (rows f-j). Full list + the
  rotation/half-board/printed-number gotchas are in `references/schema.md` →
  *Breadboard pins*. `validate` checks pin names, so wire it, run `validate`, done.
- **Full-board rails are split at the center — build it the way that works on the real
  ELEGOO kit, and teach why.** Wokwi treats a rail as one continuous node, but the
  physical board splits it at the midline (left `.n ≤ 25`, right `.n > 25`). So by
  default keep a rail's feed and taps on the **same half**, and keep the `+` and `−`
  feeds in the **same half as each other** (so a region has both power and ground), or
  drop a bridge jumper (`tp.25 ↔ tp.26`) — and tell the student about the split.
  `validate` warns on both (a) one rail used across both halves, and (b) `+` and `−`
  feeds on opposite halves — and either warning is a **stop-and-ask gate** (see workflow
  step 4): whenever a request would land you there — e.g. the user wants 5V on the wrong
  half, or 5V on one half while ground is on the other — pause mid-response and
  `AskUserQuestion`.
  - **Question text — teach the reality, don't assume they know it.** e.g. *"Heads up:
    this won't work on the real ELEGOO breadboard you're using in the lab. On that board
    each power rail is split down the middle (the break Dr. Song points out in the
    videos), so 5V on the left half never reaches your circuit on the right half. Wokwi
    would light it up because it doesn't simulate the split, but the physical build would
    be dead. How do you want to handle it?"*
  - **Options, hardware-correct first:**
    1. **(Recommended) Move the feed into the half you're already working in** — put 5V
       in the same region as the ground/circuit. Works on the real board, no jumper. (Not
       the exact pin they named, but the right fix.)
    2. **Keep the requested pin and add a bridge** across the split (`tp.25 ↔ tp.26`, or
       the − rail) so both halves connect. Works on hardware, keeps their position.
    3. **Wire it exactly as asked (sim-only)** — lights up in Wokwi, dead on the real
       ELEGOO board. Only if they choose it.
- LEDs need a **series resistor** — wire `pin → resistor → LED anode → LED
  cathode → GND`, not the pin straight to the LED.
- Match the wiring to what the assembly code expects. If the code toggles PB5
  (Arduino D13), the LED must be on pin `13`.
- Exact pixel positions don't affect the simulation, only readability — get the
  **connections** right first, nudge `top`/`left` only to tidy up.

## Hand-editing
For things the script doesn't do (custom wire routes, bulk restructuring, exotic
parts), edit the JSON directly using `references/schema.md`, then still run
`validate` to catch mistakes.

## Reference: I2C LCD that immediately prints text
If the user wants an LCD1602 that shows a message at startup, **don't derive the
HD44780 init from scratch** (it's fiddly and fails intermittently) — reuse the
known-good, Wokwi-verified driver `references/lcd-i2c-hello.S` (pure AVR assembly,
GNU/avr-gcc syntax). Steps:
- Copy it into the sketch as `lcd.S`; add a 2-line `.ino` that calls `lcd_hello()`.
- Wire a `wokwi-lcd1602` with `attrs.pins = "i2c"`: `SDA->uno:A4`, `SCL->uno:A5`,
  `VCC->5V`, `GND->GND`.
- Change the text via the `.asciz` string; for a different backpack address set
  `SLA_W = addr << 1` (0x27 -> 0x4E).

This is the **I2C-backpack** LCD (4 wires). The parallel 16-pin LCD1602 that some
kits ship needs a different driver (RS/E/D4–D7 on GPIO) — offer that variant if the
user is on real hardware rather than Wokwi.
