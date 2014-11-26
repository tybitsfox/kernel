#include"kern.h"
#include"klib.h"

//{{{void _set_flp_flag() 磁盘中断调用，设置中断标志的函数
void _set_flp_flag()
{
	struct _SYS_TABLE *st=(struct _SYS_TABLE *)SYS_TABLE_INDEX;
	struct _SYS_FLOPPY *sp=(struct _SYS_FLOPPY *)(st->sys_flp);
	sp->fflag[0]|=0x80;
}//}}}















