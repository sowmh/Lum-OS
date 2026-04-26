// src/bootloader/stage2/memory.h
#pragma once
#include "stdint.h"

// E820 Memory Map Entry Structure
typedef struct {
    uint64_t base;      // Base address
    uint64_t length;    // Length in bytes
    uint32_t type;      // Memory type
    uint32_t acpi;      // ACPI 3.0 attributes
} __attribute__((packed)) E820Entry;

// Memory types
#define MEMORY_TYPE_USABLE          1
#define MEMORY_TYPE_RESERVED        2
#define MEMORY_TYPE_ACPI_RECLAIM    3
#define MEMORY_TYPE_ACPI_NVS        4
#define MEMORY_TYPE_BAD             5

// Function declarations
uint16_t _cdecl detect_memory(void);
void _cdecl print_memory_map(void);
uint32_t _cdecl get_total_memory_kb(void);
const E820Entry* _cdecl get_memory_map(void);
uint16_t _cdecl get_memory_map_count(void);
