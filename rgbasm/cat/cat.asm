;
;                               CAT       
;                        MAIN SOURCE FILE                      
;                        Beta Version 1.1 
;
;	All Source, Routines and Data CopyRight 1998 John Pericos.
;	Any use of said copyright for commercial distribution is 
;	STRICTLY prohibited.  This document is provided for internal 
;	use only. Any violation of said copyright is punishable BY LAW.
;
;	Source successfully built with RGBDS v0.4.1
;	Reference: https://rgbds.gbdev.io/
;
;	John Pericos [john.pericos@gmail.com]


; Variables SetUp
memvar		EQU		$CC00
dist        EQU		memvar
delay       EQU		memvar+1
wait        EQU		memvar+2


SECTION	"ROOT",ROM0[$0000]


; Set all irq vectors to do nothing.

SECTION	"VBlank_IRQ",ROM0[$0040] 		; VBlank IRQ
	call	vblank_int
	reti
SECTION	"LCDC_Status_IRQ",ROM0[$0048] 	; LCDC Status IRQ
	call	lcdc_int
	reti
SECTION	"Timer_Overflow",ROM0[$0050] 	; Timer Overflow
	reti
SECTION	"Serial_Transfer ",ROM0[$0058]  ; Serial Transfer 
	reti
SECTION	"p1thru4",ROM0[$0060]			; Who cares about this one...
	reti


; ****************************************************************************************
; boot loader jumps to here.
; ****************************************************************************************
SECTION	"header",ROM0[$0100]
	nop
	jp	begin

; ****************************************************************************************
; ROM HEADER
; ****************************************************************************************

;***********************************************
; Nintendo Scrolling Title Graphic
;***********************************************
DB $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
DB $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
DB $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E

DB $00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00
				
DB $00,$00,$00						; Not used
DB $00								; Cart type  ROM ONLY
DB $00								; ROM Size   32k
DB $00								; RAM Size    0k
DB "J","P"     						; Maker ID
DB $01								; Version = 1
DB $64         						; complement check
DB $ff,$ff							; checksum

SECTION	"start",ROM0[$0150]

begin:
	di								; disable interrupts

	ld     sp,$0fff4				; set inital stack value.


	ld     a, %01110111
	ldh    [$40],a					; turn off screen.

	ld     a,%01011100     			; set lcdc int to occur when LY = LCY
	ldh    [$48],a

	ld     a,0
	ld     [dist],a
	ld     [wait],a
	ld     [delay],a
	ldh    [$43],a

 	ld     a,16						; set line at which lcdc interrupt occurs
	ldh    [$45],a

	ld     a,%01000100				; set lcdc int to occur when LY = LCY
	ldh    [$41],a

	ld     a,%00000011				; enable vblank and lcdc interrupts
	ldh    [$ff],a

									; turn screen on.
    ld     a, %10010111
	ldh    [$40],a
									; bg char data = $8000
									; bg screen data = $9800,	obj constuction = 8*16, obj = on
									; bg = on.
	call   move_sprite
	call   move_char
	call   move_text
	call   nor_col

	ei								; enable interrupts

pok:	
	jr    pok						; let the interrupts do their thing from here

;============================================================================

vblank_int:
	push   af						; save any modified registers because this
									; can be called in the middle of any routine
	ld     a,[dist]
	ldh    [$43],a        

	pop    af      					; restore any modified registers because this
									; can be called in the middle of any routine
	ret

;============================================================================

lcdc_int:
	push	af						; save any modified registers because this
									; can be called in the middle of any routine

	call    joy
	call    joy

	pop     af						; restore any modified registers because this
									; can be called in the middle of any routine
	ret

;============================================================================                                                                          *

hey:
	ld     a,[wait]
	inc    a
	cp     $3d
	jr     nz,hs1
	call   wr
	ld     a,[$fe02]
	add    a,6
	ld     [$fe02],a
	ld     a,[$fe06]
	add    a,6
	ld     [$fe06],a
	ld     a,[$fe0a]
	add    a,6
	ld     [$fe0a],a

	ld     a,[$fe02]
	cp     $7c
	jr     nz,hc1
	call   wr
	ld     a,$64
	ld     [$fe02],a
	add    a,2
	ld     [$fe06],a
	add    a,2
	ld     [$fe0a],a

hc1:
	ld     a,0
hs1:
	ld     [wait],a     
	ret

joy:
	ld     a,$20
	ldh    [$00],a         			; turn on P15
	ldh    a,[$00]         			; delay
	ldh    a,[$00]

	cpl
	and    $0f
	swap   a
	ld     b,a

	ld     a,$10
	ldh    [$00],a         			; turn on P14
	ldh    a,[$00]         			; delay
	ldh    a,[$00]
	ldh    a,[$00]
	ldh    a,[$00]
	ldh    a,[$00]
	ldh    a,[$00]

	cpl
	and    $0f
	or     b
	swap   a
			
	; cp     $8
	; jp     z,up
	; cp     $4
	; jp     z,down
	cp     $2
	jp     z,left
	cp     $1
	jp     z,right
	call   hey
	ret

	;up:
	; ld      a,[Y]
	; inc     a
	; ld      [Y],a
	; ret

	;down:
	; ld      a,[Y]
	; dec     a
	; ld      [Y],a
	; ret

left:
	ld      a,[dist]
	dec     a
	ld      [dist],a

	call   wr
	ld     a,%00100000      		; flip cat facing left
	ld     [$fe03],a
	ld     [$fe07],a
	ld     [$fe0b],a
	ld     a,$58
	ld     [$fe01],a
	ld     a,$48
	ld     [$fe09],a

	ld     a,[delay]
	inc    a
	cp     $08
	jr     nz,ss1

	call   wr
	ld     a,[$fe02]
	add    a,6
	ld     [$fe02],a
	ld     a,[$fe06]
	add    a,6
	ld     [$fe06],a
	ld     a,[$fe0a]
	add    a,6
	ld     [$fe0a],a

	ld     a,[$fe02]
	cp     $64
	jr     z,ok1
	cp     $7c
	jr     nz,rc1
ok1:
	call   wr
	ld     a,$40
	ld     [$fe02],a
	add    a,2
	ld     [$fe06],a
	add    a,2
	ld     [$fe0a],a

rc1:
	ld     a,0
ss1:
	ld     [delay],a     
	ret

right:
	ld     a,[dist]
	inc    a
	ld     [dist],a
	call   wr
	ld     a,%00000000        		; flip cat facing right
	ld     [$fe03],a
	ld     [$fe07],a
	ld     [$fe0b],a
	ld     a,$48
	ld     [$fe01],a
	ld     a,$58
	ld     [$fe09],a

	ld     a,[delay]
	inc    a
	cp     $08
	jr     nz,ss2
	call   wr
	ld     a,[$fe02]
	add    a,6
	ld     [$fe02],a
	ld     a,[$fe06]
	add    a,6
	ld     [$fe06],a
	ld     a,[$fe0a]
	add    a,6
	ld     [$fe0a],a

	ld     a,[$fe02]
	cp     $64
	jr     z,ok2
	cp     $7c
	jr     nz,rc2
ok2:
	call   wr
	ld     a,$40
	ld     [$fe02],a
	add    a,2
	ld     [$fe06],a
	add    a,2
	ld     [$fe0a],a

rc2:
	ld     a,0
ss2:
	ld     [delay],a     
	ret

nor_col:							; Sets the colors to normal palette
	ld     a,%11111001    			; grey 3=11 [Black]
									; grey 2=10 [Dark grey]
									; grey 1=01 [Ligth grey]
									; grey 0=00 [Transparent]
	ldh    [$47],a
	ld     a,%11111111
	ldh    [$48],a
	ret
wr:  
	push   af						; Save reg A and flags
wr2:
	ldh    a,[$41]
	and    2
	jr     nz,wr2
	pop    af						; Restore reg A and flags
	ret

move_sprite:
	ld     hl,$fe00
	ld     bc,sprite
	ld     d,12

msprite_loop:
	ld     a,[bc]
	call   wr
	ld     [hli],a
	inc    bc
	dec    d
	jp     nz,msprite_loop

	ld     de,$8400                 ; BG-tiles position  
	ld     hl,sprite_data
	ld     c,60                     ; Nr. of tiles
loadsprites:
	ld     b,16                     ; 16 bytes per tile 
loadonesprite:
	ld     a,[hli]
	call   wr
	ld     [de],a
	inc    de
	dec    b
	jr     nz,loadonesprite
	dec    c
	jr     nz,loadsprites
	ret

move_text:
	ld     hl,$9800
	ld     bc,backdrop_map

	ld     d,$00
	ld     e,$04           

mtext_loop:
	ld     a,[bc]
	call   wr
	ld     [hli],a
	inc    bc
	dec    d
	jp     nz,mtext_loop
	dec    e
	jp     nz,mtext_loop
	ret

move_char:
	ld     bc,$8000
	ld     hl,backdrop_gfx
	ld     a,55
	ld     d,a

mchar_loop1:
	ld     e,16

mchar_loop2:
	ld     a,[hli]
	call   wr
	ld     [bc],a
	inc    bc
	dec    e
	jr     nz,mchar_loop2
	dec    d
	jr     nz,mchar_loop1
	ret


sprite:
DB $88,$48,$64,$00,$88,$50,$66,$00,$88,$58,$68,$00

sprite_data:
include "sprites.asm"

backdrop_gfx:
include "backdrop_gfx.asm"

backdrop_map:
include "backdrop_map.asm"


;============================================================================
.end


