#include "stdint.h"

typedef struct {
    uint16_t limit_low;
    uint16_t base_low;
    uint8_t base_mid;
    uint8_t access;
    uint8_t granularity;
    uint8_t base_high;
} __attribute__((packed)) GDTEntry;

GDTEntry g_gdt[3]; // Null, Code, Data

void setup_gdt() {
    // Descriptor nulo
    // Segmento de Código (Base 0, Límite 4GB)
    g_gdt[1] = (GDTEntry){0xFFFF, 0, 0, 0x9A, 0xCF, 0};
    // Segmento de Datos (Base 0, Límite 4GB)
    g_gdt[2] = (GDTEntry){0xFFFF, 0, 0, 0x92, 0xCF, 0};
    
    // Aquí llamarías a LGDT en assembly
}
