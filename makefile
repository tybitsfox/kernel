boot.img:bt0.elf hd0.elf k0.elf
	dd bs=512 if=./boot.0/bt0.elf of=boot.img count=2
	dd bs=512 if=./head.0/hd0.elf of=boot.img seek=2 count=7
	dd bs=512 if=./kernel/k0.elf of=boot.img seek=9 count=27
	dd bs=512 if=/dev/zero of=boot.img seek=36 count=2844
bt0.elf:
	(cd boot.0;make)
hd0.elf:
	(cd head.0;make)
k0.elf:
	(cd kernel;make)
clean:
	(cd kernel;make clean)
	(cd boot.0;make clean)
	(cd head.0;make clean)
	rm boot.img
install:
	cp boot.img ~/

