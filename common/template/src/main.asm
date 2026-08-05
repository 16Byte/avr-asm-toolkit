;==============================================================
; main.asm  -  ATmega328P blink, AVRASM2 syntax
;
; Dialect: Atmel/Microchip Studio (AVRASM2) -- same as the Mazidi
; textbook. Assembled here with `avra`, emulated in Wokwi.
;
; Blinks the LED on PB5 (Arduino digital pin 13) at 16 MHz.
; Build:  press Ctrl+Shift+B  (or run  .\build.ps1)
;==============================================================

.include "m328Pdef.inc"        ; register/bit names: DDRB, PORTB, SPL/SPH, RAMEND...

.cseg                          ; code segment (flash)
.org 0x0000
    rjmp RESET                 ; the reset vector: on power-up the CPU starts at 0

;--------------------------------------------------------------
; RESET - program entry
;--------------------------------------------------------------
RESET:
    ; Unlike C, nothing sets up the stack for us. Point the stack
    ; pointer at the top of RAM (RAMEND) so rcall/ret/push/pop work.
    ldi  r16, high(RAMEND)
    out  SPH, r16
    ldi  r16, low(RAMEND)
    out  SPL, r16

    sbi  DDRB, 5               ; DDRB bit5 = 1  -> PB5 is an OUTPUT

;--------------------------------------------------------------
; Main loop
;--------------------------------------------------------------
BLINK:
    sbi  PORTB, 5             ; PB5 = 1 -> LED on
    rcall DELAY
    cbi  PORTB, 5             ; PB5 = 0 -> LED off
    rcall DELAY
    rjmp BLINK

;--------------------------------------------------------------
; DELAY - crude busy-wait, ~0.5 s at 16 MHz.
; Exercise: compute the exact cycle count (taken brne = 2 cycles,
; not-taken = 1) and retune r18 for a precise interval.
;--------------------------------------------------------------
DELAY:
    ldi  r18, 41
D1: ldi  r19, 0               ; 0 -> 256 iterations
D2: ldi  r20, 0               ; 0 -> 256 iterations
D3: dec  r20
    brne D3
    dec  r19
    brne D2
    dec  r18
    brne D1
    ret
