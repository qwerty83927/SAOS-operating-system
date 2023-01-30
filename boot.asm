[bits 16]
[org 0x7C00]

mov [BOOT_DISK], dl
jmp boot

boot:
 mov ah, 0x0
 mov al, 0x03
 int 0x10

 mov ah, 2
 mov al, 64
 mov ch, 0
 mov cl, 2
 mov dl, [BOOT_DISK]
 xor bx, bx
 mov es, bx
 mov bx, 0x7E00
 int 0x13
 jmp 0x7E00

jmp $
BOOT_DISK db 0
times 510 - ($-$$) db 0
dw 0xaa55
