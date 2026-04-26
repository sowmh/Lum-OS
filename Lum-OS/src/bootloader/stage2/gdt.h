// src/bootloader/stage2/gdt.h
#pragma once

// GDT segment selectors
#define GDT_CODE_SEGMENT 0x08
#define GDT_DATA_SEGMENT 0x10

// Setup and load GDT
void _cdecl setup_gdt(void);
