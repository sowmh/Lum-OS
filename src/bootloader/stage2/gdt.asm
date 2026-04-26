; src/bootloader/stage2/gdt.asm
bits 16

section .text class=CODE

global _gdt_load

; void _cdecl gdt_load(const GDTDescriptor* desc)
_gdt_load:
    push bp
    mov bp, sp
    
    ; Get pointer to GDT descriptor
    mov bx, [bp + 4]    ; Offset of descriptor struct
    
    ; Load GDT
    lgdt [bx]
    
    pop bp
    ret
