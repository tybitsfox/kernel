/*kern.h	2014-11-26	tybitsfox
 本文件定义了内核模块所需的各类核心表的信息、所有中断处理程序的实现以及任务调度和内存管理进程函数的声明
 具体而通用的功能函数将在klib.h中定义。
 */
#ifndef	_KERN_INIT
#define _KERN_INIT		tkernel_01
#define	BYTE	unsigned char
#define WORD	unsigned short
#define size_t	unsigned int
#endif
//定义系统表的索引，=内核数据段中的偏移,偏移0存放_sys_data结构，随后存_sys_table
#define	SYS_TABLE_INDEX	0x100012
//{{{ 下面结构定义了各系统表的存储信息 struct _SYS_TABLE
struct _SYS_TABLE
{
	long		pdt_off;		//pdt的段内偏移
	size_t		pdt_len;		//pdt表长
	long		pt_off;
	size_t		pt_len;
	long		idt_off;
	size_t		idt_len;
	long		gdt_off;
	size_t		gdt_len;
	long		tss0_off;
	size_t		tss0_len;
	long		ldt0_off;
	size_t		ldt0_len;
	long		tss1_off;
	size_t		tss1_len;
	long		ldt1_off;
	size_t		ldt1_len;
//下面的关键数据都是在默认的内核数据段内，所以只记录偏移即可
	long		sys_data;		//关键数据的存储偏移
	long		sys_flp;		//磁盘数据的存储偏移
	long		sys_seg;		//段使用信息的存储偏移
};//}}}
//{{{ 下面结构定义了内核关键数据的存储	struct _SYS_DATA
struct _SYS_DATA
{
	long	pos;			//光标位置
	long	count;			//8253计数器0的累加值，单位值：10ms
	long	pmem;			//机器所拥有的实际物理内存
	BYTE	tm[6];			//存储了实时钟的值：年月日时分秒
};//}}}
//{{{下面定义磁盘的相关数据信息 struct _SYS_FLOPPY
struct _SYS_FLOPPY
{
	BYTE		fflag[4];		//软驱中断标志
	BYTE		fpara[12];		//取自bios的软盘参数
	BYTE		fret[10];		//软驱控制器FDC读取的返回状态字
	BYTE		head;			//当前磁头号0 or 1
	BYTE		cylinder;		//当前柱面号0-79
	BYTE		sector;			//当前磁道号1-18
	BYTE		drv;			//当前驱动器号0-3
	BYTE		nsectors;		//本次读取的扇区数
	BYTE		benable;		//有效标志
};
//}}}
//{{{ 下面定义默认的内核段 struct _SYS_SEG
struct _SYS_SEG
{
	long	kstk[2];				//内核堆栈段和栈指针
	long	kds;					//内核数据段
	long	kdisp;					//显示缓冲段
	long	ktab;					//系统表段
	long	kdma;					//dma所在段
	long	kdma_off;				//dma缓冲区偏移
	long	kds_safe_off;			//安全的数据段使用起始偏移（除去核心数据区）	
};
//}}}













