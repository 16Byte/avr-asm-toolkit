# Lab3 — Nonlinear program execution and body fat monitor

**100 points. Individual lab** (identical duplicate submissions get zero).
Source of truth = the 20 screenshots in `C:\Users\Marco\Desktop\Lab3\` (grabbed from a
course video before the class started). This file is a faithful transcription so the lab
can be referenced without re-reading the images.

Toolchain: **avr-gcc GNU `.S` + Arduino `.ino`**, built in the Arduino IDE (NOT `avra` —
see `../README.md`).

---

## Concept: conditional branches (nonlinear execution)

AVR has no if/else; you branch. A compare sets flags in **SREG**, then a conditional
branch acts on them:

```
    CP   R18, R19      ; if (R18 < R19)
    BRSH addr          ;   {   (BRSH = Branch if Same or Higher, unsigned >=)
    ...                ;     do something (runs only when R18 < R19)
addr:                  ;   }
    ...remaining program
```

`BRSH` branches (skips) when `R18 >= R19`, so the code between the branch and `addr` runs
only when `R18 < R19`. You typically program the branch as the **negative** of the
condition you want, because the branch skips the conditional body.

### Rules the lab insists on
- **Use unsigned branches `BRSH` / `BRLO`, or equality `BREQ` / `BRNE` only.**
  **Do NOT use signed `BRGE` / `BRLT`** — the program will not work.
- Only two comparisons exist natively: **"same or higher" (>=, `BRSH`)** and
  **"lower than" (<, `BRLO`)**. For **">" (strictly higher)** reverse the registers:
  for `if (R18 > R19)` do `CP R19, R18` then `BRLO`.
- Useful compares: `CP` (register vs register) and `CPI` (register vs immediate).
- **Branch range is only ~±64 instructions**; jumping farther is an assembly error.
- Hint: write the C/Java algorithm first, using **only simple conditions and nested
  if/else** (no `&&` / `||`), then translate to assembly.
- `test.S` from **Lab1** shows branch-based for-loops that **blink** an LED — reference
  it for the blinking behavior this lab needs.

---

## The Body Fat Monitor

Read three 2-digit **hex** values over serial (same as Lab2): **gender, age, body-fat %**.
- Gender code: **`0x0F` = Female**, **`0x0A` = Male**.
- Classify body fat as Low / Normal / High / Very High per the table, then drive 3 LEDs.

### Feedback
| Body fat | LED behavior |
|----------|--------------|
| Low       | **blue** LED blinks |
| Normal    | **green** LED blinks |
| High      | **red** LED blinks |
| Very High | **all three** LEDs stay ON (no blinking) |

### Classification table (Gallagher et al., Am. J. Clin. Nutrition, Vol. 72, Sept 2000)
Notation `[24,36)` = `>= 24 and < 36` (inclusive low end, exclusive high end).

| Gender | Age   | Low  | Normal   | High     | Very High |
|--------|-------|------|----------|----------|-----------|
| Female | 20–39 | < 21 | [21, 33) | [33, 39) | >= 39 |
| Female | 40–59 | < 23 | [23, 34) | [34, 40) | >= 40 |
| Female | 60–79 | < 24 | [24, 36) | [36, 42) | >= 42 |
| Male   | 20–39 | < 8  | [8, 20)  | [20, 25) | >= 25 |
| Male   | 40–59 | < 11 | [11, 22) | [22, 28) | >= 28 |
| Male   | 60–79 | < 13 | [13, 25) | [25, 30) | >= 30 |

("Note that you can simplify the checking if you order your clauses appropriately.")

---

## Circuit

PORTB5–0 of the AVR map to Arduino sockets **D13–D8**. This lab uses **PB5=D13, PB4=D12,
PB0=D8** — which is exactly the `0b00110001` bit pattern the test stub sets.

Parts: breadboard, red/blue/green LEDs, **three 220 Ω resistors**, 4 jumper cables.

Final pin mapping (from the wiring photos):

| LED   | AVR pin | Arduino socket |
|-------|---------|----------------|
| Blue  | PB5     | **D13** |
| Green | PB4     | **D12** |
| Red   | PB0     | **D8**  |

Breadboard build (as shown):
1. Jumper from the lower-left blue "I" negative rail to Arduino **GND** → common ground.
2. LED **short pins (cathodes)** → GND rail sockets **1st, 5th, 8th** (blue, green, red).
   LED **long pins (anodes)** → **61j, 57j, 53j** (blue, green, red).
3. Three 220 Ω resistors: end1 at **61h / 57h / 53h** (same rows as the anodes),
   end2 at **61c / 57c / 53c**.
4. Blue/green/red jumpers from **61a / 57a / 53a** to Arduino **D13 / D12 / D8**.

---

## The assembly side (FatMonitor.S)

In the Arduino IDE: create sketch "Lab3", Add File the `Lab3.ino` contents, then make a
**New Tab** named `FatMonitor.S`.

**Wiring-test stub** the lab gives you (this is the `FatMonitor.S` currently stored here):

```asm
    .text
    .global lightup
lightup:
    ldi  r18, 0b00110001
    out  0x04, r18   ; 0x04 = I/O address of DDRB
    out  0x05, r18   ; 0x05 = I/O address of PORTB
    ret
```

This lights **all three** LEDs (bits 0,4,5). It is a **hardware check, not the
assignment** — "once you confirm LEDs work properly, you can program your assignment."
You also need **variable declarations** for the globals — copy Lab2's declarations and
rename them to `gender`, `age`, `fat` (Lab2 uses `.comm`, not `.byte 0` — see `NOTES.md`).

---

## Questions (part of the report)
Convert each to hex, determine which LED lights:

| Gender | Age | Body Fat | Light? |
|--------|-----|----------|--------|
| M | 24 | 45 | _(work it out)_ |
| F | 52 | 33 | |
| M | 45 | 21 | |
| F | 33 | 25 | |

---

## Deliverables (submit online)
1. The **assembly source (`.S`)** for the problem.
2. A **lab report**, all sections + question answers (template is on Canvas → Pages).
3. **Demo to the TA** before submitting.

Submit only the `.S` and the report. Style, neatness, and commenting are graded.
