.include "./defconst.inc"
.data
.text
	movl $0x10,%eax
	movw %ax,%ds
	movw %ax,%fs
	movl $0x28,%eax
	movw %ax,%es
	movl $0x38,%eax
	movw %ax,%gs
	movl $LSTK2,%edi
	movl $0x1f00,%eax
	movl %eax,%gs:(%edi)
	movl $0x18,%eax
	movl %eax,%gs:4(%edi)	#save ss:esp
	lss %gs:(%edi),%esp
	call _init_data
	nop
	call disp_1
	nop
	call setup_8253
	nop
	call setup_idt
	nop
	lidt l_idt
	sti
	movl $0x10,%eax
	movw %ax,%ds
	movw %ax,%fs
	movl $0x28,%eax
	movw %ax,%es
	movl $0x38,%eax
	movw %ax,%gs
	call disp_flp_return
	nop
	call disp_flp_param
	nop
	call disp_phy_mem
	nop
	xorl %eax,%eax
	call motor_on
	jnc 1f
	movl $0xa01,%eax
	jmp .
1:	
	xorl %eax,%eax
	call cmd_seek_head
   	jnc 2f
	call disp_flp_flag
	movl err,%eax
	jmp .
2:
	call disp_flp_return
	nop
	jmp .
3:
	movl $0x1200,%eax
	roll $16,%eax
	addl $2,%eax
	movl $0x20000,%ebx
	call setup_dma
	jnc 4f
	movl $0xa02,%eax
	jmp .
4:
	movl $10,%eax
	roll $16,%eax
	call cmd_read_sector
	jnc 5f
	call disp_flp_return
	movl $0xa03,%eax
	jmp .
5:
	call cmd_chk_interrupt
	jnc 6f
	call disp_flp_return
	movl $0xa04,%eax
	jmp .
6:
	call disp_result
	movl $0xa05,%eax
#上面的代码已经完成了最终中断例程以及相关函数的加载了，下面测试能否取得他们
#的偏移地址,测试成功！可以进行下面的工作了：将最终的idt，gdt，pdt/pt的设置完成
#并准备进入正式的内核环境！	
#	call disp_offset
#启用分页机制
	call setup_pdt
	movl $0,%eax
	movl %eax,%cr3
	movl %cr0,%eax
	orl $0x80000000,%eax
	movl %eax,%cr0
	nop	
	call move_int
	cli
	call setup_final_idt
	nop
	call setup_final_gdt
	nop
	lidt l_final_idt
	nop
	lgdt l_final_gdt
	jmp .+2
	movl $0x10,%eax
	movw %ax,%ds
	movw %ax,%es
	movw %ax,%fs
	movl $0x38,%eax
	movw %ax,%gs
	movl $LSTK2,%edi
	lss %gs:(%edi),%esp
	sti
	nop
	call disp_offset
	nop
	movl $0x28,%eax
	movw %ax,%es
	movl $4024,%esi			#offset of int_show
	movl %es:(%esi),%eax
/*	
	movl $0x30,%ebx
	movl %eax,ljp
	movl %ebx,ljp1
	movl $ljp,%ebx
	movl $1,%eax
	lcall *(%ebx)
	xorl %eax,%eax
	jmp .
*/
	movl $0x30,%ebx
	movl %eax,ljp
	movl %ebx,ljp1
	movl $ljp,%ebx
	ljmp *(%ebx)

//{{{_init_data
_init_data:
	pusha
	push %ds
	push %es
	movl $0x28,%eax
	movw %ax,%es
	movl $0x20,%eax
	movw %ax,%ds
	movl $0x400,%esi
	movl $0,%edi
	movl $0x110,%ecx
	rep movsb
	movl $0x28,%eax
	movw %ax,%ds
	movl $0x38,%eax
	movw %ax,%es
	movl $0x100,%esi
	movl $WMEM2,%edi
	movsl
	movl $BFPARAM12,%edi
	movl $12,%ecx
	rep movsb
	movl $LPOSITION1,%edi
	movl $0,%eax
	stosl							#save display pos
	stosl							#save time count
	movl $BFFLAG4,%edi
	movl $114,%ecx
	rep stosb						#clear buffer,flp_flag,flp_ret
	movl $BHEAD1,%edi
	stosw							#flp head,cylinder
	movb $10,%al
	stosb							#flp sector
	movb $0,%al
	pop %es
	pop %ds
	stosb							#flp driver
	popa
	ret
//}}}
//{{{calc_pos
#in:	ecx:current string's length
#rt:	edi:current disp's position CF clear if ok
#该函数计算当前字符串要显示的位置，以及保存当前字符串结束的位置。
#显示位置适用与MDA模式的显示位置，存储的结束位置分为：高16位保存
#行号（0-base），低16位保存当前行属性位的起始位置。	
calc_pos:
	cmpl $80,%ecx
	jb  1f
	stc
	ret
1:
	pushl %eax
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %esi
	movl %ecx,%eax
	addl %eax,%ecx
	movl $LPOSITION1,%edi	#默认段选择符为gs
	movl %gs:(%edi),%ebx
	movl %ebx,%eax
	addl %ecx,%eax
	cmpw $158,%ax
	jae  2f
	addl $2,%eax
	movl %eax,%gs:(%edi)
	jmp 3f
2:
	addl $0x10000,%ebx
	andl $0xffff0000,%ebx
	addl %ebx,%ecx
	addl $2,%ecx
	movl %ecx,%gs:(%edi)
3:	
	movl %ebx,%eax
	roll $16,%eax
	andl $0xffff,%eax
	movw $160,%cx
	mulw %cx
	andl $0xffff,%ebx
	addl %ebx,%eax
	movl %eax,%edi
	popl %esi
	popl %edx
	popl %ecx
	popl %ebx
	popl %eax
	ret
//}}}
//{{{disp_1
disp_1:
	pusha
	push %es
	movl $0x58,%eax
	movw %ax,%es
	leal msg,%esi
	movl $len,%ecx
	movl $0x0a00,%eax
	call calc_pos
	jc  2f
1:
	lodsb
	stosw
	loop 1b
2:	
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
	jmp .+2
	movl $11930,%eax
	movl $0x40,%edx
	outb %al,%dx
	jmp .+2
	movb %ah,%al
	outb %al,%dx
	popl %edx
	popl %eax
	ret
//}}}
//{{{nor_int
nor_int:
	pusha
	movl $0x20,%eax
	outb %al,%dx
	push %es
	movl $0x58,%eax
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
	pushl %eax
	pushl %edi
	push %gs
	movl $0x20,%eax
	outb %al,$0x20
	movl $0x38,%eax
	movw %ax,%gs
	movl $LCOUNT1,%edi
	movl %gs:(%edi),%eax
	incl %eax
	cmpl $0x70000000,%eax
	jbe  1f
	movl $0,%eax
1:
	movl %eax,%gs:(%edi)
	pop %gs
	popl %edi
	popl %eax
	iret
//}}}
//{{{sys_int
sys_int:
	pusha

	popa
	iret
//}}}
//{{{flp_int
flp_int:
	pushl %eax
	pushl %edi
	push %es
	movl $0x58,%eax
	movw %ax,%es
	movl $318,%edi
	movl $0x0a42,%eax
	stosw
	movl $0x20,%eax
	outb %al,$0x20
	movl $BFFLAG4,%edi
	movl %gs:(%edi),%eax
	movb  $0x80,%al
	movl %eax,%gs:(%edi)
	pop %es
	popl %edi
	popl %eax
	iret
//}}}
//{{{int_0xF
int_0xF:
	pushl %eax
	pushl %edi
	movl $0x20,%eax
	outb %al,$0x20
	push %es
	movl $0x58,%eax
	movw %ax,%es
	movl $318,%edi
	movl $0x0b42,%eax
	stosw
	pop %es
	popl %edi
	popl %eax
	iret
//}}}
//{{{setup_idt
setup_idt:
	pusha
	push %es
	movl $0x28,%eax
	movw %ax,%es
	movl $0x1000,%edi
	leal nor_int,%edx
	movl $0x00080000,%eax
	movw %dx,%ax
	movw $0x8e00,%dx
	movl $256,%ecx
1:
	movl %eax,%es:(%edi)
	movl %edx,%es:4(%edi)
	addl $8,%edi
	loop 1b							#setup nor_int
	leal time_int,%edx
	movl $64,%edi
	addl $0x1000,%edi
	movl $0x00080000,%eax
	movw %dx,%ax
	movw $0x8e00,%dx
	movl %eax,%es:(%edi)
	movl %edx,%es:4(%edi)			#setup time_int
	movl $0x400,%edi
	addl $0x1000,%edi
	leal sys_int,%edx
	movl $0x00080000,%eax
	movw %dx,%ax
	movw $0xef00,%dx				#trap gate
	movl %eax,%es:(%edi)
	movl %edx,%es:4(%edi)			#setup sys_int
	movl $0x70,%edi
	addl $0x1000,%edi
	leal flp_int,%edx
	movl $0x00080000,%eax
	movw %dx,%ax
	movw $0x8e00,%dx
	movl %eax,%es:(%edi)
	movl %edx,%es:4(%edi)			#setup flp_int
	addl $8,%edi
	leal int_0xF,%edx
	movl $0x00080000,%eax
	movw %dx,%ax
	movw $0x8e00,%dx
	movl %eax,%es:(%edi)
	movl %edx,%es:4(%edi)			#setup int_0xF
	pop %es
	popa
	ret
//}}}
//{{{disp_flp_return
disp_flp_return:
	pusha
	push %ds
	push %es
	movl $0x38,%eax
	movw %ax,%ds
	movw %ax,%es
	movl $BFLPRT10,%esi
	movl $BBUF_100,%edi
	movl $10,%ecx
1:
	lodsb
	movb %al,%ah
	rolb $4,%al
	andb $0xf,%al
	addb $0x30,%al
	cmpb $0x39,%al
	jbe 2f
	addb $7,%al
2:
	stosb
	movb %ah,%al
	andb $0xf,%al
	addb $0x30,%al
	cmpb $0x39,%al
	jbe 3f
	addb $7,%al
3:
	stosb
	movb $0x20,%al
	stosb
	loop 1b
	movl $BBUF_100,%esi
	movl $0x58,%eax
	movw %ax,%es
	movl $30,%ecx
	call calc_pos
	movl $0x0a00,%eax
4:
	lodsb
	stosw
	loop 4b
	pop %es
	pop %ds
	popa
	ret
//}}}
//{{{disp_flp_param
disp_flp_param:
	pusha
	push %ds
	push %es
	movl $0x38,%eax
	movw %ax,%ds
	movw %ax,%es
	movl $BFPARAM12,%esi
	movl $BBUF_100,%edi
	movl $12,%ecx
1:
	lodsb
	movb %al,%ah
	rol $4,%al
	andb $0xf,%al
	addb $0x30,%al
	cmpb $0x39,%al
	jbe  2f
	addb $7,%al
2:
	stosb
	movb %ah,%al
	andb $0xf,%al
	addb $0x30,%al
	cmpb $0x39,%al
	jbe 3f
	addb $0x7,%al
3:
	stosb
	movb $0x20,%al
	stosb
	loop 1b
	movl $BBUF_100,%esi
	movl $0x58,%eax
	movw %ax,%es
	movl $36,%ecx
	call calc_pos
	movl $0x0c00,%eax
4:
	lodsb
	stosw
	loop 4b
	pop %es
	pop %ds
	popa
	ret
//}}}
//{{{disp_phy_mem
disp_phy_mem:
	pusha
	push %ds
	push %es
	movl $0x38,%eax
	movw %ax,%ds
	movw %ax,%es
	movl $WMEM2,%esi
	movl $BBUF_100,%edi
	lodsl
	movl %eax,%ebx
	movl $4,%ecx
1:
	roll $8,%ebx
	movb %bl,%al
	rolb $4,%al
	andb $0xf,%al
	addb $0x30,%al
	cmpb $0x39,%al
	jbe  2f
	addb $7,%al
2:
	stosb
	movb %bl,%al
	andb $0xf,%al
	addb $0x30,%al
	cmpb $0x39,%al
	jbe 3f
	addb $7,%al
3:
	stosb
	movb $0x20,%al
	stosb
	loop 1b
	movl $BBUF_100,%esi
	movl $0x58,%eax
	movw %ax,%es
	movl $12,%ecx
	call calc_pos
	movl $0x0a00,%eax
4:
	lodsb
	stosw
	loop 4b
	pop %es
	pop %ds
	popa
	ret
//}}}
//{{{motor_on
#in:	eax:0-3:driver A-D
#rt:	CF
motor_on:
	pusha
	cmpl $3,%eax
	jbe 1f
	stc
	jmp 9f
1:
	movl %eax,%ecx
	movb $0x10,%al
	rolb %cl,%al
	addb %cl,%al
	orb  $0xc,%al
	movl $0x3f2,%edx
	outb %al,%dx
	movl $80,%eax
	call delay
	clc
9:	
	popa
	ret
//}}}
//{{{delay
#in:	eax:delay times per 1/100 second
#rt:	none
delay:
	pushl %eax
	pushl %edx
	pushl %ecx
	movl $LCOUNT1,%edx
	movl %gs:(%edx),%ecx
	addl %ecx,%eax
1:
	movl %gs:(%edx),%ecx
	cmpl %eax,%ecx
	jb 1b
	popl %ecx
	popl %edx
	popl %eax
	ret
//}}}
//{{{cmd_seek_head
#in:	eax:bit0-1:driverA-D,bit2:head,bit8-bit15:cylinder
#rt:	CF
cmd_seek_head:
	movl %eax,%ebx
	movl $0xf,%eax
	call send_cmd				#send command
	movl $0xf001,%eax
	movl %eax,err
	jc 9f
	movl %ebx,%eax
	andl $0xff,%eax
	call send_cmd				#send param1
	movl $0xf002,%eax
	movl %eax,err
	jc 9f
	movl %ebx,%eax
	movb %ah,%al
	andl $0xff,%eax
	call send_cmd				#send param2
	movl $0xf003,%eax
	movl %eax,err
	jc 9f
	call wait_for_irq
	movl $0xf004,%eax
	movl %eax,err
	jc 9f
	call cmd_chk_interrupt
	movl $0xf005,%eax
	movl %eax,err
	jc 9f
	movl $0,%eax
	movl %eax,err
9:
	ret
//}}}
//{{{send_cmd
#in:	eax: command or parameter
#rt:	CF
send_cmd:
	pusha
	movl %eax,%ebx
	movl $0x3f4,%edx
	movl $60,%ecx
1:
	inb %dx,%al
	jmp .+2
	testb $0x40,%al
	jz 2f
	movl $20,%eax
	call delay
	loop 1b
	stc
	jmp 9f
2:
	movl $60,%ecx
3:	
	inb %dx,%al
	jmp .+2
	testb $0x80,%al
	jnz 4f
	movl $20,%eax
	call delay
	loop 3b
	stc
	jmp 9f
4:
	movl %ebx,%eax
	incl %edx
	outb %al,%dx
	jmp .+2
9:
	popa
	ret
//}}}	
//{{{wiat_for_irq
#in:	none
#rt:	CF
wait_for_irq:
	pushl %eax
	pushl %edx
	pushl %ecx
	movl $100,%ecx
	movl $BFFLAG4,%edx
1:	
	movl %gs:(%edx),%eax
	testb $0x80,%al
	jnz  2f
	movl $60,%eax
	call delay
	loop 1b
	stc
	jmp 3f
2:	
	andb $0x7f,%al
	movl %eax,%gs:(%edx)
3:
	popl %ecx
	popl %edx
	popl %eax
	ret
//}}}
//{{{cmd_chk_interrupt
#in:	none
#rt:	CF
cmd_chk_interrupt:
	movl $8,%eax
	call send_cmd
	jc 1f
	call recv_cmd
1:
	ret
//}}}
//{{{recv_cmd
#in:	none
#rt:	CF
recv_cmd:
	pusha
	push %es
	movl $0x38,%eax
	movw %ax,%es
	movl $BFLPRT10,%edi
	movl $0,%eax
	movl $10,%ecx
	rep stosb
	movl $BFLPRT10,%edi
	movl $0x3f4,%edx
	movl $60,%ecx
	movl $0,%ebx
1:
	inb %dx,%al
	jmp .+2
	test $0x10,%al
	jnz 2f
	movl $20,%eax
	call delay
	loop 1b
	jmp 9f
2:
	incl %edx
	inb %dx,%al
	jmp .+2
	stosb
	incl %ebx
	cmpl $7,%ebx
	ja 9f
	decl %edx
	movl $60,%ecx
	jmp 1b
9:
	movb %bl,%al
	stosb
	pop %es	
	popa
	ret
//}}}
//{{{fetch_param
#in:	eax:index
#rt:	eax:param
fetch_param:
	pushl %edi
	movl $BFPARAM12,%edi
	addl %eax,%edi
	movb %gs:(%edi),%al
	popl %edi
	ret
//}}}
//{{{disp_flp_flag
disp_flp_flag:
	pusha
	push %ds
	push %es
	movl $0x38,%eax
	movw %ax,%ds
	movw %ax,%es
#	movl $BFFLAG4,%esi
	movl $LCOUNT1,%esi
	movl $BBUF_100,%edi
	movl $4,%ecx
1:	
	lodsb
	movb %al,%bl
	rolb $4,%al
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
	jbe 3f
	addb $7,%al
3:
	stosb
	movb $0x20,%al
	stosb
	loop 1b
	movl $0x58,%eax
	movw %ax,%es
	movl $BBUF_100,%esi
	movl $12,%ecx
	call calc_pos
	movl $0x0a00,%eax
4:
	lodsb
	stosw
	loop 4b
	pop %es
	pop %ds
	popa
	ret
//}}}
//{{{cmd_read_sector
#in:	eax:bit0-1:driver,bit2:head,bit8-15:cylinder,bit16-23:sector
#rt:	CF
cmd_read_sector:
	movl %eax,%ebx
	movl $0x66,%eax
	call send_cmd					#send command
	jc 9f
	movl %ebx,%eax
	andl $0xff,%eax
	call send_cmd					#send param1 head/driver
	jc 9f
	movl %ebx,%eax
	movb %ah,%al
	andl $0xff,%eax
	call send_cmd					#send param2 culinder
	jc 9f
	movl %ebx,%eax
	andl $0xff,%eax
	rorl $2,%eax
	call send_cmd					#send param3 head
	jc 9f
	movl %ebx,%eax
	rorl $16,%eax
	andl $0xff,%eax
	call send_cmd					#send param4 sector
	jc 9f
	movl $3,%eax
	call fetch_param
	nop
	call send_cmd					#send param5
	jc 9f
	movl $4,%eax
	call fetch_param
	nop 
	call send_cmd					#send param6
	jc 9f
	movl $5,%eax
	call fetch_param
	nop
	call send_cmd					#send param7
	jc 9f
	movl $6,%eax
	call fetch_param
	nop
	call send_cmd					#send param8
	jc 9f
	call wait_for_irq
	jc 9f
	call recv_cmd
9:
	ret
//}}}
//{{{setup_dma
#in:	eax:bit0-1:tunnel number,bit16-31:size
#		ebx:physical address for dma's buffer
#rt:	CF
setup_dma:
	pusha
	cli
	movl %eax,%esi
	andl $0xf,%eax
	orl $4,%eax
	movl $10,%edx
	outb %al,%dx						#mask tunnel 2
	movl %esi,%eax
	andl $0xf,%eax
	orl  $0x44,%eax						#must be 0x46
	movl $12,%edx
	outb %al,%dx						#clear byte's pointer
	jmp .+2
	movl $11,%edx
	outb %al,%dx						#set dma's work model: tunnel2,read mode,signal dma
	movl %ebx,%eax
	rorl $16,%eax
	andl $0xffff,%eax
	cmpl $0x10,%eax
	jb 1f
	stc
	jmp 9f
1:
	movl $12,%edx
	outb %al,%dx						#clear
	jmp .+2
	movl $0x81,%edx
	outb %al,%dx						#set dma's page register
	movl %ebx,%eax
	andl $0xffff,%eax
	movl $12,%edx
	outb %al,%dx						#clear
	movl $4,%edx
	outb %al,%dx
	jmp .+2
	movb %ah,%al
	outb %al,%dx						#set dma's offset register
	jmp .+2
	movl %esi,%eax
	rorl $16,%eax
	andl $0xffff,%eax
	movl $12,%edx
	outb %al,%dx						#clear
	movl $5,%edx
	outb %al,%dx
	jmp .+2
	movb %ah,%al
	outb %al,%dx						#set dma's count register
	movl %esi,%eax
	andl $0xf,%eax
	movl $10,%edx
	outb %al,%dx						#un mask tunnel 2
9:
	sti
	popa
	ret
//}}}	
//{{{disp_result
disp_result:
	pusha
	push %ds
	push %es
	movl $0x30,%eax
	movw %ax,%ds
	movl $0x38,%eax
	movw %ax,%es
	movl $4500,%esi
	movl $BBUF_100,%edi
	movl $11,%ecx
	rep movsb
	movl $0x38,%eax
	movw %ax,%ds
	movl $0x58,%eax
	movw %ax,%es
	movl $BBUF_100,%esi
	movl $11,%ecx
	call calc_pos
	movl $0x0b00,%eax
4:
	lodsb
	stosw
	loop 4b
	pop %es
	pop %ds
	popa
	ret
//}}}
//{{{disp_offset
#这是一个测试程序，用来测试取得的最终各中断函数的入口地址，以便与进行安装
disp_offset:
	movl $0x28,%eax
	movw %ax,%ds
	movl $0x38,%eax
	movw %ax,%es
	movl $4000,%esi
	movl $BBUF_100,%edi
	movl $20,%ecx
1:
	lodsb
	movb %al,%bl
	rorb $4,%al
	andl $0xf,%eax
	addb $0x30,%al
	cmpb $0x39,%al
	jbe 2f
	addb $7,%al
2:
	stosb
	movb %bl,%al
	andl $0xf,%eax
	addb $0x30,%al
	cmpb $0x39,%al
	jbe 3f
	addb $7,%al
3:
	stosb
	movb $0x20,%al
	stosb
	loop 1b
	push %es
	pop %ds
	movl $0x40,%eax
	movw %ax,%es
	movl $BBUF_100,%esi
	movl $60,%ecx
	call calc_pos
	movl $0x0c00,%eax
4:
	lodsb
	stosw
	loop 4b
	ret
//}}}
//{{{setup_pdt
setup_pdt:
	pusha
	push %es
	movl $0x20,%eax
	movw %ax,%es
	movl $0,%edi
	movl $0x1007,%eax
	stosl
	movl $0,%eax
	movl $1023,%ecx
	rep stosl			#end of pdt
	movl $7,%eax
	movl $1024,%ecx
1:
	stosl
	addl $0x1000,%eax
	loop 1b				#end of pt
	pop %es
	popa
	ret
//}}}
//{{{move_int
move_int:
	pusha
	push %ds
	push %es
	movl $0x30,%eax
	movw %ax,%ds
	movl $0x40,%eax
	movw %ax,%es
	movl $0,%esi
	movl $0,%edi
	movl $4000,%ecx
	rep movsb
	pop %es
	pop %ds
	popa
	ret
//}}}	
//{{{setup_final_idt
setup_final_idt:
	pusha
	push %fs
	push %es
	movl $0x30,%eax
	movw %ax,%fs
	movl $0x20,%eax
	movw %ax,%es
	movl $4000,%esi
	movl $0x4000,%edi
	movl %fs:(%esi),%edx	#nor_int
	movl $0x00300000,%eax
	movw %dx,%ax
	movw $0x8e00,%dx
	movl $256,%ecx
1:
	movl %eax,%es:(%edi)
	movl %edx,%es:4(%edi)
	addl $8,%edi
	loop 1b					#end of nor_int
/*
	movl $4012,%esi
	movl $0x4000,%edi
	movl %fs:(%esi),%edx
	movl $0x00300000,%eax
	movw %dx,%ax
	movw $0x8e00,%dx
	movl $4,%ecx
2:
	movl %eax,%es:(%edi)
	movl %edx,%es:4(%edi)	#end of int_0xF
	addl $8,%edi
	loop 2b 
*/
	movl %fs:4(%esi),%edx	#time_int
	movl $0x00300000,%eax
	movl $0x4000,%edi
	addl $64,%edi
	movw %dx,%ax
	movw $0x8e00,%dx
	movl %eax,%es:(%edi)
	movl %edx,%es:4(%edi)	#end of time_int
	addl $8,%esi
	movl %fs:(%esi),%edx
	movl $0x00300000,%eax
	movl $0x4000,%edi
	addl $0x400,%edi
	movw %dx,%ax
	movw $0xef00,%dx
	movl %eax,%es:(%edi)
	movl %edx,%es:4(%edi)	#end of sys_int
	movl $0x4000,%edi
	addl $0x78,%edi
	movl %fs:4(%esi),%edx
	movl $0x00300000,%eax
	movw %dx,%ax
	movw $0x8e00,%dx
	movl $16,%ecx
	movl %eax,%es:(%edi)
	movl %edx,%es:4(%edi)	#end of int_0xF
	addl $8,%esi
	movl %fs:(%esi),%edx
	movl $0x00300000,%eax
	movw %dx,%ax
	movw $0x8e00,%dx
	movl $0x4000,%edi
	addl $0x70,%edi
	movl %eax,%es:(%edi)
	movl %edx,%es:4(%edi)	#end of flp_int
	pop %es
	pop %fs
	popa
	ret
//}}}
//{{{setup_final_gdt
setup_final_gdt:
	pusha
	push %es
	movl $0x20,%eax
	movw %ax,%es
	leal tgdt,%esi
	movl $0x4a00,%edi
	xorl %ecx,%ecx
	movw l_final_gdt,%cx
	incl %ecx
	rep movsb
	movl $LREG_DISP1,%edi
	movl $0x40,%eax				#new disp
	movl %eax,%gs:(%edi)
	movl $LREG_DMA1,%edi
	movl $0x28,%eax				#new dma buffer
	movl %eax,%gs:(%edi)
	movl $LREG_BIOS1,%edi
	movl $0x20,%eax
	movl %eax,%gs:(%edi)		#new bios's backup
	movl $LREG_DEF_TEXT1,%edi
	movl $0x8,%eax
	movl %eax,%gs:(%edi)		#new text
	movl $LREG_DEF_DATA1,%edi
	movl $0x10,%eax
	movl %eax,%gs:(%edi)		#new data
	movl $LREG_INT_TEXT1,%edi
	movl $0x30,%eax
	movl %eax,%gs:(%edi)		#new interrupt
	pop %es
	popa
	ret
//}}}


l_idt:	.word	0x800
		.long	0x11000
l_final_idt:
		.word	0x800
		.long	0x4000
l_final_gdt:
		.word	79
		.long	0x4a00
#对gdt的设置：测试期间先不改动代码段和数据段的位置，待中断安装并成功运行后
#再考虑对代码段和数据段的修改和移动
tgdt:
		.word	0,0,0,0
		.word	3,0x8000,0x9a00,0x00c0		#0x8	text
		.word	3,0x8000,0x9200,0x00c0		#0x10	data
		.word	1,0xe000,0x921f,0x00c0		#0x18	stack
		.word	15,0x000,0x9201,0x00c0		#0x20	backup bios data
		.word	79,0x000,0x9202,0x00c0		#0x28	dma'a buffer
		.word	15,0x000,0x9a10,0x00c0		#0x30	inter's func
		.word	31,0x000,0x9207,0x00c0		#0x38	personal's data
		.word	7,0x8000,0x920b,0x00c0		#0x40	display
		.word	0,0,0,0
ljp:	.long	0
ljp1:	.long	0


msg:	.ascii	"booting.......................[ok]"
len=.-msg
err:	.long	0
.org	3579
.ascii	"part2"

