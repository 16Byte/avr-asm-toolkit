# AVR Assembly Toolkit — Overview, Status & Roadmap

_Last updated: 2026-08-09 · active branch: `arduino-cli`_

A companion to `README.md`: what this project **is**, where it's **at**, and where it
could **go**. README is the how-to-install; this is the map.

---

## 1. What this is

A **portable, self-contained toolkit** for doing the NMSU AVR assembly course labs
(Dr. Song; Mazidi text; ELEGOO UNO R3 Super Starter Kit) entirely from the command
line — **no PlatformIO, no paid Wokwi graphical editor, no system pollution.**

It lets a student (and Claude Code) **write, build, wire, and simulate** ATmega328P
labs — Arduino `.ino` + AVR assembly `.S` — with the circuit authored *as code*.

- **Repo:** `~/avr-asm-toolkit`
- **Two branches:**
  - `avra` — AVRASM2 / Microchip-Studio syntax, assembled with `avra`.
  - **`arduino-cli` (current, becoming default)** — `arduino-cli` + the `arduino:avr`
    core (avr-gcc), projects are `.ino` + `.S`. Everything below describes this branch.
- **Verified on** Windows and Apple-Silicon macOS.

---

## 2. Architecture

| Piece | Role |
|---|---|
| `bootstrap.ps1` / `bootstrap.sh` | One-time per-machine setup. Installs **contained** arduino-cli + `arduino:avr` core, an **embeddable Python**, and **wokwi-cli** under `%LOCALAPPDATA%\avr-asm-toolkit` (Win) / `~/.local/share/...` (mac). Persists `AVR_TOOLKIT_HOME` + `AVR_TOOLKIT_PY`. Installs the wokwi-diagram skill as a live junction/symlink. |
| `common/template/` | Project scaffold: `<Name>.ino`, `blink.S`, `wokwi.toml`, `diagram.json`, `CLAUDE.md`. |
| `windows/New-AvrProject.ps1` · `macos/new-avr-project.sh` | Scaffold a new lab project from the template. |
| `build.ps1` / `build.sh` (template overlay) | `arduino-cli compile` → normalize to `build/firmware.hex` + `.elf`. Locates the toolchain via `AVR_TOOLKIT_HOME`. |
| **`wokwi-diagram` skill** (`~/.claude/skills/wokwi-diagram`) | The heart. `scripts/wokwi_diagram.py` edits `diagram.json`: `add/move/connect/plug/serial/remove/list/validate`. `references/schema.md` + `parts.md` capture the pin/wiring knowledge. Source of truth lives in `common/skill/`. |
| `windows/Sim-Run.ps1` | Headless run of a sketch via wokwi-cli — returns serial output, can feed input and assert. |
| `windows/Reset-WokwiLicense.ps1` | Refresh the license-expiry estimate stamp. |

**Key env vars:** `AVR_TOOLKIT_HOME` (contained runtime), `AVR_TOOLKIT_PY` (skill's
Python), `WOKWI_CLI_TOKEN` (user-set, for wokwi-cli — never stored by the toolkit).

---

## 3. Current state — what works

**Toolchain**
- Fully contained; **PlatformIO removed**. Builds work in a bare shell (Claude-run).
- Contained Python for the skill helper (no system/Store/PlatformIO interpreter).

**Circuit-as-code (replaces the paid Wokwi editor)**
- **Anchored placement** — `add/move --anchor below|above|left|right|corners` relative
  to the Uno; in-sim-calibrated breadboard positions + rotations.
- **Direct-plug placement** — `plug ID PIN bb1:HOLE` seats a component's legs in real
  holes and computes `top/left/rotate` from calibrated geometry. Wires legs with the
  `$bb` marker. Legibility that matches the no-solder lab.
- **Breadboard pin scheme** (undocumented by Wokwi, reverse-engineered + validated):
  holes `<col>t.<a-e>` (abcde side) / `<col>b.<f-j>` (fghij side); rails
  `tp|tn|bp|bn.<n>`; full board = **63 columns** (830-pt).
- **Hardware-aware validation** — beyond pin correctness, `validate` flags things that
  work in Wokwi but fail on the real ELEGOO board, each feeding a **stop-and-ask gate**
  that teaches the student:
  - a power rail wired across its **center split** without a bridge,
  - `+` and `−` feeds on **opposite halves** (no region has both power and ground),
  - **two pins in one hole**.
- **Legible wiring** — jumpers auto-route with Wokwi's `"*"` token (clean orthogonals).
- **Serial Monitor** — opens by default (`display: "always"` in the template); Claude
  toggles it on request; "monitor disappeared" recovery documented.

**Headless run / verify (wokwi-cli — needs token, cloud/metered)**
- `Sim-Run.ps1` runs a sketch, returns serial output, can **feed typed input and assert**
  (`-InputText`, `-ExpectText`) — the "why isn't this working?" / lab-verify loop.
- `wokwi-cli lint --offline` — authoritative pin/part check (no token), complements
  `validate`.

**Reusable assets**
- Known-good I2C LCD "hello" driver (`references/lcd-i2c-hello.S`).

---

## 4. Knowledge / calibration captured

- **Breadboard geometry** for auto-placement: **9.6 px pitch** (0.1"), **28.8 px** row
  e→f ravine, per-part plug anchors — in `PLUG_GEOMETRY` (script) + the geometry memo.
- **Rail split** at hole **25** of a 50-hole rail (center of the 63-col board).
- These were **measured from real Wokwi diagrams**, not guessed — the whole method has
  been empirical (build → look → calibrate).

---

## 5. Known limitations / gaps

- **`plug` geometry is only calibrated for**: LED (0/90/180/270), resistor (0/180),
  6mm pushbutton (90). Any other part/rotation errors with the known list — add a
  calibration row (30-sec: plug it once by hand in Wokwi, record `top/left/rotate` +
  holes, add to `PLUG_GEOMETRY`).
- **Plugging targets grid holes only** — components plugged into a *rail* aren't
  geometry-calibrated yet.
- **`breadboard-mini`** size is still an estimate (untested).
- **Screenshots for layout: not possible** — wokwi-cli only screenshots a single
  (display) part; the breadboard can't be captured. Eyeball the sim yourself.
- **wokwi-cli** is cloud/metered and needs a token; `Sim-Run` is **Windows-only** so far.
- **Wokwi license** — free keys last ~30 days; `build.ps1` prints a non-blocking estimate.

---

## 6. Roadmap

### Near-term (this week — get labs running)
- [ ] **Expand `PLUG_GEOMETRY`** as each new lab part shows up (pushbutton, potentiometer,
      7-segment, LCD, servo, joystick, 74HC595, …) — one calibration row each.
- [ ] **macOS parity for `Sim-Run`** (`macos/sim-run.sh`).

### Medium
- [ ] **Rail-hole plug geometry** (plug a component leg into a rail, not just the grid).
- [ ] **Calibrate `breadboard-mini`.**
- [ ] **Fold `wokwi-cli lint`** into the validate flow as an automatic second opinion.
- [ ] **More reusable `.S` driver references** (in the style of the I2C LCD one) for
      common lab peripherals.

### Parked / evaluated-and-dropped
- **wokwi-cli MCP server** (`wokwi-cli mcp`) — exposes interactive tools (`read_serial`/
  `write_serial`, **`read_pin`**, `set_control`, start/stop/restart). Genuinely useful
  for interactive debugging, but wiring it into the desktop/VS Code Claude Code app +
  restart is high-friction for the payoff. **Revisit** if live-pin debugging becomes a
  real need. (`Sim-Run.ps1` already covers the batch run+read case.)
- **Layout screenshots** — no Wokwi mechanism exists (per-part crop only). Human eyeball
  stays the layout check.

---

## 7. Quick reference

```powershell
# one-time per machine
.\bootstrap.ps1

# new lab
.\windows\New-AvrProject.ps1 Lab3 -Open

# build (or Ctrl+Shift+B in VS Code)
.\build.ps1

# edit the circuit — let Claude drive the wokwi-diagram skill, or directly:
& $env:AVR_TOOLKIT_PY $env:USERPROFILE\.claude\skills\wokwi-diagram\scripts\wokwi_diagram.py validate

# run/verify a Serial lab headless (needs WOKWI_CLI_TOKEN set at User scope)
.\windows\Sim-Run.ps1 -InputText "22`n33`n44`n" -ExpectText "The sum is 99"
```

---

## 8. Changelog — 2026-08-09 (this build)

On `arduino-cli`, in order:
1. `bootstrap` installs a **contained Python**; PlatformIO dependency dropped.
2. wokwi-diagram: **anchors, z-order, breadboard pins + hardware-aware validation**.
3. wokwi-diagram: **direct-plug component placement** (calibrated) + one-pin-per-hole.
4. wokwi-diagram: **`"*"` auto-routed jumpers**.
5. wokwi-diagram: **`serial` command** to configure the Serial Monitor.
6. **template opens the Serial Monitor by default**; Claude toggles it.
7. `toolkit`: **install wokwi-cli + headless run/lint helpers** (screenshots evaluated
   and dropped; MCP evaluated and parked).
