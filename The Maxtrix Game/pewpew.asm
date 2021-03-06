	.model tiny
;////////////// SOUND DEF ////////////////
	Bj = 2415                               ; B low
	C = 2280
	Ck = 2152                               ; C#
	D = 2031
	Dk = 1917                               ; D#
	E = 1809
	F = 1715
	Fk = 1612                               ; F#
	G = 1521
	A = 1355
	B = 1207
	
	.data
;///////////////// Setting /////////////////
	easyMode	dw	04h
	normalMode	dw	02h
	hardMode	dw	01h
	
;//////////////// Screening ////////////////
	endProgram		db 'End of Program $', 0
	modeScreen1		db 'Mode : Easy$', 0
	modeScreen2		db 'Mode : Normal$', 0
	modeScreen3		db 'Mode : Hard$', 0
	scoreScreen		db 'Score : $', 0
	hpScreen		db 'HP : 10$', 0
;	status		db '  Mode : |                      Score : |                              HP : |   $'
;				   '0         1         2         3         4         5         6         7         '
;                  '01234567890123456789012345678901234567890123456789012345678901234567890123456789'
	titleScreen	db '     _|_|      _|_|   _|_|   _|      _| _|_|_|_|_| _|_|_|   _| _|      _|       ', 0
				db '     _|  _|  _|  _| _|    _|   _|  _|       _|     _|    _| _|   _|  _|         ', 0
				db '     _|  _|  _|  _| _|_|_|_|     _|         _|     _|_|_|   _|     _|           ', 0
				db '     _|    _|    _| _|    _|   _|  _|       _|     _|    _| _|   _|  _|         ', 0
				db '     _|    _|    _| _|    _| _|      _|     _|     _|    _| _| _|      _|       ', 0
				db '                                                                                ', 0
				db '       _|_|_| _|_|_|                                                            ', 0
				db '       _|  _| _|                                                                ', 0
				db '       _|_|_| _|_|_|                                                            ', 0
				db '       _|     _|                                                                ', 0
				db '       _|     _|_|_|                                                            ', 0
				db '                                                                                ', 0
				db '                                                                                ', 0
				db '                                                                                ', 0
				db '                                                                                ', 0
				db '                                                                                ', 0
				db '                                                                                ', 0
				db '                                                                                ', 0
				db '                                                                                ', 0
				db '                                                                                 $', 0

;//////////////// Variable /////////////////
	row			db	10 	dup (-1)
	column		db	10	dup	(-1)
	char		db	10  dup	(0)
	
	hp			db	10			; Start HP = 10
	score		db	3	dup (0)	; Start Score = 0
	
	ci			dw	?
	i			dw	?
	j			db	?
	k			dw	?           ; k = i^2 - i
	temp		dw  0
	ex			db	?
	count		db	0
	keyin		db	0
	
;/////////////// Seed /////////////////////	
	seed	db	?
	seed80	db 	?
	seed94	db 	?
	
	.code
	org		0100h

;/////////////// Main Start /////////////////////
main:
	call	setScreen
	call	hideCursor
	call	getSeed
	
	mov		ex, 1
	mov		count, 0			; Start Round 0
	mov		i, 0				; index of array
	mov		di, i				; and store in di 
	call	getStart			; Get start variable for game
	call	printHP
	call	printScore
	
gameloop:						; Game Processing

	mov		i, 0
ploop:
	call	checkKey
	mov		di, i
	call	printChar
	inc		[row + di]
	
	cmp		[row + di], 24
	jl		gonxt
	dec		hp
	call	delLine
	call	newLine
	
gonxt:	
	call	printHP
	inc		i
	cmp		i, 10
	jl		ploop
	
	call	delayinit
	cmp		hp, 0
	jg		gameloop
	jmp		endMain
	
;//////////////// Function Zone Start ////////////////
;//////////////// System Function ////////////////
delayinit:						; delay FN
	mov		ah, 86h
	mov		cx, 2
	mov		dx, 40h
	int		15h
	ret
	
delay:							; delay FN assign by game mode
	ret
	
setScreen:
	mov		ah,	00h				; Set screen 80x25 and use to clear screen
	mov		al, 03h
	int		10h
	ret
	
hideCursor:
	mov  	ch, 32   			; Hide cursor
	mov  	ah, 1
	int 	10h
	ret
	
checkKey:
	mov		ah, 01h
	int 	16h
	jz		rp2					; is buffer clear ? no getchar
	mov		ah, 00h				; getchar
	int		16h	
	mov		keyin, al			; store in keyin
	
	cmp		al, 27				; is keyin ESC ? yes end the game
	je		escf
	jne		rp1
	rp1:
	sub		al, 32
	mov		ci, 0				; key preesed check to delLine
	rpp:
	mov		di, ci
	cmp		[char + di], al
	jne		rp3
	call	delLine
	call	newLine
	call	incScore			; inc Score here
	jmp		rp2
	rp3:
	inc		ci
	cmp		ci, 10
	jl		rpp
	jmp		rp2
	escf:
	jmp		endMain
	rp2:
	ret
	
getSeed:
	mov		ah, 00h
	int		1Ah
	
	mov		seed, dl
	call	delayinit
	mov		ah, 00h
	int		1Ah
	mov		seed80, dl
	call	delayinit
	mov		ah, 00h
	int		1Ah
	mov		seed94, dl
	call	delayinit
	ret
	
getStart:
	mov		i, 0
	for1:
	mov		di, i
	call	randChar
	call	randRow
	call	randColumn
	inc		i
	cmp		i, 10
	jl		for1
	ret
	
newLine:
	mov		[row + di], 0
	call	randChar
	call	randRow
	call	randColumn
	ret
	
delLine:
	mov		j, 0
	jloop:
	mov		dh, j
	mov		dl, [column + di]
	call	setpos
	call	printBlack
	inc		j
	cmp		j, 30
	jl		jloop
	ret
	
setpos:
	mov		ah, 02h
	int		10h
	ret
	
;//////////// Random Function //////////////
randChar:
	push	ax					; Set k = i^2 - i
	mov		ax, i
	mul		i
	sub		ax, i
	mov		k, ax
	pop		ax
	
	mov		ah, 00h   
	mov		al, seed94
	mov		cx, 95
	mul		cx
	add		ax, k
	mov		cx, 26
	xor		dx, dx
	div		cx
	add		dl, 'A'
	mov		seed94, dl		
	mov		[char + di], dl
	ret 
	
randColumn:
	mov		ah, 00h
	mov		al, seed80
	mov		cx, 81
	mul		cx
	add		ax, 17
	mov		cx, 75
	xor		dx, dx
	div		cx
	mov		seed80, dl
	mov		[column + di], dl
	ret

randRow:
	mov		ah, 00h
	mov		al, seed
	mov		cx, 10
	mul		cx
	add		ax, k
	mov		cx, 40
	xor		dx, dx
	div		cx
	sub		dl, 15
	mov		seed, dl
	sub		dl, 40
	mov		[row + di], dl
	ret

;//////////// Print-Display Function //////////////
printHP:
	mov		dh, 24
	mov		dl, 71
	call	setpos
	
	mov		ah, 09h
	mov		dx, offset hpScreen
	int		21h
	
	mov		dh, 24
	cmp		hp, 10
	jl		nxtHP1
	jmp		nxtHP2
	nxtHP1:
	mov		dl, 76
	call	setpos
	mov		al, ' '
	inc		dh
	call	printGray
	inc		dl
	inc		dh
	call	setpos
	mov		al, hp
	add		al, '0'
	call	printGray
	nxtHP2:
	ret
	
printScore:
	mov		dh, 24
	mov		dl, 32
	call	setpos
	mov		ah, 09h
	mov		dx, offset scoreScreen
	int		21h
	mov		dh, 24
	
	inc		dh
	mov		dl, 42
	mov		al, [score + 0]
	add		al, '0'
	call	printGray
	inc		dh
	mov		dl, 41
	mov		al, [score + 1]
	add		al, '0'
	call	printGray
	inc		dh
	mov		dl, 40
	mov		al, [score + 2]
	add		al, '0'
	call	printGray
	ret
	

printChar:			
	mov		di, i
	mov		dh, [row + di]		; set pos
	mov		dl, [column + di]
	mov		ah, 02h
	int		10h
	
	mov		al, [char + di]
	call	printWhite
	call	printGray
	call	printGreen
	call	printGreen
	call	printGreen
	call	printGreen
	call	printGreen
	call	printGreen
	call	printGreen
	dec		dh
	call	printBlack
	ret
	
printBlack:						; print black at pos
	call	setpos
	mov		bl, 00h
	mov		cx, 01h
	mov		ah, 09h
	int		10h
	ret

printWhite:						; print white at pos
	call	setpos
	mov		bl, 0Fh
	mov		cx, 01h
	mov		ah, 09h
	int		10h
	ret

printGray:						; update pos row-- and print gray at pos
	dec		dh
	call	setpos
	mov		bl, 07H
	mov		cx, 01h
	mov		ah, 09h
	int		10h
	ret
	
printGreen:						; update pos row-- and print green at pos
	dec		dh
	call	setpos
	mov		bl, 02h
	mov		cx, 01h
	mov		ah, 09h
	int		10h
	ret
	
;//////////// Game Logic Function //////////////
decHP:
	dec		hp
	cmp		hp, 0
	je		endMain
	ret
	
incScore:
	sub		al, 20
	mov		j, al
	jj:
	inc		[score + 0]
	cmp		[score + 0], 10
	jne		nxtIS
	mov		[score + 0], 0
	inc		[score + 1]
	cmp		[score + 1], 10
	jne		nxtIS
	mov		[score + 1], 0
	inc		[score + 2]
	
	nxtIS:
	dec		j
	cmp		j, 0
	jg		jj
	call	printScore
	ret
	
gameOver:
	jmp		endMain
	
;///////////// Sound FN //////////////////
LoopIt: lodsw                        ; load desired freq.
        or   ax,ax                   ; if freq. = 0 then done
        jz   short LDone             ;
        mov  dx,42h                  ; port to out
        out  dx,al                   ; out low order
        xchg ah,al                   ;
        out  dx,al                   ; out high order
        lodsw                        ; get duration
        mov  cx,ax                   ; put it in cx (16 = 1 second)
        call PauseIt                 ; pause it
        jmp  short LoopIt

LDone:  mov  dx,61h                  ; turn speaker off
        in   al,dx                   ;
        and  al,0FCh                 ;
        out  dx,al                   ;
        ret
		
PauseIt:                             ; some delay
        mov    ah, 86h
        mov    dx, 00h
        int    15h
		ret
	
;//////////// End Program //////////////
endMain:
	call	setScreen
	mov		ah, 09h
	mov		dx, offset endProgram
	int		21h
	int		20h
	end 	main
	