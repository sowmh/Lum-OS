#include "win_paint.h"
#include "ui_vga.h"
#include "desktop.h"

void win_paint_draw_body(int inner_row, int inner_col, int inner_h, int inner_w) {
    // Simple canvas placeholder
    for (int r = 0; r < 16; r++) {
        for (int c = 0; c < 40; c++) {
            vga_put_char(inner_row + r, inner_col + c, ' ', VGA_ATTR(VGA_WHITE, VGA_BLACK));
        }
    }
    vga_put_str(inner_row + 17, inner_col, "q:quit c:clear 1-9:char Space:draw Arrows:move", VGA_ATTR(VGA_WHITE, VGA_BLACK));
}