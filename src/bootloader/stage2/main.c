#include "stdio.h"
#include "stdint.h"
#include "memory.h"
#include "gdt.h"
#include "a20.h"

void _cdecl cstart_(uint16_t bootDrive) {
    clrscr();
    printf("Lum-OS Stage 2 Bootloader\n\n");

    printf("Step 1: Memory Detection...\n");
    detect_memory();
    print_memory_map();

    printf("\nStep 2: Enabling A20...\n");
    enable_a20();

    printf("Step 3: Setting up GDT...\n");
    setup_gdt();

    printf("\nStage 2 Complete! System Halted.\n");
    for(;;);
}
