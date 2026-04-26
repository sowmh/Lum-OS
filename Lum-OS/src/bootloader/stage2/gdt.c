// src/bootloader/stage2/gdt.c
#include "gdt.h"
#include "stdio.h"
#include "stdint.h"

typedef struct {
    uint16_t limit_low;
    uint16_t base_low;
    uint8_t base_mid;
    uint8_t access;
    uint8_t granularity;
    uint8_t base_high;
} __attribute__((packed)) GDTEntry;

typedef struct {
    uint16_t size;
    uint32_t offset;
} __attribute__((packed)) GDTDescriptor;

// GDT must be aligned to 8 bytes
static GDTEntry g_gdt[3] __attribute__((aligned(8)));
static GDTDescriptor g_gdt_desc;

// External assembly function
extern void _cdecl gdt_load(const GDTDescriptor* desc);

void _cdecl setup_gdt(void) {
    puts("Setting up GDT...\n");
    
    // Entry 0: Null descriptor (required by CPU)
    g_gdt[0].limit_low = 0;
    g_gdt[0].base_low = 0;
    g_gdt[0].base_mid = 0;
    g_gdt[0].access = 0;
    g_gdt[0].granularity = 0;
    g_gdt[0].base_high = 0;
    
    // Entry 1: Code segment (0x08)
    // Base: 0, Limit: 0xFFFFF (4GB with granularity)
    // Access: Present, Ring 0, Code, Executable, Readable
    g_gdt[1].limit_low = 0xFFFF;
    g_gdt[1].base_low = 0;
    g_gdt[1].base_mid = 0;
    g_gdt[1].access = 0x9A;      // 1001 1010
    g_gdt[1].granularity = 0xCF;  // 1100 1111 (4K blocks, 32-bit)
    g_gdt[1].base_high = 0;
    
    // Entry 2: Data segment (0x10)
    // Base: 0, Limit: 0xFFFFF (4GB with granularity)
    // Access: Present, Ring 0, Data, Writable
    g_gdt[2].limit_low = 0xFFFF;
    g_gdt[2].base_low = 0;
    g_gdt[2].base_mid = 0;
    g_gdt[2].access = 0x92;      // 1001 0010
    g_gdt[2].granularity = 0xCF;  // 1100 1111
    g_gdt[2].base_high = 0;
    
    // Setup descriptor
    g_gdt_desc.size = sizeof(g_gdt) - 1;
    
    // Calculate linear address of GDT
    uint16_t segment;
    uint16_t offset = (uint16_t)&g_gdt;
    __asm {
        mov ax, ds
        mov segment, ax
    }
    g_gdt_desc.offset = ((uint32_t)segment << 4) + offset;
    
    printf("GDT at: %p\n", g_gdt_desc.offset);
    
    // Load GDT
    gdt_load(&g_gdt_desc);
    
    puts("GDT loaded successfully\n");
}
