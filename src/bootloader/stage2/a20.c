// src/bootloader/stage2/a20.c
#include "a20.h"
#include "stdio.h"
#include "x86.h"

// Test if A20 line is enabled
uint8_t _cdecl test_a20(void) {
    uint16_t result;
    
    __asm {
        push ds
        push es
        push di
        push si
        
        // Write 0x00 to 0x0000:0x0500
        xor ax, ax
        mov ds, ax
        mov si, 0x0500
        mov byte ptr [si], 0x00
        
        // Write 0xFF to 0xFFFF:0x0510 
        // If A20 disabled, wraps to 0x00500
        mov ax, 0xFFFF
        mov es, ax
        mov di, 0x0510
        mov byte ptr es:[di], 0xFF
        
        // Read from 0x0000:0x0500
        xor ax, ax
        mov ds, ax
        mov al, byte ptr [si]
        
        // If we read 0xFF, A20 is disabled (wrapped)
        cmp al, 0xFF
        je a20_disabled
        
        // A20 is enabled
        mov result, 1
        jmp done
        
    a20_disabled:
        mov result, 0
        
    done:
        pop si
        pop di
        pop es
        pop ds
    }
    
    return result;
}

// Enable A20 via BIOS
static uint8_t enable_a20_bios(void) {
    uint16_t result;
    
    __asm {
        mov ax, 0x2401      // Enable A20
        int 0x15
        jc failed
        
        mov result, 1
        jmp done
    failed:
        mov result, 0
    done:
    }
    
    return result;
}

// Enable A20 via keyboard controller
static void enable_a20_keyboard(void) {
    __asm {
        cli
        
        // Wait for input buffer empty
    wait1:
        in al, 0x64
        test al, 0x02
        jnz wait1
        
        // Read output port command
        mov al, 0xD0
        out 0x64, al
        
        // Wait for output buffer full
    wait2:
        in al, 0x64
        test al, 0x01
        jz wait2
        
        // Read output port value
        in al, 0x60
        push ax
        
        // Wait for input buffer empty
    wait3:
        in al, 0x64
        test al, 0x02
        jnz wait3
        
        // Write output port command
        mov al, 0xD1
        out 0x64, al
        
        // Wait for input buffer empty
    wait4:
        in al, 0x64
        test al, 0x02
        jnz wait4
        
        // Write value with A20 enabled
        pop ax
        or al, 0x02         // Set A20 bit
        out 0x60, al
        
        // Wait for completion
    wait5:
        in al, 0x64
        test al, 0x02
        jnz wait5
        
        sti
    }
}

// Enable A20 via Fast A20
static void enable_a20_fast(void) {
    uint8_t val = x86_Inb(0x92);
    val |= 0x02;     // Set A20 bit
    val &= 0xFE;     // Don't trigger reset!
    x86_Outb(0x92, val);
}

// Delay for hardware
static void a20_delay(void) {
    for (volatile uint16_t i = 0; i < 10000; i++);
}

uint8_t _cdecl enable_a20(void) {
    // Already enabled?
    if (test_a20()) {
        puts("A20 line already enabled\n");
        return 1;
    }
    
    puts("Enabling A20 line...\n");
    
    // Method 1: BIOS
    puts("  Trying BIOS method...\n");
    if (enable_a20_bios()) {
        a20_delay();
        if (test_a20()) {
            puts("  Success (BIOS)\n");
            return 1;
        }
    }
    
    // Method 2: Keyboard controller
    puts("  Trying keyboard controller...\n");
    enable_a20_keyboard();
    a20_delay();
    if (test_a20()) {
        puts("  Success (keyboard)\n");
        return 1;
    }
    
    // Method 3: Fast A20
    puts("  Trying Fast A20...\n");
    enable_a20_fast();
    a20_delay();
    if (test_a20()) {
        puts("  Success (Fast A20)\n");
        return 1;
    }
    
    puts("  ERROR: Failed to enable A20!\n");
    return 0;
}
