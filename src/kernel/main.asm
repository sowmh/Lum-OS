org 0x0000
bits 16


%define ENDL 0x0D, 0x0A


start:
 jmp main


puts:
 push si
 push ax
 push bx


.loop:
 lodsb
 or al, al
 jz .done
 mov ah, 0x0e
 mov bh, 0
 int 0x10
 jmp .loop


.done:
 pop bx
 pop ax
 pop si
 ret


main:
 mov ax, 0
 mov ds, ax
 mov es, ax
 mov ss, ax
 mov sp, 0x7C00

 mov si, msg_hello
 call puts

 jmp .halt

.halt:
 hlt
 jmp .halt

msg_hello: db 'Hello Lum-OS!', ENDL, 0

times 510 - ($ - $$) db 0
dw 0xAA55