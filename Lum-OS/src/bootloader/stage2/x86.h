// src/bootloader/stage2/x86.h
#pragma once
#include "stdint.h"

// Video functions
void _cdecl x86_Video_WriteCharTeletype(char c, uint8_t page);
void _cdecl x86_Video_SetMode(uint8_t mode);

// I/O port functions
void _cdecl x86_Outb(uint16_t port, uint8_t value);
uint8_t _cdecl x86_Inb(uint16_t port);
