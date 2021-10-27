;**************************************************************
; Drivers for SMC Ultra (ex.83c790) adapters
; Mostly copied from linux 2.4.5 kernels SMC Ultra drivers
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


; *******************************
; smc_probe
smc_probe:
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
 ld a,2
 ld (ethwrdlen),a
 ld a,START_PG
 ld (etxStartPage),a
 add a,TX_PAGES
 ld (erxStartPage),a
 ld a,$20
 ld (ethStopPage),a
; Set up jump-table which is called by applications
 ld hl,jsmc_reset
 ld (ejReset),hl
 ld hl,jsmc_open
 ld (ejOpen),hl
 ld hl,jDP8390_enable
 ld (ejEnable),hl
 ld hl,jDP8390_init
 ld (ejDisable),hl
 ld hl,jne_interrupt
 ld (ejInterrupt),hl
 ld hl,jne_send
 ld (ejSend),hl
;
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
; end of smc_probe

; *******************************
; smc_open
jsmc_open:
 pop hl
smc_open:
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
 or $44         ; THIS IS FOR IRQ10, should it be changed?!?
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
 call DP8390_init
;
 ld a,(ethbase)
 add a,ULTRA_NIC_OFFSET
 ld (ethbase),a
 ret
; end of smc_open

; *******************************
; smc_reset
jsmc_reset:
 pop hl
smc_reset:
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
; end of smc_reset

; end of SMC-ultra driver
;**************************************************************
