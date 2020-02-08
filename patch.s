; AS configuration and original binary file to patch over
	CPU 68000
	PADDING OFF
	ORG		$000000
	BINCLUDE	"prg.orig"

; Free space at the end of the ROM.
ROM_FREE = $03FD84

; For free play, we will use the first unused switch of DSWA. When set, Free
; Play is enabled.
DSWALoc = $240B45  ; <-- free play when bit 0 is set.

; The sub CPU handles credit counting, and places the credit count in shared memory.
SubCpuCreditLoc = $140005

; This is copied from the sub CPU for the main CPU to act on.
CreditCountLoc = $240B4B

; Function that prints a string selected by d0. Location and other attributes
; are predetermined by a mapping table at $01500C.
StringMetaPrint = $005184

; Macro for checking free play ----------------------------
FREEPLAY macro
	move.l	d1, -(sp)
	btst.b	#0, (DSWALoc).l
	bne	.freeplay_is_enabled
	bra	+

.freeplay_is_enabled:
	move.l	(sp)+, d1
	ENDM

POST macro
	move.l	(sp)+, d1
	ENDM

; Fix checksum
; TODO: This was done by hand - it would be best if this was done at build time
	ORG	$0000C0
	dc.l	$9BDA71C3
	ORG	$0000C4
	dc.l	$20FD8682

; Disable credit copy from sub CPU's count.
	ORG	$000314
	jsr	credit_count_from_sub_cpu
	nop
	nop

; Disable subtraction of credits from sub CPU's count.
	ORG	$000EE8
	jsr	sub_credit_on_start
	nop
	nop
	nop
	nop

; Hide credit count in free play
	ORG	$005088
	jmp	draw_credit_count

; Change "UNUSED" string pointer to Free Play for DIP settings screen
	ORG	$015220
	dc.l	free_play_string


	ORG	ROM_FREE
free_play_string:
	dc.b	"FREE PLAY", $FF
	align	2

credit_count_from_sub_cpu:
	FREEPLAY
	move.b	#$02, (CreditCountLoc).l
	rts

/	POST
	move.b	(SubCpuCreditLoc).l, (CreditCountLoc).l
	rts

sub_credit_on_start:
	FREEPLAY
	rts

/	POST
	; D4 contains game start cost
	move.b	(SubCpuCreditLoc).l, d0
	sub.b	d4, d0
	move.b	d0, (SubCpuCreditLoc).l
	rts

draw_credit_count:
	FREEPLAY
	jmp	($0051B4).l

/	POST
	move.w	#$FF, ($240B4E).l
	moveq	#6, d0 ; select credit string
	jsr	(StringMetaPrint).l
	jmp	($005096).l
