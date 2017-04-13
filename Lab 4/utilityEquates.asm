outLeftHalf	equ	$FF49	;convert left half of A to ASCII and output
outRightHalf	equ	$FF4C	;convert right half of A to ASCII and output
outOneCharInA	equ	$FF4F	;output ASCII character in A
outOneByte	equ	$FF52	;convert byte at address in X to 2 ASCII characters and output
outOneByteSpace	equ	$FF55	;convert byte at address in X to 2 ASCII characters and output w/ space
outTwoByteSpace	equ	$FF58	;convert 2 bytes at address in X to 4 ASCII characters and output w/ space
outCRLF		equ	$FF5B	;output CR LF
outString	equ	$FF5E	;output $04 terminated ASCII string
outStringNoCR	equ	$FF61	;outString w/o the initial CR

inChar		equ	$FF64	;wait and input one keystroke (ASCII) into A