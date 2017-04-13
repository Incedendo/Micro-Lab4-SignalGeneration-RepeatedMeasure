;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Student Name:    Jim Pfluger, Kiet Nguyen
; Program Name:    Lab# 4  
; Semester:        Spring, 2017
; Class & Section: CoSc 30353 - Microprocessors
; Instructor:      Dr. Donnell Payne
; Due Date:        April 12, 2017                                    
;                                                                        
; Program Overview:                                                     
;     This program prompts the user for a command
;	upon hitting E, the program exits
;	upon hitting G, the user is prompted for a frequency and duty cycle to input
;	upon hitting M, the incoming signal is measured
; Input:                                                                
;     Generated signal data comes from the command line via the user
;     Measured signal comes into port T1
;
; Output:                                                               
;     Generated signal comes out port T0
;     Measured signal data is outputted to the console
;                                                                        
; Program Limitations:                                                  
;     None known (backspace is accounted for!!!)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include utilityEquates.asm

TIOS		equ 	$40 		;Input/output compare select address
TCNT		equ 	$44 		;counter address
TSCR1		equ 	$46 		;TSCR1 address, for enabling counter and fast flag clear
TSCR2		equ 	$4D 		;TSCR2 address, for enabling overflow interrupts and scaling
TCTL1		equ	$48		;Timer control register 1 address (ch7-4)
TCTL2		equ 	$49 		;Timer control register 2 address (ch3-0)
TCTL3		equ	$4A		;Timer control register 3, rising/falling edges (ch7-4)
TCTL4		equ	$4B		;Timer control register 4, rising/falling edges (ch3-0)
TIE		equ	$4C		;Timer interrupt enables
TFLG1		equ 	$4E 		;Timer interrupt flag register address
TFLG2		equ	$4F		;Timer overflow flag register address
TC0		equ 	$50 		;address chan 0 counter
TC1		equ 	$52 		;address chan 1 counter

UserTimerOvf	equ	$3FDE
IOS1		equ	$02
IOS0		equ	$01
C0F		equ	$01
C1F		equ	$02
TOF		equ	$80

SC0BDH		equ	$C8
SC0CR1		equ	$CA
SC0CR2		equ	$CB
SC0SR1		equ	$CC
SC0DRL		equ	$CF
RDRF		equ	$20

ramStart	equ	$1000		;RAM start location
progStart	equ	ramStart+$1000	;Program start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		org	ramStart
keyBuff		rmb	16

;measureSignal
captured_edge	ds.b	2
rising_edge1	ds.b	2
rising_edge2	ds.b	2
rising_edge3	ds.b	2
falling_edge	ds.b	2
pulse_width	dw	0
period		dw	0
measure_freq	dw	0
measure_duty	dw	0
num_edges	dw	0
numChars	dw	0
isPrintingFreq	dw	0

;generateSignal
totalCount	dw	0
timeHi		dw	0
timeLo		dw	0
sumHex		dw	0
sumDec		dw	0
placeHolder	db	$04
inputFreq	dw	0
inputDuty	dw	0
upper500	dw	$0007
lower500	dw	$A120
HiorLo		ds.b	1

;repeated measurements
storedChar	dw	0

;general prompts to be printed
promptAsk	dc.b	"Generate (G), Measure (M), Exit (E)? ", $04
promptGenFreq	dc.b	"Frequency (10Hz - 10000Hz)? ", $04
promptGenDuty	dc.b	"Duty Cycle % (10 - 90)? ", $04
promptMesFreq	dc.b	"Frequency Measured in Hz = ", $04
promptMesDuty	dc.b	"Duty Cycle in % = ",$04

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		org	$3FEC			;address for measuring interupt service routine
		dc.w	ISR_EDGE
		org	$3FEE			;address for generating interupt service routine
		dc.w	ISR_GEN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		org	progStart
		; start loop
main_loop_start
		ldd	#keyBuff
		pshd
		jsr	inputCmdEntry		;enter a command in
		leas	2,sp			;clean up stack pointer
	
		ldaa	keyBuff
		cmpa	#$45			;if input==E
		beq	main_end		;exit program
		cmpa	#$47			;if input==G
		beq	main_gen		;go generate signal
		cmpa	#$4D			;if input==M
		beq	main_measure		;go measure signal'
		bra	main_loop_start

main_measure
		jsr	serial_inChar
		;jsr	initialMeasure
		bra	main_loop_end		;go back to the beginning of the main function
main_gen	
		jsr	inputFreqDuty		;manipulate the input to get the #hiCount and #loCount
		jsr 	generateSignal		;continue generating the signal
		bra	main_loop_end
main_loop_end
		jsr	outCRLF
		bra	main_loop_start
main_end
		swi




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	inputCmdEntry
;	------------
;	Goal: take the user input command entered
;	Input:
;	   keyboard buffer - stored at sp+2 
;	Output:
;	   keyboard buffer of command
;	Note: this actually handles backspace characters, so if the backspace
;	      is pressed, the previous character won't be stored
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
inputCmdEntry
		ldx	#promptAsk	;load the prompt for the user
		jsr	outStringNoCR	;display the prompt for the user
		ldx	2,sp
		jsr	inChar		;take in a single character, stored in A
		andb	#0
		cmpa	#$47		;check if G
		std	0,x
		beq	inputCmdDone	;if so, return
		cmpa	#$4D		;check if M
		std	0,x
		beq	inputCmdDone	;if so, return
		cmpa	#$45		;check if E
		std	0,x
		beq	inputCmdDone	;if so, return
inputCmdDone
		jsr	outCRLF
		rts			;return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	inputFreqDuty
;	------------
;	Goal: Ask the user to enter a Frequency and Duty Cycle, convert these to hex values and store them appropriately
;	Input:
;	   global keyBuff variable
;	Output:
;	   global keyBuff variable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		
inputFreqDuty
		ldd	#0			;reset the variables
		std	keyBuff
		std	sumHex
		
		ldx	#promptGenFreq
		pshx
		ldx	#keyBuff
		pshx
		jsr	inputEntryNumber	;input the frequency
		ldx	#keyBuff
		pshx
		jsr	toHex_start		;convert the decimal frequency into a hex frequency
		ldd	sumHex
		std	inputFreq		;store the converted frequency

		ldd	#0			;reset the variables
		std	keyBuff
		std	sumHex

		ldx	#promptGenDuty
		pshx
		ldx	#keyBuff
		pshx
		jsr	inputEntryNumber	;input the duty cycle
		ldx	#keyBuff
		pshx
		jsr	toHex_start		;convert the decimal duty cycle into a hex duty cycle
		ldd	sumHex
		std	inputDuty		;store the converted frequency
		
		jsr 	setHiLo

		leas	12,sp
		rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	inputEntryNumber
;	------------
;	Goal: take the user input characters and store them; used for 
;	Input:
;	   keyboard buffer - stored at sp+2
;	   prompt to print - stored at sp+4
;	Output:
;	   keyboard buffer global
;	Note: this actually handles backspace characters, so if the backspace
;	      is pressed, the previous character won't be stored
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
inputEntryNumber
		ldx	4,sp		;load the prompt for the user
		jsr	outStringNoCR	;display the prompt for the user
		ldx	2,sp		;initialize our array address parameter
inputNumberLoop
		jsr	inChar		;take in a single character, stored in A
		cmpa	#$0D		;check if CR
		beq	inputNumberDone	;if so, return
		cmpa	#$08		;check if backspace character
		bne	inputNumberSkip	;if it is NOT, skip the handling
		stx	1,x-		;remove the last character
		bra	inputNumberLoop	;if is backspace character, restart loop
inputNumberSkip
		staa	1,x+		;otherwise store the input character
		bra 	inputNumberLoop	;branch up again
		
inputNumberDone
		ldaa	#4		;load the end of stream character
		staa	0,x		;and store it at the end of the keyboard buffer
		rts			;return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	toHex_Start
;	------------
;	Goal: conver the user's input decimal into hex. It does so by multiplying
;	      the sum by 10 (the base) and adding the digit to it, until no digits remian.
;	Input:
;	   keyboard buffer - stored at sp+2 
;	Output:
;	   sumHex - result of the converted decimal into hex
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
toHex_Start
		ldx	2,sp		;load the address of keyBuffer in
toHex_Num
		ldab	1,x+		;load the character at 'x', increment the address after
		cmpb	#$0D		;check to see if the char is a carriage return...
		beq	toHex_done	;... if it is, then we must leave
		cmpb	#$04		;check to see if the char is a carriage return...
		beq	toHex_done	;... if it is, then we must leave
		subb	#$30		;convert the ascii character into it's numeric equivalent
		anda	#0		;clear 'a'
		pshd			;store d
		ldy	#10		;load the base
		ldd	sumHex		;load the current sum
		emul			;multiply base*sum
		std	sumHex		;store the new sum
		exg	d,y		;exchange it into y
		puld			;restore the character value
		addd	sumHex		;and add it to the sum
		std	sumHex		;otherwise store the new sum
		
		bra	toHex_Num	;branch up to the top
toHex_Done
		rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	toDec_start
;	------------
;	Goal: conver an input hex number into a printed decimal number
;	Input:
;	   input number - stored at sp+2 
;	Output:
;	   Printed decimal value
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
toDec_start
		ldx	2,sp			;load the address of the input
		ldy	#0
toDec_num_load
		;count up
		;load the frequency, divide by 10, push the remainder on the stack
		exg	d,x
		ldx	#10
		idiv
		pshd
		iny				; y store the number of digits so far
		cpx	#0			; as long as the result of the divison is not zero, keep pushing onto the stack
		bne	toDec_num_load

		ldaa	isPrintingFreq		; check if we're printing Frequency, if yes, load the numChars from y
		cmpa	#1
		bne	toDec_num_unload
		movb	#0,numChars		; clear out numChars before storing new value
		sty	numChars

toDec_num_unload
		;counter down
		;get the last digit pushed on the stack, and print it
		puld
		exg	a,b
		adda	#$30
		jsr	outOneCharInA
		dey
		cpy	#0
		bne	toDec_num_unload
toDec_done
		rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	setHiLo
;	------------
;	Goal: 
;	Input:
;	    timeHi - total amount of counts the signal spends high
;	    timeLo - total amount of counts the signal spends low
;	    inputFreq - user's inputted frequency
;	    inputDuty - user's inputted duty cycle
;	Output:
;	    changed values of timeHi and timeLo
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
setHiLo
		ldd	#0
		std	timeHi
		std	timeLo
		ldy	upper500
		ldd	lower500
		ldx	inputFreq
		ediv			;divide 500,000 by the user's input frequency
		sty	totalCount
		
		ldy	totalCount
		ldd	inputDuty
		ldx	#100
		emul			;multiply the totalCount by the user's inputDuty time
		ediv			;then divide by 100 to get the % high
		sty	timeHi
		
		ldd	totalCount
		subd	timeHi		;timeLo=totalCount-timeHi
		std	timeLo

		rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	generateSignal
;	------------
;	Goal: set up ability to generate signals, allowing for interrupts to occur at the end
;	Input:
;	    n/a
;	Output:
;	   n/a
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
generateSignal
		movb	#$90, TSCR1		;enable timer; use fast timer flaf clear
		movb	#$04, TSCR2		;disable TCNT OV interrupt, set prescaler 16
		bset	TIOS, #$01		;allow output compare at TC0
		movb	#$FF, TFLG1		;clear channel flags

		movb	#$03, TCTL2		;set to output quick HI(11) on CO0
		ldd	TCNT			;start
		addd	#10
		std	TC0
		brclr	TFLG1, #%00000001,*
		
		movb	#$01,TCTL2		;select toggle pin
		bset	TIE,#$01		;chan 0 interrupt allowation
		movb	#0,HiorLo		;starting Hi, 0 count will be next to set
		ldd	TC0			;copy TC0 counter
repeat		addd	timeHi			;add timeHi value
		std	TC0			;store TC0
		cli				;enable interrupts
here		rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	repeatMeasure
;	------------
;	Goal: repeatedly measure the frequency, so we do not print the
;		measured frequency prompt, as it gets erased over
;	Input:
;	    n/a
;	Output:
;	    frequency measured
;	    duty cycle measured
;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
repeatMeasure
		jsr	measureSignal
		
		movb	#1,isPrintingFreq
		ldx	measure_freq
		pshx
		jsr	toDec_start
		
		ldx	#promptMesDuty		;print out the resulting measure_duty
		jsr	outString
		movb	#0,isPrintingFreq
		ldx	measure_duty
		pshx
		jsr	toDec_start
		leas	4,sp		
		rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	initialMeasure
;	------------
;	Input:
;	   n/a
;	Output:
;	    frequency measured
;	    duty cycle measured
;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
initialMeasure
		jsr	measureSignal
		
		ldx	#promptMesFreq		;print out the resulting frequency
		jsr	outString
		movb	#1,isPrintingFreq
		ldx	measure_freq
		pshx
		jsr	toDec_start
		
		ldx	#promptMesDuty		;print out the resulting measure_duty
		jsr	outString
		movb	#0,isPrintingFreq
		ldx	measure_duty
		pshx
		jsr	toDec_start
		leas	4,sp		
		rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	measureSignal
;	------------
;	Input:
;	   n/a
;	Output:
;	    frequency measured
;	    duty cycle measured
;	    number of edges captured
;	    width of a pulse
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
measureSignal	
		;measureSignal	
		movw	#0,period		
		movb	#$90, TSCR1		; enable TCNT and fast timer flag clear
		movb	#$04, TSCR2		; PRESCALE 16
		ldab	TIOS
		andb	#$FD
		stab	TIOS
		ldab	TIE
		orab	#$02
		stab	TIE
		movb	#$04, TCTL4 		; capture rising edge on channel 1
		ldx	#0
		stx	num_edges
		cli
edge1		ldx	num_edges		; continue to wait for the arrival of the first edge
		cpx	#1
		bne	edge1
		movw	captured_edge,rising_edge1

		;bset	TSCR2, $04		; enable TCNT overflow interrupt, maining prescale factor of 16
		movb	#$08,TCTL4 		; capture falling edge on channel 1
edge2		ldx	num_edges
		cpx	#2
		bne	edge2			; continue to wait for the arrival of the second edge
		movw	captured_edge,falling_edge

		;bset	TSCR2, $04		; enable TCNT overflow interrupt, maining prescale factor of 16
		movb	#$04,TCTL4 		; capture rising edge on channel 1
edge3		ldx	num_edges
		cpx	#3
		bne	edge3			; continue to wait for the arrival of the third edge
		movw	captured_edge,rising_edge2

edge4		ldx	num_edges
		cpx	#4
		bne	edge4			; continue to wait for the arrival of the fourth edge
		movw	captured_edge,rising_edge3
		
		ldd	falling_edge
		subd	rising_edge1
		std	pulse_width		; counts of HIGH TIME

		ldd	rising_edge3		; load D with the counts at next rising edge
		subd	rising_edge2		; subtract the count at the first rising edge to get the period
		std	period
		
		;calculate Freq
		ldy	upper500		; calculate Frequency:
		ldd	lower500		; freq = 500 000 / No. of counts of Period	
		ldx	period
		ediv
		sty	measure_freq

		;calculate Duty Cycle
		ldd	#100			; duty cycle = Counts of Pulse Width x 100 / Counts of Period
		ldy	pulse_width
		emul
		ldx	period
		ediv
		cpy	#100
		blt	measureSig_sd
		exg	y,d
		subd	#100
		exg	y,d

		iny

measureSig_sd	sty	measure_duty	

		rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	serial_init
;	------------
;	Goal: Set up for repeated measurements
;	Input:
;	    n/a
;	Output:
;	    n/a
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
serial_setup
		clr	SC0CR1
		ldd	#52
		std	SC0BDH
		ldaa	#$0C
		staa	SC0CR2
		rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	serial_inChar
;	------------
;	Goal: Repeatedly measure the frequency every 1sec, w/ possibility of being stopped by user entering <cr>
;	Input:
;	    n/a
;	Output:
;	    n/a (functions inside output to console)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
serial_inChar
		jsr	serial_setup		;set up for repeated measurements
		jsr	initialMeasure		;call the initial measurements
		ldx	#0			;initialize the counters
		ldy	#0
serial_beginLoop
		ldaa	SC0SR1			;load the status register
		anda	#RDRF
		bne	serial_endLoop		;if the data register isn't full, keep trying. Branch when found
		inx
		cpx	#65000
		bne	serial_beginLoop	;inner loop occurs for extremely roughly ~0.1sec
		iny
		cpy	#12
		bne	serial_beginLoop	;outer loop multiplies the time of the inner loop by 'y'
		
serial_endLoop
		ldaa	SC0DRL			;when the data register is full
		staa	storedChar		;store its character
		psha

		ldd	numChars
		;exg	d,y
		pula
		addb	#21			;size of the prompt
		addb	numChars		;added with the number of characters in the frequency
serial_bcksp
		ldaa	#$08
		jsr	outOneCharInA
		decb
		cmpb	#0
		bne	serial_bcksp		;print the backspace character promptSize+freqSize times

		jsr	repeatMeasure		;perform another measurement

		ldaa	storedChar		;check the stored character
		cmpa	#$0D			;if it is not a <cr>, continue looping
		bne	serial_beginLoop
		rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	OVF_ISR
;	------------
;	Goal: increment the number of overflows if one occurs
;	Input:
;	    n/a
;	Output:
;	    store updated amount of overflows (incremented by 1)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ISR_EDGE	movw	TC1,captured_edge
		ldx	num_edges
		inx
		stx	num_edges
edge_done	rti


	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	ISR_GEN
;	------------
;	Goal: adds either the # of counts to be hi OR to be lo, depending on who's turn it is 
;	Input:
;	    comes in via TC0 and globals that specify the counts of hi/lo
;	Output:
;	    modified TC0 with the additional number of counts is stored
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ISR_GEN
		tst	HiorLo			;check if doing hi or lo
		beq	ISR_GEN_addLo

ISR_GEN_addHi	ldd	TC0
		addd	timeHi			;hi time
		std	TC0
		movb	#$00, HiorLo		;switch to lo
		bra 	ISR_GEN_done

ISR_GEN_addLo	ldd	TC0
		addd	timeLo			;lo time
		std	TC0
		movb	#$01, HiorLo		;switch to hi

ISR_GEN_done	rti

		
		end











