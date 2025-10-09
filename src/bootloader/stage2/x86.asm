bits 16

section .text class=CODE
global _x86_Video_WriteCharTeletype

_x86_Video_WriteCharTeletype:
    push bp
    mov bp, sp

    mov ah, 0Eh       
    mov al, [bp + 4]   
    mov bh, [bp + 6]   

    int 10h

    pop bp
    ret
