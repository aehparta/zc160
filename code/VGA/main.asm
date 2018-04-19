;******************************************************************************
;
;
; The ZC160: GPU OS
;
;
;
; Authors: Antti Partanen, <aehparta@iki.fi>
;
;******************************************************************************


.include "system.def"


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
    ld a, 100
delay_ms1:              ; 1ms delay
    nop
    nop                 ; 8 clocks / 1us
    nop
    nop                 ; 8 clocks / 1us
    nop
    nop                 ; 8 clocks / 1us
    nop
    nop                 ; 8 clocks / 1us
    nop
    nop                 ; 8 clocks / 1us
    nop
    nop                 ; 8 clocks / 1us
    nop
    nop                 ; 8 clocks / 1us
    nop
    nop                 ; 8 clocks / 1us
    nop                 ; 4 clocks / 0.5us
    dec a               ; 4 clocks / 0.5us
    jp nz, delay_ms1    ; 10 clocks / 1.25us
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


;******************************************************************************
; calculate pixel address, mono mode
; changes: a, hl, de, bc
; params:
;   de: x-coordinate
;   hl: y-coordinate
; return:
;   a: bit mask of the pixel inside byte
;   b: zero
;   c: bit number inside the byte
;   hl: pixel address
mono_pixel_address:
    ; multiply y by 64
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ; add x
    ld a, e ; save lower 3 bits to a
    ; divide by 8
    srl d
    rr e
    srl e
    srl e
    ; add x value
    add hl, de
    ; add video ram start address
    ld de, VRAM_START
    add hl, de
    ; get bit mask inside byte
    ex de, hl
    ld hl, BIT_MASK_LOOKUP
    ld b, 0
    and $07
    ld c, a
    add hl, bc
    ld a, (hl)
    ex de, hl
    ret


;******************************************************************************
; draw single pixel, mono mode
mono_draw_pixel:
    ld de, (DRAW_X)
    ld hl, (DRAW_Y)
    call mono_pixel_address
    or (hl)
    ld (hl), a
    ret


;******************************************************************************
; erase single pixel, mono mode
mono_erase_pixel:
    ld de, (DRAW_X)
    ld hl, (DRAW_Y)
    call mono_pixel_address
    cpl
    and (hl)
    ld (hl), a
    ret


;******************************************************************************
; toggle single pixel, mono mode
mono_toggle_pixel:
    ld de, (DRAW_X)
    ld hl, (DRAW_Y)
    call mono_pixel_address
    xor (hl)
    ld (hl), a
    ret


;******************************************************************************
; skeleton of draw horizontal line, mono mode
; changes: a, hl, de, bc
mono_draw_line_horizontal_skeleton:
    call mono_pixel_address
    ld bc, (DRAW_W)
    cp 1
    jr z, _mono_draw_line_horizontal_first_bits_skip
_mono_draw_line_horizontal_first_bits:
    ld e, a
    rlca
    jr c, _mono_draw_line_horizontal_first_bits_done
    or e
    dec c
    jp po, _mono_draw_line_horizontal_first_bits
    dec b
    jp po, _mono_draw_line_horizontal_first_bits
    inc bc
_mono_draw_line_horizontal_first_bits_done:
    dec bc
    ld (hl), e
    inc hl
_mono_draw_line_horizontal_first_bits_skip:
    ld a, c
    srl b
    rr c
    srl c
    srl c
    ld b, c
    jp z, _mono_draw_line_horizontal_full_bytes_done
    ld e, $ff
_mono_draw_line_horizontal_full_bytes:
    ld (hl), e
    inc hl
    djnz _mono_draw_line_horizontal_full_bytes
_mono_draw_line_horizontal_full_bytes_done:
    and $07
    ret z
    dec a
    ld b, 0
    ld c, a
    ld a, (hl)
    ex de, hl
    ld hl, FILL_BITS_END_LOOKUP
    add hl, bc
    or (hl)
    ld (de), a
    ret


;******************************************************************************
; draw horizontal line, mono mode
; changes: a, hl, de, bc
mono_draw_line_horizontal:
    ld de, (DRAW_X)
    ld hl, (DRAW_Y)
;     call mono_draw_line_horizontal_skeleton
;     ld hl, (DRAW_W)
;     dec h
;     ret nz
;     xor a
;     ld (DRAW_W), a
;     ld de, (DRAW_X)
;     add hl, de
;     ex de, hl
;     ld hl, (DRAW_Y)
    jp mono_draw_line_horizontal_skeleton


;******************************************************************************
; fill rectangle, mono mode
; changes: a, hl, de, bc
mono_fill_rectangle:
    ld hl, (DRAW_Y)
_mono_fill_rectangle_loop:
    push hl
    ld de, (DRAW_X)
    call mono_draw_line_horizontal_skeleton
    pop hl
    inc hl
    dec (ix + DRAW_I_H)
    jp nz, _mono_fill_rectangle_loop
;     djnz _mono_fill_rectangle_loop
_mono_fill_rectangle_done:
    ret


;******************************************************************************
; draw char and increase cursor position, mono mode
; a = character
mono_draw_char:
    push bc
    push de
    push hl
    ; check for newline character
    cp LF
    jp z, _mono_draw_newline
    ; get y position
    ld hl, (CURSOR_Y)
    ld h, 0
    ; multiply by 8
    add hl, hl
    add hl, hl
    add hl, hl
    ; multiply by 64
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ; get x position
    ld bc, (CURSOR_X)
    ld b, 0
    ; add x to y to get character position
    add hl, bc
    ; add video ram start
    ld bc, VRAM_START
    add hl, bc
    ; save hl to bc
    ld b, h
    ld c, l
    ; get character data position
    ld h, 0
    ld l, a
    ; multiply by 8
    add hl, hl
    add hl, hl
    add hl, hl
    ; add font pointer to get character data position
    ld de, SYSFONT
    add hl, de
    ld d, h
    ld e, l
    ld h, b
    ld l, c
    ; draw character
    ld bc, 64
    ; draw 8 bytes from the char
    ; byte 1
    ld a, (de)
    ld (hl), a
    inc de
    add hl, bc
    ; byte 2
    ld a, (de)
    ld (hl), a
    inc de
    add hl, bc
    ; byte 3
    ld a, (de)
    ld (hl), a
    inc de
    add hl, bc
    ; byte 4
    ld a, (de)
    ld (hl), a
    inc de
    add hl, bc
    ; byte 5
    ld a, (de)
    ld (hl), a
    inc de
    add hl, bc
    ; byte 6
    ld a, (de)
    ld (hl), a
    inc de
    add hl, bc
    ; byte 7
    ld a, (de)
    ld (hl), a
    inc de
    add hl, bc
    ; byte 8
    ld a, (de)
    ld (hl), a
    ; increase cursor position
    ld a, (CURSOR_X)
    inc a
    cp 64
    jp m, _mono_draw_char_no_newline
_mono_draw_newline:
    ld a, (CURSOR_Y)
    inc a
    cp 48
    jp m, _mono_draw_char_no_scroll
    ; scroll screen
    ld de, VRAM_START
    ld hl, VRAM_START + 8 * 64
    ld bc, 64 * 384 - 8 * 64
    ldir
    ld a, 0
    ld hl, VRAM_START + 64 * 384 - 8 * 64
    ld (hl), a
    ld de, VRAM_START + 64 * 384 - 8 * 64 + 1
    ld bc, 8 * 64 - 1
    ldir
_mono_draw_char_no_scroll:
    ld a, 0
_mono_draw_char_no_newline:
    ld (CURSOR_X), a
    pop hl
    pop de
    pop bc
    ret

;******************************************************************************
; draw text, mono mode
_mono_put_string_lf:
    ld a, (CURSOR_Y)
    cp 47
    jr z, _mono_put_string_lf_scroll
    inc a
    ld (CURSOR_Y), a
    jp _mono_put_string_cr
_mono_put_string_lf_scroll:
    memcpy VRAM_START, VRAM_START + 8 * 64, 64 * 384 - 8 * 64
    memset VRAM_START + 64 * 384 - 8 * 64, 0, 8 * 64
_mono_put_string_cr:
    xor a
    ld (CURSOR_X), a
    jp _mono_put_string_loop
_mono_put_string_eol:
    pop hl
    pop de
    pop bc
    ret
; actual draw routine start
mono_put_string:
    push bc
    push de
    push hl
    ld bc, (TEXT_POINTER)
    push bc
_mono_put_string_loop:
    pop bc
    ld a, (bc)
    inc bc
    cp EOL
    jr z, _mono_put_string_eol
    push bc
    cp LF
    jr z, _mono_put_string_lf
    cp CR
    jr z, _mono_put_string_cr
    ; resolve character data position
    ld h, 0
    ld l, a
    ; multiply by 8
    add hl, hl
    add hl, hl
    add hl, hl
    ; add font pointer to get character data position
    ld de, SYSFONT
    add hl, de
    ex de, hl
    ; cursor position
    ld hl, (CURSOR_Y)
    ld h, 0
    ; multiply by 8
    add hl, hl
    add hl, hl
    add hl, hl
    ; multiply by 64
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ; get x position
    ld a, (CURSOR_X)
    ld c, a
    inc a
    ld (CURSOR_X), a
    ld b, 0
    add hl, bc
    ld bc, VRAM_START
    add hl, bc
    ; draw character
    ld bc, 64
    ld a, (de)
    ld (hl), a
    inc de
    add hl, bc
    ld a, (de)
    ld (hl), a
    inc de
    add hl, bc
    ld a, (de)
    ld (hl), a
    inc de
    add hl, bc
    ld a, (de)
    ld (hl), a
    inc de
    add hl, bc
    ld a, (de)
    ld (hl), a
    inc de
    add hl, bc
    ld a, (de)
    ld (hl), a
    inc de
    add hl, bc
    ld a, (de)
    ld (hl), a
    inc de
    add hl, bc
    ld a, (de)
    ld (hl), a
    jp _mono_put_string_loop

;******************************************************************************
; Setup and start the ZC160 GPU OS.
reset:
; setup stack pointer
    ld sp, OS_STACK
; green foreground, blank off, mode 0
    ld a, $4c
    out (IO_LATCH), a
; reset to start of video ram
    ld a, $00
    out (IO_VRAM_BANK), a
; clear screen, first 24 kB (mono display)
;     profile_start
    memset VRAM_START, 0, $6000
;     profile_end
; ix points to x-coordinate as default
    ld ix, DRAW_X

; position cursor to bottom as default
    ld bc, 0
    ld (CURSOR_X), bc
    ld bc, 47
    ld (CURSOR_Y), bc

; line draw test
;     ld bc, 0
;     ld (DRAW_X), bc
;     ld bc, 20
;     ld (DRAW_Y), bc
;     ld bc, $ff
;     ld (DRAW_W), bc
;     call mono_draw_line_horizontal
;     ld bc, 21
;     ld (DRAW_Y), bc
;     ld bc, $100
;     ld (DRAW_W), bc
;     call mono_draw_line_horizontal
;     ld bc, 22
;     ld (DRAW_Y), bc
;     ld bc, $101
;     ld (DRAW_W), bc
;     call mono_draw_line_horizontal

;     ld bc, 4
;     ld (DRAW_X), bc
;     ld bc, 40
;     ld (DRAW_Y), bc
;     ld bc, $ff
;     ld (DRAW_W), bc
;     call mono_draw_line_horizontal
;     ld bc, 41
;     ld (DRAW_Y), bc
;     ld bc, $100
;     ld (DRAW_W), bc
;     call mono_draw_line_horizontal
;     ld bc, 42
;     ld (DRAW_Y), bc
;     ld bc, $101
;     ld (DRAW_W), bc
;     call mono_draw_line_horizontal

;     halt

;     ld bc, 0
;     ld (DRAW_X), bc
;     ld bc, 384
; loopping:
;     ld (DRAW_W), bc
;     dec bc
;     ld (DRAW_Y), bc
;     push bc
;     profile_start
;     call mono_draw_line_horizontal
;     profile_end
;     pop bc
;     ld a, b
;     or c
;     jp nz, loopping
;     halt

;     ld bc, 4
;     ld (DRAW_X), bc
;     ld bc, 60
;     ld (DRAW_Y), bc
;     ld bc, 8
;     ld (DRAW_W), bc
;     profile_start
;     call mono_draw_line_horizontal
;     profile_end

;     ld bc, 4
;     ld (DRAW_X), bc
;     ld bc, 70
;     ld (DRAW_Y), bc
;     ld bc, 3
;     ld (DRAW_W), bc
;     profile_start
;     call mono_draw_line_horizontal
;     profile_end

; draw zc160 logo
;     profile_start
draw_logo:
    ld bc, 8
    ld (DRAW_W), bc
    ld (DRAW_H), bc
    ld hl, LOGO_TOP
    ld bc, LOGO_DATA
    push bc
    ;
    ld a, 17
_draw_logo_loop:
    ld (TEMP02), a
    ld de, LOGO_LEFT
    ld a, 4
_draw_logo_line_loop:
    ld (TEMP01), a
    pop bc
    ld a, (bc)
    inc bc
    push bc
    ld b, 8
_draw_logo_draw_blocks_loop:
    ld (DRAW_X), de
    ld (DRAW_Y), hl
    sla a
    jp c, _draw_logo_skip_block
    push af
    exx
    ld (ix + 6), 8
    call mono_fill_rectangle
    exx
    pop af
_draw_logo_skip_block:
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    djnz _draw_logo_draw_blocks_loop
    ld a, (TEMP01)
    dec a
    jp nz, _draw_logo_line_loop
    ld bc, 8
    add hl, bc
    ld a, (TEMP02)
    dec a
    jp nz, _draw_logo_loop
    ;
    pop bc
;     profile_end

; print bootup string
    ld bc, S_BOOTUP
    ld (TEXT_POINTER), bc
    call mono_put_string

    halt

; draw sine
    ld hl, 0
    ld (DRAW_Y), hl
    ld (DRAW_X), hl
    ld de, m_lut_sin
    ld hl, DRAW_X
    ld b, 255
test_sin:
    ld a, (de)
    cpl
    
    ld (DRAW_Y), a
    push hl
    push bc
    push de
    call mono_draw_pixel
    pop de
    pop bc
    pop hl
    inc (hl)
    inc de
    djnz test_sin

xxx:
    inc a
    and $3f
    or $40
    out (IO_LATCH), a
    ld bc, 200
    call delay_ms
    jp xxx

; halt
halt:
    halt

FILL_BITS_END_LOOKUP:       .db     $01, $03, $07, $0f, $1f, $3f, $7f

LOGO_DATA:
.db %11111111, %11110000, %00000111, %11111111
.db %11111111, %11111111, %11111111, %11111111
.db %00000001, %11000000, %00000001, %11111111
.db %11111111, %11111111, %11111111, %11111111
.db %00000001, %00000000, %00000000, %01111111
.db %11111111, %11111111, %11111111, %11111111
.db %11110001, %00000101, %00010001, %11111111
.db %11111111, %11111101, %01110101, %11111111
.db %11000111, %00000101, %00010101, %11111111
.db %11111111, %11111101, %01010101, %11111111
.db %00011111, %00000101, %00010001, %11111111
.db %11111111, %11111111, %11111111, %11111111
.db %00000001, %00000000, %00000000, %01111111
.db %11111111, %11111111, %11111111, %11111111
.db %00000001, %11000000, %00000001, %11111111
.db %11111111, %11111111, %11111111, %11111111
.db %11111111, %11110000, %00000111, %11111111

BIT_MASK_LOOKUP: .db $01, $02, $04, $08, $10, $20, $40, $80

S_BOOTUP: .db "Bootup OK.", LF, "Waiting for commands...", LF, EOL
