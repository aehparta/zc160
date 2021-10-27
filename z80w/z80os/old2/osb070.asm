;**************************************************************
;
;                       The Z80 WestOS
;
;                 Operating System for Z80 board
;                       West 17 Designs
;
;  Authors: Antti Partanen, <aehparta@cc.hut.fi>
;
;**************************************************************
; Misc information:
; The LCD-display mentioned in the code should be 2x20
; characters LCD-display module using hd44780-based
; controller.
;
;**************************************************************

#define OS_FILE

#include "OSdef.h"

;**************************************************************
; Code origin
.org $0000

;**************************************************************
; RST $00
; Set the counters third counter's out to inactive state
; becose nmi interrupt is not a good thing in here
 ld a,$90
 out (CounterC),a
 jp RESET
; RST $08
; This RST jumps to HALT-routine
.org $0008
 jp HALT
; RST $10
.org $0010
 halt
 reti
; RST $18
.org $0018
 halt
 reti
; RST $20
.org $0020
 halt
 reti
; RST $28
.org $0028
 halt
 reti
; RST $30
.org $0030
 halt
 reti
; RST $38 or /INT-signal in interrupt mode 1
; INT is used by ethernet controller
.org $0038
 di
; Handle the ethernet NIC's interrupt
 call ethInterrupt
 ei
 reti
;**************************************************************
; Empty space for the NMI-interrupt point
; Here are three default delay routines
; and little string ;)
; $40
; $1000 loops in these delays takes about 16.428ms when
; CPU runs @4MHz
; @2MHz it takes 32.856ms
; @8MHz it takes 8.214ms
; (Interrupts are not included in these delays)
.org $0040
DelayBC:
 inc b
 inc c
DelayBC0:
 dec c          ; 1byte    4 clocks / 1us / 2us
 jr nz,DelayBC0 ; 2bytes   12/7 clocks / 3us/1.75us / 6us/3.5us
 dec b          ; 1byte    4 clocks / 1us / 2us
 jr nz,DelayBC0 ; 2bytes   12 clocks / 3us / 6us
 ret            ; 1byte
DelayDE:
 inc d
 inc e
DelayDE0:
 dec e          ; 1byte
 jr nz,DelayDE0 ; 2bytes
 dec d          ; 1byte
 jr nz,DelayDE0 ; 2bytes
 ret            ; 1byte
DelayHL:
 inc h
 inc l
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
 jp HandleNMI
 retn

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
; Writes 'HALT' into 7segments, "CPU halted." into
; system log and then halt's the cpu
; /INT and /NMI signals can wake up the CPU
; from halt-mode
HALT:
 push af
 push hl
 ld a,%10100100
 out (SSeg1),a
 ld a,%10100000
 out (SSeg2),a
 ld a,%11001101
 out (SSeg3),a
 ld a,%11101001
 out (SSeg4),a
 ld a,(SystemLogId)
 ld hl,s_SysHalt
 call AddLog
 ld a,$ff
 halt
 out (SSeg1),a
 out (SSeg2),a
 out (SSeg3),a
 out (SSeg4),a
 ld a,(SystemLogId)
 ld hl,s_SysHaltWake
 call AddLog
 pop hl
 pop af
 reti
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
; flags are changed
b_to_7seg:
 push af
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
 srl a
 srl a
 srl a
 srl a
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
 pop af
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
 srl a
 srl a
 srl a
 srl a
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
 push de
 ld a,%00000001
 out (LCDi),a
 ld a,b
 out (LCDd),a
 ld a,%00000000
 out (LCDi),a
 ld de,LCD_delay
 call Delayms
 ld a,%00000001
 out (LCDi),a
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
 ld a,%00000101
 out (LCDi),a
 ld a,b
 out (LCDd),a
 ld a,%00000100
 out (LCDi),a
 ld de,LCD_delay
 call Delayms
 ld a,%00000001
 out (LCDi),a
 pop de
 pop bc
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
; This routine also exits if it find EOL- or EOLOG-char and
; returns that char in reg c, otherwise it returns NOEOL
; The string is just added to displays previous
; contents
; none is changed
strn2lcd:
 push af
 push bc
 inc c
sn2l_loop:
 ld a,NOEOL
 dec c
 jr z,sn2l_end
 ld a,(hl)
 cp EOL
 jr z,sn2l_end
 cp EOLOG
 jr z,sn2l_end
 ld b,a
 call char2lcd
 inc hl
 jr sn2l_loop
sn2l_end:
 pop bc
 ld c,a
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
 srl a
 srl a
 srl a
 srl a
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
 srl a
 srl a
 srl a
 srl a
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
 srl a
 srl a
 srl a
 srl a
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
; and when it ends. These actions takes 30us+4.25us for calling
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

; *** CreateLog
; Creates a log into log memory if there is enough space left
; Log size in h as amount of 256B slices
; Returns logs id in reg a, if a is 0 the there was no space left to create log
; or there was too many logs
CreateLog:
 ld a,(logs_curid)
 cp MAX_LOGS
 ld a,0
 ret z
 cp h
 ret z
 ld l,0
 push bc
 push de
 push hl
 ld de,(logs_cur)
 ld bc,$10000-LOG_MEMORY_SIZE
 add hl,de
 jr c,cl_end
 add hl,bc
 jr c,cl_end
 pop hl
 push hl 
 add hl,de
 ld (logs_cur),hl
 ld bc,logs
 add hl,bc
 dec hl
 ld a,EOLOG
 ld (hl),a
 dec hl
 ld a,EOL
 ld (hl),a
; ex de,hl
; add hl,bc
; ld a,EOLOG
; ld (hl),a
 ld a,(logs_curid)
 inc a
 ld (logs_curid),a
 sla a
 ld hl,logs_ids
 ld b,0
 ld c,a
 add hl,bc
 ld de,(logs_cur)
 ld (hl),e
 inc hl
 ld (hl),d
 ld a,(logs_curid)
cl_end:
 pop hl
 pop de
 pop bc
 ret
; end of CreateLog

; *** AddLog
; Logs id in reg a and add string's address in hl
; String lenght should not be more than 255 chars
AddLog:
 push af
 push bc
 push de
 ld b,a
 ld a,(logs_curid)
 cp b
 jp c,al_end
 xor a
 cp b
 jp z,al_end
 ld a,(logs_status)
 cp log_adding
 jp z,al_end
 or log_adding
 ld (logs_status),a
; If string lenght is more than 255 chars this loop fails
; Failure is not fatal anyway, so let the 'user' do the checking
; for lenght of the string
 ld c,0
al_cnts:
 ld a,(hl)
 inc hl
 inc c
 jp c,al_cntover
 cp EOL
 jp nz,al_cnts
al_cntover:
 dec hl
 dec hl
 dec c
 jp z,al_end
 push hl
 push bc
 sla b
 dec b
 dec b
 ld d,0
 ld e,b
 ld hl,logs_ids
 add hl,de
 ld e,(hl)
 inc hl
 ld d,(hl)
 inc hl
 ld a,c
 ld c,(hl)
 inc hl
 ld b,(hl)
 ld h,0
 ld l,a
 add hl,de
 push hl
 ld a,c
 sub l
 ld c,a
 ld a,b
 sbc a,h
 ld b,a
 ld hl,logs
 add hl,de
 ex de,hl
 pop hl
 push de
 ld de,logs
 add hl,de
 pop de
 ldir
 pop bc
 sla b
 ld d,0
 ld e,b
 ld hl,logs_ids
 add hl,de
 ld e,(hl)
 inc hl
 ld d,(hl)
 ld hl,logs
 add hl,de
 dec hl
 dec hl
 ex de,hl
 pop hl
 ld b,0
 lddr
al_end:
 ld a,(logs_status)
 and ~log_adding
 ld (logs_status),a
 pop de
 pop bc
 pop af
 ret
; end of AddLog

; *** ViewLog
; Log id in reg a
ViewLog:
 push af
 push bc
 push de
 push hl
 ld c,a
 ld a,(logs_curid)
 cp c
 jp c,vl_end
 xor a
 cp c
 jp z,vl_end
 sla c
 dec c
 dec c
 ld b,0
 ld hl,logs_ids
 add hl,bc
 ld c,(hl)
 inc hl
 ld b,(hl)
 inc hl
 ld e,(hl)
 inc hl
 ld d,(hl)
 ld a,e
 sub c
 ld c,a
 ld a,d
 sbc a,b
 ld b,a
 ld a,EOL
 ld hl,logs
 add hl,de
 cpdr
 inc hl
 inc hl
 ld d,h
 ld e,l
;
 call reset_lcd
 ld b,%00001100         ; This sets cursor and cursor blinking off
 call set_lcd
;
 call vl_show
vl_start:
 ld a,Enter
 ld (key_pressed),a
 ld a,$20
 ld (key_delay),a
 ld bc,(RepeatDelay)
 ld (key_repeatdelay),bc
 ld bc,(RepeatRate)
 ld (key_repeatrate),bc
 ld a,$ff
 ld (key_rset),a
;
vl_loop:
 call key_getkey
; Now test which key was pressed
 cp Enter
 jp z,vl_end
 cp CK1
 jp z,vl_rollup
 cp CK3
 jp z,vl_rolldown
 jp vl_loop
;
vl_rollup:
 ld a,d
 cp h
 jr nz,vlu_dec
 ld a,e
 cp l
 jr nz,vlu_dec
 call vl_show
 ld a,CK1
 jp vl_loop
vlu_dec:
 ld a,20
vlu_dec20loop:
 dec hl
 dec a
 jr nz,vlu_dec20loop;
 call vl_show
 ld a,CK1
 jp vl_loop
;
vl_rolldown:
 push hl
 ld b,20
vld_inc20loop:
 inc hl
 ld a,(hl)
 cp EOL
 jr z,vld_nroll
 cp EOLOG
 jr z,vld_nroll
 dec b
 jr nz,vld_inc20loop;
 call vl_show
 ld a,CK3
 pop bc
 jp vl_loop
vld_nroll:
 ld a,CK3
 pop hl
 jp vl_loop
;
vl_show:
 push hl
 ld c,20
 ld a,Line1
 call setDDRAMa
 ld b,0
 call strn2lcd
 ld a,NOEOL
 cp c
 jr nz,vl_eolog
 push hl
 ld c,20
 ld a,Line2
 call setDDRAMa
 ld b,1
 call strn2lcd
 ld a,NOEOL
 cp c
 jr nz,vl_eolog
 pop hl
 pop hl
 ret
vl_eolog:
 xor a
 cp b
 jr z,vle_tend
 ld a,Line2
 call setDDRAMa
 ld hl,s_clearline
 call str2lcd
 pop hl 
 ld a,Line2
 call setDDRAMa
 call strn2lcd
 pop hl
 ret
vle_tend:
 call clear_lcd
 ld a,Line1
 call setDDRAMa
 pop hl
 push hl
 call strn2lcd
 ld a,Line2
 call setDDRAMa
 ld hl,s_clearline
 call str2lcd
 pop hl
 ret
;
vl_end:
 pop hl
 pop de
 pop bc
 pop af
 ret
; end of ViewLog

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
; Address $c000-$dfff also contains a 8kb RAM..
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
 srl a
 srl a
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
 srl a
 srl a
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
 srl a
 srl a
 srl a
 srl a
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
 srl a
 srl a
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
 ld hl,$0c00
error_delay_loop:
 nop
 dec l
 jr nc,error_delay_loop
 dec h
 jr nc,error_delay_loop
no_error_in_memory:
; Now we set up the stack pointer
 ld sp,StackPointerOrigin
; Start by  initializing and blinking the default 7segments
 ld a,$ff
 out (SSeg1),a
 out (SSeg2),a
 out (SSeg3),a
 out (SSeg4),a
; Also 'reset' the keyboard, just for safe
 out (KeyS),a
; Let's do some blinking
 ld de,500      ; 500ms
 call Delayms   ; Wait a bit when the 7segments are off
 ld a,0
 out (SSeg1),a
 out (SSeg2),a
 out (SSeg3),a
 out (SSeg4),a
 ld de,500
 call Delayms   ; Wait a bit when the 7segments are on
 ld a,$ff       ; Then reset the 7segments off
 out (SSeg1),a
 out (SSeg2),a
 out (SSeg3),a
 out (SSeg4),a
; Now the memory error message in the LEDs should have been seeable
; enough long time so reset the LEDs also
 leds_load($ff)
; Set up timer which creates NMI interrupt for system timing
; and clear uptime counter
; Set the NMI to happen every 1secs
; (Counter 0 clock must be 4MHz)
; Counter 0
 ld a,%00110111
 out (CounterC),a
 ld a,$00
 out (Counter0),a
 ld a,$01
 out (Counter0),a
; Counter 1
 ld a,%01110111
 out (CounterC),a
 ld a,$04
 out (Counter1),a
 ld a,$00
 out (Counter1),a
; Counter 2
 ld a,%10110111
 out (CounterC),a
 ld a,$96
 out (Counter2),a
 ld a,$99
 out (Counter2),a
; Uptime counter
 ld hl,0
 ld (uptime),hl
 ld (uptime+2),hl
 ld (uptime+4),hl
; Set flash to page 0
 xor a
 out (flashcom),a
; Reset logs and create system's default log
 xor a
 ld (logs_curid),a
 ld (logs_status),a
 ld hl,0
 ld (logs_cur),hl
 ld (logs_ids),hl
 ld hl,1024     ; 51,2 lines long, 20 characters per line, 1024bytes
 call CreateLog ; No checking if the log was even created
 ld (SystemLogId),a
 ld a,(SystemLogId)
 ld hl,s_SysFirst
 call AddLog
 ld hl,s_SysStartUp
 call AddLog
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
 ld (GT0),a
 ld (GT1),a
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
; The ethernet adapter is not enabled here yet
; Also init network and enable NIC
 ld a,(SystemLogId)
 ld hl,s_SysProbeNIC
 call AddLog
; call ethInit
 ld a,$69
 ld hl,s_SysNoNIC
 cp $69                 ; $69 should be NoNIC
 jr z,sup_nonicfound
 call net_init
 ld hl,s_SysNICfound
sup_nonicfound:
 ld a,(SystemLogId)
 call AddLog
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
 ld a,(SystemLogId)
 ld hl,s_SysModeS
 call AddLog
 ld a,none
 ld (key_pressed),a
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
 ld a,FastKeyDelay
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
 cp CK2
 jp nz,mcp_nuptime
 ld hl,s_viewuptime
 ld c,CK2
 jp mcp_str2lcd
mcp_nuptime:
 cp CK3
 jp nz,mcp_nlogs
 ld hl,s_viewlogs
 ld c,CK3
 jp mcp_str2lcd
mcp_nlogs:
;
 ld a,Line2
 call setDDRAMa
 ld b,'>'
 call char2lcd
 ld hl,s_clearline
 ld c,19
 call strn2lcd
 ld a,Line2+1
 call setDDRAMa
 ld c,none
 jp mcp_comloop
;
mcp_str2lcd:
 ex de,hl
 ld a,Line2
 call setDDRAMa
 ld hl,s_clearline
 call str2lcd
 ld a,Line2
 call setDDRAMa
 ex de,hl
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
 cp CK2
 jp z,mcp_viewuptime
 cp CK3
 jp z,mcp_viewlogs
 jp mcp_comloop
; ***
mcp_help:
 ld hl,s_helptext
 call help_read
 jp mcp_start
mcp_hexedit:
 call hexedit
 jp mcp_start
mcp_viewuptime:
 call ViewUptime
 jp mcp_start
mcp_viewlogs:
 call ViewLogs
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
he_call_jumpcmd:
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

; *** ViewLogs
ViewLogs:
 push af
 push hl
 push bc
 ld a,FastKeyDelay
 ld (key_delay),a
 call clear_lcd
 ld b,%00001100         ; This sets cursor and cursor blinking off
 call set_lcd
 ld a,(logs_curid)
 cp 0
 jp nz,vil_logsexist
 ld hl,s_nologs
 call str2lcd
vil_nwait:
 call key_getkey
 cp Enter
 jp nz,vil_nwait
 jp vil_end
vil_logsexist:
 ld a,Line1
 call setDDRAMa
 ld hl,s_viewslog
 call str2lcd
 ld a,Line2
 call setDDRAMa
 ld hl,s_lognumber
 call str2lcd
 ld c,1
vil_selectloop:
 ld a,Line2+6
 call setDDRAMa
 ld b,'0'
 ld a,c
 add a,b
 ld b,a
 call char2lcd
 call key_getkey
 cp CK1
 jp nz,vil_nCK1
 dec c
 jp nz,vil_selectloop
 inc c
 jp vil_selectloop
vil_nCK1:
 cp CK3
 jp nz,vil_nCK3
 ld a,(logs_curid)
 cp c
 jp z,vil_selectloop
 inc c
 jp vil_selectloop
vil_nCK3:
 cp CK5
 jp nz,vil_nCK5
 jp vil_end
vil_nCK5:
 cp Enter
 jp nz,vil_selectloop
 ld a,c
 call ViewLog
 call clear_lcd
 jp vil_logsexist
vil_end:
 pop bc
 pop hl
 pop af
 ret
; end of ViewLogs

; *** ViewUptime
ViewUptime:
 push af
 push hl
 push bc
 call clear_lcd
 ld b,%00001100         ; This sets cursor and cursor blinking off
 call set_lcd
 ld a,Line1
 call setDDRAMa
 ld hl,s_uptime1
 call str2lcd
vu_wait:
 ld a,Line2
 call setDDRAMa
 ld a,(uptime+5)
 call byte2lcd
 ld a,(uptime+4)
 call byte2lcd
 ld a,(uptime+3)
 call byte2lcd
 ld b,'d'
 call char2lcd
 ld a,(uptime+2)
 call byte2lcd
 ld b,'h'
 call char2lcd
 ld a,(uptime+1)
 call byte2lcd
 ld b,'m'
 call char2lcd
 ld a,(uptime+0)
 call byte2lcd
 ld b,'s'
 call char2lcd
 call key_scan
 ld hl,key_pressed
 cp (hl)
 jp z,vu_wait
 ld (key_pressed),a
 cp Enter
 jp nz,vu_wait
 pop bc
 pop hl
 pop af
 ret
; end of ViewUptime

; *** System
System:
 push af
 push bc
 push de
 push hl

 pop hl
 pop de
 pop bc
 pop af
 ret
; end of System

; *** HandleNMI
HandleNMI:
 di
 push af
 push bc
 push hl
 ld a,%10110001
 out (CounterC),a
 ld a,$97
 out (Counter2),a
 ld a,$99
 out (Counter2),a
 ld a,(uptime)
 add a,1
 daa
 ld (uptime),a
 cp $60
 jp nz,hn_incupend
 xor a
 ld (uptime),a
 ld a,(uptime+1)
 add a,1
 daa
 ld (uptime+1),a
 cp $60
 jp nz,hn_incupend
 xor a
 ld (uptime+1),a
 ld a,(uptime+2)
 add a,1
 daa
 ld (uptime+2),a
 cp $24
 jp nz,hn_incupend
 xor a
 ld (uptime+2),a
 ld a,(uptime+3)
 add a,1
 daa
 ld (uptime+3),a
 cp $00
 jp nz,hn_incupend
 ld a,(uptime+4)
 add a,1
 daa
 ld (uptime+4),a
 cp $00
 jp nz,hn_incupend
 ld a,(uptime+5)
 add a,1
 daa
 ld (uptime+5),a
hn_incupend:
;
 led_toggle(%00010000)
 pop hl
 pop bc
 pop af
 ei
 retn
; end of HandleNMI

;**************************************************************
; Misc data, example character strings
s_OSstring      .db "Z80 WestOS, by Duge",EOL
s_version       .db "version b0.70",EOL
s_halted        .db "CPU halted.",EOL
s_defprompt     .db "Input  command:",EOL
s_help          .db ">help",EOL
s_hexedit       .db ">hexedit",EOL
s_viewlogs      .db ">view logs",EOL
s_viewuptime    .db ">view uptime",EOL
s_clearline     .db "                    ",EOL
s_endof         .db "*-------end--------*",EOL
s_enter         .db "Press Enter.........",EOL
s_helptext      .db "#Use CK1 and CK3 to ",EOL
                .db "#roll up and down   ",EOL
                .db "CK0: Help           ",EOL
                .db "Show this help      ",EOL
                .db "CK1: Hexedit        ",EOL
                .db "Memory hex editor   ",EOL
                .db "Also for I/O-usage  ",EOL
                .db "CK2: View uptime    ",EOL
                .db "CK3: View logs      ",EOL
                .db "Shift:              ",EOL
                .db "Usage of Shift is   ",EOL
                .db "marked with ^X,     ",EOL
                .db "where X is some key ",EOL
                .db "#Press Enter to exit",EOL
                .db EOL
s_he_help       .db "#Up:CK1 Down:CK3    ",EOL
                .db "Enter: Exit hexedit ",EOL
                .db "CK0: Choose address ",EOL
                .db "CK2: I/O output     ",EOL
                .db "^CK2: Jump to n     ",EOL
                .db "CK4: I/O input      ",EOL
                .db "^CK4: Call to n     ",EOL
                .db "After this command  ",EOL
                .db "the value read from ",EOL
                .db "given port is seen  ",EOL
                .db "in 7segments as hex.",EOL
                .db "CK1: Roll memory up ",EOL
                .db "^CK1: Up by 4       ",EOL
                .db "CK3: Roll mem. down ",EOL
                .db "^CK3: Down by 4     ",EOL
                .db "CK5: Undo           ",EOL
                .db "Undo in most cases. ",EOL
                .db "0-F: Change memory  ",EOL
                .db "^CK0: Help          ",EOL
                .db "#Press Enter to exit",EOL
                .db EOL
s_he_string     .db "WestOS Hexedit v0.25",EOL
s_inputaddress  .db "Give address:",EOL
s_inputword     .db "Give word:",EOL
s_inputbyte     .db "Give byte:",EOL
s_inputioaddr   .db "Give I/O-address:",EOL
s_inputdelay    .db "Give delay:",EOL
s_uptime1       .db "System uptime:",EOL
s_uptime2       .db "00000d00h00m00s",EOL
s_lognumber     .db ">Log #",EOL
s_nologs        .db "No logs created.",EOL
s_viewslog      .db "View log:",EOL
s_SysFirst      .db "Z80 WestOS b0.70 by Duge.",LOGSP,EOL
s_SysStartUp    .db "Starting up..",LOGSP,EOL
s_SysProbeNIC   .db "Probing for NIC @ISA..",LOGSP,EOL
s_SysNICfound   .db "NIC found, see Net log(1).",LOGSP,EOL
s_SysNoNIC      .db "No NIC found.",LOGSP,EOL
s_SysModeS      .db "Going to start up-mode..",LOGSP,EOL
s_SysHalt       .db "CPU halted.",LOGSP,EOL
s_SysHaltWake   .db "CPU waked up.",LOGSP,EOL
hextolcd        .db '0','1','2','3','4','5','6','7','8','9'
                .db 'A','B','C','D','E','F'
hexto7segment   .db %10000001,%10110111,%11000010,%10010010
                .db %10110100,%10011000,%10001000,%10110011
                .db %10000000,%10010000,%10100000,%10001100
                .db %11001001,%10000110,%11001000,%11101000
;**************************************************************

#include "drivers.asm"
#include "flash.asm"

.end

