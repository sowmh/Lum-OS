// src/kernel/kernel.c
// 32-bit Protected Mode Kernel

#include <stdint.h>

// VGA text mode buffer
#define VGA_MEMORY 0xB8000
#define VGA_WIDTH 80
#define VGA_HEIGHT 25

// Colors
#define COLOR_BLACK 0
#define COLOR_BLUE 1
#define COLOR_GREEN 2
#define COLOR_CYAN 3
#define COLOR_RED 4
#define COLOR_MAGENTA 5
#define COLOR_BROWN 6
#define COLOR_LIGHT_GRAY 7
#define COLOR_DARK_GRAY 8
#define COLOR_LIGHT_BLUE 9
#define COLOR_LIGHT_GREEN 10
#define COLOR_LIGHT_CYAN 11
#define COLOR_LIGHT_RED 12
#define COLOR_LIGHT_MAGENTA 13
#define COLOR_YELLOW 14
#define COLOR_WHITE 15

typedef struct {
    uint8_t character;
    uint8_t color;
} __attribute__((packed)) vga_char;

static vga_char* vga_buffer = (vga_char*)VGA_MEMORY;
static uint32_t cursor_x = 0;
static uint32_t cursor_y = 0;
static uint8_t current_color = (COLOR_WHITE << 4) | COLOR_BLACK;

void clear_screen() {
    for (uint32_t y = 0; y < VGA_HEIGHT; y++) {
        for (uint32_t x = 0; x < VGA_WIDTH; x++) {
            uint32_t index = y * VGA_WIDTH + x;
            vga_buffer[index].character = ' ';
            vga_buffer[index].color = current_color;
        }
    }
    cursor_x = 0;
    cursor_y = 0;
}

void set_color(uint8_t fg, uint8_t bg) {
    current_color = (bg << 4) | fg;
}

void putchar(char c) {
    if (c == '\n') {
        cursor_x = 0;
        cursor_y++;
    } else {
        uint32_t index = cursor_y * VGA_WIDTH + cursor_x;
        vga_buffer[index].character = c;
        vga_buffer[index].color = current_color;
        cursor_x++;
        
        if (cursor_x >= VGA_WIDTH) {
            cursor_x = 0;
            cursor_y++;
        }
    }
    
    if (cursor_y >= VGA_HEIGHT) {
        // Scroll screen
        for (uint32_t y = 0; y < VGA_HEIGHT - 1; y++) {
            for (uint32_t x = 0; x < VGA_WIDTH; x++) {
                uint32_t dst = y * VGA_WIDTH + x;
                uint32_t src = (y + 1) * VGA_WIDTH + x;
                vga_buffer[dst] = vga_buffer[src];
            }
        }
        
        // Clear last line
        for (uint32_t x = 0; x < VGA_WIDTH; x++) {
            uint32_t index = (VGA_HEIGHT - 1) * VGA_WIDTH + x;
            vga_buffer[index].character = ' ';
            vga_buffer[index].color = current_color;
        }
        
        cursor_y = VGA_HEIGHT - 1;
    }
}

void print(const char* str) {
    while (*str) {
        putchar(*str);
        str++;
    }
}

void print_hex(uint32_t num) {
    char hex[] = "0123456789ABCDEF";
    print("0x");
    for (int i = 7; i >= 0; i--) {
        putchar(hex[(num >> (i * 4)) & 0xF]);
    }
}

// Kernel entry point
void kernel_main() {
    clear_screen();
    
    // Print banner with colors
    set_color(COLOR_YELLOW, COLOR_BLUE);
    print("================================================================================");
    putchar('\n');
    set_color(COLOR_WHITE, COLOR_BLUE);
    print("                        LUM-OS KERNEL v0.1 (32-bit)                           ");
    putchar('\n');
    set_color(COLOR_YELLOW, COLOR_BLUE);
    print("================================================================================");
    putchar('\n');
    putchar('\n');
    
    set_color(COLOR_LIGHT_GREEN, COLOR_BLACK);
    print("[OK] Protected mode enabled\n");
    print("[OK] Kernel loaded successfully\n");
    print("[OK] VGA text mode initialized\n\n");
    
    set_color(COLOR_LIGHT_CYAN, COLOR_BLACK);
    print("System Information:\n");
    set_color(COLOR_WHITE, COLOR_BLACK);
    print("  - Architecture: x86 (32-bit)\n");
    print("  - Boot mode: Legacy BIOS\n");
    print("  - Display: VGA Text Mode (80x25)\n\n");
    
    set_color(COLOR_LIGHT_MAGENTA, COLOR_BLACK);
    print("Memory Layout:\n");
    set_color(COLOR_WHITE, COLOR_BLACK);
    print("  - Kernel base: ");
    print_hex(0x10000);
    putchar('\n');
    print("  - VGA buffer:  ");
    print_hex(VGA_MEMORY);
    putchar('\n');
    print("  - Stack:       ");
    print_hex(0x400000);
    putchar('\n');
    putchar('\n');
    
    set_color(COLOR_YELLOW, COLOR_BLACK);
    print("Welcome to Lum-OS!\n\n");
    
    set_color(COLOR_LIGHT_GRAY, COLOR_BLACK);
    print("This is a minimal 32-bit operating system kernel.\n");
    print("The bootloader has successfully:\n");
    print("  1. Loaded from disk\n");
    print("  2. Detected memory (E820)\n");
    print("  3. Enabled A20 line\n");
    print("  4. Set up GDT\n");
    print("  5. Switched to protected mode\n");
    print("  6. Jumped to kernel\n\n");
    
    set_color(COLOR_LIGHT_RED, COLOR_BLACK);
    print("System halted. No further functionality implemented yet.\n");
    
    // Halt CPU
    while (1) {
        __asm__ volatile("hlt");
    }
}
