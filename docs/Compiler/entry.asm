; entry.asm 
; NASM x86-64

section .text
global _start

_start:
    mov rax, 60     ; syscall número 60 = exit
    xor rdi, rdi    ; código de salida 0
    syscall
