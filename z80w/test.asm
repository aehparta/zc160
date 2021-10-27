
#define equ .equ
#define CPU_AT_4MHZ

; Stack Pointer start value,
; it reserves 256bytes ($ff00-$ffff)
Stack			equ $ff00

; 8255 PIO -chip registers
;  LCD-display
PortA           equ $0
PortB           equ $1
PortC           equ $2
PIOCtrl         equ $3
LCDd            equ PortA
LCDi            equ PortC

; Timer
Counter0        equ $20
Counter1        equ $21
Counter2        equ $22
CounterC        equ $23

; Delay after actions when using LCD. (2ms)
LCD_delay       equ $0002

; First line of LCD.
#define Line1 $00

; Second line of LCD.
#define Line2 $40

; End Of Line, used with strings.
#define EOL $17

; End Of LOG
#define EOLOG $18

#define NOEOL $19


;**************************************************************
; Code origin
.org $0000

;**************************************************************
; Start
	di
	jp RESET


;**************************************************************
;**************************************************************
;**************************************************************
; KERNEL ROUTINES
.org $100
;**************************************************************

; *** byte2lcd
; This routine outputs the hex value of reg a into
; LCD-display
byte2lcd:
	push hl
	push bc
; Upper 4bits of reg a
	ld hl, hextolcd
	push af
	ld b, 0
	srl a
	srl a
	srl a
	srl a
	ld c, a
	add hl, bc
	ld b, (hl)
	call char2lcd
	pop af
; Lower 4bits of reg a
	ld hl, hextolcd
	ld b, 0
	and $0f
	ld c, a
	add hl, bc
	ld b, (hl)
	call char2lcd
;
	pop bc
	pop hl
	ret
; end of byte2lcd

; *** set_lcd
; Sets value to LCDs instruction register
set_lcd:
	push af
	push de
	ld a, %00000001
	out (LCDi), a
	ld a, b
	out (LCDd), a
	ld a, %00000000
	out (LCDi), a
	ld de, LCD_delay
	call Delayms
	ld a, %00000001
	out (LCDi), a
	pop de
	pop af
	ret
; end of set_lcd


; *** char2lcd
; Outs character to LCD-display
char2lcd:
	push af
	push bc
	push de

	ld a, %00000101
	out (LCDi), a
	ld a, b
	out (LCDd), a

	ld a, %00000100
	out (LCDi), a
	ld de, LCD_delay
	call Delayms
	ld a, %00000001
	out (LCDi), a

	pop de
	pop bc
	pop af
	ret
; end of char2lcd


; *** reset_lcd
; Resets the LCD-diplay
; Clears the LCD, returns cursor to home, sets cursor move
; direction to incremental, sets display shifting off,
; sets display on, cursor on, cursor blinking off, sets
; cursor-move mode on, shift direction left, interface
; data lenght to 8bits, number of display lines to 2lines
; and character font to 5x7.
; none of the regs or flags are changed
reset_lcd:
	push af
	nop
	nop
	pop af
	ret
	
	push af
	push bc

;	ld b,%00000001
;	call set_lcd
;	ld b,%00000110
;	call set_lcd
;	ld b,%00001100
;	call set_lcd
;	ld b,%00010000
;	call set_lcd
;	ld b,%00111000
;	call set_lcd
;	ld b,%10000000
;	call set_lcd

	pop bc
	pop af
	ret
; end of reset_lcd

; *** clear_lcd
; Clears the LCD
clear_lcd:
 push bc
 ld b,%00000001
 call set_lcd
 pop bc
 ret
; end of clear_lcd

; *** str2lcd
; Outputs a string into LCD-display
; The string start address should be stored into hl and
; end of the string should be marked with EOL
; The string is just added to displays previous
; contents
; hl and flags are changed
str2lcd:
 push af
 push bc
 ld a,EOL
s2l_loop:
 ld b,(hl)
 cp b
 jr z,s2l_end
 call char2lcd
 inc hl
 jr s2l_loop
s2l_end:
 pop bc
 pop af
 ret
; end of str2lcd

; *** strn2lcd
; Outputs a string into LCD-display
; The string start address should be stored into hl and
; lenght of the string should be in reg c
; This routine also exits if it finds EOL- or EOLOG-char and
; returns that char in reg c, otherwise it returns NOEOL
; The string is just added to displays previous
; contents
; none is changed
strn2lcd:
	push af
	push bc
	inc c
sn2l_loop:
	ld a, NOEOL
	dec c
	jr z, sn2l_end
	ld a, (hl)
	cp EOL
	jr z, sn2l_end
	cp EOLOG
	jr z, sn2l_end
	ld b, a
	call char2lcd
	inc hl
	jr sn2l_loop
sn2l_end:
	pop bc
	ld c, a
	pop af
	ret
; end of strn2lcd

; *** strd2lcd
; Outputs a string into LCD-display with delay
; The string start address should be stored into hl,
; end of the string should be marked with EOL,
; delay between characters in de as milliseconds
; The string is just added to displays previous
; contents
; hl and flags are changed
strd2lcd:
 push af
 push bc
 ld a,EOL
sd2l_loop:
 ld b,(hl)
 cp b
 jr z,sd2l_end
 call char2lcd
 inc hl
 call Delayms
 jr sd2l_loop
sd2l_end:
 pop bc
 pop af
 ret
; end of strd2lcd
 
; *** setDDRAMa
; Sets LCDs DDRAM address
setDDRAMa:
 push bc
 or $80
 ld b,a
 call set_lcd
 pop bc
 ret
; end of setDDRAMa

#ifdef CPU_AT_2MHZ
; *** Delayms
; This loop waits amount of milliseconds which is stored in de
; CPU should run @2MHz
; There is always spend some extra clocks when this delay is initialized
; and when it ends.
Delayms:        ; Clocks spend in instructions and time
 push af        ; 11 / 
 push bc        ; 11 / 
 push de        ; 11 / 
 push ix        ; 15 / 
 xor a          ; 4 / 
 inc d          ; 4 / 
 ld bc,40|$100 ; 10 /
Delayms0:       ; = 66 /
; Here should be used enough clocks that one loop
; would spend 1ms! NOP is not an option :)
 dec ix         ; 10 /
 nop            ; 4 /
 nop            ; 4 /
 nop            ; 4 /
 nop            ; 4 /
 dec bc         ; 6 /
 cp b           ; 4 / 
 jr nz,Delayms0 ; 12 /
                ; = 48 / 24us
; There goes 984us and rest of the 1000us is spend here
 ld bc,40|$100 ; 10 / 
 dec de         ; 6 / 
 cp d           ; 4 / 
 jr nz,Delayms0 ; 12 / 
                ; = 32 / 16us
 pop ix         ; 14 / 
 pop de         ; 10 / 
 pop bc         ; 10 / 
 pop af         ; 10 / 
 ret            ; 10 / 
                ; = 54 / 
; end of Delayms
#endif

#ifdef CPU_AT_4MHZ
; *** Delayms
; This loop waits amount of milliseconds which is stored in de
; CPU should run @4MHz
; There is always spend some extra clocks when this delay is initialized
; and when it ends. These actions takes 30us+4.25us per call.
Delayms:        ; Clocks spend in instructions and time
 push af        ; 11 / 2.75us
 push bc        ; 11 / 2.75us
 push de        ; 11 / 2.75us
 push ix        ; 15 / 3.75us
 xor a          ; 4 / 1us
 inc d          ; 4 / 1us , becose 1ms should be 1ms and so on...
 ld bc,123|$100 ; 10 / 2.5us
Delayms0:       ; = 66 / 16.5us
; Here should be used enough clocks that one loop
; would spend 1ms! NOP is not an option :)
 dec ix         ; 10 / 2.5us
 dec bc         ; 6 /1.5us
 cp b           ; 4 / 1us
 jr nz,Delayms0 ; 12 / 3us
                ; = 32 / 8us
; There goes 992us and rest 8us of 1000us is spend here
 ld bc,123|$100 ; 10 / 2.5us
 dec de         ; 6 / 1.5us
 cp d           ; 4 / 1us
 jr nz,Delayms0 ; 12 / 3us
                ; = 32 / 8us
 pop ix         ; 14 / 3.5us
 pop de         ; 10 / 2.5us
 pop bc         ; 10 / 2.5us
 pop af         ; 10 / 2.5us
 ret            ; 10 / 2.5us
                ; = 54 / 13.5us
; end of Delayms
#endif
#ifdef CPU_AT_8MHZ
; *** Delayms
; This loop waits amount of milliseconds which is stored in de
; CPU should run @4MHz
; There is always spend some extra clocks when this delay is initialized
; and when it ends.
Delayms:        ; Clocks spend in instructions and time
 push af        ; 11 / 1.375us
 push bc        ; 11 / 1.375us
 push de        ; 11 / 1.375us
 push ix        ; 15 / 1.875us
 xor a          ; 4 / 0.5us
 inc d          ; 4 / 0.5us , becose 1ms should be 1ms and so on...
 ld bc,199|$100 ; 10 / 1.25us
Delayms0:       ; = 66 / 8.25us
; Here should be used enough clocks that one loop
; would spend 1ms! NOP is not an option :)
 nop            ; 4 / 0.5us
 nop            ; 4 / 0.5us
 dec ix         ; 10 / 1.25us
 dec bc         ; 6 / 0.75us
 cp b           ; 4 / 0.5us
 jr nz,Delayms0 ; 12 / 1.5us
                ; = 40 / 5us
; There goes 995us and rest 5us of 1000us is spend here
 nop            ; 4 / 0.5us
 nop            ; 4 / 0.5us
 ld bc,199|$100 ; 10 / 1.25us
 dec de         ; 6 / 0.75us
 cp d           ; 4 / 0.5us
 jr nz,Delayms0 ; 12 / 1.5us
                ; = 40 / 5us
 pop ix         ; 14 / 1.75us
 pop de         ; 10 / 1.25us
 pop bc         ; 10 / 1.25us
 pop af         ; 10 / 1.25us
 ret            ; 10 / 1.25us
                ; = 54 / 6.625us
; end of Delayms
#endif

;**************************************************************
;**************************************************************
;**************************************************************
; RESET
;**************************************************************
RESET:
	ld a, $90
	out (CounterC), a
	ld b, $10
	
; Init 8255 PIO
; Port A and port C lower 4bits to LCD-diplay.
; Port B and port C upper 4bits as outputs for now.
; Mode for 8255 is 0 for now.
	ld a, %10000000
	out (PIOCtrl), a
	ld a, $aa
	out (LCDd), a
	ld a, %00000001
	out (LCDi), a

; Init 8253 Counter Timer
; Timer 0 divides incoming 4MHz frequency by 1000.
; Timer 1 creates NMI interrupt every 1sec.
; Timer 2 acts as sound generator.
	ld a, %00110110
	out (CounterC), a
	ld a, $e8
	out (Counter0), a
	ld a, $03
	out (Counter0), a
; Counter 1
;	ld a, %01110111
; out (CounterC), a
; ld a, $04
; out (Counter1), a
; ld a, $00
; out (Counter1), a
; Counter 2
	ld a, %10110000
	out (CounterC), a
	ld a, $00
	out (Counter2), a
	ld a, $00
	out (Counter2), a
	
; Set up the stack pointer
	ld sp, Stack

; Init LCD.
	call reset_lcd
;	call xxxx
	
; Beeb for everything OK.
	ld a, %10110110
	out (CounterC), a
	ld a, b
	out (Counter2), a
	ld a, $00
	out (Counter2), a
	
	ld de, 500
	call Delayms

	ld a, %10110000
	out (CounterC), a
	ld a, $00
	out (Counter2), a
	ld a, $00
	out (Counter2), a

	halt

; Start the OS.
	ld hl, s_OSstring
	call str2lcd
	ld hl, s_version
	call str2lcd
		
halt:
;	halt

xxx:
	push af
	pop af
	ret
	
xxxx:
	push af
	pop af
	ret
	
;**************************************************************
; Misc data, example character strings
s_OSstring      .db "Z80 WestOS, by Duge",EOL
s_version       .db "version b0.01",EOL
s_halted        .db "CPU halted.",EOL
s_clearline     .db "                    ",EOL
s_uptime1       .db "System uptime:",EOL
s_uptime2       .db "00000d00h00m00s",EOL
hextolcd        .db '0','1','2','3','4','5','6','7','8','9'
                .db 'A','B','C','D','E','F'
;**************************************************************

.end

