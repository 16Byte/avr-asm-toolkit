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
   # Pick a real Python 3: PY="py -3" on Windows, PY=python3 on macOS/Linux.
   PY="py -3"
   SC="$HOME/.claude/skills/wokwi-diagram/scripts/wokwi_diagram.py"

   $PY "$SC" list
   $PY "$SC" add wokwi-led led_red --attr color=red
   $PY "$SC" add wokwi-resistor r1 --attr value=220
   $PY "$SC" connect uno:8 r1:1
   $PY "$SC" connect r1:2 led_red:A
   $PY "$SC" connect led_red:C uno:GND.1
   $PY "$SC" validate
   ```
   Note: on Windows avoid the bare `python` in Git Bash — it's often the Microsoft
   Store stub and fails. Use `py -3`; if that's unavailable, any real python3 works
   (on a machine with PlatformIO, its bundled `python.exe` is a reliable fallback).

4. **Always run `validate`** afterward. It flags unknown parts, invalid pin
   names, and duplicate ids. Fix anything it reports before telling the user it's
   done.
5. Summarize what you wired and remind them to rebuild (Ctrl+Shift+B) and restart
   the Wokwi simulation so it reloads the diagram.

## Script commands
`list` · `add TYPE ID [--top --left --rotate --attr k=v]` · `move ID --top --left
[--rotate]` · `attr ID --attr k=v` · `connect A:PIN B:PIN [--color]` · `remove ID`
· `validate`. Run with `--file path/to/diagram.json` if not in the project dir.

- `add` without `--top/--left` auto-places the part to the right of the board,
  spaced so parts don't overlap.
- `connect` auto-colors by net (black=GND, red=5V/VCC, green=signal); override
  with `--color`.

## Wiring correctly
Read `references/schema.md` for the diagram.json format and the standard wiring
patterns (LED+resistor, button pull-up/pull-down, analog sensor→ADC, 7-segment,
74HC595, etc.). Key rules:

- Pin names are exact and case-sensitive: `GND.1`, `2.l`, `A0`, `V+`.
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
