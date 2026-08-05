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

## Bundled third-party software
- **avra** — the AVR macro assembler that does the actual work. Copyright ©
  1998–2020 The AVRA Authors, licensed under the **GNU General Public License,
  version 2**. Source is vendored at `common/build-avra/avra-src/` (full license in
  its `COPYING`); prebuilt binaries are in `windows/avra/` and `macos/avra/`.
  Upstream: https://github.com/Ro5bert/avra
- **Device definitions** (`common/avra/includes/*.inc`) are distributed with avra
  and carry avra's licensing.

## Not bundled — you install these yourself
- **Wokwi** — the hardware simulator, via the Wokwi VS Code extension (a
  third-party product with its own terms).
- **Claude Code** — used as the AI pair-programmer and tutor.
- The **Mazidi, Naimi & Naimi** textbook is referenced for AVRASM2 syntax only;
  no textbook content is included here.

## Using it responsibly
This is meant to help you **learn** — to build things, then understand why they
work. Using AI assistance on graded coursework may be limited or prohibited by your
course or institution. Check your instructor's policy and your school's
academic-integrity rules, and make sure the understanding (and the submitted work)
is genuinely yours.
