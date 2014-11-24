.code16
.data
.text
	jmp $0x7c0,$go
go:
	mov %cs,%ax
	mov %ax,%ds
	mov %ax,%es
	lss stk,%sp
	mov $0x200,%bx
	mov $0,%dx
	mov $2,%cx
	mov $0x0207,%ax
	int $0x13
	jnc 1f
	jmp .
1:
	call cls
	nop
	call get_phy_mem
	nop
	call get_flp_param
	nop
	cli
	lgdt l_gdt
	mov %cr0,%eax
	or $1,%eax
	mov %eax,%cr0
	jmp $8,$0


//{{{cls
cls:
	pusha
	push %es
	mov $0xb800,%ax
	mov %ax,%es
	mov $0,%di
	mov $0x7d0,%cx
	mov $0x20,%ax
	rep stosw
	pop %es
	popa
	ret
//}}}	
//{{{get_phy_mem
get_phy_mem:
	push %es
	mov $0x50,%eax
	mov %ax,%es
	mov $0,%ebx
	mov $0,%esi
1:
	mov $0,%edi
	mov $20,%ecx
	mov $0x534d4150,%edx	#SMAP
	mov $0xe820,%eax
	int $0x15
	jc  2f
	mov $8,%edi
	mov %es:(%di),%eax
	add %eax,%esi
	clc
	cmp $0,%ebx
	jne 1b
	jmp 3f
2:
	mov $0,%esi
3:
	mov $0,%edi
	mov %esi,%es:(%edi)
	pop %es
	mov $0,%eax				#code16下push,pop不能保存寄存器的高16位，用这种方式清零
	mov %eax,%ebx
	mov %eax,%ecx
	mov %eax,%edx
	mov %eax,%esi
	mov %eax,%edi
	ret	
//}}}
//{{{get_flp_param
get_flp_param:
	push %es
	push %ds
	mov $0,%ax
	mov %ax,%ds
	mov $0x78,%si
	mov $0x50,%ax
	mov %ax,%es
	mov $4,%di
	lodsw
	mov %ax,%bx
	lodsw
	mov %ax,%ds
	mov %bx,%si
	mov $12,%cx
	rep movsb			#save in 0x50:4
	pop %ds
	pop %es
	ret
//}}}


stk:	.word	0x300,0x4000,0

.org	510
.word	0xaa55
l_gdt:	.word	103,0x7c00+gdt,0
gdt:
		.word	0,0,0,0
		.word	3,0x8000,0x9a00,0x00c0			#0x8	text
		.word	3,0x8000,0x9200,0x00c0			#0x10	data
		.word	1,0xe000,0x921f,0x00c0			#0x18	stack
		.word	15,0x000,0x9200,0x00c0			#0x20	pdt/pt,idt,gdt
		.word	15,0x000,0x9201,0x00c0			#0x28	backup bios data
		.word	79,0x000,0x9202,0x00c0			#0x30	dma's buffer
		.word	31,0x000,0x9207,0x00c0			#0x38	personal's data area
		.word	15,0x000,0x9210,0x00c0			#0x40	final interrupt func's area
		.word	15,0x000,0x9220,0x00c0			#0x48	final kernel's area
		.word	3,0x0000,0x922c,0x00c0			#0x50	tss0,ldt0
		.word	7,0x8000,0x920b,0x00c0			#0x58	disp
		.word	0,0,0,0

.org	1019
.ascii	"part1"

