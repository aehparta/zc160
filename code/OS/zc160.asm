;******************************************************************************
;
;
; The ZC160 Operating System
;
;
;
; Authors: Antti Partanen, <aehparta@iki.fi>
;
;******************************************************************************


.include "zc160.def"


;******************************************************************************
; Basic reset and interrupt vectors.

; code origin and reset vector $0000
.org $0000
    di
    jp reset

; rst $0008
.org $0008
    reti

; rst $0010
.org $0010
    reti

; rst $0018
.org $0018
    reti

; rst $0020
.org $0020
    reti

; rst $0028
.org $0028
    reti

; rst $0030
.org $0030
    reti

; rst $0038 or /INT-signal in interrupt mode 1
.org $0038
    reti


;******************************************************************************
; Very basic delay routine for multiples of milliseconds.
; Interrupts are not disabled during this delay, so they can mix it up.
; Either way it is not totally accurate.
;
; bc: delay in milliseconds
;
.org $0040
delay_ms:
    push af
delay_ms0:
    ld a, 80
delay_ms1:              ; 1ms delay
    nop                 ; 4 clocks / 1us
    nop                 ; 4 clocks / 1us
    nop                 ; 4 clocks / 1us
    nop                 ; 4 clocks / 1us
    nop                 ; 4 clocks / 1us
    nop                 ; 4 clocks / 1us
    nop                 ; 4 clocks / 1us
    nop                 ; 4 clocks / 1us
    nop                 ; 4 clocks / 1us
    dec a               ; 4 clocks / 1us
    jp nz, delay_ms1    ; 10 clocks / 2.5us
    ; count for that total delay
    dec bc
    ; a is zero here without touching it!
    cp b
    jp nz, delay_ms0
    cp c
    jp nz, delay_ms0
    ;
    pop af
    ret


;******************************************************************************
; This is the point where the processor comes when NMI-interrupt is signalled.
.org $0066
 retn




;******************************************************************************
;******************************************************************************
; Here starts the actual operating system code.
;******************************************************************************
;******************************************************************************
.org $0070
.db "zc160os by duge\0\0\0\0"


;******************************************************************************
; Wait until the LCD is ready to receive new command.
;
; registers changed: a
;
lcd_wait:
    in a, (LCD_REG_CMD)
    and %10000000
    jr nz, lcd_wait
    ret

    
;******************************************************************************
; Write byte in register b to LCD command register.
;
; registers changed: a
;
lcd_cmd:
    call lcd_wait
    ld a, b
    out (LCD_REG_CMD), a
    ret


;******************************************************************************
; Init LCD display.
lcd_init:
    push af
    push bc
    ld b, %00110000
    call lcd_cmd
    ld b, %00000110
    call lcd_cmd
    ld b, %00001111
    call lcd_cmd
    ld b, %00010000
    call lcd_cmd
    ld b, %00000001
    call lcd_cmd
    pop bc
    pop af
    ret


;******************************************************************************
; Clear LCD display.
lcd_clear:
    push af
    push bc
    ld b, %00000001
    call lcd_cmd
    pop bc
    pop af
    ret


;******************************************************************************
; Write string to LCD.
;
; hl: string pointer
;
lcd_puts:
    push af
lcd_puts_cont:
    call lcd_wait
    ld a, (hl)
    cp EOL
    jp z, lcd_puts_ret
    out (LCD_REG_DATA), a
    inc hl
    jp lcd_puts_cont
lcd_puts_ret:
    pop af
    ret


;******************************************************************************
; Set character address to LCD.
;
; h: line
; l: column
;
lcd_addr:
    push af
    push bc
    ld a, h
    cp $00
    jp z, lcd_addr_line_selected
    ld a, 40
lcd_addr_line_selected:
    add a, l
    or $80
    ld b, a
    call lcd_cmd
    pop bc
    pop af
    ret
    
    
;******************************************************************************
; Memory copy using DMA. Will override even NMI, but will keep memory
; refresh up.
;
; clock cycles:
;   ld a, R:        6 * 4     = 24
;   out (BYTE), a:  6 * 11    = 66
;   ret:                      = 10
;   total:                    = 100
;
; DMA cycles (not including start and end of bus request):
;   byte_count * 2 = clock cycles
;
; hl: source
; de: destination
; bc: bytes to transfer
; registers changed: a
;
memcpy_dma:
    ld a, l
    out (DMA_SRCL), a
    ld a, h
    out (DMA_SRCH), a
    ld a, e
    out (DMA_DSTL), a
    ld a, d
    out (DMA_DSTH), a
    ld a, c
    out (DMA_CNTL), a
    ld a, b
    out (DMA_CNTH), a
    ; DMA controller takes control of the system using BUSRQ when DMA_CNTH is
    ; written and will be finished before next 'ret' is complete
    ret


;******************************************************************************
; Setup and start the ZC160 Operating System.
reset:
; setup stack pointer
    ld sp, OS_STACK
; memory bank windows $8000-bfff and $c000-ffff to memory banks 0 and 1
    ld a, $10
    out (MB_LATCH), a
; setup lcd
    call lcd_init
    ld hl, $0000
    call lcd_addr
    ld hl, POWERON0
    call lcd_puts
    ld hl, $0100
    call lcd_addr
    ld hl, POWERON1
    call lcd_puts
    halt


;******************************************************************************
; Strings
POWERON0:       .db "  ZC160 OS v1.0 ", EOL
POWERON1:       .db "   booting...   ", EOL


