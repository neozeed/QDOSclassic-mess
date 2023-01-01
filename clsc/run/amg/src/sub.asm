BPLCON1 EQU	$DFF102
INTENA	EQU	$DFF09A
INTREQ	EQU	$DFF09C
DMACON	EQU	$DFF096
DMACONR EQU	$DFF002
BLACK	 EQU	  $0000
RED	 EQU	  $0F00
GREEN	 EQU	  $00F0
BLUE	 EQU	  $000F
WHITE	 EQU	  $0FFF
YELLOW	 EQU	  $0FF0
CYAN	 EQU	  $00FF
MAGENTA  EQU	  $0F0F
COLOR00  EQU	  $DFF180

_LVOSuperState	EQU	-150
AttnFlags	EQU	296
CACRF_EnableI	EQU	0
CACRF_EnableD	EQU	8

	section text	code

; m/c subroutine to do all the dirty work for L_QDOS.
; the following is passed on the stack:
;
; a0 $04(A7) sub_dst	  : safe address for the subroutine that moves things about
; a1 $08(A7) ql_lomem	  : lomem for QDOS
; a2 $0C(A7) ql_himem	  : himem for QDOS
; a3 $10(A7) rom_dst	  : address where to move the ROM images
; a4 $14(A7) qp 	  : address where the ROM images are currently loaded
; d0 $1C(A7) rom[0].rlen  : length of QDOS
; d1 $20(A7) rom_len	  : sum of the lengths of the ROM images
; d2 $24(A7) rom[1].rlen  : length of MAIN ROM
; d3 $28(A7) ql_ssp	  : SSP for QDOS
; d4 $2C(A7) qldate	  : date for QDOS

_sub:
	movea.l $4,a6
	jsr	_LVOSuperState(a6) ; enter supervisor mode
	move.l	d0,d7

	or	#$0700,sr	; disable all interrupts

	clr.b	$BFEA01 	; reset CIA-A event counter
	clr.b	$BFE901
	clr.b	$BFE801

waitblit:
	move.w	DMACONR,d7
	btst	#14,d7		; wait for blitter DMA to stop
	bne.s	waitblit

	move.w	#$3FFF,INTENA	; disable all possible interrupt sources
	move.w	#$3FFF,INTREQ	; clear all pending interrupts
	move.w	#$01FF,DMACON	; disable DMA (bitplane, copper, blitter)

	move.w	#0,BPLCON1	; scroll value=0. Messed up by rolling titles?

	movea.l $4,a6
	move.w	AttnFlags(a6),d4

	btst	#$0,d4		; branch if <'010 or more
	beq.s	go_on2

	btst	#3,d4
	beq.s	go_on1

	moveq	#0,d1		; MMU off
	dc.w	$4E7B,$1003	; movec d1,TCR

go_on1:
	moveq	#0,d0
	dc.w	$4E7B,$0801	; movec a6,VBR

	bsr	CLRALL		; clear instruction & data caches

	moveq	#0,d0		; new cache bits
	move.l	#CACRF_EnableI|CACRF_EnableD,d1 ; mask
	bsr	CTRLCACHE

go_on2:
	movem.l $4(a7),a0-a4
	movem.l $18(a7),d0-d4

	lea	_subtoclear-_theworks(a0),a7

	lea	_theworks(pc),a6
	move.l	#(_dummy-_theworks)>>1-1,d6
	move.l	a0,d7
mvlup:
	move.w	(a6)+,(a0)+
	dbra	d6,mvlup

	move.l	d7,a0
	jmp	(a0)

; -------------------------------------------------------------
;  clear data and instruction caches

CLRALL:
	movem.l d0-d1/d4,-(a7)

	move.l	#$808,d1
	bra.s	L0000C3E

; -------------------------------------------------------------
;  clear data caches

CLRDATA:
	movem.l d0-d1/d4,-(a7)

	moveq	#$8,d1
	rol.l	#8,d1

; -------------------------------------------------------------
;  clear cache(s). d1=$800 - clear data cache
;		   d1=$808 - clear data and instruction caches

;	      and on 68040 - update memory from caches

L0000C3E:
	ori.w	#$0700,sr	; interrupts off

	movea.l $4,a6
	move.w	AttnFlags(a6),d4

	btst	#$1,d4		; branch if '020 or more
	bne.s	L0000C48

	bra.s	CLRCACHEX	; ...otherwise exit

L0000C48:
	btst	#$3,d4
	bne.s	L0000C68	; '040 ?

	and.l	#$808,d1
	ori	#$700,sr
	dc.w	$4E7A,$0002	; movec cacr,d0
	or.l	d1,d0
	dc.w	$4E7B,$0002	; movec d0,cacr

	ifd	ShoCach
	move.l	d7,-(a7)
	move.w	#$8000,d7
WAITRED:
	move.w	#$0F00,$DFF180
	move.w	#0,$DFF180
	dbra	d7,WAITRED
	move.l	(a7)+,d7
	endif

	bra.s	CLRCACHEX

L0000C68:
	btst	#$3,d1
	bne.s	L0000C74

	dc.w	$F478		; CPUSHA dc ('040 only)
				; update memory from cache
	bra.s	L0000C76

L0000C74:
	dc.w	$F4F8		; CPUSHA ic/dc ('040 only)
				; update memory from caches
L0000C76:

CLRCACHEX:
	movem.l (a7)+,d0-d1/d4
	tst.l	d0

	rts

; -------------------------------------------------------------
;  set bits in cacr d0=bits to set d1=bits to clear/alter

CTRLCACHE:
L0000C8E:
	movem.l d2-d4,-(a7)

	moveq	#$0,d3

	movea.l $4,a6
	move.w	AttnFlags(a6),d4

	btst	#$1,d4		; exit if not at least '020
	beq.s	L0000CAE

	and.l	d1,d0
	or.w	#$808,d0	; signal clear data & instr.
	not.l	d1

L0000CB6:
	ori	#$700,sr
	dc.w	$4E7A,$2002	; movec cacr,d2
	btst	#$3,d4
	beq.s	L0000CD0	; skip if not '040

	swap	d2		; '040 code
	ror.w	#8,d2
	rol.l	#1,d2
	move.l	d2,d3
	rol.l	#4,d3
	or.l	d3,d2

L0000CD0:
	move.l	d2,d3		; cache register to d3
	and.l	d1,d2		; mask off changed bits
	or.l	d0,d2		; or in set bits
	btst	#$3,d4
	beq.s	L0000CEC	; skip if not '040

	ror.l	#1,d2		; '040 code
	rol.w	#8,d2
	swap	d2
	and.l	#$80008000,d2
	nop
	dc.w	$F4F8		; CPUSHA ic/dc ('040 only)
				; update memory from caches

L0000CEC:
	nop
	dc.w	$4E7B,$2002	; movec d2,cacr
	nop

L0000CAE:
	move.l	d3,d0

	movem.l (a7)+,d2-d4
	rts

; --------------------------------------------------------------
_theworks:
	move.w	#MAGENTA,COLOR00

	move.l	d0,d5

	sub.l	a0,a0
	lsr.l	#1,d0
	subq.l	#1,d0

qmvlup:
	move.w	(a4),(a0)+	; move QDOS code
	clr.w	(a4)+
	dbra	d0,qmvlup

	cmpa.l	a2,a3		; relocate QDOS
	beq.s	newbit

	move.l	d5,a5
	move.w	-(a5),d0
	bra.s	rloctst

rloclup:
	moveq	#0,d6
	move.w	-(a5),d6
	move.l	d6,a0
	move.l	(a0),d6
	add.l	a2,d6
	sub.l	#$600,d6
	move.l	d6,(a0)

rloctst:
	dbra	d0,rloclup

	move.l	a2,a5		; move QDOS
	move.l	d5,d0
	movea.l #$600,a0
	sub.l	a0,d0
	lsr.l	#1,d0
	subq.l	#1,d0

zmvlup:
	move.w	(a0),(a5)+
	clr.w	(a0)+
	dbra	d0,zmvlup

newbit:
	lea	$1F400,a0
	move.l	d2,d0
	lsr.l	#1,d0
	subq.l	#1,d0

xmvlup:
	move.w	(a4),(a0)+	; move MAIN code
	clr.w	(a4)+
	dbra	d0,xmvlup

	move.l	a4,a5

	tst.l	d1
	beq.s	clrmem

	cmp.l	a5,a3	; check which direction we should
	blt.s	rmvdn	; move roms and act accordingly.

rmvup:
	add.l	d1,a5	; after last word in ROM code
	add.l	d1,a3	; after last word of destination area
	lsr.l	#1,d1

	bra.s	rmvuptst

rmvuphilup:
	swap	d1

rmvuplolup:
	move.w	-(a5),-(a3)   ; move the ROM code
	clr.w	2(a5)

rmvuptst:
	dbra	d1,rmvuplolup
	swap	d1
	dbra	d1,rmvuphilup
	bra.s	clrmem

rmvdn:
	lsr.l	#1,d1

	bra.s	rmvdntst

rmvdnhilup:
	swap	d1

rmvdnlolup:
	move.w	(a5),(a3)+   ; move the ROM code
	clr.w	(a5)+

rmvdntst:
	dbra	d1,rmvdnlolup
	swap	d1
	dbra	d1,rmvdnhilup

clrmem:
	moveq	#0,d0
	bra.s	getrange

clrlup:
	move.l	d0,(a3)+

clrtst:
	cmp.l	a5,a3
	blt.s	clrlup

getrange:
	move.l	(a7)+,a3
	move.l	(a7)+,a5
	cmp.l	d0,a5
	bne.s	clrtst

doql:
	move.l	$4,a0	; get initial PC

	move.l	d3,a7	; get initial SSP
	move.l	a7,$0	; and store it

	and.l	#-$8000,d3	; calculate address of system variables
	move.l	d3,a6

	move.w	#$D254,(a6)	; set QDOS id
	move.l	a1,$04(a6)	; store lomem
	move.l	a2,$20(a6)	; store himem

	move.l	d4,$18000	; store date

	move.w	#GREEN,COLOR00

	jmp   (a0)	; start QDOS

	rts

;   this area is filled by the c code with the address ranges
;   that it is necessary to clear (a maximum of 8, zero terminated).

_subtoclear:
	dcb.l	18,0

_dummy:
	xdef	_sub
	xdef	_subtoclear
	xdef	_dummy
	xdef	_theworks

	end
