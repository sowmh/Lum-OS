#include "memory.h"
#include "stdio.h"
#include "stdint.h"

#define E820_SIGNATURE 0x534D4150

E820Entry g_memory_map[32];
uint8_t g_entry_count = 0;

void _cdecl detect_memory() {
    uint32_t continuation = 0;
    uint32_t signature;
    uint32_t bytes_read;
    
    g_entry_count = 0;

    for (int i = 0; i < 32; i++) {
        E820Entry* entry = &g_memory_map[i];
        uint16_t error = 0;

        __asm {
            mov eax, 0xE820
            mov ebx, [continuation]
            mov ecx, 24
            mov edx, E820_SIGNATURE
            mov di, [entry]
            int 0x15
            jc error_label     // Si hay Carry Flag, terminó o hubo error
            mov [continuation], ebx
            mov [signature], eax
            mov [bytes_read], ecx
            jmp success_label
        error_label:
            mov error, 1
        success_label:
        }

        if (error || signature != E820_SIGNATURE) break;

        g_entry_count++;
        if (continuation == 0) break;
    }
}

void print_memory_map() {
    printf("Base Area          Length             Type\n");
    for (int i = 0; i < g_entry_count; i++) {
        printf("%p  %p  %d\n", (uint32_t)g_memory_map[i].base_low, (uint32_t)g_memory_map[i].length_low, (uint32_t)g_memory_map[i].type);
    }
}
