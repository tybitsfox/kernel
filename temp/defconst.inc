/*关于内存划分使用的初步构想
现在开始考虑对整体内存的使用规划了，初步设想：
 1、1M内存的分配：
 （1）前64k（0-0xffff）地址存放pdt/pt，idt和gdt。
 （2）第二个64k（0x10000-0x1ffff）存放备份的bios数据。
 （3）紧接着的320k（0x20000-0x6ffff）用于dma的读写缓冲区。
 （4）自0x70000-0x8ffff的128k为自定义的系统数据区。
 原定义的自定义数据区为到0x9ffff的192k空间，为了不引起意外的冲突
 现将0x90000开始的64k先用于临时的保护模式代码区，待保护模式进一步初始化
 后再将这部分空间划归自定义数据区。
 （5）0x100000至1M的（其中有显示缓冲区）部分保留。
 2、1M-2M之间的内存分配：
 （1）中断处理函数存放位置
 （2）最后8k（0x1e0000-0x1fffff）为内核堆栈区。
 3、2M-4M之间的内存分配：
 （1）前64k（0x200000-0x20ffff）存放ldt/tr,及部分pt。
 （2）剩余部分为内核代码、数据区。
 4、4M之后为用户空间。
*/
#本头文件将作为通用文件。
#*******************定义的常量************************************
REG_DEF_GS			=	0x38	#对于personal段，所有的gdt都用该值	
#在初期进行gdt的设置时，personal段在所有gdt中都使用这个定值，以保证
#在任何时期对personal段都有一致的段选择符可用。
MAX_TIME_CNT		=	0x70000000	#定时器计数最大值，（大约218天）
#超过该值则归零。

#enum	flp_cmd{
FDC_CMD_READ_TRACK	=	2
FDC_CMD_SPECIFY		=	3
FDC_CMD_CHECK_STAT	=	4
FDC_CMD_WRITE_SECT	=	5
FDC_CMD_READ_SECT	=	6
FDC_CMD_CALIBRATE	=	7
FDC_CMD_CHECK_INT	=	8
FDC_CMD_WRITE_DEL_S	=	9
FDC_CMD_READ_ID_S	=	0xa
FDC_CMD_READ_DEL_S	=	0xc
FDC_CMD_FORMAT_TRACK	=	0xd
FDC_CMD_SEEK		=	0xf	
#};
#enum定义的是FDC命令字。
#*******************定义的偏移************************************
#下列定义的常量为自定义数据区中变量的位置偏移，命名规则为
#Lxxxnum，Wxxxnum，Bxxxnum：分别表示长度类型，后面的num表示该长度数量
LSTK2 =	0				#用于加载ess:esp
LPOSITION1	= 8			#当前字符串显示位置
LCOUNT1	=	12			#计数器1的累加数值，每1/100秒加1.
BFPARAM12	=	16		#取得的bios的软驱参数。
BFFLAG4	=	28			#软驱中断使用的标志
BBUF_100	=	32		#存储显示字符串的空间
BFLPRT10	=	132		#软驱控制器FDC读取的返回字节，最大返回字节数7,紧跟的一位存储返回字节数
WMEM2	=	142			#内存大小
BHEAD1	=	146			#软驱当前磁头号 0 or 1
BCYD1	=	147			#软驱当前柱面号 max80
BSECTOR1	=	148		#软驱当前扇区号 max18
BDRV1	=	149			#软驱驱动器号 0～～3
BSIZE1	=	150			#本次读取的扇区数
WSEG1	=	151			#输出缓冲区段选择符
LOFFSET1	=	153		#输出缓冲区偏移
BENABLE1	=	157		#有效标志
#下面的定义仅用于在变更gdt时对某些特殊段引用的统一，为了避免gdt变更后有些代码对
#某些段选择符的使用出现错误，今后将不再把具体的段选择符值硬编码进代码中，而是通过
#对段选择符的检索来获取，因此，在gdt的设置函数中，必须同时将本次gdt的设置与这里同步。
LREG_DISP1	=	158		#显示缓冲区的段
LREG_DMA1	=	162		#dma buffer
LREG_BIOS1	=	166		#bios data backup
LREG_DEF_TEXT1	=	170	#default text
LREG_DEF_DATA1	=	174	#default data
LREG_INT_TEXT1	=	178	#interrupt text
#------------下面的定义是为便于作为参数获取目标段选择符-----------
DISP	=	LREG_DISP1
DMA		=	LREG_DMA1
BIOS	=	LREG_BIOS1
TEXT	=	LREG_DEF_TEXT1
DATA	=	LREG_DEF_DATA1
INTTEXT	=	LREG_INT_TEXT1
#下面的定义用于段间的跳转、调用时使用
LRET_FAR1	=	182		#调用，远调用的区别标志，=1为远调用
LCALL_ADDR2	=	186		#间接远跳转、调用时的远端地址
#-----------显然前面定义的BBUF_100的缓冲区太小了，这里我们要定义一个更大的
BBUF_1000	=	0x1000







