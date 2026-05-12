#include "gfx.h"
#include <stdint.h>

#define FB_VIRT_BASE    0xFD000000UL
#define PAGE_SIZE       4096
#define PTE_PRESENT     0x001
#define PTE_WRITE       0x002
#define PTE_PCD         0x010
#define PTE_PWT         0x008

static volatile uint32_t *fb = NULL;
static uint32_t fb_width = 0;
static uint32_t fb_height = 0;
static uint32_t fb_pitch = 0;  /* in bytes */
static uint8_t  fb_bpp = 0;
static uint8_t  fb_red_pos = 0;
static uint8_t  fb_green_pos = 0;
static uint8_t  fb_blue_pos = 0;

/* Simple memory operations without stdlib */
static void *memset_int(void *s, int c, unsigned long n) {
    unsigned char *p = (unsigned char *)s;
    while (n-- > 0) {
        *p++ = (unsigned char)c;
    }
    return s;
}

static void *memcpy_int(void *dst, const void *src, unsigned long n) {
    unsigned char *d = (unsigned char *)dst;
    const unsigned char *s = (const unsigned char *)src;
    while (n-- > 0) {
        *d++ = *s++;
    }
    return dst;
}

/* External paging function (from kernel) */
extern void map_pages(uint32_t virt, uint32_t phys, uint32_t size, uint32_t flags);

void gfx_init(uint32_t phys_addr, uint32_t width, uint32_t height,
              uint32_t pitch, uint8_t bpp, uint8_t red_pos,
              uint8_t green_pos, uint8_t blue_pos) {
    if (phys_addr == 0 || width == 0 || height == 0) {
        return;  /* Invalid parameters, fallback to text mode */
    }

    fb_width = width;
    fb_height = height;
    fb_pitch = pitch;
    fb_bpp = bpp;
    fb_red_pos = red_pos;
    fb_green_pos = green_pos;
    fb_blue_pos = blue_pos;

    /* Map framebuffer to virtual address 0xFD000000 */
    uint32_t fb_size = pitch * height;
    uint32_t fb_size_aligned = ((fb_size + PAGE_SIZE - 1) / PAGE_SIZE) * PAGE_SIZE;
    
    map_pages(FB_VIRT_BASE, phys_addr, fb_size_aligned,
              PTE_PRESENT | PTE_WRITE | PTE_PCD | PTE_PWT);
    
    fb = (volatile uint32_t *)FB_VIRT_BASE;
}

void gfx_put_pixel(int x, int y, Color c) {
    if (fb == NULL) return;
    if ((unsigned)x >= fb_width || (unsigned)y >= fb_height) return;
    
    volatile uint32_t *pixel = fb + (y * (fb_pitch / 4)) + x;
    *pixel = c;
}

void gfx_clear(Color c) {
    if (fb == NULL) return;
    
    for (uint32_t y = 0; y < fb_height; y++) {
        for (uint32_t x = 0; x < fb_width; x++) {
            gfx_put_pixel(x, y, c);
        }
    }
}

void gfx_fill_rect(int x, int y, int w, int h, Color c) {
    if (fb == NULL) return;
    
    int x_start = (x < 0) ? 0 : x;
    int y_start = (y < 0) ? 0 : y;
    int x_end = (x + w > (int)fb_width) ? (int)fb_width : x + w;
    int y_end = (y + h > (int)fb_height) ? (int)fb_height : y + h;
    
    for (int py = y_start; py < y_end; py++) {
        for (int px = x_start; px < x_end; px++) {
            gfx_put_pixel(px, py, c);
        }
    }
}

void gfx_draw_rect(int x, int y, int w, int h, int thickness, Color c) {
    if (fb == NULL) return;
    
    /* Top and bottom edges */
    for (int i = 0; i < thickness; i++) {
        gfx_fill_rect(x, y + i, w, 1, c);
        gfx_fill_rect(x, y + h - 1 - i, w, 1, c);
    }
    
    /* Left and right edges */
    for (int i = 0; i < thickness; i++) {
        gfx_fill_rect(x + i, y, 1, h, c);
        gfx_fill_rect(x + w - 1 - i, y, 1, h, c);
    }
}

void gfx_draw_line(int x0, int y0, int x1, int y1, Color c) {
    if (fb == NULL) return;
    
    /* Bresenham's line algorithm */
    int dx = (x1 > x0) ? (x1 - x0) : (x0 - x1);
    int dy = (y1 > y0) ? (y1 - y0) : (y0 - y1);
    int sx = (x0 < x1) ? 1 : -1;
    int sy = (y0 < y1) ? 1 : -1;
    int err = dx - dy;
    
    int x = x0;
    int y = y0;
    
    while (1) {
        gfx_put_pixel(x, y, c);
        
        if (x == x1 && y == y1) break;
        
        int e2 = 2 * err;
        if (e2 > -dy) {
            err -= dy;
            x += sx;
        }
        if (e2 < dx) {
            err += dx;
            y += sy;
        }
    }
}

void gfx_fill_circle(int cx, int cy, int r, Color c) {
    if (fb == NULL) return;
    
    /* Midpoint circle algorithm */
    int x = r;
    int y = 0;
    int d = 3 - 2 * r;
    
    while (x >= y) {
        /* Draw horizontal lines for each octant */
        gfx_fill_rect(cx - x, cy + y, 2 * x + 1, 1, c);
        gfx_fill_rect(cx - x, cy - y, 2 * x + 1, 1, c);
        gfx_fill_rect(cx - y, cy + x, 2 * y + 1, 1, c);
        gfx_fill_rect(cx - y, cy - x, 2 * y + 1, 1, c);
        
        if (d < 0) {
            d = d + 4 * y + 6;
        } else {
            d = d + 4 * (y - x) + 10;
            x--;
        }
        y++;
    }
}

void gfx_draw_circle(int cx, int cy, int r, Color c) {
    if (fb == NULL) return;
    
    /* Draw circle outline using Midpoint algorithm */
    int x = r;
    int y = 0;
    int d = 3 - 2 * r;
    
    while (x >= y) {
        gfx_put_pixel(cx + x, cy + y, c);
        gfx_put_pixel(cx - x, cy + y, c);
        gfx_put_pixel(cx + x, cy - y, c);
        gfx_put_pixel(cx - x, cy - y, c);
        gfx_put_pixel(cx + y, cy + x, c);
        gfx_put_pixel(cx - y, cy + x, c);
        gfx_put_pixel(cx + y, cy - x, c);
        gfx_put_pixel(cx - y, cy - x, c);
        
        if (d < 0) {
            d = d + 4 * y + 6;
        } else {
            d = d + 4 * (y - x) + 10;
            x--;
        }
        y++;
    }
}

void gfx_fill_gradient_v(int x, int y, int w, int h, Color c1, Color c2) {
    if (fb == NULL || h == 0) return;
    
    for (int py = 0; py < h; py++) {
        /* Linear interpolation between c1 and c2 */
        int t = (py * 255) / h;
        
        uint8_t r1 = (c1 >> 16) & 0xFF;
        uint8_t g1 = (c1 >> 8) & 0xFF;
        uint8_t b1 = c1 & 0xFF;
        
        uint8_t r2 = (c2 >> 16) & 0xFF;
        uint8_t g2 = (c2 >> 8) & 0xFF;
        uint8_t b2 = c2 & 0xFF;
        
        uint8_t r = (uint8_t)((r1 * (255 - t) + r2 * t) / 255);
        uint8_t g = (uint8_t)((g1 * (255 - t) + g2 * t) / 255);
        uint8_t b = (uint8_t)((b1 * (255 - t) + b2 * t) / 255);
        
        Color c = COLOR(r, g, b);
        gfx_fill_rect(x, y + py, w, 1, c);
    }
}

void gfx_fill_rounded_rect(int x, int y, int w, int h, int r, Color c) {
    if (fb == NULL) return;
    
    /* Fill main rectangle */
    gfx_fill_rect(x + r, y, w - 2 * r, h, c);
    gfx_fill_rect(x, y + r, w, h - 2 * r, c);
    
    /* Fill four corners with quarter circles */
    for (int dx = 0; dx < r; dx++) {
        for (int dy = 0; dy < r; dy++) {
            int dist_sq = dx * dx + dy * dy;
            if (dist_sq <= r * r) {
                /* Top-left */
                gfx_put_pixel(x + r - dx, y + r - dy, c);
                /* Top-right */
                gfx_put_pixel(x + w - r + dx, y + r - dy, c);
                /* Bottom-left */
                gfx_put_pixel(x + r - dx, y + h - r + dy, c);
                /* Bottom-right */
                gfx_put_pixel(x + w - r + dx, y + h - r + dy, c);
            }
        }
    }
}

void gfx_draw_rounded_rect(int x, int y, int w, int h, int r, int t, Color c) {
    if (fb == NULL) return;
    
    /* Draw outline of rounded rectangle */
    for (int i = 0; i < t; i++) {
        gfx_draw_rect(x + r, y + i, w - 2 * r, h, 1, c);
        gfx_draw_rect(x + i, y + r, w, h - 2 * r, 1, c);
    }
}

void gfx_blit_rect(int dst_x, int dst_y, int src_x, int src_y, int w, int h) {
    if (fb == NULL) return;
    
    for (int py = 0; py < h; py++) {
        for (int px = 0; px < w; px++) {
            int src_px = src_x + px;
            int src_py = src_y + py;
            int dst_px = dst_x + px;
            int dst_py = dst_y + py;
            
            if ((unsigned)src_px < fb_width && (unsigned)src_py < fb_height &&
                (unsigned)dst_px < fb_width && (unsigned)dst_py < fb_height) {
                
                Color c = fb[(src_py * (fb_pitch / 4)) + src_px];
                fb[(dst_py * (fb_pitch / 4)) + dst_px] = c;
            }
        }
    }
}

Color gfx_blend(Color dst, Color src) {
    uint8_t a = (src >> 24) & 0xFF;
    uint8_t sr = (src >> 16) & 0xFF;
    uint8_t sg = (src >> 8) & 0xFF;
    uint8_t sb = src & 0xFF;
    
    uint8_t dr = (dst >> 16) & 0xFF;
    uint8_t dg = (dst >> 8) & 0xFF;
    uint8_t db = dst & 0xFF;
    
    uint8_t r = (uint8_t)((sr * a + dr * (255 - a)) / 255);
    uint8_t g = (uint8_t)((sg * a + dg * (255 - a)) / 255);
    uint8_t b = (uint8_t)((sb * a + db * (255 - a)) / 255);
    
    return COLOR(r, g, b);
}

void gfx_fill_rect_alpha(int x, int y, int w, int h, Color c) {
    if (fb == NULL) return;
    
    for (int py = y; py < y + h; py++) {
        for (int px = x; px < x + w; px++) {
            if ((unsigned)px < fb_width && (unsigned)py < fb_height) {
                Color dst = fb[(py * (fb_pitch / 4)) + px];
                Color blended = gfx_blend(dst, c);
                fb[(py * (fb_pitch / 4)) + px] = blended;
            }
        }
    }
}

uint32_t gfx_get_width(void) {
    return fb_width;
}

uint32_t gfx_get_height(void) {
    return fb_height;
}
