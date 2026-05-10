#ifndef UI_VGA_H
#define UI_VGA_H

#include <stdint.h>

// VGA text mode buffer
#define VGA_MEMORY ((volatile uint16_t*)0xB8000)
#define VGA_COLS 80
#define VGA_ROWS 25

// Colors
#define VGA_BLACK 0
#define VGA_BLUE 1
#define VGA_GREEN 2
#define VGA_CYAN 3
#define VGA_RED 4
#define VGA_MAGENTA 5
#define VGA_BROWN 6
#define VGA_LIGHT_GRAY 7
#define VGA_DARK_GRAY 8
#define VGA_LIGHT_BLUE 9
#define VGA_LIGHT_GREEN 10
#define VGA_LIGHT_CYAN 11
#define VGA_LIGHT_RED 12
#define VGA_LIGHT_MAG 13
#define VGA_YELLOW 14
#define VGA_WHITE 15

#define VGA_ATTR(fg, bg) ((uint8_t)((bg) << 4 | (fg)))

// API
void vga_clear(uint8_t attr);
void vga_put_char(int row, int col, char c, uint8_t attr);
void vga_put_str(int row, int col, const char *s, uint8_t attr);
void vga_fill_rect(int row, int col, int h, int w, char c, uint8_t attr);
void vga_draw_hline(int row, int col, int len, uint8_t attr);
void vga_draw_vline(int row, int col, int len, uint8_t attr);
void vga_draw_box(int row, int col, int h, int w, uint8_t attr);
void vga_draw_box_double(int row, int col, int h, int w, uint8_t attr);
void vga_move_cursor(int row, int col);
void vga_hide_cursor(void);

#endif