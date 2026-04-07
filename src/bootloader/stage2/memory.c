#include "memory.h"
#include "stdio.h"

static E820Entry g_memory_map[32];
static uint16_t g_entry_count = 0;

uint16_t _cdecl detect_memory() {
    uint32_t continuation = 0;
    uint32_t signature;
    uint32_t bytes_read;
    
    do {
        E820Entry* current = &g_memory_map[g_entry_count];
        __asm {
            mov eax, 0xE820
            mov ebx, continuation
            mov ecx, 24             ; Tamaño del buffer esperado
            mov edx, 0x534D4150     ; 'SMAP'
            mov di, current
            int 0x15
            mov continuation, ebx
            mov signature, eax
            mov bytes_read, ecx
        }
        
        if (signature != 0x534D4150) break;
        g_entry_count++;
        
    } while (continuation != 0 && g_entry_count < 32);
    
    return g_entry_count;
}
