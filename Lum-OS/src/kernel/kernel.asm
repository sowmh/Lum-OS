org 0x10000
bits 32

%define STACK_TOP             0x0009F000
%define VGA_TEXT              0xB8000
%define VGA_COLS              80
%define VGA_ROWS              25
%define VGA_ROW_BYTES         (VGA_COLS * 2)
%define COM1                  0x3F8
%define PIC1_COMMAND          0x20
%define PIC1_DATA             0x21
%define PIC2_COMMAND          0xA0
%define PIC2_DATA             0xA1
%define PIC_EOI               0x20
%define PIT_COMMAND           0x43
%define PIT_CHANNEL0          0x40
%define PIT_DIVISOR           11931
%define PIT_HZ                100
%define KBD_DATA_PORT         0x60
%define KBD_STATUS_PORT       0x64
%define BOOT_INFO_ADDR        0x00009000
%define BOOTINFO_MAGIC        0x304D554C
%define BOOTINFO_BOOT_DRIVE   5
%define BOOTINFO_CONV_KB      6
%define BOOTINFO_EXT_KB       8
%define BOOTINFO_TOTAL_KB     10
%define GDT_CODE_SELECTOR     0x08
%define GDT_DATA_SELECTOR     0x10
%define LINE_BUFFER_SIZE      128
%define KEYBOARD_BUFFER_SIZE  64
%define KEYBOARD_BUFFER_MASK  (KEYBOARD_BUFFER_SIZE - 1)

start:
    cli
    cld
    mov esp, STACK_TOP

    mov byte [text_color], 0x0F
    mov dword [cursor_row], 0
    mov dword [cursor_col], 0
    mov dword [tick_count], 0
    mov byte [keybuf_head], 0
    mov byte [keybuf_tail], 0
    mov byte [kbd_shift], 0
    mov byte [kbd_extended], 0

    call serial_init
    call clear_screen
    call load_idt
    call remap_pic
    call init_pit

    sti

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
    mov esi, irq_ok_message
    call console_write
    mov esi, pit_ok_message
    call console_write
    mov esi, keyboard_ok_message
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
    mov edi, cmd_uptime
    call command_equals
    test eax, eax
    jnz .uptime

    mov esi, line_buffer
    mov edi, cmd_ticks
    call command_equals
    test eax, eax
    jnz .ticks

    mov esi, line_buffer
    mov edi, cmd_irq
    call command_equals
    test eax, eax
    jnz .irq

    mov esi, line_buffer
    mov edi, cmd_boot
    call command_equals
    test eax, eax
    jnz .boot

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

.uptime:
    call print_uptime
    jmp .done

.ticks:
    call print_ticks
    jmp .done

.irq:
    call print_irq_status
    jmp .done

.boot:
    call print_boot_status
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
    call keyboard_buffer_pop
    jnc .done

    mov dx, COM1 + 5
    in al, dx
    test al, 0x01
    jnz .serial_ready

    pause
    jmp .poll

.serial_ready:
    mov dx, COM1
    in al, dx

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

print_uptime:
    push eax
    push ebx
    push edx

    mov esi, uptime_prefix
    call console_write

    mov eax, [tick_count]
    xor edx, edx
    mov ebx, PIT_HZ
    div ebx
    push edx
    call print_uint32
    mov al, '.'
    call console_putc
    pop eax
    mov ebx, 100
    mul ebx
    xor edx, edx
    mov ebx, PIT_HZ
    div ebx
    call print_two_digits

    mov esi, uptime_middle
    call console_write
    mov eax, [tick_count]
    call print_uint32
    mov esi, uptime_suffix
    call console_write

    pop edx
    pop ebx
    pop eax
    ret

print_ticks:
    mov esi, ticks_prefix
    call console_write
    mov eax, [tick_count]
    call print_uint32
    mov al, 10
    call console_putc
    ret

print_irq_status:
    mov esi, irq_title
    call console_write

    mov esi, irq_idt_prefix
    call console_write
    mov eax, idt_table
    call print_hex32
    mov al, 10
    call console_putc

    mov esi, irq_pit_prefix
    call console_write
    mov eax, PIT_HZ
    call print_uint32
    mov esi, hz_suffix
    call console_write

    mov esi, irq_ticks_prefix
    call console_write
    mov eax, [tick_count]
    call print_uint32
    mov al, 10
    call console_putc

    mov esi, irq_keys_prefix
    call console_write
    call keyboard_buffer_count
    call print_uint32
    mov al, 10
    call console_putc
    ret

print_boot_status:
    cmp dword [BOOT_INFO_ADDR], BOOTINFO_MAGIC
    jne .missing

    mov esi, boot_title
    call console_write
    mov esi, boot_drive_prefix
    call console_write
    movzx eax, byte [BOOT_INFO_ADDR + BOOTINFO_BOOT_DRIVE]
    call print_hex32
    mov al, 10
    call console_putc

    mov esi, boot_kernel_prefix
    call console_write
    mov eax, start
    call print_hex32
    mov al, 10
    call console_putc
    ret

.missing:
    mov esi, mem_missing
    call console_write
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
    push edi

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
    pop edi
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

load_idt:
    xor ecx, ecx
    mov esi, interrupt_handler_table

.fill:
    lodsd
    call set_idt_entry
    inc ecx
    cmp ecx, interrupt_handler_count
    jb .fill

    lidt [idt_descriptor]
    ret

set_idt_entry:
    push ebx
    push edi

    lea edi, [idt_table + ecx * 8]
    mov [edi + 0], ax
    mov word [edi + 2], GDT_CODE_SELECTOR
    mov byte [edi + 4], 0
    mov byte [edi + 5], 0x8E
    shr eax, 16
    mov [edi + 6], ax

    pop edi
    pop ebx
    ret

remap_pic:
    mov al, 0x11
    out PIC1_COMMAND, al
    out PIC2_COMMAND, al

    mov al, 0x20
    out PIC1_DATA, al
    mov al, 0x28
    out PIC2_DATA, al

    mov al, 0x04
    out PIC1_DATA, al
    mov al, 0x02
    out PIC2_DATA, al

    mov al, 0x01
    out PIC1_DATA, al
    out PIC2_DATA, al

    mov al, 0xF8
    out PIC1_DATA, al
    mov al, 0xFF
    out PIC2_DATA, al
    ret

init_pit:
    mov al, 0x36
    out PIT_COMMAND, al

    mov ax, PIT_DIVISOR
    out PIT_CHANNEL0, al
    mov al, ah
    out PIT_CHANNEL0, al
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

keyboard_buffer_push:
    push ebx
    push edx

    movzx ebx, byte [keybuf_head]
    mov edx, ebx
    inc edx
    and edx, KEYBOARD_BUFFER_MASK

    cmp dl, [keybuf_tail]
    je .done

    mov [keyboard_buffer + ebx], al
    mov [keybuf_head], dl

.done:
    pop edx
    pop ebx
    ret

keyboard_buffer_pop:
    push ebx

    mov bl, [keybuf_tail]
    cmp bl, [keybuf_head]
    je .empty

    movzx ebx, bl
    mov al, [keyboard_buffer + ebx]
    inc bl
    and bl, KEYBOARD_BUFFER_MASK
    mov [keybuf_tail], bl
    clc
    jmp .done

.empty:
    stc

.done:
    pop ebx
    ret

keyboard_buffer_count:
    push edx

    movzx eax, byte [keybuf_head]
    movzx edx, byte [keybuf_tail]
    sub eax, edx
    and eax, KEYBOARD_BUFFER_MASK

    pop edx
    ret

process_keyboard_scancode:
    cmp al, 0xE0
    jne .maybe_extended
    mov byte [kbd_extended], 1
    ret

.maybe_extended:
    cmp byte [kbd_extended], 0
    je .shift_checks
    mov byte [kbd_extended], 0
    ret

.shift_checks:
    cmp al, 0x2A
    je .shift_down
    cmp al, 0x36
    je .shift_down
    cmp al, 0xAA
    je .shift_up
    cmp al, 0xB6
    je .shift_up

    test al, 0x80
    jnz .done

    movzx ebx, al
    cmp byte [kbd_shift], 0
    jne .upper
    mov al, [kbd_scancode_lower + ebx]
    jmp .emit

.upper:
    mov al, [kbd_scancode_upper + ebx]

.emit:
    test al, al
    jz .done
    call keyboard_buffer_push
    ret

.shift_down:
    mov byte [kbd_shift], 1
    ret

.shift_up:
    mov byte [kbd_shift], 0

.done:
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

print_two_digits:
    push eax
    push ebx
    push edx

    xor edx, edx
    mov ebx, 10
    div ebx
    add al, '0'
    call console_putc
    mov al, dl
    add al, '0'
    call console_putc

    pop edx
    pop ebx
    pop eax
    ret

print_hex32:
    push eax
    push ebx
    push ecx
    push edx

    mov ebx, eax

    mov al, '0'
    call console_putc
    mov al, 'x'
    call console_putc

    mov ecx, 8

.loop:
    mov edx, ebx
    shr edx, 28
    mov al, [hex_digits + edx]
    call console_putc
    shl ebx, 4
    loop .loop

    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

reboot_system:
.wait_ready:
    in al, KBD_STATUS_PORT
    test al, 0x02
    jnz .wait_ready

    mov al, 0xFE
    out KBD_STATUS_PORT, al

.hang:
    cli
    hlt
    jmp .hang

exception_common:
    pushad
    push ds
    push es
    push fs
    push gs

    mov ax, GDT_DATA_SELECTOR
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov eax, [esp + 48]
    mov [last_exception_vector], eax
    mov eax, [esp + 52]
    mov [last_exception_error], eax
    mov eax, [esp + 56]
    mov [last_exception_eip], eax

    call show_exception_screen

.hang:
    cli
    hlt
    jmp .hang

show_exception_screen:
    mov byte [text_color], 0x4F
    call clear_screen

    mov esi, exception_title
    call console_write

    mov byte [text_color], 0x0F
    mov esi, exception_vector_prefix
    call console_write
    mov eax, [last_exception_vector]
    call print_uint32
    mov al, 10
    call console_putc

    mov esi, exception_error_prefix
    call console_write
    mov eax, [last_exception_error]
    call print_hex32
    mov al, 10
    call console_putc

    mov esi, exception_eip_prefix
    call console_write
    mov eax, [last_exception_eip]
    call print_hex32
    mov al, 10
    call console_putc

    mov esi, exception_halt_message
    call console_write
    ret

timer_irq_handler:
    inc dword [tick_count]
    mov al, PIC_EOI
    out PIC1_COMMAND, al
    ret

keyboard_irq_handler:
    in al, KBD_DATA_PORT
    call process_keyboard_scancode
    mov al, PIC_EOI
    out PIC1_COMMAND, al
    ret

spurious_master_irq_handler:
    mov al, PIC_EOI
    out PIC1_COMMAND, al
    ret

spurious_slave_irq_handler:
    mov al, PIC_EOI
    out PIC2_COMMAND, al
    out PIC1_COMMAND, al
    ret

%macro ISR_NOERR 1
isr_stub_%1:
    cli
    push dword 0
    push dword %1
    jmp exception_common
%endmacro

%macro ISR_ERR 1
isr_stub_%1:
    cli
    push dword %1
    jmp exception_common
%endmacro

%macro IRQ_STUB 2
irq_stub_%1:
    pushad
    call %2
    popad
    iretd
%endmacro

ISR_NOERR 0
ISR_NOERR 1
ISR_NOERR 2
ISR_NOERR 3
ISR_NOERR 4
ISR_NOERR 5
ISR_NOERR 6
ISR_NOERR 7
ISR_ERR   8
ISR_NOERR 9
ISR_ERR   10
ISR_ERR   11
ISR_ERR   12
ISR_ERR   13
ISR_ERR   14
ISR_NOERR 15
ISR_NOERR 16
ISR_ERR   17
ISR_NOERR 18
ISR_NOERR 19
ISR_NOERR 20
ISR_NOERR 21
ISR_NOERR 22
ISR_NOERR 23
ISR_NOERR 24
ISR_NOERR 25
ISR_NOERR 26
ISR_NOERR 27
ISR_NOERR 28
ISR_NOERR 29
ISR_NOERR 30
ISR_NOERR 31

IRQ_STUB 0,  timer_irq_handler
IRQ_STUB 1,  keyboard_irq_handler
IRQ_STUB 2,  spurious_master_irq_handler
IRQ_STUB 3,  spurious_master_irq_handler
IRQ_STUB 4,  spurious_master_irq_handler
IRQ_STUB 5,  spurious_master_irq_handler
IRQ_STUB 6,  spurious_master_irq_handler
IRQ_STUB 7,  spurious_master_irq_handler
IRQ_STUB 8,  spurious_slave_irq_handler
IRQ_STUB 9,  spurious_slave_irq_handler
IRQ_STUB 10, spurious_slave_irq_handler
IRQ_STUB 11, spurious_slave_irq_handler
IRQ_STUB 12, spurious_slave_irq_handler
IRQ_STUB 13, spurious_slave_irq_handler
IRQ_STUB 14, spurious_slave_irq_handler
IRQ_STUB 15, spurious_slave_irq_handler

align 8
idt_table:
    times 256 dq 0
idt_table_end:

idt_descriptor:
    dw idt_table_end - idt_table - 1
    dd idt_table

interrupt_handler_table:
    dd isr_stub_0, isr_stub_1, isr_stub_2, isr_stub_3
    dd isr_stub_4, isr_stub_5, isr_stub_6, isr_stub_7
    dd isr_stub_8, isr_stub_9, isr_stub_10, isr_stub_11
    dd isr_stub_12, isr_stub_13, isr_stub_14, isr_stub_15
    dd isr_stub_16, isr_stub_17, isr_stub_18, isr_stub_19
    dd isr_stub_20, isr_stub_21, isr_stub_22, isr_stub_23
    dd isr_stub_24, isr_stub_25, isr_stub_26, isr_stub_27
    dd isr_stub_28, isr_stub_29, isr_stub_30, isr_stub_31
    dd irq_stub_0, irq_stub_1, irq_stub_2, irq_stub_3
    dd irq_stub_4, irq_stub_5, irq_stub_6, irq_stub_7
    dd irq_stub_8, irq_stub_9, irq_stub_10, irq_stub_11
    dd irq_stub_12, irq_stub_13, irq_stub_14, irq_stub_15
interrupt_handler_count equ ($ - interrupt_handler_table) / 4

text_color:              db 0x0F
serial_shadow:           db 0
keybuf_head:             db 0
keybuf_tail:             db 0
kbd_shift:               db 0
kbd_extended:            db 0
cursor_row:              dd 0
cursor_col:              dd 0
tick_count:              dd 0
last_exception_vector:   dd 0
last_exception_error:    dd 0
last_exception_eip:      dd 0

banner_top:              db '==============================================================', 10, 0
banner_mid:              db ' Lum-OS kernel online (32-bit protected mode)', 10, 0
banner_bottom:           db '==============================================================', 10, 0
boot_ok_message:         db '[ok] Boot path complete: FAT12 -> stage2 -> protected mode -> kernel', 10, 0
irq_ok_message:          db '[ok] IDT loaded and PIC remapped for hardware interrupts', 10, 0
pit_ok_message:          db '[ok] PIT timer running at 100 Hz for uptime and idle wakeups', 10, 0
keyboard_ok_message:     db '[ok] Keyboard driver is now IRQ-driven instead of controller polling', 10, 0
shell_hint:              db 'Type help. Keyboard input uses IRQ1, serial input still works in headless mode.', 10, 10, 0

prompt:                  db 'lum> ', 0
unknown_prefix:          db 'Unknown command: ', 0
help_text:               db 'Commands: help, about, clear, mem, boot, irq, ticks, uptime, echo <text>, reboot, halt', 10, 0
about_text:              db 'Lum-OS now boots into an interrupt-driven 32-bit kernel with PIT timing,', 10, 'IRQ keyboard input, VGA + serial console output, and a simple shell.', 10, 0
halt_message:            db 'CPU halted.', 10, 0
reboot_message:          db 'Rebooting system...', 10, 0

mem_conv_prefix:         db 'Conventional memory: ', 0
mem_ext_prefix:          db 'Extended memory:     ', 0
mem_total_prefix:        db 'Approx total memory: ', 0
mem_missing:             db 'Memory info unavailable.', 10, 0
boot_title:              db 'Boot status:', 10, 0
boot_drive_prefix:       db '  boot drive:  ', 0
boot_kernel_prefix:      db '  kernel base: ', 0
uptime_prefix:           db 'Uptime: ', 0
uptime_middle:           db 's (', 0
uptime_suffix:           db ' ticks @ 100 Hz)', 10, 0
ticks_prefix:            db 'Ticks: ', 0
irq_title:               db 'Interrupt status:', 10, 0
irq_idt_prefix:          db '  idt base:           ', 0
irq_pit_prefix:          db '  pit frequency:      ', 0
irq_ticks_prefix:        db '  timer ticks:        ', 0
irq_keys_prefix:         db '  queued keypresses:  ', 0
kb_suffix:               db ' KB', 10, 0
hz_suffix:               db ' Hz', 10, 0

exception_title:         db 'KERNEL EXCEPTION', 10, 10, 0
exception_vector_prefix: db 'Vector:     ', 0
exception_error_prefix:  db 'Error code: ', 0
exception_eip_prefix:    db 'EIP:        ', 0
exception_halt_message:  db 10, 'System halted after an unrecoverable exception.', 10, 0

cmd_help:                db 'help', 0
cmd_about:               db 'about', 0
cmd_clear:               db 'clear', 0
cmd_mem:                 db 'mem', 0
cmd_boot:                db 'boot', 0
cmd_irq:                 db 'irq', 0
cmd_ticks:               db 'ticks', 0
cmd_uptime:              db 'uptime', 0
cmd_echo:                db 'echo', 0
cmd_echo_prefix:         db 'echo ', 0
cmd_reboot:              db 'reboot', 0
cmd_halt:                db 'halt', 0

hex_digits:              db '0123456789ABCDEF'

kbd_scancode_lower:
    db 0, 27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8, 9
    db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 10, 0
    db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', 39, '`', 0, '\'
    db 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, '*', 0, ' '
    times (128 - ($ - kbd_scancode_lower)) db 0

kbd_scancode_upper:
    db 0, 27, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', 8, 9
    db 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', 10, 0
    db 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', 34, '~', 0, '|'
    db 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 0, '*', 0, ' '
    times (128 - ($ - kbd_scancode_upper)) db 0

number_buffer:           times 16 db 0
line_buffer:             times LINE_BUFFER_SIZE db 0
keyboard_buffer:         times KEYBOARD_BUFFER_SIZE db 0
