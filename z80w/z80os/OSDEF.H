;**************************************************************
;
; Defines & equs & routine addresses
;
;**************************************************************

#define equ .equ

#define CPU_AT_4MHZ

; Macros for using the LEDs
#define led_reset(reset) ld a,(LEDs_state)\ or ~reset\ out (LEDs),a\ ld (LEDs_state),a
#define led_set(set) ld a,(LEDs_state)\ and ~set\ out (LEDs),a\ ld (LEDs_state),a
#define led_toggle(toggle) ld a,(LEDs_state)\ xor toggle\ out (LEDs),a\ ld (LEDs_state),a
#define leds_load(load) ld a,load\ out (LEDs),a\ ld (LEDs_state),a

; Operating system reserves memory between $ea00-$ffff

; Stack Pointer start value,
; it reserves 256bytes ($ff00-$ffff)
StackPointerOrigin: equ $fff0
; Variables
SRM             equ $ea00       ; Here are OS's variables
UMO             equ $e000       ; Here starts the 'User's Memory' (1KB)
; Temporary values
T0              equ SRM+0       ; These values are bytes
T1              equ SRM+1
T2              equ SRM+2
T3              equ SRM+3
GT0             equ SRM+4
GT1             equ SRM+5
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
; Log id's and addresses
logs_curid      equ SRM+60      ;byte
logs_status     equ SRM+61      ;byte
logs_cur        equ SRM+62      ;word
logs_ids        equ SRM+64      ;9words=18bytes
;
SystemLogId     equ SRM+127     ;byte
; Used by network
network         equ SRM+128     ;reserves 256bytes
; Uptime counter               
uptime          equ SRM+384     ;6bytes
; State of LEDs
LEDs_state      equ SRM+390
; For logs
logs            equ SRM+640     ;reserves 4KB

;**************************************************************
; LEDs, 7segments and keyboard io-addresses
SSeg1           equ $01
SSeg2           equ $02
SSeg3           equ $03
SSeg4           equ $04
KeyS            equ $05
KeyR            equ $06
LEDs            equ $07
; 8255 PIO -chip registers
;  LCD-display
PortA           equ $20
PortB           equ $21
PortC           equ $22
PIOCtrl         equ $23
LCDd            equ PortB
LCDi            equ PortC
; Timer
Counter0        equ $a0
Counter1        equ $a1
Counter2        equ $a2
CounterC        equ $a3
; Other IOs
ethcom          equ $c0
flashcom        equ $c1
ETHBASE         equ $e0


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

; defines
#define Line1 $00
#define Line2 $40
#define EOL $17                 ; End Of Line, used with strings
#define EOLOG $18               ; End Of LOG
#define NOEOL $19
#define LOGSP $ff
#define log_adding $01          ; This flag is set in log_status when there is adding in progress
#define MAX_LOGS 8
#define LOG_MEMORY_SIZE 4096

; Next delay-values are relative to speed of CPU
#ifdef CPU_AT_2MHZ
_RepeatDelay    equ $0aff       ; default value
_RepeatRate     equ $00ff       ; default value
FastKeyDelay    equ $40
NormalKeyDelay  equ $a0
#endif
#ifdef CPU_AT_4MHZ
_RepeatDelay    equ $0fff       ; default value
_RepeatRate     equ $01ff       ; default value
FastKeyDelay    equ $80
NormalKeyDelay  equ $f0
#endif
#ifdef CPU_AT_8MHZ
_RepeatDelay    equ $1fff       ; default value
_RepeatRate     equ $02ff       ; default value
FastKeyDelay    equ $c0
NormalKeyDelay  equ $f0
#endif

LCD_delay       equ $0002       ; Delay after actions when using
                                ; LCD for 2ms

ErrorMesg       equ 3000        ; Show error for 3secs
NormalMesg      equ 1000        ; Show normal messages for 1,5secs
FastMesg        equ 1000        ; Show fast messages for 1sec
LongMesg        equ 4000        ; Show long message for 4secs
LLongMesg       equ 7000        ; Show really long message for 7secs

; *****************
; Routine addresses
#ifndef OS_FILE
DelayBC         equ $0040
DelayDE         equ $0049
DelayHL         equ $0052
HALT            equ $006b
n_as_7seg       equ $009e
n_to_7seg       equ $00b1
b_to_7seg       equ $00cb
byte2lcd        equ $00fe
set_lcd         equ $0125
char2lcd        equ $013f
reset_lcd       equ $015b
clear_lcd       equ $017e
str2lcd         equ $0186
strn2lcd        equ $0197
strd2lcd        equ $01b3
setDDRAMa       equ $01c7
key_scan        equ $01d0
key_testshift   equ $026a
key_getkey      equ $0277
key_getbyte     equ $030a
key_getaddress  equ $03e1
key_getword     equ $03f7
Delayms         equ $0554
CreateLog       equ $0571
AddLog          equ $05bd
ViewLog         equ $0640
#endif

; ************
; "Next level"
; (Network and such)

; These macros makes easier to use the NIC
; by adding the base address of NIC to the
; relative NIC register address
;#define einb(address) ld a,(ethbase)\ add a,address\ ld c,a\ in a,(c)
;#define eoutb(address) ex af,af'\ ld a,(ethbase)\ add a,address\ ld c,a\ ex af,af'\ out (c),a

; network variables
ETHM            equ SRM+128     ;256bytes (must be equ to network
                                ;in osXXX.asm)
;
ethdetect       equ ETHM+1      ;byte
ethtmp          equ ETHM+2      ;byte
ethsaprom       equ ETHM+3      ;32 bytes
ethhwaddr       equ ETHM+35      ;6 bytes
ethpiomode      equ ETHM+41     ;byte
ethaddr         equ ETHM+42     ;byte
ethirqreg       equ ETHM+43     ;byte
ethwrdlen       equ ETHM+44     ;byte
ethT0           equ ETHM+45     ;byte
ethT1           equ ETHM+46     ;byte
ethT2           equ ETHM+47     ;byte
ethT3           equ ETHM+48     ;byte
etxStartPage    equ ETHM+49     ;byte
erxStartPage    equ ETHM+50     ;byte
ethStopPage     equ ETHM+51     ;byte
ethCurrentPage  equ ETHM+52     ;byte
NetLogId        equ ETHM+53     ;byte
; Jump-table
ejProbe         equ ETHM+60     ;word
ejReset         equ ETHM+62     ;word
ejOpen          equ ETHM+64     ;word
ejEnable        equ ETHM+66     ;word
ejDisable       equ ETHM+68     ;word
ejInterrupt     equ ETHM+70     ;word
ejSend          equ ETHM+72     ;word
; Information for sending and receiving packets
ethDataAddr     equ ETHM+80     ;word
ethDataLen      equ ETHM+82     ;word
ethDataPage     equ ETHM+84     ;word
; Error counters
ethRxFrameErrs  equ ETHM+100    ;word frame errors
ethRxCrcErrs    equ ETHM+102    ;word CRC errors
ethRxMissedErrs equ ETHM+104    ;word missed-errors
ethTxCarrErrs   equ ETHM+106    ;word tx carrier errors
ethTxHBErrs     equ ETHM+108    ;word tx heartbeat errors
ethTxWindow     equ ETHM+110    ;word tx window errors
ethRxOverErrs   equ ETHM+112    ;word rx overrun errors
ethRxErrs       equ ETHM+114    ;word rx errors
ethRxFifoErrs   equ ETHM+116    ;word rx fifo errors
ethRxLenErrs    equ ETHM+118    ;word rx lenght errors
ethRxPackets    equ ETHM+120    ;dword rx packets counter
ethTxPackets    equ ETHM+124    ;dword tx packets counter
ethRxBytes      equ ETHM+128    ;dword rx bytes
ethTxBytes      equ ETHM+132    ;dword tx bytes
ethRxDropped    equ ETHM+136    ;word rx packets dropped
; Structures (ex. headers) and such
; receive packet header
#define pkthdr_size 4
pkthdr          equ ETHM+150    ;2 bytes+1 word=4 bytes
pkthdr_stat     equ ETHM+150    ;byte
pkthdr_next     equ ETHM+151    ;byte
pkthdr_count    equ ETHM+152    ;word
; Ing:s :)
#define XXXing 17
ethRxing        equ ETHM+160    ;byte
ethTxing        equ ETHM+161    ;byte

; Temporary values
NT0             equ ETHM+252    ;byte
NT1             equ ETHM+253    ;byte
NT2             equ ETHM+254    ;byte
NT3             equ ETHM+255    ;byte
