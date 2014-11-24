boot.img:boot.elf head.elf task.elf root.elf
	dd bs=512 if=boot.elf of=boot.img count=2
	dd bs=512 if=head.elf of=boot.img seek=2 count=7
	dd bs=512 if=task.elf of=boot.img seek=9 count=9
	dd bs=512 if=root/root.elf of=boot.img seek=18 count=2
	dd bs=512 if=/dev/zero of=boot.img seek=20 count=2860
boot.elf:boot.bin
	objcopy -R .pdr -R .comment -R .note -S -O binary boot.bin boot.elf
head.elf:head.bin
	objcopy -R .pdr -R .comment -R .note -S -O binary head.bin head.elf
task.elf:task.bin
	objcopy -R .pdr -R .comment -R .note -S -O binary task.bin task.elf
root.elf:
	(cd root;make)
boot.bin:boot.o
	ld -o boot.bin boot.o -Ttext 0
head.bin:head.o
	ld -o head.bin head.o -Ttext 0
task.bin:task.o
	ld -o task.bin task.o -Ttext 0
boot.o:bt6.s
	as -o boot.o bt6.s
head.o:hd6.s
	as -o head.o hd6.s
task.o:tk6.s
	as -o task.o tk6.s
clean:
	rm boot.* head.* task.*
	(cd root;make clean)
install:
	cp boot.img ~/

