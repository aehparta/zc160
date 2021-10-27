;**************************************************************
;
; FLASH.asm
;       version 008
;
; Here is routines and such for network mostly
; Some other miscellaneous code also... 

; Enable some of these to use LEDs and 7segments for debugging
;#define DEBUG_MM        ; DEBUG when running memory manager code
;#define DEBUG_TCPIP     ; DEBUG when running TCP/IP code
#define DEBUG_HANDLEPACKET      ;DEBUG when running TCP/IP code

#ifndef OS_FILE
#define ALONE
#endif

#ifdef ALONE
#include "OSdef.h"
#include "drivers.asm"
#endif

; Jump table
net_init:
 jp nnet_init
net_checkspace:
 jp nnet_checkspace
net_allocbuffer:
 jp nnet_allocbuffer
net_freebuffer:
 jp nnet_freebuffer
net_resetbuf:
 jp nnet_resetbuf
net_handlepacket:
 jp nnet_handlepacket

;**************************************************************
;
; code for TCP/IP & ARP support
;
;**************************************************************

; #defines
#define ARP_OR_IP  $08
#define ARP_PACKET $06
#define IP_PACKET  $00

#define ARP_REQUEST 1
#define ARP_REPLY 2
#define ARP_HWTYPE_ETH 1

#define IP_PROTO_ICMP 1

#define IP_DEFAULT_TTL 64
#define IP_ICMP_ECHO_TTL 32
#define IP_ICMP_MAX_SIZE 80     ; Maximum size of incoming icmp-packet
                                ; which is still handled
                                ; (Absolut maximum is 254)
                                ; This is here for now becose of some bug in 
                                ; ip-packet handling or network drivers
#define ICMP_ECHO_REPLY 0
#define ICMP_ECHO 8
#define ICMP_DROP 7
#define ICMP_UNREACHABLE 3
#define ICMP_DEFAULT_REPLY_TYPE ICMP_ECHO_REPLY
#define ICMP_DEFAULT_REPLY_CODE 0
;
#define HWTYPE_ETH 1            ; No support for others than ethernet (probably)
#define OPCODE_ARPREQ 1         ; ARP-request
#define OPCODE_ARPREP 2         ; ARP-reply
;
#define nBufPages 12
#define nBufTocs 8
#define nBufTocMaxPages 6
#define nBufPageSize 256
#define nBufMaxSize nBufTocMaxPages*nBufPageSize
#define nBuf1TocSize 10
#define nBufTocSize nBufTocs*nBuf1TocSize
;
#define nBufTocStat 0           ;byte
#define nBufTocNPages 1         ;byte
#define nBufTocLen 2           ;word
#define nBufTocPages  4         ;6 bytes
;
#define nBufferRead 1
#define nBufferWrite 2
#define nBufPageReserved 1
#define nBufTocReserved 1
; ARP table
#define nArpTables 16
#define nArp1TabSize 12
#define nArpTabSize nArpTables*nArp1TabSize
#define nArpTabStat 0           ;byte
#define nArpTabDate 1           ;byte
#define nArpTabMAC 2            ;6 bytes
#define nArpTabIp 8             ;4 bytes
; Ethernet packet header
; DLC header
#define ehDlcSize 14
#define ehTarget 0              ;6 bytes
#define ehSource 6              ;6 bytes
#define ehType 12               ;word
; ARP specific header
#define ehArpSize 28
#define ehArpHwType 14          ;word
#define ehArpProtocol 16        ;word
#define ehArpHwLen 18           ;byte
#define ehArpProtoLen 19        ;byte
#define ehArpOpCode 20          ;word
#define ehArpSourceHw 22        ;6 bytes
#define ehArpSourceIp 28        ;4 bytes, when using IP-protocol
#define ehArpTargetHw 32        ;6 bytes
#define ehArpTargetIp 38        ;4 bytes, when IP...
; IP specific header
#define ehIpSize 20
#define ehIpVhl 14              ;byte
#define ehIpTos 15              ;byte
#define ehIpLen 16              ;word
#define ehIpId 18               ;word
#define ehIpOffset 20           ;word
#define ehIpTtl 22              ;byte
#define ehIpProto 23            ;byte
#define ehIpChecksum 24         ;word
#define ehIpSource 26           ;4 bytes
#define ehIpTarget 30           ;4 bytes
; ICMP header
#define ehIcmpSize 8
#define ehIcmpType 34           ;byte
#define ehIcmpCode 35           ;byte
#define ehIcmpChecksum 36       ;word
#define ehIcmpId 38             ;word
#define ehIcmpSeqNumb 40        ;word
;
nBufCopyIO      equ 0
nBufCopyMem     equ 1
nBufNoSpace     equ $ff
nBufNoId        equ $ff
;
nArpDate        equ 40

; RAM at address $c000-$dfff
NETB            equ $c000       ;4KB of RAM for use of network
NETBL           equ NETB+$fff
;
netBuffer       equ NETB+0      ;Reserves 12*256 bytes as buffer for received
                                ;and queue transmit packets
;
netBufToc       equ NETB+3072   ;8*10 bytes
netArpTable     equ NETB+3152   ;16*12 bytes
;Misc
netIcmpReplyType        equ NETBL-57    ;byte
netIcmpReplyCode        equ NETBL-56    ;byte
netChksumAddr   equ NETBL-55    ;word
netChksumCount  equ NETBL-53    ;word
;Here are settings for this systems NIC
IpMasked        equ NETBL-51    ;*
IpAddress       equ NETBL-47    ;4 bytes
NetMask         equ NETBL-43    ;*
GateWay         equ NETBL-39    ;*
DNS             equ NETBL-35    ;*
;
netMacAddress   equ NETBL-31    ;6 bytes, for MAC address
netIpAddress    equ NETBL-25    ;4 bytes, for IP address
netBufStat      equ NETBL-21    ;12 bytes, 1 for each buffer page
netBufUsedPages equ NETBL-9     ;byte
netDataLen      equ NETBL-8     ;word
netDataAddr     equ NETBL-6     ;word
netCopyType     equ NETBL-4     ;byte
netIOCopyPort   equ NETBL-3     ;byte
netBufStatus    equ NETBL-2     ;byte
netBufTemp      equ NETBL-1     ;byte
netBufTocId     equ NETBL-0     ;byte
;

default_ip_settings:
def_ip          .db 111,112,113,217
def_mask        .db 255,255,255,0
def_gw          .db 0,0,0,0
def_dns         .db 0,0,0,0

;**************************************************************
; Network buffer memory manager

; *******************************
; net_resetbuf
nnet_resetbuf:
 push af
 push bc
 push hl
 ld bc,nBufTocSize-1
 ld hl,netBufToc
 ld de,netBufToc+1
 ld (hl),0
 ldir
 ld bc,nBufPages-1
 ld hl,netBufStat
 ld de,netBufStat+1
 ld (hl),0
 ldir
 ld bc,nArpTabSize-1
 ld hl,netArpTable
 ld de,netArpTable+1
 ld (hl),0
 ldir
 xor a
 ld (netBufUsedPages),a
 ld (netBufStatus),a
 ld a,nBufNoSpace
 ld (netBufTocId),a
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
nnet_checkspace:
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
nnet_allocbuffer:
 ld a,(netBufStatus)            ; This should not happen!
 cp 0                           ; (That the buffer is already in use)
 ld a,nBufNoSpace
 ret nz
 ld a,nBufferWrite
 ld (netBufStatus),a
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
 ld (netBufTemp),a
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
 ld a,(netBufTemp)
 dec a
 ld (netBufTemp),a
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
 ld a,(netBufTemp)
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
 ld a,(netBufTemp)
 dec a
 ld (netBufTemp),a
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
 ld (netBufStatus),a
 ld a,b
 pop hl
 pop de
 pop bc
 ret
; end of net_allocbuffer

; *******************************
; net_freebuffer
; Marks free a TOC which ID must be stored in (netBufTocId)
nnet_freebuffer:
 push af
 push bc
 push ix
 push iy
 ld ix,netBufToc
 ld bc,nBuf1TocSize
 ld a,(netBufTocId)
 inc a
ntf_gettotoc:
 dec a
 jp z,ntf_gottotoc
 add ix,bc
 jp ntf_gettotoc
ntf_gottotoc:
 ld a,(ix+nBufTocStat)
 cp 0
 jp z,ntf_end
 xor a
 ld b,a
 ld (ix+nBufTocStat),a
 ld c,(ix+nBufTocNPages)
 ld a,(netBufUsedPages)
 sub c
 ld (netBufUsedPages),a
 ld a,c
 ld iy,netBufStat
ntf_markpagesfree:
 ld c,(ix+nBufTocPages)
 add iy,bc
 ld (iy),b
 inc ix
 dec a
 jp nz,ntf_markpagesfree
ntf_end:
 pop iy
 pop ix
 pop bc
 pop af
 ret
; end of net_freebuffer

; end of Memory manager
;**************************************************************

; *******************************
; net_init
nnet_init:
 di
 push hl
 push de
 push bc
 call net_resetbuf
; Set default ip, netmask, gateway and dns
 ld hl,default_ip_settings
 ld de,IpAddress
 ld bc,4*4
 ldir
; Logical and between ip and netmask for later use
 ld ix,NetMask
 ld a,(IpAddress)
 and (ix)
 ld (IpMasked),a
 ld a,(IpAddress+1)
 and (ix+1)
 ld (IpMasked+1),a
 ld a,(IpAddress+2)
 and (ix+2)
 ld (IpMasked+2),a
 ld a,(IpAddress+3)
 and (ix+3)
 ld (IpMasked+3),a
; Set icmp reply type and code
 ld a,ICMP_DEFAULT_REPLY_TYPE
 ld (netIcmpReplyType),a
 ld a,ICMP_DEFAULT_REPLY_CODE
 ld (netIcmpReplyCode),a
; Send kind of 'test packet'
 xor a
 ld (ethDataPage),a
 ld a,(etxStartPage)
 ld (ethDataPage+1),a
 ld hl,MIN_ETH_PACKET_SIZE
 ld (ethDataLen),hl
 ld hl,test_packet
 ld (ethDataAddr),hl
 call ethSend
;
 pop bc
 pop de
 pop hl
 ei
 ret
; end of nnet_init

; *******************************
; net_handlepacket
; Should be called when a packet arrives from network
; Packet TOC ID must be stored in netBufTocId
nnet_handlepacket:
 push af
 push bc
 push de
 push hl
 push iy
 push ix
; Find out what kind of packet we are dealing with
#ifdef DEBUG_HANDLEPACKET
 ld a,0
 ld c,SSeg1
 call n_to_7seg
 ld a,$ff
 out (SSeg2),a
 out (SSeg3),a
 out (SSeg4),a
#endif
 ld ix,netBufToc
 ld bc,nBuf1TocSize
 ld a,(netBufTocId)
 inc a
nh_gettotoc:
 dec a
 jp z,nh_gottotoc
 add ix,bc
 jp nh_gettotoc
nh_gottotoc:
 ld a,(ix+nBufTocStat)  ;Check, just for sure, that this
 cp 0                   ;TOC is really in use
 jp z,nh_end
 ld b,(ix+nBufTocPages)
 ld c,0
 ld iy,netBuffer
 add iy,bc              ;Now iy has the start address of packet's first page
; Check out that the packet is using a protocol which is
; supported
 ld a,ARP_OR_IP
 cp (iy+ehType)
 jp nz,nh_packethandled
 ld a,ARP_PACKET 
 cp (iy+ehType+1)
 jp z,nh_handlearppacket
 ld a,IP_PACKET 
 cp (iy+ehType+1)
 jp z,nh_handleippacket
; Now the packet should be handled and the buffer can be set free
nh_drop:
nh_packethandled:
 ld a,(netBufTocId)
 call net_freebuffer
;
nh_end:
#ifdef DEBUG_HANDLEPACKET
 ld a,2
 ld c,SSeg1
 call n_to_7seg
#endif
 pop ix
 pop iy
 pop hl
 pop de
 pop bc
 pop af
 ret
; Handle an arp-packet
nh_handlearppacket:
#ifdef DEBUG_HANDLEPACKET
 ld a,0
 ld c,SSeg2
 call n_to_7seg
#endif
; Here could be checked if the packet is too small, but
; the NIC drivers should already have checked that the packet
; is atleast 60 bytes long.
; ld a,(ix+nBufTocLen+1)
; cp 0
; jp nz,nh_enough
; ld a,(ix+nBufTocLen)
; cp ehDlcSize+ehArpSize
; jp c,nh_packethandled
;nh_enough:
 xor a
 cp (iy+ehArpOpCode)
 jp nz,nh_packethandled
 ld a,(iy+ehArpOpCode+1)
 cp ARP_REQUEST
 jp z,nh_arprequest
 cp ARP_REPLY
 jp nz,nh_packethandled
nh_arpreply:
#ifdef DEBUG_HANDLEPACKET
 ld a,0
 ld c,SSeg3
 call n_to_7seg
#endif
 jp nh_packethandled
nh_arprequest:
#ifdef DEBUG_HANDLEPACKET
 ld a,8
 ld c,SSeg3
 call n_to_7seg
#endif
; Check that is the ip-address this node's
 ld a,(IpAddress)
 cp (iy+ehArpTargetIp)
 jp nz,nh_packethandled
 ld a,(IpAddress+1)
 cp (iy+ehArpTargetIp+1)
 jp nz,nh_packethandled
 ld a,(IpAddress+2)
 cp (iy+ehArpTargetIp+2)
 jp nz,nh_packethandled
 ld a,(IpAddress+3)
 cp (iy+ehArpTargetIp+3)
 jp nz,nh_packethandled
#ifdef DEBUG_HANDLEPACKET
 ld a,9
 ld c,SSeg3
 call n_to_7seg
#endif
; This ARP-request was meant for this node
; Set opcode to ARP-reply
; xor a
; ld (iy+ehArpOpCode),a
 ld a,ARP_REPLY
 ld (iy+ehArpOpCode+1),a
; Set target MAC-address (horrifying long, but faster than a loop)
#define nh__set_target_mac_address(fix) ld a,(iy+ehArpSourceHw+fix)
#defcont \ ld (iy+ehArpTargetHw+fix),a
#defcont \ ld (iy+ehTarget+fix),a
 nh__set_target_mac_address(0)
 nh__set_target_mac_address(1)
 nh__set_target_mac_address(2)
 nh__set_target_mac_address(3)
 nh__set_target_mac_address(4)
 nh__set_target_mac_address(5)
; Set source MAC-address
#define nh__set_source_mac_address(fix) ld a,(ethhwaddr+fix)
#defcont \ ld (iy+ehArpSourceHw+fix),a
#defcont \ ld (iy+ehSource+fix),a
 nh__set_source_mac_address(0)
 nh__set_source_mac_address(1)
 nh__set_source_mac_address(2)
 nh__set_source_mac_address(3)
 nh__set_source_mac_address(4)
 nh__set_source_mac_address(5)
; Set target IP-address
#define nh__set_target_ip(fix) ld a,(iy+ehArpSourceIp+fix)
#defcont \ ld (iy+ehArpTargetIp+fix),a
 nh__set_target_ip(0)
 nh__set_target_ip(1)
 nh__set_target_ip(2)
 nh__set_target_ip(3)
; Set source IP-address
#define nh__set_source_ip(fix) ld a,(IpAddress+fix)
#defcont \ ld (iy+ehArpSourceIp+fix),a
 nh__set_source_ip(0)
 nh__set_source_ip(1)
 nh__set_source_ip(2)
 nh__set_source_ip(3)
; Send this packet
#ifdef DEBUG_HANDLEPACKET
 ld a,$a
 ld c,SSeg3
 call n_to_7seg
#endif
 xor a
 ld (ethDataPage),a
 ld a,(etxStartPage)
 ld (ethDataPage+1),a
 ld hl,MIN_ETH_PACKET_SIZE
 ld (ethDataLen),hl
 ld (ethDataAddr),iy
 call ethSend
#ifdef DEBUG_HANDLEPACKET
 ld a,$b
 ld c,SSeg3
 call n_to_7seg
#endif
 jp nh_packethandled
; Handle an ip-packet
nh_handleippacket:
#ifdef DEBUG_HANDLEPACKET
 ld a,1
 ld c,SSeg2
 call n_to_7seg
#endif
; Check that the packet is valid
 ld a,$45
 cp (iy+ehIpVhl)
 jp nz,nh_drop
; Here should be checked that the ip packet lenght is valid,
; but it is left out for now
; No ip fragments allowed
 ld a,(iy+ehIpOffset)
 and $3f
 jp nz,nh_drop
; Check if the packet is for us
 ld a,(IpAddress)
 cp (iy+ehIpTarget)
 jp nz,nhip_arpupdate
 ld a,(IpAddress+1)
 cp (iy+ehIpTarget+1)
 jp nz,nhip_arpupdate
 ld a,(IpAddress+2)
 cp (iy+ehIpTarget+2)
 jp nz,nhip_arpupdate
 ld a,(IpAddress+3)
 cp (iy+ehIpTarget+3)
 jp nz,nhip_arpupdate
; This packet is for us
; Check checksum
; Skip cheksum for now
 ld a,IP_PROTO_ICMP
 cp (iy+ehIpProto)
 jp z,nhip_icmp
nhip_arpupdate:
; Use netmask to the packet ip
; and compare packet and this node ip address with netmask
; to see if the packet came from LAN
 push ix
 ld ix,IpMasked
 ld hl,NetMask
 ld a,(iy+ehIpSource)
 ld (netIpAddress),a
 and (hl)
 cp (ix)
 jp nz,nhip_notlan
 ld a,(iy+ehIpSource+1)
 ld (netIpAddress+1),a
 inc hl
 and (hl)
 cp (ix+1)
 jp nz,nhip_notlan
 ld a,(iy+ehIpSource+2)
 ld (netIpAddress+2),a
 inc hl
 and (hl)
 cp (ix+2)
 jp nz,nhip_notlan
 ld a,(iy+ehIpSource+3)
 ld (netIpAddress+3),a
 inc hl
 and (hl)
 cp (ix+3)
 jp nz,nhip_notlan
 pop ix
; Packet came from LAN, update ARP-table
; Copy the packet ip and mac
#define nh__copy_mac(fix) ld a,(iy+ehSource+fix)
#defcont \ ld (netMacAddress+fix),a
 nh__copy_mac(0)
 nh__copy_mac(1)
 nh__copy_mac(2)
 nh__copy_mac(3)
 nh__copy_mac(4)
 nh__copy_mac(5)
 call arp_update
 jp nh_packethandled
nhip_notlan:
 pop ix
 jp nh_packethandled
; Handle icmp-packet
nhip_icmp:
#ifdef DEBUG_HANDLEPACKET
 ld a,0
 ld c,SSeg3
 call n_to_7seg
#endif
; Check that is the icmp echo-reply
; denied totaly and if it is then
; just drop the packet
 ld a,(netIcmpReplyType)
 cp ICMP_DROP
 jp z,nh_drop
; Limit icmp-packet size
; If size is bigger than ICMP_MAX_SIZE
; then just drop the packet
; (Absolut maximum is 254)
 ld a,(ix+nBufTocLen+1)
 cp 0
 jp nz,nh_drop
 ld a,(ix+nBufTocLen)
 cp IP_ICMP_MAX_SIZE+1
 jp nc,nh_drop
 ld a,ICMP_ECHO
 cp (iy+ehIcmpType)
 jp z,nhicmp_echo
 ld a,(netIcmpReplyType)
 cp (iy+ehIcmpType)
 ld a,(netIcmpReplyCode)
 cp (iy+ehIcmpCode)
 jp z,(nhicmp_reply
 jp nhip_arpupdate
nhicmp_echo:
#ifdef DEBUG_HANDLEPACKET
 ld a,0
 ld c,SSeg4
 call n_to_7seg
#endif
; Just answer to the echo with echo reply
 ld a,ICMP_ECHO_REPLY
 ld (iy+ehIcmpType),a
 ld a,IP_ICMP_ECHO_TTL
 ld (iy+ehIpTtl),a
#define nhicmp__mac(fix) ld a,(iy+ehSource+fix)
#defcont \ ld (iy+ehTarget+fix),a
#defcont \ ld a,(ethhwaddr+fix)
#defcont \ ld (iy+ehSource+fix),a
#define nhicmp__ip(fix) ld a,(iy+ehIpSource+fix)
#defcont \ ld (iy+ehIpTarget+fix),a
#defcont \ ld a,(IpAddress+fix)
#defcont \ ld (iy+ehIpSource+fix),a
 nhicmp__mac(0)
 nhicmp__mac(1)
 nhicmp__mac(2)
 nhicmp__mac(3)
 nhicmp__mac(4)
 nhicmp__mac(5)
 nhicmp__ip(0)
 nhicmp__ip(1)
 nhicmp__ip(2)
 nhicmp__ip(3)
; Set up sending parameters
 xor a
 ld (ethDataPage),a
 ld (ethDataLen+1),a
 ld a,(etxStartPage)
 ld (ethDataPage+1),a
 ld a,(ix+nBufTocLen)
 ld (ethDataLen),a
 xor a
 ld (ethDataLen+1),a
 ld (ethDataAddr),iy
 ld a,(uptime)
 add a,(iy+ehIpId)
 ld (iy+ehIpId),a
 add a,(iy+ehIpId+1)
 ld (iy+ehIpId+1),a
; Calculate checksums
 xor a
 ld (iy+ehIpChecksum),a
 ld (iy+ehIpChecksum+1),a
 ld (iy+ehIcmpChecksum),a
 ld (iy+ehIcmpChecksum+1),a
 push iy
 ld bc,ehIpSize
 ld (netChksumCount),bc
 ld bc,ehDlcSize
 add iy,bc
 ld (netChksumAddr),iy
 call chksum
 ld de,(netChksumAddr)
 ld a,(ix+nBufTocLen)
 sub ehDlcSize+ehIpSize
 ld (netChksumCount),a
 xor a
 ld (netChksumCount+1),a
 ld bc,ehIpSize
 add iy,bc
 ld (netChksumAddr),iy
 call chksum
 pop iy
 ld (iy+ehIpChecksum),d
 ld (iy+ehIpChecksum+1),e
 ld a,(netChksumAddr+1)
 ld (iy+ehIcmpChecksum),a
 ld a,(netChksumAddr)
 ld (iy+ehIcmpChecksum+1),a
; Send
 call ethSend
 jp nhip_arpupdate
nhicmp_reply:
#ifdef DEBUG_HANDLEPACKET
 ld a,1
 ld c,SSeg4
 call n_to_7seg
#endif
 jp nhip_arpupdate
; end of net_handlepacket

; *******************************
; chksum
; Calculates checksum of example ip-header
; Data address in (netChksumAddr) and count in (netChksumCount)
; Returns checksum in (netChksumAddr)
chksum:
 push af
 push bc
 push de
 push hl
 push ix
 ld hl,0
 ld ix,(netChksumAddr)
 ld bc,(netChksumCount)
 srl b
 rr c
 inc b
 or a
chks_loop:
 ld d,(ix)
 ld e,(ix+1)
 inc ix
 inc ix
 adc hl,de
 dec c
 jp nz,chks_loop
 dec b
 jp nz,chks_loop
 ld de,0
 adc hl,de
 ld a,(netChksumCount)
 and 1
 jp z,chks_noodd
 ld d,(ix)
 ld e,0
 adc hl,de
 ld de,0
 adc hl,de
chks_noodd:
 ld a,h
 xor $ff
 ld (netChksumAddr+1),a
 ld a,l
 xor $ff
 ld (netChksumAddr),a
 pop ix
 pop hl
 pop de
 pop bc
 pop af
 ret
; *******************************
; arp_update
; Updates ARP-table
; Incoming packets IP-address must be stored in (netIpAddress)
; and MAC-address in (netMacAddress)
arp_update:
; Pushs and pops should be enabled if this routine
; is called from else where than net_handlepacket
; push af
; push bc
; push de
; push hl
; push iy
; push ix
 ld c,nArpTables+1
 ld de,nArp1TabSize
 ld ix,netArpTable-nArp1TabSize
aup_findupdate:
 xor a
 add ix,de
 dec c
 jp z,aup_noold
 cp (ix+nArpTabStat)
 jp z,aup_findupdate
 ld a,(netIpAddress)
 cp (ix+nArpTabIp)
 jp nz,aup_findupdate
 ld a,(netIpAddress+1)
 cp (ix+nArpTabIp+1)
 jp nz,aup_findupdate
 ld a,(netIpAddress+2)
 cp (ix+nArpTabIp+2)
 jp nz,aup_findupdate
 ld a,(netIpAddress+3)
 cp (ix+nArpTabIp+3)
 jp nz,aup_findupdate
 jp aup_end
aup_noold:
 ld c,nArpTables+1
 ld d,0
 ld e,nArp1TabSize
 ld ix,netArpTable-nArp1TabSize
 xor a
aup_findempty:
 add ix,de
 dec c
 jp z,aup_noempty
 cp (ix+nArpTabStat)
 jp nz,aup_findempty
 jp aup_ipend
aup_noempty:
 ld c,nArpTables
 ld d,0
 ld e,nArp1TabSize
 ld iy,netArpTable
 ld ix,netArpTable
 ld a,(ix+nArpDate)
aup_findoldest:
 add iy,de
 dec c
 jp z,aup_ipend
 cp (iy+nArpTabDate)
 jp c,aup_findoldest
 xor a
 cp (iy+nArpTabStat)
 ld a,(ix+nArpTabDate)
 jp z,aup_findoldest
 push iy
 pop ix
 ld a,(ix+nArpTabDate)
 jp aup_findoldest
aup_ipend:
 ld bc,(netIpAddress)
 ld de,(netIpAddress+2)
 ld (ix+nArpTabIp),c
 ld (ix+nArpTabIp+1),b
 ld (ix+nArpTabIp+2),e
 ld (ix+nArpTabIp+3),d
aup_end:
 ld a,nArpDate
 ld bc,(netMacAddress)
 ld de,(netMacAddress+2)
 ld hl,(netMacAddress+4)
 ld (ix+nArpTabStat),a
 ld (ix+nArpTabDate),a
 ld (ix+nArpTabMAC),c
 ld (ix+nArpTabMAC+1),b
 ld (ix+nArpTabMAC+2),e
 ld (ix+nArpTabMAC+3),d
 ld (ix+nArpTabMAC+4),l
 ld (ix+nArpTabMAC+5),h
; pop ix
; pop iy
; pop hl
; pop de
; pop bc
; pop af
 ret
; end of arp_update

; end of TCP/IP & ARP
;**************************************************************
#ifdef ALONE
.end
#endif
