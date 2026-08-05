#!/usr/bin/env python3
"""
wokwi_diagram.py - programmatic editor + validator for Wokwi diagram.json.

Exists because Wokwi's graphical editor is a paid feature. This lets you add,
move, wire, and remove parts from the command line and, importantly, VALIDATE
the result so a typo in a pin name doesn't silently produce a dead circuit.

Commands (run from a project dir containing diagram.json, or pass --file):
    list                              show parts and connections
    add    TYPE ID [--top T --left L] [--rotate R] [--attr k=v ...]
    move   ID --top T --left L [--rotate R]
    attr   ID --attr k=v ...          set/replace attributes on a part
    connect A:PIN B:PIN [--color C]   wire two pins (default color by net)
    remove ID                         delete a part and any connections to it
    validate                          check JSON, part refs, and pin names

Pin names come from PIN_DB below (verified against docs.wokwi.com). For a part
type not in PIN_DB, pin checks are skipped with a note -- look the part up at
https://docs.wokwi.com/parts/<type> and add it here if you use it a lot.
"""
import argparse
import json
import os
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
PIN_CHECK_SKIP = {"wokwi-breadboard", "wokwi-breadboard-half",
                  "wokwi-breadboard-mini", "wokwi-ir-remote"}

# Wire color by "net" for readable diagrams.
NET_COLOR = {"gnd": "black", "5v": "red", "vcc": "red", "3.3v": "red"}


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
    pos = auto_position(doc)
    part = {
        "type": a.type,
        "id": a.id,
        "top": a.top if a.top is not None else pos["top"],
        "left": a.left if a.left is not None else pos["left"],
        "attrs": parse_attrs(a.attr),
    }
    if a.rotate:
        part["rotate"] = a.rotate
    doc["parts"].append(part)
    print(f"added {a.type} id={a.id} at top={part['top']} left={part['left']}")


def cmd_move(doc, a):
    p = find_part(doc, a.id) or sys.exit(f"no part id '{a.id}'")
    if a.top is not None:
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
    color = a.color or _net_color(a.a, a.b)
    doc["connections"].append([a.a, a.b, color, []])
    print(f"connected {a.a} <-> {a.b} ({color})")


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
    if not problems:
        print("validate: OK")
        return 0
    print("validate: found issues:")
    for p in problems:
        print("  - " + p)
    return 1


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--file", default="diagram.json", help="path to diagram.json")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("add"); p.add_argument("type"); p.add_argument("id")
    p.add_argument("--top", type=float); p.add_argument("--left", type=float)
    p.add_argument("--rotate", type=int); p.add_argument("--attr", action="append")
    p.set_defaults(func=cmd_add)

    p = sub.add_parser("move"); p.add_argument("id")
    p.add_argument("--top", type=float); p.add_argument("--left", type=float)
    p.add_argument("--rotate", type=int); p.set_defaults(func=cmd_move)

    p = sub.add_parser("attr"); p.add_argument("id")
    p.add_argument("--attr", action="append", required=True)
    p.set_defaults(func=cmd_attr)

    p = sub.add_parser("connect"); p.add_argument("a"); p.add_argument("b")
    p.add_argument("--color"); p.set_defaults(func=cmd_connect)

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
