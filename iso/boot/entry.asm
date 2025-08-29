[bits 32]
align 4

multiboot_header:
    dd 0x1BADB002
    dd 0x00000003
    dd -(0x1BADB002 + 0x00000003)

global _start
_start:
    cli
    xor eax, eax
    mov ds, eax
    mov es, eax
    mov fs, eax
    mov gs, eax
    mov ss, eax

    extern stack_space
    mov esp, stack_space

    mov edi, 0x000B8000
    mov ecx, 25
    mov edx, 80

    mov esi, msg
    mov eax, msg_len
    mov ebx, edx
    sub ebx, eax
    shr ebx, 1
    mov edi, edi
    mov esi, msg
    mov edi, edi
    add edi, (12*edx + ebx)*2

    call print_string

hang:
    jmp hang

print_string:
    cld
.next_char:
    lodsb
    test al, al
    jz .done
    mov [edi], al
    inc edi
    mov byte [edi], 0x1F
    inc edi
    jmp .next_char
.done:
    ret

msg db "Lum OS booted successfully!", 0
msg_len equ $-msg
