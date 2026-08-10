// Starter Arduino sketch (World B) — the .ino drives the program and calls
// assembly routines defined in blink.S. This is the same .ino + .S structure the
// course labs use (e.g. Lab5.ino + push_button.S): write your bit-manipulation
// (sbi/cbi/sbis/sbic) in the .S file and call it from here.
//
// For a lab: scaffold a project named after the lab, then replace this file and
// blink.S with the lab's provided files (keep the .ino named the same as the folder).

extern "C" void asm_led_on(void);
extern "C" void asm_led_off(void);

void setup() {
  DDRB |= (1 << 5);        // PB5 (Arduino D13) as output
}

void loop() {
  asm_led_on();
  delay(500);
  asm_led_off();
  delay(500);
}
