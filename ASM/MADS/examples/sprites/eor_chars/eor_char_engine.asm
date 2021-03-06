
/*
 v3.0 - naj najszybsza, kosztem pami?ci (obs?uga 1 ducha zajmuje prawie $300 bajt?w pami?ci),
 	do obs?ugi ducha potrzebna osobna procedura (np. 8 duch?w = 8 procedur)

 Silnik ten dzia?a na zasadzie EOR-owania obrazu, wykorzystuje tylko 1 bufor obrazu, potrzebuje $300 bajt?w pami?ci
 na obs?ug? 1 ducha, nie ma potrzeby zapami?tywania ani od?wie?ania zawarto?ci ekranu po wy?wietleniu ducha.

 Przesuni?cia bit?w zosta?y stablicowane ShiftRight2H:ShiftRight2L, ShiftRight4H:ShiftRight4L, ShiftRight6H:ShiftRight6L

 *** !!! Dokonywane jest przesuni?cie JEDNEJ bitmapy ducha z aktualnej pozycji, bitmapa z poprzedniej pozycji jest w buforze !!! ***

 !!! Maksymalna wysoko?? przetwarzanych duch?w wynosi 128/ShapeWidth !!!

 !!! Minimalna szeroko?? duch?w ShapeWidth = 2..5 !!!

 Ca?y silnik sk?ada si? z jednej procedury PutShape

 PutShape	procedura realizuj?ca kopiowanie bitmapy ducha do bufora, przesuwanie bit?w bitmapy ducha,
 		umieszczanie nowo przeliczonej bitmapy w odpowiednim obszarze pami?ci (obszarze pami?ci obrazu)


 SCHEMAT DZIA?ANIA:

 0. X = $80
    wyzeruj obszar ShapeBuffer[0..127]
 
 1. przepisz_bitmape_dla_ducha_i_przesu?_jej_pixle w obszarze ShapeBuffer[X..X+127]

 2. if X<>0
	duch0 EOR dane_obrazu_o_wsp??rz?dnych_dla_ducha0
    	duch1 EOR dane_obrazu_o_wsp??rz?dnych_dla_ducha1
    else
	duch1 EOR dane_obrazu_o_wsp??rz?dnych_dla_ducha0
    	duch0 EOR dane_obrazu_o_wsp??rz?dnych_dla_ducha1
    endif

 4. X = X eor $80

 5. goto 1

*/


; $26 linii skaningowych (maksymalna pr?dko?? silnika dla ducha o rozmiarze 32x16 pixli Hires)
; $1e linii skaningowych (maksymalna pr?dko?? silnika dla ducha o rozmiarze 24x16 pixli Hires)
; $16 linii skaningowych (maksymalna pr?dko?? silnika dla ducha o rozmiarze 16x16 pixli Hires)
; $0e linii skaningowych (maksymalna pr?dko?? silnika dla ducha o rozmiarze 8x16 pixli Hires)


ScreenWidth	= 40		; szeroko?? obrazu

ShapeWidth	= 4		; width+1, szeroko?? przetwarzanych duch?w w bajtach (+1 dodatkowy bajt)

	ert ShapeWidth<2||ShapeWidth>5

* -------------------------------------------------------------------

ShapeBuffer	.ds 256
ShapeBuffer0	= ShapeBuffer		; bufor pomocniczy dla ducha #0 (koniecznie w obszarze strony pami?ci)
ShapeBuffer1	= ShapeBuffer+128	; bufor pomocniczy dla ducha #1 (koniecznie w obszarze strony pami?ci)

ShiftRight2H	:256 dta h([#<<8]>>2)
ShiftRight2L	:256 dta l([#<<8]>>2)

ShiftRight4H	:256 dta h([#<<8]>>4)
ShiftRight4L	:256 dta l([#<<8]>>4)

ShiftRight6H	:256 dta h([#<<8]>>6)
ShiftRight6L	:256 dta l([#<<8]>>6)

mulTab0		:128/ShapeWidth dta #*ShapeWidth	; pomocnicza tablica mno?enia (oszcz?dzamy dzi?ki niej pare cykli)
mulTab1		:128/ShapeWidth dta #*ShapeWidth+$80	; pomocnicza tablica mno?enia (oszcz?dzamy dzi?ki niej pare cykli)

* -------------------------------------------------------------------

tabShiftH	dta h(0, ShiftRight2H, ShiftRight4H, ShiftRight6H)

;tabShiftL	dta h(0, ShiftRight2L, ShiftRight4L, ShiftRight6L)

* -------------------------------------------------------------------


main	lda #16
	sta height

	lda #15*4
	sta positionX

	lda #12*8
	sta positionY

	lda #0
	sta type


	lda <mulTab1			; init default value
	sta PutShape.E_95df+1

	lda <ShapeBuffer1
	sta PutShape.E_9591+1

.nowarn	lda #{bmi}
	sta PutShape.loopShf


loop
	lda:rne $d40b
	

	mva #$0f $d01a

	jsr putShape

	inc positionX

	inc positionY
	lda positionY
	cmp #204-32
	scc
	lda #0

	sta positionY

	mva #$00 $d01a

	lda $d40b
	cmp $100
	scc
	sta $100	; tutaj zapisujemy aktualn? szybko?? wy?wietlenia ducha

	jmp loop


* -------------------------------------------------------------------
* ---	WY?WIETLENIE DUCH?W PROGRAMOWYCH W POLU GRY
* ---	PRZETWARZANE S? DWA DUCHY, ShapeBuffer0 (#0) i ShapeBuffer1 (#1)
* ---	DUCH NA POZYCJI POPRZEDNIEJ ORAZ DUCH NA POZYCJI AKTUALNEJ
* ---	NIE MA POTRZEBY OD?WIE?ANIA POLA GRY STAR? ZAWARTO??I?
* -------------------------------------------------------------------
.proc	PutShape

E_958f	ldy type

E_9591	ldx	<ShapeBuffer1		; !!! koniecznie zaczynamy od <ShapeBuffer1 !!!

	mva	lAdrShape,y	ScreenAdr1
	mva	hAdrShape,y	ScreenAdr1+1

	ldy height			; wysoko?? ducha

	txa
	add mulTab0,y
	sta max				; wysoko?? ducha*ShapeWidth+<ShapeBuffer

	ldy #0

moveShp
	.rept ShapeWidth
	ift #<>ShapeWidth-1
	lda (ScreenAdr1),y		; przenosimy do bufora bitmape ducha
	sta ShapeBuffer+#,x
	iny
	els
	lda #0
	sta ShapeBuffer+#,x		; ostatni bajt jest zerowany
	eif
	.endr

;	clc
	txa
	adc #ShapeWidth
	tax

	cpx #0
max	equ *-1
	bne moveShp


E_95d4	lda positionX			; pozycja pozioma ducha #1
	and #$03
	beq E_9602

	tay
	ldx tabShiftH,y

	ift .def tShfH0
	stx tShfH0+2
	eif

	ift .def tShfH1
	stx tShfH1+2
	eif

	ift .def tShfH2
	stx tShfH2+2
	eif

	ift .def tShfH3
	stx tShfH3+2
	eif

	ift .def tShfH4
	stx tShfH4+2
	eif

	inx

	ift .def tShfL0
	stx tShfL0+2
	eif

	ift .def tShfL1
	stx tShfL1+2
	eif

	ift .def tShfL2
	stx tShfL2+2
	eif

	ift .def tShfL3
	stx tShfL3+2
	eif

E_95dc	ldy height			; wysoko?? ducha
	dey

E_95df	ldx mulTab1,y			; !!! koniecznie zaczynamy od mulTab1 !!!

	sec

shift	ldy ShapeBuffer,x
tShfH0	lda $ff00,y
	sta ShapeBuffer,x
tShfL0	lda $ff00,y

	ldy ShapeBuffer+1,x
tShfH1	ora $ff00,y
	sta ShapeBuffer+1,x

	ift ShapeWidth>2
tShfL1	lda $ff00,y

	ldy ShapeBuffer+2,x
tShfH2	ora $ff00,y
	sta ShapeBuffer+2,x
	eif

	ift ShapeWidth>3
tShfL2	lda $ff00,y

	ldy ShapeBuffer+3,x
tShfH3	ora $ff00,y
	sta ShapeBuffer+3,x
	eif

	ift ShapeWidth>4
tShfL3	lda $ff00,y

	ldy ShapeBuffer+4,x
tShfH4	ora $ff00,y
	sta ShapeBuffer+4,x
	eif

	txa
	sbc #ShapeWidth
	tax

loopShf	bmi shift


E_9602	ldy height

	ldx mulTab0,y
	dex				; wysoko?? ducha*ShapeWidth-1 = d?ugo?? danych ducha (!!! regX !!!)

	lda positionY_old		; pozycja pionowa ducha #0
	clc
	adc height			; wysoko?? ducha
	sta b10.posY0+1
	sta b01.posY0+1

	lda positionX_old		; pozycja pozioma ducha #0
	asl @
	and #$f8
	sta b10.posX0+1
	sta b01.posX0+1


	lda positionY			; pozycja pionowa ducha #1
	clc
	adc height			; wysoko?? ducha 
	sta b10.posY1+1
	sta b01.posY1+1

	lda positionX			; pozycja pozioma ducha #1
	asl @
	and #$f8
	sta b10.posX1+1
	sta b01.posX1+1

	lda E_9591+1
	bne b01

b10	.local

posY0	ldy #0
posX0	lda #0
	clc
	adc lAdrLine,y
	sta ScreenAdr0
	lda #$00
	adc hAdrLine,y
	sta ScreenAdr0+1		; adres pierwszego bajtu ekranu dla ducha #0

posY1	ldy #0
posX1	lda #0
	clc
	adc lAdrLine,y
	sta ScreenAdr1
	lda #$00
	adc hAdrLine,y
	sta ScreenAdr1+1		; adres pierwszego bajtu ekranu dla ducha #1

	?tmp = [ShapeWidth-1]*8		; przenosimy duchy od do?u do g?ry (pewnie w celu zminimalizowania mrugania)

	.rept ShapeWidth
	ldy #?tmp

	lda ShapeBuffer1-#,x
	eor (ScreenAdr0),y
	sta (ScreenAdr0),y

	lda (ScreenAdr1),y		; je?li bajt t?a to nie ma kolizji
	eor ShapeBuffer0-#,x
	sta (ScreenAdr1),y

	?tmp -= 8
	.endr

	dec posY0+1
	dec posY1+1

	txa
	sub #ShapeWidth
	tax

	bpl b10
	bmi quit

	.endl


b01	.local

posY0	ldy #0
posX0	lda #0
	clc
	adc lAdrLine,y
	sta ScreenAdr0
	lda #$00
	adc hAdrLine,y
	sta ScreenAdr0+1		; adres pierwszego bajtu ekranu dla ducha #0

posY1	ldy #0
posX1	lda #0
	clc
	adc lAdrLine,y
	sta ScreenAdr1
	lda #$00
	adc hAdrLine,y
	sta ScreenAdr1+1		; adres pierwszego bajtu ekranu dla ducha #1

	?tmp = [ShapeWidth-1]*8		; przenosimy duchy od do?u do g?ry (pewnie w celu zminimalizowania mrugania)

	.rept ShapeWidth
	ldy #?tmp

	lda ShapeBuffer0-#,x
	eor (ScreenAdr0),y
	sta (ScreenAdr0),y

	lda (ScreenAdr1),y		; je?li bajt t?a to nie ma kolizji
	eor ShapeBuffer1-#,x
	sta (ScreenAdr1),y

	?tmp -= 8
	.endr

	dec posY0+1
	dec posY1+1

	txa
	sub #ShapeWidth
	tax

	bpl b01

	.endl

quit
	mva	positionX	positionX_old
	mva	positionY	positionY_old

	lda E_95df+1			; prze??czenie bufor?w
	eor #[<mulTab0]^[<mulTab1]
	sta E_95df+1

	lda E_9591+1
	eor #[<ShapeBuffer0]^[<ShapeBuffer1]
	sta E_9591+1

	lda loopShf
.nowarn	eor #{bpl}^{bmi}
	sta loopShf

	rts
.endp


* ---------------------------------

lAdrShape	dta l(krab)
hadrShape	dta h(krab)

	.get 'crab.mic'

krab	@@CutMIC 0 0 ShapeWidth-1 16

* ---------------------------------

	opt l-
	icl '@@cutmic.mac'
