
#include <stdio.h>
#include <stdlib.h>   
#include <math.h>
#include <imagelib.h>
#include <wavelet.h>

#define length    16       /* Input sample size */
#define order     4       /* Number of FIR filter coefficients */

extern void waveletdecom(int *, unsigned int, int *, unsigned int, int *, int *,int *);
extern void waveletrecon(int *, int *, int *, int,int *, int , int *);

/* wavelet coefficients */
int h_gDecom[order*2]=
{
	15825,   27410,    7344,   -4240,
	-4240,   -7344,   27410,  -15825
};
int h_gRecon[order*2]=
{
	 7344,	15825,	 27410,	-4240,
	-4240,	27410,	-15825,	-7344
};
int input[length]={100, 200, 300, -100, 100, -400, -200, 400,-50,14,59,580,-4,-450,666,75};

unsigned int i;
int x[length];

short signal[length];	       /* Output buffer */
int y_low[length/2];
int y_high[length/2];
short temp_wksp[length];

int xbuffer1[order],xbuffer2[order]; 
  
void main(void)
{
    for (i=0; i<order; i++)
		xbuffer2[i]=0;
	for (i=0; i<length; i++)
	{
	x[i]=input[i];	/* Get a buffer of samples */
	signal[i]=input[i];
	}

waveletdecom(x,length,h_gDecom,order,y_low,y_high,xbuffer1);
IMG_wave_decom_one_dim( signal, temp_wksp, db2,  length,1 );

waveletrecon(y_low,y_high,x,length,h_gRecon,order, xbuffer2);
IMG_wave_recon_one_dim( signal, temp_wksp, db2, length, 1 );

}
