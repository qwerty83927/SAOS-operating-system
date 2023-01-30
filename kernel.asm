[bits 16]

jmp start

gdt_nulldesc:
 dd 0
 dd 0
gdt_codedesc:
 dw 0xFFFF
 dw 0x0000
 db 0x00
 db 10011010b
 db 11001111b
 db 0x00
gdt_datadesc:
 dw 0xFFFF
 dw 0x0000
 db 0x00
 db 10010010b
 db 11001111b
 db 0x00
gdt_end:
gdt_descriptor:
 gdt_size:
  dw gdt_end - gdt_nulldesc - 1
  dq gdt_nulldesc

codeseg equ gdt_codedesc - gdt_nulldesc
dataseg equ gdt_datadesc - gdt_nulldesc

start:
 in al, 0x92
 or al, 2
 out 0x92, al
 cli
 lgdt [gdt_descriptor]
 mov eax, cr0
 or eax, 1
 mov cr0, eax
 jmp codeseg:kernel32

[bits 32]

section .bss
idt:
 resd 64
idt_reg:
 resb 6

section .data

idtr:
 dw (64*2)-1
 dd idt

keyboard_map: db 0,27,"1234567890-=BTqwertyuiop[]E",2,"asdfghjkl;'~",1,"\zxcvbnm,./",1,0,0," ",0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,4,0,5,0,0,6,0,0,0,0,0
cursor_pos: dd 0

section .text
global cursor_pos

isr0:
 push BYTE 0
 push BYTE 0
 jmp isr_common_stub

isr1:
 mov edx, 0x20
 mov al, 0x20
 out dx, al
 call keyboard_handler
 push BYTE 0
 push BYTE 1
 jmp isr_common_stub

isr2:
 mov ebx, 0

 mov edx, 0x3d4
 mov al, 0x0e
 out dx, al
 mov eax, 0

 mov edx, 0x3d5
 in al, dx
 shl eax, 8
 add ebx, eax
 mov eax, 0

 mov edx, 0x3d4
 mov al, 0x0f
 out dx, al
 mov eax, 0

 mov edx, 0x3d5
 in al, dx
 add ebx, eax

 push BYTE 0
 push BYTE 2
 jmp isr_common_stub

isr3:
 pusha
 push ebx

 mov edx, 0x3d4
 mov al, 0x0e
 out dx, al

 mov edx, 0x3d5
 shr ebx, 8
 mov al, bl
 out dx, al
 mov ebx, 0

 mov edx, 0x3d4
 mov al, 0x0f
 out dx, al

 mov edx, 0x3d5
 pop ebx
 and ebx, 0xff
 mov al, bl
 out dx, al
 popa
 push BYTE 0
 push BYTE 3
 jmp isr_common_stub

isr12:
 push BYTE 12
 jmp isr_common_stub

isr31:
 push BYTE 0
 push BYTE 31
 jmp isr_common_stub

irq0:
 push BYTE 0
 push BYTE 32
 jmp irq_common_stub

irq1:
 push BYTE 1
 push BYTE 33
 jmp irq_common_stub

irq7:
 push BYTE 7
 push BYTE 39
 jmp irq_common_stub

irq8:
 push BYTE 8
 push BYTE 40
 jmp irq_common_stub

irq15:
 push BYTE 15
 push BYTE 47
 jmp irq_common_stub

irq_common_stub:
isr_common_stub:
 pusha
 mov ax, ds
 push eax
 mov ax, 0x10
 mov ds, ax
 mov es, ax
 mov fs, ax
 mov gs, ax
 push esp
 call handler
 pop eax
 pop eax
 mov ds, ax
 mov es, ax
 mov fs, ax
 mov gs, ax
 popa
 add esp, 8
 iret

handler:
 ret

keyboard_handler:
 pusha

 mov edx, 0x60
 in al, dx
 cmp al, BYTE 0
 jle .exit

 mov eax, [keyboard_map+eax]

 push eax
 int 2
 pop eax

 cmp al, BYTE 3
 je .up_arrow
 cmp al, BYTE 4
 je .left_arrow
 cmp al, BYTE 5
 je .update
 cmp al, BYTE 6
 je .down_arrow
 cmp al, BYTE 'E'
 je .enter
 cmp al, BYTE 'B'
 je .backspace

 mov [0xb8000+ebx*2], BYTE al
 mov [0xb8000+ebx*2+1], BYTE 0x0f
 jmp .update

.up_arrow:
 sub ebx, 81
 jmp .update
.down_arrow:
 add ebx, 79
 jmp .update
.backspace:
 mov [0xb8000+ebx*2-2], BYTE 0
.left_arrow:
 sub ebx, 2
 jmp .update
.enter:
 push ebx
 mov eax, ebx
 cdq
 mov ebx, 80
 idiv ebx
 inc eax
 imul ebx
 mov ebx, eax
 pop ecx
 add ecx, ecx
 mov edx, ebx
 add edx, edx
 sub edx, ecx
 ;edx = max_letters_per_row - index_you_pressed_button_on
 dec ebx
 jmp .update
.update:
 inc ebx
 int 3

.exit:
 popa
 ret

[extern main]

kernel32:
 mov ax, dataseg
 mov ds, ax
 mov ss, ax
 mov es, ax
 mov fs, ax
 mov gs, ax

 mov [0xb8000], BYTE 'B'
 mov [0xb8002], BYTE 'o'
 mov [0xb8004], BYTE 'o'
 mov [0xb8006], BYTE 't'
 mov [0xb8008], BYTE 'i'
 mov [0xb800a], BYTE 'n'
 mov [0xb800c], BYTE 'g'

 mov edx, 0x3d4
 mov al, 0x0e
 out dx, al

 mov edx, 0x3d5
 mov al, 80 >> 8
 out dx, al

 mov edx, 0x3d4
 mov al, 0x0f
 out dx, al

 mov edx, 0x3d5
 mov al, 80 & 0xff
 out dx, al

 lidt [idtr]
 mov eax,isr0
 mov [idt+0*8],ax
 mov word [idt+0*8+2],0x08
 mov word [idt+0*8+4],0x8E00
 shr eax,16
 mov [idt+0*8+6],ax

 mov eax,isr1
 mov [idt+1*8],ax
 mov word [idt+1*8+2],0x08
 mov word [idt+1*8+4],0x8E00
 shr eax,16
 mov [idt+1*8+6],ax

 mov eax,isr2
 mov [idt+2*8],ax
 mov word [idt+2*8+2],0x08
 mov word [idt+2*8+4],0x8E00
 shr eax,16
 mov [idt+2*8+6],ax

 mov eax,isr3
 mov [idt+3*8],ax
 mov word [idt+3*8+2],0x08
 mov word [idt+3*8+4],0x8E00
 shr eax,16
 mov [idt+3*8+6],ax

 mov eax,isr12
 mov [idt+12*8],ax
 mov word [idt+12*8+2],0x08
 mov word [idt+12*8+4],0x8E00
 shr eax,16
 mov [idt+12*8+6],ax

 mov eax,isr31
 mov [idt+31*8],ax
 mov word [idt+31*8+2],0x08
 mov word [idt+31*8+4],0x8E00
 shr eax,16
 mov [idt+31*8+6],ax

 mov edx, 0x20
 mov al, 0x11
 out dx, al
 mov edx, 0xA0
 mov al, 0x1
 out dx, al
 mov ebx, 0x21
 mov al, 0x20
 out dx, al
 mov edx, 0xA1
 mov al, 0x28
 out dx, al
 mov edx, 0x21
 mov al, 0x00
 out dx, al
 mov edx, 0xA1
 mov al, 0x00
 out dx, al
 mov edx, 0x21
 mov al, 0x01
 out dx, al
 mov edx, 0xA1
 mov al, 0x01
 out dx, al
 mov edx, 0x21
 mov al, 0xff
 out dx, al
 mov edx, 0xA1
 mov al, 0xff
 out dx, al

 mov eax,irq0
 mov [idt+32*8],ax
 mov word [idt+32*8+2],0x08
 mov word [idt+32*8+4],0x8E00
 shr eax,16
 mov [idt+32*8+6],ax

 mov eax,irq1
 mov [idt+33*8],ax
 mov word [idt+33*8+2],0x08
 mov word [idt+33*8+4],0x8E00
 shr eax,16
 mov [idt+33*8+6],ax

 mov eax,irq7
 mov [idt+39*8],ax
 mov word [idt+39*8+2],0x08
 mov word [idt+39*8+4],0x8E00
 shr eax,16
 mov [idt+39*8+6],ax

 mov eax,irq8
 mov [idt+40*8],ax
 mov word [idt+40*8+2],0x08
 mov word [idt+40*8+4],0x8E00
 shr eax,16
 mov [idt+40*8+6],ax

 mov eax,irq15
 mov [idt+47*8],ax
 mov word [idt+47*8+2],0x08
 mov word [idt+47*8+4],0x8E00
 shr eax,16
 mov [idt+47*8+6],ax

 sti
 mov edx, 0x21
 mov al, 0xFD
 out dx, al

 call main

 hlt

jmp $
