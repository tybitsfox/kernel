k0.elf:k0.bin
	objcopy -R .pdr -R .comment -R .note -S -O binary k0.bin k0.elf
%.bin:%.o
	ld -o $@ $< -Ttext 0
%.o:%.s
	as -o $@ $<
clean:
	rm *.o *.bin *.elf
#------------------------
k0.bin:k0.o
k0.o:k0.s

