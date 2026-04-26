// src/bootloader/stage2/main.c
#include "stdint.h"
#include "stdio.h"
#include "memory.h"
#include "a20.h"
#include "gdt.h"
#include "disk.h"
#include "pmode.h"

#define KERNEL_LOAD_ADDRESS 0x10000  // Load kernel at 64KB

void _cdecl cstart_(uint16_t bootDrive)
{
    clrscr();
    
    puts("==========================================\n");
    puts("  Lum-OS Stage 2 Bootloader v1.0\n");
    puts("==========================================\n");
    printf("Boot drive: %x\n\n", bootDrive);
    
    // Step 1: Detect memory
    puts("Step 1: Detecting memory...\n");
    uint16_t mem_entries = detect_memory();
    
    if (mem_entries == 0) {
        puts("\nFATAL: No memory detected!\n");
        goto halt;
    }
    
    print_memory_map();
    
    uint32_t total_kb = get_total_memory_kb();
    uint32_t total_mb = total_kb / 1024;
    printf("\nTotal RAM: %d KB (%d MB)\n\n", total_kb, total_mb);
    
    // Step 2: Enable A20 line
    puts("Step 2: Enabling A20 line...\n");
    if (!enable_a20()) {
        puts("\nFATAL: Cannot access extended memory!\n");
        goto halt;
    }
    puts("\n");
    
    // Step 3: Setup GDT
    puts("Step 3: Setting up GDT...\n");
    setup_gdt();
    puts("\n");
    
    // Step 4: Load kernel from disk
    puts("Step 4: Loading kernel from disk...\n");
    if (!load_kernel(bootDrive, KERNEL_LOAD_ADDRESS)) {
        puts("\nFATAL: Failed to load kernel!\n");
        goto halt;
    }
    puts("\n");
    
    // Step 5: Enter protected mode and jump to kernel
    puts("Step 5: Entering protected mode...\n");
    puts("Jumping to kernel at 0x10000...\n\n");
    
    puts("==========================================\n");
    puts("  Switching to 32-bit Protected Mode...\n");
    puts("==========================================\n\n");
    
    // This function does not return
    enter_protected_mode(KERNEL_LOAD_ADDRESS);
    
    // Should never reach here
    puts("ERROR: Returned from protected mode!\n");
    
halt:
    puts("\nSystem halted. Press any key to reboot.\n");
    
    // Wait for keypress
    __asm {
        xor ax, ax
        int 0x16
    }
    
    // Reboot via far jump
    __asm {
        jmp 0xFFFF:0x0000
    }
}
