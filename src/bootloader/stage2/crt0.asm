BITS 16
section _ENTRY class=CODE
extern _cstart_
global entry
entry:
    cli                         
    mov ax, 0x2000
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov sp, 0xFFF0
    mov bp, sp
    sti                         
    xor dh, dh
    push dx
    call _cstart_               
.hang:
    cli
    hlt
    jmp .hang
