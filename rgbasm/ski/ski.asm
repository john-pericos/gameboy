;
;                          DOWNHILL SKI
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
varbase		EQU		$c100
xpos        EQU     varbase
ypos		EQU		varbase+1
tree_row	EQU		varbase+2
level_ptr	EQU		varbase+3
hiscore		EQU		varbase+4
score		EQU		varbase+9

KeyStart	EQU		$7
KeySelect	EQU		$6
KeyB		EQU		$5
KeyA		EQU		$4
KeyDown		EQU		$3
KeyUp		EQU		$2
KeyLeft		EQU		$1
KeyRight	EQU		$0

UpdateOAM   EQU		$ff80

SECTION	"ROOT",ROM0[$0000]

; Sprite data and tile codes for ski guy
ski_sprite:
DB 40,74,160,0
DB 40,82,162,0
DB 40,90,168,0
DB 40,98,170,0
DB 56,74,164,0
DB 56,82,166,0
DB 56,90,172,0
DB 56,98,174,0

ski_straight:
DB 160,162,168,170,164,166,172,174

ski_left:
DB 176,178,184,186,180,182,188,190

ski_right:
DB 192,194,200,202,196,198,204,206

ski_dead:
DB 224,226,232,234,228,230,236,164


; Set all irq vectors to do nothing.

SECTION	"VBlank_IRQ",ROM0[$0040] ; VBlank IRQ
	reti
SECTION	"LCDC_Status_IRQ",ROM0[$0048] ; LCDC Status IRQ
	reti
SECTION	"Timer_Overflow",ROM0[$0050] ; Timer Overflow
	reti
SECTION	"Serial_Transfer ",ROM0[$0058] ; Serial Transfer 
	reti
SECTION	"p1thru4",ROM0[$0060]; Who cares about this one...
	reti

; Some misc data for the game

snowpatch:
DB 0,0,0,0
DB 0,0,0,0
DB 0,0,0,0
DB 0,0,0,0

gameover_set:
DB 72,71,164,0
DB 72,79,164,0
DB 72,87,164,0
DB 72,95,164,0

hitext:
DB	"TODAYS@HISCORE"

thetext:
DB	"@@[@DOWNHILL@SKI@[@@"
DB	"@@BY@JOHN@PERICOS@@@"
DB	"PRESS@@@@@@@@@@START"

tree:
DB 0,210,216,0
DB 209,211,217,219
DB 212,214,220,222
DB 0,215,221,0

snowman:
DB 224,226,232,234
DB 225,227,233,235
DB 228,230,236,238
DB 229,231,237,0

overmusic:						; Play the notes down for gameover sound
 ld		a,20
om:
 push 	af
 ld		bc,100		
 call	delay		
 call get_notes
 call nice_note
 pop	af
 dec	a
 jp		nz,om
 ret

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
;Nintendo Scrolling Title Graphic
;***********************************************
 DB $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
 DB $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
 DB $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E

	 
DB "  DOWNHILL SKI  "
				
DB $00,$00,$00	; Not used
DB $00			; Cart type  ROM ONLY
DB $00			; ROM Size   32k
DB $00			; RAM Size    0k
DB "J","P"     	; Maker ID
DB $01			; Version = 1
DB $64         	; complement check
DB $ff,$ff		; checksum

SECTION	"start",ROM0[$0150]

begin:
 di						; Disable IRQs
 ld		sp,$d900		; Put the stack somewere

 ld		a,%00000000		; No IRQs at all
 ldh	[$ff],a

 call	waitvbl			; Must be in VBL before turning the screen off.
 ld		a,%00000000		; LCD Controller = Off [No picture on screen]
 ldh	[$40],a
 
 ld 	a,136			; Set Window bottom right corner for score counter
 ldh 	[$4a],a
 ld 	a,127
 ldh 	[$4b],a

 call	set_volume

 ld		hl, 0 			; Clear out sprite table
 ld		de, $c000
 ld		bc, 40*4
 call	fill	

 ld 	a, $80			; Reset the hiscore storage
 ld 	[hiscore],a
 ld 	[hiscore+1],a
 ld 	[hiscore+2],a
 ld 	[hiscore+3],a
 ld 	[hiscore+4],a

 call	move_grafix

 call	initdma

start:					; This is where to jump to after 'gameover'

 call	waitvbl			; Must be in VBL before turning the screen off.
 ld		a,%00000000		; LCD Controller = Off [No picture on screen]
 ldh	[$40],a

 ld		bc,200			; Set delay counter
 call	delay			; wait a sec!!!!

 ld 	a,$80			; Reset the score storage
 ld 	[score],a
 ld 	[score+1],a
 ld 	[score+2],a
 ld 	[score+3],a
 ld 	[score+4],a

 ld		hl,ski_straight  ; Set ski guy straight 		
 call	spritechange

 sub	a				; Misc standard init things..
 ldh	[$41],a			; LCDC Status
 ldh	[$42],a			; Screen scroll Y=0
 ldh	[$43],a			; Screen scroll X=0
 ld 	[xpos],a		; X=0
 ld 	[ypos],a		; Y=0
 ld     [level_ptr],a	; Reset to beginning of level

 call	normal_color	; Normal palette
 
 call 	Set_title		; Set title screen			

 call	UpdateOAM		; Update sprites

 ld		a,%11110111 	; Switch screen items on
 ldh	[$40],a

 call	reset_player

getready:
 call	player
 call 	getkeys   		; Wait for player to hit 'Start'
 bit 	KeyStart,a
 jp 	z, getready
 ld		bc,200			; Set delay counter
 call	delay			; wait a sec!!!!

 ld		hl, 0 			; Clear out 'today hiscore'
 ld		de, $9800+544
 ld		bc, 20
 call	fill	
					
 ld		de,$9c00		; Display '0000' score counter
 ld		hl,score				
 ld		bc,5				
 call	move

mainloop:				; Main ingame loop
 
 call 	skimovement
 
 call 	collision

 call 	down

 call 	UpdateOAM

 call	pause

 jp 	mainloop

pause:
 call 	getkeys   		; Wait for player to hit 'Start' to pause
 bit 	KeyStart,a
 ret 	z
 ld		hl, $0100
 call	nice_note
 ld		bc,200			; Set delay counter
 call	delay			; wait a sec!!!!

pausing:
 call 	getkeys   		; Wait for player to hit 'Start'
 bit 	KeyStart,a
 jp 	z, pausing
 ld		hl, $0100
 call	nice_note
 ld		bc,200			; Set delay counter
 call	delay			; wait a sec!!!!
 ret

skimovement	:			; Change direction of ski player via pad keys
 call 	getkeys   
 bit 	KeyA,a
 call	nz,doubledown       
 bit 	KeyRight,a
 jp 	nz,right
 bit 	KeyLeft,a
 jp 	nz,left
 call 	waitvbl

 ld		hl,ski_straight  ; Just stay straight if no key is pressed		
 call	spritechange
 ret

right:					; Turn ski guy right
 push 	af
 ld 	a,[xpos]
 inc 	a
 ldh	[$43],a	
 ld 	[xpos],a

 call	waitvbl
 ld		hl,ski_right    	
 call	spritechange
 pop 	af
 ret

left:					; Turn ski guy left
 push 	af
 ld 	a,[xpos]
 dec 	a
 ldh	[$43],a	
 ld 	[xpos],a 

 call	waitvbl
 ld		hl,ski_left		  	
 call	spritechange
 pop 	af
 ret

spritechange:		; Change image of sprites
 ld 	de,$c002
 ld 	bc,8
sc:
 ld     a,[hli]
 ld     [de],a
 inc    de
 inc	de
 inc    de
 inc	de
 dec    bc
 ld     a,b
 or		c
 jr     nz, sc
 ret

doubledown:			; Move ski guy down hill!!!
 call 	down
 call 	down
 call 	down
 call 	down
 call 	IncScore	; Increment score counter as ski guy progresses the level
 ret

down:
 push 	af
 call 	waitvbl
 ld 	a,[ypos]
 inc 	a
 ldh	[$42],a	
 ld 	[ypos],a 

 call 	plot_trees

 pop 	af
 ret

collision:
 ld 	b, 0		; Calculate current tile underneath ski guy
 ld 	a,[ypos]
 rra
 rra
 rra
 and 	%00011111
 ld 	c,a
 ld 	de, 32
 call 	multiply
 ld 	d, $98
 ld 	a,[xpos]
 rra
 rra
 rra
 and 	%00011111
 add 	a, 170
 ld 	e, a
 add 	hl,de

 ld 	a,h			; Adjust address if calculated off screen
 cp 	$9c
 jp 	nz,adjust1
 ld 	h,$98

adjust1:			
 call 	waitSM
 ld 	a,[hl] 		; if its snow then continue as normal
 bit 	$7,a		; any tile number > 128 is an collision 
 jr 	nz,die
 ret

die:						; Otherwise die as an snowman!
 ld		a,$8a
 ld		[$c000+34],a	; Set the Game Over sign
 ld		a,$8c
 ld		[$c000+38],a
 ld		a,$8e
 ld		[$c000+42],a
 ld		a,$90
 ld		[$c000+46],a

 ld		hl,ski_dead			
 call	spritechange
 call   UpdateOAM
 call	overmusic 
gow:
 call 	getkeys   
 bit 	KeyStart,a
 jp 	z,gow
 call 	HIScore		; Check and up date hiscore
 jp 	start		; Go back to set up title screen
	
plot_trees:
 ld 	a,[ypos]			; Find the hidden section of screen
 cp 	96
 ld 	de, $9800
 jp 	z, doit
 cp 	128
 ld 	de, $9880
 jp 	z, doit
 cp 	160
 ld 	de, $9900
 jp 	z, doit
 cp 	192
 ld 	de, $9980
 jp 	z, doit
 cp 	224
 ld 	de, $9a00
 jp 	z, doit
 cp 	0
 ld 	de, $9a80
 jp 	z, doit
 cp 	32
 ld 	de, $9b00
 jp 	z, doit
 cp 	64
 ld 	de, $9b80
 jp 	z, doit
 ret

doit: 

 call 	IncScore				; Increment score counter

 ld     hl,level        		; Read next byte in scroll 
 ld     a,[level_ptr]
 inc	a
 ld		[level_ptr],a
 ld     c,a
 ld     a,0
 ld     b,a
 add    hl,bc
 
 ld     a,[hl]                  ; Reset scroller if seen this [$ff]
 cp     $ff
 jp     z,reset_level
 ld 	[tree_row],a
 ld 	bc, 9

rotate_bit:
 ld 	a,[tree_row]
 bit 	$7,a					; Check bit to plant a tree else just 'snow'
 ld 	hl, tree
 call 	nz,plant_4x4
 ld 	hl, snowpatch
 call 	z, plant_4x4
next:
 ld 	a,[tree_row]
 rlca							; We rotate byte till we checked all 8 bits
 ld 	[tree_row],a
 inc 	de
 inc	de
 inc 	de
 inc 	de
 dec 	bc
 ld  	a,c
 cp  	1          
 jp  	nz,rotate_bit
 ret

plant_4x4:						; Plant the 4x4 block
 push 	af 
 push 	bc
 push 	de
 ld		bc, 4
grow:
 push 	bc
 ld 	bc, 4
 call 	move
 pop 	bc
 ld 	a, $1c
 adc 	a,e
 ld 	e,a
 dec    bc
 ld     a,b            
 or     c
 jr     nz, grow
 pop 	de
 pop 	bc
 pop 	af
 ret

reset_level:				; Obvious.....
 ld 	a,0
 ld 	[level_ptr],a
 ret

IncScore:			; Increment score counter
 push 	hl
 push 	de
 push 	bc
 push 	af

 ld 	de,score+4
 ld 	bc, 5
dcounter:
 ld 	a,[de]
 inc 	a
 cp 	$8a
 jp 	nz,dh
 ld 	a,$80
dh:
 ld 	[de],a
 cp 	$80
 jp 	nz, dx		; If not reached zero digit again then exit

 dec 	de
 dec	 bc
 ld 	a,b
 or 	c
 jr 	nz,dcounter

dx:
 ld		de,$9c00				; Update score in window
 ld		hl,score				
 ld		bc,5					
 call	move

 pop 	af
 pop	bc
 pop 	de
 pop 	hl
 ret

HIScore:		; Compare current score to hiscore and update it
 push 	hl
 push 	de
 push 	bc
 push 	af
 
 ld 	de,hiscore
 ld 	hl,score
 ld 	bc, 5
dtest:
 scf
 ld		a,[de]
 cp 	[hl]
 jp 	z, eql 
 sbc 	a,[hl]
 jp 	nc, dhx
 jp 	c,dxsave

eql:
 inc 	de
 inc 	hl
 dec 	bc
 ld 	a,b
 or 	c
 jr 	nz,dtest
 jp 	dhx

dxsave:							; Save hi-score
 ld		de,hiscore				; Destination
 ld		hl,score				; Source
 ld		bc,5					; number of bytes to move
 call	move
dhx:
 pop 	af
 pop 	bc
 pop 	de
 pop 	hl
 ret

move_grafix:
 ld		de,$8000				; Set up abc font
 ld		hl,abc_font				
 ld		bc,$07c0			
 call	move

 ld		de,$8800				; Set up digit font
 ld		hl,digit_font		
 ld		bc,$07c0+128			
 call	move

 ld		de,$8a00				; Set up ski guy grafix
 ld		hl,skigfx			
 ld		bc,1280 			
 call	move

 ld		de,$c000				; Set up ski guy sprite
 ld		hl,ski_sprite		
 ld		bc,32				
 call	move

 ret

Set_title:
 ld	    hl, 0					; Clear screen
 ld		de, $9800
 ld		bc, 32*32	
 call	fill

 ld		de,$c000+32				; Set up gameover sprites
 ld		hl,gameover_set		
 ld		bc,16		
 call	move

 ld		de,$9980				; Display snowman on each side of the screen
 ld 	hl, snowman
 call 	plant_4x4

 ld		de,$9980+16				
 ld 	hl, snowman
 call 	plant_4x4

 ld		hl, thetext				; Display title 
 ld		de, $9800+32
 ld		bc, 20
 call	move_text

 ld		hl, thetext+20			; Display credits
 ld		de, $9800+64
 ld		bc, 20
 call	move_text

 ld		hl, thetext+40			; Display 'press start'
 ld		de, $9800+128
 ld		bc, 20
 call	move_text

 ld		hl, hitext 				; Display hiscore text i.e. 'hiscore today'
 ld		de, $9800 + 544
 ld		bc, 16
 call	move_text

 ld		de,$9c00				; Display hiscore
 ld		hl,hiscore				
 ld		bc,5					
 call	move
 ret

; Standard Library
include "stdlib.asm"

; Graphics
include "ski_graphics.asm"

; Font
include "snow_font.asm"

; Music
include "music_player.asm"

; Level Map [see file for details]
include "level_map.asm"
	
