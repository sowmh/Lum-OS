bits 16
section .text class=CODE
global _enter_protected_mode
_enter_protected_mode:
    push bp
    mov bp, sp
    mov eax, [bp + 4]       
    cli
    in al, 0x92
    or al, 2
    out 0x92, al
    mov ebx, cr0
    or ebx, 1
    mov cr0, ebx
    jmp 0x08:protected_mode_entry
bits 32
protected_mode_entry:
    mov bx, 0x10            
    mov ds, bx
    mov es, bx
    mov fs, bx
    mov gs, bx
    mov ss, bx
    mov esp, 0x00400000
    jmp eax
hang:
    hlt
    jmp hang
