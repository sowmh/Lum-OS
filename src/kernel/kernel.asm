org 0x10000
bits 32

%define VGA_TEXT                0xB8000
%define VGA_COLS                80
%define VGA_ROWS                25
%define VGA_ROW_BYTES           (VGA_COLS * 2)
%define COM1                    0x3F8
%define BOOT_INFO_ADDR          0x00009000
%define BOOTINFO_MAGIC          0x304D554C
%define BOOTINFO_CONV_KB        6
%define BOOTINFO_EXT_KB         8
%define BOOTINFO_TOTAL_KB       10
%define BOOTINFO_ROOTDIR_ENTRIES 14
%define BOOTINFO_ROOTDIR_ADDR    16
%define LINE_BUFFER_SIZE        128

start:
    cli
    mov esp, 0x0009F000

    mov byte [text_color], 0x0F
    call serial_init
    call clear_screen
    call show_banner

shell_loop:
    mov esi, prompt
    call console_write
    call read_line
    call dispatch_command
    jmp shell_loop

show_banner:
    mov byte [text_color], 0x1E
    mov esi, banner_top
    call console_write
    mov esi, banner_mid
    call console_write
    mov esi, banner_bottom
    call console_write

    mov byte [text_color], 0x0A
    mov esi, boot_ok_message
    call console_write

    mov byte [text_color], 0x07
    mov esi, shell_hint
    call console_write
    ret

dispatch_command:
    cmp byte [line_buffer], 0
    je .done

    mov esi, line_buffer
    mov edi, cmd_help
    call command_equals
    test eax, eax
    jnz .help

    mov esi, line_buffer
    mov edi, cmd_about
    call command_equals
    test eax, eax
    jnz .about

    mov esi, line_buffer
    mov edi, cmd_clear
    call command_equals
    test eax, eax
    jnz .clear

    mov esi, line_buffer
    mov edi, cmd_mem
    call command_equals
    test eax, eax
    jnz .mem

    mov esi, line_buffer
    mov edi, cmd_ls
    call command_equals
    test eax, eax
    jnz .ls

    mov esi, line_buffer
    mov edi, cmd_halt
    call command_equals
    test eax, eax
    jnz .halt

    mov esi, line_buffer
    mov edi, cmd_reboot
    call command_equals
    test eax, eax
    jnz .reboot

    mov esi, line_buffer
    mov edi, cmd_echo
    call command_equals
    test eax, eax
    jnz .echo_empty

    mov esi, line_buffer
    mov edi, cmd_echo_prefix
    call starts_with
    test eax, eax
    jnz .echo_with_text

    mov esi, unknown_prefix
    call console_write
    mov esi, line_buffer
    call console_write
    mov al, 10
    call console_putc
    jmp .done

.help:
    mov esi, help_text
    call console_write
    jmp .done

.about:
    mov esi, about_text
    call console_write
    jmp .done

.clear:
    call clear_screen
    call show_banner
    jmp .done

.mem:
    call print_memory_report
    jmp .done

.ls:
    call print_root_directory
    jmp .done

.echo_empty:
    mov al, 10
    call console_putc
    jmp .done

.echo_with_text:
    mov esi, line_buffer + 5
    call console_write
    mov al, 10
    call console_putc
    jmp .done

.halt:
    mov esi, halt_message
    call console_write
.halt_loop:
    cli
    hlt
    jmp .halt_loop

.reboot:
    mov esi, reboot_message
    call console_write
    call reboot_system
    jmp .done

.done:
    ret

print_memory_report:
    cmp dword [BOOT_INFO_ADDR], BOOTINFO_MAGIC
    jne .missing

    mov esi, mem_conv_prefix
    call console_write
    movzx eax, word [BOOT_INFO_ADDR + BOOTINFO_CONV_KB]
    call print_uint32
    mov esi, kb_suffix
    call console_write

    mov esi, mem_ext_prefix
    call console_write
    movzx eax, word [BOOT_INFO_ADDR + BOOTINFO_EXT_KB]
    call print_uint32
    mov esi, kb_suffix
    call console_write

    mov esi, mem_total_prefix
    call console_write
    mov eax, [BOOT_INFO_ADDR + BOOTINFO_TOTAL_KB]
    call print_uint32
    mov esi, kb_suffix
    call console_write
    ret

.missing:
    mov esi, mem_missing
    call console_write
    ret

print_root_directory:
    cmp dword [BOOT_INFO_ADDR], BOOTINFO_MAGIC
    jne .missing

    mov ebx, [BOOT_INFO_ADDR + BOOTINFO_ROOTDIR_ADDR]
    movzx ecx, word [BOOT_INFO_ADDR + BOOTINFO_ROOTDIR_ENTRIES]
    test ebx, ebx
    jz .missing
    test ecx, ecx
    jz .empty

    mov esi, ls_header
    call console_write

    xor edx, edx

.next_entry:
    test ecx, ecx
    jz .done_listing
    cmp byte [ebx], 0x00
    je .done_listing
    cmp byte [ebx], 0xE5
    je .skip_entry

    mov al, [ebx + 11]
    cmp al, 0x0F
    je .skip_entry
    test al, 0x08
    jnz .skip_entry

    push ecx
    push edx
    push ebx

    mov esi, ebx
    call print_fat_name
    mov esi, ls_spacing
    call console_write
    mov eax, [ebx + 28]
    call print_uint32
    mov esi, bytes_suffix
    call console_write

    pop ebx
    pop edx
    pop ecx
    inc edx

.skip_entry:
    add ebx, 32
    dec ecx
    jmp .next_entry

.done_listing:
    test edx, edx
    jnz .done

.empty:
    mov esi, ls_empty
    call console_write
    ret

.missing:
    mov esi, ls_missing
    call console_write

.done:
    ret

print_fat_name:
    push eax
    push ebx
    push ecx
    push edx
    push esi

    mov edx, esi
    mov ecx, 8

.name_loop:
    test ecx, ecx
    jz .check_ext
    mov al, [edx]
    cmp al, ' '
    je .check_ext
    call console_putc
    inc edx
    dec ecx
    jmp .name_loop

.check_ext:
    mov edx, esi
    add edx, 8
    mov ecx, 3

.scan_ext:
    test ecx, ecx
    jz .done
    cmp byte [edx], ' '
    jne .print_ext
    inc edx
    dec ecx
    jmp .scan_ext

.print_ext:
    mov al, '.'
    call console_putc

    mov edx, esi
    add edx, 8
    mov ecx, 3

.ext_loop:
    test ecx, ecx
    jz .done
    mov al, [edx]
    cmp al, ' '
    je .done
    call console_putc
    inc edx
    dec ecx
    jmp .ext_loop

.done:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

read_line:
    mov edi, line_buffer
    xor ecx, ecx

.read_char:
    call read_input_char

    cmp al, 13
    je .finish
    cmp al, 10
    je .finish
    cmp al, 8
    je .backspace
    cmp al, 127
    je .backspace

    cmp ecx, LINE_BUFFER_SIZE - 1
    jae .read_char

    mov [edi + ecx], al
    inc ecx
    call console_putc
    jmp .read_char

.backspace:
    test ecx, ecx
    jz .read_char
    dec ecx
    call console_backspace
    jmp .read_char

.finish:
    mov byte [edi + ecx], 0
    mov al, 10
    call console_putc
    ret

read_input_char:
.poll:
    mov dx, COM1 + 5
    in al, dx
    test al, 0x01
    jz .keyboard
    mov dx, COM1
    in al, dx
    ret

.keyboard:
    in al, 0x64
    test al, 0x01
    jz .poll

    in al, 0x60
    cmp al, 0xE0
    je .poll
    test al, 0x80
    jnz .poll

    movzx ebx, al
    mov al, [kbd_scancode_table + ebx]
    test al, al
    jz .poll
    ret

command_equals:
    push esi
    push edi

.compare:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne .not_equal
    test al, al
    je .equal
    inc esi
    inc edi
    jmp .compare

.equal:
    mov eax, 1
    jmp .done

.not_equal:
    xor eax, eax

.done:
    pop edi
    pop esi
    ret

starts_with:
    push esi
    push edi

.compare:
    mov bl, [edi]
    test bl, bl
    je .match
    mov al, [esi]
    cmp al, bl
    jne .no_match
    inc esi
    inc edi
    jmp .compare

.match:
    mov eax, 1
    jmp .done

.no_match:
    xor eax, eax

.done:
    pop edi
    pop esi
    ret

console_write:
    push eax

.loop:
    lodsb
    test al, al
    jz .done
    call console_putc
    jmp .loop

.done:
    pop eax
    ret

console_putc:
    cmp al, 13
    je .carriage_return
    cmp al, 10
    je .newline

    push eax
    call serial_write_raw
    pop eax
    call vga_write_char
    ret

.carriage_return:
    push eax
    call serial_write_raw
    pop eax
    mov dword [cursor_col], 0
    ret

.newline:
    push eax
    mov al, 13
    call serial_write_raw
    mov al, 10
    call serial_write_raw
    pop eax
    call vga_newline
    ret

console_backspace:
    push eax

    mov al, 8
    call serial_write_raw
    mov al, ' '
    call serial_write_raw
    mov al, 8
    call serial_write_raw

    cmp dword [cursor_col], 0
    jne .same_row
    cmp dword [cursor_row], 0
    je .done
    dec dword [cursor_row]
    mov dword [cursor_col], VGA_COLS - 1
    jmp .erase

.same_row:
    dec dword [cursor_col]

.erase:
    mov eax, [cursor_row]
    imul eax, VGA_COLS
    add eax, [cursor_col]
    shl eax, 1
    mov edi, VGA_TEXT
    add edi, eax
    mov al, ' '
    mov ah, [text_color]
    mov [edi], ax

.done:
    pop eax
    ret

vga_write_char:
    push eax
    push edx
    push edi

    cmp dword [cursor_col], VGA_COLS
    jb .write
    call vga_newline

.write:
    mov dl, al
    mov eax, [cursor_row]
    imul eax, VGA_COLS
    add eax, [cursor_col]
    shl eax, 1
    mov edi, VGA_TEXT
    add edi, eax
    mov al, dl
    mov ah, [text_color]
    mov [edi], ax

    inc dword [cursor_col]
    cmp dword [cursor_col], VGA_COLS
    jb .done
    call vga_newline

.done:
    pop edi
    pop edx
    pop eax
    ret

vga_newline:
    mov dword [cursor_col], 0
    inc dword [cursor_row]
    call vga_scroll_if_needed
    ret

vga_scroll_if_needed:
    cmp dword [cursor_row], VGA_ROWS
    jb .done

    push eax
    push ecx
    push esi
    push edi

    mov esi, VGA_TEXT + VGA_ROW_BYTES
    mov edi, VGA_TEXT
    mov ecx, (VGA_COLS * (VGA_ROWS - 1) * 2) / 4
    rep movsd

    mov edi, VGA_TEXT + (VGA_ROW_BYTES * (VGA_ROWS - 1))
    mov ah, [text_color]
    mov al, ' '
    mov ecx, VGA_COLS
    rep stosw

    mov dword [cursor_row], VGA_ROWS - 1

    pop edi
    pop esi
    pop ecx
    pop eax

.done:
    ret

clear_screen:
    push eax
    push ecx
    push edi

    mov edi, VGA_TEXT
    mov ah, [text_color]
    mov al, ' '
    mov ecx, VGA_COLS * VGA_ROWS
    rep stosw

    mov dword [cursor_row], 0
    mov dword [cursor_col], 0

    pop edi
    pop ecx
    pop eax
    ret

serial_init:
    mov dx, COM1 + 1
    xor al, al
    out dx, al

    mov dx, COM1 + 3
    mov al, 0x80
    out dx, al

    mov dx, COM1 + 0
    mov al, 0x01
    out dx, al

    mov dx, COM1 + 1
    xor al, al
    out dx, al

    mov dx, COM1 + 3
    mov al, 0x03
    out dx, al

    mov dx, COM1 + 2
    mov al, 0xC7
    out dx, al

    mov dx, COM1 + 4
    mov al, 0x0B
    out dx, al
    ret

serial_write_raw:
    push edx
    mov [serial_shadow], al

.wait:
    mov dx, COM1 + 5
    in al, dx
    test al, 0x20
    jz .wait

    mov dx, COM1
    mov al, [serial_shadow]
    out dx, al

    pop edx
    ret

print_uint32:
    push eax
    push ebx
    push ecx
    push edx
    push edi

    mov edi, number_buffer + 15
    mov byte [edi], 0
    dec edi
    mov ebx, 10

    cmp eax, 0
    jne .convert
    mov al, '0'
    call console_putc
    jmp .done

.convert:
    xor edx, edx
    div ebx
    add dl, '0'
    mov [edi], dl
    dec edi
    test eax, eax
    jnz .convert

    lea esi, [edi + 1]
    call console_write

.done:
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

reboot_system:
.wait_ready:
    in al, 0x64
    test al, 0x02
    jnz .wait_ready

    mov al, 0xFE
    out 0x64, al

.hang:
    cli
    hlt
    jmp .hang

text_color:        db 0x0F
serial_shadow:     db 0
cursor_row:        dd 0
cursor_col:        dd 0

banner_top:        db '==============================================================', 10, 0
banner_mid:        db ' Lum-OS kernel online (32-bit protected mode)', 10, 0
banner_bottom:     db '==============================================================', 10, 0
boot_ok_message:   db '[ok] Boot path complete: FAT12 -> stage2 -> protected mode -> kernel', 10, 0
shell_hint:        db 'Type help. Input works from the QEMU keyboard or the serial console.', 10, 10, 0

prompt:            db 'lum> ', 0
unknown_prefix:    db 'Unknown command: ', 0
help_text:         db 'Commands: help, about, clear, mem, ls, echo <text>, reboot, halt', 10, 0
about_text:        db 'Lum-OS is a tiny from-scratch x86 OS demo with a FAT12 stage1/stage2 loader,', 10, 'a protected-mode kernel, and a small interactive shell with root directory listing.', 10, 0
halt_message:      db 'CPU halted.', 10, 0
reboot_message:    db 'Rebooting system...', 10, 0
mem_conv_prefix:   db 'Conventional memory: ', 0
mem_ext_prefix:    db 'Extended memory:     ', 0
mem_total_prefix:  db 'Approx total memory: ', 0
mem_missing:       db 'Memory info unavailable.', 10, 0
kb_suffix:         db ' KB', 10, 0
ls_header:         db 'Root directory:', 10, 0
ls_spacing:        db '  ', 0
bytes_suffix:      db ' bytes', 10, 0
ls_empty:          db '<empty>', 10, 0
ls_missing:        db 'Root directory metadata unavailable.', 10, 0

cmd_help:          db 'help', 0
cmd_about:         db 'about', 0
cmd_clear:         db 'clear', 0
cmd_mem:           db 'mem', 0
cmd_ls:            db 'ls', 0
cmd_echo:          db 'echo', 0
cmd_echo_prefix:   db 'echo ', 0
cmd_reboot:        db 'reboot', 0
cmd_halt:          db 'halt', 0

kbd_scancode_table:
    db 0, 27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8, 9
    db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', 0, 0, 10, 0
    db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 0, 0, 0, 0, 0
    db 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, '*', 0, ' '
    times (128 - ($ - kbd_scancode_table)) db 0

number_buffer:     times 16 db 0
line_buffer:       times LINE_BUFFER_SIZE db 0
