#ifndef KERNEL_API_H
#define KERNEL_API_H

#include <stdint.h>

void show_banner(void);
void print_prompt(void);
void read_line(void);
void dispatch_command(void);
void console_write(const char *s);
void console_putc(char c);
void clear_screen(void);
void set_body_color(void);
void init_paging(void);
void map_framebuffer(void);

extern uint32_t timer_ticks;
extern uint32_t heap_end;
extern uint32_t heap_used_bytes;
extern uint32_t heap_alloc_count;
extern uint32_t heap_free_count;
extern uint32_t heap_high_water;
extern uint32_t fb_addr;
extern uint32_t fb_width;
extern uint32_t fb_height;
extern uint32_t fb_pitch;

#endif
