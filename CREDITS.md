# Credits & licensing

This toolkit is an **unofficial, student-made learning aid**. It is **not
affiliated with, endorsed by, or provided on behalf of** New Mexico State
University, any CS 2230 / CS 4993 instructor, or any textbook author or publisher.
It's a convenience wrapper around existing open-source tools. Provided **as-is**,
with no warranty (see LICENSE).

## This project's own code — MIT
The bootstrap scripts, project template, build scripts, scaffolders, docs, and the
`wokwi-diagram` Claude skill are © 2026 Diego Jimenez and MIT-licensed (see
[LICENSE](LICENSE)).

## Toolchain — downloaded, not bundled
- **arduino-cli** (Apache-2.0) is downloaded by bootstrap into a per-user runtime
  directory; it is not committed in this repo. Upstream: https://github.com/arduino/arduino-cli
- The **Arduino AVR core** (`arduino:avr`, which includes avr-gcc) is installed by
  arduino-cli on first bootstrap. It carries its own upstream licenses (the Arduino
  core is LGPL/GPL, avr-gcc is GPL, avr-libc is BSD-style) and lives in the runtime,
  not in this repo.

## Not bundled — you install these yourself
- **Wokwi** — the hardware simulator, via the Wokwi VS Code extension (a
  third-party product with its own terms).
- **Claude Code** — used as the AI pair-programmer and tutor.
- The **Mazidi, Naimi & Naimi** textbook is the course text; no textbook content is
  included here.

## Using it responsibly
This is meant to help you **learn** — to build things, then understand why they
work. Using AI assistance on graded coursework may be limited or prohibited by your
course or institution. Check your instructor's policy and your school's
academic-integrity rules, and make sure the understanding (and the submitted work)
is genuinely yours.
