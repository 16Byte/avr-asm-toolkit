; blink.S — GNU-syntax AVR assembly (avr-gcc), the dialect the course labs use.
; Defines the two routines the .ino calls. Practice bit-manipulation here:
; sbi/cbi set/clear a bit; sbis/sbic skip on a bit (for reading inputs).
;
; .S (capital) is run through the C preprocessor first, so <avr/io.h> works and
; gives register names + _SFR_IO_ADDR() for the I/O-space instructions.

#include <avr/io.h>

    .global asm_led_on
    .global asm_led_off

asm_led_on:
    sbi _SFR_IO_ADDR(PORTB), 5     ; PB5 = 1 -> LED on
    ret

asm_led_off:
    cbi _SFR_IO_ADDR(PORTB), 5     ; PB5 = 0 -> LED off
    ret
