hd0.elf:hd0.bin
	objcopy -R .pdr -R .comment -R .note -S -O binary hd0.bin hd0.elf
%.bin:%.o
	ld -o $@ $< -Ttext 0
%.o:%.s
	as -o $@ $< 
clean:
	rm *.o *.bin *.elf
#------------------------
hd0.bin:hd0.o
hd0.o:hd0.s

