; http://vm02.cvs.sourceforge.net/viewvc/vm02/vm02/src/utils.s

;*
;* MULTIPLY BY 5 - TURN INDEX INTO CONSTANT POOL INTO OFFSET
;* ENTRY: AX = VALUE
;* EXIT:  AX = VALUE * 5
;*         C = OVERFLOW
;*
MUL5:	STA	TMP
	STX	TMP+1
	ASL
	ROL	TMP+1
	ASL
	ROL	TMP+1
	ADC	TMP
	PHA
	TXA
	ADC	TMP+1
	TAX
	PLA
	RTS
;*
;* MULTIPLY BY 7 - TURN INDEX INTO FIELD TABLE INTO OFFSET
;* ENTRY: AX = VALUE
;* EXIT:  AX = VALUE * 7
;*         C = OVERFLOW
;*
;MUL7:	STA	TMP
;	STX	TMP+1
;	ASL	TMP
;	ROL	TMP+1
;	ADC	TMP
;	PHA
;	TXA
;	ADC	TMP+1
;	TAX
;	PLA
;	ASL	TMP
;	ROL	TMP+1
;	ADC	TMP
;	PHA
;	TXA
;	ADC	TMP+1
;	TAX
;	PLA
;	RTS
;*
;* MULTIPLY BY 9 - TURN INDEX INTO FIELD TABLE INTO OFFSET
;* ENTRY: AX = VALUE
;* EXIT:  AX = VALUE * 9
;*         C = OVERFLOW
;*
MUL9:	STA	TMP
	STX	TMP+1
	ASL
	ROL	TMP+1
	ASL
	ROL	TMP+1
	ASL
	ROL	TMP+1
	ADC	TMP
	PHA
	TXA
	ADC	TMP+1
	TAX
	PLA
	RTS
;*
;* MULTIPLY BY 10 - TURN INDEX INTO METHOD TABLE INTO OFFSET
;* ENTRY: AX = VALUE
;* EXIT:  AX = VALUE * 10
;*         C = OVERFLOW
;*
MUL10:	STA	TMP		; Y = X + 4X = 5X
	STX	TMP+1
	ASL
	ROL	TMP+1
	ASL
	ROL	TMP+1
	ADC	TMP
	STA	TMP
	TXA
	ADC	TMP+1
	ASL	TMP		; RETURN Y * 4 = 5X * 2 = 10X
	ROL
	TAX
	LDA	TMP
	RTS
;*
;* MULTIPLY BY 20 - TURN INDEX INTO METHOD TABLE INTO OFFSET
;* ENTRY: AX = VALUE
;* EXIT:  AX = VALUE * 20
;*         C = OVERFLOW
;*
;MUL20:	STA	TMP		; Y = X + 4X = 5X
;	STX	TMP+1
;	ASL
;	ROL	TMP+1
;	ASL
;	ROL	TMP+1
;	ADC	TMP
;	STA	TMP
;	TXA
;	ADC	TMP+1
;	ASL	TMP		; RETURN Y * 4 = 5X * 4 = 20X
;	ROL
;	ASL	TMP
;	ROL
;	TAX
;	LDA	TMP
;	RTS
