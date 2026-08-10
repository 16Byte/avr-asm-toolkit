.text
    .global lightup
lightup:
    ldi r18, 0b00110001
    out 0x04, r18   ; io address of DDRB
    out 0x05, r18   ; io address of PORTB
    ret
