; Standard Library
; 
; move 			= To copy blocks of bytes
; fill			= To fill a block of bytes
; move_text 	= To transfer text onto screen area 
; getkeys 		= Get keypad status
; normal_color	= Sets the colors to normal palette
; initdma 		= Transfer DMA routine to RAM
; waitSM		= Wait until Screen Memory avaliable
; waitvbl 		= Wait for Vertical blank
; multiply		= Multiply two numbers
; delay			= Wait a bit

; Labels defined for key recognition
; Once called 'getkey' you should then bit test 
; e.g. 'bit KeyStart,a' to test start key


move:
; PURPOSE: To copy blocks of bytes
; RECIEVES: hl = source  de = destination  bc = number of bytes
; RETURNS: Nothing
 
 ld     a,[hli]
 call   waitSM
 ld     [de],a
 inc    de
 dec    bc
 ld     a,b            
 or     c
 jr     nz, move
 ret

fill:
; PURPOSE: To fill a block of bytes
; RECIEVES: hl = byte[hi byte ignored]  de = destination  bc = number of bytes
; RETURNS: Nothing
 
 ld     a,l
 call   waitSM
 ld     [de],a
 inc    de
 dec    bc
 ld     a,b            
 or     c
 jr     nz, fill
 ret

move_text:
; PURPOSE: To transfer text onto screen area 
; RECIEVES: hl = screen address  de = the source of text  bc = counter
; RETURNS: Nothing

 
 ld     a,[hli]
 call   waitSM
 and	$3f
 ld     [de],a
 inc    de
 dec    bc
 ld     a,b            
 or     c
 jr     nz, move_text

 ret


getkeys:
; PURPOSE: Get keypad status
; RECIEVES: Nothing
; RETURNS: a = KeyStart, KeySelect, KeyA, KeyB, KeyUp, KeyDown, KeyLeft, KeyRight

 ld     a,$20
 ldh    [$00],a         ;turn on P15
 ldh    a,[$00]         ;delay
 ldh    a,[$00]

 cpl
 and    $0f
 swap   a
 ld     b,a

 ld     a,$10
 ldh    [$00],a         ;turn on P14
 ldh    a,[$00]         ;delay
 ldh    a,[$00]
 ldh    a,[$00]
 ldh    a,[$00]
 ldh    a,[$00]
 ldh    a,[$00]

 cpl
 and    $0f
 or     b
 swap   a
 ret

normal_color:      
; PURPOSE: Sets the colors to normal palette
; RECIEVES: Nothing
; RETURNS: Nothing

 ld     a,%11100100     ; grey 3=11 [Black]
                        ; grey 2=10 [Dark grey]
                        ; grey 1=01 [Ligth grey]
                        ; grey 0=00 [Transparent]
 ldh    [$47],a

 ld     a,%11100100     
 ldh    [$48],a         ; 48,49 are sprite palettes 
 ld     a,$00000000
 ldh    [$49],a
 ret

initdma:       
; PURPOSE: Transfer DMA routine to RAM
; RECIEVES: Nothing
; RETURNS: Nothing

 ld     de,$ff80
 ld     hl,dmacode
 ld     bc,dmaend-dmacode
 call   move
 ret

dmacode:                ; Transfer sprite data from reg A pos. using DMA
 di
 push af
 ld     a,$c0
 ldh    [$46],a         ; Start DMA
 ld     a,$28           ; Wait for 160ns
dma_wait:
 dec    a
 jr     nz,dma_wait
 pop af
 ei
 ret
dmaend:

waitvbl:            
; PURPOSE: Wait for Vertical blank
; RECIEVES: Nothing
; RETURNS: Nothing

 push 	af
 push 	bc
 push 	de
 push 	hl
 ldh    a,[$40]         ; LCD screen on??
 add    a,a
 jr     nc,wvb
notyet:
 ldh    a,[$44]         ; $ff44=LCDC Y-Pos
 cp     $98             ; $98 and bigger = in VBL
 jr     nz,notyet
wvb:
 pop 	hl
 pop	de
 pop 	bc
 pop 	af
 ret


waitSM:
; PURPOSE: Wait until Screen Memory avaliable
; RECIEVES: Nothing
; RETURNS: Nothing

  push 	af
sm:
  ldh 	a,[$41]
  and 	2
  jr 	nz, sm
  pop 	af
  ret

multiply:
; PURPOSE: Multiply two numbers
; RECIEVES: DE = number 1 BC = number 2
; RETURNS: HL = product

 ld		hl,0
multi:
 ld     a,b             
 or     c
 jr     z, xmulti
 add    hl,de
 dec    bc
 jp     multi
xmulti:
 ret

delay:
; PURPOSE: Delayer
; RECIEVES: c = counter delay
; RETURNS: Nothing

 push 	af
 push 	bc
 push 	de
 push 	hl

 ld		d,0

nyet:
 dec	d
 ld		a,d
 jr     nz,nyet
 dec	bc
 ld     a,b            
 or     c
 jr     nz,nyet

 pop 	hl
 pop	de
 pop 	bc
 pop 	af
 ret
