; src/kernel/entry.asm
; 32-bit kernel entry point

bits 32

global _start
extern kernel_main

section .text
_start:
    ; Set up stack
    mov esp, 0x00400000     ; 4MB stack
    mov ebp, esp
    
    ; Clear direction flag
    cld
    
    ; Call kernel main
    call kernel_main
    
    ; If kernel_main returns, halt
.hang:
    cli
    hlt
    jmp .hang
