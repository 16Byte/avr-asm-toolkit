# Project templates

Curated starting points for `New-AvrProject` / `new-avr-project.sh`. A scaffolded project
is composed as **`common/base` (shared boilerplate) + one template here + the platform
overlay** (`build` script + VS Code task).

## How a template is chosen
The scaffolder matches the **project name** against the folder names here,
**case-insensitively**:

- `New-AvrProject Lab3` (or `lab3`) → uses **`Lab3/`**.
- `New-AvrProject MyThing` → no match → falls back to **`blinky/`** (the default).
- `-Template <name>` forces a specific template regardless of the project name.

The single starter `.ino` is renamed to match the project folder (Arduino requires the
main sketch to share the folder's name).

## What a template contains
Just the files that differ from the shared base — the sketch and its circuit:

- `blinky/` — the default: `blinky.ino`, `blink.S`, `diagram.json` (one LED blink).
- `Lab3/` — a **lab** template: the lab's `Lab3.ino` + `FatMonitor.S` starter, the
  canonical `diagram.json` (pre-wired circuit), **plus** its reference docs:
  - `LAB.md` — the full lab writeup (spec, tables, circuit, deliverables).
  - `pinouts.md` — the wiring spec used to author/verify `diagram.json`.
  - `NOTES.md` — known issues / quirks.

## Adding a lab template
Create `common/templates/<LabName>/` with the lab's provided `.ino` + `.S` (verbatim —
keep source pristine so students do the graded assembly themselves), a validated
`diagram.json`, and `LAB.md` / `pinouts.md` / `NOTES.md`. Name the folder exactly how a
student would name the project (`Lab5`) so name-matching finds it.

> Toolchain: these are **avr-gcc GNU `.S` + Arduino `.ino`**, built with `arduino-cli` —
> NOT AVRASM2/`avra`. Validate `diagram.json` with the `wokwi-diagram` skill's helper.
