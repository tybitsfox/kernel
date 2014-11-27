vpath %.h ../include
kernel.elf:kernel.bin
	objcopy -R .pdr -R .comment -R .note -S -O binary kernel.bin kernel.elf
%.bin:%.o
	ld -o $@ $^ -Ttext 0 -Tdata 2c00
%.o:%.s
	as -o $@ $<
%.o:%.c
	gcc -fno-builtin -nostdinc -c -o $@ $< -I../include
klib.o:
	(cd ../klib;make)
clean:
	rm *.o *.bin *.elf
	(cd ../klib;make clean)
#----------------------------------
kernel.bin:kernel.o kern.o ../klib/klib.o
kernel.o:kernel.s
#kernel_end.o:kernel_end.s
kern.o:kern.c 

