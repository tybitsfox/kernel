/*2014-11-24
  开始定义一些汇编所必须的正式使用的段值，系统表的起始地址等重要信息
 */
//内核数据段
SYS_DATA_LEN	=	127
SYS_DATA_1		=	0x0000
SYS_DATA_0		=	0x9220
SYS_DATA_C		=	0x00c0
//内核代码段
SYS_TEXT_LEN	=	127
SYS_TEXT_1		=	0x0000
SYS_TEXT_0		=	0x9a10
SYS_TEXT_C		=	0x00c0
//内核堆栈段
SYS_STACK_LEN	=	3
SYS_STACK_1		=	0xc000
SYS_STACK_0		=	0x921F
SYS_STACK_C		=	0x00C0
//内核系统表段
SYS_TABLE_LEN	=	31
SYS_TABLE_1		=	0x0000
SYS_TABLE_0		=	0x9200
SYS_TABLE_C		=	0x00C0
//dma数据缓冲段
SYS_DMA_LEN		=	79
SYS_DMA_1		=	0x0000
SYS_DMA_0		=	0x9202
SYS_DMA_C		=	0x00C0
//定义默认的代码段,数据段..
DEF_TEXT_SEG	=	0x8
DEF_DATA_SEG	=	0x10
DEF_STACK_SEG	=	0x18
DEF_DISP_SEG	=	0x20
//初始化数据段时count的位置
DEF_COUNT_OFF	=	0x4
DEF_POS_OFF		=	0

//

/*一、初始化代码段的安排：
 代码放置在0x8000处，由一个独立的模块加载，主要作用为
 1、将一些重要数据移动至最终数据段指定位置
 2、设置临时中断处理程序以及idt
 3、使用临时的磁盘驱动加载正式内核所需的中断处理程序
 4、初始化正式系统表：pdt/pt,idt,gdt,tss,ldt
 5、启用新的系统表，并跳转至正式内核中的初期管理程序
 以上初始化代码及所用到的系统表将在一个独立的模块中完成：head，该模块的加载由实模式代码负责。

二、最终代码段的安排：
代码段的开始放置256个中断处理程序
然后放置内核的库函数
然后再放置内核的初期管理程序
最后放置用于任务调度的任务0
该模块是由初始化代码中的临时磁盘驱动进行加载，这是内核的核心模块：kernel
三、最终数据段的安排：
前4k存放内核所用的所有系统表、核心表的偏移地址（系统表所在的段不是默认的代码段，但不存放其段址）和表长度以及定时器计数。
然后，后面的64k存放各种核心表。
再往后为普通数据存放处。
*/
//下面定义系统表的存放偏移及长度
//PDT
SYSTB_PDT_L		=	0x1000
SYSTB_PDT_OFF	=	0
//PT
SYSTB_PT_L		=	0x1000
SYSTB_PT_OFF	=	0x1000
//IDT
SYSTB_IDT_L		=	0x800
SYSTB_IDT_OFF	=	0x4000
//GDT
SYSTB_GDT_L		=	159
SYSTB_GDT_OFF	=	0x5000
//data中临时缓冲区的偏移
KERNEL_DATA_BUF	=	0x101000
KERNEL_DATA_BUF_L	=	0x1000
//2014-11-28 定义了代码段和数据段为同一内存范围，因此这里定义一些内核核心数据的存储起始位置
KERNEL_DATA_BEGIN	=	0x100000

