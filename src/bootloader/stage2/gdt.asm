bits 16
section .text class=CODE
global _gdt_load
_gdt_load:
    push bp
    mov bp, sp
    mov bx, [bp + 4]    
    lgdt [bx]
    pop bp
    ret
