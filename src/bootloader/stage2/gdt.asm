bits 16

section _TEXT class=CODE

global _gdt_load
_gdt_load:
    push bp
    mov bp, sp

    mov eax, [bp + 4]   ; Puntero a la GDT Descriptor
    lgdt [eax]          ; Carga la GDT

    mov sp, bp
    pop bp
    ret
