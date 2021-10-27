;
; Operating System for Z80 board (West 17 Designs - by Duge)
;

#define equ .equ

StackPointerOrigin: equ $ff00

; Code origin
.org $0000

; RST $00
 jp RESET ; 3bytes
 nop      
 nop
 nop
 nop      ; 5 times 1byte makes 5bytes
 halt     ; 3b+5b=8b :)
; RST $08
 nop
 nop
 nop
 nop
 nop
 nop
 nop
 halt
; RST $10
 nop
 nop
 nop
 nop
 nop
 nop
 nop
 halt
; RST $18
 nop
 nop
 nop
 nop
 nop
 nop
 nop
 halt
; RST $20
 nop
 nop
 nop
 nop
 nop
 nop
 nop
 halt
; RST $28
 nop
 nop
 nop
 nop
 nop
 nop
 nop
 halt
; RST $30
 nop
 nop
 nop
 nop
 nop
 nop
 nop
 halt
; RST $38 or /INT-signal in interrupt mode 1
 nop
 nop
 nop
 nop
 nop
 nop
 nop
 halt
; Empty space for the NMI-interrupt point
; Here are some default rutines like delays and such
; $40
DelayBC:
 dec c          ; 1byte
 jr nz,DelayBC  ; 2bytes
 dec b          ; 1byte
 jr nz,DelayBC  ; 2bytes
 ret            ; 1byte
 nop            ; 1byte
; $48
DelayDE:
 dec e          ; 1byte
 jr nz,DelayBC  ; 2bytes
 dec d          ; 1byte
 jr nz,DelayBC  ; 2bytes
 ret            ; 1byte
 nop            ; 1byte
; $50
DelayHL:
 dec l          ; 1byte
 jr nz,DelayBC  ; 2bytes
 dec h          ; 1byte
 jr nz,DelayBC  ; 2bytes
 ret            ; 1byte
 nop            ; 1byte
; $58
 nop
 nop
 nop
 nop
 nop
 nop
 nop
 nop
; $60
 nop
 nop
 nop
 nop
 nop
 nop
; This is the point where the processor goes when NMI-interrupt
; is signalled
; 0066H or $66
; retn for now, becose NMI not in use yet
 retn
 halt
 halt

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
 ld a,%10101010         ; first test pattern
 ld (de),a
 ld a,(de)
 cp %10101010
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
 ld a,%01010101         ; Second test pattern
 ld (de),a
 ld a,(de)
 cp %01010101
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
 out(0),a
 dec h
 jp nz,fill_loop0

; End of memory test
; Show the result of the test with the 8 LEDs
 ld a,b
 out (0),a
; If there was found an error from memory in the test
; then show 'EEEE'-string in the default 7segments
 cp $ff
 jr z,no_error_in_memory
 ld a,%11001000
 out (1),a
 out (2),a
 out (3),a
 out (4),a
 ld hl,$c000
error_delay_loop:
 dec l
 jr nz,error_delay_loop
 dec h
 jr nz,error_delay_loop
no_error_in_memory:

; Now we set up the stack pointer
 ld sp,StackPointerOrigin 
; Start by  initializing and blinking the default 7segments
 ld a,$ff
 out (1),a
 out (2),a
 out (3),a
 out (4),a
; Also reset the keyboard, just for safe
 out (5),a
; Let's do some blinking
 ld hl,$4000
 call DelayHL   ; Wait a bit when the 7segments are off
 ld a,0
 out (1),a
 out (2),a
 out (3),a
 out (4),a
 ld hl,$7000
 call DelayHL   ; Wait a bit when the 7segments are on
 ld a,$ff       ; Then reset the 7segments off
 out (1),a
 out (2),a
 out (3),a
 out (4),a
; Now the memory error message in the LEDs should have been seeable
; enough long time so reset the LEDs also
 ld a,%11101111 ; This pattern lights up the fourth LED for mark of
 out (0),a      ; 'power up'



; This halt is just for safe too
 halt
 
.end
