#include "win_apps.h"
#include "ui_vga.h"
#include "desktop.h"

void win_apps_draw_body(int inner_row, int inner_col, int inner_h, int inner_w) {
    vga_put_str(inner_row, inner_col, "\xDA\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xBF", VGA_ATTR(VGA_WHITE, VGA_BLACK)); // ┌─ STUDIO DECK ──────────────────────┐
    vga_put_str(inner_row + 1, inner_col, "\xB3  [1] >_ Shell      Terminal del kernel     \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 2, inner_col, "\xB3  [2] ## Monitor    Sistema y memoria       \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 3, inner_col, "\xB3  [3] [] Files      Archivos FAT12          \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 4, inner_col, "\xB3  [4] +- Calc       Calculadora entera      \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 5, inner_col, "\xB3  [5] .. Paint      Canvas ASCII 40x16      \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 6, inner_col, "\xB3  [6] Ed Inkboard   Editor de notas         \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 7, inner_col, "\xB3  [7] ?? About      Info del sistema        \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 8, inner_col, "\xC0\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xD9", VGA_ATTR(VGA_WHITE, VGA_BLACK)); // └────────────────────────────────────┘
    vga_put_str(inner_row + 9, inner_col, "  Usa las flechas + Enter para abrir", VGA_ATTR(VGA_WHITE, VGA_BLACK));
}