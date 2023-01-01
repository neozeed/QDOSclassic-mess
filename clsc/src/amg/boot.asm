	INCLUDE	'DEV/ASM/QDOS/DEFINES_inc'
	INCLUDE	'CLSC/SRC/CORE/BOOT_inc'
	INCLUDE	'DEV/ASM/AMG/HW_inc'
	INCLUDE	'CLSC/SRC/AMG/CLSC_inc'

*	INCLUDE	'..\..\..\DEV\ASM\QDOS\DEFINES_inc'
*	INCLUDE	'..\..\..\CLSC\SRC\CORE\BOOT_inc'
*	INCLUDE	'..\..\..\DEV\ASM\AMG\HW_inc'
*	INCLUDE	'..\..\..\CLSC\SRC\AMG\CLSC_inc'

	SECTION	BOOT

	XDEF	HW_RESET,HW_ENABLE
	XDEF	HW_MEMCHEK
	XDEF	HW_SERIALIZED,HW_WRITETHROUGH,HW_COPYBACK
	XDEF	HW_SERINIT,HW_SERJUNK,HW_SER1GETC

	XDEF	HW_VCTR_BEG
	XDEF	HW_VCTR.LVL2_NEW,HW_VCTR.LVL2_OLD
	XDEF	HW_VCTR.ILLG_NEW,HW_VCTR.ILLG_OLD
	XDEF	HW_VCTR.LEN

	XDEF	HW_KICK_BEG
	XDEF	HW_KICK
	XDEF	HW_KICK.LEN

	XDEF	HARDTAG

	XREF	CACHOFF,SETCACH

*******************************************************************
*
* BOOT_asm - AMIGA specific routines for bootstrap ROM
*	  - originated July 98 - Mark Swift
*	  - last modified 13/08/99 (MSW)

BASE:

*******************************************************************
*
* Begin custom vector routines

HW_VCTR_BEG:

*******************************************************************
*
*  Custom interrupt server for main 50Hz & external.interrupts

LVL2:

HW_VCTR.LVL2_NEW	EQU	(LVL2-HW_VCTR_BEG)

	ori.w	#$0700,sr	; disable further interrupts

	move.l	d0,-(a7)

	move.w	INTENAR,d0
	btst	#5,d0		; 50Hz ints enabled?
	beq.s	EXTRN_INT	; no, must be another.

	move.w	INTREQR,d0	; read interrupt request reg
	btst	#5,d0		; 50Hz interrupt?
	beq.s	EXTRN_INT	; nope.

;  server for 50 Hz vertical blank interrupt

FRAME_INT:
	move.w	#%0000000000100000,INTREQ ; clear interrupts

	move.b	#%00001000,PC_INTR ; signal 50Hz interrupt
				 ; in QL hardware

	bra.s	LVL2X

;  Let external interrupt server handle it
;  NOTE every driver MUST clear the relevant interrupt request!

EXTRN_INT:
	move.b	#%00010000,PC_INTR ; signal external interrupt
				 ; in QL hardware

LVL2X:
	move.l	(a7)+,d0

LVL2JMP:

HW_VCTR.LVL2_OLD	EQU	(LVL2JMP-HW_VCTR_BEG)+2

	DC.W	$4EF9,$0000,$0000  ; filled in later

*******************************************************************
*
*  Custom interrupt server for illegal interrupts

ILLG:

HW_VCTR.ILLG_NEW	EQU	(ILLG-HW_VCTR_BEG)

ILLGJMP:

HW_VCTR.ILLG_OLD	EQU	(ILLGJMP-HW_VCTR_BEG)+2

	DC.W	$4EF9,$0000,$0000  ; filled in later

*******************************************************************
*
*  Start of routines required for ROM swapping

NOPpad2:
	DCB.w ((0-(NOPpad2-BASE))&$3)/2,$4E71 ; pad to long word boundary

HW_KICK_BEG:

*******************************************************************
*
*  HARDWARE RESET : initialise hardware to factory defaults

HW_RESET:
	move.b	#$7F,CIAA_ICR	; no ints from CIA-A
	move.b	#$7F,CIAB_ICR	; no ints from CIA-B
	move.w	#$7FFF,INTREQ	; clear interrupt requests
	move.w	#$7FFF,INTENA	; disable interrupts
	move.w	#$07FF,DMACON	; no DMA, no blitter prio'ty
	clr.b	$de0000		; no slow bus errors

;  initialise hard-coded structures - (bad practice, but quick)

CLR_BP:
	lea	BPLANE1,a0	; clear R,G & B bitplanes
	move.w	#$1FFF,d0
CLR_BPLUP:
	clr.l	(a0)+
	dbra	d0,CLR_BPLUP

	clr.b	AV.CIAA_ICR	; clear mirror CIA variables
	clr.b	AV.CIAB_ICR
	clr.b	AV.CIAA_MSK
	clr.b	AV.CIAB_MSK

	rts

*******************************************************************
*
* End custom vector routines

NOPpad3:
	DCB.w ((0-(NOPpad3-BASE))&$3)/2,$4E71 ; pad to long word boundary

HW_VCTR_END:

HW_VCTR.LEN	EQU	(HW_VCTR_END-HW_VCTR_BEG)

*******************************************************************
*
*  KICK start a 'SOFT' ROM - reboots the machine with new ROM
*
*  Before entry, allocate some memory, copy this routine into the
*  end of the allocation and load the prior $18000 bytes of RAM
*  with the new ROM. Then run the routine from the RAM copy.

KICK:

HW_KICK	EQU	(KICK-HW_KICK_BEG)

	lea	HW_KICK_BEG(pc),a1
	move.l	-(a1),d0 	; restore ROM length
	sub.l	d0,a1		; address of new ROM
	sub.l	a0,a0		; copy to address $0

	lsr.l	#2,d0
	subq.l	#1,d0		; initialise count

KICKLUP:
	move.l	(a1)+,(a0)+	; store new ROM
	dbra	d0,KICKLUP

	moveq	#0,d0
	dc.l	$4E7B0801	; movec d0,vbr
	dc.l	$4E7B0002	; movec d0,cacr
	dc.l	$4E7B0003	; movec d0,tc
	dc.l	$4E7B0004	; movec d0,itt0
	dc.l	$4E7B0005	; movec d0,itt1
	dc.l	$4E7B0006	; movec d0,dtt0
	dc.l	$4E7B0007	; movec d0,dtt1

	bsr	HW_RESET

	move.l	(0),a7
	move.l	a7,d0		; Calculate start of
	andi.w	#-$8000,d0	; system variables
	move.l	d0,a6
	clr.l	(a6)		; remove SV.IDENT
	move.l	(4),a0
	jmp	(a0)		; reset

*******************************************************************
*
*  End of routines required for ROM swapping

NOPpad4:
	DCB.w ((0-(NOPpad4-BASE))&$3)/2,$4E71 ; pad to long word boundary

HW_KICK_END:

HW_KICK.LEN EQU	(HW_KICK_END-HW_KICK_BEG)

*******************************************************************
*
*  HARDWARE ENABLE : initialise hardware to for use,
*		   enable relevant interrupts/DMA

HW_ENABLE:
	move.w	#%1100000000100000,INTENA ; enable 50Hz int

	move.b	AV.FLGS1,d0
	andi.b	#%00111111,d0
	move.b	d0,AV.FLGS1	; allow blitter activity

;	move.b	#$??,$a7(a6)	; machine type $?? == 'AMG'
	rts

*******************************************************************
*
*  MEMORY CHECK : check how much memory is installed
*
*  On the Amiga, the loader program sets RAM base (at this point a6)
*  and RAM top (SV_RAMT). We simply look for holes in the memory map
*  and alter the relevant tables.

HW_MEMCHEK:
	movem.l	d0/a1-a5,-(a7)

	cmp.l	#$1000000,a6
	bge.s	MEMCHEKX 	; memory this far up is contiguous

;  Link unused memory (system memory has to be contiguous), into
;  common heap. Allocate ranges that do not contain memory as
;  'used'.

	move.l	SV_RAMT(a6),a3	; don't check memory beyond

; find last free space in common heap

	lea	SV_CHPFR(a6),a5	; first free space in heap
	subq.l	#4,a5

	bra.s	CHPJMP

CHPLUP:
	adda.l	d0,a5		; next free space

CHPJMP:
	move.l	4(a5),d0
	bne.s	CHPLUP

	move.l	SV_FREE(a6),a4

; link free CHIP RAM into common heap

	bsr.s	chip_ram 	; how much CHIP RAM?

	bsr	MEMLINK		; link memory into common heap

	cmp.l	a2,a3
	ble.s	MEMSKIP

; link expansion memory into common heap

	lea	$200000,a1

ERAM_LUP:
	bsr	expansion_ram	; how much EXPANSION RAM?

	bsr	MEMLINK		; link memory into common heap

	move.l	a2,a1
	adda.l	#$10000,a1	; next 64K

	cmp.l	#$A00000,a1
	blt.s	ERAM_LUP

	cmp.l	a1,a3
	ble.s	MEMSKIP

; link RANGER memory into common heap

	bsr	ranger_ram

	bsr	MEMLINK

MEMSKIP:
	clr.l	4(a5)		; dislocate last block of RAM
				; from common heap.

	move.l	0(a4),d0 	; length of last block of RAM
	add.l	a4,d0
	move.l	d0,a2		; calculate maximum RAMTOP

	move.l	a4,a1		; base of free area

; a1 now holds base of free area, a2 max RAM, a3 RAMTOP


; find first usable entry in slave table

	move.l	a1,d0
	addi.l	#$1FF,d0
	sub.l	a6,d0		; Slave blocks start at the
	andi.w	#-$200,d0	; sys vars and are each 512
	lsr.l	#6,d0		; bytes long.

; invalidate all slave block entries outside system RAM

	lea	SV_STACT(a6),a1	; first address in slave table
	lea	0(a1,d0.l),a4	; first usable address

INI_TBL1:
	clr.l	(a1)+
	cmpa.l	a4,a1
	blt.s	INI_TBL1

	move.l	a1,SV_BTPNT(a6)	; Store most recent block.

MEMCHEKX:
	movem.l	(a7)+,d0/a1-a5
	rts

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; find how much CHIP RAM is installed

; on exit:

;   a1=0
;   a2=CHIP top

chip_ram:
	movem.l	d0-d1/a0-a1,-(a7)

	suba.l	a1,a1
	move.l	(a1),a0
	clr.l	(a1)
	suba.l	a2,a2
	move.l	#-$D2B4977,d1
	bra.s	LF801E0

LF801DE:
	move.l	d0,(a2)

LF801E0:
	lea	$4000(a2),a2

	cmpa.l	#$200000,a2	; ...or maximum CHIP RAM
	beq.s	LF801FA

	move.l	(a2),d0
	move.l	d1,(a2)
	nop
	cmp.l	(a1),d1
	beq.s	LF801FA

	cmp.l	(a2),d1
	beq	LF801DE

LF801FA:
	move.l	d0,(a2)
	move.l	a0,(a1)

	movem.l	(a7)+,d0-d1/a0-a1

	rts

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; find how much EXPANSION RAM is installed

; The machine has not been reset since expansion.library of
; AmigaDOS initialised the expansion memory. Therefore when you
; enter	QDOS the expansion RAM should still be mapped in (if
; there's any installed).

; on entry

;   a1=EXPANSION base

; on exit:

;   a1=EXPANSION base
;   a2=EXPANSION top

expansion_ram:
	movem.l	d1-d2/a0/a4,-(a7)

	move.l	a7,a4		; save for later

	dc.w	$2078,$0008	; move.l  $08.w,a0 (bus err)
	lea	exp_EXIT(pc),a2
	dc.w	$21CA,$0008	; move.l  a2,$08.w

	move.l	a1,a2

exp_NEXT:
	move.w	(a2),d2
	moveq	#1,d1

exp_CHEK:
	move.w	d1,(a2)
	cmp.w	(a2),d1
	bne.s	exp_EXIT

	lsl.w	#1,d1
	bne.s	exp_CHEK

	move.w	d2,(a2)
	adda.l	#$10000,a2	; next 64K

	cmpa.l	#$A00000,a2
	blt.s	exp_NEXT 	; ...or max expansion RAM

exp_EXIT:
	dc.w	$21C8,$0008	; move.l  a0,$08.w

	move.l	a4,a7		; tidy up stack

	movem.l	(a7)+,d1-d2/a0/a4
	rts

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; find how much RANGER RAM is installed

; on exit:

;   a1=$C00000
;   a2=RANGER top

ranger_ram:
	movem.l	d0-d1/a0/a4,-(a7)

	lea	$C00000,a1
	lea	$DC0000,a0

	move.l	a1,a2

	adda.l	#$40000,a1	; a1 holds $C40000

LF80330:
	move.l	a2,a4
	adda.l	#$40000,a4

	move.w	INTENAR,d1	; store interrupts
	move.w	-$F66(a4),d0	; store (RAM) contents

	move.w	#$7FFF,$9A-$1000(a4)	; mirror custom chips?
	tst.w	$1C-$1000(a4)
	bne.s	LF80352			; ...possible RAM

	move.w	#$BFFF,$9A-$1000(a4)
	cmpi.w	#$3FFF,$1C-$1000(a4)
	bne.s	LF80352			; ...possible RAM

; at this point we definitely have a mirror of the custom chips

LF8038A:
	move.w	#$7FFF,INTENA	; disable all interrupts

	ori.w	#%1100000000000000,d1	; enable interrupts
	move.w	d1,INTENA

	bra.s	LF80390			; ...and exit

LF80352:

; may be RAM

	move.l	#$F2D4,d1
	move.w	d1,-$F66(a4)	; store test number into RAM
	cmp.w	-$F66(a4),d1
	bne.s	LF80390		; exit if RAM test failed

	move.l	#$B698,d1
	move.w	d1,-$F66(a4)	; store different test number
	cmp.w	-$F66(a4),d1
	bne.s	LF80390		; exit if RAM test failed

; definitely RAM - but may be a mirror of $C00000-$C40000

	cmpa.l	a1,a4
	beq.s	LF80384		; addresses same? not mirror

	cmp.w	-$F66(a1),d1	; mirror of previous RAM?
	bne.s	LF80384		; no ...must be real RAM

	move.l	#$F2D4,d1
	move.w	d1,-$F66(a4)	; store test number into RAM

	cmp.w	-$F66(a1),d1	; mirror of previous RAM?
	bne.s	LF80384		; no ...must be real RAM

; at this point, RAM at (a1) has proven to be a mirror of RAM at (a4)

LF80380:
	move.w	d0,-$F66(a4)	; restore RAM contents
	bra.s	LF80390		; ...and exit

LF80384:
	move.w	d0,-$F66(a4)	; restore RAM contents

	move.l	a4,a2

	cmpa.l	a2,a0		; check against upper bound
	bhi	LF80330

LF80390:
	suba.l	#$40000,a1	; a1 holds $C00000

	movem.l	(a7)+,d0-d1/a0/a4

LF8039C:
	rts

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; link memory into common heap as 'free' heap.

; a1 holds base, a2 the upper limit of memory range.

MEMLINK:
	movem.l	d0-d1/a3,-(a7)

	cmp.l	a1,a2		; memory range valid?
	ble.s	MEMLINKX

	cmp.l	a4,a1
	blt.s	MEMLINK2 	; no previous range

; must link the HOLES between memory ranges as 'allocated' heap

	move.l	a4,a3		; find 'gap' between last
	add.l	0(a4),a3 	; free range and this one.
	move.l	a1,d0
	sub.l	a3,d0
	bne.s	MEMLINK1

; no gap between last memory range and this one, so concatenate

	movea.l	a4,a1
	bra.s	MEMLINK5

MEMLINK1:
	moveq	#16,d1		; length of header
	sub.l	d1,a3
	add.l	d1,d0
	move.l	d0,0(a3) 	; store a header for memory hole
	clr.l	$4(a3)
	clr.l	$8(a3)
	clr.l	$C(a3)

	sub.l	d1,0(a4) 	; reduce length of last range

MEMLINK2:
	cmp.l	SV_FREE(a6),a1	; common heap extended beyond
	bge.s	MEMLINK3 	; lower bound of memory range?

	move.l	SV_FREE(a6),a1	; new lower bound for memory

MEMLINK3:
	cmp.l	a4,a1
	bne.s	MEMLINK4

	movea.l	a5,a4

MEMLINK4:
	move.l	a1,d0
	sub.l	a4,d0		; store relative pointer from
	move.l	d0,4(a4) 	; previous block

	move.l	a4,a5
	move.l	a1,a4
	move.l	a4,SV_FREE(a6)	; update SV_FREE

MEMLINK5:
	move.l	a2,d0
	sub.l	a1,d0		; find length of memory block

	move.l	d0,0(a1) 	; store length
	clr.l	4(a1)		; zero pointer to next free block
	clr.l	$8(a1)		; owner
	clr.l	$C(a1)		; location to set/clr when removed

MEMLINKX:
	movem.l	(a7)+,d0-d1/a3

	rts

*******************************************************************
*
*  TTR/ACU OPTIONS : set cache options for memory map

HW_COPYBACK:
	movem.l	d0-d2/d7,-(a7)
	move.l	#$00FFC020,d2	; other memory = cachable, copyback (*amiga)
	bra.s	TTRACU

HW_WRITETHROUGH:
	movem.l	d0-d2/d7,-(a7)
	move.l	#$00FFC000,d2	; other memory = cachable, writethrough (amiga)
	bra.s	TTRACU

HW_SERIALIZED:
	movem.l	d0-d2/d7,-(a7)
	move.l	#$00FFC040,d2	; other memory = non-cachable, serialized (amiga)

TTRACU:
	bsr	CACHOFF		; disable caches
	move.l	d0,d7		; save cacr value

	move.l	#$0000C040,d1	; Serialize 0-16 Mb
	dc.w	$4E7B,$1006	; movec d1,DTT0
	dc.w	$4E7B,$1004	; movec d1,ITT0

	move.l	d2,d1
	dc.w	$4E7B,$1007	; movec d1,DTT1
	dc.w	$4E7B,$1005	; movec d1,ITT1

	move.l	d7,d0
	bsr	SETCACH

	movem.l	(a7)+,d0-d2/d7
	rts

*******************************************************************
*
*  SERIAL INIT : initialise serial hardware for use

HW_SERINIT:
	movem.l	d0/d7,-(a7)

	move.b	CIAB_DDRA,d7
	andi.b	#%00000111,d7
	ori.b	#%11000000,d7	; DTR(7),RTS(6) as outputs &
	move.b	d7,CIAB_DDRA	; CD(5),CTS(4),DSR(3) inputs

	move.w	#B_9600,D0
	bset	#15,D0		; 9 bit receive data
	move.w	D0,SERPER	; Set baudrate

	move.b	CIAB_PRA,d0
	and.b	#%01111111,d0
	move.b	d0,CIAB_PRA	; enable receive (DTR(7) high)

	movem.l	(a7)+,d0/d7
	rts

*******************************************************************
*
*  SERIAL JUNK : junk data on serial lines

HW_SERJUNK:

HW_SERJUNKL:
	btst	#(14-8),SERDATR	; receive buffer full?
	beq.s	HW_SERJUNKX	; nope, quit

	move.w	SERDATR,D0	; throw data
	bra.s	HW_SERJUNKL

HW_SERJUNKX:
	rts

*******************************************************************
*
*  SERIAL CHAR IN : get one char from serial hardware

HW_SER1GETC:
	btst	#(14-8),SERDATR	; receive buffer full?
	beq.s	HW_SER1GETC	; nope, lup

	MOVE.W	SERDATR,D0	; get data
	rts

*******************************************************************
*
* Pad out to long words

NOPpad5:
	DCB.w ((0-(NOPpad5-BASE))&$3)/2,$4E71 ; pad to long word boundary

*******************************************************************

	END
