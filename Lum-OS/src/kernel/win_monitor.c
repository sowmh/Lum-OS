#include "win_monitor.h"
#include "ui_vga.h"
#include "desktop.h"
#include "kernel_globals.h"

void win_monitor_draw_body(int inner_row, int inner_col, int inner_h, int inner_w) {
    vga_put_str(inner_row, inner_col, "\xDA\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xBF", VGA_ATTR(VGA_WHITE, VGA_BLACK)); // ┌─ SISTEMA ─────────────────────┐
    vga_put_str(inner_row + 1, inner_col, "\xB3 Kernel base:  0x00010000      \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 2, inner_col, "\xB3 Heap range:   0x120000-0x220000\xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 3, inner_col, "\xB3 Boot info @:  0x00009000      \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 4, inner_col, "\xB3 Arch:         x86 32-bit PM   \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 5, inner_col, "\xC3\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xB4", VGA_ATTR(VGA_WHITE, VGA_BLACK)); // ├─ ESTADO ──────────────────────┤
    vga_put_str(inner_row + 6, inner_col, "\xB3 Uptime:       000h 00m 00s   \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 7, inner_col, "\xB3 Ticks PIT:    00000000        \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 8, inner_col, "\xB3 Heap usado:   \xB0\xB0\xB0\xB0\xB0\xB0\xB0\xB0 28%  \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 9, inner_col, "\xB3 A20:  OK  PIC: OK  PIT: OK   \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 10, inner_col, "\xB3 Paging: ON   Guard: ON        \xB3", VGA_ATTR(VGA_WHITE, VGA_BLACK));
    vga_put_str(inner_row + 11, inner_col, "\xC0\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xC4\xD9", VGA_ATTR(VGA_WHITE, VGA_BLACK)); // └───────────────────────────────┘
    
    // Update uptime
    uint32_t hours = uptime_seconds / 3600;
    uint32_t minutes = (uptime_seconds % 3600) / 60;
    uint32_t seconds = uptime_seconds % 60;
    char uptime_buf[12];
    uptime_buf[0] = '0' + (hours / 100);
    uptime_buf[1] = '0' + ((hours / 10) % 10);
    uptime_buf[2] = '0' + (hours % 10);
    uptime_buf[3] = 'h';
    uptime_buf[4] = ' ';
    uptime_buf[5] = '0' + (minutes / 10);
    uptime_buf[6] = '0' + (minutes % 10);
    uptime_buf[7] = 'm';
    uptime_buf[8] = ' ';
    uptime_buf[9] = '0' + (seconds / 10);
    uptime_buf[10] = '0' + (seconds % 10);
    uptime_buf[11] = 's';
    vga_put_str(inner_row + 6, inner_col + 15, uptime_buf, VGA_ATTR(VGA_WHITE, VGA_BLACK));
    
    // Update ticks
    char ticks_buf[9];
    uint32_t t = pit_ticks;
    for (int i = 7; i >= 0; i--) {
        ticks_buf[7 - i] = '0' + (t % 10);
        t /= 10;
    }
    ticks_buf[8] = 0;
    vga_put_str(inner_row + 7, inner_col + 15, ticks_buf, VGA_ATTR(VGA_WHITE, VGA_BLACK));
}