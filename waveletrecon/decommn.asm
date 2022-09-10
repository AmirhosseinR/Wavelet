;****************************************************************
; Function:    	decom
; Version:     	1.00
; Processor:   	C55xx
; Description: 	1D gerneral purpose wavelet decomposition
;              
; Usage:  	   	decom( int *singal, int *output, 
;						  int LENGTH, int *wavename );
;                                     
; Arguments:	
;    signal:   	the signal buffer
;    output:    output buffer, the low-pass output save in the first
;               half of the output buffer, and the high-pass 
;				output saved in the second half of the output buffer
;    LENGTH:	number of signal elements
;  wavename:    the wavelet filter coefficients 
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
      .asg     CDP, input           ;input data, circular pointer
      .asg     AR1, low_out         ;low output, linear pointer
      .asg     AR2, high_out        ;high output, linear pointer
      .asg     AR3, low_filter	    ;low_pass filter, circular pointer
      .asg     AR4, high_filter     ;high_pass filter, circular pointer
     
      .asg     XAR1, xlow_out       ; extended low output
      .asg     XAR2, xhigh_out      ; extended high output
      .asg     BSAC, input_base     ;base addr for input_ptr
      .asg     BSA45, high_fl_base  ;base addr for low_filter
      .asg     BSA23, low_fl_base   ;base addr for high_filter
      
      .asg     BK03, low_fl_sz      ;circ buffer size for filter_sz
      .asg     BK47, high_fl_sz     ;circ buffer size for filter_sz 
      .asg     BKC,  input_sz       ;input circular buffer size
    

      .asg     CSR, inner_cnt       ;inner loop count
      .asg     BRC0, outer_cnt      ;outer loop count

ST2mask  .set  0000000100011000b   	;circular/linear pointers


      .global _decom_1D

      .text
_decom:

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
	MOV		mmap(AR0), input_base	;base address of input 
	MOV		*AR2+, T1				;length of filter
    MOV		mmap(AR2), low_fl_base	;base address of low_pass filter
    AMAR 	*(AR2+T1)              	;point to high_pass filter
	MOV		mmap(AR2), high_fl_base	;base address of high_pass filter
	
	MOV		#0,	input               ;reset input buffer index
	MOV		#0, low_filter          ;reset low_pass filter index
	MOV		#0, high_filter         ;reset high_pass filter index
	
	MOV		mmap(T1), low_fl_sz	    ;low_pass filter circular buffer size
    MOV		mmap(T1), high_fl_sz    ;high_pass filter circular buffer size
    MOV 	mmap(T0), input_sz      ;input circular buffer size  
        
; Set circular/linear ARx behavior

	MOV		#ST2mask, mmap(ST2_55)	;configure circular/linear pointers
;
; Setup loop counts
;----------------------------------------------------------------
	SFTL	T0, #-1             	;output_length = input_length>>1
	MOV		xlow_out, xhigh_out   	;low output buffer
	ADD		#0, *(high_out+T0)  	;high output buffer
	
	SUB		#1, T0         
	MOV		T0, outer_cnt           ;outer loop executes times    
	
	SUB		#3, T1      
	MOV		T1, inner_cnt       	;inner loop executes times
	NEG		T1, T0              	;T0 is used to reset input pointer
                                       
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
	MOV	HI(AC0), *low_out+	        ;store short result to low_out buffer
	::MOV	HI(AC1), *high_out+     ;store short result to high_out buffer
	
loop1:					            ;end of outer loop

;
; Restore status regs to expected C-convention values as needed
;----------------------------------------------------------------
	BCLR	FRCT			        ;clear FRCT

	AND	#0FE00h, mmap(ST2_55)	    ;clear CDPLC and AR[7-0]LC

	BSET	ARMS			        ;set ARMS

;
; Return to calling function
;----------------------------------------------------------------
	||RET							;return to calling function

;----------------------------------------------------------------
;End of file
