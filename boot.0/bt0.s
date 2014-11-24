/*这是实模式下的模块代码，由bios自动加载，该模块需完成：
 1、保护模式下临时模块head的加载
 2、取得bios设置的软盘参数表，并保存至指定位置
 3、取得bios设置的硬盘参数表，并保存至指定位置
 4、通过int15H调用取得物理内存大小，并保存至指定位置
 5、加载临时gdt，并跳转至保护模式
 */
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
	mov $0x0208,%ax
	int $0x13
	jnc 1f
	jmp .
1:
	call get_phy_mem
	nop
	call get_flp_param
	nop
	call get_hd_param
	nop
	cli
	lgdt l_gdt
	mov %cr0,%eax
	or $1,%eax
	mov %eax,%cr0
	jmp $8,$0
	
//{{{get_phy_mem
get_phy_mem:
	push %es
	mov $0x50,%ax
	mov %ax,%es
	mov $0,%ebx
	mov $0,%esi
1:
	mov $0,%edi
	mov $20,%ecx
	mov $0x534d4150,%edx		#SMAP
	mov $0xe820,%eax
	int $0x15
	jc  2f
	mov %es:8(%di),%eax
	add %eax,%esi
	cmp $0,%ebx
	je 3f
	jmp 1b
2:
	mov $0,%esi
3:
	mov $0,%edi
	mov %esi,%es:(%di)			#save in 0x0050:0
	pop %es
	ret
//}}}
//{{{get_flp_param
get_flp_param:
	push %ds
	push %es
	mov $0x50,%ax
	mov %ax,%es
	mov $4,%di
	mov $0x78,%ax			#int 0x1e
	mov %ax,%ds
	mov $0,%si
	lodsw
	mov %ax,%bx
	lodsw
	mov %ax,%ds
	mov %bx,%si
	mov $10,%cx
	rep movsb
	pop %es
	pop %ds
	ret
//}}}
//{{{get_hd_param
get_hd_param:
	push %ds
	push %es
	mov $0x50,%ax
	mov %ax,%es
	mov $14,%di
	mov $0x104,%ax
	mov %ax,%ds
	mov $0,%si
	lodsw
	mov %ax,%bx
	lodsw
	mov %ax,%ds
	mov %bx,%si
	mov $16,%cx
	rep movsb
	pop %es
	pop %ds
	ret
//}}}	


stk:	.word	0x300,0x4000,0
.org	510
.word	0xaa55
l_gdt:	.word	71,0x7c00+gdt,0
gdt:
		.word	0,0,0,0
		.word	3,0x8000,0x9a00,0x00c0			#0x8	text
		.word	3,0x8000,0x9200,0x00c0			#0x10	data
		.word	1,0xe000,0x921f,0x00c0			#0x18	stack
		.word	7,0x8000,0x920b,0x00c0			#0x20	disp
		.word	159,0x000,0x9200,0x00c0			#0x28	sys table
		.word	127,0x000,0x9210,0x00c0			#0x30	final text
		.word	127,0x000,0x9220,0x00c0			#0x38	final data
		.word	0,0,0,0
.org	1019
.ascii	"part1"

