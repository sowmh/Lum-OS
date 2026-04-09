#include "gdt.h"
#include "stdint.h"

typedef struct {
    uint16_t limit;
    uint16_t base_low;
    uint8_t  base_mid;
    uint8_t  access;
    uint8_t  flags;
    uint8_t  base_high;
} __attribute__((packed)) GDTEntry;

typedef struct {
    uint16_t limit;
    uint32_t base;
} __attribute__((packed)) GDTDescriptor;

static GDTEntry g_gdt[3] __attribute__((aligned(8)));
static GDTDescriptor g_gdt_desc;

extern void _cdecl gdt_load(GDTDescriptor* descriptor);

void _cdecl setup_gdt() {
    // Null Descriptor
    g_gdt[0] = (GDTEntry){0, 0, 0, 0, 0, 0};
    // Code Segment (0x08)
    g_gdt[1] = (GDTEntry){0xFFFF, 0, 0, 0x9A, 0xCF, 0};
    // Data Segment (0x10)
    g_gdt[2] = (GDTEntry){0xFFFF, 0, 0, 0x92, 0xCF, 0};

    g_gdt_desc.limit = sizeof(g_gdt) - 1;
    g_gdt_desc.base = (uint32_t)g_gdt; // Nota: Ajustar según segmento si es necesario

    gdt_load(&g_gdt_desc);
}
