# Lab3 — known issues (reference only; NOT fixed in the verbatim files)

Full lab writeup is in `LAB.md` (transcribed from the Desktop screenshots).
Toolchain: avr-gcc GNU `.S` + Arduino `.ino`, built in the Arduino IDE.

## Issue 1 — "paste this and the LED lights up" is misleading (UX)

The `lightup` stub the lab hands out sets DDRB/PORTB = `0b00110001` (PB0, PB4, PB5
steady on) and the writeup says "that should light up all three LEDs." But you can't see
that on power-up: `Lab3.ino`'s `setup()` first calls `read2DigitHexValue()` **three
times** (gender, age, fat), each blocking on `while (!Serial.available()) delay(100);`.
So the board sits with **no LEDs on**, silently waiting for serial input, and `lightup()`
only runs *after* all three 2-digit hex values are entered in the Serial Monitor (9600
baud). Nothing is broken — it's an expectation gap that trips up anyone not fluent in
code/hardware. The confusion is real because the handout frames `lightup` as a
standalone "does the wiring work?" test, but the provided `.ino` gates it behind three
serial reads.

## Issue 2 — `gender` / `age` / `fat` need storage, and the lab wants `.comm`, not `.byte 0`

`Lab3.ino` declares `extern byte gender; extern byte age; extern byte fat;`, but the
handed-out `FatMonitor.S` **defines none of them**, so as-pasted the sketch won't link.
The lab explicitly says to supply them: *"you'll also need variable declarations for the
two variables; you can copy your Lab 2 variable declaration code and simply rename the
variables."*

- A previous fix added them as `.byte 0` (initialized bytes in `.data`). That links, but
  it's **not the lab's idiom** — Lab2's declarations use `.comm`.
- Correct form (common/uninitialized symbols in `.bss`), **not applied to the verbatim
  `FatMonitor.S`** — apply only when asked:

  ```asm
      .comm gender, 1
      .comm age, 1
      .comm fat, 1
  ```

  `.byte 0` = an initialized zero placed in `.data`; `.comm name, size` = an uninitialized
  common symbol of `size` bytes — which is what Lab2 (and therefore this lab) uses.

## Issue 3 — the `lightup` stub is a wiring test, not the solution (steady vs. blink)

Easy to mistake the stub for a starting point for the assignment. The spec wants
**blinking** for Low/Normal/High (blue/green/red respectively) and **all three steady on**
only for Very High. The stub just sets pins steady, so it happens to match *only* the
Very-High case. Real implementation needs branch-driven delay loops for the blink — the
lab points at Lab1's `test.S` for exactly that pattern. Don't treat `lightup` as more
than "prove the LEDs and wiring are correct before you start."
