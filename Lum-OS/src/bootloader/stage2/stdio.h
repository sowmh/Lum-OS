// src/bootloader/stage2/stdio.h
#pragma once

void _cdecl putc(char c);
void _cdecl puts(const char* str);
void _cdecl printf(const char* fmt, ...);
void _cdecl clrscr(void);
