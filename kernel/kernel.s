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
	sti
	call disp_01


	jmp .

//{{{nor_int
nor_int:
	pusha
	call  _printk0
/*	push %es
	movl $0x20,%eax
	movw %ax,%es
	movl $158,%edi
	movl $0x0a41,%eax
	stosw
	pop %es*/
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
//{{{disp_01
disp_01:
	pusha
	movl $0x7e,%esi
	movl $0x3000,%edi
	movl $24,%ecx
1:
	lodsb
	movb %al,%bl
	rorb $4,%al
	andb $0xf,%al
	addb $0x30,%al
	cmpb $0x39,%al
	jbe 2f
	addb $7,%al
2:
	stosb
	movb %bl,%al
	andb $0xf,%al
	addb $0x30,%al
	cmpb $0x39,%al
	jbe  3f
	addb $7,%al
3:
	stosb
	movb $0x20,%al
	stosb
	loop 1b
	push %es
	movl $0x20,%eax
	movw %ax,%es
	movl $640,%edi
	movl $0x3000,%esi
	movl $72,%ecx
	movl $0x0a00,%eax
4:
	lodsb
	stosw
	loop 4b
	pop %es
	popa
	ret
//}}}



.data

.long	nor_int,time_int,flp_int,sys_int

.org	2555
.ascii	"part5"



