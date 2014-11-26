#include"kern.h"
#include"klib.h"

//{{{void* klocate(int index) 定位核心表地址的函数
void* klocate(int index)
{
	struct _SYS_TABLE *p;
	void *p1;
	p=(struct _SYS_TABLE *)SYS_TABLE_INDEX;
	switch(index)
	{
	case K_PDT:
		p1=(void *)p->pdt_off;
		break;
	case K_PT:
		p1=(void *)p->pt_off;
		break;
	case K_IDT:
		p1=(void *)p->idt_off;
		break;
	case K_GDT:
		p1=(void *)p->gdt_off;
		break;
	case K_TSS0:
		p1=(void *)p->tss0_off;
		break;
	case K_LDT0:
		p1=(void *)p->ldt0_off;
		break;
	case K_TSS1:
		p1=(void *)p->tss1_off;
		break;
	case K_LDT1:
		p1=(void *)p->ldt1_off;
		break;
	case K_DATA:
		p1=(void *)p->sys_data;
		break;
	case K_FLP:
		p1=(void *)p->sys_flp;
		break;
	case K_SEG:
		p1=(void *)p->sys_seg;
		break;
	};
	return p1;
}
//}}}
//{{{long kpos() 获得光标位置的函数
long kpos()
{
	struct _SYS_DATA *sd=(struct _SYS_DATA *)0;
	return sd->pos;
}
//}}}
//{{{void _printk0() 通用中断中用于显示一个字符的函数-临时函数
void _printk0()
{
	int i;
	struct _SYS_SEG *ss=(struct _SYS_SEG *)klocate(K_SEG);
	i=ss->kdisp;
	__asm__
		("pusha;push %%es;movw %%ax,%%es;\
		 movl $158,%%edi;movl $0x0a41,%%eax;\
		 stosw;pop %%es;popa;"::"a"(i)
		);
	return;
}
//}}}
//{{{void* memset(void *src,BYTE b,size_t len)
void* memset(void *src,BYTE b,size_t len)
{
	void *p=src;
//这里之所以这样写，是因为我测试的c函数的ds和es一致。	
	__asm__
		("movl %0,%%edi;rep stosb;"::"m"(src),"a"(b),"c"(len));
	return p;
}//}}}
//{{{void* memcpy(void *src,void *dst,size_t len)
void* memcpy(void *src,void *dst,size_t len)
{
	void *p=src;
	__asm__
		("movl %0,%%esi;movl %1,%%edi;\
		 rep movsb;"::"m"(src),"m"(dst),"c"(len));
}//}}}
//{{{long _calc_pos(char *ch) 取得本次显示的位置，并计算保存下次显示位置
long _calc_pos(char *ch)
{
	int i,j,k,len;
	len=(int)strlen(ch);
	len*=2;
	k=(int)kpos();
	i=k/160;j=k%160;
	if(i>24)
	{
		_clsr();
		spos((long)(len+2));
		return 0;
	}
	if((j+len)>=160)
	{
		i++;j=i*160;
		k=j+len+2;
		spos((long)k);
		return (long)j;
	}
	j=k+len+2;
	spos((long)j);
	return (long)k;
}
//}}}
//{{{size_t strlen(char *ch) 取得字符串长度
size_t strlen(char *ch)
{
	size_t t=0;
	char *p=ch;
	while(*p!=0)
	{
		t++;p++;
	}
	return t;
}
//}}}
//{{{void _clsr() 清屏函数
void _clsr()
{
	struct _SYS_SEG *ss=(struct _SYS_SEG*)klocate(K_SEG);
	int i=(int)(ss->kdisp);
	__asm__
		("push %%es;movw %0,%%es;\
		 movl $0,%%edi;movl $0x7d0,%%ecx;\
		 movl $0x20,%%eax;rep stosw;\
		 pop %%es;"::"a"(i));
	return;
}
//}}}
//{{{void spos(long p) 保存新的光标位置
void spos(long p)
{
	struct _SYS_DATA *sd=(struct _SYS_DATA *)klocate(K_DATA);
	sd->pos=p;
	return;
}
//}}}
//{{{void _printk(char *ch) 内核信息打印函数
void _printk(char *ch)
{
	struct _SYS_SEG *ss=(struct _SYS_SEG*)klocate(K_SEG);
	int i=(int)(ss->kdisp);
	int p=(int)_calc_pos(ch);
	int len=(int)strlen(ch);
	__asm__
		("push %%es;movw %0,%%es;movl %1,%%esi;\
		 movl $0x0b00,%%eax;1:;lodsb;stosw;loop 1b;\
		 "::"a"(i),"m"(ch),"c"(len),"D"(p));
	return;
}
//}}}

















