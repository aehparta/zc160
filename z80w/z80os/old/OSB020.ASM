;**************************************************************
;
;                       The Z80 WestOS
;
;                 Operating System for Z80 board
;                       West 17 Designs
;                        - by Duge -
;
;**************************************************************
; Misc information:
; The LCD-display mentioned in the code should be 2x20
; characters LCD-display module using hd44780-based
; controller.
;
;**************************************************************

#define equ .equ

; Stack Pointer's start value
StackPointerOrigin: equ $feff
; LEDs, 7segments and keyboard io-addresses
SSeg1:          equ $01
SSeg2:          equ $02
SSeg3:          equ $03
SSeg4:          equ $04
KeyS:           equ $05
KeyR:           equ $06
LEDs:           equ $07
; 8255 PIO -chip registers
;  LCD-display
PortA:          equ $20
PortB:          equ $21
PortC:          equ $22
PIOCtrl:        equ $23
LCDd:           equ PortB
LCDi:           equ PortC

;**************************************************************
; Code origin
.org $0000

;**************************************************************
; RST $00
 jp RESET ; 3bytes
 nop      
 nop
 nop
 nop      ; 5 times 1byte makes 5bytes
 nop      ; 3b+5b=8b :)
; RST $08
; This RST routine writes 'HALT' into 7segments and halt's the cpu
.org $0008
 jp HALT
 halt
 halt
 halt
 halt
 halt
; RST $10
.org $0010
 halt
 nop
 nop
 nop
 nop
 nop
 nop
 nop
; RST $18
.org $0018
 halt
 nop
 nop
 nop
 nop
 nop
 nop
 nop
; RST $20
.org $0020
 halt
 nop
 nop
 nop
 nop
 nop
 nop
 nop
; RST $28
.org $0028
 halt
 nop
 nop
 nop
 nop
 nop
 nop
 nop
; RST $30
.org $0030
 halt
 nop
 nop
 nop
 nop
 nop
 nop
 nop
; RST $38 or /INT-signal in interrupt mode 1
; reti for now, becose INT not in use
.org $0038
 reti
 nop
 nop
 nop
 nop
 nop
 nop
;**************************************************************
; Empty space for the NMI-interrupt point
; Here are three default delay routines
; and little string ;)
; $40
.org $0040
DelayBC:
 dec c          ; 1byte
 jr nz,DelayBC  ; 2bytes
 dec b          ; 1byte
 jr nz,DelayBC  ; 2bytes
 ret            ; 1byte
DelayDE:
 dec e          ; 1byte
 jr nz,DelayDE  ; 2bytes
 dec d          ; 1byte
 jr nz,DelayDE  ; 2bytes
 ret            ; 1byte
DelayHL:
 dec l          ; 1byte
 jr nz,DelayHL  ; 2bytes
 dec h          ; 1byte
 jr nz,DelayHL  ; 2bytes
 ret            ; 1byte
;

.db "Z80WestOS by Duge"

;**************************************************************
; This is the point where the processor goes when NMI-interrupt
; is signalled
; 0066H or $66
.org $0066
; retn for now, becose NMI not in use yet
 retn
 halt
 halt

;**************************************************************
; Here starts the 'REAL' code
; First are misc data like strings then some routines and then
; the main code
;**************************************************************
; Misc data, example character strings
OSstring        .db "Z80 WestOS, by Duge.",$17
version         .db "version B0.20",$17
halted          .db "CPU halted.",$17
hexto7segment   .db %10000001,%10110111,%11000010,%10010010
                .db %10110100,%10011000,%10001000,%10110011
                .db %10000000,%10010000,%10100000,%10001100
                .db %11001001,%10000110,%11001000,%11101000
;**************************************************************
; Routines
;
; Three delay routines have already been written in earlier
; addresses

; *** HALT
; Writes 'HALT' into 7segments and then halt's the cpu
HALT:
 ld a,%10100100
 out (SSeg1),a
 ld a,%10100000
 out (SSeg2),a
 ld a,%11001101
 out (SSeg3),a
 ld a,%11101001
 out (SSeg4),a
 halt
; end of HALT

; *** n_as_7seg
; This routine converts the hex value of lower 4bits of reg a
; as 7segment value and returns the result in reg a
; The 7bit of reg a is leaved unchanged for use of dot
n_as_7seg:
 push hl
 push bc

 ld hl,hexto7segment
 ld b,a
 and $0f
 ld c,a
 ld a,b
 ld b,0
 add hl,bc
 and $80
 and (hl)

 pop bc
 pop hl
 ret
; end of n_as_7seg

; *** n_to_7seg
; This routine outputs the hex value of lower 4bits of reg a
; into 7segment display which io-address is specified in
; reg c
; Carry flag defines if the dot is on or off
; reg a and flags are changed
n_to_7seg:
 push hl
 push bc

 ld b,$ff
 jr nc,nto7_nocarry
 res 7,b
nto7_nocarry:
 ld hl,hexto7segment
 push bc
 ld b,0
 and $0f
 ld c,a
 add hl,bc
 pop bc
 ld a,b
 and (hl)
 out (c),a

 pop bc
 pop hl
 ret
; end of n_to_7seg

; *** b_to_7seg
; This routine outputs the hex value of of reg a into
; two 7segment display
; First display io-address is specified in reg c
; The most valuable nibble of reg a will be outed
; into the address of c, then c's value is increased
; and the lower nibble is outed into that address
; Carry flag defines if the dot is on or off
; reg a, c and flags are changed
b_to_7seg:
 push hl
 push bc

 ld b,$ff
 jr nc,bto7_nocarry
 res 7,b
bto7_nocarry:
; Upper 4bits of reg a
 ld hl,hexto7segment
 push af
 push bc
 ld b,0
 sra a
 sra a
 sra a
 sra a
 and $0f
 ld c,a
 add hl,bc
 pop bc
 ld a,(hl)
 out (c),a
 inc c
 pop af
; Lower 4bits of reg a
 push bc
 ld hl,hexto7segment
 ld b,0
 and $0f
 ld c,a
 add hl,bc
 pop bc
 ld a,b
 and (hl)
 out (c),a

 pop bc
 pop hl
 ret
; end of b_to_7seg

; *** set_lcd
; Sets value to LCDs instruction register
set_lcd:
 ld a,%00000001
 out (LCDi),a
 ld a,b
 out (LCDd),a
 ld a,%00000000
 out (LCDi),a
 push bc
 ld bc,$01af
 call DelayBC
 pop bc
 ld a,%00000001
 out (LCDi),a
 ret
; end of set_lcd

; *** char2lcd
; Outs character to LCD-display
char2lcd:
 ld a,%00000101
 out (LCDi),a
 ld a,b
 out (LCDd),a
 ld a,%00000100
 out (LCDi),a
 push bc
 ld bc,$01af
 call DelayBC
 pop bc
 ld a,%00000001
 out (LCDi),a
 ret
; end of char2lcd

; *** reset_lcd
; Resets the LCD-diplay
; Clears the LCD, returns cursor to home, sets cursor move
; direction to incremental, sets display shifting off,
; sets dosplay on, cursor on, cursor blinking off, sets
; cursor-move mode on, shift direction left, interface
; data lenght to 8bits, number of display lines to 2lines
; and character font to 5x7.
; none of the regs or flags are changed
reset_lcd:
 push af
 push bc

 ld b,%00000001
 call set_lcd
 ld b,%00000110
 call set_lcd
 ld b,%00001110
 call set_lcd
 ld b,%00010000
 call set_lcd
 ld b,%00111000
 call set_lcd
 ld b,%10000000
 call set_lcd

 pop bc
 pop af
 ret
; end of reset_lcd

; *** str2lcd
; Outputs a string into LCD-display
; The string start address should be stored into hl and
; end of the string should be marked with byte $17
; The string is just added to displays previous
; contents
; hl and flags are changed
str2lcd:
 push af
 push bc
s2l_loop:
 ld a,(hl)
 cp $17
 jr z,s2l_end
 ld b,a
 call char2lcd
 inc hl
 jr s2l_loop
s2l_end:
 pop bc
 pop af
 ret
; end of str2lcd

; *** setDDRAMa
; Sets LCDs DDRAM address
setDDRAMa:
 or $80
 ld b,a
 call set_lcd
 ret
; end of setDDRAMa

;**************************************************************
; OS's main code start location
RESET:
; After Reset we come here
; Disable interrupts and couple of nops just for safe ;)
 di
 nop
 nop
 nop
 
; Testing the 8kB RAM at address $e000-$ffff
; Address $c000-$dfff can also contain a 8kb RAM..
; Should not be using stack in any way, becose don't
; know if the memory is OK, or even exists really
; The error test won't affect on running the os
; really in any way. It just will inform the user
; that there is bad memory in the system.
 ld b,$ff
 ld hl,$2000
 ld de,$e000
; Address pointer de and counter hl have now been set up
; Start testing:
fill_loop0:
 ld a,(de)              ; store the original value into reg c
 ld c,a                 ;
 ld a,%10101010         ; first test pattern
 ld (de),a
 ld a,(de)
 cp %10101010
 ld a,c                 ; save the original value back
 ld (de),a              ;
 jr z,fill0             ; If OK then continue
 ld a,d                 ; Otherwise check where the error was found
 and %00011100
 sra a
 sra a
; Here is checked which 1kB page of the 8kB has faulty memory
; The result is stored in register b
 cp 0
 jr z,z00
 cp 1
 jr z,z01
 cp 2
 jr z,z02
 cp 3
 jr z,z03
 cp 4
 jr z,z04
 cp 5
 jr z,z05
 cp 6
 jr z,z06
 cp 7
 jr z,z07
z00:
 res 0,b
 jr fill0
z01:
 res 1,b
 jr fill0
z02:
 res 2,b
 jr fill0
z03:
 res 3,b
 jr fill0
z04:
 res 4,b
 jr fill0
z05:
 res 5,b
 jr fill0
z06:
 res 6,b
 jr fill0
z07:
 res 7,b
 jr fill0

fill0:
 ld a,(de)              ; store the original value into reg c
 ld c,a                 ;
 ld a,%01010101         ; Second test pattern
 ld (de),a
 ld a,(de)
 cp %01010101
 ld a,c                 ; save the original value back
 ld (de),a              ;
 jr z,fill1             ; If OK then continue
 ld a,d                 ; Otherwise check where the error was found
 and %00011100
 sra a
 sra a
; Again checking the 1kB page
 cp 0
 jr z,z10
 cp 1
 jr z,z11
 cp 2
 jr z,z12
 cp 3
 jr z,z13
 cp 4
 jr z,z14
 cp 5
 jr z,z15
 cp 6
 jr z,z16
 cp 7
 jr z,z17
z10:
 res 0,b
 jr fill1
z11:
 res 1,b
 jr fill1
z12:
 res 2,b
 jr fill1
z13:
 res 3,b
 jr fill1
z14:
 res 4,b
 jr fill1
z15:
 res 5,b
 jr fill1
z16:
 res 6,b
 jr fill1
z17:
 res 7,b
 jr fill1
 
fill1:
 inc de
 dec l
 jp nz,fill_loop0
; Show the current position of test with the 8 LEDs
; This just for fun ;)
 ld c,b
 ld a,d
 and %00011100
 sra a
 sra a
; Find out the 1kB page
 cp 0
 jr z,z20
 cp 1
 jr z,z21
 cp 2
 jr z,z22
 cp 3
 jr z,z23
 cp 4
 jr z,z24
 cp 5
 jr z,z25
 cp 6
 jr z,z26
 cp 7
 jr z,z27
z20:
 res 0,c
 jr test_position_end
z21:
 res 1,c
 jr test_position_end
z22:
 res 2,c
 jr test_position_end
z23:
 res 3,c
 jr test_position_end
z24:
 res 4,c
 jr test_position_end
z25:
 res 5,c
 jr test_position_end
z26:
 res 6,c
 jr test_position_end
z27:
 res 7,c
 jr test_position_end

test_position_end:
 ld a,c
 out (LEDs),a
 dec h
 jp nz,fill_loop0

; End of memory test
; Show the result of the test with the 8 LEDs
 ld a,b
 out (LEDs),a
; If there was found an error from memory in the test
; then show 'EEEE'-string in the default 7segments
 cp $ff
 jr z,no_error_in_memory
 ld a,%11001000
 out (SSeg1),a
 out (SSeg2),a
 out (SSeg3),a
 out (SSeg4),a
 ld hl,$ffff
error_delay_loop:
 nop
 dec l
 jr nz,error_delay_loop
 dec h
 jr nz,error_delay_loop
no_error_in_memory:

; Now we set up the stack pointer
 ld sp,StackPointerOrigin 
; Start by  initializing and blinking the default 7segments
 ld a,$ff
 out (SSeg1),a
 out (SSeg2),a
 out (SSeg3),a
 out (SSeg4),a
; Also reset the keyboard, just for safe
 out (KeyS),a
; Let's do some blinking
 ld hl,$4000
 call DelayHL   ; Wait a bit when the 7segments are off
 ld a,0
 out (SSeg1),a
 out (SSeg2),a
 out (SSeg3),a
 out (SSeg4),a
 ld hl,$7000
 call DelayHL   ; Wait a bit when the 7segments are on
 ld a,$ff       ; Then reset the 7segments off
 out (SSeg1),a
 out (SSeg2),a
 out (SSeg3),a
 out (SSeg4),a
; Now the memory error message in the LEDs should have been seeable
; enough long time so reset the LEDs also
 ld a,%11101111 ; This pattern lights up the fifth LED for mark of
 out (LEDs),a   ; 'power up'
; Set default interrupt mode
 im 1
; Init 8255 PIO
; Port B and port C lower 4bits to LCD-diplay
; Port A and port C upper 4bits as inputs for now
; Mode for 8255 is 0 for now
 ld a,%10011000
 out (PIOCtrl),a
 ld a,$0
 out (LCDd),a
 ld a,%00000001
 out (LCDi),a
; Init the LCD-display
 call reset_lcd
; Put a string to the display
 ld hl,OSstring
 call str2lcd
 ld a,$40
 call setDDRAMa
 ld hl,version
 call str2lcd
 jp HALT
; This halt is just for safe too
 halt
 
.end
