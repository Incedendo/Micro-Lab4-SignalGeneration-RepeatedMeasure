;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
; define given functions at certain memory locations
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
outstrg	equ	$FF5E
inchar	equ	$FF64
outa	equ	$FF4F
outcrlf	equ	$FF5B

	org	$1000
; set up the global var to store the counts
count04		db	0
count59		db	0
countAH		db	0
countIP		db	0
countQZ		db	0
span		db	0
maxlength	db	80
msg1		dc.b	"Enter a string less than 80 characters." ,$04
prompt		dc.b	"Waiting for input" ,$04
warning		dc.b 	"Exceed 80 chars" ,$04
ct04		dc.b	"Count from 0-4 = " ,$04
ct59		dc.b	"Count from 5-9 = " ,$04
ctAH		dc.b	"Count from A-H = " ,$04
ctIP		dc.b	"Count from I-P = " ,$04
ctQZ		dc.b	"Count from Q-Z = " ,$04
array	rmb	80

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
; main:
;				start at location $2000
;
;
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	org	$2000
	;initialize the 5 global variables to 0
			ldaa 	#0
			staa	count04
			staa	count59
			staa	countAH
			staa	countIP
			staa	countQZ
			ldx	#prompt
			jsr	outstrg								; "Waiting for input"
			jsr	outcrlf								; print a new line after
			jsr	query								; GO to Query srt
			;
			ldy	#array
			pshy									; push addr of string on stack
			leas	-5, sp							; save 5 spaces for the 5 counts
			;
			;initialize the 5 counts on stack to 0
			;
			ldab	#$0
			stab	0, sp		; set count = 0
			stab	1, sp		; set count = 0
			stab	2, sp		; set count = 0
			stab	3, sp		; set count = 0
			stab	4, sp		; set count = 0
	;------------------------
	; relative stack pos:	;
	;------------------------
	;count of Q-Z			;
	;------------------------
	;count of I-P			;
	;------------------------
	;count of A-H			;
	;------------------------
	;count of 5-9			;
	;------------------------
	;count of 0-4			;
	;------------------------
	;Higher addr of  		;
	;------------------------
	;Lower addr of Y 		;
	;------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	A loop to traverse through the length of the string until <Cr> char is read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			jsr	outcrlf
print		ldaa	1,y+		; load accumulator a with a char in string
			cmpa	#$0D		; as long as char is not CR char, keep iterating through
			beq	reloadY
			jsr	outa
			bra	 print
reloadY		ldy	#array
outchar		ldaa	1,y+		; load a with a char in string
			cmpa	#$0D
			beq	done
			psha			; push char on to the stack
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	As each char is read, it is passed to 5 subroutines 
;	to check if it belongs to that range
;			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;check range 0-4
		   	ldx     #$3034
		    pshx                    ; push lower range $30 and push upper range $5A
			jsr     chk04           ; call sub to check range and count
			;
			pulx
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;check range 5-9
		   	ldx     #$3539
		    pshx                    ; push lower range $30 and push upper range $5A
			jsr     chk59           ; call sub to check range and count
			;
			pulx
			;pula
			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;check range A-H
		   	ldx     #$4148
		    pshx                    ; push lower range $30 and push upper range $5A
			jsr     chkAH           ; call sub to check range and count
			;
			pulx
			;pula
			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;check range I-P
		   	ldx     #$4950
		    pshx                    ; push lower range $30 and push upper range $5A
			jsr     chkIP           ; call sub to check range and count
			;
			pulx
			;pula
			;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;check range Q-Z
		   	ldx     #$515A
		    pshx                    ; push lower range $30 and push upper range $5A
			jsr     chkQZ           ; call sub to check range and count
			;
			pulx
			pula
nxt			bra	 outchar
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 	print result:
; 		for each of the 5 counts, load base 10 at reg X, load count at accumulator B
; 		use idiv to get the division result in X and the remainder in D
; 		exchange lower byte of D and X with accumulator A to use outa subroutine to print out the number
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
done		jsr	outcrlf
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;
		;;;;	Print count for 0-4
		;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			ldx	#ct04
			jsr	outstrg
			ldx	#$000A ;load x with 10
			ldab	count04
			ldaa	#$00
			idiv    ; D : X
			exg	x,a
			adda	#$30
			jsr	outa
			exg	d,a
			adda	#$30
			jsr	outa
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;
		;;;;	Print count for 5-9
		;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			ldx	#ct59
			jsr	outstrg
			ldx	#$000A ;load x with 10
			ldab	count59
			ldaa	#$00
			idiv    ; D : X
			exg	x,a
			adda	#$30
			jsr	outa
			exg	d,a
			adda	#$30
			jsr	outa
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;
		;;;;	Print count for A-H
		;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			ldx	#ctAH
			jsr	outstrg
			ldx	#$000A ;load x with 10
			ldab	countAH
			ldaa	#$00
			idiv    ; D : X
			exg	x,a
			adda	#$30
			jsr	outa
			exg	d,a
			adda	#$30
			jsr	outa
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;
		;;;;	Print count for I-P
		;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			ldx	#ctIP
			jsr	outstrg
			ldx	#$000A ;load x with 10
			ldab	countIP
			ldaa	#$00
			idiv    ; D : X
			exg	x,a
			adda	#$30
			jsr	outa
			exg	d,a
			adda	#$30
			jsr	outa
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;
		;;;;	Print count for Q-Z
		;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			ldx	#ctQZ
			jsr	outstrg
			ldx	#$000A ;load x with 10
			ldab	countQZ
			ldaa	#$00
			idiv    ; D : X
			exg	x,a
			adda	#$30
			jsr	outa
			exg	d,a
			adda	#$30
			jsr	outa
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;
		;;;;	Clean up the stack and pull Y 
		;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			leas	5, sp
			puly
			swi
;
;
;
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
; Subroutine query:
;	Handle input by user
;	Convert Upper case letter to Lower case letter, ignore the rest
;
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;
;
;
query		pshx
			ldx		#array
			clr		span
qy1			jsr		inchar				; store char at reg a
			cmpa	#$0D			; check for <cr> char to signal termination
			beq		q_done				; if user hit enter, jump to q_done to quit srt
			;compare span and maxlength, 
			;if a-z then convert to A-Z
			cmpa	#$60
			bls		c_done
			cmpa	#$7B
			bhs		c_done
			suba	#$20
c_done		staa	1,x+			; if not a valid char, simply store it in the string
			inc 	span
			ldab	span
			cmpb	#$50
			bhs		q_done
			bra		qy1					; jump back to loop qy1
q_done 		ldaa	#$0D			; store the terminating char #$0D to signal end of string
			staa	1,x+
			clr		0,x
			pulx
			rts
;
;
;
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
; Subroutine Count:
;	count the number of occurrences of characters in the given range
;	pull the count for each subclass off the stack and increment if the character belongs
;	in that racket
;
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;
;:::::::::::::::::::::::::::::::::::::::::::::
;  check range of I to P: $51-$5A
;:::::::::::::::::::::::::::::::::::::::::::::
chkQZ	
			ldab	2, sp	; load b with 51
			ldaa	4, sp
			cba
			blo	QZ_done	; if char in a is smaller than lower bound, branch to done
			ldab	3, sp	; load b with 5A
			cba
			bhi	QZ_done	; if char in a is smaller than lower bound, branch to done
			ldaa	5, sp
			inca
			staa	5, sp
			staa	countQZ
QZ_done		rts
;
;:::::::::::::::::::::::::::::::::::::::::::::
;  check range of I to P: $49-$50
;:::::::::::::::::::::::::::::::::::::::::::::
;
chkIP	
			ldab	2, sp	; load b with the lower bound
			ldaa	4, sp
			cba
			blo	IP_done	; if char in a is smaller than lower bound, branch to done
			ldab	3, sp	; load b with the upper bound
			cba
			bhi	IP_done	; if char in a is smaller than lower bound, branch to done
			ldaa	6, sp
			inca
			staa	6, sp
			staa	countIP
IP_done		rts
;
;;:::::::::::::::::::::::::::::::::::::::::::::
;  check range of A to H: $41-$48
;::::::::::::::::::::::::::::::::::::::::::::::
;
chkAH
			ldab	2, sp	; load b with the lower bound
			ldaa	4, sp
			cba
			blo	AH_done	; if char in a is smaller than lower bound, branch to done
			ldab	3, sp	; load b with the upper bound
			cba
			bhi	AH_done	; if char in a is smaller than lower bound, branch to done
			ldaa	7, sp
			inca
			staa	7, sp
			staa	countAH
AH_done		rts
;
;;:::::::::::::::::::::::::::::::::::::::::::::
;  check range of 0 to 4: $30-$34
;::::::::::::::::::::::::::::::::::::::::::::::
;
chk04	
			ldab	2, sp	; load b with the lower bound
			ldaa	4, sp
			cba
			blo	Z4_done	; if char in a is smaller than lower bound, branch to done
			ldab	3, sp	; load b with the upper bound
			cba
			bhi	Z4_done	; if char in a is smaller than lower bound, branch to done
			ldaa	9, sp
			inca
			staa	9, sp
			staa	count04
Z4_done		rts
;
;;:::::::::::::::::::::::::::::::::::::::::::::
;  check range of 5 to 9: $35-$39
;::::::::::::::::::::::::::::::::::::::::::::::
;
chk59	
			ldab	2, sp	; load b with the lower bound
			ldaa	4, sp
			cba
			blo	F9_done	; if char in a is smaller than lower bound, branch to done
			ldab	3, sp	; load b with the upper bound
			cba
			bhi	F9_done	; if char in a is smaller than lower bound, branch to done
			ldaa	8, sp
			inca
			staa	8, sp
			staa	count59
F9_done		rts
			end
