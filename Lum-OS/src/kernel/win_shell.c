#include "win_shell.h"
#include "ui_vga.h"
#include "desktop.h"
#include "wm.h"

#define SHELL_BUFFER_LINES 16
#define SHELL_LINE_MAX 64

typedef struct {
    char text[SHELL_LINE_MAX];
    uint8_t color;
} ShellLine;

static ShellLine shell_buffer[SHELL_BUFFER_LINES];
static int shell_buffer_head = 0;
static int shell_buffer_count = 0;

static char shell_input[64];
static int shell_input_len = 0;

void shell_print(const char* str, uint8_t color) {
    // Simple print: add to buffer
    while (*str) {
        if (*str == '\n') {
            // New line
            shell_buffer_head = (shell_buffer_head + 1) % SHELL_BUFFER_LINES;
            if (shell_buffer_count < SHELL_BUFFER_LINES) shell_buffer_count++;
            shell_buffer[shell_buffer_head].text[0] = 0; // Clear new line
            shell_buffer[shell_buffer_head].color = color;
        } else {
            // Append to current line
            int len = 0;
            while (shell_buffer[shell_buffer_head].text[len]) len++;
            if (len < SHELL_LINE_MAX - 1) {
                shell_buffer[shell_buffer_head].text[len] = *str;
                shell_buffer[shell_buffer_head].text[len + 1] = 0;
            }
        }
        str++;
    }
    wm_redraw_win(WIN_SHELL);
}

void win_shell_draw_body(int inner_row, int inner_col, int inner_h, int inner_w) {
    // Draw output buffer
    int lines_to_show = inner_h - 1; // Last line for prompt
    int start_line = shell_buffer_count > lines_to_show ? shell_buffer_count - lines_to_show : 0;
    
    for (int i = 0; i < lines_to_show && i < shell_buffer_count; i++) {
        int buf_idx = (shell_buffer_head - shell_buffer_count + 1 + i) % SHELL_BUFFER_LINES;
        vga_put_str(inner_row + i, inner_col, shell_buffer[buf_idx].text, VGA_ATTR(shell_buffer[buf_idx].color, THEME_WIN_BG));
    }
    
    // Draw prompt
    vga_put_str(inner_row + inner_h - 1, inner_col, "root@lum:~$ ", VGA_ATTR(THEME_PROMPT_FG, THEME_WIN_BG));
    vga_put_str(inner_row + inner_h - 1, inner_col + 12, shell_input, VGA_ATTR(THEME_CMD_FG, THEME_WIN_BG));
}