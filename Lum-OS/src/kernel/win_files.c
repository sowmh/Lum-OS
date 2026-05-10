#include "win_files.h"
#include "ui_vga.h"
#include "desktop.h"

void win_files_draw_body(int inner_row, int inner_col, int inner_h, int inner_w) {
    vga_put_str(inner_row, inner_col, "\xDA\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xBF", VGA_ATTR(VGA_WHITE, VGA_BLACK)); // ┌─ FAT12 / ─────────────────────┐
    vga_put_str(inner_row + 1, inner_col, "\xB3  STAGE1.BIN    512 B   [ROM]  \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 2, inner_col, "\xB3  STAGE2.BIN   4096 B   [ROM]  \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 3, inner_col, "\xB3  KERNEL.BIN  38912 B   [RAM]  \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 4, inner_col, "\xB3  README.TXT   1228 B   [RAM]  \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 5, inner_col, "\xB3  NOTES.TXT     256 B   [RAM]  \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 6, inner_col, "\xB3  TEST.TXT      128 B   [RAM]  \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 7, inner_col, "\xB3                               \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 8, inner_col, "\xB3  6 archivos · FAT12 1.44MB   \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 9, inner_col, "\xC0\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xD9", VGA_ATTR(VGA_WHITE, VGA_BLACK)); // └───────────────────────────────┘
}