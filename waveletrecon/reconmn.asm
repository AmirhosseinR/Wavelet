;****************************************************************
; Function:    	recon
; Version:     	1.00
; Processor:   	C55xx
; Description: 	reconstruction wavelet-decompsed signal
; 
; Usage:		recon( int *input, int *output, 
;						  int length, int *wavename );      
; Note:			before calling the function, interlace() should be
;				called first. In other word, the input buffer is 
;				the interlaced signal of the filter bank outputs
;                               
; Arguments:
;     input:	interlaced filter bank outputs
;    output:    output buffer
;    length:    size of input buffer
;  wavename:    wavelet filter coefficients
;
; Copyright Texas instruments Inc, 2000
;****************************************************************

      .ARMS_off                     ;enable assembler for ARMS=0
      .CPL_on                       ;enable assembler for CPL=1
      .mmregs                       ;enable mem mapped register names

; Stack frame
; -----------
RET_ADDR_SZ       .set 1            ;return address
REG_SAVE_SZ       .set 0            ;save-on-entry registers saved
FRAME_SZ          .set 0            ;local variables
ARG_BLK_SZ        .set 0            ;argument block

PARAM_OFFSET      .set ARG_BLK_SZ + FRAME_SZ + REG_SAVE_SZ + RET_ADDR_SZ


; Register usage
; --------------
      .asg     CDP, input           ;circular pointer
      .asg     AR1, output         	;linear pointer
      .asg     AR2, low_filter	    ;circular pointer
      .asg     AR4, high_filter     ;circular pointer
     
                   
      .asg	   BSAC, input_base		;base addr for input
      .asg     BSA23, low_fl_base   ;base addr for low_filter
      .asg     BSA45, high_fl_base	;bass addr for high_filter
                                                              
      .asg     BKC, input_sz		;input circular buffer size
      .asg     BK03, low_fl_sz      ;circ buffer size for filter_sz
      .asg     BK47, high_fl_sz     ;circ buffer size for filter_sz 

      .asg     CSR, inner_cnt       ;inner loop count
      .asg     BRC0, outer_cnt      ;outer loop count

ST2mask  .set  0000000100010100b  	;circular/linear pointers

      .global _recon_1D

      .text
_recon:

;
; Configure the status registers as needed.
;----------------------------------------------------------------

	AND	#001FFh, mmap(ST0_55)		;clear all ACOVx,TC1, TC2, C
 
	OR	#04140h, mmap(ST1_55)		;set CPL, SXMD, FRCT

	AND	#0F9DFh, mmap(ST1_55)		;clear M40, SATD, 54CM    
    
	AND	#07A00h, mmap(ST2_55)		;clear ARMS, RDM, CDPLC, AR[0-7]LC

	AND	#0FFDDh, mmap(ST3_55)		;clear SATA, SMUL       
	
;
; Setup passed parameters in their destination registers
; Setup circular/linear CDP/ARx behavior
;----------------------------------------------------------------
   	MOV	 	*AR2+, T1				;length of filter
    AMAR 	*(AR2+T1)				
    AMAR 	*(AR2+T1)               ;AR2 point to lower rec filter
    MOV		mmap(AR2), low_fl_base	;get the low_pass filter address
    
    AMAR 	*(AR2+T1)               ;AR2 point to higher rec filter
	MOV		mmap(AR2), high_fl_base	;get the high_pass filter address

; Set circular/linear ARx behavior

	MOV	#ST2mask, mmap(ST2_55)		
	
	MOV		#0, low_filter		    	
	MOV		#0, high_filter		    	   
	
	MOV		mmap(T1), low_fl_sz		    
    MOV		mmap(T1), high_fl_sz		    
    MOV 	mmap(T0), input_sz		
 
;
; Setup loop counts
;----------------------------------------------------------------
	SFTL    T0, #-1         		;T0 = T0/2-1, input length
	SUB     #1, T0
	MOV	    T0, outer_cnt   		;outer loop executes nr times
	
	SUB		#3, T1      
	MOV		T1, inner_cnt   		;inner loop executes times
	NEG		T1, T0          		;T0 is used to reset input pointer   
	
	MOV		#0,	input					
	MOV		mmap(AR0), input_base	;base address of input             
	
;
; Start of outer loop
;----------------------------------------------------------------
	RPTBLOCAL	loop1-1				;start the outer loop
    
;1st iteration                                          
	
  	MPY	*low_filter+, *input+, AC0
	::MPY	*high_filter+, *input+, AC1
   
;inner loop
	||RPT	inner_cnt
	MAC	*low_filter+, *input+, AC0
	::MAC	*high_filter+, *input+, AC1

;last iteration
	MAC	*low_filter+, *(input+T0), AC0
	::MAC	*high_filter+, *(input+T0), AC1
	
  
;store result to memory
	MOV	HI(AC0), *output+			;store short result to memory
	MOV	HI(AC1), *output+			;store short result to memory
	
loop1:								;end of outer loop

;
; Restore status regs to expected C-convention values as needed
;----------------------------------------------------------------
	BCLR	FRCT					;clear FRCT

	AND	#0FE00h, mmap(ST2_55)		;clear CDPLC and AR[7-0]LC

	BSET	ARMS					;set ARMS

;
; Return to calling function
;----------------------------------------------------------------
	||RET							;return to calling function

;----------------------------------------------------------------
;End of file
