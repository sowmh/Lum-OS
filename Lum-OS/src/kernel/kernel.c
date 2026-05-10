// src/kernel/kernel.c
// 32-bit Protected Mode Kernel

#include <stdint.h>
#include "desktop.h"
#include "wm.h"
#include "kernel_globals.h"

// Global variables
uint32_t pit_ticks = 0;
uint32_t uptime_seconds = 0;

// Kernel entry point
void kernel_main() {
    // Initialize desktop UI
    desktop_init();
    
    // Initialize window manager
    wm_init();
    
    // Open shell window
    wm_open(WIN_SHELL);
    
    // TODO: Initialize subsystems (IDT, PIC, PIT, etc.)
    // TODO: shell_run();
    
    // For now, just halt
    while (1) {
        __asm__ volatile("hlt");
    }
}
