#ifndef FONT_H
#define FONT_H

#include "gfx.h"

/* Font dimensions */
#define FONT_W  8
#define FONT_H  16

/* Font functions */
void font_init(void);
void font_draw_char(int px, int py, char c, Color fg, Color bg);
void font_draw_str(int px, int py, const char *s, Color fg, Color bg);
void font_draw_char_trans(int px, int py, char c, Color fg);
void font_draw_str_trans(int px, int py, const char *s, Color fg);

#endif /* FONT_H */