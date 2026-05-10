#ifndef WM_H
#define WM_H

#include <stdint.h>

#define WM_MAX_WINS 6
#define WIN_W_MAX 68
#define WIN_H_MAX 22

typedef struct {
    int id;
    int row, col;
    int h, w;
    int visible;
    int focused;
    char title[32];
    void (*draw_body)(int inner_row, int inner_col, int inner_h, int inner_w);
} Window;

#define WIN_SHELL 0
#define WIN_MONITOR 1
#define WIN_APPS 2
#define WIN_FILES 3
#define WIN_CALC 4
#define WIN_PAINT 5
#define WIN_ABOUT 6

void wm_init(void);
void wm_open(int win_id);
void wm_close(int win_id);
void wm_focus(int win_id);
void wm_redraw_all(void);
void wm_redraw_win(int win_id);
int wm_focused(void);

#endif