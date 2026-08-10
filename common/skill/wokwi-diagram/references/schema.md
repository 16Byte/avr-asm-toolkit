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
- route — the wire path, a list of moves (Wokwi's mini-language). `"v12"` = down 12px,
  `"h-8"` = left 8px (pixels, signed). **`"*"`** (at most once) splits the list: moves
  *before* it are anchored to the **source** pin; moves *after* it are anchored to the
  **target** pin and applied **in reverse order**; Wokwi auto-connects the gap between.
  So `["*"]` = no manual offsets, Wokwi routes it cleanly (orthogonal, not a diagonal).
  Example `["v10","h5","*","v-15","h10"]` = from source, down 10 then right 5; from
  target (reversed), right 10 then up 15. An empty `[]` draws a plain direct diagonal.
  **Prefer `["*"]` for jumpers** — clean routing, no hand-crafted segments. (`["$bb"]`
  is the separate marker for a leg seated in a hole — see *Plugging components* below.)

### Plugging components into the board (legibility, and how the real kit works)
On a real solderless breadboard a component's **legs plug straight into holes** — you
don't run a cable from the part. Wokwi models this with a special connection: **empty
color + route `["$bb"]`**, e.g. `[ "led1:A", "bb1:26t.e", "", [ "$bb" ] ]`. That renders
the leg seated in the hole instead of a wire. (Confirmed from a real diagram.)
- **Prefer plugging over cabling** for components (LED, resistor, button, sensor legs):
  it's what the lab hardware does and it's far more legible than wires crossing the board.
  Script: `connect COMP:PIN bb1:HOLE --plug`. Use plain `connect` (a colored cable) only
  for **jumpers** — hole↔hole or Uno↔hole.
- The connection is still explicit (Wokwi doesn't auto-wire by proximity); place the
  component near its holes so the seated leg reads right.

### One pin per hole (a hole holds ONE leg/wire)
A physical breadboard hole fits exactly one pin. Wokwi will happily stack several
endpoints on the same hole, but the real ELEGOO board can't. **Never put two endpoints
on the identical hole.** To join a node where a leg already sits (say the LED anode in
`26t.e`), tap a **different hole in the same column** — same number, same `t`/`b` block,
a different row (`26t.d`); the five holes of that column are one node. `validate` warns
on any doubled hole.

## Coordinates & layout (no graphical editor needed)
- Think of the board at origin. Put new parts to the right (`left: 200`+) or above/
  below, spaced ~80–100px apart so they don't overlap. The helper script's
  auto-layout does exactly this.
- To rearrange, set `top`/`left`/`rotate` (script: `move ID --top .. --left .. --rotate ..`).
- Exact pixel-perfect placement doesn't affect the simulation — only wiring does.
  So prioritize correct connections; nudge positions only for readability.

## Breadboard pins (known — don't go searching)
Wokwi doesn't publish breadboard pin names, so they're captured here. **You already
know them; wire directly.** The script's `validate` checks them, so you can confirm
without guessing.

- **Holes:** `<col><section>.<row>` — `section` `t` (top block, rows `a`–`e`) or `b`
  (bottom block, rows `f`–`j`); the row is the literal silk-screen label, so `t` always
  goes with `a`–`e` and `b` with `f`–`j`. `col` is `1`–`30` (`wokwi-breadboard-half`)
  or `1`–`63` (`wokwi-breadboard`, an 830-pt board). Examples: `bb1:1t.a`, `bb1:45t.c`, `bb1:26b.j`,
  `bb1:35b.g`. (Confirmed against a real Wokwi diagram.)
- **Power rails:** `<section><polarity>.<n>` — `tp`/`tn` (top +/−), `bp`/`bn`
  (bottom +/−), `n` = position. Examples: `bb1:tp.1`, `bb1:bn.25`.
- **The full board's rails are SPLIT at the center — wire as if they are, and teach
  it.** A real ELEGOO full board breaks each `+`/`−` rail at the midline into two
  halves of ~25 holes (5 groups of 5). Wokwi treats the rail as one continuous node,
  so a wire that crosses the split *works in the sim* — but it's a **dead net on the
  real kit**. This is a course concept, so the goal isn't just "make Wokwi light up,"
  it's to build what would also work on hardware. **Default behavior: keep a rail's
  feed and its taps on the same half, or add a bridge jumper across the center
  (`tp.25 ↔ tp.26`). Explain the split to the student as you do it.**
  - `validate` flags two split hazards (left half = `.n ≤ 25`, right = `.n > 25`):
    (1) **one rail used on both halves** without a bridge; and (2) the **`+` rail and
    `-` rail on opposite halves** — so no single region of the real board has both power
    and ground (e.g. `5V→tp.10` on the left while `GND→tn.35` is on the right). Both
    work in Wokwi, both fail on hardware.
  - **Whenever a request would land on either warning — stop and ask (don't silently
    comply, don't silently "fix"), even if the user never mentions hardware.** The moment
    you can see the wiring would power/tap the wrong half *or* put the + and − feeds on
    opposite halves (e.g. "put 5V on pin 10" when ground is already on the right half),
    pause *mid-response* and use `AskUserQuestion`.
    - **Teach the reality — assume they don't know it.** e.g. *"Heads up: this won't work
      on the real ELEGOO breadboard you're using in the lab. Each power rail is split
      down the middle (the break Dr. Song shows in the videos), so 5V on the left half
      never reaches your circuit on the right. Wokwi lights it up because it doesn't
      simulate the split, but the physical build would be dead."*
    - **Options, hardware-correct first:** (1) *(Recommended)* move the feed into the
      half you're already working in — same region as the ground/circuit, no jumper;
      (2) keep the requested pin and add a bridge across the split so both halves connect;
      (3) wire it exactly as asked, sim-only (works in Wokwi, dead on the real board).
    Only take the sim-only path if they pick it.
  - The half board (`wokwi-breadboard-half`) rails are continuous — no split.
- **Rail `.n` ≠ the printed column number.** Rail holes are grouped in fives (with
  gaps), so there are fewer of them than the 60 grid columns and `.n` runs *ahead* of
  the silk-screen number (`tn.45` sits out near printed ~54). Grid holes don't drift —
  `45t.a` is under printed 45. When a student says "ground rail at 45" they mean the
  printed 45, so place the wire near printed 45 for readability (roughly
  `n = printed * 5/6`).
- The `t`/`b` prefix picks which grid block: **`t` = the "abcde side"** (top block,
  rows `a`–`e`), **`b` = the "fghij side"** (bottom block, rows `f`–`j`). A column's
  five holes within a block share one node, so `45t.a`…`45t.e` are the same electrical
  point (and likewise `45b.f`…`45b.j`). The `a`–`e`/`f`–`j` halves are separated by the
  center channel and are **not** connected to each other.
- Pin names are **logical**: a breadboard's `rotate` changes only how it looks on
  screen, never its pin names. Don't let a rotated board make you second-guess.
- **Half board has only 30 columns** — `45` doesn't exist on it (`validate` will say
  so). Use a full `wokwi-breadboard` (63 columns) if you need columns 31–63.

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

## Serial Monitor
A top-level `"serialMonitor"` key in diagram.json configures the monitor (helper:
`serial --display … --newline … --collapse --convert-eol`):
```json
"serialMonitor": {
  "display": "terminal",   // auto (default) | always | never | plotter | terminal
  "newline": "lf",         // lf (default) | cr | crlf | none  — appended to typed input
  "collapse": false,
  "convertEol": false      // terminal mode only: \n -> \r\n
}
```
- **`display: "auto"` is the default and the reason the monitor is easy to lose** — it
  only appears when output shows up. For a lab that reads typed input, set
  `"always"` (monitor open from sim start) or `"terminal"` (XTerm view, color, best for
  interactive typing). `"plotter"` graphs numeric output.
- **`newline`** is what gets appended when the student presses Enter — match it to what
  the sketch parses (`Serial.parseInt`/`readStringUntil('\n')` want `lf`).
- Wokwi limitations these keys do **not** fix: the monitor is a fresh instance each
  time you press play, and it doesn't clear on reset. Setting `display` just keeps it
  reliably visible so you don't have to stop/restart to find it.

## Workflow reminders
- After **any** edit, run `validate` — it catches unknown parts, bad pin names,
  and duplicate ids before you waste time in the simulator.
- Keep `id`s meaningful (`led_red`, `btn_start`) — they show up in connections.
- For an authoritative second opinion on part/pin names, `wokwi-cli lint --offline .`
  (no token needed) checks against Wokwi's registry. Our `validate` still owns the
  hardware-aware checks (rail split, one-pin-per-hole, plug geometry) that lint doesn't.
