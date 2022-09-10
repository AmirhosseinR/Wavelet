/*********************************************************************
* $RCSfile: dsk5510x.cmd,v $
* $Revision: 1.4 $
* $Date: 2001/09/19 19:02:35 $
* Copyright (c) 1997 Texas Instruments Incorporated
*
* Description:
*       This file is a sample command file that can be used
*       for linking programs built with the LEAD 3 C Compiler.
*       Use it as a guideline; you  may want to change the
*       allocation scheme according to the size of your program
*       and the memory layout of your target system.
*
* Usage:
*       lnk55x <obj files...>    -o <out file> -m <map file> lnk.cmd
*       cl55x  <src files...> -z -o <out file> -m <map file> lnk.cmd
/********************************************************************/
-c
-stack 0x1000                   /* PRIMARY STACK SIZE               */
-sysstack 0x1000                /* SECONDARY STACK SIZE             */
-heap  0x1000                   /* HEAP AREA SIZE                   */

/* This symbol defines the interrupt mask to be applied to IER inside
   RTDX Critical Code sections.
   The LSB 16bits => IER0, MSB 16bits => IER1

   This example masks IE4 (timer) and DLOGINT (for RTDX) on a C5510.
*/
_RTDX_interrupt_mask = ~0x02000010; /* interrupts masked by RTDX    */


/* Set entry point to Reset vector                                  */
/* - Allows Reset ISR to force IVPD/IVPH to point to vector table.  */
-e RESET_ISR

/* SPECIFY THE SYSTEM MEMORY MAP                                    */
/* - Loader/Linker only uses Byte-addresses.                        */
MEMORY
{
        PAGE 0:
                MMR (RWIX)      : o=0000000h, l=00000C0h
                DARAM0 (RWIX)   : o=00000C0h, l=000FF40h
                SARAM0 (RWIX)   : o=0010000h, l=0010000h
                SARAM1 (RWIX)   : o=0020000h, l=0020000h
                SARAM2 (RWIX)   : o=0040000h, l=0010000h
                SDRAM  (RWIX)   : o=0050000h, l=0100000h
                FLASH (RX)      : o=0400000h, l=0200000h
                CPLD  (RX)      : o=0600000h, l=0200000h
       /* Addresses in CE2 and CE3 are reserved for use
        with a daughter card.  If used, a user will have
        to map this memory depending on what is residing
        in these addresses */
       
         PAGE 2:
                IOPORT (RWI)    : o=0000000h, l=0020000h
}

/* SPECIFY THE SECTIONS ALLOCATION INTO MEMORY                      */
SECTIONS
{
	/* The power-up vector location is NOT writable.            */
	/* - So vectors must be loaded at a different address.      */
        /* .intvecs        > 0ffff00h                               */
        .intvecs        > SARAM2

        /*
         * To illustrate Large Memory Model, we will arrange sections
         * so references have "far" offsets.
         */

        .text           > SARAM2                /* CODE             */
        .rtdx_text      > SARAM2                /* RTDX CODE        */
        .switch         > SARAM2                /* SWITCH TABLE INFO      */
        .const          > SARAM2                /* CONSTANT DATA    */
        .cinit          > SARAM2                /* INITIALIZATION TABLES  */
        .pinit          > SARAM2                /* INITIALIZATION TABLES  */

        .data           > DARAM0 fill=0xBEEF    /* INITIALIZED DATA */
        .rtdx_data      > DARAM0 fill=0xBEEF    /* RTDX DATA        */
        .bss            > DARAM0 fill=0xBEEF    /* GLOBAL & STATIC VARS   */
        .sysmem         > DARAM0 fill=0xBEEF    /* DYNAMIC MALLOC AREA    */
        .stack          > DARAM0 fill=0xBEEF    /* PRIMARY SYSTEM STACK   */
        .sysstack       > DARAM0 fill=0xBEEF    /* SECONDARY SYSTEM STACK */
        .cio            > DARAM0 fill=0xBEEF

        .ioport         > IOPORT PAGE 2
}
