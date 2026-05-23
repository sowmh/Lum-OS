#include <stdint.h>

#include "boot_info.h"
#include "font.h"
#include "gfx.h"
#include "kernel_api.h"

static void kernel_draw_boot_desktop(const volatile struct boot_info *bi) {
    if (bi->fb_addr == 0 || bi->fb_width == 0 || bi->fb_height == 0 || bi->fb_bpp != 32) {
        return;
    }

    gfx_init(
        bi->fb_addr,
        bi->fb_width,
        bi->fb_height,
        bi->fb_pitch,
        bi->fb_bpp,
        bi->fb_red_pos,
        bi->fb_green_pos,
        bi->fb_blue_pos
    );

    font_init();
    gfx_fill_gradient_v(0, 0, (int)gfx_get_width(), (int)gfx_get_height(), C_BG_DESKTOP, C_BG_SURFACE);

    int screen_w = (int)gfx_get_width();
    int screen_h = (int)gfx_get_height();
    int win_x = 32;
    int win_y = 96;
    int win_w = screen_w - 64;
    int win_h = screen_h - 192;

    gfx_fill_rounded_rect(win_x, win_y, win_w, win_h, 12, C_BG_PANEL);
    gfx_draw_rounded_rect(win_x, win_y, win_w, win_h, 12, 2, C_BORDER);
    gfx_fill_rect(win_x + 4, win_y + 4, win_w - 8, 28, C_BG_PANEL);
    font_draw_str_trans(win_x + 12, win_y + 8, "Lum-OS Terminal", C_TEXT_PRI);
    gfx_fill_rect(0, screen_h - 40, screen_w, 40, C_BG_PANEL);
    font_draw_str_trans(24, screen_h - 30, "[F1] Help  [F2] Shell  [F3] Exit", C_TEXT_SEC);
    font_draw_str_trans(24, 54, "LUM-OS framebuffer online", C_ACCENT);
    font_draw_str_trans(24, 74, "Terminal ready. Use keyboard input below.", C_TEXT_PRI);
}

void gui_console_putc(uint32_t ch) {
    (void)ch;
}

void kernel_main(void) {
    volatile struct boot_info *bi = boot_info_get();

    init_paging();
    kernel_draw_boot_desktop(bi);
    font_init();
    clear_screen();
    show_banner();

    while (1) {
        print_prompt();
        read_line();
        dispatch_command();
    }
}
