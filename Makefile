run: boot.iso

boot.iso: boot.bin kernel.bin
	cat boot.bin kernel.bin > boot.iso
	od -t x1 -A n boot.iso

main.o: main.asm
	nasm main.asm -felf -o main.o

kernel.bin: kernel.asm main.asm main.o
	nasm kernel.asm -felf -o kernel.o
	ld -m elf_i386 -o kernel.bin -Ttext 0x7E00 kernel.o main.o --oformat binary

boot.bin: boot.asm
	nasm boot.asm -fbin -o boot.bin
