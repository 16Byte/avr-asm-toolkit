#!/usr/bin/env python3
"""
wokwi_diagram.py - programmatic editor + validator for Wokwi diagram.json.

Exists because Wokwi's graphical editor is a paid feature. This lets you add,
move, wire, and remove parts from the command line and, importantly, VALIDATE
the result so a typo in a pin name doesn't silently produce a dead circuit.

Commands (run from a project dir containing diagram.json, or pass --file):
    list                              show parts and connections
    add    TYPE ID [--anchor SPOT --ref ID] [--top T --left L] [--rotate R] [--attr k=v ...]
    move   ID [--anchor SPOT --ref ID] [--top T --left L] [--rotate R]

  --anchor places a part at a named spot around the board (the Uno by default,
  or --ref ID): below | above | left | right | below-left | below-right |
  above-left | above-right. 'below'/'above' center it horizontally; 'left'/
  'right' center it vertically. Explicit --top/--left override the anchor.
    attr   ID --attr k=v ...          set/replace attributes on a part
    connect A:PIN B:PIN [--color C]   wire two pins (default color by net)
    plug   ID PIN BBID:HOLE [--rotate R]   seat a component so PIN lands in a grid
                                      hole and wire every leg in with $bb plugs
                                      (computes top/left from calibrated geometry)
    serial [--display D --newline N --collapse --convert-eol]   configure the
                                      Serial Monitor (display: auto|always|never|
                                      plotter|terminal; newline: lf|cr|crlf|none)
    remove ID                         delete a part and any connections to it
    validate                          check JSON, part refs, and pin names

Pin names come from PIN_DB below (verified against docs.wokwi.com). For a part
type not in PIN_DB, pin checks are skipped with a note -- look the part up at
https://docs.wokwi.com/parts/<type> and add it here if you use it a lot.
"""
import argparse
import json
import os
import re
import sys

# --- verified pin names per part type (docs.wokwi.com/parts/<type>) ----------
PIN_DB = {
    "wokwi-arduino-uno": (
        [str(d) for d in range(0, 14)]        # digital 0..13
        + [f"A{n}" for n in range(0, 6)]      # analog A0..A5
        + ["5V", "3.3V", "VIN", "GND.1", "GND.2", "GND.3",
           "AREF", "IOREF", "RESET"]
    ),
    "wokwi-led": ["A", "C"],
    "wokwi-resistor": ["1", "2"],
    "wokwi-pushbutton": ["1.l", "1.r", "2.l", "2.r"],
    "wokwi-pushbutton-6mm": ["1.l", "1.r", "2.l", "2.r"],
    "wokwi-slide-switch": ["1", "2", "3"],
    "wokwi-potentiometer": ["GND", "SIG", "VCC"],
    "wokwi-analog-joystick": ["VCC", "VERT", "HORZ", "SEL", "GND"],
    "wokwi-hc-sr04": ["VCC", "TRIG", "ECHO", "GND"],
    "wokwi-dht22": ["VCC", "SDA", "NC", "GND"],
    "wokwi-servo": ["PWM", "V+", "GND"],
    "wokwi-buzzer": ["1", "2"],
    "wokwi-rgb-led": ["R", "G", "B", "COM"],
    "wokwi-ir-receiver": ["GND", "VCC", "DAT"],
    "wokwi-relay-module": ["VCC", "GND", "IN", "NC", "COM", "NO"],
    "wokwi-photoresistor-sensor": ["VCC", "GND", "DO", "AO"],
    "wokwi-ntc-temperature-sensor": ["VCC", "OUT", "GND"],
    "wokwi-7segment": ["A", "B", "C", "D", "E", "F", "G", "DP", "COM",
                       "DIG1", "DIG2", "DIG3", "DIG4", "CLN"],
    "wokwi-74hc595": ["DS", "SHCP", "STCP", "OE", "MR", "GND", "VCC",
                      "Q0", "Q1", "Q2", "Q3", "Q4", "Q5", "Q6", "Q7", "Q7S"],
    "wokwi-lcd1602": ["VSS", "VDD", "V0", "RS", "RW", "E",
                      "D0", "D1", "D2", "D3", "D4", "D5", "D6", "D7", "A", "K",
                      "GND", "VCC", "SDA", "SCL"],  # full + i2c variants
    "wokwi-membrane-keypad": ["R1", "R2", "R3", "R4", "C1", "C2", "C3", "C4"],
    "wokwi-stepper-motor": ["A+", "A-", "B+", "B-"],
}
# Types whose pin set is large/positional; skip strict pin validation for these.
PIN_CHECK_SKIP = {"wokwi-ir-remote"}

# --- breadboard pin naming (Wokwi convention; not in the public docs) --------
# Confirmed against a real Wokwi diagram (2026-08-09).
# Holes:  <col><section>.<row>   section = t | b, col = 1..N.
#   t = the TOP block, rows a-e ("abcde side");  b = the BOTTOM block, rows f-j
#   ("fghij side"). The row letter is the literal silk-screen label (a-j), so the
#   section and row always agree: t pairs with a-e, b pairs with f-j.
#   e.g. 15t.a, 30t.c, 26b.j, 35b.g.
# Rails:  <section><polarity>.<n>  section = t|b, polarity = p (+) | n (-),
#                                n = position.  e.g. tp.1 (top +), bn.25 (bottom -)
# Pin names are logical — a part's rotation changes only how it looks, never them.
BREADBOARD_COLS = {"wokwi-breadboard": 63, "wokwi-breadboard-half": 30}  # 830-pt = 63 cols
_BB_HOLE = re.compile(r"^(\d+)([tb])\.([a-j])$")
_BB_RAIL = re.compile(r"^([tb][pn])\.(\d+)$")
_SECTION_ROWS = {"t": "abcde", "b": "fghij"}

# --- plug placement geometry (calibrated in-sim; see memory) ------------------
# Seat a component's legs directly in board holes by computing its top/left/rotate
# (the "$bb" marker draws the leg but does NOT move the part). Holes are on a 9.6px
# grid (0.1"); the center ravine adds 19.2px between rows e and f. Per (type, rotate):
#   anchor = (dLeft, dTop) offset from the breadboard origin that seats the REF pin at
#            ref (pin, col, row);  pins = {pin: (dcol, drow)} hole offsets from the ref
#            pin (drow in row-index steps, a=0..j=9, ravine handled by _row_offset).
_PITCH = 9.6
_ROWS = "abcdefghij"


def _row_offset(i):
    """Vertical px from row-index 0 to row-index i (ravine adds 19.2 past row e)."""
    return i * _PITCH + (19.2 if i >= 5 else 0)


PLUG_GEOMETRY = {
    ("wokwi-led", 0):   {"anchor": (173.8, 47.4),  "ref": ("C", 18, "e"),
                         "pins": {"C": (0, 0), "A": (1, 0)}},
    ("wokwi-led", 90):  {"anchor": (23.0, 97.8),   "ref": ("C", 1, "f"),
                         "pins": {"C": (0, 0), "A": (0, 1)}},
    ("wokwi-led", 180): {"anchor": (11.0, 129.4),  "ref": ("C", 2, "h"),
                         "pins": {"C": (0, 0), "A": (-1, 0)}},
    ("wokwi-led", 270): {"anchor": (37.0, 127.0),  "ref": ("C", 6, "j"),
                         "pins": {"C": (0, 0), "A": (0, -1)}},
    ("wokwi-resistor", 0):   {"anchor": (26.0, 83.75), "ref": ("1", 1, "e"),
                              "pins": {"1": (0, 0), "2": (6, 0)}},
    ("wokwi-resistor", 180): {"anchor": (24.6, 74.45), "ref": ("1", 7, "d"),
                              "pins": {"1": (0, 0), "2": (-6, 0)}},
    ("wokwi-pushbutton-6mm", 90): {"anchor": (145.2, 90.4), "ref": ("1.l", 16, "e"),
                                   "pins": {"1.l": (0, 0), "2.l": (-2, 0),
                                            "1.r": (0, 1), "2.r": (-2, 1)}},
}

# Real ELEGOO full board: each power rail is physically SPLIT at the center into
# two halves of 25 holes (5 groups of 5). Wokwi treats the rail as one continuous
# node, so wiring that crosses the split works in the sim but NOT on hardware.
# Value = highest .n in the LEFT half (holes above it are the right half). The half
# board isn't split. TUNABLE — calibrate against the sim if the boundary is off.
RAIL_SPLIT = {"wokwi-breadboard": 25}


def _rail_split_warnings(doc):
    """Warnings for wiring that works in Wokwi (continuous rails) but is wrong on the
    physical ELEGOO board, whose full-board rails split at the center. Catches:
      (1) one rail used on BOTH halves with no bridge across the split;
      (2) the +(p) rail and the -(n) rail landing on OPPOSITE halves, so no single
          region of the real board has both power and ground.
    Returns a list of warning strings."""
    side_name = {"L": "left", "R": "right"}
    types = {p["id"]: p.get("type") for p in doc["parts"]}
    sides, bridged = {}, set()            # (pid,rail) -> {'L','R'};  bridged rails
    pol = {}                              # (pid, 'p'/'n') -> set of halves
    for c in doc["connections"]:
        ends = []
        for ep in (c[0], c[1]):
            pid, _, pin = ep.partition(":")
            split = RAIL_SPLIT.get(types.get(pid))
            m = _BB_RAIL.match(pin) if split else None
            if not m:
                ends.append(None)
                continue
            rail, n = m.group(1), int(m.group(2))
            side = "L" if n <= split else "R"
            sides.setdefault((pid, rail), set()).add(side)
            pol.setdefault((pid, rail[1]), set()).add(side)   # rail[1] = p or n
            ends.append((pid, rail, side))
        a, b = ends                       # a jumper across the same rail = a bridge
        if a and b and a[0] == b[0] and a[1] == b[1] and a[2] != b[2]:
            bridged.add((a[0], a[1]))
    warns = []
    # (1) a single rail straddling the split without a bridge
    for (pid, rail), s in sorted(sides.items()):
        if len(s) == 2 and (pid, rail) not in bridged:
            warns.append(
                f"{pid}:{rail} is wired on BOTH halves: the real ELEGOO board "
                f"splits this rail at the center, so those are separate nodes. Works "
                f"in Wokwi (continuous), dead on hardware. Keep the feed and taps on "
                f"one half, or add a bridge jumper {rail}.{RAIL_SPLIT[types[pid]]} "
                f"<-> {rail}.{RAIL_SPLIT[types[pid]] + 1}.")
    # (2) + and - rails fed on disjoint halves -> no region has both power and ground
    for pid in sorted({p for (p, _pol) in pol}):
        plus, minus = pol.get((pid, "p"), set()), pol.get((pid, "n"), set())
        if plus and minus and plus.isdisjoint(minus):
            p_h = "/".join(side_name[h] for h in sorted(plus))
            n_h = "/".join(side_name[h] for h in sorted(minus))
            warns.append(
                f"{pid}: the +(5V) rail is on the {p_h} half but GND(-) is on the "
                f"{n_h} half. On the real split board no single region has both power "
                f"and ground, so nothing there can use both. Put the + and - feeds in "
                f"the same half, or bridge the rail you need across the center.")
    return warns


def _one_pin_per_hole_warnings(doc):
    """A real breadboard hole takes exactly ONE pin/leg. Wokwi lets you stack any
    number of endpoints on the same hole; the physical ELEGOO board can't. Warn on
    any breadboard hole referenced by more than one connection endpoint."""
    types = {p["id"]: p.get("type") for p in doc["parts"]}
    count = {}
    for c in doc["connections"]:
        for ep in (c[0], c[1]):
            pid, _, pin = ep.partition(":")
            if types.get(pid) in BACKGROUND_TYPES:      # a breadboard hole
                count[(pid, pin)] = count.get((pid, pin), 0) + 1
    warns = []
    for (pid, pin), n in sorted(count.items()):
        if n > 1:
            hint = ("same column, a different a-e/f-j row" if _BB_HOLE.match(pin)
                    else "a nearby free hole on the same rail")
            warns.append(
                f"{pid}:{pin} has {n} things in one hole: a real breadboard hole takes "
                f"only one pin. Move the extra to another free hole on the same node "
                f"({hint}); it's electrically identical.")
    return warns


def breadboard_pin_error(part_type, pin):
    """None if `pin` is a valid breadboard pin, else a helpful error string."""
    m = _BB_HOLE.match(pin)
    if m:
        col, section, row = int(m.group(1)), m.group(2), m.group(3)
        cols = BREADBOARD_COLS.get(part_type)
        if cols and not (1 <= col <= cols):
            return f"column {col} out of range 1..{cols} for {part_type}"
        if row not in _SECTION_ROWS[section]:   # t holds a-e, b holds f-j
            other = "b" if section == "t" else "t"
            return (f"row '{row}' isn't in the {section} section "
                    f"({section} = {_SECTION_ROWS[section]}); use the {other} section "
                    f"for rows {_SECTION_ROWS[other]}")
        return None
    if _BB_RAIL.match(pin):
        return None
    return (f"'{pin}' isn't a breadboard pin. Holes are <col>t.<a-e> or <col>b.<f-j> "
            f"(e.g. 15t.a, 26b.j); rails are tp|tn|bp|bn.<n> (e.g. tp.1, bn.25)")

# Wire color by "net" for readable diagrams.
NET_COLOR = {"gnd": "black", "5v": "red", "vcc": "red", "3.3v": "red"}

# --- placement --------------------------------------------------------------
# On-canvas size (diagram px) of the parts we position *relative to the board*.
# The Uno's 72.58x53.34 mm body is ~274x202 px (Wokwi renders ~3.78 px/mm). The
# breadboard WIDTHS were calibrated in-sim: with the Uno at 0,0, 'below' centers
# the half breadboard at left=-25 and the full one at left=-180 (i.e. widths 324
# and 634). TUNABLE: adjust a width/height here to shift centering, or GAP for
# spacing. (breadboard-mini is still an estimate — calibrate it if you use it.)
PART_SIZE = {
    "wokwi-arduino-uno":     (274, 202),
    "wokwi-arduino-nano":    (73, 175),
    "wokwi-breadboard":      (634, 208),   # calibrated (width)
    "wokwi-breadboard-half": (324, 208),   # calibrated (width)
    "wokwi-breadboard-mini": (170, 132),   # estimate
}
DEFAULT_SIZE = (100, 60)   # small parts (LED, resistor, button, sensor, …)
GAP = 23                   # px of clearance between the board and an anchored part
                           # (calibrated: full/half breadboard sit at top=225 below a 0,0 Uno)

# Named spots relative to the reference board (the Uno unless --ref is given).
ANCHORS = ("below", "above", "left", "right",
           "below-left", "below-right", "above-left", "above-right")

# Big background parts (breadboards). These render *behind* the board and components,
# so on add they're inserted at the FRONT of the parts list (later = drawn on top).
BACKGROUND_TYPES = {"wokwi-breadboard", "wokwi-breadboard-half",
                    "wokwi-breadboard-mini"}

# Exact, in-sim-calibrated spots for parts that need rotation or a hand-tuned
# position the centering math can't derive (breadboards flanking the Uno are
# rotated to sit vertically). Keyed by (type, anchor); values are offsets from
# the board's top/left (measured with the Uno at 0,0) plus an optional rotate.
# When present these win over the computed geometry. Add rows here to calibrate
# more parts. left/right rotate the board and align its top to the Uno's; above
# mirrors below (same left, negated top).
ANCHOR_OVERRIDES = {
    ("wokwi-breadboard-half", "below"): {"top": 225,  "left": -25},
    ("wokwi-breadboard-half", "above"): {"top": -225, "left": -25},
    ("wokwi-breadboard-half", "left"):  {"top": 0, "left": -275, "rotate": 90},
    ("wokwi-breadboard-half", "right"): {"top": 0, "left": 225,  "rotate": 270},
    ("wokwi-breadboard", "below"): {"top": 225,  "left": -180},
    ("wokwi-breadboard", "above"): {"top": -225, "left": -180},
    ("wokwi-breadboard", "left"):  {"top": 0, "left": -438, "rotate": 90},
    ("wokwi-breadboard", "right"): {"top": 0, "left": 62,   "rotate": 270},
}


def load(path):
    if not os.path.exists(path):
        return {"version": 1, "author": "", "editor": "wokwi",
                "parts": [], "connections": [], "dependencies": {}}
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def save(path, doc):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(doc, f, indent=2)
        f.write("\n")


def find_part(doc, pid):
    return next((p for p in doc["parts"] if p.get("id") == pid), None)


def auto_position(doc):
    """Place a new part to the right of the board, stacked vertically."""
    existing = [p for p in doc["parts"] if p.get("left", 0) >= 200]
    return {"top": -100 + 90 * len(existing), "left": 250}


def _size(part_type):
    return PART_SIZE.get(part_type, DEFAULT_SIZE)


def find_board(doc, ref_id=None):
    """The part anchors are measured from: an explicit --ref, else the first
    Arduino board, else the first part in the diagram."""
    if ref_id:
        return find_part(doc, ref_id)
    for p in doc["parts"]:
        if p.get("type", "").startswith("wokwi-arduino"):
            return p
    return doc["parts"][0] if doc["parts"] else None


def insert_index(doc, part_type):
    """Index to insert a new part at so z-order (later in list = drawn on top)
    stays sensible: breadboards go at the FRONT (before the board and components,
    so both draw on top of the breadboard — matching what Wokwi's own editor
    emits); everything else appends to the end."""
    if part_type not in BACKGROUND_TYPES:
        return len(doc["parts"])
    idx = 0                                # insert after any leading breadboards,
    for p in doc["parts"]:                 # before the board and the rest
        if p.get("type") in BACKGROUND_TYPES:
            idx += 1
        else:
            break
    return idx


def anchor_position(doc, anchor, new_type, ref_id=None):
    """Compute {top, left[, rotate]} for a new part at a named spot around the
    board. Calibrated spots (which may rotate the part) come from
    ANCHOR_OVERRIDES; otherwise 'below'/'above' center the part horizontally on
    the board, 'left'/'right' center it vertically, and corners align to edges."""
    ref = find_board(doc, ref_id)
    if ref is None:                       # nothing to anchor to yet
        return {"top": 0, "left": 0}
    rt, rl = float(ref.get("top", 0)), float(ref.get("left", 0))
    ov = ANCHOR_OVERRIDES.get((new_type, anchor))
    if ov:                                # exact, in-sim-calibrated placement
        out = {"top": rt + ov["top"], "left": rl + ov["left"]}
        if "rotate" in ov:
            out["rotate"] = ov["rotate"]
        return out
    rw, rh = _size(ref.get("type", ""))   # reference (board) size
    nw, nh = _size(new_type)              # new part size
    cx = rl + (rw - nw) / 2.0             # left that centers new part on board (x)
    cy = rt + (rh - nh) / 2.0             # top that centers new part on board (y)
    below, above = rt + rh + GAP, rt - nh - GAP
    left, right = rl - nw - GAP, rl + rw + GAP
    table = {
        "below": (below, cx),        "above": (above, cx),
        "left":  (cy, left),         "right": (cy, right),
        "below-left":  (below, rl),  "below-right": (below, rl + rw - nw),
        "above-left":  (above, rl),  "above-right": (above, rl + rw - nw),
    }
    top, lft = table[anchor]
    return {"top": round(top, 1), "left": round(lft, 1)}


def parse_attrs(items):
    out = {}
    for it in items or []:
        if "=" not in it:
            sys.exit(f"bad --attr '{it}', expected key=value")
        k, v = it.split("=", 1)
        out[k] = v
    return out


def cmd_add(doc, a):
    if find_part(doc, a.id):
        sys.exit(f"part id '{a.id}' already exists")
    # explicit --top/--left win per-axis; else --anchor; else auto-stack.
    pos = anchor_position(doc, a.anchor, a.type, a.ref) if a.anchor \
        else auto_position(doc)
    part = {
        "type": a.type,
        "id": a.id,
        "top": a.top if a.top is not None else pos["top"],
        "left": a.left if a.left is not None else pos["left"],
    }
    rot = a.rotate if a.rotate is not None else pos.get("rotate")
    if rot:                               # explicit --rotate, else anchor's rotate
        part["rotate"] = rot
    part["attrs"] = parse_attrs(a.attr)
    doc["parts"].insert(insert_index(doc, a.type), part)  # z-order aware
    via = f" (anchor={a.anchor} of {find_board(doc, a.ref)['id']})" \
        if a.anchor and find_board(doc, a.ref) else ""
    print(f"added {a.type} id={a.id} at top={part['top']} left={part['left']}"
          f"{' rotate=' + str(rot) if rot else ''}{via}")


def cmd_move(doc, a):
    p = find_part(doc, a.id) or sys.exit(f"no part id '{a.id}'")
    if a.anchor:                          # snap to a named spot, then let
        pos = anchor_position(doc, a.anchor, p.get("type", ""), a.ref)
        p["top"], p["left"] = pos["top"], pos["left"]
        if "rotate" in pos:
            p["rotate"] = pos["rotate"]
        elif p.get("type") in BACKGROUND_TYPES:
            p.pop("rotate", None)         # e.g. left(90) -> below clears rotation
    if a.top is not None:                 # explicit --top/--left still win
        p["top"] = a.top
    if a.left is not None:
        p["left"] = a.left
    if a.rotate is not None:
        p["rotate"] = a.rotate
    print(f"moved {a.id} -> top={p.get('top')} left={p.get('left')} "
          f"rotate={p.get('rotate', 0)}")


def cmd_attr(doc, a):
    p = find_part(doc, a.id) or sys.exit(f"no part id '{a.id}'")
    p.setdefault("attrs", {}).update(parse_attrs(a.attr))
    print(f"{a.id} attrs -> {p['attrs']}")


def _net_color(*endpoints):
    for ep in endpoints:
        pin = ep.split(":", 1)[1].lower()
        for key, col in NET_COLOR.items():
            if pin.startswith(key) or pin.endswith(key):
                return col
    return "green"


def cmd_connect(doc, a):
    for ep in (a.a, a.b):
        if ":" not in ep:
            sys.exit(f"endpoint '{ep}' must be ID:PIN")
        pid = ep.split(":", 1)[0]
        if not find_part(doc, pid):
            sys.exit(f"no part id '{pid}' (referenced by {ep})")
    if a.plug:
        # Seat a component leg directly in a breadboard hole (no cable). Wokwi's
        # marker for this is an empty color + a "$bb" route, e.g.
        #   [ "led1:A", "bb1:26t.e", "", [ "$bb" ] ]
        doc["connections"].append([a.a, a.b, "", ["$bb"]])
        print(f"plugged {a.a} into {a.b}")
    else:
        color = a.color or _net_color(a.a, a.b)
        # "*" is Wokwi's auto-route token: a clean orthogonal path, not a diagonal.
        doc["connections"].append([a.a, a.b, color, ["*"]])
        print(f"connected {a.a} <-> {a.b} ({color})")


def cmd_plug(doc, a):
    """Position a component so PIN seats in BBID:HOLE (a grid hole), and wire every
    leg into its hole with $bb plugs. Computes top/left/rotate from PLUG_GEOMETRY."""
    part = find_part(doc, a.id) or sys.exit(f"no part id '{a.id}'")
    rot = a.rotate if a.rotate is not None else int(part.get("rotate", 0))
    geo = PLUG_GEOMETRY.get((part["type"], rot))
    if not geo:
        avail = ", ".join(sorted(f"{t}@{r}" for (t, r) in PLUG_GEOMETRY))
        sys.exit(f"no plug geometry for {part['type']} at rotate {rot}. "
                 f"Calibrated: {avail}. (Add a row to PLUG_GEOMETRY to teach it.)")
    if ":" not in a.hole:
        sys.exit("hole must be BBID:HOLE, e.g. bb1:18t.e")
    bbid, hole = a.hole.split(":", 1)
    bb = find_part(doc, bbid) or sys.exit(f"no part id '{bbid}'")
    if bb.get("type") not in BACKGROUND_TYPES:
        sys.exit(f"{bbid} is not a breadboard")
    m = _BB_HOLE.match(hole)
    if not m:
        sys.exit(f"plug target must be a grid hole <col>t|b.<a-j>, got '{hole}'")
    if a.pin not in geo["pins"]:
        sys.exit(f"{part['type']} plug geometry has no pin '{a.pin}' "
                 f"(pins: {', '.join(geo['pins'])})")
    cols = BREADBOARD_COLS.get(bb["type"], 63)
    col, row_i = int(m.group(1)), _ROWS.index(m.group(3))
    # back-compute the reference pin's hole from the pin the caller anchored on
    dc, dr = geo["pins"][a.pin]
    ref_col, ref_row_i = col - dc, row_i - dr
    # translate the calibration anchor by whole pitches to the requested spot
    g_col, g_row_i = geo["ref"][1], _ROWS.index(geo["ref"][2])
    d_left = geo["anchor"][0] + (ref_col - g_col) * _PITCH
    d_top = geo["anchor"][1] + (_row_offset(ref_row_i) - _row_offset(g_row_i))
    # resolve every pin's hole first (so we fail before mutating on off-board legs)
    seats = []
    for pin, (pdc, pdr) in geo["pins"].items():
        pc, pri = ref_col + pdc, ref_row_i + pdr
        if not (0 <= pri < len(_ROWS)) or not (1 <= pc <= cols):
            sys.exit(f"pin {pin} would land off the board (col {pc}, "
                     f"row {_ROWS[pri] if 0 <= pri < len(_ROWS) else pri})")
        pr = _ROWS[pri]
        seats.append((pin, f"{pc}{'t' if pr in 'abcde' else 'b'}.{pr}"))
    # place the part
    part["top"] = round(float(bb.get("top", 0)) + d_top, 1)
    part["left"] = round(float(bb.get("left", 0)) + d_left, 1)
    if rot:
        part["rotate"] = rot
    else:
        part.pop("rotate", None)
    # replace this part's connections with fresh $bb plugs to each seated hole
    doc["connections"] = [c for c in doc["connections"]
                          if c[0].split(":", 1)[0] != a.id
                          and c[1].split(":", 1)[0] != a.id]
    for pin, h in seats:
        doc["connections"].append([f"{a.id}:{pin}", f"{bbid}:{h}", "", ["$bb"]])
    print(f"plugged {a.id} ({part['type']} @{rot}) at top={part['top']} "
          f"left={part['left']}: " + ", ".join(f"{p}->{h}" for p, h in seats))


# Serial Monitor config (top-level "serialMonitor" key in diagram.json).
_SERIAL_DISPLAY = ("auto", "always", "never", "plotter", "terminal")
_SERIAL_NEWLINE = ("lf", "cr", "crlf", "none")


def cmd_serial(doc, a):
    """Set/merge the diagram's serialMonitor block. Only given options change; the
    rest are left as-is. Default display 'auto' is why the monitor is easy to lose —
    'always' opens it from sim start, 'terminal' is the XTerm view (color, good for
    typing input)."""
    sm = doc.setdefault("serialMonitor", {})
    if a.display is not None:
        sm["display"] = a.display
    if a.newline is not None:
        sm["newline"] = a.newline
    if a.collapse is not None:
        sm["collapse"] = a.collapse
    if a.convert_eol is not None:
        sm["convertEol"] = a.convert_eol
    if not sm:
        del doc["serialMonitor"]
        print("serialMonitor: unset (Wokwi defaults: display=auto, newline=lf)")
    else:
        print("serialMonitor: " + json.dumps(sm))


def cmd_remove(doc, a):
    if not find_part(doc, a.id):
        sys.exit(f"no part id '{a.id}'")
    doc["parts"] = [p for p in doc["parts"] if p.get("id") != a.id]
    before = len(doc["connections"])
    doc["connections"] = [
        c for c in doc["connections"]
        if not (c[0].split(":", 1)[0] == a.id or c[1].split(":", 1)[0] == a.id)
    ]
    print(f"removed {a.id} and {before - len(doc['connections'])} connection(s)")


def cmd_list(doc, a):
    print("PARTS:")
    for p in doc["parts"]:
        print(f"  {p['id']:<12} {p['type']:<26} "
              f"top={p.get('top')} left={p.get('left')} "
              f"rotate={p.get('rotate', 0)} attrs={p.get('attrs', {})}")
    print("CONNECTIONS:")
    for c in doc["connections"]:
        print(f"  {c[0]:<16} <-> {c[1]:<16} {c[2]}")


def cmd_validate(doc, a):
    problems = []
    ids = [p.get("id") for p in doc["parts"]]
    for i in ids:
        if ids.count(i) > 1:
            problems.append(f"duplicate part id: {i}")
    types = {p["id"]: p["type"] for p in doc["parts"]}
    for c in doc["connections"]:
        for ep in (c[0], c[1]):
            if ":" not in ep:
                problems.append(f"connection endpoint not ID:PIN: {ep}")
                continue
            pid, pin = ep.split(":", 1)
            if pid not in types:
                problems.append(f"connection references unknown part: {ep}")
                continue
            t = types[pid]
            if t in BACKGROUND_TYPES:          # breadboards: check hole/rail name
                err = breadboard_pin_error(t, pin)
                if err:
                    problems.append(f"{ep}: {err}")
                continue
            if t in PIN_CHECK_SKIP:
                continue
            if t in PIN_DB and pin not in PIN_DB[t]:
                problems.append(
                    f"pin '{pin}' not valid for {t} (part {pid}); "
                    f"valid: {', '.join(PIN_DB[t])}")
            elif t not in PIN_DB:
                problems.append(
                    f"NOTE: pins for type '{t}' not in PIN_DB; verify {ep} "
                    f"at https://docs.wokwi.com/parts/{t}")
    warnings = _rail_split_warnings(doc) + _one_pin_per_hole_warnings(doc)
    if problems:
        print("validate: found issues:")
        for p in problems:
            print("  - " + p)
    if warnings:
        print("validate: warnings (works in Wokwi, wrong on real hardware):")
        for w in warnings:
            print("  ! " + w)
    if not problems:
        print("validate: OK" + (" (with warnings)" if warnings else ""))
        return 0
    return 1


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--file", default="diagram.json", help="path to diagram.json")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("add"); p.add_argument("type"); p.add_argument("id")
    p.add_argument("--top", type=float); p.add_argument("--left", type=float)
    p.add_argument("--rotate", type=int); p.add_argument("--attr", action="append")
    p.add_argument("--anchor", choices=ANCHORS,
                   help="place at a named spot around the board (see --ref)")
    p.add_argument("--ref", help="part id to anchor to (default: the Arduino board)")
    p.set_defaults(func=cmd_add)

    p = sub.add_parser("move"); p.add_argument("id")
    p.add_argument("--top", type=float); p.add_argument("--left", type=float)
    p.add_argument("--rotate", type=int)
    p.add_argument("--anchor", choices=ANCHORS,
                   help="snap to a named spot around the board (see --ref)")
    p.add_argument("--ref", help="part id to anchor to (default: the Arduino board)")
    p.set_defaults(func=cmd_move)

    p = sub.add_parser("attr"); p.add_argument("id")
    p.add_argument("--attr", action="append", required=True)
    p.set_defaults(func=cmd_attr)

    p = sub.add_parser("connect"); p.add_argument("a"); p.add_argument("b")
    p.add_argument("--color")
    p.add_argument("--plug", action="store_true",
                   help="seat a component leg directly in a breadboard hole "
                        "(no cable) — use for COMP:PIN -> BB:HOLE")
    p.set_defaults(func=cmd_connect)

    p = sub.add_parser("plug"); p.add_argument("id"); p.add_argument("pin")
    p.add_argument("hole", help="BBID:HOLE grid target, e.g. bb1:18t.e")
    p.add_argument("--rotate", type=int, help="0/90/180/270 (default: the part's)")
    p.set_defaults(func=cmd_plug)

    p = sub.add_parser("serial")
    p.add_argument("--display", choices=_SERIAL_DISPLAY,
                   help="auto (default, easy to lose) | always | never | plotter | terminal")
    p.add_argument("--newline", choices=_SERIAL_NEWLINE,
                   help="appended to typed input lines: lf (default) | cr | crlf | none")
    p.add_argument("--collapse", action=argparse.BooleanOptionalAction, default=None)
    p.add_argument("--convert-eol", dest="convert_eol",
                   action=argparse.BooleanOptionalAction, default=None,
                   help="terminal mode: convert \\n to \\r\\n")
    p.set_defaults(func=cmd_serial)

    p = sub.add_parser("remove"); p.add_argument("id"); p.set_defaults(func=cmd_remove)
    p = sub.add_parser("list"); p.set_defaults(func=cmd_list)
    p = sub.add_parser("validate"); p.set_defaults(func=cmd_validate)

    a = ap.parse_args()
    doc = load(a.file)
    rc = a.func(doc, a)
    if a.cmd != "validate" and a.cmd != "list":
        save(a.file, doc)
    sys.exit(rc or 0)


if __name__ == "__main__":
    main()
