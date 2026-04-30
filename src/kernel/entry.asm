bits 32
global _start
extern kernel_main
section .text
_start:
    mov esp, 0x00400000     
    mov ebp, esp
    cld
    call kernel_main
.hang:
    cli
    hlt
    jmp .hang
