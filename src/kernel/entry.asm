bits 32
global _start
extern __bss_start
extern __bss_end
extern kernel_bootstrap
extern kernel_main
section .text
_start:
    mov esp, 0x0009FC00
    mov ebp, esp
    cld
    mov edi, __bss_start
    mov ecx, __bss_end
    sub ecx, edi
    xor eax, eax
    rep stosb
    call kernel_bootstrap
    call kernel_main
.hang:
    cli
    hlt
    jmp .hang
