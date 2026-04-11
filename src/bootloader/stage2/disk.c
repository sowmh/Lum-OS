// src/bootloader/stage2/disk.c
#include "disk.h"
#include "stdio.h"

// Read sectors from disk using BIOS INT 13h
// Returns: 1 on success, 0 on failure
static uint8_t read_sectors(uint8_t drive, uint8_t start_sector, 
                            uint8_t sector_count, uint16_t segment, 
                            uint16_t offset) {
    uint16_t error_flag;
    uint8_t attempts = 3;
    
    while (attempts > 0) {
        __asm {
            push es
            
            mov ah, 0x02            ; Read sectors function
            mov al, sector_count    ; Number of sectors to read
            mov ch, 0               ; Cylinder 0
            mov cl, start_sector    ; Starting sector
            mov dh, 0               ; Head 0
            mov dl, drive           ; Drive number
            
            mov bx, segment
            mov es, bx
            mov bx, offset          ; ES:BX = buffer
            
            int 0x13                ; BIOS disk interrupt
            
            jc read_error
            
            ; Success
            mov error_flag, 0
            jmp read_done
            
        read_error:
            mov error_flag, 1
            
        read_done:
            pop es
        }
        
        if (error_flag == 0) {
            return 1; // Success
        }
        
        // Reset disk on error
        __asm {
            mov ah, 0x00
            mov dl, drive
            int 0x13
        }
        
        attempts--;
    }
    
    return 0; // Failed after 3 attempts
}

uint8_t _cdecl load_kernel(uint8_t drive, uint32_t load_address) {
    puts("Loading kernel.bin from disk...\n");
    
    // Kernel is stored after Stage 1 (sector 1) and Stage 2
    // Let's assume kernel starts at sector 10 and is max 64KB (128 sectors)
    uint8_t kernel_start_sector = 10;
    uint8_t sectors_to_read = 128;  // 64KB (128 sectors * 512 bytes)
    
    // Calculate segment:offset from linear address
    // For load_address = 0x100000 (1MB), we need to load in chunks
    // since we're in real mode (can only address 1MB)
    
    // For now, load to 0x10000 (64KB) temporarily
    uint16_t temp_segment = 0x1000;
    uint16_t temp_offset = 0x0000;
    
    printf("Reading %d sectors from sector %d\n", sectors_to_read, kernel_start_sector);
    printf("Loading to %x:%x\n", temp_segment, temp_offset);
    
    // Read kernel in chunks (BIOS can only read ~64KB at a time)
    uint8_t sectors_per_chunk = 64;  // 32KB per chunk
    uint8_t chunks = sectors_to_read / sectors_per_chunk;
    
    for (uint8_t i = 0; i < chunks; i++) {
        uint8_t current_sector = kernel_start_sector + (i * sectors_per_chunk);
        uint16_t current_segment = temp_segment + (i * 0x800); // Each chunk is 32KB = 0x8000 bytes
        
        if (!read_sectors(drive, current_sector, sectors_per_chunk, 
                         current_segment, 0)) {
            printf("ERROR: Failed to read chunk %d\n", i);
            return 0;
        }
        
        putc('.');  // Progress indicator
    }
    
    puts("\nKernel loaded successfully\n");
    return 1;
}
