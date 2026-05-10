#include "win_about.h"
#include "ui_vga.h"
#include "desktop.h"

void win_about_draw_body(int inner_row, int inner_col, int inner_h, int inner_w) {
    vga_put_str(inner_row, inner_col, "\xC9\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xBB", VGA_ATTR(VGA_WHITE, VGA_BLACK)); // ╔═ ACERCA DE LUM-OS ════════════╗
    vga_put_str(inner_row + 1, inner_col, "\xBA                               \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 2, inner_col, "\xBA      \x9C\x9C     \x9C\x9C   \x9C\x9C\x9C\x9C\x9C   \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK)); // ASCII art for LUM-OS
    vga_put_str(inner_row + 3, inner_col, "\xBA      \x9C\x9C     \x9C\x9C   \x9C\x9C\x9C\x9C\x9C   \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 4, inner_col, "\xBA      \x9C\x9C     \x9C\x9C   \x9C\x9C\x9C\x9C\x9C   \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 5, inner_col, "\xBA                               \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 6, inner_col, "\xBA  Versi\xA2n:  0.9                \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 7, inner_col, "\xBA  Arch:     x86 32-bit PM      \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 8, inner_col, "\xBA  FS:       FAT12 1.44 MB      \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 9, inner_col, "\xBA  Licencia: MIT                \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 10, inner_col, "\xBA  Autor:    sowmh              \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 11, inner_col, "\xBA  github.com/sowmh/Lum-OS      \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 12, inner_col, "\xC8\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xBC", VGA_ATTR(VGA_WHITE, VGA_BLACK)); // ╚═══════════════════════════════╝
}