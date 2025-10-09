BITS 16
SECTION _ENTRY CLASS=CODE

extern _cstart_
global entry

entry:
    cli
    mov  ax, ds
    mov  ss, ax
    mov  sp, 0x7C00
    mov  bp, sp
    sti

    xor  dh, dh
    push dx
    call _cstart_

    cli
    hlt
