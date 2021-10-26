mcount		EQU     $c203

reset_player:
 ld bc,tempo            ; load speed/tempo of the song
 ld a,[bc]              
 ld [$c202],a
 ld [$c201],a
 ld [$c200],a
 inc bc
 ld a,b
 ld [mcount],a
 ld a,c
 ld [mcount+1],a
 ret

player:         
 ld a,[mcount]
 ld b,a
 ld a,[mcount+1]
 ld c,a
TT:     
 ld a,[$c200]            ; timer 
 sub 1
 ld [$c200],a
 jp nc,TT
 ld a,[$c201]            ; timer 
 sub 1
 ld [$c201],a
 jp nc,TT

 ld a,[$c202]            ; reset timer
 ld [$c200],a
 ld	[$c201],a

; play notes
 ld a,[bc]
 cp $ff					 ; check if at end of track
 jp z, reset_player
 cp 0
 jp z,m1
 call get_notes
 call nice_note
m1:
 inc bc
 ld a,[bc]
 cp 0
 jp z,m2
 call get_notes
 call nice_note2
m2:
 inc bc
 
 call	snare

 ld a,b
 ld [mcount],a
 ld a,c
 ld [mcount+1],a 
 ret

                           
; set channels for Max volume, both speakers.
set_volume:
 ld a,%01110111
 ld [$FF24],a
 ld a,%11111111
 ld [$FF25],a
 ld a,%11111111
 ld [$FF26],a
 ret
   
nice_note:
 ld a,%11001111
 ld [$FF16],a
 ld a,%01100011
 ld [$FF17],a
 ld a,l
 ld [$FF18],a
 ld a,$80
 or  h
 ld [$FF19],a
 ret

nice_note2:
 ld a,%00000011
 ld [$ff10],a
 ld a,%10101111
 ld [$FF11],a
 ld a,%00110001
 ld [$FF12],a
 ld a,l
 ld [$FF13],a
 ld a,$80
 or h
 ld [$FF14],a
 ret

snare:
 ld a,135
 ld [$FF20],a
 ld a,%01110001
 ld [$FF21],a
 ld a,%11101011  
 ld [$FF22],a
 ld a,%00001100
 ld [$FF23],a
 ret

get_notes:
 push bc
 rla
 ld e,a
 ld a,0
 ld d,a
 ld hl, music_notes
 add hl,de
 ld	d,h
 ld	e,l
 ld a,[de]
 ld h,a		;store hi byte
 dec de
 ld a,[de]
 ld l,a		;store low byte
 pop bc
 ret

; music notes of the song
music_notes:
DB $00,$2C,$00,$9C,$00,$6B,$01,$06,$01,$C9,$01,$23,$02,$77,$02,$C6,$02,$12,$03
DB $56,$03,$9B,$03,$DA,$03,$16,$04,$4E,$04,$B5,$04,$83,$04,$E5,$04,$11,$05,$3B
DB $05,$63,$05,$89,$05,$AC,$05,$CE,$05,$ED,$05,$0A,$06,$27,$06,$5B,$06,$42,$06
DB $72,$06,$89,$06,$9E,$06,$B2,$06,$C4,$06,$D6,$06,$E7,$06,$F7,$06,$06,$07,$14
DB $07,$2D,$07,$21,$07,$39,$07,$44,$07,$4F,$07,$59,$07,$62,$07,$6B,$07,$73,$07
DB $7B,$07,$83,$07,$8A,$07,$97,$07,$90,$07,$9D,$07,$A2,$07,$A7,$07,$AC,$07,$B1
DB $07,$B6,$07,$BA,$07,$BE,$07,$C1,$07,$C4,$07,$CB,$07,$C8,$07,$CE,$07,$D1,$07
DB $D4,$07,$D6,$07,$D9,$07,$DB,$07,$DD,$07,$DF,$07

; track speed/tempo of the song
tempo:
DB $3A,$29,$00,$2C,$00,$31,$00,$00,$00,$31,$00,$00,$00,$2E,$00,$2C,$00,$29,$00
DB $2C,$00,$31,$00,$00,$00,$00,$00,$00,$00,$31,$00,$33,$00,$35,$00,$00,$00,$35
DB $00,$00,$00,$38,$00,$38,$00,$35,$00,$33,$00,$00,$00,$00,$00,$00,$00,$38,$00
DB $38,$00,$35,$00,$00,$00,$35,$00,$35,$00,$35,$00,$33,$00,$31,$00,$31,$00,$31
DB $00,$2E,$00,$00,$00,$2E,$00,$2E,$00,$2E,$00,$33,$00,$31,$00,$2D,$00,$2E,$00
DB $2C,$00,$00,$00,$2C,$00,$00,$00,$35,$00,$33,$00,$2E,$00,$2D,$00,$31,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$FF,$FF,$00,$00,$00

