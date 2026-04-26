; src/bootloader/stage2/crt0.asm
BITS 16

section _ENTRY class=CODE

extern _cstart_
global entry

entry:
    cli                         ; Desactiva interrupciones durante el setup
    
    ; Stage 2 cargado en 0x2000:0x0000
    mov ax, 0x2000
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    ; Setup del Stack (0x2000:0xFFF0) - Lejos del Stage 1 (0x7C00)
    mov ss, ax
    mov sp, 0xFFF0
    mov bp, sp
    
    sti                         ; Reactiva interrupciones
    
    ; Pasar el drive de booteo (DL) a la función C
    xor dh, dh
    push dx
    
    call _cstart_               ; Salto al main.c
    
.hang:
    cli
    hlt
    jmp .hang
