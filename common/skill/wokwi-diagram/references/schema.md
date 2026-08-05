# diagram.json schema + wiring patterns

## Anatomy
```json
{
  "version": 1,
  "author": "…",
  "editor": "wokwi",
  "parts": [
    { "type": "wokwi-arduino-uno", "id": "uno", "top": 0, "left": 0, "attrs": {} },
    { "type": "wokwi-led", "id": "led1", "top": -72, "left": 24,
      "rotate": 0, "attrs": { "color": "red" } }
  ],
  "connections": [
    [ "led1:A", "uno:13", "green", [ "v12", "h70" ] ],
    [ "led1:C", "uno:GND.1", "black", [] ]
  ],
  "dependencies": {}
}
```

### parts[]
- `type` — the `wokwi-*` string (see `parts.md`).
- `id` — unique name you choose; used in connections (`id:pin`).
- `top` / `left` — position in **pixels**; may be negative or fractional. The
  board usually sits at `0,0`; place other parts around it. Larger `top` = lower,
  larger `left` = further right.
- `rotate` — optional, one of `0/90/180/270` degrees.
- `attrs` — part-specific options (colors, values…), all **strings**.

### connections[]
Each connection is a 4-element array:
```
[ "partA:pin", "partB:pin", "color", [ route ] ]
```
- Endpoints are `id:pin`; pin names are exact and case-sensitive (`GND.1`, `2.l`, `A0`).
- `color` — wire color. Convention: `black`=GND, `red`=5V/VCC, `green`/others=signals.
  Good color use makes a diagram readable at a glance.
- route — optional list of relative movements for the wire path, e.g. `"v12"`
  (down 12px), `"h-8"` (left 8px). **An empty list `[]` is fine** — Wokwi draws a
  direct wire. Don't hand-craft routes; leave `[]` unless the user wants tidy paths.

## Coordinates & layout (no graphical editor needed)
- Think of the board at origin. Put new parts to the right (`left: 200`+) or above/
  below, spaced ~80–100px apart so they don't overlap. The helper script's
  auto-layout does exactly this.
- To rearrange, set `top`/`left`/`rotate` (script: `move ID --top .. --left .. --rotate ..`).
- Exact pixel-perfect placement doesn't affect the simulation — only wiring does.
  So prioritize correct connections; nudge positions only for readability.

## Common circuit patterns
These are how the kit parts are normally wired. Reproduce the electrical intent.

**LED (needs a series resistor):**
`uno:<pin> → resistor:1`, `resistor:2 → led:A`, `led:C → uno:GND`. Resistor `value=220`.

**Push button (active-low with internal pull-up):**
`button:1.l → uno:<pin>`, `button:2.l → uno:GND`. In firmware enable the internal
pull-up; pressing reads LOW. (Active-high alternative: button between `5V` and the
pin, plus a ~10k resistor from pin to GND as an external pull-down.)

**Potentiometer / analog sensor → ADC:**
`pot:VCC → uno:5V`, `pot:GND → uno:GND`, `pot:SIG → uno:A0`. Same VCC/GND/signal
shape for photoresistor (`AO`), thermistor (`OUT`), joystick (`VERT`/`HORZ`).

**HC-SR04:** `VCC→5V`, `GND→GND`, `TRIG→`a digital out, `ECHO→`a digital in.

**7-segment (common-cathode):** each segment `A`–`G`,`DP` through its own resistor
to a digital pin; `COM → GND`. Multi-digit: `DIG1..n` select digits (multiplex).

**74HC595:** `DS→`data pin, `SHCP→`clock pin, `STCP→`latch pin, `OE→GND`,
`MR→5V`, `VCC→5V`, `GND→GND`; `Q0..Q7` drive outputs (e.g. LED segments).

## Workflow reminders
- After **any** edit, run `validate` — it catches unknown parts, bad pin names,
  and duplicate ids before you waste time in the simulator.
- Keep `id`s meaningful (`led_red`, `btn_start`) — they show up in connections.
