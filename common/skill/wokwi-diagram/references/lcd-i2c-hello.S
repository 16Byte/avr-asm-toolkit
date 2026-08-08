; ============================================================================
; REFERENCE DRIVER — I2C (PCF8574 backpack) HD44780 LCD1602, pure AVR assembly.
;
; Known-good, Wokwi-verified. Reuse this instead of re-deriving the HD44780 init
; from scratch (the 4-bit-over-TWI dance is fiddly and easy to get subtly wrong).
; GNU / avr-gcc syntax (World B: Arduino .ino + .S), NOT AVRASM2.
;
; HOW TO USE
;   1. Copy this file into the sketch folder (e.g. as lcd.S).
;   2. Minimal .ino:
;          extern "C" void lcd_hello(void);
;          void setup() { lcd_hello(); }
;          void loop()  {}
;   3. Wire in diagram.json: a wokwi-lcd1602 with attrs { "pins": "i2c" },
;      SDA -> uno:A4, SCL -> uno:A5, VCC -> 5V, GND -> GND.
;
; HOW TO ADAPT
;   - Change the message: edit the .asciz string at the bottom (<=16 chars/line).
;   - Different backpack I2C address: SLA_W = (addr << 1). 0x27 -> 0x4E, 0x3F -> 0x7E.
;   - Delays assume 16 MHz (the Wokwi Uno).
;
; NOTE: this is the I2C-backpack LCD (4 wires). The parallel 16-pin LCD1602 (what
; some kits ship) needs a different driver (RS/E/D4-D7 on GPIO) — ask for that variant.
;
; PCF8574 -> HD44780 bit mapping: P0=RS P1=RW P2=E P3=Backlight P4..P7=data nibble.
; RW held 0 (write); backlight bit set on every byte.
; ============================================================================

; ---- ATmega328P TWI registers (extended I/O -> lds/sts, not in/out) ----
#define TWBR_ADDR 0xB8
#define TWSR_ADDR 0xB9
#define TWDR_ADDR 0xBB
#define TWCR_ADDR 0xBC
#define TWINT 7
#define TWSTA 5
#define TWSTO 4
#define TWEN  2

; ---- LCD / PCF8574 constants ----
#define SLA_W 0x4E   ; (0x27 << 1) | 0  -> address + write
#define BL    0x08   ; backlight bit
#define EN    0x04   ; enable strobe
#define RS    0x01   ; register-select (1 = data, 0 = command)

    .text

; lcd_hello — public entry: init TWI + LCD, print the message.  void(void)
    .global lcd_hello
lcd_hello:
    rcall twi_init

    ldi   r24, 50
    rcall delay_ms            ; >15 ms power-up wait

    ; --- HD44780 4-bit init dance (raw high-nibble writes, RS=0) ---
    ldi   r24, 0x30 | BL
    rcall lcd_pulse
    ldi   r24, 5
    rcall delay_ms

    ldi   r24, 0x30 | BL
    rcall lcd_pulse
    rcall delay_150us

    ldi   r24, 0x30 | BL
    rcall lcd_pulse
    rcall delay_150us

    ldi   r24, 0x20 | BL      ; switch to 4-bit interface
    rcall lcd_pulse
    rcall delay_150us

    ; --- full-byte commands (RS=0) ---
    ldi   r24, 0x28           ; function set: 4-bit, 2 lines, 5x8 font
    clr   r22
    rcall lcd_send

    ldi   r24, 0x0C           ; display on, cursor off, blink off
    clr   r22
    rcall lcd_send

    ldi   r24, 0x01           ; clear display
    clr   r22
    rcall lcd_send
    ldi   r24, 2
    rcall delay_ms

    ldi   r24, 0x06           ; entry mode: increment, no shift
    clr   r22
    rcall lcd_send

    ldi   r24, 0x80           ; DDRAM address 0 -> row 0, col 0
    clr   r22
    rcall lcd_send

    ; --- print the message from flash ---
    ldi   r30, lo8(lcd_msg)
    ldi   r31, hi8(lcd_msg)
1:  lpm   r24, Z+
    tst   r24
    breq  2f
    ldi   r22, RS             ; RS=1 -> character data
    push  r30
    push  r31
    rcall lcd_send
    pop   r31
    pop   r30
    rjmp  1b
2:  ret

; lcd_send — send one byte as two 4-bit nibbles.  r24 = value, r22 = RS bit.
lcd_send:
    mov   r23, r24            ; keep the original byte
    andi  r24, 0xF0           ; high nibble
    ori   r24, BL
    or    r24, r22
    rcall lcd_pulse
    mov   r24, r23            ; low nibble
    swap  r24
    andi  r24, 0xF0
    ori   r24, BL
    or    r24, r22
    rcall lcd_pulse
    ret

; lcd_pulse — put r24 on the bus, strobe E high->low so the HD44780 latches it.
lcd_pulse:
    push  r24
    ori   r24, EN             ; E high
    rcall twi_write_byte
    rcall delay_50us
    pop   r24                 ; E low (original byte)
    rcall twi_write_byte
    rcall delay_50us
    ret

; twi_init — 100 kHz master, TWI enabled.
twi_init:
    clr   r24
    sts   TWSR_ADDR, r24      ; prescaler = 1
    ldi   r24, 72             ; TWBR: SCL = 16MHz/(16+2*72) = 100 kHz
    sts   TWBR_ADDR, r24
    ldi   r24, (1<<TWEN)
    sts   TWCR_ADDR, r24
    ret

; twi_write_byte — one full transaction: START, SLA+W, data, STOP.  r24 = data.
; (No ACK checking — Wokwi's LCD always ACKs; keeps the code short.)
twi_write_byte:
    ldi   r25, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)   ; START
    sts   TWCR_ADDR, r25
1:  lds   r25, TWCR_ADDR
    sbrs  r25, TWINT
    rjmp  1b
    ldi   r25, SLA_W                             ; address + write
    sts   TWDR_ADDR, r25
    ldi   r25, (1<<TWINT)|(1<<TWEN)
    sts   TWCR_ADDR, r25
2:  lds   r25, TWCR_ADDR
    sbrs  r25, TWINT
    rjmp  2b
    sts   TWDR_ADDR, r24                         ; data byte
    ldi   r25, (1<<TWINT)|(1<<TWEN)
    sts   TWCR_ADDR, r25
3:  lds   r25, TWCR_ADDR
    sbrs  r25, TWINT
    rjmp  3b
    ldi   r25, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)   ; STOP
    sts   TWCR_ADDR, r25
    ret

; Busy-wait delays (16 MHz).  Clobber r24 and Z (r30:r31) only.
delay_ms:                    ; r24 = milliseconds
1:  ldi   r31, hi8(4000)
    ldi   r30, lo8(4000)
2:  sbiw  r30, 1             ; 4 cyc/iteration -> 4000*4 = 16000 = 1 ms
    brne  2b
    subi  r24, 1
    brne  1b
    ret

delay_150us:
    rcall delay_50us
    rcall delay_50us
    ; fall through for the third 50 us
delay_50us:                  ; ~50 us
    ldi   r31, hi8(200)
    ldi   r30, lo8(200)
1:  sbiw  r30, 1             ; 200*4 = 800 cyc = 50 us
    brne  1b
    ret

    .section .progmem.data,"a",@progbits
lcd_msg:
    .asciz "Hello, World!"
