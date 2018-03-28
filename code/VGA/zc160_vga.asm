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


.include "zc160_vga.def"


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
; draw single pixel, mono mode
draw_1_pixel:
    ld a, 0
    ld bc, (DRAW_Y)
    ld de, 64 ; 512 / 8
    ld hl, VRAM_START
_draw_1_pixel_start_line_find:
    cp c
    jp nz, _draw_1_pizel_start_line_continue
    cp b
    jp z, _draw_1_pixel_start_line_found
_draw_1_pizel_start_line_continue:
    dec bc
    add hl, de
    jp _draw_1_pixel_start_line_find
_draw_1_pixel_start_line_found:
    ld bc, (DRAW_X)
    ; get pixel position in the byte
    ld a, c
    and $07
    ; divide bc by 8
    srl b
    rr c
    srl b
    rr c
    srl b
    rr c
    ; add bc to hl, hl then points to the byte where the pixel is
    add hl, bc
    ; find the bit that must change
    ld b, a
    inc b
    ld a, 1
    djnz _draw_1_pixel_bit_from_byte_find
    jp _draw_1_pixel_bit_from_byte_found
_draw_1_pixel_bit_from_byte_find:
    sla a
    djnz _draw_1_pixel_bit_from_byte_find
_draw_1_pixel_bit_from_byte_found:
    or (hl)
    ld (hl), a
    ret


;******************************************************************************
; draw horizontal line, mono mode
draw_1_line_horizontal:
    push bc
    push de
    push hl
    ld a, 0
    ld bc, (DRAW_Y)
    ld de, 64 ; 512 / 8
    ld hl, VRAM_START
_draw_1_line_horizontal_start_line_find:
    cp c
    jp nz, _draw_1_line_horizontal_start_line_continue
    cp b
    jp z, _draw_1_line_horizontal_start_line_found
_draw_1_line_horizontal_start_line_continue:
    dec bc
    add hl, de
    jp _draw_1_line_horizontal_start_line_find
_draw_1_line_horizontal_start_line_found:
    ld bc, (DRAW_X)
    ; get pixel position in the byte
    ld a, c
    and $07
    ; divide bc by 8
    srl b
    rr c
    srl b
    rr c
    srl b
    rr c
    ; add bc to hl, hl then points to the byte where the pixel is
    add hl, bc
    ;
    ; first pixel byte address found, start drawing
    ;
    ld de, (DRAW_W)
    cp $00
    jp z, _draw_1_line_horizontal_first_byte_done
    ;
    ; draw pixels from odd start byte
    ;
    ld b, a
    inc b
    ld a, 1
    djnz _draw_1_line_horizontal_start_bit_from_byte_find
    jp _draw_1_line_horizontal_start_bit_from_byte_found
_draw_1_line_horizontal_start_bit_from_byte_find:
    sla a
    djnz _draw_1_line_horizontal_start_bit_from_byte_find
_draw_1_line_horizontal_start_bit_from_byte_found:
    ld b, a
    jp _draw_1_line_horizontal_start_bit_end_from_byte_find_loop
_draw_1_line_horizontal_start_bit_end_from_byte_find:
    sla b
    jp c, _draw_1_line_horizontal_first_byte_almost_done
    ld a, c
    or b
_draw_1_line_horizontal_start_bit_end_from_byte_find_loop:
    ld c, a
    dec de
    ld a, d
    or e
    jp nz, _draw_1_line_horizontal_start_bit_end_from_byte_find
_draw_1_line_horizontal_first_byte_almost_done:
    ld a, (hl)
    or c
    ld (hl), a
    inc hl
_draw_1_line_horizontal_first_byte_done:
    ;
    ; now draw full 8 pixel wide blocks (bytes)
    ;
    ld a, e
    and $07
    ld c, a
    ; divide de by 8
    srl d
    rr e
    srl d
    rr e
    srl d
    rr e
    ;
    jp _draw_1_line_horizontal_full_bytes_start
_draw_1_line_horizontal_full_bytes_loop:
    ld (hl), $ff
    inc hl
    dec de
_draw_1_line_horizontal_full_bytes_start:
    ld a, d
    or e
    jp nz, _draw_1_line_horizontal_full_bytes_loop
    ;
    ld d, h
    ld e, l
    ld b, 0
    ld hl, FILL_BITS_LOOKUP0
    add hl, bc
    ld a, (hl)
    ld h, d
    ld l, e
    or (hl)
    ld (hl), a
    pop hl
    pop de
    pop bc
    ret

;******************************************************************************
; fill rectangle, mono mode
draw_1_fill_rectangle:
    push bc
    push de
    ld bc, (DRAW_H)
_draw_1_fill_rectangle_loop:
    ld a, b
    or c
    jp z, _draw_1_fill_rectangle_done
    call draw_1_line_horizontal
    dec bc
    ld de, (DRAW_Y)
    inc de
    ld (DRAW_Y), de
    jp _draw_1_fill_rectangle_loop
_draw_1_fill_rectangle_done:
    pop de
    pop bc
    ret


;******************************************************************************
; draw char and increase cursor position, mono mode
; a = character
draw_1_char:
    push bc
    push de
    push hl
    ; check for newline character
    cp LF
    jp z, _draw_1_newline
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
    jp m, _draw_1_char_no_newline
_draw_1_newline:
    ld a, (CURSOR_Y)
    inc a
    cp 48
    jp m, _draw_1_char_no_scroll
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
_draw_1_char_no_scroll:
    ld a, 0
_draw_1_char_no_newline:
    ld (CURSOR_X), a
    pop hl
    pop de
    pop bc
    ret

;******************************************************************************
; draw text, mono mode
draw_1_text:
    push bc
    push de
    push hl
    ld bc, (TEXT_POINTER)
    push bc
_draw_1_text_loop:
    pop bc
    ld a, (bc)
    inc bc
    cp EOL
    jp z, _draw_1_text_eol
    push bc
    cp LF
    jp z, _draw_1_text_lf
    cp CR
    jp z, _draw_1_text_cr
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
    jp _draw_1_text_loop
_draw_1_text_lf:
    ld a, (CURSOR_Y)
    cp 47
    jp z, _draw_1_text_lf_scroll
    inc a
    ld (CURSOR_Y), a
    jp _draw_1_text_cr
_draw_1_text_lf_scroll:
    memcpy VRAM_START, VRAM_START + 8 * 64, 64 * 384 - 8 * 64
    memset VRAM_START + 64 * 384 - 8 * 64, 0, 8 * 64
_draw_1_text_cr:
    xor a
    ld (CURSOR_X), a
    jp _draw_1_text_loop
_draw_1_text_eol:
    pop hl
    pop de
    pop bc
    ret

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
    profile_start
    memset VRAM_START, 0, $6000
    profile_end

; position cursor to bottom
    ld bc, 0
    ld (CURSOR_X), bc
    ld bc, 47
    ld (CURSOR_Y), bc

; draw zc160 logo
    profile_start
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
    call draw_1_fill_rectangle
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
    profile_end

; draw text
    ld a, 0
    ld (CURSOR_X), a
    ld a, 45
    ld (CURSOR_Y), a
    ld bc, S_TEST
    ld (TEXT_POINTER), bc
    ld b, 10
scroll:
    profile_start
    call draw_1_text
    profile_end
    djnz scroll

    ld bc, S_TEST2
    ld (TEXT_POINTER), bc
    call draw_1_text

    ld bc, 0
    ld (DRAW_X), bc
    ld (DRAW_Y), bc
    ld bc, 512
    ld (DRAW_W), bc
    call draw_1_line_horizontal

; halt
halt:
    halt

FILL_BITS_LOOKUP0:    .db    $00, $01, $03, $07, $0f, $1f, $3f, $7f, $ff

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

S_TEST: .db "Hello world!", LF, EOL
S_TEST2: .db 32,32,31,32,30, LF, EOL
