[bits 32]
[section .text]
[global _start]


_start:
; Set up the stack
cli 
xor ebp, ebp
mov esp, stack_top 


; Call kernel main
call kmain


; Halt CPU when kernel returns
.halt:
hlt
jmp .halt


[section .bss]
stack_space: resb 4096 
[section .data]
stack_top: equ stack_space + 4096