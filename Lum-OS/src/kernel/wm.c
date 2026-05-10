#include "wm.h"
#include "ui_vga.h"
#include "desktop.h"
#include "win_shell.h"
#include "win_monitor.h"
#include "win_apps.h"
#include "win_files.h"
#include "win_calc.h"
#include "win_paint.h"
#include "win_about.h"

static Window windows[WM_MAX_WINS];
static int focused_win = -1;

void wm_init(void) {
    for (int i = 0; i < WM_MAX_WINS; i++) {
        windows[i].visible = 0;
        windows[i].focused = 0;
    }
    
    // Initialize shell window
    windows[WIN_SHELL].id = WIN_SHELL;
    windows[WIN_SHELL].row = 2;
    windows[WIN_SHELL].col = 12;
    windows[WIN_SHELL].h = 18;
    windows[WIN_SHELL].w = 50;
    windows[WIN_SHELL].draw_body = win_shell_draw_body;
    const char* title_shell = "Shell";
    for (int j = 0; j < 32 && title_shell[j]; j++) {
        windows[WIN_SHELL].title[j] = title_shell[j];
    }
    
    // Initialize monitor window
    windows[WIN_MONITOR].id = WIN_MONITOR;
    windows[WIN_MONITOR].row = 2;
    windows[WIN_MONITOR].col = 42;
    windows[WIN_MONITOR].h = 14;
    windows[WIN_MONITOR].w = 36;
    windows[WIN_MONITOR].draw_body = win_monitor_draw_body;
    const char* title_monitor = "Monitor";
    for (int j = 0; j < 32 && title_monitor[j]; j++) {
        windows[WIN_MONITOR].title[j] = title_monitor[j];
    }
    
    // Initialize apps window
    windows[WIN_APPS].id = WIN_APPS;
    windows[WIN_APPS].row = 4;
    windows[WIN_APPS].col = 14;
    windows[WIN_APPS].h = 16;
    windows[WIN_APPS].w = 44;
    windows[WIN_APPS].draw_body = win_apps_draw_body;
    const char* title_apps = "Apps";
    for (int j = 0; j < 32 && title_apps[j]; j++) {
        windows[WIN_APPS].title[j] = title_apps[j];
    }
    
    // Initialize files window
    windows[WIN_FILES].id = WIN_FILES;
    windows[WIN_FILES].row = 3;
    windows[WIN_FILES].col = 13;
    windows[WIN_FILES].h = 14;
    windows[WIN_FILES].w = 38;
    windows[WIN_FILES].draw_body = win_files_draw_body;
    const char* title_files = "Files";
    for (int j = 0; j < 32 && title_files[j]; j++) {
        windows[WIN_FILES].title[j] = title_files[j];
    }
    
    // Initialize calc window
    windows[WIN_CALC].id = WIN_CALC;
    windows[WIN_CALC].row = 3;
    windows[WIN_CALC].col = 55;
    windows[WIN_CALC].h = 16;
    windows[WIN_CALC].w = 22;
    windows[WIN_CALC].draw_body = win_calc_draw_body;
    const char* title_calc = "Calc";
    for (int j = 0; j < 32 && title_calc[j]; j++) {
        windows[WIN_CALC].title[j] = title_calc[j];
    }
    
    // Initialize paint window
    windows[WIN_PAINT].id = WIN_PAINT;
    windows[WIN_PAINT].row = 2;
    windows[WIN_PAINT].col = 12;
    windows[WIN_PAINT].h = 20;
    windows[WIN_PAINT].w = 44;
    windows[WIN_PAINT].draw_body = win_paint_draw_body;
    const char* title_paint = "Paint";
    for (int j = 0; j < 32 && title_paint[j]; j++) {
        windows[WIN_PAINT].title[j] = title_paint[j];
    }
    
    // Initialize about window
    windows[WIN_ABOUT].id = WIN_ABOUT;
    windows[WIN_ABOUT].row = 5;
    windows[WIN_ABOUT].col = 20;
    windows[WIN_ABOUT].h = 14;
    windows[WIN_ABOUT].w = 38;
    windows[WIN_ABOUT].draw_body = win_about_draw_body;
    const char* title_about = "About";
    for (int j = 0; j < 32 && title_about[j]; j++) {
        windows[WIN_ABOUT].title[j] = title_about[j];
    }
}

void wm_open(int win_id) {
    if (win_id < 0 || win_id >= WM_MAX_WINS) return;
    windows[win_id].visible = 1;
    wm_focus(win_id);
    wm_redraw_all();
}

void wm_close(int win_id) {
    if (win_id < 0 || win_id >= WM_MAX_WINS) return;
    windows[win_id].visible = 0;
    windows[win_id].focused = 0;
    if (focused_win == win_id) {
        focused_win = -1;
        // TODO: Focus another window
    }
    wm_redraw_all();
}

void wm_focus(int win_id) {
    if (win_id < 0 || win_id >= WM_MAX_WINS || !windows[win_id].visible) return;
    if (focused_win >= 0) {
        windows[focused_win].focused = 0;
    }
    focused_win = win_id;
    windows[win_id].focused = 1;
    wm_redraw_all();
}

void wm_redraw_all(void) {
    desktop_init(); // Redraw desktop
    for (int i = 0; i < WM_MAX_WINS; i++) {
        if (windows[i].visible) {
            wm_redraw_win(i);
        }
    }
}

void wm_redraw_win(int win_id) {
    if (win_id < 0 || win_id >= WM_MAX_WINS || !windows[win_id].visible) return;
    Window *win = &windows[win_id];
    
    // Draw border
    uint8_t border_attr = win->focused ? VGA_ATTR(THEME_WIN_BORDER, VGA_BLACK) : VGA_ATTR(VGA_LIGHT_GRAY, VGA_BLACK);
    vga_draw_box_double(win->row, win->col, win->h, win->w, border_attr);
    
    // Draw title
    uint8_t title_attr = VGA_ATTR(THEME_WIN_TITLE_FG, THEME_WIN_TITLE_BG);
    vga_fill_rect(win->row, win->col + 1, 1, win->w - 2, ' ', title_attr);
    int title_len = 0;
    while (win->title[title_len]) title_len++;
    int title_start = win->col + (win->w - title_len) / 2;
    vga_put_str(win->row, title_start, win->title, title_attr);
    
    // Clear body
    vga_fill_rect(win->row + 1, win->col + 1, win->h - 2, win->w - 2, ' ', VGA_ATTR(THEME_WIN_FG, THEME_WIN_BG));
    
    // Draw body
    if (win->draw_body) {
        win->draw_body(win->row + 1, win->col + 1, win->h - 2, win->w - 2);
    }
}

int wm_focused(void) {
    return focused_win;
}