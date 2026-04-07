; src/bootloader/stage2/x86.asm
bits 16

section .text class=CODE

; void _cdecl x86_Video_WriteCharTeletype(char c, uint8_t page)
global _x86_Video_WriteCharTeletype
_x86_Video_WriteCharTeletype:
    push bp
    mov bp, sp
    push bx

    mov al, [bp + 4]    ; c
    mov bh, [bp + 6]    ; page
    mov ah, 0x0E
    int 0x10

    pop bx
    pop bp
    ret

; void _cdecl x86_Video_SetMode(uint8_t mode)
global _x86_Video_SetMode
_x86_Video_SetMode:
    push bp
    mov bp, sp
    
    mov al, [bp + 4]    ; mode
    mov ah, 0x00
    int 0x10
    
    pop bp
    ret

; void _cdecl x86_Outb(uint16_t port, uint8_t value)
global _x86_Outb
_x86_Outb:
    push bp
    mov bp, sp
    mov dx, [bp + 4]    ; port
    mov al, [bp + 6]    ; value
    out dx, al
    pop bp
    ret

; uint8_t _cdecl x86_Inb(uint16_t port)
global _x86_Inb
_x86_Inb:
    push bp
    mov bp, sp
    mov dx, [bp + 4]    ; port
    in al, dx
    pop bp
    ret
