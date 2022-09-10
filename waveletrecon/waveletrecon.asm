;waveletrecon.asm
;
; prototype : void waveletrecon(int *Xlow, int *Xhigh, int *yOut, int length,
;								int *hgRecon, int order, int *buffer)
;
; Entry : 	arg1 :	AR0 - Xlow  : s*
;			arg2 :	AR1 - Xhigh : d*
;			arg3 :	AR2 - yOut  : S
;			arg4 :	T0  - length
;			arg5 :	AR3 - hgRecon : wavelet coeficients
;			arg6 :	T1  - order : Length of hgRecon/2
;			arg7 :	AR4 - buffer
;
	
	.def _waveletrecon
	.text

_waveletrecon

    PSH		AR5
    pshm	ST1_55            		 ; Save ST1, ST2, and ST3
    pshm 	ST2_55
    pshm	ST3_55

	OR 		#0X340, MMAP(ST1_55)	;SET FRCT,SXMD,SATD
	BSET	SMUL
	MOV		MMAP(AR3), BSA23		;CIRCULAR BUFFER (AR3) START ADDRESS : h_g even	
	ADD		T1, AR3
	MOV		MMAP(AR3), BSA45		;CIRCULAR BUFFER (AR5) START ADDRESS : h_g odd
	MOV		MMAP(AR4), BSAC			;CIRCULAR BUFFER (CDP) START ADDRESS : BUFFER
	MOV		MMAP(T1), BK03			;CIRCULAR BUFFER SIZE : ORDER
	MOV		MMAP(T1), BK47
	MOV		MMAP(T1), BKC			;CIRCULAR BUFFER SIZE : ORDER
	OR		#0X128, MMAP(ST2_55)	;ENABLE AR3=>h & AR5=>g & CDP=>xbuffer AS CICULAR POINTERS


	MOV		#0,AR3
	MOV		#0,AR5
	MOV		#0,CDP



	MOV 	T1,T3					;T3=T1=ORDER
	SFTL	T0,#-1					;T0=LENGTH/2
	MOV		T0,T2					;T2=LENGTH/2

	SUB		#1,T0
	MOV		T0,BRC0
	MOV		T2,T0
	NEG		T0						;T0=-LENGTH/2
	SFTL	T1,#-1					;T1=ORDER/2
	SUB		T1,T2					;T2=LENGTH/2 - ORDER/2
	ADD		#1,T2								;T2=LENGTH/2 - ORDER/2 + 1
	SUB		#2,T1					;T1=ORDER/2 - 2
	ADD		T2,AR0
	ADD		T2,AR1
	MOV		T1,CSR
	RPT		CSR
	MOV		*AR0+,*CDP+
	AMAR	*(AR0+T0)
	MOV		*AR0+,*CDP+
	RPT		CSR
	MOV		*AR1+,*CDP+
	AMAR	*(AR1+T0)
	MOV		*AR1+,*CDP+

	MOV		T3,T1					;T1=ORDER
	SUB		#3,T1,T0				;T0=ORDER-3
	MOV		T0,CSR
	ADD		#1,T0

	RPTBLOCAL	LOOP-1
    mpy  	*AR3+,*CDP+,AC0    		; The first operation
::  mpy  	*AR5+,*CDP+,AC1
||  rpt  	CSR
    mac		*AR3+,*CDP+,AC0    		; The rest MAC iterations
::  mac		*AR5+,*CDP+,AC1     
    macr	*AR3+,*CDP+,AC0
::  macr	*AR5+,*CDP+,AC1     		; The last MAC operation 
    MOV		HI(AC0),*AR3+
	MOV		HI(AC1),*AR3+
	MOV		*AR1+,*(CDP+T0)
	MOV		*AR0+,*(CDP+T0)
	AMAR	*CDP+
LOOP:
    popm	ST3_55
    popm 	ST2_55
	popm	ST1_55
	POP		AR5
	RET
	.END