#ifndef _KERN_INIT
#include"kern.h"
#endif
enum{
K_PDT	=	0,
K_PT	=	1,
K_IDT	=	2,
K_GDT	=	3,
K_TSS0	=	4,
K_LDT0	=	5,
K_TSS1	=	6,
K_LDT1	=	7,
K_DATA	=	8,
K_FLP	=	9,
K_SEG	=	10
};


long _calc_pos(char *ch);
void _printk(char *ch);
void* memset(void *src,BYTE b,size_t len);
void* memcpy(void *src,void *dst,size_t len);
long klocate(int index);
long kpos();
void _printk0();
size_t strlen(char *ch);
void _clsr();
void spos(long p);	//save pos



