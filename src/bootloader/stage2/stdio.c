// src/bootloader/stage2/stdio.c
#include "stdio.h"
#include "stdint.h"
#include "x86.h"

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
        putc(*str);
        str++;
    }
}

void _cdecl clrscr(void) {
    x86_Video_SetMode(0x03); // 80x25 text mode
}

// Helper functions
static char hex_digit(uint8_t val) {
    return val < 10 ? '0' + val : 'A' + (val - 10);
}

static void print_hex16(uint16_t num) {
    putc('0'); putc('x');
    for (int i = 3; i >= 0; i--) {
        putc(hex_digit((num >> (i * 4)) & 0xF));
    }
}

static void print_hex32(uint32_t num) {
    putc('0'); putc('x');
    for (int i = 7; i >= 0; i--) {
        putc(hex_digit((num >> (i * 4)) & 0xF));
    }
}

static void print_dec(uint32_t num) {
    char buf[12];
    int i = 0;
    
    if (num == 0) {
        putc('0');
        return;
    }
    
    while (num > 0) {
        buf[i++] = '0' + (num % 10);
        num /= 10;
    }
    
    while (i > 0) {
        putc(buf[--i]);
    }
}

void _cdecl printf(const char* fmt, ...) {
    uint16_t* args = (uint16_t*)&fmt;
    args++; // Skip format string pointer
    
    while (*fmt) {
        if (*fmt == '%' && *(fmt + 1)) {
            fmt++;
            switch (*fmt) {
                case 's': {
                    const char* str = (const char*)(*args);
                    args++;
                    if (str) puts(str);
                    break;
                }
                case 'c': {
                    char c = (char)(*args);
                    args++;
                    putc(c);
                    break;
                }
                case 'd': {
                    uint16_t num = *args;
                    args++;
                    print_dec(num);
                    break;
                }
                case 'x': {
                    uint16_t num = *args;
                    args++;
                    print_hex16(num);
                    break;
                }
                case 'p': {
                    uint32_t ptr = *(uint32_t*)args;
                    args += 2;
                    print_hex32(ptr);
                    break;
                }
                case '%': {
                    putc('%');
                    break;
                }
            }
        } else {
            putc(*fmt);
        }
        fmt++;
    }
}
