bits 16
section .text class=CODE
global _x86_Video_WriteCharTeletype
_x86_Video_WriteCharTeletype:
    push bp
    mov bp, sp
    push bx
    mov al, [bp + 4]    
    mov bh, [bp + 6]    
    mov ah, 0x0E
    int 0x10
    pop bx
    pop bp
    ret
global _x86_Video_SetMode
_x86_Video_SetMode:
    push bp
    mov bp, sp
    mov al, [bp + 4]    
    mov ah, 0x00
    int 0x10
    pop bp
    ret
global _x86_Outb
_x86_Outb:
    push bp
    mov bp, sp
    mov dx, [bp + 4]    
    mov al, [bp + 6]    
    out dx, al
    pop bp
    ret
global _x86_Inb
_x86_Inb:
    push bp
    mov bp, sp
    mov dx, [bp + 4]    
    in al, dx
    pop bp
    ret
