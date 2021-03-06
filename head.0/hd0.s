.include"../include/defconst.inc"
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
	call clsr
	nop
	call setup_idt
	nop
	lidt l_idt
	call setup_pdt
	nop
	sti
	call motor_on
	nop
	movl $0,%eax
	movb $10,%ah
	call cmd_seek_head
	jnc 1f
8:
	call disp_flp_param
	nop
	movl err,%eax
	movl errt,%edx
	jmp .
1:	
	movl $0x1200,%eax
	roll $16,%eax
	addl $2,%eax
	movl $0x20000,%ebx
	call setup_dma
	movl $0x1234,%eax
	movl %eax,err
	jc 8b
	nop
	movl $10,%eax
	roll $16,%eax
	call cmd_read_sector
	movl $0x2345,%eax
	movl %eax,err
	jc 8b
	call move_ff1
	nop
	movl $0x2400,%eax
	roll $16,%eax
	addl $2,%eax
	movl $0x20000,%ebx
	call setup_dma
	jc 8b
	movl $1,%eax
	roll $16,%eax
	addl $4,%eax		#head=1
	call cmd_read_sector
	movl $0x23456,%eax
	movl %eax,err
	jc	8b
	call move_ff2
/*到这里，临时磁盘驱动已经成功加载了0x3600字节的kernel模块，如需继续加载可重复前面的加载代码，直到将全部的kernel加载进内存
 而前面已经加载的数据位于磁盘的0柱面0磁头的18扇区和1磁头的18扇区。下面将要完成pdt/pt,idt,gdt,tss,ldt正式系统表的设置以及内存
 核心表的设置。首先要根据加载进来的kernel模块中各中断处理程序的入口地址生成新的idt*/	
	call motor_off
	nop
	call setup_final_data
	nop
	cli
	call reset_8259A
	nop
	call setup_final_idt
	nop
	call setup_final_gdt
	nop
#	cli
	lidt l_fidt
	lgdt l_fgdt
#	sti
	jmp $0x8,$0
#	call disp_flp_ret
#	nop
	call show_msg
	movl $0,%eax
	movl $0,%edx
	jmp .
//{{{clsr
clsr:
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
	movl $0x400,%esi
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
//{{{flp_int
flp_int:
	pushl %eax
	movl $0x20,%eax
	outb %al,$0x20
	movl fflag,%eax
	orb $0x80,%al
	movl %eax,fflag
	popl %eax
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
	movl $0x7000,%edi
	addl $0x70,%edi
	leal flp_int,%edx
	movl $0x00080000,%eax
	movw %dx,%ax
	movw $0x8e00,%dx
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
//{{{setup_pdt
setup_pdt:
	pusha
	push %es
	movl $0x28,%eax
	movw %ax,%es
	movl $0,%edi
	movl $0x1007,%eax
	stosl 
	movl $1023,%ecx
	movl $0,%eax
	rep stosl
	movl $7,%eax
	movl $1024,%ecx
1:
	stosl
	addl $0x1000,%eax
	loop 1b
	pop %es
	popa
	ret
//}}}
//{{{disp
disp:
	pusha
	push %es
	movl $0x20,%eax
	movw %ax,%es
	leal msg,%esi
	movl $len,%ecx
	movl $0,%edi
	movl $0x0b00,%eax
1:
	lodsb
	stosw
	loop 1b
	pop %es
	popa
	ret
//}}}	
//{{{motor_on
motor_on:
	pushl %eax
	pushl %edx
	movl $0x1c,%eax
	movl $0x3f2,%edx
	outb %al,%dx
	movl $100,%eax
	call delay
	popl %edx
	popl %eax
	ret
//}}}
//{{{delay
//in:	eax delay times
//rt:	none	
delay:
	pushl %eax
	pushl %ebx
	movl count,%ebx
	addl %ebx,%eax
1:
	movl count,%ebx
	cmpl %ebx,%eax
	ja 1b
	popl %ebx
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
	movl $0xbbb,%eax
	movl %eax,errt
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
	movl $0xaaa,%eax
	movl %eax,errt
	jmp 9f
4:
	movl %ebx,%eax
	incl %edx
	outb %al,%dx
#	xorl %eax,%eax
	movl $0xccc,%eax
	movl %eax,errt
	clc
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
1:	
	movl fflag,%eax
	testb $0x80,%al
	jnz  2f
	movl $60,%eax
	call delay
	loop 1b
	stc
	movl $0x0b0b,%eax
	movl %eax,errt
	jmp 3f
2:	
	andb $0x7f,%al
	movl %eax,fflag
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
	push %ds
	pop %es
	movl $fbuf,%edi
	movl $0,%eax
	movl $10,%ecx
	rep stosb
	movl $fbuf,%edi
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
	movl $0xeeee,%eax
	movl %eax,errt
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
	clc
	movb %bl,%al
	stosb
	popa
	ret
//}}}
//{{{fetch_param
#in:	eax:index
#rt:	eax:param
fetch_param:
	push %es
	pushl %ebx
	pushl %edi
	movl $0x38,%ebx
	movw %bx,%es
	movl $0x10504,%edi
#	movl $BFPARAM12,%edi
	addl %eax,%edi
#	movb %gs:(%edi),%al
	xorl %eax,%eax
	movb %es:(%edi),%al
	popl %edi
	popl %ebx
	pop %es
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
	movl $0x0a0a,%eax
	movl %eax,errt
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
	clc
9:
	sti
	popa
	ret
//}}}	
//{{{disp_flp_param
disp_flp_param:
	pusha
	push %ds
	push %es
	push %ds
	pop  %es
	movl $0x38,%eax
	movw %ax,%ds
	movl $0x10504,%esi
	leal outbuf,%edi
	movl $10,%ecx
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
	jbe 3f
	addb $7,%al
3:
	stosb
	movb $0x20,%al
	stosb
	loop 1b
	movl $0x10,%eax
	movw %ax,%ds
	movl $0x20,%eax
	movw %ax,%es
	leal outbuf,%esi
	movl $160,%edi
	movl $30,%ecx
	movl $0x0a00,%eax
1:
	lodsb
	stosw
	loop 1b
	pop %es
	pop %ds
	popa
	ret
//}}}	
//{{{motor_off
motor_off:
	pushl %eax
	pushl %edx
	movl $0,%eax
	movl $0x3f2,%edx
	outb %al,%dx	
	popl %edx
	popl %eax
	ret
//}}}
//{{{disp_flp_ret
disp_flp_ret:
	pusha
	push %es
	push %ds
	pop %es
	leal fbuf,%esi
	leal outbuf,%edi
	movl $8,%ecx
1:
	lodsb
	movb %al,%bl
	rorb $4,%al
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
	jbe  3f
	addb $7,%al
3:
	stosb
	movb $0x20,%al
	stosb
	loop 1b
	movl $0x20,%eax
	movw %ax,%es
	leal outbuf,%esi
	movl $0,%edi
	movl $0x0a00,%eax
	movl $24,%ecx
4:
	lodsb
	stosw
	loop 4b
	pop %es
	popa
	ret
//}}}
//{{{show_msg
show_msg:
	pusha
	leal outbuf,%edi
	push %ds
	push %es
	movl $0x30,%eax
	movw %ax,%ds
	movl $0,%esi
	movl $10,%ecx
1:
	lodsb
	movb %al,%bl
	rorb $4,%al
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
	movl $0x10,%eax
	movw %ax,%ds
	movl $0x20,%eax
	movw %ax,%es
	leal outbuf,%esi
	movl $480,%edi
	movl $30,%ecx
	movl $0x0a00,%eax
/*	movl $0x28,%eax
	movw %ax,%ds
	movl $0x20000,%esi
	addl $1024,%esi
	movl $0x20,%eax
	movw %ax,%es
	movl $480,%edi
	movl $13,%ecx
	movl $0x0a00,%eax */
1:
	lodsb
	stosw
	loop 1b
	pop %es
	pop %ds
	popa
	ret
//}}}
//{{{move_ff1
move_ff1:
	pusha
	push %ds
	push %es
	movl $0x28,%eax
	movw %ax,%ds
	movl $0x20000,%esi
	movl $0x1200,%ecx
	movl $0x30,%eax
	movw %ax,%es
	movl $0,%edi
	rep movsb	
	pop %es
	pop %ds
	popa
	ret
//}}}
//{{{move_ff2
move_ff2:
	pusha
	push %ds
	push %es
	movl $0x28,%eax
	movw %ax,%ds
	movl $0x20000,%esi
	movl $0x2400,%ecx
	movl $0x30,%eax
	movw %ax,%es
	movl $0x1200,%edi
	rep movsb	
	pop %es
	pop %ds
	popa
	ret
//}}}
//{{{setup_final_data
//这是设置最终数据段的关键函数，最终的数据段不是由外存储读入的，关键数据均是由该函数设置的！	
setup_final_data:
	pusha
	push %ds
	push %es
	movl $0x38,%eax
	movw %ax,%ds
	movl $0,%eax
#先存储对应_SYS_DATA结构的数据
	movl $0,%esi
	movl %eax,(%esi)			#pos
	movl %eax,4(%esi)			#count
	movl $0x10500,%edi
	movl %ds:(%edi),%eax		#get mem
	movl %eax,8(%esi)			#mem
	movl $0,%eax
	movl %eax,12(%esi)			#real clock
	movw %ax,16(%esi)
#存储_SYS_TABLE结构的数据
	movl $0,%eax
	movl %eax,18(%esi)			#pdt_off
	movl $0x1000,%ebx
	movl %ebx,22(%esi)			#pdt_len
	movl %ebx,26(%esi)			#pd_off
	movl %ebx,30(%esi)			#pd_len
	movl $0x4000,%eax
	movl %eax,34(%esi)			#idt_off
	movl $0x800,%eax
	movl %eax,38(%esi)			#idt_len
	movl $0x5000,%eax
	movl %eax,42(%esi)			#gdt_off
	movl $87,%eax
	movl %eax,46(%esi)			#gdt_len
	movl $0x6000,%eax
	movl %eax,50(%esi)			#tss0_off
	movl $104,%eax
	movl %eax,54(%esi)			#tss0_len
	movl $0x6100,%eax
	movl %eax,58(%esi)			#ldt0_off
	movl 47,%eax
	movl %eax,62(%esi)			#ldt0_len
	movl $0x6200,%eax
	movl %eax,66(%esi)			#tss1_off
	movl $104,%eax
	movl %eax,70(%esi)			#tss1_len
	movl $0x6300,%eax
	movl %eax,74(%esi)			#ldt1_off
	movl $47,%eax
	movl %eax,78(%esi)			#ldt1_len
	movl $KERNEL_DATA_BEGIN,%ebx
	movl $0,%eax
	addl %ebx,%eax
	movl %eax,82(%esi)			#sys_data's offset
	movl $94,%eax
	addl %ebx,%eax
	movl %eax,86(%esi)			#sys_flp's offset
	movl $126,%eax
	addl %ebx,%eax
	movl %eax,90(%esi)			#sys_seg's offset
#开始初始化_SYS_FLOPPY的数据	
	push %ds
	pop  %es
	movl %esi,%edi
	addl $94,%edi
	movl $0x10504,%esi
	movl $0,%eax
	stosl						#98
	movl $12,%ecx
	rep movsb					#floppy's parameter
#初始化_SYS_SEG
	movl $126,%edi
	movl $0x1f00,%eax
	stosl
	movl $0x18,%eax
	stosl						#kstk[2]
	movl $0x10,%eax
	stosl						#kds
	movl $0x20,%eax
	stosl						#kdisp
	movl $0x28,%eax
	stosl						#ktab
	stosl						#kdma
	movl $0x20000,%eax
	stosl						#kmda_off
	movl $0x101000,%eax
	stosl						#kds_safe_off
	pop %es
	pop %ds
	popa
	ret
//}}}
//{{{setup_final_idt
setup_final_idt:
	pusha
	push %ds
	push %es
	movl $0x28,%eax
	movw %ax,%es
	movw %ax,%ds
	movl $0x20000,%esi
	addl $0x1a00,%esi			#??1700
	movl $0x4000,%edi
	lodsl						#get nor_int
	movl $0x00080000,%ebx
	movw %ax,%bx
	movw $0x8e00,%ax
	movl $256,%ecx
1:
	movl %ebx,%es:(%edi)
	movl %eax,%es:4(%edi)
	addl $8,%edi
	loop 1b
	lodsl						#get time_int
	movl $0x4000,%edi
#	addl $64,%edi				now change to int0x20~~
	addl $0x100,%edi
	movl $0x00080000,%ebx
	movw %ax,%bx
	movw $0x8e00,%ax
	movl %ebx,%es:(%edi)
	movl %eax,%es:4(%edi)
	lodsl						#flp_int
	movl $0x4000,%edi
#	addl $0x70,%edi				now change to int0x26~~
	addl $0x130,%edi
	movl $0x00080000,%ebx
	movw %ax,%bx
	movw $0x8e00,%ax
	movl %ebx,%es:(%edi)
	movl %eax,%es:4(%edi)
	lodsl						#sys_int
	movl $0x4000,%edi
	movl $0x400,%edi
	movl $0x00080000,%ebx
	movw %ax,%bx
	movw $0xef00,%ax
	movl %ebx,%es:(%edi)
	movl %eax,%es:4(%edi)
	pop %es
	pop %ds
	popa
	ret
//}}}
//{{{setup_final_gdt
setup_final_gdt:
	pusha
	movl $0x10,%eax
	movw %ax,%ds
	push %es
	movl $0x28,%eax
	movw %ax,%es
	movl $0x5000,%edi
	leal fgdt,%esi
	xorl %ecx,%ecx
	movw l_fgdt,%cx
	incl %ecx
	rep movsb
	pop %es
	popa
	ret
//}}}
//{{{reset_8259A
reset_8259A:
	pusha
	movl $0x11,%eax			#初始化命令字
	movl $0x20,%edx
	out %al,%dx				#发送至主芯片
	jmp .+2
	jmp .+2
	movl $0xa0,%edx			#发送至从芯片
	outb %al,%dx
	jmp .+2
	jmp .+2
	movl $0x20,%eax			#设置主芯片中断起始号
	movl $0x21,%edx
	outb %al,%dx
	jmp .+2
	jmp .+2
	movl $0xa1,%edx
	movl $0x28,%eax			#设置从芯片中断起始号
	outb %al,%dx
	jmp .+2
	jmp .+2
	movl $4,%eax			#设置主芯片的IR2连接从芯片INT
	movl $0x21,%edx
	outb %al,%dx
	jmp .+2
	jmp .+2
	movl $2,%eax			#设置从芯片的INT连接主芯片的IR2
	movl $0xa1,%edx
	outb %al,%dx
	jmp .+2
	jmp .+2
	movl $1,%eax			#设置8086模式，普通EIO，非缓冲，需发送命令字复位
	movl $0x21,%edx
	outb %al,%dx
	jmp .+2
	jmp .+2
	movl $0xa1,%edx
	outb %al,%dx
	jmp .+2
	jmp .+2
	movl $0xff,%eax			#屏蔽命令字，屏蔽所有中断
	movl $0x21,%edx
	outb %al,%dx
	jmp .+2
	jmp .+2
	movl $0xa1,%edx
	outb %al,%dx
	jmp .+2
	jmp .+2
	popa
	ret
//}}}






stk:	.long	0x1f00,0x18
count:	.long	0
l_idt:	.word	0x800
		.long	0x7000,0
l_fidt:	.word	0x800
		.long	0x4000,0
l_fgdt:	.word	87
		.long	0x5000,0
fgdt:
		.word	0,0,0,0
		.word	511,0x000,0x9a10,0x00c0		#0x8 text
		.word	511,0x000,0x9210,0x00c0		#0x10 data
		.word	1,0xe000,0x922f,0x00c0		#0x18 stack
		.word	7,0x8000,0x920b,0x00c0		#0x20 disp
		.word	159,0x000,0x9200,0x00c0		#0x28 sys table
		.word	104,0x6000,0xe900,0			#0x30 tss0
		.word	47,0x6100,0xe200,0			#0x38 ldt0
		.word	104,0x6200,0xe900,0			#0x40 tss1
		.word	47,0x6300,0xe200,0			#0x48 ldt1
		.word	0,0,0,0
msg:	.ascii	"booting.......................[ok]"
len=.-msg
fflag:	.long	0
err:	.long	0
fbuf:	.space	20,0
outbuf:	.space	60,0
emsg:	.ascii	"error!"
errt:	.long	0
.org	3579
.ascii	"part2"

