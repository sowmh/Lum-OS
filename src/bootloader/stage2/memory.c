// src/bootloader/stage2/memory.c
#include "memory.h"
#include "stdio.h"

// Memory map buffer (aligned for BIOS compatibility)
static E820Entry g_memory_map[32] __attribute__((aligned(16)));
static uint16_t g_entry_count = 0;

uint16_t _cdecl detect_memory(void) {
    uint32_t continuation = 0;
    uint16_t error_flag;
    
    puts("Detecting memory (INT 15h, E820)...\n");
    
    do {
        E820Entry* current = &g_memory_map[g_entry_count];
        
        __asm {
            push di
            push es
            
            mov eax, 0xE820
            mov ebx, continuation
            mov ecx, 24              // Buffer size
            mov edx, 0x534D4150      // 'SMAP' signature
            mov di, current          // ES:DI = buffer
            
            int 0x15
            
            // Check carry flag (error indicator)
            jc error_detected
            
            // Verify signature
            cmp eax, 0x534D4150
            jne error_detected
            
            // Success
            mov continuation, ebx
            mov error_flag, 0
            jmp done
            
        error_detected:
            mov continuation, 0
            mov error_flag, 1
            
        done:
            pop es
            pop di
        }
        
        // Stop if error and we have no entries
        if (error_flag) {
            if (g_entry_count == 0) {
                puts("ERROR: BIOS does not support E820!\n");
            }
            break;
        }
        
        // Add valid entry
        if (current->length > 0) {
            g_entry_count++;
            
            if (g_entry_count >= 32) {
                puts("WARNING: Too many regions (max 32)\n");
                break;
            }
        }
        
    } while (continuation != 0);
    
    printf("Found %d memory regions\n", g_entry_count);
    return g_entry_count;
}

void _cdecl print_memory_map(void) {
    const char* type_names[] = {
        "Unknown ",
        "Usable  ",
        "Reserved",
        "ACPI Rec",
        "ACPI NVS",
        "Bad Mem "
    };
    
    puts("\n--- Memory Map ---\n");
    puts("Base              Length            Type\n");
    puts("--------------------------------------------------\n");
    
    for (uint16_t i = 0; i < g_entry_count; i++) {
        E820Entry* e = &g_memory_map[i];
        
        // Print base address (lower 32 bits)
        printf("%p", (uint32_t)(e->base & 0xFFFFFFFF));
        puts("  ");
        
        // Print length (lower 32 bits)
        printf("%p", (uint32_t)(e->length & 0xFFFFFFFF));
        puts("  ");
        
        // Print type
        if (e->type <= 5) {
            puts(type_names[e->type]);
        } else {
            puts("Unknown");
        }
        putc('\n');
    }
    puts("--------------------------------------------------\n");
}

uint32_t _cdecl get_total_memory_kb(void) {
    uint32_t total_kb = 0;
    
    for (uint16_t i = 0; i < g_entry_count; i++) {
        if (g_memory_map[i].type == MEMORY_TYPE_USABLE) {
            uint32_t region_bytes = (uint32_t)(g_memory_map[i].length & 0xFFFFFFFF);
            total_kb += region_bytes / 1024;
        }
    }
    
    return total_kb;
}

const E820Entry* _cdecl get_memory_map(void) {
    return g_memory_map;
}

uint16_t _cdecl get_memory_map_count(void) {
    return g_entry_count;
}
