#include "stdio.h"
#include "stdint.h"

// Enlaza con la función de x86.asm que usa la BIOS
extern void _cdecl x86_Video_WriteCharTeletype(char c, uint8_t page);

void _cdecl putc(char c) {
    if (c == '\n') {
        x86_Video_WriteCharTeletype('\r', 0);
        x86_Video_WriteCharTeletype('\n', 0);
    } else {
        x86_Video_WriteCharTeletype(c, 0);
    }
}

void _cdecl puts(const char* str) {
    while (*str) {
        putc(*str++);
    }
}

// Auxiliar para imprimir números en hexadecimal
static void print_hex(uint32_t num) {
    char* hex_chars = "0123456789ABCDEF";
    putc('0'); putc('x');
    for (int i = 7; i >= 0; i--) {
        putc(hex_chars[(num >> (i * 4)) & 0xF]);
    }
}

void _cdecl printf(const char* fmt, ...) {
    uint16_t* args = (uint16_t*)&fmt + 1; // Puntero a argumentos en el stack
    while (*fmt) {
        if (*fmt == '%' && *(fmt + 1)) {
            fmt++;
            switch (*fmt) {
                case 's': puts(*(char**)args); args += 2; break;
                case 'x': print_hex(*(uint32_t*)args); args += 2; break;
                case 'd': /* implementar print_dec si es necesario */ break;
            }
        } else {
            putc(*fmt);
        }
        fmt++;
    }
}
