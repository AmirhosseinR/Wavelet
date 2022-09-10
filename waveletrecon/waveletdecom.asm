;waveletdecom.asm		
;prototype : void _wavelet_decom(int *x,unsigned int length,int *h_g
;					,unsigned int order,int *y_low,int *y_high,int *xbuffer);
;
;	Entry : arg1: AR0 : x - wavelet input buffer pointer
;			arg2: T0  : length - num of sample in input buffer
;			arg3: AR1 : h_g - wavelet coefficient array pointer
;			arg4: T1  : order - number of low or high wavelet coefficient
;			arg5: AR2 : y_low
;			arg6: AR3 : y_high
;			arg7: AR4 : xbuffer - signal buffer pointer

	.def _waveletdecom
	.text

_waveletdecom
	

    pshm	ST1_55             ; Save ST1, ST2, and ST3
    pshm 	ST2_55
    pshm	ST3_55

	OR 		#0X340, MMAP(ST1_55)	;SET FRCT,SXMD,SATD
;
;FRCT =1 : fractional mode is on.Result of multiply operation are shifted
;			left by 1 bit for decimal point adjustment.This require when
;				you multiply 2 signed Q15 Values and you need a Q31 
;					result.(spru374.pdf)
;
;SXMD=1 : Input operand are sign extended
;
;SATD=1 : If overflow is detected, the destination register is saturated to
;			7FFFH (positive overflow) or 8000H (nagavite overflow)
;
	BSET	SMUL
;
;SMUL=1 : saturation mode is on
;
;			SMUL=1 -\
;			FRCT=1   >	This force the product of 2 negative numbers
;			SATD=1 -/			to be a positive number
;
	MOV		MMAP(AR1), BSA01		;CIRCULAR BUFFER (AR1) START ADDRESS : h
	ADD 	T1,AR1				;AR1=AR1+T1 ,(T1= order)
	MOV		MMAP(AR1),BSA45			;CIRCULAR BUFFER (CDP) START ADDRESS : g
	MOV		MMAP(AR0), BSAC		;CIRCULAR BUFFER (AR0) START ADDRESS : xbuffer
	MOV		MMAP(T1), BK03			;CIRCULAR BUFFER SIZE : ORDER
	MOV		MMAP(T1), BK47
	MOV		MMAP(T0), BKC			;CIRCULAR BUFFER SIZE : length
	OR		#0X112, MMAP(ST2_55)	;ENABLE AR1=>h & AR6=>g & CDP=>xbuffer AS CICULAR POINTERS
	MOV		#0,AR1					;START FROM ZERO OFFSET
	MOV		#0,CDP
	MOV		#0,AR4

	SFTL	T0,#-1					;T0=T0>>1 => T0=T0/2	
	SUB		#1,T0
	MOV		T0,BRC0					;INITIALIZE OUTER LOOP FOR LENGTH


	SUB		#3, T1, T0				;T0=T1-3=order-3
	MOV		T0, CSR

	RPTBLOCAL	LOOP-1
	MPY		*AR1+,*CDP+,AC0
	::MPY	*AR4+,*CDP+,AC1
||	RPT		CSR
	MAC		*AR1+,*CDP+,AC0
	::MAC	*AR4+,*CDP+,AC1
	MACR	*AR1+,*CDP+,AC0
	::MACR	*AR4+,*CDP+,AC1
	MOV		HI(AC0),*AR2+
	MOV		HI(AC1),*AR3+
	AMAR	*CDP-
	AMAR	*CDP-
LOOP:

    popm	ST3_55             ; Restore ST1, ST2, and ST3
    popm	ST2_55 
    popm	ST1_55    	

	RET
    .end
