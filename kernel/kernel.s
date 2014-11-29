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
	call cmos_time
	call unmask_8259a
	sti
	pushl $9
#	call klocate
#	nop
	call disp_01
	nop
	call disp_count
	nop
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
	movl $0x20,%eax
	outb %al,$0x20
	movl $KERNEL_DATA_BEGIN,%esi
	movl 4(%esi),%eax
	incl %eax
	movl %eax,4(%esi)
	popl %esi 
	popl %eax
	iret
//}}}
//{{{flp_int
flp_int:
	pusha
	movl $0x20,%eax
	outb %al,$0x20
	call _set_flp_flag
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
	movl $KERNEL_DATA_BEGIN,%eax
	movl $0x7e,%esi
	addl %eax,%esi
	movl $0x3000,%edi
	addl %eax,%edi
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
	movl $KERNEL_DATA_BEGIN,%eax
	addl %eax,%esi
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
//{{{disp_count
disp_count:
	pusha
0:	
	movl $0x100004,%esi
	movl $0x101000,%edi
	lodsl
	movl %eax,%ebx
	movl $4,%ecx
1:	
	movl %ebx,%eax
	roll %cl,%eax
	andb $0xf,%al
	addb $0x30,%al
	cmpb $0x39,%al
	jbe 2f
	addb $7,%al
2:
	stosb
	addl $4,%ecx
	cmpl $32,%ecx
	jb 1b
	push %es
	movl $0x20,%eax
	movw %ax,%es
	movl $0x101000,%esi
	movl $0,%edi
	movl $8,%ecx
	movl $0x0c00,%eax
3:
	lodsb
	stosw
	loop 3b
	pop %es
	movl $10000,%ecx
4:
	loop 4b
	jmp 0b
	popa
	ret
//}}}	
//{{{cmos_time
cmos_time:
	pusha
	movl $KERNEL_DATA_BEGIN,%edi
	addl $12,%edi		
	movb $9,%al						#get year
	movl $0x70,%edx
	outb %al,%dx
	incl %edx
	inb  %dx,%al
	stosb
	decl %edx
	movb $8,%al						#get month
	outb %al,%dx
	incl %edx
	inb  %dx,%al
	stosb
	decl %edx
	movb $7,%al						#get day
	outb %al,%dx
	incl %edx
	inb  %dx,%al
	stosb
	decl %edx
	movb $4,%al						#get hour
	outb %al,%dx
	incl %edx
	inb  %dx,%al
	stosb
	decl %edx
	movb $2,%al						#get minter
	outb %al,%dx
	incl %edx
	inb %dx,%al
	stosb
	decl %edx
	movb $0,%al
	outb %al,%dx
	incl %edx
	inb %dx,%al						#get sector
	stosb
	popa
	ret
//}}}
//{{{unmask_8259a
unmask_8259a:
	pusha
	movl $0x21,%edx
	inb %dx,%al
	movl $0,%eax
	outb %al,%dx
	popa
	ret
//}}}


.data

.long	nor_int,time_int,flp_int,sys_int

.org	2555
.ascii	"part5"



