run: boot.iso

boot.iso: boot.bin kernel.bin
	cat boot.bin kernel.bin > boot.iso

kernel.bin: kernel.asm main.o
	nasm kernel.asm -felf -o kernel.o
	ld -m elf_i386 -o kernel.bin -Ttext 0x7E00 kernel.o main.o --oformat binary

main.o: main.c
	gcc -m32 -fno-pie -ffreestanding -c main.c -o main.o

boot.bin: boot.asm
	nasm boot.asm -fbin -o boot.bin
