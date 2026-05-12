#ifndef GFX_H
#define GFX_H

#include <stdint.h>

/* Color format: 0xAARRGGBB (ARGB) */
typedef uint32_t Color;

#define COLOR(r, g, b)         (0xFF000000 | ((r) << 16) | ((g) << 8) | (b))
#define COLOR_ALPHA(r, g, b, a) (((a) << 24) | ((r) << 16) | ((g) << 8) | (b))

/* --- Lum-OS Theme Palette --- */
#define C_BG_DESKTOP    COLOR(13,  17,  23)   /* #0D1117 nearly black */
#define C_BG_SURFACE    COLOR(22,  27,  34)   /* #161B22 surface */
#define C_BG_PANEL      COLOR(33,  38,  45)   /* #21262D panel */
#define C_BORDER        COLOR(48,  54,  61)   /* #30363D border */
#define C_ACCENT        COLOR(88, 166, 255)   /* #58A6FF blue accent */
#define C_ACCENT2       COLOR(63, 185, 80)    /* #3FB950 green accent */
#define C_ERROR         COLOR(248, 81,  73)   /* #F85149 red error */
#define C_WARN          COLOR(210, 153, 34)   /* #D29922 orange warn */
#define C_TEXT_PRI      COLOR(230, 237, 243)  /* #E6EDF3 primary text */
#define C_TEXT_SEC      COLOR(139, 148, 158)  /* #8B949E secondary text */
#define C_WIN_TITLE_BG  COLOR(22,  27,  34)   /* window title bar */
#define C_WIN_CLOSE     COLOR(255, 95,  86)   /* window close button (red) */
#define C_WIN_MIN       COLOR(255, 189, 46)   /* window minimize button (yellow) */
#define C_WIN_MAX       COLOR(39, 201, 63)    /* window maximize button (green) */

/* Framebuffer initialization */
void gfx_init(uint32_t phys_addr, uint32_t width, uint32_t height, 
              uint32_t pitch, uint8_t bpp, uint8_t red_pos, 
              uint8_t green_pos, uint8_t blue_pos);

/* Basic pixel operations */
void gfx_clear(Color c);
void gfx_put_pixel(int x, int y, Color c);

/* Rectangle operations */
void gfx_fill_rect(int x, int y, int w, int h, Color c);
void gfx_draw_rect(int x, int y, int w, int h, int thickness, Color c);
void gfx_fill_rounded_rect(int x, int y, int w, int h, int r, Color c);
void gfx_draw_rounded_rect(int x, int y, int w, int h, int r, int t, Color c);

/* Line and circle operations */
void gfx_draw_line(int x0, int y0, int x1, int y1, Color c);
void gfx_draw_circle(int cx, int cy, int r, Color c);
void gfx_fill_circle(int cx, int cy, int r, Color c);

/* Gradients */
void gfx_fill_gradient_v(int x, int y, int w, int h, Color c1, Color c2);

/* Blitting */
void gfx_blit_rect(int dst_x, int dst_y, int src_x, int src_y, int w, int h);

/* Alpha blending */
Color gfx_blend(Color dst, Color src);
void gfx_fill_rect_alpha(int x, int y, int w, int h, Color c);

/* Utility functions */
uint32_t gfx_get_width(void);
uint32_t gfx_get_height(void);

#endif /* GFX_H */
