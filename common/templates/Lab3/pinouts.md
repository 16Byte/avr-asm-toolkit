# Lab3 — pinouts (build spec for the Wokwi diagram)

Read this to build/verify `diagram.json` for Lab3. Output target is the Arduino project's
diagram, `C:\Users\Marco\Documents\Arduino\Lab3\diagram.json` (use the `wokwi-diagram`
skill). This is the source of truth for wiring; the full lab is in `LAB.md`.

Parts: `wokwi-arduino-uno`, `wokwi-breadboard`, 3× `wokwi-led` (red/green/blue),
3× `wokwi-resistor` (220 Ω).

## Signal map

| Color | AVR pin | Arduino socket | Breadboard column |
|-------|---------|----------------|-------------------|
| Red   | PB0     | D8             | **53** |
| Green | PB4     | D12            | **57** |
| Blue  | PB5     | D13            | **61** |

`lightup` drives `0b00110001` = PB0, PB4, PB5 → these three columns.

## Breadboard electrical model (so the net list makes sense)

Within a column, the two 5-hole groups are internally shared and split by the center
ravine: **`a=b=c=d=e`** (top group) and **`f=g=h=i=j`** (bottom group). So for column X,
`Xa…Xe` is one node and `Xf…Xj` is another. In Wokwi these are addressed `Xt.<row>` for
the a–e (top) group and `Xb.<row>` for the f–j (bottom) group.

## Net list — per LED column X ∈ {53 red, 57 green, 61 blue}

| From | To | Notes |
|------|----|-------|
| LED anode `A` | `Xj` (`Xb.j`) | long pin, bottom group |
| LED cathode `C` | negative rail `bn` | **explicit black wire** — Wokwi LED legs don't stretch to the rail |
| Resistor end1 | `Xh` (`Xb.h`) | bottom group, shares node with the anode at `Xj` |
| Resistor end2 | `Xc` (`Xt.c`) | top group; **`Xd` is equivalent** (same a–e node) — use `Xd` if it avoids an extra wire |
| Arduino jumper | `Xa` (`Xt.a`) | top group, shares node with resistor end2 |

Signal path per channel: `Arduino pin → Xa → (a–e node) → Xc/Xd → resistor → Xh →
(f–j node) → Xj → LED anode → LED → cathode → bn rail → GND`.

## Global connections

| From | To | Wire color |
|------|----|------------|
| Arduino `D8`  | `53a` (`53t.a`) | red |
| Arduino `D12` | `57a` (`57t.a`) | green |
| Arduino `D13` | `61a` (`61t.a`) | blue |
| Arduino `GND` | negative rail `bn` | gold/yellow |

**Rail invariant:** every LED cathode **and** the Arduino GND must sit on the **same**
rail. Per spec that rail is the negative one (`bn`). (The hand-built diagram put cathodes
on `bp` and GND on `bn` — different rails; unify on `bn`.)

## Wokwi placement notes (from the hand-built diagram, known-good)

- LEDs: `rotate: 270`. Resistors: `rotate: 90`.
- LED order left→right on the board is red, green, blue (columns 53, 57, 61).
- Cathode→rail wires are black; keep resistor/anode $bb auto-routes.
- After edits, **validate** with the skill's helper (`$env:AVR_TOOLKIT_PY`), and confirm
  the three columns still match the signal map above.
