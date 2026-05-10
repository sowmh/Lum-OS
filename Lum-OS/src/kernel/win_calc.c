#include "win_calc.h"
#include "ui_vga.h"
#include "desktop.h"

void win_calc_draw_body(int inner_row, int inner_col, int inner_h, int inner_w) {
    vga_put_str(inner_row, inner_col, "\xC9\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xBB", VGA_ATTR(VGA_WHITE, VGA_BLACK)); // ╔═ NUMBER FORGE ══╗
    vga_put_str(inner_row + 1, inner_col, "\xBA  \xDA\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xBF  \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 2, inner_col, "\xBA  \xB3       0     \xB3  \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 3, inner_col, "\xBA  \xC0\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xD9  \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 4, inner_col, "\xBA  [7][8][9][/]   \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 5, inner_col, "\xBA  [4][5][6][*]   \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 6, inner_col, "\xBA  [1][2][3][-]   \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 7, inner_col, "\xBA  [0][.][=][+]   \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 8, inner_col, "\xBA  [C]  [<<]      \xBA", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 9, inner_col, "\xC8\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xCD\xBC", VGA_ATTR(VGA_WHITE, VGA_BLACK)); // ╚═════════════════╝
}