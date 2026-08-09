# ELEGOO UNO R3 Super Starter Kit → Wokwi parts

Maps each kit component to its Wokwi `type` string with **verified** pin names
(from docs.wokwi.com) and the attrs you'll actually set. Pin names are what you
put after the colon in a connection endpoint, e.g. `"led1:A"`.

For any part not in this table, its canonical pins are at
`https://docs.wokwi.com/parts/<type>` — check there rather than guessing, and
consider adding it to `PIN_DB` in `scripts/wokwi_diagram.py`.

## Board
| Kit item | type | pins | notes |
|---|---|---|---|
| UNO R3 | `wokwi-arduino-uno` | `0`–`13`, `A0`–`A5`, `5V`, `3.3V`, `VIN`, `GND.1`, `GND.2`, `GND.3`, `AREF`, `IOREF`, `RESET` | 3 separate grounds: `GND.1` (top by pin 13), `GND.2`/`GND.3` (bottom). `RESET`/`AREF` not simulated. |

## Output
| Kit item | type | pins | key attrs |
|---|---|---|---|
| LED (red/yellow/green/blue) | `wokwi-led` | `A` (anode +), `C` (cathode −) | `color` (red/green/blue/yellow…), `label` |
| RGB LED | `wokwi-rgb-led` | `R`, `G`, `B`, `COM` | `common` = `anode` (default) or `cathode` |
| 1-digit 7-seg | `wokwi-7segment` | `A`–`G`, `DP`, `COM` | `common` = `anode`/`cathode`, `color` |
| 4-digit 7-seg | `wokwi-7segment` | `A`–`G`, `DP`, `DIG1`–`DIG4`, `CLN` | `digits=4`, `common`, `colon=1` for clock |
| Active/Passive buzzer | `wokwi-buzzer` | `1` (−), `2` (+) | `volume`, `mode` (smooth/accurate) |
| 5V Relay | `wokwi-relay-module` | control: `VCC`,`GND`,`IN`; switched: `COM`,`NO`,`NC` | `transistor` = `npn` (active-high) / `pnp` |
| LCD1602 | `wokwi-lcd1602` | full: `VSS`,`VDD`,`V0`,`RS`,`RW`,`E`,`D0`–`D7`,`A`,`K`; i2c: `GND`,`VCC`,`SDA`,`SCL` | `pins`=`full`(default)/`i2c`, `i2cAddress`, `background`, `color` |

## Input
| Kit item | type | pins | key attrs |
|---|---|---|---|
| Button (small) | `wokwi-pushbutton` | `1.l`,`1.r`,`2.l`,`2.r` | `color`, `label`, `key` (keyboard), `bounce=0` |
| Potentiometer | `wokwi-potentiometer` | `GND`, `SIG`, `VCC` | `value` (0–1023 initial) |
| Joystick | `wokwi-analog-joystick` | `VCC`,`VERT`,`HORZ`,`SEL`,`GND` | `bounce` |
| Tilt switch | *(no native part)* | — | substitute `wokwi-slide-switch` (`1`,`2`,`3`) or a `wokwi-pushbutton` |

## Sensors
| Kit item | type | pins | key attrs |
|---|---|---|---|
| Ultrasonic HC-SR04 | `wokwi-hc-sr04` | `VCC`,`TRIG`,`ECHO`,`GND` | `distance` (cm, initial) |
| DHT11 temp/humidity | `wokwi-dht22` | `VCC`,`SDA`,`NC`,`GND` | `temperature`, `humidity` — Wokwi models the DHT22; protocol is the DHT family, fine for practice |
| Photoresistor | `wokwi-photoresistor-sensor` | `VCC`,`GND`,`DO`,`AO` | `lux`, `threshold` |
| Thermistor | `wokwi-ntc-temperature-sensor` | `VCC`,`OUT`,`GND` | `temperature`, `beta` |

## Motors / actuators
| Kit item | type | pins | key attrs |
|---|---|---|---|
| Servo (SG90) | `wokwi-servo` | `PWM`,`V+`,`GND` | `horn`, `hornColor` |
| Stepper + ULN2003 | `wokwi-stepper-motor` | `A+`,`A-`,`B+`,`B-` | Wokwi models a **bipolar** stepper; the kit's 28BYJ-48+ULN2003 is unipolar, so this is an approximation for practice |

## Logic / misc
| Kit item | type | pins | key attrs |
|---|---|---|---|
| 74HC595 shift register | `wokwi-74hc595` | `DS`,`SHCP`,`STCP`,`OE`,`MR`,`GND`,`VCC`,`Q0`–`Q7`,`Q7S` | — |
| IR receiver | `wokwi-ir-receiver` | `GND`,`VCC`,`DAT` | pairs with `wokwi-ir-remote` |
| IR remote | `wokwi-ir-remote` | *(virtual; no wired pins)* | — |
| Resistor | `wokwi-resistor` | `1`, `2` | `value` (ohms, e.g. `220`, `10000`) |
| Breadboard | `wokwi-breadboard` / `-half` / `-mini` | holes `<col>t.<a-e>` / `<col>b.<f-j>` (e.g. `45t.c`, `26b.j`), rails `tp\|tn\|bp\|bn.<n>` (e.g. `bn.25`) | full=60 cols, half=30; `t`=abcde side, `b`=fghij side; `validate` checks these — see schema.md → *Breadboard pins* |

## No Wokwi equivalent (skip / substitute)
Power-supply module, 9V battery, USB cable, jumper wires (wires = connections),
1N4007 diode, PN2222 transistor, Dupont wires. These are physical-only; model the
*circuit behavior* instead (e.g., wire power directly to `5V`/`GND`).
