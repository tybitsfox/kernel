.data
.text
	movl $0x10,%eax
	movw %ax,%ds
	movw %ax,%es
	movw %ax,%fs
	lss  stk,%esp
	call move_data
	nop
	call setup_8253
	nop
	call cls
	nop
	call setup_idt
	nop
	lidt l_idt
	sti
	jmp .
//{{{cls
cls:
	push %es
	movl $0x20,%eax
	movw %ax,%es
	movl $0,%edi
	movl $0x20,%eax
	movl $0x7d0,%ecx
	rep stosw
	pop %es
	ret
//}}}	
//{{{move_data
move_data:
	pusha
	push %ds
	push %es
	movl $0x28,%eax
	movw %ax,%ds
	movl $0x500,%esi
	movl $0x11e,%ecx
	movl $0x38,%eax
	movw %ax,%es
	movl $0x10400,%edi
	rep movsb
	pop %es
	pop %ds
	popa
	ret
//}}}
//{{{nor_int
nor_int:
	pusha
	push %es
	movl $0x20,%eax
	movw %ax,%es
	movl $158,%edi
	movl $0x0a41,%eax
	stosw
	pop %es
	popa
	iret
//}}}
//{{{time_int
time_int:
	pusha
	push %ds
	movl $0x20,%eax
	outb %al,$0x20
	movl $0x10,%eax
	movw %ax,%ds
	movl count,%eax
	incl %eax
	movl %eax,count
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
//{{{setup_idt
setup_idt:
	pusha
	push %es
	movl $0x28,%eax
	movw %ax,%es
	movl $0x7000,%edi
	movl $256,%ecx
	leal nor_int,%edx
	movl $0x00080000,%eax
	movw %dx,%ax
	movw $0x8e00,%dx
1:
	movl %eax,%es:(%edi)
	movl %edx,%es:4(%edi)
	addl $8,%edi
	loop 1b
	movl $0x7000,%edi
	addl $64,%edi
	leal time_int,%edx
	movl $0x00080000,%eax
	movw %dx,%ax
	movw $0x8e00,%dx
	movl %eax,%es:(%edi)
	movl %edx,%es:4(%edi)
	movl $0x7000,%edi
	addl $0x400,%edi
	leal sys_int,%edx
	movl $0x00080000,%eax
	movw %dx,%ax
	movw $0xef00,%dx
	movl %eax,%es:(%edi)
	movl %edx,%es:4(%edi)
	pop %es
	popa
	ret
//}}}	
//{{{setup_8253
setup_8253:
	pushl %eax
	pushl %edx
	movl $0x36,%eax
	movl $0x43,%edx
	outb %al,%dx
	movl $11930,%eax
	movl $0x40,%edx
	outb %al,%dx
	movb %ah,%al
	outb %al,%dx
	popl %edx
	popl %eax
	ret
//}}}	

stk:	.long	0x1f00,0x18
count:	.long	0
l_idt:	.word	0x800
		.long	0x7000,0
.org	3579
.ascii	"part2"

