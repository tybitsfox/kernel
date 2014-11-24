bt0.elf:bt0.bin
	objcopy -R .pdr -R .comment -R .note -S -O binary bt0.bin bt0.elf
%.bin:%.o
	ld -o $@ $< -Ttext 0
%.o:%.s
	as -o $@ $<
clean:
	rm *.o *.bin *.elf
#----------------------
bt0.bin:bt0.o
bt0.o:bt0.s

