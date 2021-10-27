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

; Operating system reserves memory are between $fc00-$ffff
; Stack Pointer's start value
StackPointerOrigin: equ $feff
; Variables
SRM             equ $fa00       ; Here are OS's variables
UMO             equ $e000       ; Here starts the 'User's Memory'
; Temporary values
T0              equ SRM+0       ; These values are bytes
T1              equ SRM+1
T2              equ SRM+2
T3              equ SRM+3
T4              equ SRM+4
T5              equ SRM+5
; Hex editor
w_he_address    equ SRM+6       ;word
b_he_addset     equ SRM+8       ;byte
b_he_undovalue  equ SRM+9       ;byte
w_he_undoaddr   equ SRM+10      ;word
b_he_undoset    equ SRM+12      ;byte
b_he_nibble     equ SRM+13      ;byte
b_he_output     equ SRM+14      ;byte
b_he_input      equ SRM+15      ;byte
w_he_jumpaddr   equ SRM+16      ;word
b_he_calljump   equ SRM+18      ;byte
w_he_calladdr   equ SRM+19      ;word
; key-routines
key_pressed     equ SRM+30      ;byte
key_timer       equ SRM+31      ;byte
key_delay       equ SRM+32      ;byte
key_press       equ SRM+33      ;byte
key_repeatdelay equ SRM+34      ;word
key_repeatrate  equ SRM+36      ;word
key_rd          equ SRM+38      ;word
key_rr          equ SRM+40      ;word
key_rset        equ SRM+42      ;byte
; Default repeat delay and rate for keyboard
RepeatDelay     equ SRM+50      ;word
RepeatRate      equ SRM+52      ;word
RepeatSet       equ SRM+54      ;byte
; Ethernet
ethbase         equ SRM+60      ;byte
ethdetect       equ SRM+61      ;byte
ethtmp          equ SRM+62      ;byte
ethsaprom       equ SRM+63      ;32 bytes
ethhwaddr       equ SRM+95      ;6 bytes
ethpiomode      equ SRM+101     ;byte
ethaddr         equ SRM+102     ;byte
ethirqreg       equ SRM+103     ;byte
ethwrdlen       equ SRM+104     ;byte
ethT0           equ SRM+105     ;byte
ethT1           equ SRM+106     ;byte
ethT2           equ SRM+107     ;byte
ethT3           equ SRM+108     ;byte
etxStartPage    equ SRM+109     ;byte
erxStartPage    equ SRM+110     ;byte
ethStopPage     equ SRM+111     ;byte
ejReset         equ SRM+112     ;word
ejEnable        equ SRM+114     ;word
ejReceive       equ SRM+116     ;word
ejSend          equ SRM+118     ;word

;**************************************************************
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

; Keyboard
; These values are returned by key-routines
key0    equ $00
key1    equ $01
key2    equ $02
key3    equ $03

key4    equ $04
key5    equ $05
key6    equ $06
key7    equ $07

key8    equ $08
key9    equ $09
keya    equ $0a
keyb    equ $0b

keyc    equ $0c
keyd    equ $0d
keye    equ $0e
keyf    equ $0f

CK0     equ $10
CK1     equ $11
CK2     equ $12
CK3     equ $13

CK4     equ $14
CK5     equ $15
Shift   equ $16
Enter   equ $17

none    equ $ff

; other equs
Line1           equ $00
Line2           equ $40
_RepeatDelay    equ $0aff       ;default value
_RepeatRate     equ $02ff       ;default value
FastKeyDelay    equ $20
NormalKeyDelay  equ $50

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
; INT is used by ethernet controller
.org $0038
 di
 call eth_packetreceived
 ei
 reti
;**************************************************************
; Empty space for the NMI-interrupt point
; Here are three default delay routines
; and little string ;)
; $40
.org $0040
DelayBC:
 inc b          ; 1byte
 inc c          ; 1byte
DelayBC0:
 dec c          ; 1byte
 jr nz,DelayBC0 ; 2bytes
 dec b          ; 1byte
 jr nz,DelayBC0 ; 2bytes
 ret            ; 1byte
DelayDE:
 inc d          ; 1byte
 inc e          ; 1byte
DelayDE0:
 dec e          ; 1byte
 jr nz,DelayDE0 ; 2bytes
 dec d          ; 1byte
 jr nz,DelayDE0 ; 2bytes
 ret            ; 1byte
DelayHL:
 inc h          ; 1byte
 inc l          ; 1byte
DelayHL0:
 dec l          ; 1byte
 jr nz,DelayHL0 ; 2bytes
 dec h          ; 1byte
 jr nz,DelayHL0 ; 2bytes
 ret            ; 1byte
;

.db "by Duge"

;**************************************************************
; This is the point where the processor goes when NMI-interrupt
; is signalled
; 0066H or $66
.org $0066
 di
 call eth_packetreceived
 ei
 retn
 halt

;**************************************************************
; Here starts the 'REAL' code
; First routines, then the main code
; and then misc data like strings and such
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
; This routine outputs the hex value of reg a into
; two 7segment display
; First display io-address is specified in reg c
; The most valuable nibble of reg a will be outed
; into the address of c, then c's value is increased
; and the lower nibble is outed into that address
; Carry flag defines if the dot is on or off
; reg a and flags are changed
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

; *** byte2lcd
; This routine outputs the hex value of reg a into
; LCD-display
byte2lcd:
 push hl
 push bc
; Upper 4bits of reg a
 ld hl,hextolcd
 push af
 ld b,0
 sra a
 sra a
 sra a
 sra a
 and $0f
 ld c,a
 add hl,bc
 ld b,(hl)
 call char2lcd
 pop af
; Lower 4bits of reg a
 ld hl,hextolcd
 ld b,0
 and $0f
 ld c,a
 add hl,bc
 ld b,(hl)
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
 ld a,%00000001
 out (LCDi),a
 ld a,b
 out (LCDd),a
 ld a,%00000000
 out (LCDi),a
 push bc
 ld bc,$00af
 call DelayBC
 pop bc
 ld a,%00000001
 out (LCDi),a
 pop af
 ret
; end of set_lcd

; *** char2lcd
; Outs character to LCD-display
char2lcd:
 push af
 ld a,%00000101
 out (LCDi),a
 ld a,b
 out (LCDd),a
 ld a,%00000100
 out (LCDi),a
 push bc
 ld bc,$00af
 call DelayBC
 pop bc
 ld a,%00000001
 out (LCDi),a
 pop af
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
 ld b,%00001100
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

; *** strd2lcd
; Outputs a string into LCD-display with delay
; The string start address should be stored into hl and
; end of the string should be marked with byte $17
; The string is just added to displays previous
; contents
; de, hl and flags are changed
strd2lcd:
 push af
 push bc
sd2l_loop:
 ld a,(hl)
 cp $17
 jr z,sd2l_end
 ld b,a
 call char2lcd
 inc hl
 push de
 call DelayDE
 pop de
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

; *** key_scan
; Tests all keys on keyboard and if finds a pressed key
; then aborts the loop and returns that key's value
; in reg a
key_scan:
 ld a,%11111110
 out (KeyS),a
 in a,(KeyR)
 bit 0,a
 jp z,key_Enter
 bit 1,a
 jp z,key_CK5
 bit 2,a
 jp z,key_CK3
 bit 3,a
 jp z,key_CK1
 ld a,%11111101
 out (KeyS),a
 in a,(KeyR)
; bit 0,a
; jp z,key_Shift
 bit 1,a
 jp z,key_CK4
 bit 2,a
 jp z,key_CK2
 bit 3,a
 jp z,key_CK0
 ld a,%11111011
 out (KeyS),a
 in a,(KeyR)
 bit 0,a
 jp z,key_f
 bit 1,a
 jp z,key_b
 bit 2,a
 jp z,key_7
 bit 3,a
 jp z,key_3
 ld a,%11110111
 out (KeyS),a
 in a,(KeyR)
 bit 0,a
 jp z,key_e
 bit 1,a
 jp z,key_a
 bit 2,a
 jp z,key_6
 bit 3,a  
 jp z,key_2
 ld a,%11101111
 out (KeyS),a
 in a,(KeyR)
 bit 0,a
 jp z,key_d
 bit 1,a
 jp z,key_9
 bit 2,a
 jp z,key_5
 bit 3,a
 jp z,key_1
 ld a,%11011111
 out (KeyS),a
 in a,(KeyR)
 bit 0,a
 jp z,key_c
 bit 1,a
 jp z,key_8
 bit 2,a
 jp z,key_4
 bit 3,a  
 jp z,key_0
; no key was pressed, load $ff into reg a
; for mark of that
 ld a,$ff
 ret
; end of key_scan

; *** key_testshift
; Test Shift's current status
; Result is returned in Z-flag
key_testshift:
 push bc
 ld b,a
 ld a,%11111101
 out (KeyS),a
 in a,(KeyR)
 bit 0,a
 ld a,b
 pop bc
 ret
; end of key_testshift

; *** key_getkey
key_getkey:
 push hl
 ld a,(key_delay)
 ld (key_timer),a
 ld a,(key_rset)
 cp $ff
 jr nz,gk_loop
 ld a,$00
 ld (key_rset),a
 ld hl,(key_repeatdelay)
 ld (key_rd),hl
 ld hl,(key_repeatrate)
 ld (key_rr),hl
gk_loop:
 call key_scan
 cp none
 jr nz,gk_key        ; Some key was pressed
 ld a,(key_pressed)
 cp none
 jr z,gk_loop
 ld hl,(key_repeatdelay)
 ld (key_rd),hl
 ld hl,(key_repeatrate)
 ld (key_rr),hl
 ld a,(key_timer)
 dec a
 ld (key_timer),a
 jr nz,gk_loop
 ld a,none
 ld (key_pressed),a
 ld a,(key_delay)
 ld (key_timer),a
 jr gk_loop
;
gk_key:
 ld (key_press),a    ;
 ld a,(key_pressed)  ; Test if this key was pressed earlier
 ld hl,key_press     ;
 cp (hl)             ;
 jr nz,gk_nkey
 ld hl,(key_repeatdelay)
 ld a,0
 cp h
 jr nz,gk_delay
 cp l
 jr nz,gk_delay
 jp gk_loop
gk_delay:
 ld hl,(key_rd)
 cp h
 jr nz,gk_dntr
 cp l
 jr nz,gk_dntr
 ld hl,(key_rr)
 cp h
 jr nz,gk_rntr
 cp l
 jr nz,gk_rntr
 jr gk_nkey
gk_dntr:
 dec hl
 ld (key_rd),hl
 jp gk_loop
gk_rntr:
 dec hl
 ld (key_rr),hl
 jp gk_loop
;
gk_nkey:
 ld a,(key_press)
 ld (key_pressed),a
 pop hl
 ret
; end of key_getkey

; *** key_getbyte
; Uses the LCD to get word-value from the user
; Default value should be stored into b, value
; given is also returned in b
; In a is the key which was pressed to get here
key_getbyte:
 push af
 push hl
 call clear_lcd
 ld a,Line1
 call setDDRAMa
 ld hl,s_inputbyte
 call str2lcd
 pop hl
 pop af
; If there is need for own start string, then
; jump here after setting that
key_getbvalue:
 push de
 push hl
 ld d,b
 ld e,b
 ld (key_pressed),a
 ld a,Line2
 call setDDRAMa
 ld b,'>'
 call char2lcd
 ld a,d
 call byte2lcd
 ld a,Line2+1
 call setDDRAMa
 ld b,1
 ld a,FastKeyDelay
 ld (key_delay),a
;
gb_loop:
 call key_getkey
;
 cp $10
 jp c,gb_number
 cp Enter
 jr nz,gb_nEnter
 ld b,d
 ld a,Enter
 jp gb_end
gb_nEnter:
 cp CK5
 jp nz,gb_nundo
 ld d,e
 ld a,CK5
 jp gb_end
gb_nundo:
 cp CK0
 jp z,gb_left
 cp CK1
 jp z,gb_right
 jp gb_loop
;
gb_left:
 ld a,1
 cp b
 jp z,gb_loop
 inc b
 ld a,1
 sub b
 add a,Line2+1
 call setDDRAMa
 jp gb_loop
;
gb_right:
 ld a,0
 cp b
 jp z,gb_loop
 dec b
 ld a,1
 sub b
 add a,Line2+1
 call setDDRAMa
 jp gb_loop
;
gb_number:
 ld l,a
 ld a,b
;
 cp 1
 jr nz,gb_n1
 ld a,l
 sla a
 sla a
 sla a
 sla a
 and $f0
 ld l,a
 ld a,d
 and $0f
 or l
 ld d,a
 ld a,l
 sra a
 sra a
 sra a
 sra a
 and $0f
 dec b
 call gb_setadda
 jp gb_loop
;
gb_n1:
 cp 0
 jr nz,gb_n0
 ld a,l
 and $0f
 ld l,a
 ld a,d
 and $f0
 or l
 ld d,a
 ld a,l
 call gb_setadda
 ld a,Line2+2
 call setDDRAMa
 jp gb_loop
;
gb_setadda:
 push bc
 ld b,0
 push hl
 ld hl,hextolcd
 ld c,a
 add hl,bc
 ld b,(hl)
 call char2lcd
 pop hl
 pop bc
 ret
;
gb_n0:
 jp gb_end
;
gb_end:
 pop hl
 pop de
 ret
; end of key_getbyte

; *** key_getaddress
; Uses the LCD to get word-value from the user
; Default value should be stored into hl, value
; given is also returned in hl
; In a is the key which was pressed to get here
key_getaddress:
 push af
 push hl
 call clear_lcd
 ld a,Line1
 call setDDRAMa
 ld hl,s_inputaddress
 call str2lcd
 pop hl
 pop af
 call key_getwvalue
 ret
; end of key_getaddress

; *** key_getword
; Uses the LCD to get word-value from the user
; Default value should be stored into hl, value
; given is also returned in hl
; In a is the key which was pressed to get here
key_getword:
 push af
 push hl
 call clear_lcd
 ld a,Line1
 call setDDRAMa
 ld hl,s_inputword
 call str2lcd
 pop hl
 pop af
; If there is need for own start string, then
; jump here after setting that
key_getwvalue:
 push bc
 push de
 ld d,h
 ld e,l
 ld (key_pressed),a
 ld a,Line2
 call setDDRAMa
 ld b,'>'
 call char2lcd
 ld a,h
 call byte2lcd
 ld a,l
 call byte2lcd
 ld a,Line2+1
 call setDDRAMa
 ld b,3
 ld a,FastKeyDelay
 ld (key_delay),a
;
gw_loop:
 call key_getkey
;
 cp $10
 jp c,gw_number
 cp Enter
 jr nz,gw_nEnter
 ld a,Enter
 jp gw_end
gw_nEnter:
 cp CK5
 jp nz,gw_nundo
 ld h,d
 ld l,e
 ld a,CK5
 jp gw_end
gw_nundo:
 cp CK0
 jp z,gw_left
 cp CK1
 jp z,gw_right
 jp gw_loop
;
gw_left:
 ld a,3
 cp b
 jp z,gw_loop
 inc b
 ld a,3
 sub b
 add a,Line2+1
 call setDDRAMa
 jp gw_loop
;
gw_right:
 ld a,0
 cp b
 jp z,gw_loop
 dec b
 ld a,3
 sub b
 add a,Line2+1
 call setDDRAMa
 jp gw_loop
;
gw_number:
 ld c,a
 ld a,b
;
 cp 3
 jr nz,gw_n3
 ld a,c
 sla a
 sla a
 sla a
 sla a
 and $f0
 ld c,a
 ld a,h
 and $0f
 or c
 ld h,a
 ld a,c
 sra a
 sra a
 sra a
 sra a
 and $0f
 dec b
 call gw_setadda
 jp gw_loop
;
gw_n3:
 cp 2
 jr nz,gw_n2
 ld a,c
 and $0f
 ld c,a
 ld a,h
 and $f0
 or c
 ld h,a
 ld a,c
 dec b
 call gw_setadda
 jp gw_loop
;
gw_n2:
 cp 1
 jr nz,gw_n1
 ld a,c
 sla a
 sla a
 sla a
 sla a
 and $f0
 ld c,a
 ld a,l
 and $0f
 or c
 ld l,a
 ld a,c
 sra a
 sra a
 sra a
 sra a
 and $0f
 dec b
 call gw_setadda
 jp gw_loop
;
gw_n1:
 cp 0
 jr nz,gw_n0
 ld a,c
 and $0f
 ld c,a
 ld a,l
 and $f0
 or c
 ld l,a
 ld a,c
 call gw_setadda
 ld a,Line2+4
 call setDDRAMa
 jp gw_loop
;
gw_setadda:
 push bc
 ld b,0
 push hl
 ld hl,hextolcd
 ld c,a
 add hl,bc
 ld b,(hl)
 call char2lcd
 pop hl
 pop bc
 ret
;
gw_n0:
 jp gw_end
;
gw_end:
 pop de
 pop bc
 ret
; end of key_getword

; Jump-table for key-routines to get the key value into reg a
key_0:
 ld a,key0
 ret
key_1:
 ld a,key1
 ret
key_2:
 ld a,key2
 ret
key_3:
 ld a,key3
 ret
key_4:
 ld a,key4
 ret
key_5:
 ld a,key5
 ret
key_6:
 ld a,key6
 ret
key_7:
 ld a,key7
 ret
key_8:
 ld a,key8
 ret
key_9:
 ld a,key9
 ret
key_a:
 ld a,keya
 ret
key_b:
 ld a,keyb
 ret
key_c:
 ld a,keyc
 ret
key_d:
 ld a,keyd
 ret
key_e:
 ld a,keye
 ret
key_f:
 ld a,keyf
 ret
key_CK0:
 ld a,CK0
 ret
key_CK1:
 ld a,CK1
 ret
key_CK2:
 ld a,CK2
 ret
key_CK3:
 ld a,CK3
 ret
key_CK4:
 ld a,CK4
 ret
key_CK5:
 ld a,CK5
 ret
key_Shift:
 ld a,Shift
 ret
key_Enter:
 ld a,Enter
 ret
; end of key-jump-table

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
 ld a,b
 sra a
 sra a
 sra a
 sra a
 and $0f
 ld c,a
 ld a,b
 sla a
 sla a
 sla a
 sla a
 and $f0
 or c
 ld c,a
 ld a,d
 and %00011100
 sra a
 sra a
; Find out the 1kB page
 cp 0
 jr z,z24
 cp 1
 jr z,z25
 cp 2
 jr z,z26
 cp 3
 jr z,z27
 cp 4
 jr z,z20
 cp 5
 jr z,z21
 cp 6
 jr z,z22
 cp 7
 jr z,z23
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
; Set keyboard's default repeat delay and rate,
; if not already set
 ld a,(RepeatSet)
 cp $17
 jr z,j_RepeatSet
 ld hl,_RepeatDelay
 ld (RepeatDelay),hl
 ld hl,_RepeatRate
 ld (RepeatRate),hl
 ld a,$17
 ld (RepeatSet),a
j_RepeatSet:
; Some settings for hexedit
 ld a,$ff
 ld (b_he_undoset),a
; Misc settings
 xor a
 ld (T0),a
 ld (T1),a
 ld (T2),a
 ld (T3),a
 ld (T4),a
 ld (T5),a
; Set default interrupt mode
 im 1   ; INT is probably used by ethernet controller
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
; Detect and init ethernet adapter
 call InitEthernet
; Put a string to the LCD
 call clear_lcd
 ld b,%00001110         ; This sets cursor on and cursor blinking off
 call set_lcd
 ld hl,s_OSstring
 ld de,$2000
 call str2lcd
 ld a,Line2
 call setDDRAMa
 ld hl,s_version
 ld de,$2000
 call str2lcd
 ld b,%00001111         ; This sets cursor and cursor blinking on
 call set_lcd
 ld b,' '
 call char2lcd
; Wait for user to push Enter-button
 ld a,%11111110
 out (KeyS),a
sup_waitEnter:
 in a,(KeyR)
 bit 0,a
 jr nz,sup_waitEnter
; Start the default command prompt
mcp_start:
 call clear_lcd         ; This clears the LCD and returns cursor to home
 ld b,%00001111         ; This sets cursor and cursor blinking on
 call set_lcd           ;
 ld a,Line1
 call setDDRAMa
 ld hl,s_defprompt
 call str2lcd
 ld a,Line2
 call setDDRAMa
 ld b,'>'
 call char2lcd
; Wait for user to give a command
mcp_command:
 ld a,none
 ld (key_pressed),a
 ld a,$40
 ld (key_delay),a
 ld hl,$0000
 ld (key_repeatdelay),hl
 ld hl,$0000
 ld (key_repeatrate),hl
 ld a,$ff
 ld (key_rset),a
;
mcp_comloop:
 call key_getkey
; Now test which key was pressed
 cp Enter
 jp z,mcp_Enter

 cp CK0
 jp nz,mcp_nhelp
 ld hl,s_help
 ld c,CK0
 jp mcp_str2lcd
mcp_nhelp:
 cp CK1
 jp nz,mcp_nhexedit
 ld hl,s_hexedit
 ld c,CK1
 jp mcp_str2lcd
mcp_nhexedit:
 cp CK5
 jp nz,mcp_ncopy
 call key_testshift
 jr nz,mcp_copy_nshift
 ld hl,s_copy_system
 ld c,CK5+$a0
 jp mcp_str2lcd
mcp_copy_nshift:
 jp mcp_comloop
mcp_ncopy:
;
 jp mcp_comloop
;
mcp_str2lcd:
 ld a,Line2
 call setDDRAMa
 call str2lcd
 jp mcp_comloop
; ***
mcp_Enter
 ld a,c
 cp none
 jp z,mcp_command
 ld c,none
 cp CK0
 jp z,mcp_help
 cp CK1
 jp z,mcp_hexedit
 cp CK5+$a0
 jp z,mcp_cs
 jp mcp_comloop
; ***
mcp_help:
 ld hl,s_helptext
 call help_read
 jp mcp_start
mcp_hexedit:
 call hexedit
 jp mcp_start
mcp_cs:
 call copy_system
 jp mcp_start
; *** help_read
; Help reader
help_read:
 call reset_lcd
 push af
 push de
 ld (T0),hl
;
 ld a,Line1
 call setDDRAMa
 call str2lcd
 inc hl
 ld a,(hl)
 ld d,$02
 cp $17
 jr z,hr_start
 ld a,Line2
 call setDDRAMa
 call str2lcd
 inc hl
 ld a,(hl)
 call hr_dec21hl
 cp $17
 jr z,hr_start
 ld d,$01
hr_start:
 ld a,Enter
 ld (key_pressed),a
 ld a,$20
 ld (key_delay),a
 push hl
 ld hl,(RepeatDelay)
 ld (key_repeatdelay),hl
 ld hl,(RepeatRate)
 ld (key_repeatrate),hl
 pop hl
 ld a,$ff
 ld (key_rset),a
;
hr_loop:
 call key_getkey
; Now test which key was pressed
 cp Enter
 jp z,hr_end
 cp CK1
 jp z,hr_rollup
 cp CK3
 jp z,hr_rolldown
 jp hr_loop
;
hr_rolldown:
 ld a,$02
 cp d
 jr z,hr_rd_end
hr_rd_ru:
 ld a,Line1
 call setDDRAMa
 call str2lcd
 inc hl
 ld a,(hl)
 ld d,$02
 cp $17
 jr nz,hr_rd_jp
 push hl
 ld hl,s_endof
 ld a,Line2
 call setDDRAMa
 call str2lcd
 pop hl
 jr hr_rd_end
hr_rd_jp:
 ld a,Line2
 call setDDRAMa
 call str2lcd
 inc hl
 ld a,(hl)
 call hr_dec21hl
 cp $17
 jr z,hr_rd_end
 ld d,$01
hr_rd_end:
 jp hr_loop
;
hr_rollup:
 ld e,2
hr_ru_uploop:
 ld a,(T1)
 cp h
 jr nz,hr_ru_nu
 ld a,(T0)
 cp l
 jp z,hr_ru_end
hr_ru_nu:
 call hr_dec21hl
 dec e
 jr nz,hr_ru_uploop
 jp hr_rd_ru
hr_ru_end:
 jp hr_loop
hr_dec21hl:
 ld a,21
hr_dec21hl_loop:
 dec hl
 dec a
 jr nz,hr_dec21hl_loop
 ret
;
hr_end:
 pop de
 pop af
 ret
; end of help_read

; *** hexedit
; Hex editor
hexedit:
 push af
 push bc
 push de
 push hl
;
 ld a,(b_he_addset)
 cp $17
 jr z,he_addset
 ld hl,UMO
 ld (w_he_jumpaddr),hl
 ld (w_he_calladdr),hl
 dec hl
 dec hl
 ld (w_he_address),hl
 ld a,$17
 ld (b_he_addset),a
 ld a,$00
 ld (b_he_input),a
 ld a,$00
 ld (b_he_output),a
he_addset:
 call clear_lcd
 ld a,Line1
 call setDDRAMa
 ld hl,s_he_string
 call str2lcd
 ld a,Line2
 call setDDRAMa
 ld hl,s_enter
 call str2lcd
; Wait for Enter-key be pressed
 ld a,Enter
 ld (key_pressed),a
 ld a,$10
 ld (key_delay),a
 ld hl,$0000
 ld (key_repeatdelay),hl
 ld hl,$0000
 ld (key_repeatrate),hl
 ld a,$ff
 ld (key_rset),a
he_swaitEnter:
 call key_getkey
 cp Enter
 jr nz,he_swaitEnter
 ld a,Enter
he_start:
 ld (key_pressed),a
 ld a,1
 ld (b_he_nibble),a
 call clear_lcd
 ld b,%00001110         ; This sets cursor on and cursor blinking off
 call set_lcd
 ld hl,(w_he_address)
 call he_showmemory
 ld a,$10
 ld (key_delay),a
 ld hl,(RepeatDelay)
 ld (key_repeatdelay),hl
 ld hl,(RepeatRate)
 ld (key_repeatrate),hl
 ld a,$ff
 ld (key_rset),a
;
he_loop:
 call key_getkey
; Now test which key was pressed
 cp $10
 jp c,he_change
 cp Enter
 jp z,he_end
 cp CK0
 jp nz,he_nhelp
 call key_testshift
 jp z,he_help
 jp he_setaddress
he_nhelp:
 cp CK1
 jp nz,he_nrollup
 call key_testshift
 jp z,he_rollup4
 jp he_rollup
he_nrollup:
 cp CK3
 jp nz,he_nrolldown
 call key_testshift
 jp z,he_rolldown4
 jp he_rolldown
he_nrolldown:
 cp CK5
 jp z,he_undo
 cp CK2
 jp nz,he_noutput
 call key_testshift
 jp z,he_jump
 jp he_output
he_noutput:
 cp CK4
 jp nz,he_ninput
 call key_testshift
 jp z,he_call
 jp he_input
he_ninput:
 jp he_loop
; Ouput given value to given I/O-address
he_output:
 push bc
 ld c,a
 ld a,(b_he_output)
 ld b,a
 ld a,c
 push af
 push hl
 call clear_lcd
 ld a,Line1
 call setDDRAMa
 ld hl,s_inputioaddr
 call str2lcd
 pop hl
 pop af
 call key_getbvalue
 cp CK5
 jr z,he_op_end
 ld c,b
 push af
 ld a,b
 ld (b_he_output),a
 pop af
 ld b,$00
 call key_getbyte
 cp CK5
 jr z,he_op_end
 out (c),b
he_op_end:
 pop bc
 jp he_start
; Input value from given I/O-address
he_input:
 push bc
 ld c,a
 ld a,(b_he_input)
 ld b,a
 ld a,c
 push af
 push hl
 call clear_lcd
 ld a,Line1
 call setDDRAMa
 ld hl,s_inputioaddr
 call str2lcd
 pop hl
 pop af
 call key_getbvalue
 cp CK5
 jr z,he_ip_end
 ld c,b
 ld b,a
 ld a,c
 ld (b_he_input),a
 in a,(c)
 ld c,SSeg3
 or a
 call b_to_7seg
 ld a,$ff
 out (SSeg1),a
 out (SSeg2),a
 ld a,b
he_ip_end:
 pop bc
 jp he_start
; Show Hex editor's help
he_help:
 ld hl,s_he_help
 call help_read
 ld a,Enter
 jp he_start
; Roll memory up
he_rollup:
 push hl
 ld hl,(w_he_address)
 dec hl
 ld (w_he_address),hl
 ld a,1
 ld (b_he_nibble),a
 call he_showmemory
 pop hl
 jp he_loop
; Roll memory down
he_rolldown:
 push hl
 ld hl,(w_he_address)
 inc hl
 ld (w_he_address),hl
 ld a,1
 ld (b_he_nibble),a
 call he_showmemory
 pop hl
 jp he_loop
; Roll memory up by 4
he_rollup4:
 push hl
 ld hl,(w_he_address)
 dec hl
 dec hl
 dec hl
 dec hl
 ld (w_he_address),hl
 ld a,1
 ld (b_he_nibble),a
 call he_showmemory
 pop hl
 jp he_loop
; Roll memory down by 4
he_rolldown4:
 push hl
 ld hl,(w_he_address)
 inc hl
 inc hl
 inc hl
 inc hl
 ld (w_he_address),hl
 ld a,1
 ld (b_he_nibble),a
 call he_showmemory
 pop hl
 jp he_loop
; Change memory
he_change:
 push hl
 push bc
 ld hl,(w_he_address)
 inc hl
 inc hl
 ld b,(hl)
 ld c,a
;
 ld a,(b_he_nibble)
 cp 0
 jr nz,he_ch_n0
 ld a,b
 ld (b_he_undovalue),a
 ld (w_he_undoaddr),hl
 and $f0
 ld b,a
 ld a,c
 and $0f
 or b
 ld (hl),a
 ld a,1
 ld (b_he_nibble),a
 inc hl
 jp he_ch_end
he_ch_n0:
 ld a,b
 ld (b_he_undovalue),a
 ld (w_he_undoaddr),hl
 and $0f
 ld b,a
 ld a,c
 sla a
 sla a
 sla a
 sla a
 and $f0
 or b
 ld (hl),a
 ld a,0
 ld (b_he_nibble),a
he_ch_end:
 ld a,$00
 ld (b_he_undoset),a
 dec hl
 dec hl
 ld (w_he_address),hl
 call he_showmemory
 pop bc
 pop hl
 jp he_loop
; Undo
he_undo
 push hl
 ld hl,(w_he_undoaddr)
 ld a,(b_he_undoset)
 cp $ff
 jr z,he_un_end
 push bc
 ld a,(b_he_undovalue)
 ld b,(hl)
 ld (hl),a
 ld a,b
 ld (b_he_undovalue),a
 ld a,1
 ld (b_he_nibble),a
 pop bc
he_un_end
 dec hl
 dec hl
 ld (w_he_address),hl
 call he_showmemory
 pop hl
 jp he_loop
; Set address
he_setaddress:
 push hl
 ld hl,(w_he_address)
 inc hl
 inc hl
 call key_getaddress
 dec hl
 dec hl
 ld (w_he_address),hl
 pop hl
 jp he_start
; Jump to address
he_jump:
 ld hl,(w_he_jumpaddr)
 call key_getaddress
 cp CK5
 jp z,he_start
 ld (w_he_jumpaddr),hl
 ld hl,w_he_jumpaddr
 jp (hl)
; Call to address
he_call:
 push af
 push hl
 ld hl,(w_he_calladdr)
 call key_getaddress
 cp CK5
 jr z,he_call_end
 ld (w_he_calladdr),hl
 ld a,(he_call_jumpcmd)
 ld (b_he_calljump),a
 call b_he_calljump
he_call_end:
 pop hl
 pop af
 jp he_start
he_call_jumpcmd
 jp $0000
; Show 4bytes of memory contents, start address in hl
he_showmemory:
 push af
 push bc
;
 call clear_lcd
 ld a,Line1
 call setDDRAMa
 call he_sm_show
 dec hl
 dec hl
 ld b,(hl)
 call char2lcd
 inc hl
 ld b,(hl)
 call char2lcd
 inc hl
 ld b,(hl)
 call char2lcd
 inc hl
 ld b,(hl)
 call char2lcd
 dec hl

 ld a,Line2
 call setDDRAMa
 call he_sm_show

 jp he_sm_end
;
he_sm_show:
 ld c,2
he_sm_loop:
 ld a,h
 call byte2lcd
 ld a,l
 call byte2lcd
 ld b,':'
 call char2lcd
 ld a,(hl)
 call byte2lcd
 ld b,' '
 call char2lcd
 inc hl
 dec c
 jr nz,he_sm_loop
 ret
;
he_sm_end
 ld a,(b_he_nibble)
 ld b,a
 ld a,Line2+6
 sub b
 call setDDRAMa
 dec hl
 dec hl
 dec hl
 dec hl
 pop bc
 pop af
 ret
;
he_end:
 pop hl
 pop de
 pop bc
 pop af
 ret
; end of hexedit

; *** copy_system
; Copy's 8KB system ROM ($0000-$2000) to given address
copy_system:
 push af
 push bc
 push de
 push hl
 di
 call clear_lcd
 ld a,Line1
 call setDDRAMa
 ld hl,s_inputdelay
 call str2lcd
 ld a,Enter
 ld hl,$0500
 call key_getwvalue
 cp CK5
 jr z,cs_end
 ld (T0),hl
 ld hl,$c000
 call key_getaddress
 cp CK5
 jr z,cs_end
;
 ld d,h
 ld e,l
 call clear_lcd
 ld hl,$0000
cs_loop:
 ld a,(hl)
 ld (de),a
 push hl
 ld hl,(T0)
 call DelayHL
 pop hl
 inc hl
 inc de
 ld a,$20
 cp h
 jr z,cs_end
 ld a,h
 ld c,SSeg1
 call b_to_7seg
 ld a,l
 ld c,SSeg3
 call b_to_7seg
 jr cs_loop
cs_end:
 ei
 pop hl
 pop de
 pop bc
 pop af
 ret
; end of copy_system

;**************************************************************
; Misc data, example character strings
s_OSstring      .db "Z80 WestOS, by Duge",$17
s_version       .db "version b0.63",$17
s_halted        .db "CPU halted.",$17
s_defprompt     .db "Input  command:",$17
s_help          .db ">help               ",$17
s_hexedit       .db ">hexedit            ",$17
s_copy_system   .db ">copy system        ",$17
s_clearline     .db "                    ",$17
s_endof         .db "*-------end--------*",$17
s_enter         .db "Press Enter.........",$17
s_helptext      .db "#Use CK1 and CK3 to ",$17
                .db "#roll up and down   ",$17
                .db "CK0: Help           ",$17
                .db "Show this help      ",$17
                .db "CK1: Hexedit        ",$17
                .db "Memory hex editor   ",$17
                .db "Also for I/O-usage  ",$17
                .db "Shift:              ",$17
                .db "Usage of Shift is   ",$17
                .db "marked with ^X,     ",$17
                .db "where X is some key ",$17
                .db "#Press Enter to exit",$17
                .db $17
s_he_help       .db "#Up:CK1 Down:CK3    ",$17
                .db "Enter: Exit hexedit ",$17
                .db "CK0: Choose address ",$17
                .db "CK2: I/O output     ",$17
                .db "^CK2: Jump to n     ",$17
                .db "CK4: I/O input      ",$17
                .db "^CK4: Call to n     ",$17
                .db "After this command  ",$17
                .db "the value read from ",$17
                .db "given port is seen  ",$17
                .db "in 7segments as hex.",$17
                .db "CK1: Roll memory up ",$17
                .db "^CK1: Up by 4       ",$17
                .db "CK3: Roll mem. down ",$17
                .db "^CK3: Down by 4     ",$17
                .db "CK5: Undo           ",$17
                .db "Undo in most cases. ",$17
                .db "0-F: Change memory  ",$17
                .db "^CK0: Help          ",$17
                .db "#Press Enter to exit",$17
                .db $17
s_he_string     .db "WestOS Hexedit v0.24",$17
s_inputaddress  .db "Give address:",$17
s_inputword     .db "Give word:",$17
s_inputbyte     .db "Give byte:",$17
s_inputioaddr   .db "Give I/O-address:",$17
s_inputdelay    .db "Give delay:",$17
hextolcd        .db '0','1','2','3','4','5','6','7','8','9'
                .db 'A','B','C','D','E','F'
hexto7segment   .db %10000001,%10110111,%11000010,%10010010
                .db %10110100,%10011000,%10001000,%10110011
                .db %10000000,%10010000,%10100000,%10001100
                .db %11001001,%10000110,%11001000,%11101000
;**************************************************************

;**************************************************************
; This code is for the ISA ethernet NIC -adapter
; .org $4000

; Call(jump)-table for applications
ethReset:
 ld hl,(ejReset)
 jp (hl)
ethEnable:
 ld hl,(ejEnable)
 jp (hl)
ethReceive:
 ld hl,(ejReceive)
 jp (hl)
ethSend:
 ld hl,(ejSend)
 jp (hl)
;

; ***
; Drivers
; ***
;ethbase                 equ $40
#define einb(address) ld a,(ethbase)\ add a,address\ ld c,a\ in a,(c)
#define eoutb(address) ld (ethtmp),a\ ld a,(ethbase)\ add a,address\ ld c,a\ ld a,(ethtmp)\ out (c),a
#define eoutb_ ld (ethtmp),a\ ld a,(ethbase)\ add a,c\ ld c,a\ ld a,(ethtmp)\ out (c),a
ethcom          equ $80

; Ethernet NIC's
NEcomp     equ $01
SMCultra   equ $02
SMCEtherEZ equ $03
c3c509     equ $04
noNIC      equ $69

NoNIC        .db "No Ethernet NIC     ",$17,
             .db "found.              ",$17,$17
NICsearch    .db "Searching for NIC...",$17

; Drivers for NE1000/NE2000 (DP8390) compatible adapters
; Mostly copied from linux 2.4.5 kernels NE1000/NE2000 (DP8390) drivers
; (written by Donald Becker)
ne_copyright .db "NEx000 drivers      ",$17
             .db "By Duge. Mostly     ",$17
             .db "copied from linux   ",$17
             .db "kernel drivers      ",$17
             .db "written by          ",$17
             .db "Donald Becker.      ",$17,$17
ne_nodev     .db "No NE[1,2]000 found.",$17,
             .db "                    ",$17,$17
ne_noreset   .db "Reset failed on     ",$17
             .db "NE[1,2]000-NIC.     ",$17,$17
ne1_detected .db "NE1000-NIC          ",$17
             .db "detected.           ",$17,$17
ne2_detected .db "NE2000-NIC          ",$17
             .db "detected.           ",$17,$17
neC_detected .db "NE-compatible Ctron-",$17
             .db "NIC detected.       ",$17,$17

; #define's
;
; Weird stuff, but have no reason to change this 'grab' from
; the linux kernel, so leaving it like this
;
#define TX_2X_PAGES 12
#define TX_1X_PAGES 6
; Should always use two Tx slots to get back-to-back transmits.
#define EI_PINGPONG
#ifdef EI_PINGPONG
#define TX_PAGES TX_2X_PAGES
#else
#define TX_PAGES TX_1X_PAGES
#endif
;

NE_BASE                 equ $00
NE_CMD                  equ $00
NE_DATAPORT             equ $10    ; NatSemi-defined port window offset. 
NE_RESET                equ $1f    ; Issue a read to reset, a write to clear. 
NE_IO_EXTENT            equ $20

NE1SM_START_PG          equ $20    ; First page of TX buffer 
NE1SM_STOP_PG           equ $40    ; Last page +1 of RX ring 
NESM_START_PG           equ $40    ; First page of TX buffer 
NESM_STOP_PG            equ $80    ; Last page +1 of RX ring 
; Some generic ethernet register configurations.
E8390_TX_IRQ_MASK	equ $a	; For register EN0_ISR 
E8390_RX_IRQ_MASK	equ $5
E8390_RXCONFIG		equ $4	; EN0_RXCR: broadcasts, no multicast,errors 
E8390_RXOFF		equ $20	; EN0_RXCR: Accept no packets 
E8390_TXCONFIG		equ $00	; EN0_TXCR: Normal transmit mode 
E8390_TXOFF		equ $02	; EN0_TXCR: Transmitter off 

; Register accessed at EN_CMD, the 8390 base addr.  
E8390_STOP	equ $01	; Stop and reset the chip 
E8390_START	equ $02	; Start the chip, clear reset 
E8390_TRANS	equ $04	; Transmit a frame 
E8390_RREAD	equ $08	; Remote read 
E8390_RWRITE	equ $10	; Remote write  
E8390_NODMA	equ $20	; Remote DMA 
E8390_PAGE0	equ $00	; Select page chip registers 
E8390_PAGE1	equ $40	; using the two high-order bits 
E8390_PAGE2	equ $80	; Page 3 is invalid. 
 
E8390_CMD	equ $00  ; The command register (for all pages 
; Page 0 register offsets. 
EN0_CLDALO	equ $01	; Low byte of current local dma addr  RD 
EN0_STARTPG	equ $01	; Starting page of ring bfr WR 
EN0_CLDAHI	equ $02	; High byte of current local dma addr  RD 
EN0_STOPPG	equ $02	; Ending page +1 of ring bfr WR 
EN0_BOUNDARY	equ $03	; Boundary page of ring bfr RD WR 
EN0_TSR		equ $04	; Transmit status reg RD 
EN0_TPSR	equ $04	; Transmit starting page WR 
EN0_NCR		equ $05	; Number of collision reg RD 
EN0_TCNTLO	equ $05	; Low  byte of tx byte count WR 
EN0_FIFO	equ $06	; FIFO RD 
EN0_TCNTHI	equ $06	; High byte of tx byte count WR 
EN0_ISR		equ $07	; Interrupt status reg RD WR 
EN0_CRDALO	equ $08	; low byte of current remote dma address RD 
EN0_RSARLO	equ $08	; Remote start address reg 0 
EN0_CRDAHI	equ $09	; high byte, current remote dma address RD 
EN0_RSARHI	equ $09	; Remote start address reg 1 
EN0_RCNTLO	equ $0a	; Remote byte count reg WR 
EN0_RCNTHI	equ $0b	; Remote byte count reg WR 
EN0_RSR		equ $0c	; rx status reg RD 
EN0_RXCR	equ $0c	; RX configuration reg WR 
EN0_TXCR	equ $0d	; TX configuration reg WR 
EN0_COUNTER0	equ $0d	; Rcv alignment error counter RD 
EN0_DCFG	equ $0e	; Data configuration reg WR 
EN0_COUNTER1	equ $0e	; Rcv CRC error counter RD 
EN0_IMR		equ $0f	; Interrupt mask reg WR 
EN0_COUNTER2	equ $0f	; Rcv missed frame error counter RD 

; Bits in EN0_ISR - Interrupt status register 
ENISR_RX	equ $01	; Receiver, no error 
ENISR_TX	equ $02	; Transmitter, no error 
ENISR_RX_ERR	equ $04	; Receiver, with error 
ENISR_TX_ERR	equ $08	; Transmitter, with error 
ENISR_OVER	equ $10	; Receiver overwrote the ring 
ENISR_COUNTERS	equ $20	; Counters need emptying 
ENISR_RDC	equ $40	; remote dma complete 
ENISR_RESET	equ $80	; Reset completed 
ENISR_ALL	equ $3f	; Interrupts we will enable 

; Bits in EN0_DCFG - Data config register 
ENDCFG_WTS	equ $01	; word transfer mode selection 
ENDCFG_BOS	equ $02	; byte order selection 

; Page 1 register offsets. 
EN1_PHYS   equ $01	; This board's physical enet addr RD WR 
;EN1_PHYS_SHIFT(i  equ i+1 ; Get and set mac address 
EN1_CURPAG equ $07	; Current memory page RD WR 
EN1_MULT   equ $08	; Multicast filter mask array (8 bytes RD WR 
;EN1_MULT_SHIFT(i  equ 8+i ; Get and set multicast filter 

; Bits in received packet status byte and EN0_RSR
ENRSR_RXOK	equ $01	; Received a good packet 
ENRSR_CRC	equ $02	; CRC error 
ENRSR_FAE	equ $04	; frame alignment error 
ENRSR_FO	equ $08	; FIFO overrun 
ENRSR_MPA	equ $10	; missed pkt 
ENRSR_PHY	equ $20	; physical/multicast address 
ENRSR_DIS	equ $40	; receiver disable. set in monitor mode 
ENRSR_DEF	equ $80	; deferring 

; Transmitted packet status, EN0_TSR. 
ENTSR_PTX equ $01	; Packet transmitted without error 
ENTSR_ND  equ $02	; The transmit wasn't deferred. 
ENTSR_COL equ $04	; The transmit collided at least once. 
ENTSR_ABT equ $08  ; The transmit collided 16 times, and was deferred. 
ENTSR_CRS equ $10	; The carrier sense was lost. 
ENTSR_FU  equ $20  ; A "FIFO underrun" occurred during transmit. 
ENTSR_CDH equ $40	; The collision detect "heartbeat" signal was lost. 
ENTSR_OWC equ $80  ; There was an out-of-window collision. 

; Something from Writing drivers for DP8390 -datasheet
;command                 equ ethbase+$00
;pagestart               equ ethbase+$01
;pagestop                equ ethbase+$02
;boundary                equ ethbase+$03
;transmitstatus          equ ethbase+$04
;transmitpage            equ ethbase+$04
;transmitbytecount0      equ ethbase+$05
;ncr                     equ ethbase+$05
;transmitbytecount1      equ ethbase+$06
;interruptstatus         equ ethbase+$07
;current                 equ ethbase+$07
;remotestartaddress0     equ ethbase+$08
;crdma0                  equ ethbase+$08
;remotestartaddress1     equ ethbase+$09
;crdma1                  equ ethbase+$09
;remotebytecount0        equ ethbase+$0a
;remotebytecount1        equ ethbase+$0b
;receivestatus           equ ethbase+$0c
;receiveconfiguration    equ ethbase+$0c
;transmitconfiguration   equ ethbase+$0d
;fae_tally               equ ethbase+$0d
;dataconfiguration       equ ethbase+$0e
;crc_tally               equ ethbase+$0e
;interruptmask           equ ethbase+$0f
;miss_pkt_tally          equ ethbase+$0f
;ioport                  equ ethbase+$10

ne_initregs  .db 13
             .db E8390_NODMA+E8390_PAGE0+E8390_STOP,E8390_CMD ; Select page 0
             .db $48,  EN0_DCFG                               ; Set byte-wide ($48) access. 
             .db $00,  EN0_RCNTLO                             ; Clear the count regs. 
             .db $00,  EN0_RCNTHI 
             .db $00,  EN0_IMR                                ; Mask completion irq. 
             .db $FF,  EN0_ISR 
             .db E8390_RXOFF, EN0_RXCR                        ; $20  Set to monitor 
             .db E8390_TXOFF, EN0_TXCR                        ; $02  and loopback mode. 
             .db 32,   EN0_RCNTLO
             .db $00,  EN0_RCNTHI
             .db $00,  EN0_RSARLO                             ; DMA starting at $0000. 
             .db $00,  EN0_RSARHI
             .db E8390_RREAD+E8390_START, E8390_CMD

; *** neir
; Init registers to "default"
neir:
 ld hl,ne_initregs
 ld a,(ne_initregs)
 ld b,a
neir_loop:
 inc hl
 inc hl
 ld a,(ethbase)
 add a,(hl)
 ld c,a
 dec hl
 ld a,(hl)
 inc hl
 out (c),a
 dec b
 jr nz,neir_loop
 ret
; end of neir

; *** NEinit
NE_init:
 call ne_probe
 ld a,(ethdetect)
 cp noNIC
 jr z,nein_end
; Propably not good thing to enable the NIC now
; call DP8390_enable
nein_end:
 ret
; end of NEinit

; *** ne_probe
; Let's probe for NEx000-based card
ne_probe:
 xor a
 out (ethcom),a
 einb(0)
 ld (ethT1),a
 cp $ff
 jr nz,nepb_maybe0
 jp nepb_nodev
nepb_maybe0:
 ld a,E8390_NODMA+E8390_PAGE1+E8390_STOP
 eoutb(E8390_CMD)
 einb($0d)
 ld (ethT0),a
 ld a,$ff
 eoutb($0d)
 ld a,E8390_NODMA+E8390_PAGE0
 eoutb(E8390_CMD)
 einb(EN0_COUNTER0)
 cp 0
 jr z,nepb_possibly0
 ld a,(ethT1)
 eoutb(0)
 ld a,(ethT0)
 eoutb($0d)
 jp nepb_nodev
nepb_possibly0:
 call ne_reset          ; Reset
 cp $17                 ; See if reset successful
 jr z,nepb_resets       ;
 ld hl,ne_noreset
 call help_read
 call clear_lcd
 ld hl,$a000
 call DelayHL
nepb_resets:
 call neir
; Read station address PROM (SAPROM)
 ld a,2
 ld (ethwrdlen),a
 ld b,16
 ld hl,ethsaprom
 ld a,(ethbase)
 add a,NE_DATAPORT
 ld c,a
nepb_readsaprom:
 in a,(c)
 ld (hl),a
 inc hl
 ld d,a
 in a,(c)
 ld (hl),a
 inc hl
 cp d
 jr z,nepb_wrdlen2
 ld a,1
 ld (ethwrdlen),a
nepb_wrdlen2:
 dec b
 jr nz,nepb_readsaprom
; Do some settings depending on if the NIC was detected as
; 16bit or 8bit card
 ld a,(ethwrdlen)
 cp 2
 jr nz,nepb_byte
 ld bc,ethsaprom
 ld hl,ethsaprom
 ld d,16
nepb_wsaset:
 ld a,(hl)
 ld (bc),a
 inc bc
 inc hl
 inc hl
 dec d
 jr nz,nepb_wsaset
;
 ld a,$49
 eoutb(EN0_DCFG)
 ld a,(NESM_START_PG)
 ld (etxStartPage),a
 add a,TX_PAGES
 ld (erxStartPage),a
 ld a,(NESM_STOP_PG)
 ld (ethStopPage),a
 jr nepb_jbyte
nepb_byte:
 ld a,(NE1SM_START_PG)
 ld (etxStartPage),a
 add a,TX_PAGES
 ld (erxStartPage),a
 ld a,(NE1SM_STOP_PG)
 ld (ethStopPage),a
nepb_jbyte:
; Save hardware-address
 ld d,6
 ld hl,ethsaprom
 ld bc,ethhwaddr
nepb_hwsave:
 ld a,(hl)
 ld (bc),a
 inc hl
 inc bc
 dec d
 jr nz,nepb_hwsave
 call DP8390_init
; Save the NIC's ID
 ld a,NEcomp
 ld (ethdetect),a
 ld hl,ne_detected
; Set up jump-table which is called by applications
 ld hl,ne_reset
 ld (ejReset),hl
 ld hl,DP8390_enable
 ld (ejEnable),hl
 jr nepb_end
nepb_nodev:
 ld hl,ne_nodev
 jr nepb_end
nepb_noreset:
 ld a,NEcomp
 ld (ethdetect),a
 ld hl,ne_noreset
 jr nepb_end
;
nepb_end:
 ret
; end of ne_probe

; *** ne_reset
ne_reset:
 ld a,(ethbase)
 add a,NE_RESET
 ld c,a
 in a,(c)
 out (c),a
 ld hl,$1000
 call DelayHL
 einb(EN0_ISR)
 and ENISR_RESET
 jr nz,ners_success
 ld a,$69
 ret
ners_success:
 ld a,$ff
 eoutb(EN0_ISR)
 ld a,$17
 ret
; end of ne_reset

; *** end of NEx000 compatible adapters driver
;**************************************************************

;**************************************************************
; Drivers for SMC-ultra (ex.83c790) adapters
; Mostly copied from linux 2.4.5 kernels SMC-ultra drivers
; (written by Donald Becker)
smc_copyright .db "SMC Ultra drivers   ",$17
              .db "By Duge. Mostly     ",$17
              .db "copied from linux   ",$17
              .db "kernel drivers      ",$17
              .db "written by          ",$17
              .db "Donald Becker.      ",$17,$17
smc_nodev     .db "No SMC Ultra found. ",$17,
              .db "                    ",$17,$17
smc_noreset   .db "Reset failed on     ",$17
              .db "SMC Ultra.          ",$17,$17
smcu_detected .db "SMC Ultra-NIC       ",$17
              .db "detected.           ",$17,$17
smce_detected .db "SMC EtherEZ-NIC     ",$17
              .db "detected.           ",$17,$17

; #define's
START_PG equ $00	        ; First page of TX buffer

ULTRA_CMDREG            equ 0    ; Offset to ASIC command register. 
ULTRA_RESET             equ $80  ; Board reset, in ULTRA_CMDREG. 
ULTRA_MEMENB            equ $40  ; Enable the shared memory. 
IOPD                    equ $02  ; I/O Pipe Data (16 bits), PIO operation. 
IOPA                    equ $07  ; I/O Pipe Address for PIO operation. 
ULTRA_NIC_OFFSET        equ 16   ; NIC register offset from the base_addr. 
ULTRA_IO_EXTENT         equ 32
EN0_ERWCNT              equ $08  ; Early receive warning count. 

; *** SMC_init
SMC_init:
 call SMC_probe
 ld a,(ethdetect)
 cp noNIC
 jr z,smcin_end
 push hl
 call SMC_reset
 call SMC_open
 pop hl
smcin_end:
 ret
; end of SMC_init

; *** SMC_probe
SMC_probe:
 xor a
 out (ethcom),a
 einb(7)
 and $f0
 ld (ethT0),a
 cp $20          ; SMC Ultra
 jr z,smcpb_maybe0
 cp $40          ; SMC EtherEZ, not Ultra but should work also
 jr z,smcpb_maybe0
 ld a,$11
 ld (ethT2),a
 jp smcpb_nodev
smcpb_maybe0:
 einb(4)
 and $7f
 ld (ethT1),a
 eoutb(4)
 einb(8+0)
 ld d,a
 einb(8+1)
 add a,d
 ld d,a
 einb(8+2)
 add a,d
 ld d,a
 einb(8+3)
 add a,d
 ld d,a
 einb(8+4)
 add a,d
 ld d,a
 einb(8+5)
 add a,d
 ld d,a
 einb(8+6)
 add a,d
 ld d,a
 einb(8+7)
 add a,d
 cp $ff
 jp z,smcpb_maybe1
 ld a,$12
 ld (ethT2),a
 jp smcpb_nodev
smcpb_maybe1:
; SMC-ultra found
; Save MAC-address
 einb(8+0)
 ld (ethhwaddr+0),a
 einb(8+1)
 ld (ethhwaddr+1),a
 einb(8+2)
 ld (ethhwaddr+2),a
 einb(8+3)
 ld (ethhwaddr+3),a
 einb(8+4)
 ld (ethhwaddr+4),a
 einb(8+5)
 ld (ethhwaddr+5),a
;
 ld a,(ethT1)
 or $80
 eoutb(4)
; Enabled FINE16 mode to avoid BIOS ROM width mismatches @ reboot.
; (hee...)
 einb($0c)
 or $80
 eoutb($0c)
 einb($08)
 ld (ethpiomode),a
 einb($0b)
 ld (ethaddr),a
 einb($0d)
 ld (ethirqreg),a
; "Switch back to the station address register set so that the MS-DOS driver
; can find the card after a warm boot."
; (This was cut directly from linux kernel, so... :) )
 ld a,(ethT1)
 eoutb(4)
 ld a,(ethbase)
 add a,ULTRA_NIC_OFFSET
 ld (ethbase),a
 call DP8390_init
;
; That's it for now...
;
; SMC-ultra was found
; See if it is EtherEZ instead
 ld a,(ethT0)
 cp $20
 jr z,smcpb_ultrad
 ld a,SMCEtherEZ     ; EtherEZ
 ld (ethdetect),a
 ld hl,smce_detected
 jr smcpb_end
smcpb_ultrad:
 ld a,SMCultra
 ld (ethdetect),a
 ld hl,smcu_detected
 jr smcpb_end
smcpb_nodev:
 ld hl,smc_nodev
 jr smcpb_end
smcpb_end:
; end of SMC_probe

; *** SMC_open
SMC_open:
 xor a
 out (ethcom),a
 ld a,(ethbase)
 sub ULTRA_NIC_OFFSET
 ld (ethbase),a
; Disable shared memory. There's no use for it.
 eoutb(0)
 ld a,$80
 eoutb(5)
; Set IRQ.. Use of this in this code?!? Will see later.
 einb(4)
 or $80
 eoutb(4)
 einb(13)
 and $b3
 or $44         ; THIS IS FOR IRQ10, must be changed!!!
 eoutb(13)
 einb(4)
 and $7f
 eoutb(4)
; Assume PIO-mode for now. ;)
; Hmmm.. Are we able to use the memory?!? :)
 ld a,$11
 eoutb(6)
 ld a,$01
 eoutb($19)
; Set the early receive warning level in window 0 high enough not
; to receive ERW interrupts.
 ld a,E8390_NODMA+E8390_PAGE0
 eoutb(0)
 ld a,$ff
 eoutb(EN0_ERWCNT)
;
 ld a,(ethbase)
 add a,ULTRA_NIC_OFFSET
 ld (ethbase),a
 ret
; end of SMC_open

; *** SMC_reset
SMC_reset:
 xor a
 out (ethcom),a
 ld a,(ethbase)
 sub ULTRA_NIC_OFFSET
 ld (ethbase),a
;
 ld a,ULTRA_RESET
 eoutb(0)
; Disable shared memory. There's no use for it.
 xor a
 eoutb(0)
 ld a,$80
 eoutb(5)
; Enable interrupts and PIO
 ld a,$11
 eoutb(6)
;
 ld a,(ethbase)
 add a,ULTRA_NIC_OFFSET
 ld (ethbase),a
 ret
; *** end of SMC-ultra driver
;**************************************************************

; *** DP8390_init
; Init DP8390 registers to "default"
DP8390_inrgs .db 6
             .db E8390_NODMA+E8390_PAGE0+E8390_STOP,E8390_CMD ; Select page 0
             .db $48, EN0_DCFG                                ; Set byte-wide ($48) access. 
             .db $00, EN0_RCNTLO                              ; Clear the count regs. 
             .db $00, EN0_RCNTHI 
             .db E8390_RXOFF, EN0_RXCR                        ; $20  Set to monitor 
             .db E8390_TXOFF, EN0_TXCR                        ; $02  and loopback mode. 
dp_HWsavebad .db "DP8390 hw-address   ",$17
             .db "save failed.        ",$17,$17

;
DP8390_init:
 xor a
 out (ethcom),a
 ld hl,DP8390_inrgs
 ld b,0
dp_irloop:
 inc hl
 inc hl
 ld a,(ethbase)
 add a,(hl)
 ld c,a
 dec hl
 ld a,(hl)
 inc hl
 out (c),a
 inc b
 ld a,(DP8390_inrgs)
 cp b
 jr nz,dp_irloop
;
 ld a,(etxStartPage)
 eoutb(EN0_TPSR)
 ld a,(erxStartPage)
 eoutb(EN0_STARTPG)
 ld a,(ethStopPage)
 dec a
 eoutb(EN0_BOUNDARY)
 inc a
 eoutb(EN0_STOPPG)
 ld a,$ff
 eoutb(EN0_ISR)
 xor a
 eoutb(EN0_IMR)
;
 ld a,E8390_NODMA+E8390_PAGE1+E8390_STOP
 eoutb(E8390_CMD)
; Set hardware address
 xor a
 ld (ethT3),a
 ld b,6
 ld a,(ethbase)
 add a,EN1_PHYS
 ld c,a
 ld hl,ethhwaddr
dp_hwset:
 ld a,(hl)
 out (c),a
 inc hl
 ld d,a
 in a,(c)
 inc c
 cp d
 jr z,dp_hwgood
 ld a,$69
 ld (ethT3),a
dp_hwgood:
 dec b
 jr nz,dp_hwset
;
 ld a,(ethT3)
 cp 0
 jr z,dp_hwallgood
 call clear_lcd
 ld hl,dp_HWsavebad
 call help_read
 call clear_lcd
dp_hwallgood:
 ld a,(erxStartPage)
 eoutb(EN1_CURPAG)
 ld a,E8390_NODMA+E8390_PAGE0+E8390_STOP
 eoutb(E8390_CMD)
;
 ret
; end of DP8390_init

; *** DP8390_enable
DP8390_enable:
 ld a,$ff
 eoutb(EN0_ISR)
 ld a,ENISR_ALL
 eoutb(EN0_IMR)
 ld a,E8390_NODMA+E8390_PAGE0+E8390_START
 eoutb(E8390_CMD)
 ld a,E8390_TXCONFIG
 eoutb(EN0_TXCR)
 ld a,E8390_RXCONFIG
 eoutb(EN0_RXCR)
 ret
; end of DP8390_enable

; *** InitEthernet
InitEthernet:
 call clear_lcd
 ld hl,NICsearch
 call str2lcd
 ld hl,$a000
 call DelayHL
 ld a,noNIC
 ld (ethdetect),a
 ld a,$40
 ld (ethbase),a
;
 call NE_init
 ld a,(ethdetect)
 cp noNIC
 jr nz,ie_nicfound
 call SMC_init
 ld a,(ethdetect)
 cp noNIC
 jr nz,ie_nicfound
 ld hl,NoNIC
ie_nicfound:
 call clear_lcd
 call str2lcd
 ld hl,$a000
 call DelayHL
;
 xor a
 ld (ethtmp),a
 call clear_lcd
 ret
; end of InitEthernet

; *** eth_packetreceived
eth_packetreceived:
 push af
 push bc
 
 ld a,(ethtmp)
 inc a
 ld (ethtmp),a
 or a
 ld c,SSeg3
 call b_to_7seg

 pop bc
 pop af
 ret
; end of eth_packetreceived

;**************************************************************

.end

