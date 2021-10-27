;**************************************************************
;
; FLASH.asm
;	version 006
;
; Here is routines and such for network mostly
; Some other miscellaneous code also... 
;.org $4000

; Enable some of these to use LEDs and 7segments for debugging
#define DEBUG_DRIVERS   ; DEBUG when running drivers code
;#define DEBUG_MM        ; DEBUG when running memory manager code
;#define DEBUG_TCPIP     ; DEBUG when running TCP/IP code

; network variables
ETHM            equ SRM+128     ;256bytes (must be equ to network
                                ;in osXXX.asm)
;
ethbase         equ ETHM+0      ;byte
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
pkthdr          equ ETHM+150    ;2bytes+1word=4bytes
pkthdr_stat     equ ETHM+150    ;byte
pkthdr_next     equ ETHM+151    ;byte
pkthdr_count    equ ETHM+152    ;word
; Ethernet packet header
ethpkt          equ ETHM+160
; DLC header
ep_target       equ ETHM+160    ;6 bytes
ep_source       equ ETHM+166    ;6 bytes
ep_type         equ ETHM+172    ;word
; ARP specific header
#define ethpkt_ARPsize 14+28
ep_hwtype       equ ETHM+174    ;word
ep_protocol     equ ETHM+176    ;word
ep_hwlen        equ ETHM+178    ;byte
ep_protolen     equ ETHM+179    ;byte
ep_opcode       equ ETHM+180    ;word
ep_senderhw     equ ETHM+182    ;6 bytes
ep_senderpr     equ ETHM+188    ;4 bytes, when using IP-protocol
ep_targethw     equ ETHM+192    ;6 bytes
ep_targetpr     equ ETHM+198    ;4 bytes, when using IP-protocol

; Temporary values
NT0             equ ETHM+252    ;byte
NT1             equ ETHM+253    ;byte
NT2             equ ETHM+254    ;byte
NT3             equ ETHM+255    ;byte

; Call-table for applications
ethInit:
 jp ethNICInit
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
ethInterrupt:
 push hl
 ld hl,(ejInterrupt)
 jp (hl)
ethSend:
 push hl
 ld hl,(ejSend)
 jp (hl)
net_init:
 jp nnet_init
;

; *******************************
; misc
; *******************************
;ethbase                 equ $40
; These macros makes easier to use the NIC
; by adding the base address of NIC to the
; relative NIC register address
#define einb(address) ld a,(ethbase)\ add a,address\ ld c,a\ in a,(c)
#define eoutb(address) ex af,af'\ ld a,(ethbase)\ add a,address\ ld c,a\ ex af,af'\ out (c),a
#define eoutb_ ex af,af'\ ld a,(ethbase)\ add a,c\ ld c,a\ ex af,af'\ out (c),a
ethcom          equ $80

; Ethernet NICs ID's
NE1comp         equ $01
NE2comp         equ $02
NECcomp         equ $03
NEBcomp         equ $04
; Coming...
SMCultra        equ $11
SMCEtherEZ      equ $12
c3c509b         equ $21
;
noNIC           equ $69

eSending        equ $26
eSended         equ $17
eTimedOut       equ $69

MAX_SERVICE     equ $10

#ifdef CPU_AT_2MHZ
WaitForTimeout          equ 2800        ; Should be about 20ms
#endif
#ifdef CPU_AT_4MHZ
WaitForTimeout          equ 5600        ; Should be about 20ms
#endif
#ifdef CPU_AT_8MHZ
WaitForTimeout          equ 11200       ; Should be about 20ms
#endif

s_NoNIC         .db "No Ethernet NIC",EOL
                .db "found.",EOL
s_NetProbeNIC   .db "Probing NIC...",EOL
s_NetLogFirst   .db "Net Log Created.",LOGSP,EOL
s_LOGSP         .db LOGSP,EOL 
test_packet     .db $ff,$ff,$ff,$ff,$ff,$ff
                .db $00,$40,$33,$38,$9a,$42
                .db "Test packet."
                .db "Send by Duge's Z80!!"
                .db "Send by Duge's Z80!!"
                .db "Send by Duge's Z80!!"
                .db "Send by Duge's Z80!!"
                .db $08,$06,$00,$01,$08,$00
                .db $06,$04,$00,$01,$00,$00
                .db $00,$00,$00,$17,$6f,$70
                .db $71,$11,$00,$00,$00,$00
                .db $00,$00,$6f,$70,$71,$63

; *******************************
; routines for network
; *******************************
; ethNICInit
ethNICInit:
 di
 ld hl,1024
 call CreateLog
 ld (NetLogId),a
 ld hl,s_NetLogFirst
 call AddLog
; Clear error counters
 ld hl,0
 ld (ethRxFrameErrs),hl ; rx frame errors
 ld (ethRxCrcErrs),hl   ; rx CRC errors
 ld (ethRxMissedErrs),hl; rx missed-errors
 ld (ethTxCarrErrs),hl  ; tx carrier errors
 ld (ethTxHBErrs),hl    ; tx heartbeat errors
 ld (ethTxWindow),hl    ; tx window errors
 ld (ethRxOverErrs),hl  ; rx overrun errors
 ld (ethRxErrs),hl      ; rx errors      
 ld (ethRxFifoErrs),hl  ; rx fifo errors      
 ld (ethRxLenErrs),hl   ; rx fifo errors
 ld (ethRxDropped),hl   ; rx dropped packets
;
 ld (ethRxPackets),hl   
 ld (ethRxPackets+2),hl  
 ld (ethTxPackets),hl      
 ld (ethTxPackets+2),hl    
 ld (ethRxBytes),hl    
 ld (ethRxBytes+2),hl    
 ld (ethTxBytes),hl        
 ld (ethTxBytes+2),hl        
; Show search-text in LCD
 ld a,(NetLogId)
 ld hl,s_NetProbeNIC
 call AddLog
 ld hl,s_LOGSP
 call AddLog
 call clear_lcd
 ld hl,s_NetProbeNIC
 call str2lcd
 ld de,NormalMesg
 call Delayms
 ld a,noNIC
 ld (ethdetect),a
 ld a,$40
 ld (ethbase),a
; Probe the NIC
 call ne_probe           ; NEx000-compatible cards
 cp noNIC
 jr nz,ie_nicfound
; call smc_probe
; cp noNIC
; jr nz,ie_nicfound
 ld hl,s_NoNIC
 ld a,noNIC
ie_nicfound:
 ld (ethdetect),a
 ld a,(NetLogId)
 push hl
 call AddLog
 ld hl,s_LOGSP
 call AddLog
 call clear_lcd
 pop hl
 call str2lcd
 ld a,Line2
 call setDDRAMa
 inc hl
 call str2lcd
 ld de,NormalMesg
 call Delayms
 call clear_lcd
; Enable the NIC
 ld a,noNIC
 ld (ethdetect),a
 ld a,(ethdetect)
 cp noNIC
 jp z,ie_nonic
 call ethOpen
ie_nonic:
 xor a
 ld (ethtmp),a
 call clear_lcd
 ld a,(ethdetect)
 ret
; end of ethNICInit

;**************************************************************
;
; Drivers
; 
;**************************************************************


;**************************************************************
; Some routines used by 8390-compatible NICs

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
; Init 8390 registers to "default"

dp_HWsavebad .db "8390 hw-address",$17
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
 ld d,a
 in a,(c)
 inc hl
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
 ld de,FastMesg
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
; Mostly copied from linux 2.4.5 kernels NE1000/NE2000 (8390) drivers
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
             .db "detected.",$17

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
 ld a,E8390_NODMA+E8390_PAGE0+E8390_STOP
 eoutb(E8390_CMD)
 ld a,$48
 eoutb(EN0_DCFG)
 xor a
 eoutb(EN0_RCNTLO)
 eoutb(EN0_RCNTHI)
 eoutb(EN0_IMR)
 ld a,$ff
 eoutb(EN0_ISR)
 ld a,E8390_RXOFF
 eoutb(EN0_RXCR)
 ld a,E8390_TXOFF
 eoutb(EN0_TXCR)
 ld a,32
 eoutb(EN0_RCNTLO)
 xor a
 eoutb(EN0_RCNTHI)
 eoutb(EN0_RSARLO)
 eoutb(EN0_RSARHI)
 ld a,E8390_RREAD+E8390_START
 eoutb(E8390_CMD)
; Read station address PROM (SAPROM)
 ld a,2
 ld (ethwrdlen),a
 ld b,32
 ld hl,ethsaprom
 ld a,(ethbase)
 add a,NE_DATAPORT
 ld c,a
nepb_readsaprom:
; inir
; ld a,NE2comp
; ld hl,ne2_detected
; ret
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
 ld hl,jne_interrupt
 ld (ejInterrupt),hl
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
 call ne_reset
 call DP8390_init
 call DP8390_enable
 ret
; end of ne_open

; *******************************
; ne_interrupt
jne_interrupt:
 pop hl
ne_interrupt:
 nop
 nop
 push af
 push hl
 push bc
 push de
 ld a,E8390_NODMA+E8390_PAGE0
 eoutb(NE_CMD)
 ld a,10
 ld (NT2),a
#ifdef DEBUG_DRIVERS
 ld a,$ff
 out (LEDs),a
 out (SSeg1),a
 out (SSeg2),a
 out (SSeg3),a
 out (SSeg4),a
 xor a
 push af
#endif
nei_rloop:
#ifdef DEBUG_DRIVERS
 pop af
 inc a
 push af
 or 1
 xor $ff
 out (LEDs),a
 ld de,1000
 call Delayms
#endif
 ld a,(NT2)
 dec a
 jp z,nei_end
 ld (NT2),a
 einb(EN0_ISR)
 cp 0
 jp z,nei_end
 ld b,a
 and ENISR_OVER
 jp nz,nei_over
 ld a,b
 and ENISR_RX
 jp nz,nei_rx
 ld a,b
 and ENISR_RX_ERR
 jp nz,nei_rxwitherr
 ld a,b
 and ENISR_TX
 jp nz,nei_tx
 ld a,b
 and ENISR_TX_ERR
 jp nz,nei_txwitherr
 ld a,b
 and ENISR_RDC
 jp nz,nei_enisr
 ld a,b
 and ENISR_COUNTERS
 jp nz,nei_counters
nei_loop:
 ld a,E8390_NODMA+E8390_PAGE0+E8390_START
 eoutb(E8390_CMD)
 jp nei_rloop
nei_end:
#ifdef DEBUG_DRIVERS
 pop af
 ld a,$ff
 out (LEDs),a
#endif
 pop de
 pop bc
 pop hl
 pop af
 ret
;
nei_rx:
nei_rxwitherr:
#ifdef DEBUG_DRIVERS
 ld a,0
 ld c,SSeg1
 call n_to_7seg
#endif
 call ne_receive
 jp nei_loop
nei_tx:
nei_txwitherr:
#ifdef DEBUG_DRIVERS
 ld a,1
 ld c,SSeg1
 call n_to_7seg
#endif
 jp nei_loop
; Handle receiver overrun
nei_over:
#ifdef DEBUG_DRIVERS
 ld a,2
 ld c,SSeg1
 call n_to_7seg
#endif
 einb(E8390_CMD)
 and E8390_TRANS
 ld b,a
 ld a,E8390_NODMA+E8390_PAGE0+E8390_STOP
 eoutb(E8390_CMD)
 ld hl,ethRxOverErrs
 inc hl
 ld (ethRxOverErrs),hl
 ld de,10
 call Delayms
 ld a,(ethbase)
 add a,EN0_RCNTLO
 ld c,a
 xor a
 out (c),a
 inc c
 out (c),a
 cp b
 jp z,neio_notrans
 einb(EN0_ISR)
 and ENISR_TX+ENISR_TX_ERR
 cp 0
 jp z,neio_notrans
 ld b,0
neio_notrans:
 ld a,E8390_TXOFF
 eoutb(EN0_TXCR)
 ld a,E8390_NODMA+E8390_PAGE0+E8390_START
 eoutb(E8390_CMD)
 call ne_receive
 ld a,ENISR_OVER
 eoutb(EN0_ISR)
 ld a,(E8390_TXCONFIG)
 eoutb(EN0_TXCR)
 xor a
 cp b
 jp z,neio_noretrans
 ld a,E8390_NODMA+E8390_PAGE0+E8390_START+E8390_TRANS
 eoutb(E8390_CMD)
neio_noretrans:
 jp nei_loop
; Ignore any RDC
nei_enisr:
#ifdef DEBUG_DRIVERS
 ld a,3
 ld c,SSeg1
 call n_to_7seg
#endif
 ld a,ENISR_RDC
 eoutb(EN0_ISR)
 jp nei_loop
; Update counters
nei_counters:
#ifdef DEBUG_DRIVERS
 ld a,4
 ld c,SSeg1
 call n_to_7seg
#endif
 ld a,(ethbase)
 add a,EN0_COUNTER0
 ld c,a
 in l,(c)
 ld h,0
 ld de,(ethRxFrameErrs)
 add hl,de
 ld (ethRxFrameErrs),hl
 inc c
 in l,(c)
 ld h,0
 ld de,(ethRxCrcErrs)
 add hl,de
 ld (ethRxCrcErrs),hl
 inc c
 in l,(c)
 ld h,0
 ld de,(ethRxMissedErrs)
 add hl,de
 ld (ethRxMissedErrs),hl
 ld a,ENISR_COUNTERS
 eoutb(EN0_ISR)
 jp nei_loop
; end of ne_interrupt

; *******************************
; ne_receive
ne_receive:
 push af
 push hl
 push bc
 push de
 ld a,10
 ld (NT3),a
ner_loop:
 ld a,(NT3)
 dec a
 jp z,ner_end
 ld (NT3),a
;
 ld a,E8390_NODMA+E8390_PAGE1
 eoutb(E8390_CMD)
 einb(EN1_CURPAG)
 ld b,a
 ld (NT0),a
 ld a,E8390_NODMA+E8390_PAGE0
 eoutb(E8390_CMD)
 einb(EN0_BOUNDARY)
 inc a
 ld e,a
 ld (NT1),a
 ld a,(ethStopPage)
 dec a
 cp e
 jp nc,ner_notbigger
 ld a,(erxStartPage)
 ld e,a
ner_notbigger:
 ld a,b
 cp e
 jp z,ner_end
; Now grab the 8390 header
 ld a,E8390_NODMA+E8390_PAGE0+E8390_START
 eoutb(E8390_CMD)
 ld a,pkthdr_size
 ld b,a
 eoutb(EN0_RCNTLO)
 xor a
 eoutb(EN0_RCNTHI)
 eoutb(EN0_RSARLO)
 ld a,e
 eoutb(EN0_RSARHI)
 ld a,E8390_RREAD+E8390_START
 eoutb(E8390_CMD)
 ld a,(ethbase)
 add a,NE_DATAPORT
 ld c,a
 ld hl,pkthdr
 ld a,(ethwrdlen)
 cp 2
 jp nz,ner_hdrbybyte
 srl b
ner_wloop:
 in a,(c)
 ld (hl),a
 inc hl
 in a,(ethcom)
 ld (hl),a
 inc hl
 dec b
 jp nz,ner_wloop
 jp ner_hdrcopied
ner_hdrbybyte:
 in a,(c)
 ld (hl),a
 inc hl
 dec b
 jp nz,ner_wloop
ner_hdrcopied:
 ld a,ENISR_RDC
 eoutb(EN0_ISR)
;
 ld hl,(pkthdr_count)
 ld d,h
 ld a,pkthdr_size
ner_pkthdrdec:
 dec hl
 dec a
 jr nz,ner_pkthdrdec
 ld (pkthdr_count),hl
 inc d
 ld a,e
 add a,d
 ld de,(pkthdr_next)
; Bogosity test
; Aaargh!! This kind of testing can be awful to do with assembly:
; (cut from ne.c, linux kernel drivers)
; "if (rx_frame.next != next_frame
;   && rx_frame.next != next_frame + 1
;   && rx_frame.next != next_frame - num_rx_pages
;   && rx_frame.next != next_frame + 1 - num_rx_pages) {"
;
;rx_frame.next != next_frame 
 cp e
 jp z,ner_bogend
;rx_frame.next != next_frame + 1
 inc a
 cp e
 jp z,ner_bogend
;rx_frame.next != next_frame + 1 - num_rx_pages
 ld bc,(ethStopPage)
 add a,c
 ld bc,(erxStartPage)
 sub c
 cp e
 jp z,ner_bogend
;rx_frame.next != next_frame - num_rx_pages
 dec a
 cp e
 jp z,ner_bogend
;
 ld a,(NT0)
 ld (ethCurrentPage),a
 dec a
 eoutb(EN0_BOUNDARY)
 ld hl,(ethRxErrs)
 inc hl
 ld (ethRxErrs),hl
 jp ner_loop
; bogosity test end
ner_bogend:
 ld a,(pkthdr_count+1)
 cp $00
 jp nz,ner_bigpkt
 ld a,(pkthdr_count)
 cp $3c
 jp nc,ner_pktsizeok
ner_pktsizenok:
 ld hl,(ethRxErrs)
 inc hl
 ld (ethRxErrs),hl
 ld hl,(ethRxLenErrs)
 inc hl
 ld (ethRxLenErrs),hl
 jp ner_nend
ner_bigpkt:
 ld de,(pkthdr_count)
 ld a,$05
 cp d
 jp c,ner_pktsizenok
 jp nz,ner_pktsizeok
 ld a,$ee
 cp e
 jp c,ner_pktsizenok
ner_pktsizeok:
;
 ld a,(pkthdr_stat)
 and $0f
 cp ENRSR_RXOK
 jp nz,ner_else
; The packet is really a packet and it's OK!!!
; Now it can be handled!
; Copy the packet from NIC to local memory
; Same as linux drivers ne_block_input-routine
; First check for free space in packet buffer
#ifdef DEBUG_DRIVERS
 ld a,0
 ld c,SSeg2
 call n_to_7seg
#endif
 ld hl,(pkthdr_count)
 ld (netDataLen),hl
 call net_checkspace
 cp nBufNoSpace
 jp z,ner_nospace
;
 ld a,E8390_NODMA+E8390_PAGE0+E8390_START
 eoutb(NE_CMD)
 ld a,(pkthdr_count)
 eoutb(EN0_RCNTLO)
 ld a,(pkthdr_count+1)
 eoutb(EN0_RCNTHI)
 ld a,pkthdr_size
 eoutb(EN0_RSARLO)
 ld a,(NT1)
 eoutb(EN0_RSARHI)
 ld a,E8390_RREAD+E8390_START
 eoutb(NE_CMD)
; Registers ready, start copying
 ld de,(pkthdr_count)
 ld (netDataLen),de
 ld a,(ethbase)
 add a,NE_DATAPORT
 ld (netIOCopyPort),a
 ld a,nBufCopyIO
 ld (netCopyType),a
#ifdef DEBUG_DRIVERS
 ld a,1
 ld c,SSeg2
 call n_to_7seg
#endif
 call net_allocbuffer
 cp nBufNoSpace
 jp nz,ner_copyok
; Should this be handled in this way?
; Anyway something is really wrong if this is needed
 ld a,E8390_NODMA+E8390_PAGE0+E8390_STOP
 eoutb(NE_CMD)
 ld a,E8390_NODMA+E8390_PAGE0+E8390_START
 eoutb(NE_CMD)
ner_nospace:
#ifdef DEBUG_DRIVERS
 ld a,2
 ld c,SSeg2
 call n_to_7seg
#endif
 ld hl,(ethRxDropped)
 inc hl
 ld (ethRxDropped),hl
#ifdef DEBUG_DRIVERS
 ld a,(ethRxDropped)
 ld c,SSeg3
 call b_to_7seg
#endif
 jp ner_end
ner_copyok:
#ifdef DEBUG_DRIVERS
 ld a,3
 ld c,SSeg2
 call n_to_7seg
#endif
 ld a,ENISR_RDC
 eoutb(EN0_ISR)
; Update rx packet counter and rx byte counter
 ld hl,(ethRxPackets)
 ld de,1
 add hl,de
 ld (ethRxPackets),hl
 ld hl,(ethRxPackets+2)
 ld e,0
 adc hl,de
 ld (ethRxPackets+2),hl
 ld hl,(ethRxBytes)
 ld de,(pkthdr_count)
 add hl,de
 ld (ethRxBytes),hl
 ld hl,(ethRxBytes+2)
 ld de,0
 adc hl,de
 ld (ethRxBytes+2),hl
#ifdef DEBUG_DRIVERS
 ld a,(ethRxPackets)
 ld c,SSeg3
 call b_to_7seg
#endif
;
 jp ner_nend
;
ner_else:
#ifdef DEBUG_DRIVERS
 ld a,4
 ld c,SSeg2
 call n_to_7seg
#endif
 ld hl,(ethRxErrs)
 inc hl
 ld (ethRxErrs),hl
 ld a,(pkthdr_stat)
 and ENRSR_FO
 jp z,ner_nend
 ld hl,(ethRxFifoErrs)
 inc hl
 ld (ethRxFifoErrs),hl
ner_nend:
#ifdef DEBUG_DRIVERS
 ld a,5
 ld c,SSeg2
 call n_to_7seg
#endif
 ld a,(ethStopPage)
 dec a
 ld hl,pkthdr_next
 cp (hl)
 jp nc,nerp_nbadbad
#ifdef DEBUG_DRIVERS
 ld a,6
 ld c,SSeg2
 call n_to_7seg
#endif
 ld hl,erxStartPage
nerp_nbadbad:
 ld a,(hl)
 ld (ethCurrentPage),a
 dec a
 eoutb(EN0_BOUNDARY)
 jp ner_loop
;
ner_end:
 ld a,ENISR_RX+ENISR_RX_ERR
 eoutb(EN0_ISR)
 pop de
 pop bc
 pop hl
 pop af
 ret
; end of ne_receive

; *******************************
; ne_send
; Packet's address in ethDataAddr, lenght in
; ethDataLen and start page in ethDataPage
nes_timeout     .db "Timeout for Tx RDC.",LOGSP,EOL

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
 di
 ld a,(ethwrdlen)
 cp 2                   ; Check for odd byte count if
 jp nz,nes_nodd         ; in word mode (is this needed really?)
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
 ld a,(ethwrdlen)
 cp 2																			; Is the card 16bit or 8bit?
 jp nz,nes_sendbybyte   ; Is the card 8- or 16-bit
 ld de,(ethDataLen)
 srl d                  ; Divide de's value by 2
 rr e
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
 jp nz,nes_sendbyword
 dec d
 jp nz,nes_sendbyword
 jp nes_nsend
nes_sendbybyte:
; 8-bit card not supported yet
 ld a,eSended
 pop hl
 pop de
 pop bc
 ei
 ret
nes_nsend:
 ld a,(ethbase)
 add a,EN0_ISR
 ld c,a
 ld hl,WaitForTimeout
nes_wait:               ; Should wait here about 20ms
 dec hl
 ld a,h
 cp 0
 jp z,nes_timedout
 in a,(c)
 and ENISR_RDC
 jp z,nes_wait
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
 ei
 ret
nes_timedout:
 ld a,(NetLogId)
 ld hl,nes_timeout
 call AddLog            ; This message is seen in Net log(1)
 call ne_reset
 call DP8390_init
 call DP8390_enable
 ld a,eTimedOut
 pop hl
 pop de
 pop bc
 ei
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
 ld a,$69
 pop hl
 pop bc
 ret
; end of ne_reset

; end of NEx000 compatible adapters driver
;**************************************************************


; end of Drivers
;**************************************************************


;**************************************************************
;
; code for TCP/IP & ARP support
;
;**************************************************************

; #defines
#define ARP_PACKET $0806
#define IP_PACKET  $0800

#define HWTYPE_ETH 1            ; No support for others than ethernet (probably)
#define OPCODE_ARPREQ 1         ; ARP-request
#define OPCODE_ARPREP 2         ; ARP-reply


; RAM at address $c000-$dfff
NETB            equ $c000       ;4KB of RAM for use of network
;
netBuffer       equ NETB+0      ;Reserves 12*256 bytes as buffer for received
                                ;and queue transmit packets
;
; Free 256bytes
;
netBufToc       equ NETB+3840   ;6*16 bytes
netBufT0        equ NETB+3840   ;16 bytes
netBufT1        equ NETB+3856   ;-
netBufT2        equ NETB+3872   ;-
netBufT3        equ NETB+3888   ;-
netBufT4        equ NETB+3904   ;-
netBufT5        equ NETB+3920   ;-
netBufStat      equ NETB+3936   ;12 bytes, 1 for each buffer page
netBufUsedPages equ NETB+3948   ;byte
netDataLen      equ NETB+3949   ;word
netDataAddr     equ NETB+3951   ;word
netCopyType     equ NETB+3953   ;byte
netIOCopyPort   equ NETB+3954   ;byte
netBufferStatus equ NETB+3955   ;byte
netBufferTemp   equ NETB+3956   ;byte
netBufTocId     equ NETB+3957   ;byte

;
#define nBufPages 12
#define nBufTocs 6
#define nBufTocMaxPages 6
#define nBufMaxSize 6*256
#define nBufTocSize 6*16
#define nBuf1TocSize 16
#define nBufTocStat 0           ;byte
#define nBufTocNPages 1         ;byte
#define nBufTocSize 2           ;word
#define nBufTocPages  4         ;6 bytes
#define nBufferRead 1
#define nBufferWrite 2
#define nBufPageReserved 1
#define nBufTocReserved 1
nBufCopyIO      equ 0
nBufCopyMem     equ 1
nBufNoSpace     equ $ff
nBufNoId        equ $ff

;**************************************************************
; Network buffer memory manager

; *******************************
; net_resetbuf
net_resetbuf:
 push af
 push bc
 push hl
 ld a,nBufTocSize+nBufPages+8
 ld c,0
 ld hl,netBufToc
netr_loop:
 ld (hl),c
 inc hl
 dec a
 jr nz,netr_loop
 pop hl
 pop bc
 pop af
 ret
; end of net_resetbuf

; *******************************
; net_checkspace
; Checks for free space in network buffer and if there is
; enough space returns free TOC's ID in (netBudTocId) and
; reg a, otherwise returns nBufNoSpace in reg a
net_checkspace:
 push bc
 push de
 push hl
#ifdef DEBUG_MM
 ld a,1
 ld c,SSeg1
 call n_to_7seg
#endif
 ld bc,(netDataLen)
 xor a
 cp b
 jp nz,ntc_nzero
 cp c
 ld a,nBufNoSpace
 jp z,ntc_end
ntc_nzero:
 dec bc
 ld a,nBufMaxSize/256
 cp b
 ld a,nBufNoSpace
 jp c,ntc_end
 jp z,ntc_end
 inc b
 ld a,(netBufUsedPages)
 add a,b
 dec a
 cp nBufPages
 ld a,nBufNoSpace
 jp nc,ntc_end
 ld hl,netBufToc+nBufTocStat
 ld de,nBuf1TocSize
 ld c,nBufTocs
 xor a
ntc_findfreetoc:
 cp (hl)
 jp z,ntc_fftoc
 add hl,de
 dec c
 jp nz,ntc_findfreetoc
 ld a,nBufNoSpace
 jp ntc_end
ntc_fftoc:
 ld a,nBufTocs
 sub c
 ld (netBufTocId),a
ntc_end:
#ifdef DEBUG_MM
 ld a,2
 ld c,SSeg1
 call n_to_7seg
#endif
 pop bc
 pop de
 pop hl
 ret
; end of net_checkspace

; *******************************
; net_allocbuffer
; This routine is mostly used by network drivers
; Allocates buffer with size stored in (netDataLen) and
; copies data to that buffer from address found in
; (netDataAddr), returns buffer id (netBufTocId).
; Type of copy must be stored in (netCopyType) and port
; which to copy from in (netIOCopyPort), types are memory
; and io.
; If there is no space left returns nBufNoSpace in reg a
net_allocbuffer:
 ld a,(netBufferStatus)         ; This should not happen!
 cp 0                           ; (That the buffer is already in use)
 ld a,nBufNoSpace
 ret nz
 ld a,nBufferWrite
 ld (netBufferStatus),a
 push bc
 push de
 push hl
#ifdef DEBUG_MM
 ld a,1
 ld c,SSeg2
 call n_to_7seg
 xor a
 out (SSeg3),a
#endif
 ld bc,(netDataLen)
 xor a
 cp b
 jp nz,nta_nzero
 cp c
 ld a,nBufNoSpace
 jp z,nta_end
nta_nzero:
 dec bc
 ld a,nBufMaxSize/256
 cp b
 ld a,nBufNoSpace
 jp c,nta_end
 jp z,nta_end
 inc b
 ld a,(netBufUsedPages)
 add a,b
 dec a
 cp nBufPages
 ld a,nBufNoSpace
 jp nc,nta_end
 ld hl,netBufToc+nBufTocStat
 ld de,nBuf1TocSize
 ld c,nBufTocs
 xor a
nta_findfreetoc:
 cp (hl)
 jp z,nta_fftoc
 add hl,de
 dec c
 jp nz,nta_findfreetoc
 ld a,nBufNoSpace
 jp nta_end
nta_fftoc:
; There is free TOC and enough free pages (free space)
; Now copy the data and set up TOC
#ifdef DEBUG_MM
 push bc
 ld a,4
 ld c,SSeg2
 call n_to_7seg
 pop bc
#endif
 ld a,nBufTocs
 sub c
 ld (netBufTocId),a             ; Save TOC ID
 ld a,(netBufUsedPages)
 add a,b
 ld (netBufUsedPages),a
 ld a,nBufTocReserved
 ld (hl),a
 inc hl
 ld (hl),b
 ld a,b
 ld (netBufferTemp),a
 inc hl
 ld de,(netDataLen)
 ld (hl),e
 inc hl
 ld (hl),d
 inc hl
 ex de,hl
 ld hl,netBufStat-1
 ld c,nBufPages+1
 exx
 ld de,(netDataAddr)
 exx
 xor a
nta_pgloop:
 inc hl
 dec c
 cp (hl)
 jp nz,nta_pgloop
 ld a,nBufPageReserved
 ld (hl),a
 ld a,nBufPages
 sub c
 ld (de),a
 inc de
 exx
 ld hl,netBuffer
 add a,h
 ld h,a
 ld a,(netCopyType)
 cp nBufCopyIO
 jp nz,nta_copyfrommem
nta_copyfromio:
#ifdef DEBUG_MM
 ld a,1
 ld c,SSeg3
 call n_to_7seg
#endif
 ld bc,(netIOCopyPort)
 ld a,(ethwrdlen)
 cp 2
 jp nz,nte_cpbybyte
 ld b,$80
 ld a,(netBufferTemp)
 dec a
 ld (netBufferTemp),a
 jp nz,nte_cpbyword
 ld a,(netDataLen)
 srl a
 ld b,a
nte_cpbyword:
 in a,(c)
 ld (hl),a
 inc hl
 in a,(ethcom)
 ld (hl),a
 inc hl
 dec b
 jp nz,nte_cpbyword
 ld a,(netBufferTemp)
 cp 0
 jp nz,nte_cpwnlast
 ld a,(netDataLen)
 and 1
 jp z,nte_cpwnlast
 in a,(c)
 ld (hl),a
nte_cpwnlast:
 jp nte_iocpend
nte_cpbybyte:
 ld b,0
 ld a,(netBufferTemp)
 dec a
 ld (netBufferTemp),a
 jp nz,nte_cpbnlast
 ld a,(netDataLen)
 ld b,a
nte_cpbnlast:
 inir                   ; Copy one page from io
nte_iocpend:
 exx
#ifdef DEBUG_MM
 push bc
 ld a,2
 ld c,SSeg3
 call n_to_7seg
 pop bc
#endif
 xor a
 dec b
 jp nz,nta_pgloop
 ld a,(netBufTocId)
 jp nta_end
nta_copyfrommem:
#ifdef DEBUG_MM
 ld a,4
 ld c,SSeg3
 call n_to_7seg
#endif
 ld bc,$100
 ex de,hl
 ldir                   ; Copy one page from mem
 ex de,hl
 exx
#ifdef DEBUG_MM
 push bc
 ld a,5
 ld c,SSeg3
 call n_to_7seg
 pop bc
#endif
 xor a
 dec b
 jp nz,nta_pgloop
 ld a,(netBufTocId)
nta_end:
 ld b,a
#ifdef DEBUG_MM
 ld a,8
 ld c,SSeg2
 call n_to_7seg
#endif
 xor a
 ld (netBufferStatus),a
 ld a,b
 pop hl
 pop de
 pop bc
 ret
; end of net_allocbuffer

; end of Memory manager
;**************************************************************

; *******************************
; nnet_init
nnet_init:
 call net_resetbuf
 ei
 ret
; end of nnet_init

; end of TCP/IP & ARP
;**************************************************************
