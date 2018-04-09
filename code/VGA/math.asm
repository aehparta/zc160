
m_mul_de_a_to_ahl:      ; AHL = DE × A
    ld hl, 0      ; Use HL to store the product
    ld b, 8       ; Eight bits to check
m_mul_de_a_to_ahl_loop:
    add hl, hl
    adc a, a         ; Check most-significant bit of accumulator
    jr nc, m_mul_de_a_to_ahl_skip  ; If zero, skip addition
    add hl, de
m_mul_de_a_to_ahl_skip:
    djnz m_mul_de_a_to_ahl_loop
    ret

m_div_hl_d_to_hl_a:            ; HL = HL ÷ D, A = remainder
    xor    a         ; Clear upper eight bits of AHL
    ld     b, 16     ; Sixteen bits in dividend
m_div_hl_d_to_hl_a_loop:
    add    hl, hl    ; Do a SLA HL. If the upper bit was 1, the c flag is set
    rla              ; This moves the upper bits of the dividend into A
    jr     c, m_div_hl_d_to_hl_a_overflow
    cp     d         ; Check if we can subtract the divisor
    jr     c, m_div_hl_d_to_hl_a_skip  ; Carry means D > A
m_div_hl_d_to_hl_a_overflow:
    sub    d         ; Do subtraction for real this time
    inc    l         ; Set the next bit of the quotient (currently bit 0)
m_div_hl_d_to_hl_a_skip:
    djnz   m_div_hl_d_to_hl_a_loop
    ret

m_mul_bc_de_to_bhla:
;  BHLA is the 32-bit result
    ld a, b
    or a
    ld hl, 0
    ld b, h
;1
    add a, a
    jr nc, $+4
    ld h, d
    ld l, e
;2
    add hl, hl
    rla
    jr nc, $+4
    add hl, de
    adc a, b
;227+10b-7p
    add hl,hl
    rla
    jr nc,$+4
    add hl,de
    adc a,b

    add hl,hl
    rla
    jr nc,$+4
    add hl,de
    adc a,b

    add hl,hl
    rla
    jr nc,$+4
    add hl,de
    adc a,b

    add hl,hl
    rla
    jr nc,$+4
    add hl,de
    adc a,b

    add hl,hl
    rla
    jr nc,$+4
    add hl,de
    adc a,b

    add hl,hl
    rla
    jr nc,$+4
    add hl,de
    adc a,b

;===
;AHL is the result of B*DE*256
    push hl
    ld h,b
    ld l,b
    ld b,a
    ld a,c
    ld c,h
;1
    add a,a
    jr nc,$+4
    ld h,d
    ld l,e
;2
    add hl,hl
    rla
    jr nc,$+4
    add hl,de
    adc a,c
;227+10b-7p
    add hl,hl
    rla
    jr nc,$+4
    add hl,de
    adc a,c

    add hl,hl
    rla
    jr nc,$+4
    add hl,de
    adc a,c

    add hl,hl
    rla
    jr nc,$+4
    add hl,de
    adc a,c

    add hl,hl
    rla
    jr nc,$+4
    add hl,de
    adc a,c

    add hl,hl
    rla
    jr nc,$+4
    add hl,de
    adc a,c

    add hl,hl
    rla
    jr nc,$+4
    add hl,de
    adc a,c

    pop de
;Now BDE*256+AHL
    ld c,a
    ld a,l
    ld l,h
    ld h,c
    add hl,de
    ret nc
    inc b
;BHLA is the 32-bit result
    ret


SqrtHL_prec12:
;input: HL
;Output: HL
;183 bytes
    xor a
    ld b,a

    ld e,l
    ld l,h
    ld h,a

    add hl,hl
    add hl,hl
    cp h
    jr nc,$+5
    dec h
    ld a,4

    add hl,hl
    add hl,hl
    ld c,a
    sub h
    jr nc,$+6
    cpl
    ld h,a
    inc c
    inc c

    ld a,c
    add hl,hl
    add hl,hl
    add a,a
    ld c,a
    sub h
    jr nc,$+6
    cpl
    ld h,a
    inc c
    inc c

    ld a,c
    add hl,hl
    add hl,hl
    add a,a
    ld c,a
    sub h
    jr nc,$+6
    cpl
    ld h,a
    inc c
    inc c

    ld a,c
    ld l,e

    add hl,hl
    add hl,hl
    add a,a
    ld c,a
    sub h
    jr nc,$+6
    cpl
    ld h,a
    inc c
    inc c

    ld a,c
    add hl,hl
    add hl,hl
    add a,a
    ld c,a
    sub h
    jr nc,$+6
    cpl
    ld h,a
    inc c
    inc c

    ld a,c
    add a,a
    ld c,a
    add hl,hl
    add hl,hl
    jr nc,$+6
    sub h
    jp $+6
    sub h
    jr nc,$+6
    inc c
    inc c
    cpl
    ld h,a

    ld a,l
    ld l,h
    add a,a
    ld h,a
    adc hl,hl
    adc hl,hl
    sll c
    rl b
    sbc hl,bc
    jr nc,$+3
    add hl,bc
    sbc a,a
    add a,a
    inc a
    add a,c
    ld c,a

;iteration 9
    add hl,hl
    add hl,hl
    sll c
    rl b
    sbc hl,bc
    jr nc,$+3
    add hl,bc
    sbc a,a
    add a,a
    inc a
    add a,c
    ld c,a

    add hl,hl
    add hl,hl
    sll c
    rl b
    sbc hl,bc
    jr nc,$+3
    add hl,bc
    sbc a,a
    add a,a
    inc a
    add a,c
    ld c,a

    add hl,hl
    add hl,hl
    sll c
    rl b
    sbc hl,bc
    jr nc,$+3
    add hl,bc
    sbc a,a
    add a,a
    inc a
    add a,c
    ld c,a

    add hl,hl
    add hl,hl
    sll c
    rl b
    sbc hl,bc
    jr nc,$+3
    add hl,bc
    sbc a,a
    add a,a
    inc a
    add a,c
    ld c,a
;12th iteration completed
; output in BC
    srl b
    rr c
    ld h,b
    ld l,c
    ret


m_sine_88_de_to_hl:
;Inputs: de
    push de
    sra d
    rr e
    ld b,d
    ld c,e
    call m_mul_bc_de_to_bhla
    push hl     ;x^2/4
    sra h
    rr l
    ex de,hl
    ld b,d
    ld c,e
    call m_mul_bc_de_to_bhla
    sra h
    rr l
    inc h
    ex (sp),hl    ;x^4/128+1 is on stack, HL=x^2/4
    xor a
    ld d,a
    ld b,h
    ld c,l
    add hl,hl
    rla
    add hl,hl
    rla
    add hl,bc
    adc a,d
    ld b,h
    ld c,l
    add hl,hl
    rla
    add hl,hl
    rla
    add hl,hl
    rla
    add hl,hl
    rla
    add hl,bc
    adc a,d
    ld e,l
    ld l,h
    ld h,a
    rl e
    adc hl,hl
    rl e
    jr nc,$+3
    inc hl

    pop de
    ex de,hl
    or a
    sbc hl,de
    ex de,hl
    pop bc
    jp m_mul_bc_de_to_bhla

m_lut_sin:
.db 0,3,6,9,12,16,19,22,25,28,31,34,37,40,43,46
.db 49,51,54,57,60,63,65,68,71,73,76,78,81,83,85,88
.db 90,92,94,96,98,100,102,104,106,107,109,111,112,113,115,116
.db 117,118,120,121,122,122,123,124,125,125,126,126,126,127,127,127
.db 127,127,127,127,126,126,126,125,125,124,123,122,122,121,120,118
.db 117,116,115,113,112,111,109,107,106,104,102,100,98,96,94,92
.db 90,88,85,83,81,78,76,73,71,68,65,63,60,57,54,51
.db 49,46,43,40,37,34,31,28,25,22,19,16,12,9,6,3
.db 0,-3,-6,-9,-12,-16,-19,-22,-25,-28,-31,-34,-37,-40,-43,-46
.db -49,-51,-54,-57,-60,-63,-65,-68,-71,-73,-76,-78,-81,-83,-85,-88
.db -90,-92,-94,-96,-98,-100,-102,-104,-106,-107,-109,-111,-112,-113,-115,-116
.db -117,-118,-120,-121,-122,-122,-123,-124,-125,-125,-126,-126,-126,-127,-127,-127
.db -127,-127,-127,-127,-126,-126,-126,-125,-125,-124,-123,-122,-122,-121,-120,-118
.db -117,-116,-115,-113,-112,-111,-109,-107,-106,-104,-102,-100,-98,-96,-94,-92
.db -90,-88,-85,-83,-81,-78,-76,-73,-71,-68,-65,-63,-60,-57,-54,-51
.db -49,-46,-43,-40,-37,-34,-31,-28,-25,-22,-19,-16,-12,-9,-6,-3
