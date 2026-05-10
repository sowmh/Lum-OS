#include "desktop.h"
#include "ui_vga.h"
#include "kernel_globals.h"

static const char* dock_icons[] = {
    ">",  // Shell
    "##", // Monitor
    "**", // Apps
    "[]", // Files
    "+-", // Calc
    "..", // Paint
    "??", // About
};

static const char* dock_labels[] = {
    "Shell",
    "Monitor",
    "Apps",
    "Files",
    "Calc",
    "Paint",
    "About",
};

#define DOCK_ITEMS 7

void desktop_init(void) {
    // Clear entire screen
    vga_clear(VGA_ATTR(VGA_WHITE, VGA_BLACK));

    // Draw taskbar
    vga_fill_rect(REGION_TASKBAR_ROW, REGION_TASKBAR_COL, REGION_TASKBAR_H, REGION_TASKBAR_W, ' ', VGA_ATTR(THEME_TASKBAR_FG, THEME_TASKBAR_BG));
    vga_put_str(0, 0, "\xEB ", VGA_ATTR(THEME_LOGO_FG, THEME_TASKBAR_BG)); // ⬡
    vga_put_str(0, 2, "LUM-OS v0.9", VGA_ATTR(THEME_TASKBAR_FG, THEME_TASKBAR_BG));
    vga_put_str(0, 16, "[SHELL]", VGA_ATTR(THEME_DOCK_SEL_FG, THEME_DOCK_SEL_BG));
    vga_put_str(0, 24, "[MONITOR]", VGA_ATTR(THEME_DOCK_FG, THEME_TASKBAR_BG));
    vga_put_str(0, 34, "[FILES]", VGA_ATTR(THEME_DOCK_FG, THEME_TASKBAR_BG));
    vga_put_str(0, 42, "[APPS]", VGA_ATTR(THEME_DOCK_FG, THEME_TASKBAR_BG));
    vga_put_str(0, 50, "[CALC]", VGA_ATTR(THEME_DOCK_FG, THEME_TASKBAR_BG));
    // Clock will be updated later

    // Draw dock
    vga_fill_rect(REGION_DOCK_ROW, REGION_DOCK_COL, REGION_DOCK_H, REGION_DOCK_W, ' ', VGA_ATTR(THEME_DOCK_FG, THEME_DOCK_BG));
    for (int i = 0; i < DOCK_ITEMS; i++) {
        int row = REGION_DOCK_ROW + i * 3;
        vga_put_str(row + 1, REGION_DOCK_COL + 1, dock_icons[i], VGA_ATTR(THEME_DOCK_FG, THEME_DOCK_BG));
        vga_put_str(row + 2, REGION_DOCK_COL + 1, dock_labels[i], VGA_ATTR(THEME_DOCK_FG, THEME_DOCK_BG));
    }
    // Highlight first item (Shell)
    vga_put_char(REGION_DOCK_ROW, REGION_DOCK_COL, '\x10', VGA_ATTR(THEME_DOCK_SEL_FG, THEME_DOCK_SEL_BG)); // ►
    vga_fill_rect(REGION_DOCK_ROW, REGION_DOCK_COL + 1, 3, REGION_DOCK_W - 1, ' ', VGA_ATTR(THEME_DOCK_SEL_FG, THEME_DOCK_SEL_BG));
    vga_put_str(REGION_DOCK_ROW + 1, REGION_DOCK_COL + 1, dock_icons[0], VGA_ATTR(THEME_DOCK_SEL_FG, THEME_DOCK_SEL_BG));
    vga_put_str(REGION_DOCK_ROW + 2, REGION_DOCK_COL + 1, dock_labels[0], VGA_ATTR(THEME_DOCK_SEL_FG, THEME_DOCK_SEL_BG));

    // Draw separator
    vga_draw_vline(REGION_SEPARATOR_ROW, REGION_SEPARATOR_COL, REGION_SEPARATOR_H, VGA_ATTR(VGA_LIGHT_GRAY, VGA_BLACK));

    // Draw workspace
    vga_fill_rect(REGION_WORKSPACE_ROW, REGION_WORKSPACE_COL, REGION_WORKSPACE_H, REGION_WORKSPACE_W, ' ', VGA_ATTR(THEME_WIN_FG, THEME_WS_BG));

    // Draw statusbar
    vga_fill_rect(REGION_STATUSBAR_ROW, REGION_STATUSBAR_COL, REGION_STATUSBAR_H, REGION_STATUSBAR_W, ' ', VGA_ATTR(THEME_STATUS_FG, THEME_STATUS_BG));
    vga_put_str(24, 0, "\x07 Kernel OK  \x07 IRQ OK  \x07 FAT12 OK    ticks: 00000   A20\x13 PIC\x13 PIT\x13", VGA_ATTR(THEME_STATUS_FG, THEME_STATUS_BG));
    // \x07 is ●, \x13 is ✓

    // Hide cursor initially
    vga_hide_cursor();
}

void taskbar_update_clock(void) {
    uint32_t total_seconds = uptime_seconds;
    uint32_t hours = total_seconds / 3600;
    uint32_t minutes = (total_seconds % 3600) / 60;
    uint32_t seconds = total_seconds % 60;
    
    char buf[9];
    buf[0] = '0' + (hours / 10);
    buf[1] = '0' + (hours % 10);
    buf[2] = ':';
    buf[3] = '0' + (minutes / 10);
    buf[4] = '0' + (minutes % 10);
    buf[5] = ':';
    buf[6] = '0' + (seconds / 10);
    buf[7] = '0' + (seconds % 10);
    buf[8] = 0;
    
    vga_put_str(0, 71, buf, VGA_ATTR(THEME_CLOCK_FG, THEME_TASKBAR_BG));
}

void statusbar_update_ticks(uint32_t ticks) {
    // Update ticks in statusbar
    char buf[6];
    uint32_t t = ticks;
    for (int i = 4; i >= 0; i--) {
        buf[4 - i] = '0' + (t % 10);
        t /= 10;
    }
    buf[5] = 0;
    vga_put_str(24, 44, buf, VGA_ATTR(THEME_STATUS_FG, THEME_STATUS_BG));
}