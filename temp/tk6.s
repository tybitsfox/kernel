/*本文件将完成所有中断程序以及0x80系统调用程序的实现*/
.include "./defconst.inc"
.data
.text
//{{{nor_int
#目前是通用中断程序的实现，该程序将逐步被每个实现的真实中断程序所代替
nor_int:
	pusha
	push %es
	movl $REG_DEF_GS,%eax
	movw %ax,%gs
	movl $DISP,%eax
	call get_seg
	cmpl $0,%eax
	je  9f
	movw %ax,%es
	movl $158,%edi
	movl $0x0c41,%eax
	stosw 
9:	
	pop %es
	popa
	iret
//}}}
//{{{time_int
time_int:
	pushl %eax
	pushl %edx
	movl $0x20,%eax
	movl $0x20,%edx
	outb %al,%dx
	movl $REG_DEF_GS,%eax
	movw %ax,%gs
	movl $LCOUNT1,%edx
	movl %gs:(%edx),%eax
	incl %eax					#counts per 1/1000 sec
	cmpl $MAX_TIME_CNT,%eax
	jbe  1f
	movl $0,%eax
1:
	movl %eax,%gs:(%edx)
	popl %edx
	popl %eax
	iret
//}}}
//{{{sys_int
/*2014-11-6目前只实现了2个系统中断调用：秒级的延迟调用和读磁盘调用
 ******延迟调用的入口参数********
 ah:	调用号，0xA0
 al:	需要延迟的秒数
 返回值： 无
 ******读磁盘调用的入口参数******
 ah:	调用号，2
 al:	本次要读取的扇区数
 ecx:	磁头/驱动器号，其中：bit0-1:驱动器A-D，bit2:磁头号
 edx:	本次要读取的开始扇区号(1-base),注意该值中包含了磁道号，磁道号
 的计算为该值-1整除18,余值+1为指定磁道的扇区号。
 es:ebx:	调用成功后接受数据的缓冲区地址。
 返回值： eax:=0为成功，=1失败
 */	
#rt:	none	
sys_int:
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %esi
	pushl %edi
	cmpb $0xa0,%ah			#time delay for 1 second
	je  1f
	cmpb $2,%ah			#floppy int
	jne 9f
	call flp_syscall
	jc  f01
	movl $0,%eax
	jmp 9f
f01:
	movl $1,%eax
	jmp 9f
1:
	andl $0xff,%eax
	xorl %edx,%edx
	movw $100,%bx
	mulw %bx
	movl $REG_DEF_GS,%ebx
	movw %bx,%gs
	movl $LCOUNT1,%edi
	movl %gs:(%edi),%ecx
	addl %ecx,%eax
	clc
2:
	movl %gs:(%edi),%ecx
	cmpl %eax,%ecx
	jb 2b	
9:
	popl %edi
	popl %esi
	popl %edx
	popl %ecx
	popl %ebx
	iret	
//}}}
//{{{int_0xF
int_0xF:
	pushl %eax
	pushl %edi
	push %es
	movl $0x20,%eax
	outb %al,$0x20
	movl $REG_DEF_GS,%eax
	movw %ax,%gs
	movl $DISP,%eax
	call get_seg
	cmpl $0,%eax
	je  9f
	movw %ax,%es
	movl $638,%edi
	movl $0x0c44,%eax
	stosw
9:	
	pop %es
	popl %edi
	popl %eax
	iret
//}}}
//{{{flp_int
flp_int:
	pushl %eax
	pushl %edi
	movl $0x20,%eax
	outb %al,$0x20
	movl $REG_DEF_GS,%eax
	movw %ax,%gs
	movl $BFFLAG4,%edi
	movl %gs:(%edi),%eax
	orb  $0x80,%al
	movl %eax,%gs:(%edi)
	popl %edi
	popl %eax
	iret
//}}}
//{{{flp_syscall
#读取磁盘的系统调用	
#该函数应首先考虑一次读取的扇区是否在同一磁道内，如果不是则应分多次调用
#
#	
#in:	eax: al:sector number #由于dma缓冲区大小为320k，所以该值不应超过
#640,而al最大为255,所以这里不用考虑越界的可能。	
#		es:ebx->output buffer
#		ecx:head/driver
#		edx:sector index(1-base),注意：该值最大为1面的扇区数即80×18
#rt:	CF
flp_syscall:
	clc
	pushl %eax
	movl $REG_DEF_GS,%eax
	movw %ax,%gs
	movl $BENABLE1,%esi
	movb $0,%al
	movb %al,%gs:(%esi)
#首先考虑是否在同一磁道内,先将所有信息分割并保存至缓冲区中
	movl $BSIZE1,%esi
	popl %eax
	movb %al,%gs:(%esi)		#save current sector's count
	movl %ecx,%eax
	andl $3,%eax			#get driver
	movl $BDRV1,%esi
	movb %al,%gs:(%esi)		#save driver
	movl %ecx,%eax
	rorl $2,%eax			#get head
	andl $1,%eax
	movl $BHEAD1,%esi
	movb %al,%gs:(%esi)
	movl $WSEG1,%esi
	movw %es,%ax
	movw %ax,%gs:(%esi)		#save output buffer's seg
	movl %ebx,%eax
	movl %eax,%gs:2(%esi)	#save output buffer's offset
	movl $BCYD1,%esi
	movl %edx,%eax
	decl %eax
	xorl %edx,%edx
	movl $18,%ecx
	divw %cx
	cmpl $79,%eax
	jbe 1f
	movl $BENABLE1,%esi
	movb $0,%al
	movb %al,%gs:(%esi)
	stc
	jmp 9f
1:
	movb %al,%gs:(%esi)		#save current cylinder
	movl $BSECTOR1,%esi
	incl %edx
	movb %dl,%gs:(%esi)		#save sector's index to begin
	xorl %eax,%eax
	andl $0xff,%edx
	movl $BSIZE1,%esi
	movb %gs:(%esi),%al
	addl %edx,%eax
	cmpl $19,%eax
	jbe  2f
	movl $19,%ebx
	subl %edx,%ebx
	xchgb %bl,%gs:(%esi)	#将本次读取的扇区数存入
	movb %gs:(%esi),%al
	subb %al,%bl			#剩余的扇区数
	andl $0xff,%ebx
	pushl %ebx				#保存剩余的扇区数，备下次调用
#开始计算下次缓冲区偏移
	andl $0xff,%eax
	movl $512,%ebx
	xorl %edx,%edx
	mulw %bx
	movl $LOFFSET1,%esi
	movl %gs:(%esi),%ebx
	addl %eax,%ebx
	pushl %ebx				#保存下次读入时的接受缓冲偏移地址
	push %es				#保存下次读入时的缓冲区段选择符
	movl $BHEAD1,%esi
	movb %gs:(%esi),%al
	movl $BDRV1,%esi
	movb %gs:(%esi),%ah
	rolb $2,%al
	addb %ah,%al
	andl $0xf,%eax
	pushl %eax				#保存下次读入时的磁头和驱动器号
	xorl %eax,%eax
	movl $BCYD1,%esi
	movb %gs:(%esi),%al
	incb %al
	movl $18,%ecx
	mulw %cx
	incl %eax
	movl %eax,%edx				#保存下次读取时的当前扇区号（含磁道号）
	movl $BENABLE1,%esi
	movb $1,%al
	movb %al,%gs:(%esi)
	popl %ecx
	pop %es
	popl %ebx
	popl %eax
2:
#	call read
	pusha
	push %es
	call fcall
/*	movl $REG_DEF_GS,%eax
	movw %ax,%es
	movl $BHEAD1,%esi
	movl $12,%ecx
	call conv_string
	nop
	movl $36,%ecx
	call disp_normal */
	pop %es
	popa
	jc 9f
	movl %eax,%edi
	movl $BENABLE1,%esi
	movb %gs:(%esi),%al
	cmpb $0,%al
	je 9f
	movl %edi,%eax
	jmp flp_syscall
9:
	ret
//}}}
//{{{conv_string
#in:	es:esi-> data to be convert
#		ecx:count CF
conv_string:
	pusha
	push %ds
	push %es
	cmpl $300,%ecx			#convert max count is 333
	jbe  0f
	stc
	jmp 4f
0:	
	clc
	push %es
	pop %ds
	movl $REG_DEF_GS,%eax
	movw %ax,%es
	movl $BBUF_1000,%edi
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
4:	
	pop %es
	pop %ds
	popa
	ret
//}}}	
//{{{int_show
#这是一个调用和远调用都可执行的函数，但是必须通过eax来区分二者，
#eax=0时为普通调用，！=0时为远调用。	
int_show:
	pushl %eax
	movl $REG_DEF_GS,%eax
	movw %ax,%gs
	movl $DISP,%eax
	call get_seg
	cmpl $0,%eax
	je 0f
	movw %ax,%es
	movl $0x0b46,%eax
	movl $798,%edi
	stosw
	movl %esp,%ebx
	movl 4(%esp),%ecx
	movl 8(%esp),%edx
0:	
	popl %eax
	cmpl $0,%eax
	jne  1f
	ret
1:
	lret 
//}}}
//{{{get_seg
#in:	eax:seg index
#rt:	eax:new seg
get_seg:
	pushl %ebx
	movl $REG_DEF_GS,%ebx
	movw %bx,%gs
	cmpl $DISP,%eax
	jne  1f
	movl %gs:(%eax),%ebx
	xchgl %eax,%ebx
	jmp 9f
1:
	cmpl $DMA,%eax
	jne 2f
	movl %gs:(%eax),%ebx
	xchgl %eax,%ebx
	jmp 9f
2:
	cmpl $BIOS,%eax
	jne 3f
	movl %gs:(%eax),%ebx
	xchgl %eax,%ebx
	jmp 9f
3:
	cmpl $TEXT,%eax
	jne 4f
	movl %gs:(%eax),%ebx
	xchgl %eax,%ebx
	jmp 9f
4:
	cmpl $DATA,%eax
	jne 5f
	movl %gs:(%eax),%ebx
	xchgl %eax,%ebx
	jmp 9f
5:
	cmpl $INTTEXT,%eax
	jne 6f
	movl %gs:(%eax),%ebx
	xchgl %eax,%ebx
	jmp 9f
6:
	xorl %eax,%eax				#error if return 0
9:
	popl %ebx
	ret
//}}}
//{{{calc_pos
#该函数是由head模块中移植过来的，由于head模块在初始化完成后整段代码就被遗弃
#而一些有用的函数将移植到此继续被调用执行。该函数与head模块中同名函数有少许
#的区别,原因在于head模块中的函数要保持尽量简洁，少占用空间。所以有些段值是
#硬编码进代码中的，这里就要考虑通用性以及安全性，所以，不能再使用硬编码的形
#式了.同理其他一些从head中移植过来的函数也照此处理。
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
	movl $REG_DEF_GS,%eax
	movw %ax,%gs
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
//{{{disp_flp_return
#该函数也是从head模块中移植过来的。	
disp_flp_return:
	pusha
	push %ds
	push %es
	movl $REG_DEF_GS,%eax
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

	movl $DISP,%eax
	call get_seg
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
	movl $REG_DEF_GS,%eax
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
	movl $DISP,%eax
	call get_seg
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
//{{{disp_normal
disp_normal:
	push %ds
	push %es
	pushl %ecx
	movl $REG_DEF_GS,%eax
	movw %ax,%ds
	movl $DISP,%eax
	call get_seg
	movw %ax,%es
	popl %ecx
	movl $BBUF_1000,%esi
	call calc_pos
	movl $0x0a00,%eax
1:
	lodsb
	stosw
	loop 1b
	pop %es
	pop %ds
	ret
//}}}
//{{{delay
#in:	eax:delay times per 1/100 second
#rt:	none
delay:
	pushl %eax
	pushl %edx
	pushl %ecx
	movl $REG_DEF_GS,%edx
	movw %dx,%gs
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
//{{{motor_on
#所有和软盘驱动相关的函数虽然是从head拷贝过来的，但是这里的调用进行了改写
#所有参数的传递不再是由寄存器传入了，而是从已经设置好的personal数据段获取
#in:	eax:0-3:driver A-D <----no use in task model
#rt:	CF
motor_on:
	pusha
	movl $BDRV1,%esi
	movl $REG_DEF_GS,%eax
	movw %ax,%gs
	xorl %eax,%eax
	movb %gs:(%esi),%al
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
//{{{cmd_seek_head
#in:	eax:bit0-1:driverA-D,bit2:head,bit8-bit15:cylinder
#rt:	CF
cmd_seek_head:
	movl $REG_DEF_GS,%eax
	movw %ax,%gs
	movl $BCYD1,%esi
	movb %gs:(%esi),%ah			#get cylinder
	movl $BHEAD1,%esi
	movb %gs:(%esi),%al
	rolb $2,%al
	movl $BDRV1,%esi
	movb %gs:(%esi),%bl
	addb %bl,%al				#get head/driver

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
	movl $REG_DEF_GS,%eax
	movw %ax,%gs
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
	movl $REG_DEF_GS,%eax
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
	pushl %ebx
	movl $REG_DEF_GS,%ebx
	movw %bx,%gs
	movl $BFPARAM12,%edi
	addl %eax,%edi
	movb %gs:(%edi),%al
	popl %ebx
	popl %edi
	ret
//}}}
//{{{cmd_read_sector
#in:	eax:bit0-1:driver,bit2:head,bit8-15:cylinder,bit16-23:sector
#rt:	CF
cmd_read_sector:
	movl $REG_DEF_GS,%eax
	movw %ax,%gs
	movl $BCYD1,%esi
	movb %gs:(%esi),%ah			#get cylinder
	movl $BHEAD1,%esi
	movb %gs:(%esi),%al
	rolb $2,%al
	movl $BDRV1,%esi
	movb %gs:(%esi),%bl
	addb %bl,%al				#get head/driver
	movl $BSECTOR1,%esi
	xorl %ebx,%ebx
	movb %gs:(%esi),%bl
	roll $16,%ebx
	addl %ebx,%eax				#get sector  not 19,is 1
	movl $0x20004,%eax
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
	call send_cmd					#send param2 cylinder
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
	movl $REG_DEF_GS,%edx
	movw %dx,%gs
	movl $BSIZE1,%esi
	xorl %eax,%eax
	movb %gs:(%esi),%al
	movw $512,%cx
	xorl %edx,%edx
	mulw %cx
	roll $16,%eax
	addl $2,%eax					#tunnel 2
	movl $0x20000,%ebx				#dma缓冲区的物理地址

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
//{{{fcall
fcall:
	call motor_on
	jc 9f
	call cmd_seek_head
	jc 9f
#	call disp_flp_return	return 20 01 02
#	jmp .
	call setup_dma
	jc 9f
	call cmd_read_sector
	jc 9f
#	call disp_flp_return
#	jmp .
	call cmd_chk_interrupt
9:
	ret
//}}}	


//{{{test
#这是一个测试程序，由内核代码跳转至这里，并从这里开始测试各个移植过来的函数
#测试成功！
test:
	movl $DATA,%eax
	call get_seg
	movw %ax,%ds
	movw %ax,%es
	movw %ax,%fs
	call disp_flp_param
	nop
	call disp_flp_return
	nop
	movl $DMA,%eax
	call get_seg
	movw %ax,%es
	movl $0,%esi
	movl $13,%ecx
	call conv_string
	movl $39,%ecx
	call disp_normal
	nop

	movl $0x0201,%eax
	movl $REG_DEF_GS,%ebx
	movw %bx,%es
	movl $BBUF_1000,%ebx
	movl $0,%ecx
	movl $19,%edx
	int $0x80
	cmpl $0,%eax
	jne 9f
	push %ds
	push %es
	
	movl $DMA,%eax
	call get_seg
	movw %ax,%ds
	movl $REG_DEF_GS,%eax
	movw %ax,%es
	movl $0,%esi
	movl $BBUF_1000,%edi
	movl $13,%ecx
	rep movsb
	movl $13,%ecx
/*	movl $DMA,%eax
	call get_seg
	movw %ax,%es
	movl $0,%esi
	movl $13,%ecx
	call conv_string
	movl $39,%ecx */
	call disp_normal
	pop %es
	pop %ds
9:	
	jmp .
//}}}	






.org	4000
/*这里存储了一个类似与idt的各中断的偏移地址，因为该模块的重定位信息不可能直接被head模块的初始化程序使用
 所以，必须借助下面的这些定义来取得。如果这种做法不行，那么就只能测试将idt的安装函数也放在这里，然后
 由head模块跳转至安装函数进行中断函数的安装了。测试可行！实际上这可以理解为linux的system.map了，呵呵。
 事实上，这种做法使所有中断处理使用单独一个代码段成为可能，也就是我设想的内核模块存在2个代码段： 内核代码
 段和中断处理代码段，加之远调用测试的成功，就可以使用这种方法在两个代码段之间共享部分函数了。不过这种做法
 是否必要还有待考虑。
 另外自这里开始的信息虽然由磁盘读取到内存中，但，不必安装到某指定位置长期使用。像下面这些中断函数入口地址信息
 我也仅是在安装idt时使用。安装完成后这些信息就不再使用了，因此他们只存在于dma的buffer中，没必要将其随执行代码
 移动到指定段位置处。
 */
rcl_nor_int:		.long nor_int
rcl_nor_time_int:	.long time_int
rcl_sys_int:		.long sys_int
rcl_int_0xF:		.long int_0xF
rcl_flp_int:		.long flp_int
rcl_int_show:		.long int_show
rcl_test:			.long test
.org	4500
.ascii	"hello world"
err:				.long	0
.org	4603
.ascii	"part3"

