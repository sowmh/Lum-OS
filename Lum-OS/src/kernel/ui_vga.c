#include "ui_vga.h"

void vga_clear(uint8_t attr) {
    uint16_t val = (attr << 8) | ' ';
    for (int i = 0; i < VGA_COLS * VGA_ROWS; i++) {
        VGA_MEMORY[i] = val;
    }
}

void vga_put_char(int row, int col, char c, uint8_t attr) {
    if (row < 0 || row >= VGA_ROWS || col < 0 || col >= VGA_COLS) return;
    uint16_t val = (attr << 8) | c;
    VGA_MEMORY[row * VGA_COLS + col] = val;
}

void vga_put_str(int row, int col, const char *s, uint8_t attr) {
    while (*s) {
        vga_put_char(row, col++, *s++, attr);
        if (col >= VGA_COLS) {
            col = 0;
            row++;
            if (row >= VGA_ROWS) break;
        }
    }
}

void vga_fill_rect(int row, int col, int h, int w, char c, uint8_t attr) {
    for (int r = row; r < row + h && r < VGA_ROWS; r++) {
        for (int c_ = col; c_ < col + w && c_ < VGA_COLS; c_++) {
            vga_put_char(r, c_, c, attr);
        }
    }
}

void vga_draw_hline(int row, int col, int len, uint8_t attr) {
    for (int i = 0; i < len; i++) {
        vga_put_char(row, col + i, 0xC4, attr); // ─
    }
}

void vga_draw_vline(int row, int col, int len, uint8_t attr) {
    for (int i = 0; i < len; i++) {
        vga_put_char(row + i, col, 0xB3, attr); // │
    }
}

void vga_draw_box(int row, int col, int h, int w, uint8_t attr) {
    // Top
    vga_put_char(row, col, 0xDA, attr); // ┌
    for (int i = 1; i < w - 1; i++) {
        vga_put_char(row, col + i, 0xC4, attr); // ─
    }
    vga_put_char(row, col + w - 1, 0xBF, attr); // ┐

    // Sides
    for (int i = 1; i < h - 1; i++) {
        vga_put_char(row + i, col, 0xB3, attr); // │
        vga_put_char(row + i, col + w - 1, 0xB3, attr); // │
    }

    // Bottom
    vga_put_char(row + h - 1, col, 0xC0, attr); // └
    for (int i = 1; i < w - 1; i++) {
        vga_put_char(row + h - 1, col + i, 0xC4, attr); // ─
    }
    vga_put_char(row + h - 1, col + w - 1, 0xD9, attr); // ┘
}

void vga_draw_box_double(int row, int col, int h, int w, uint8_t attr) {
    // Top
    vga_put_char(row, col, 0xC9, attr); // ╔
    for (int i = 1; i < w - 1; i++) {
        vga_put_char(row, col + i, 0xCD, attr); // ═
    }
    vga_put_char(row, col + w - 1, 0xBB, attr); // ╗

    // Sides
    for (int i = 1; i < h - 1; i++) {
        vga_put_char(row + i, col, 0xBA, attr); // ║
        vga_put_char(row + i, col + w - 1, 0xBA, attr); // ║
    }

    // Bottom
    vga_put_char(row + h - 1, col, 0xC8, attr); // ╚
    for (int i = 1; i < w - 1; i++) {
        vga_put_char(row + h - 1, col + i, 0xCD, attr); // ═
    }
    vga_put_char(row + h - 1, col + w - 1, 0xBC, attr); // ╝
}

void vga_move_cursor(int row, int col) {
    uint16_t pos = row * VGA_COLS + col;
    __asm__ volatile (
        "mov $0x3D4, %%dx\n"
        "mov $0x0F, %%al\n"
        "out %%al, %%dx\n"
        "inc %%dx\n"
        "mov %0, %%al\n"
        "out %%al, %%dx\n"
        "dec %%dx\n"
        "mov $0x0E, %%al\n"
        "out %%al, %%dx\n"
        "inc %%dx\n"
        "mov %1, %%al\n"
        "out %%al, %%dx\n"
        : : "c"((uint8_t)pos), "d"((uint8_t)(pos >> 8))
    );
}

void vga_hide_cursor(void) {
    __asm__ volatile (
        "mov $0x3D4, %%dx\n"
        "mov $0x0A, %%al\n"
        "out %%al, %%dx\n"
        "inc %%dx\n"
        "mov $0x20, %%al\n"
        "out %%al, %%dx\n"
    );
}