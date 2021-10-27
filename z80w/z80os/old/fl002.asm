;**************************************************************
;
; FLASH.asm
;	version 002
;
; Here is mostly routines and such for network
; Some other miscellaneous code also... 
; .org $4000

; Call-table for applications
ethProbe:
 jp ethNICProbe
ethReset:
 push hl
 ld hl,(ejReset)
 jp (hl)
ethOpen:
 push hl
 ld hl,(ejOpen)
 jp (hl)
ethEnable:
 push hl
 ld hl,(ejEnable)
 jp (hl)
ethDisable:
 push hl
 ld hl,(ejDisable)
 jp (hl)
ethReceive:
 push hl
 ld hl,(ejReceive)
 jp (hl)
ethSend:
 push hl
 ld hl,(ejSend)
 jp (hl)
ethIntReceive:
 push hl
 ld hl,(ejIntReceive)
 jp (hl)
;

; *******************************
; misc
; *******************************
;ethbase                 equ $40
#define einb(address) ld a,(ethbase)\ add a,address\ ld c,a\ in a,(c)
#define eoutb(address) ex af,af'\ ld a,(ethbase)\ add a,address\ ld c,a\ ex af,af'\ out (c),a
#define eoutb_ ex af,af'\ ld a,(ethbase)\ add a,c\ ld c,a\ ex af,af'\ out (c),a
ethcom          equ $80

; Ethernet NICs ID's
NE1comp         equ $01
NE2comp         equ $02
NECcomp         equ $03
NEBcomp         equ $04
SMCultra        equ $11
SMCEtherEZ      equ $12
c3c509          equ $21
noNIC           equ $69

eSending        equ $26
eSended         equ $17
eTimedOut       equ $69

#ifdef CPU_AT_2MHZ
WaitForTimeout          equ 2800        ; Should be about 20ms
#endif
#ifdef CPU_AT_4MHZ
WaitForTimeout          equ 5600        ; Should be about 20ms
#endif

s_NoNIC         .db "No Ethernet NIC     ",$17,
                .db "found.              ",$17,$17
s_NICsearch     .db "Searching for NIC...",$17
test_packet     .db $ff,$ff,$ff,$ff,$ff,$ff
                .db $00,$40,$33,$38,$9a,$42
                .db $08,$06,$00,$01,$08,$00
                .db $06,$04,$00,$01,$00,$00
                .db $00,$00,$00,$17,$6f,$70
                .db $71,$11,$00,$00,$00,$00
                .db $00,$00,$6f,$70,$71,$63
                .db "Test packet "
                .db "send by Duge's Z80!!"

; *******************************
; routines for network
; *******************************
; ethNICProbe
ethNICProbe:
 di
 call clear_lcd
 ld hl,s_NICsearch
 call str2lcd
 ld de,NormalMesg
 call Delayms
 ld a,noNIC
 ld (ethdetect),a
 ld a,$40
 ld (ethbase),a
;
 call ne_probe
 cp noNIC
 jr nz,ie_nicfound
; call smc_probe
; cp noNIC
; jr nz,ie_nicfound
 ld hl,s_NoNIC
 ld a,noNIC
ie_nicfound:
 ld (ethdetect),a
 call clear_lcd
 call str2lcd
 ld a,Line2
 call setDDRAMa
 inc hl
 call str2lcd
 ld de,NormalMesg
 call Delayms
 call clear_lcd
; Send test packet
; Enable the NIC
 call ethEnable
send_loop:
 ld de,500              ; Wait 500ms
 call Delayms
 di
 ld hl,test_packet
 ld (ethDataAddr),hl
 ld hl,256
 ld (ethDataLen),hl
 ld a,0
 ld (ethDataPage),a
 ld a,(etxStartPage)
 ld (ethDataPage+1),a
 call ethSend
 cp eSended
 jr z,send_loop
 jr send_loop
;
 xor a
 ld (ethtmp),a
 call clear_lcd
 ret
; end of ethNICProbe

; *******************************
; ethPacketReceived
ethPacketReceived:
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
; end of ethPacketReceived
;**************************************************************

;**************************************************************
;
; Drivers
; 
;**************************************************************


;**************************************************************
; Some routines used by DP8390-compatible NICs

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

; *******************************
; DP8390_init
; Init DP8390 registers to "default"

dp_HWsavebad .db "DP8390 hw-address",$17
             .db "save failed.",$17

;
jDP8390_init:
 pop hl
DP8390_init:
 push af
 push bc
 push de
 push hl
 xor a
 out (ethcom),a
 ld a,E8390_NODMA+E8390_PAGE0+E8390_STOP
 eoutb(E8390_CMD)
 ld a,(ethwrdlen)
 cp 2
 ld a,$48
 jr nz,dp_bytelen
 ld a,$49
dp_bytelen:
 eoutb(EN0_DCFG)
 xor a
 eoutb(EN0_RCNTLO)
 eoutb(EN0_RCNTHI)
 ld a,E8390_RXOFF
 eoutb(EN0_RXCR)
 ld a,E8390_TXOFF
 eoutb(EN0_TXCR)
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
 call str2lcd
 ld a,Line2
 call setDDRAMa
 inc hl
 call str2lcd
 ld de,ErrorMesg
 call Delayms
 call clear_lcd
dp_hwallgood:
 ld a,(erxStartPage)
 eoutb(EN1_CURPAG)
 ld a,E8390_NODMA+E8390_PAGE0+E8390_STOP
 eoutb(E8390_CMD)
;
 pop hl
 pop de
 pop bc
 pop af
 ret
; end of DP8390_init

; *******************************
; DP8390_enable
jDP8390_enable:
 pop hl
DP8390_enable:
 push af
 push bc
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
 pop bc
 pop af
 ret
; end of DP8390_enable
;**************************************************************


;**************************************************************
; Drivers for NE1000/NE2000 (DP8390) compatible adapters
; Mostly copied from linux 2.4.5 kernels NE1000/NE2000 (DP8390) drivers
; (written by Donald Becker)

ne_copyright .db "NEx000 drivers      ",$17
             .db "By Duge. Mostly     ",$17
             .db "copied from linux   ",$17
             .db "kernel drivers      ",$17
             .db "written by          ",$17
             .db "Donald Becker.      ",$17,$17
ne_nodev     .db "No NE[1,2]000 found.",$17,$17
ne_noreset   .db "Reset failed on",$17
             .db "NE[1,2]000-NIC.",$17
ne1_detected .db "NE1000-NIC",$17
             .db "detected.",$17
ne2_detected .db "NE2000-NIC",$17
             .db "detected.",$17
neC_detected .db "NE-compatible Ctron-",$17
             .db "NIC detected.",$17
ne_badclone  .db "Bad NEx000 clone",$17
             .db "found.",$17

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

; *******************************
; neir
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

; *******************************
; ne_probe
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
 call clear_lcd
 call str2lcd
 ld a,Line2
 call setDDRAMa
 inc hl
 call str2lcd
 ld de,ErrorMesg
 call Delayms
 call clear_lcd
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
; inir
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
 ld a,noNIC
 ld hl,ne_nodev
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
 ld a,NESM_START_PG
 ld (etxStartPage),a
 add a,TX_PAGES
 ld (erxStartPage),a
 ld a,NESM_STOP_PG
 ld (ethStopPage),a
 jr nepb_jbyte
nepb_byte:
 ld a,NE1SM_START_PG
 ld (etxStartPage),a
 add a,TX_PAGES
 ld (erxStartPage),a
 ld a,NE1SM_STOP_PG
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
; Set up jump-table which is called by applications
 ld hl,jne_reset
 ld (ejReset),hl
 ld hl,jne_open
 ld (ejOpen),hl
 ld hl,jDP8390_enable
 ld (ejEnable),hl
 ld hl,jDP8390_init
 ld (ejDisable),hl
 ld hl,jne_receive
 ld (ejReceive),hl
 ld hl,jne_send
 ld (ejSend),hl
; Save the NIC's ID
 ld a,(ethsaprom+14)
 ld b,a
 ld a,(ethsaprom+15)
 cp b
 jr nz,nepb_nonex
 cp $57                 ; Check for NEx000-card
 jr nz,nepb_badclone
nepb_copam:             ; If NE-compatible copam-card
 ld a,(ethwrdlen)
 cp 2                   ; Check if 16bit
 ld a,NE2comp
 ld hl,ne2_detected
 jr z,nepb_end          ; Jump, if was 16bit card (NE2000)
 ld a,NE1comp           ; in other case 8bit (NE1000)
 ld hl,ne1_detected
 jr nepb_end
nepb_nonex:
 cp $0
 jr nz,nepb_notcopam
 ld a,b
 cp $49
 jr z,nepb_copam        ; Card was detected as 'copam' NEx000-compatible
nepb_notcopam:
 ld a,(ethsaprom+0)
 cp $0
 jr nz,nepb_badclone
 ld a,(ethsaprom+1)
 cp $0
 jr nz,nepb_badclone
 ld a,(ethsaprom+2)
 cp $1d
 jr nz,nepb_badclone
 ld a,NECcomp           ; Ctron 8- or 16-bit NEx000-compatible card
 ld hl,neC_detected     ; Detection between 8- and 16-bits left out
 jr nepb_end            ; becose there no use for that information
nepb_badclone:
 ld hl,ne_badclone
 ld a,NEBcomp
 jr nepb_end
nepb_nodev:
 ld a,noNIC
 ld hl,ne_nodev
 jr nepb_end
;
nepb_end:
 ret
; end of ne_probe

; *******************************
; ne_open
jne_open:
 pop hl
ne_open:
 call DP8390_init
 call DP8390_enable
 ret
; end of ne_open

; *******************************
; ne_receive
jne_receive:
 pop hl
ne_receive:
 ret
; end of ne_receive

; *******************************
; ne_send
; Packet's address in ethDataAddr, lenght in ethDataLen and start page in ethDataPage
nes_timeout     .db "Timeout for Tx RDC.",$17

jne_send:
 pop hl
ne_send:
 einb(NE_CMD)           ; Is NIC already sending?
 cp $26
 ld a,eSending          ; If, return eSending in reg a
 ret z                  ;
 push bc
 push de
 push hl
 ld a,(ethwrdlen)
 cp 2                   ; Check for odd byte count if
 jr nz,nes_nodd         ; in word mode (is this needed really?)
 ld hl,(ethDataLen)
 inc hl
 ld a,l
 and $fe
 ld l,a
 ld (ethDataLen),hl
nes_nodd:
 ld a,E8390_PAGE0+E8390_START+E8390_NODMA
 eoutb(NE_CMD)
 ld a,ENISR_RDC
 eoutb(EN0_ISR)
 ld a,(ethDataLen)
 eoutb(EN0_RCNTLO)
 ld a,(ethDataLen+1)
 eoutb(EN0_RCNTHI)
 ld a,(ethDataPage)
 eoutb(EN0_RSARLO)
 ld a,(ethDataPage+1)
 eoutb(EN0_RSARHI)
 ld a,E8390_RWRITE+E8390_START
 eoutb(NE_CMD)
 ld a,(ethbase)
 add a,NE_DATAPORT
 ld c,a
; Now copy the data into NIC
; ld a,(ethwrdlen)
; cp 2
; jr nz,nes_sendbybyte
 ld de,(ethDataLen)
 ld a,e                 ; Divide de's value by 2
 sra a
 and $7f
 sra d
 jr nc,nes_sbwc
 or $80
nes_sbwc:
 ld e,a
 inc d
 ld hl,(ethDataAddr)
nes_sendbyword:
 ld b,(hl)
 inc hl
 ld a,(hl)
 inc hl
 out (ethcom),a
 out (c),b
 dec e
 jr nz,nes_sendbyword
 dec d
 jr nz,nes_sendbyword
 jr nes_nsend
nes_sendbybyte:
nes_nsend:
 ld a,(ethbase)
 add a,EN0_ISR
 ld c,a
 ld hl,WaitForTimeout
nes_wait:               ; Should wait here about 20ms
 dec hl
 ld a,h
 cp 0
 jr z,nes_timedout
 in a,(c)
 and ENISR_RDC
 jr z,nes_wait
nes_pos:
 ld a,ENISR_RDC
 eoutb((EN0_ISR)
 ld a,(ethDataPage+1)
 eoutb(EN0_TPSR)
 ld a,(ethDataLen)
 eoutb(EN0_TCNTLO)
 ld a,(ethDataLen+1)
 eoutb(EN0_TCNTHI)
 ld a,E8390_NODMA+E8390_TRANS+E8390_START
 eoutb(NE_CMD)
 ld a,eSended
 pop hl
 pop de
 pop bc
 ret
nes_timedout:
 call clear_lcd
 ld hl,nes_timeout
 call str2lcd           ; This message should go into log in the future
 ld de,NormalMesg
 call Delayms
 call ne_reset
 call DP8390_init
 call DP8390_enable
 ld a,eTimedOut
 pop hl
 pop de
 pop bc
 ret
; end of ne_send

; *******************************
; ne_reset
jne_reset:
 pop hl
ne_reset:
 push bc
 push hl
 ld a,(ethbase)
 add a,NE_RESET
 ld c,a
 in a,(c)
 out (c),a
 ld hl,$1000
 ld a,(ethbase)
 add a,EN0_ISR
 ld c,a
ners_wait:
 dec hl
 ld a,h
 cp 0
 jr z,ners_failed
 in a,(c)
 and ENISR_RESET
 jr z,ners_wait
 ld a,$ff
 out (c),a
 ld a,$17
 pop hl
 pop bc
 ret
ners_failed:
 ld a,$ff
 out (c),a
 ld a,$69
 pop hl
 pop bc
 ret
; end of ne_reset

; end of NEx000 compatible adapters driver
;**************************************************************
