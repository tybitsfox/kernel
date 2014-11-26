.include "../include/defconst.inc"
.text
	movl $0x10,%eax
	movw %ax,%ds
	movw %ax,%es
	movw %ax,%fs
	movw %ax,%gs
	movl $0x18,%eax
	movw %ax,%ss
	movl $0x1f00,%eax
	movl %eax,%esp
	jmp .

//{{{nor_int
nor_int:
	pusha
	call  _printk0
	popa
	iret
//}}}
//{{{time_int
time_int:
	pushl %eax
	pushl %esi
	push %ds
	movl $0x20,%eax
	outb %al,$0x20
	movl $DEF_DATA_SEG,%eax
	movw %ax,%ds
	movl $0,%esi
	movl (%esi),%eax
	incl %eax
	movl %eax,(%esi)
	pop %ds
	popl %esi
	popl %eax
	iret
//}}}
//{{{flp_int
flp_int:
	pusha
	push %ds
	movl $0x20,%eax
	outb %al,$0x20
	movl $DEF_DATA_SEG,%eax
	movw %ax,%ds
	call _set_flp_flag
	pop %ds
	popa
	iret
//}}}	
//{{{sys_int
sys_int:
	pusha

	popa
	iret
//}}}



.data
.long	nor_int,time_int,flp_int,sys_int

.org	2555
.ascii	"part5"

